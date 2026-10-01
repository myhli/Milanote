import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../models/color_card.dart';

/// Interactive UI widget rendering a Color Swatch Palette Card with 1 to 8 swatches,
/// 1-click HEX clipboard copying, visual color picker, and editable palette title.
class ColorCardWidget extends StatefulWidget {
  final ColorCard card;
  final bool isSelected;
  final ValueChanged<String>? onTitleChanged;
  final ValueChanged<List<String>>? onColorsChanged;

  const ColorCardWidget({
    super.key,
    required this.card,
    this.isSelected = false,
    this.onTitleChanged,
    this.onColorsChanged,
  });

  @override
  State<ColorCardWidget> createState() => _ColorCardWidgetState();
}

class _ColorCardWidgetState extends State<ColorCardWidget> {
  late final TextEditingController _titleController;
  String? _copiedHex;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.card.title);
  }

  @override
  void didUpdateWidget(covariant ColorCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.card.title != widget.card.title &&
        _titleController.text != widget.card.title) {
      _titleController.text = widget.card.title;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Color _parseHex(String hex) {
    try {
      final clean = hex.replaceAll('#', '');
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return const Color(0xFF64748B);
    }
  }

  String _toHex(Color color) {
    final hexString = color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase();
    return '#$hexString';
  }

  String _toRgb(Color color) {
    final argb = color.toARGB32();
    final r = (argb >> 16) & 0xFF;
    final g = (argb >> 8) & 0xFF;
    final b = argb & 0xFF;
    return 'rgb($r, $g, $b)';
  }

  Future<void> _copyHexToClipboard(String hex) async {
    await Clipboard.setData(ClipboardData(text: hex));
    if (!mounted) return;

    setState(() => _copiedHex = hex);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('HEX disalin ke clipboard: $hex'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        width: 250,
      ),
    );

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _copiedHex = null);
    });
  }

  Future<void> _copyRgbToClipboard(String rgb) async {
    await Clipboard.setData(ClipboardData(text: rgb));
    if (!mounted) return;

    setState(() => _copiedHex = rgb);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('RGB disalin ke clipboard: $rgb'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        width: 250,
      ),
    );

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _copiedHex = null);
    });
  }

  Future<void> _openColorPickerDialog(int index) async {
    final currentColor = _parseHex(widget.card.colorsHex[index]);
    Color selectedColor = currentColor;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Pilih Warna Swatch', style: TextStyle(fontSize: 16)),
          content: SingleChildScrollView(
            child: ColorPicker(
              color: selectedColor,
              onColorChanged: (newColor) => selectedColor = newColor,
              width: 36,
              height: 36,
              borderRadius: 8,
              spacing: 6,
              runSpacing: 6,
              wheelDiameter: 180,
              heading: Text(
                'Palet Cepat',
                style: Theme.of(ctx).textTheme.titleSmall,
              ),
              subheading: Text(
                'Roda Warna & Nuansa',
                style: Theme.of(ctx).textTheme.titleSmall,
              ),
              wheelSubheading: Text(
                'Pilih Nuansa Terang/Gelap',
                style: Theme.of(ctx).textTheme.titleSmall,
              ),
              showColorCode: true,
              colorCodeHasColor: true,
              pickersEnabled: const <ColorPickerType, bool>{
                ColorPickerType.both: false,
                ColorPickerType.primary: true,
                ColorPickerType.accent: true,
                ColorPickerType.wheel: true,
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Pilih'),
            ),
          ],
        );
      },
    );

    if (result == true && mounted) {
      final updated = List<String>.from(widget.card.colorsHex);
      updated[index] = _toHex(selectedColor);
      widget.onColorsChanged?.call(updated);
    }
  }

  void _addSwatch() {
    if (widget.card.colorsHex.length >= 8) return;
    final updated = List<String>.from(widget.card.colorsHex)..add('#4A90E2');
    widget.onColorsChanged?.call(updated);
  }

  void _removeSwatch(int index) {
    if (widget.card.colorsHex.length <= 1) return;
    final updated = List<String>.from(widget.card.colorsHex)..removeAt(index);
    widget.onColorsChanged?.call(updated);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Editable Title
          Row(
            children: [
              const Icon(Icons.palette_outlined, size: 16, color: AppColors.accentPrimary),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _titleController,
                  onChanged: widget.onTitleChanged,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Nama Palet Warna...',
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                  ),
                ),
              ),
              if (widget.card.colorsHex.length < 8)
                IconButton(
                  icon: const Icon(Icons.add_rounded, size: 18),
                  tooltip: 'Tambah Swatch (Maks 8)',
                  color: AppColors.accentPrimary,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: _addSwatch,
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Swatches Row
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: List.generate(widget.card.colorsHex.length, (index) {
                final hex = widget.card.colorsHex[index];
                final color = _parseHex(hex);

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Swatch Box
                        Expanded(
                          child: InkWell(
                            onTap: () => _openColorPickerDialog(index),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  width: 1,
                                ),
                              ),
                              child: Stack(
                                children: [
                                  if (widget.isSelected && widget.card.colorsHex.length > 1)
                                    Positioned(
                                      top: 2,
                                      right: 2,
                                      child: GestureDetector(
                                        onTap: () => _removeSwatch(index),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(alpha: 0.5),
                                            shape: BoxShape.circle,
                                          ),
                                          padding: const EdgeInsets.all(2),
                                          child: const Icon(
                                            Icons.close_rounded,
                                            size: 10,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 3),

                        // 1-Click Copy HEX button
                        InkWell(
                          key: Key('copy_hex_${index}_btn'),
                          onTap: () => _copyHexToClipboard(hex),
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 1),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _copiedHex == hex ? Icons.check_rounded : Icons.copy_rounded,
                                    size: 9,
                                    color: _copiedHex == hex ? AppColors.accentSuccess : AppColors.darkTextSecondary,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    hex,
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w600,
                                      color: _copiedHex == hex ? AppColors.accentSuccess : textColor,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // 1-Click Copy RGB button (US-007 & FR-10)
                        InkWell(
                          key: Key('copy_rgb_${index}_btn'),
                          onTap: () => _copyRgbToClipboard(_toRgb(color)),
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 1),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                _toRgb(color).replaceFirst('rgb(', '').replaceFirst(')', ''),
                                style: TextStyle(
                                  fontSize: 8.0,
                                  fontWeight: FontWeight.w500,
                                  color: _copiedHex == _toRgb(color)
                                      ? AppColors.accentSuccess
                                      : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
