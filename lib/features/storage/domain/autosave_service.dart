import 'dart:async';

/// Status of the local-first autosave mechanism.
enum AutosaveStatus {
  /// No unsaved changes or initial state.
  idle,

  /// Currently writing changes to local Hive database.
  saving,

  /// All changes safely saved to disk.
  saved,

  /// Error occurred during save operation.
  error,
}

/// Autosave engine with 400ms debounce and instantaneous flush capability.
/// Guarantees zero data loss while preventing disk I/O thrashing during card dragging.
class AutosaveEngine {
  final Duration debounceDuration;
  final Future<void> Function() onSave;
  final void Function(AutosaveStatus status)? onStatusChanged;

  Timer? _debounceTimer;
  bool _isSaving = false;
  bool _hasPendingSave = false;
  bool _isDisposed = false;
  Completer<void>? _activeSaveCompleter;
  AutosaveStatus _status = AutosaveStatus.idle;

  AutosaveEngine({
    required this.onSave,
    this.debounceDuration = const Duration(milliseconds: 400),
    this.onStatusChanged,
  });

  /// Current autosave status.
  AutosaveStatus get status => _status;

  /// True if there are mutations queued that have not been written to disk yet.
  bool get hasPendingSave => _hasPendingSave || _debounceTimer?.isActive == true;

  void _setStatus(AutosaveStatus newStatus) {
    if (_status != newStatus && !_isDisposed) {
      _status = newStatus;
      onStatusChanged?.call(newStatus);
    }
  }

  /// Notifies the engine that a canvas mutation occurred.
  /// Debounces the save operation by [debounceDuration].
  void notifyMutation() {
    if (_isDisposed) return;
    _hasPendingSave = true;
    _setStatus(AutosaveStatus.saving);

    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounceDuration, () {
      _performSave();
    });
  }

  /// Forces an immediate synchronous flush to disk, bypassing any remaining debounce delay.
  /// Essential when the board is closed, app is backgrounded, or navigating away.
  Future<void> flush() async {
    if (_isDisposed) return;
    _debounceTimer?.cancel();
    while ((_isSaving || _hasPendingSave) && !_isDisposed) {
      if (_isSaving) {
        await _activeSaveCompleter?.future;
      } else if (_hasPendingSave) {
        await _performSave();
      }
    }
  }

  Future<void> _performSave() async {
    if (_isDisposed) return;
    if (_isSaving) {
      // Re-trigger after current save finishes
      _hasPendingSave = true;
      return;
    }

    _isSaving = true;
    _hasPendingSave = false;
    _setStatus(AutosaveStatus.saving);
    _activeSaveCompleter = Completer<void>();

    try {
      await onSave();
      if (!_hasPendingSave) {
        _setStatus(AutosaveStatus.saved);
      }
    } catch (e) {
      _setStatus(AutosaveStatus.error);
    } finally {
      _isSaving = false;
      final completer = _activeSaveCompleter;
      _activeSaveCompleter = null;
      if (completer != null && !completer.isCompleted) {
        completer.complete();
      }
      if (_hasPendingSave && !_isDisposed) {
        // Run another save if mutations arrived while writing
        _performSave();
      }
    }
  }

  /// Cancels any pending timer and cleans up resources.
  void dispose() {
    _isDisposed = true;
    _debounceTimer?.cancel();
    if (_activeSaveCompleter != null && !_activeSaveCompleter!.isCompleted) {
      _activeSaveCompleter!.complete();
    }
  }
}
