import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';

class ScrollingText extends StatelessWidget {
  final String text;
  final TextStyle? style;

  const ScrollingText(this.text, {super.key, this.style});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textPainter = TextPainter(
          text: TextSpan(text: text, style: style),
          maxLines: 1,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: double.infinity);

        final height = textPainter.height;

        if (textPainter.width <= constraints.maxWidth * 0.9) {
          return SizedBox(
            height: height,
            width: constraints.maxWidth,
            child: Text(
              text,
              style: style,
              maxLines: 1,
              overflow: TextOverflow.visible,
            ),
          );
        } else {
          return SizedBox(
            height: height,
            width: constraints.maxWidth,
            child: Marquee(
              text: text,
              style: style,
              scrollAxis: Axis.horizontal,
              velocity: 30.0,
              blankSpace: 20.0,
            ),
          );
        }
      },
    );
  }
}
