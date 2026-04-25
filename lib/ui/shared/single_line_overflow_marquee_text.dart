import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';

class SingleLineOverflowMarqueeText extends StatelessWidget {
  const SingleLineOverflowMarqueeText({
    required this.text,
    super.key,
    this.style,
    this.textAlign = TextAlign.start,
    this.blankSpace = 32,
    this.velocity = 36,
  });

  final String text;
  final TextStyle? style;
  final TextAlign textAlign;
  final double blankSpace;
  final double velocity;

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = DefaultTextStyle.of(context).style.merge(style);

    return LayoutBuilder(
      builder: (context, constraints) {
        if (!constraints.hasBoundedWidth) {
          return _buildText(effectiveStyle);
        }

        final textPainter = TextPainter(
          text: TextSpan(text: text, style: effectiveStyle),
          textDirection: Directionality.of(context),
          maxLines: 1,
        )..layout(maxWidth: double.infinity);

        if (textPainter.width <= constraints.maxWidth) {
          return _buildText(effectiveStyle);
        }

        return SizedBox(
          height: textPainter.preferredLineHeight,
          child: Marquee(
            text: text,
            style: effectiveStyle,
            blankSpace: blankSpace,
            velocity: velocity,
            pauseAfterRound: const Duration(milliseconds: 800),
            startPadding: 0,
            accelerationDuration: const Duration(milliseconds: 400),
            decelerationDuration: const Duration(milliseconds: 400),
          ),
        );
      },
    );
  }

  Widget _buildText(TextStyle effectiveStyle) {
    return Text(
      text,
      style: effectiveStyle,
      textAlign: textAlign,
      maxLines: 1,
      overflow: TextOverflow.clip,
    );
  }
}
