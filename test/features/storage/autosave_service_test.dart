import 'package:flutter_test/flutter_test.dart';
import 'package:localboard/features/storage/domain/autosave_service.dart';

void main() {
  group('AutosaveEngine Tests (STS-03)', () {
    test('debounces multiple rapid mutations into a single save', () async {
      int saveCount = 0;
      final statuses = <AutosaveStatus>[];

      final engine = AutosaveEngine(
        debounceDuration: const Duration(milliseconds: 50),
        onSave: () async {
          saveCount++;
        },
        onStatusChanged: (status) => statuses.add(status),
      );

      expect(engine.status, equals(AutosaveStatus.idle));

      // Trigger 5 rapid mutations
      engine.notifyMutation();
      engine.notifyMutation();
      engine.notifyMutation();
      engine.notifyMutation();
      engine.notifyMutation();

      expect(engine.status, equals(AutosaveStatus.saving));
      expect(saveCount, equals(0));

      // Wait for debounce duration
      await Future.delayed(const Duration(milliseconds: 100));

      expect(saveCount, equals(1));
      expect(engine.status, equals(AutosaveStatus.saved));

      engine.dispose();
    });

    test('flush immediately triggers save without waiting for debounce', () async {
      int saveCount = 0;
      final engine = AutosaveEngine(
        debounceDuration: const Duration(milliseconds: 500),
        onSave: () async {
          saveCount++;
        },
      );

      engine.notifyMutation();
      expect(saveCount, equals(0));

      // Immediate flush
      await engine.flush();

      expect(saveCount, equals(1));
      expect(engine.status, equals(AutosaveStatus.saved));
      expect(engine.hasPendingSave, isFalse);

      engine.dispose();
    });

    test('handles errors gracefully and sets status to error', () async {
      final engine = AutosaveEngine(
        debounceDuration: const Duration(milliseconds: 20),
        onSave: () async {
          throw Exception('Disk full or I/O failure');
        },
      );

      engine.notifyMutation();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(engine.status, equals(AutosaveStatus.error));

      engine.dispose();
    });
  });
}
