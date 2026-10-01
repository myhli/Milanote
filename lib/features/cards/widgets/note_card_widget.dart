import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../models/note_card.dart';

/// Interactive UI widget rendering a Note Card with inline text editing,
/// checklists with toggleable checkboxes, and pastel background color selector.
class NoteCardWidget extends StatefulWidget {
  final NoteCard card;
  final bool isSelected;
  final ValueChanged<String>? onTitleChanged;
  final ValueChanged<String>? onContentChanged;
  final ValueChanged<String>? onColorChanged;
  final ValueChanged<List<ChecklistItem>>? onChecklistsChanged;
  final VoidCallback? onToggleMode;

  const NoteCardWidget({
    super.key,
    required this.card,
    this.isSelected = false,
    this.onTitleChanged,
    this.onContentChanged,
    this.onColorChanged,
    this.onChecklistsChanged,
    this.onToggleMode,
  });

  @override
  State<NoteCardWidget> createState() => _NoteCardWidgetState();
}

/// Custom TextEditingController that live-styles Markdown headings (#), bold (**text**),
/// italic (*text*), and bullet lists (• or -) directly inside the text editor without external dependencies (US-004).
class FormattingTextEditingController extends TextEditingController {
  FormattingTextEditingController({super.text});

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final defaultStyle = style ?? const TextStyle();
    if (text.isEmpty) {
      return TextSpan(text: '', style: defaultStyle);
    }

    final spans = <InlineSpan>[];
    final lines = text.split('\n');

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final isLastLine = i == lines.length - 1;
      final lineEnding = isLastLine ? '' : '\n';

      if (line.startsWith('# ') || line.startsWith('## ')) {
        // Heading
        spans.add(TextSpan(
          text: '$line$lineEnding',
          style: defaultStyle.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: (defaultStyle.fontSize ?? 13) + 2.5,
            letterSpacing: -0.2,
          ),
        ));
      } else if (line.startsWith('• ') || line.startsWith('- ')) {
        // Bullet point
        spans.add(TextSpan(
          text: line.substring(0, 2),
          style: defaultStyle.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.accentPrimary,
          ),
        ));
        _parseInlineFormatting(line.substring(2) + lineEnding, defaultStyle, spans);
      } else {
        _parseInlineFormatting(line + lineEnding, defaultStyle, spans);
      }
    }

    return TextSpan(children: spans);
  }

  void _parseInlineFormatting(String lineText, TextStyle baseStyle, List<InlineSpan> spans) {
    final regex = RegExp(r'(\*\*[^*]+\*\*|\*[^*]+\*)');
    int lastMatchEnd = 0;

    for (final match in regex.allMatches(lineText)) {
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(
          text: lineText.substring(lastMatchEnd, match.start),
          style: baseStyle,
        ));
      }

      final matchedStr = match.group(0)!;
      if (matchedStr.startsWith('**') && matchedStr.endsWith('**') && matchedStr.length >= 4) {
        spans.add(TextSpan(
          text: matchedStr,
          style: baseStyle.copyWith(fontWeight: FontWeight.bold),
        ));
      } else if (matchedStr.startsWith('*') && matchedStr.endsWith('*') && matchedStr.length >= 2) {
        spans.add(TextSpan(
          text: matchedStr,
          style: baseStyle.copyWith(fontStyle: FontStyle.italic),
        ));
      } else {
        spans.add(TextSpan(text: matchedStr, style: baseStyle));
      }

      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < lineText.length) {
      spans.add(TextSpan(
        text: lineText.substring(lastMatchEnd),
        style: baseStyle,
      ));
    }
  }
}

class _NoteCardWidgetState extends State<NoteCardWidget> {
  late final TextEditingController _titleController;
  late final FormattingTextEditingController _contentController;
  final TextEditingController _newItemController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.card.title);
    _contentController = FormattingTextEditingController(text: widget.card.content);
  }

  @override
  void didUpdateWidget(covariant NoteCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.card.title != widget.card.title &&
        _titleController.text != widget.card.title) {
      _titleController.text = widget.card.title;
    }
    if (oldWidget.card.content != widget.card.content &&
        _contentController.text != widget.card.content) {
      _contentController.text = widget.card.content;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _newItemController.dispose();
    super.dispose();
  }

  void _applyFormat(String prefix, String suffix) {
    final selection = _contentController.selection;
    final text = _contentController.text;

    if (!selection.isValid || selection.isCollapsed) {
      final insertPos = selection.isValid ? selection.baseOffset : text.length;
      final placeholder = prefix == '# ' ? 'Judul' : (prefix == '• ' ? 'Item' : 'teks');
      final insertion = '$prefix$placeholder$suffix';
      final newText = text.replaceRange(insertPos, insertPos, insertion);
      _contentController.value = TextEditingValue(
        text: newText,
        selection: TextSelection(
          baseOffset: insertPos + prefix.length,
          extentOffset: insertPos + prefix.length + placeholder.length,
        ),
      );
    } else {
      final selectedText = text.substring(selection.start, selection.end);
      final newText = text.replaceRange(selection.start, selection.end, '$prefix$selectedText$suffix');
      _contentController.value = TextEditingValue(
        text: newText,
        selection: TextSelection(
          baseOffset: selection.start + prefix.length,
          extentOffset: selection.end + prefix.length,
        ),
      );
    }
    widget.onContentChanged?.call(_contentController.text);
  }

  Color _parseCardBg(String hex) {
    try {
      final clean = hex.replaceAll('#', '');
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return const Color(0xFFFEF9C3);
    }
  }

  void _toggleChecklistItem(int index) {
    final updated = List<ChecklistItem>.from(widget.card.checklists);
    final item = updated[index];
    updated[index] = item.copyWith(isDone: !item.isDone);
    widget.onChecklistsChanged?.call(updated);
  }

  void _addChecklistItem() {
    final text = _newItemController.text.trim();
    if (text.isEmpty) return;

    final updated = List<ChecklistItem>.from(widget.card.checklists)
      ..add(
        ChecklistItem(
          id: 'item_${DateTime.now().millisecondsSinceEpoch}',
          text: text,
          isDone: false,
        ),
      );
    _newItemController.clear();
    widget.onChecklistsChanged?.call(updated);
  }

  void _removeChecklistItem(int index) {
    final updated = List<ChecklistItem>.from(widget.card.checklists)
      ..removeAt(index);
    widget.onChecklistsChanged?.call(updated);
  }

  @override
  Widget build(BuildContext context) {
    final cardBg = _parseCardBg(widget.card.colorHex);
    // Dark slate text for high contrast on pastel backgrounds
    const textColor = Color(0xFF1E293B);
    const subtextColor = Color(0xFF64748B);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subtle top drag handle
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
              color: Colors.transparent,
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          // Header Row: Title & Checklist Mode Toggle
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _titleController,
                  onChanged: widget.onTitleChanged,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                    letterSpacing: -0.2,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Judul Catatan...',
                    hintStyle: TextStyle(
                      color: subtextColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                  ),
                ),
              ),
              // Toggle Checklist Mode
              IconButton(
                icon: Icon(
                  widget.card.isChecklistMode
                      ? Icons.check_box_rounded
                      : Icons.notes_rounded,
                  size: 18,
                  color: widget.card.isChecklistMode
                      ? AppColors.accentPrimary
                      : subtextColor,
                ),
                tooltip: widget.card.isChecklistMode
                    ? 'Beralih ke Catatan Teks'
                    : 'Beralih ke Daftar Tugas (Checklist)',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: widget.onToggleMode,
              ),
            ],
          ),

          // Micro Formatting Toolbar (Heading, Bold, Italic, Bullet) when card is selected in text mode
          if (widget.isSelected && !widget.card.isChecklistMode) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(6),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const ClampingScrollPhysics(),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildFormatButton(
                      key: const Key('format_heading_btn'),
                      label: 'H',
                      tooltip: 'Heading (# Judul)',
                      isBold: true,
                      onTap: () => _applyFormat('# ', ''),
                    ),
                    const SizedBox(width: 3),
                    _buildFormatButton(
                      key: const Key('format_bold_btn'),
                      label: 'B',
                      tooltip: 'Tebal (**teks**)',
                      isBold: true,
                      onTap: () => _applyFormat('**', '**'),
                    ),
                    const SizedBox(width: 3),
                    _buildFormatButton(
                      key: const Key('format_italic_btn'),
                      label: 'I',
                      tooltip: 'Miring (*teks*)',
                      isItalic: true,
                      onTap: () => _applyFormat('*', '*'),
                    ),
                    const SizedBox(width: 3),
                    _buildFormatButton(
                      key: const Key('format_bullet_btn'),
                      label: '• List',
                      tooltip: 'Daftar Poin (• Item)',
                      onTap: () => _applyFormat('• ', ''),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 6),

          // Body: Text mode or Checklist mode
          Expanded(
            child: widget.card.isChecklistMode
                ? _buildChecklistBody(textColor, subtextColor)
                : _buildTextBody(textColor, subtextColor),
          ),

          // Bottom Bar: Pastel color swatches palette
          if (widget.isSelected) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: NoteCard.pastelColors.map((hex) {
                final isCurrent = hex.toUpperCase() == widget.card.colorHex.toUpperCase();
                return GestureDetector(
                  onTap: () => widget.onColorChanged?.call(hex),
                  child: Container(
                    margin: const EdgeInsets.only(left: 5),
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: _parseCardBg(hex),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isCurrent
                            ? AppColors.accentPrimary
                            : Colors.black.withValues(alpha: 0.25),
                        width: isCurrent ? 2 : 1,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTextBody(Color textColor, Color subtextColor) {
    return TextField(
      controller: _contentController,
      onChanged: widget.onContentChanged,
      maxLines: null,
      expands: true,
      textAlignVertical: TextAlignVertical.top,
      style: TextStyle(
        fontSize: 13,
        height: 1.45,
        color: textColor,
      ),
      decoration: InputDecoration(
        hintText: 'Tulis ide, referensi, atau deskripsi karya...',
        hintStyle: TextStyle(
          color: subtextColor,
          fontSize: 12.5,
        ),
        isDense: true,
        contentPadding: EdgeInsets.zero,
        border: InputBorder.none,
      ),
    );
  }

  Widget _buildChecklistBody(Color textColor, Color subtextColor) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: widget.card.checklists.length,
            itemBuilder: (context, index) {
              final item = widget.card.checklists[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Row(
                  children: [
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: Checkbox(
                        value: item.isDone,
                        onChanged: (_) => _toggleChecklistItem(index),
                        activeColor: AppColors.accentPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        item.text,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: item.isDone ? subtextColor : textColor,
                          decoration: item.isDone
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 14),
                      color: subtextColor.withValues(alpha: 0.6),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => _removeChecklistItem(index),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        // Add new checklist item input
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _newItemController,
                style: TextStyle(fontSize: 12, color: textColor),
                decoration: InputDecoration(
                  hintText: '+ Tambah tugas...',
                  hintStyle: TextStyle(fontSize: 12, color: subtextColor),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 4),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _addChecklistItem(),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_rounded, size: 18),
              color: AppColors.accentPrimary,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: _addChecklistItem,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFormatButton({
    required Key key,
    required String label,
    required String tooltip,
    required VoidCallback onTap,
    bool isBold = false,
    bool isItalic = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        key: key,
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
              color: const Color(0xFF1E293B),
            ),
          ),
        ),
      ),
    );
  }
}
