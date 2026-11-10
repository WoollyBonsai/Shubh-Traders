import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../localization/app_locale.dart';

enum DualTextDisplayMode {
  stacked,
  inline,
}

class DualText extends ConsumerWidget {
  final String en;
  final String? hi;
  final TextStyle? style;
  final TextStyle? subStyle;
  final DualTextDisplayMode mode;
  final TextAlign textAlign;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisAlignment mainAxisAlignment;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool forceDual;

  const DualText({
    super.key,
    required this.en,
    this.hi,
    this.style,
    this.subStyle,
    this.mode = DualTextDisplayMode.stacked,
    this.textAlign = TextAlign.start,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.maxLines,
    this.overflow,
    this.forceDual = false,
  });

  const DualText.inline({
    super.key,
    required this.en,
    this.hi,
    this.style,
    this.subStyle,
    this.textAlign = TextAlign.start,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.maxLines,
    this.overflow,
    this.forceDual = false,
  }) : mode = DualTextDisplayMode.inline;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(appLocaleProvider);

    // If Hindi or English only is requested and not forced dual:
    if (!forceDual && lang == AppLanguage.english) {
      return Text(
        en,
        style: style,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
      );
    }

    if (!forceDual && lang == AppLanguage.hindi) {
      return Text(
        (hi != null && hi!.trim().isNotEmpty) ? hi! : en,
        style: style,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
      );
    }

    // Dual display mode (or when forceDual is true)
    if (hi == null || hi!.trim().isEmpty) {
      return Text(
        en,
        style: style,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
      );
    }

    if (mode == DualTextDisplayMode.inline) {
      return RichText(
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow ?? TextOverflow.clip,
        text: TextSpan(
          text: en,
          style: style ?? DefaultTextStyle.of(context).style,
          children: [
            TextSpan(
              text: ' / $hi',
              style: (subStyle ?? style ?? DefaultTextStyle.of(context).style).copyWith(
                fontWeight: FontWeight.normal,
                color: (style?.color ?? DefaultTextStyle.of(context).style.color)?.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      );
    }

    // Stacked mode
    final defaultStyle = DefaultTextStyle.of(context).style;
    final primaryStyle = style ?? defaultStyle;
    final secondaryStyle = subStyle ??
        primaryStyle.copyWith(
          fontSize: (primaryStyle.fontSize ?? 14.0) * 0.84,
          fontWeight: FontWeight.w400,
          color: (primaryStyle.color ?? defaultStyle.color)?.withValues(alpha: 0.75),
        );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Text(
          en,
          style: primaryStyle,
          textAlign: textAlign,
          maxLines: maxLines,
          overflow: overflow,
        ),
        const SizedBox(height: 1),
        Text(
          hi!,
          style: secondaryStyle,
          textAlign: textAlign,
          maxLines: maxLines,
          overflow: overflow,
        ),
      ],
    );
  }
}
