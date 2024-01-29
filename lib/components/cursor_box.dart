import 'dart:ui';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:get/get.dart';

class CursorBox extends StatelessWidget {
  final double _x, _y;
  final Alignment anchor;
  final double cursorSize;
  final Color? cursorColor;

  const CursorBox({
    super.key,
    required double x,
    required double y,
    this.anchor = Alignment.center,
    this.cursorSize = 10,
    this.cursorColor,
  })  : _y = y,
        _x = x;

  double x(BoxConstraints constraints) {
    double offset = 0;
    if (anchor == Alignment.center) {
      offset = constraints.maxWidth / 2;
    }

    return clampDouble(_x + offset, 0, constraints.maxWidth - cursorSize);
  }

  double y(BoxConstraints constraints) {
    double offset = 0;
    if (anchor == Alignment.center) {
      offset = constraints.maxHeight / 2;
    }

    return clampDouble(_y + offset, 0, constraints.maxHeight - cursorSize);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.maxFinite,
      height: double.maxFinite,
      decoration: BoxDecoration(
        border: Border.all(
          color: context.theme.primaryColor,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(5),
      ),
      // A circle absolute positioned where the cursor is
      child: LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) {
        return Stack(
          children: [
            Positioned(
              left: x(constraints),
              top: y(constraints),
              child: SizedBox(
                width: cursorSize,
                height: cursorSize,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 1, maxHeight: 1),
                  decoration: BoxDecoration(
                    color: cursorColor ?? context.theme.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  width: 1.0,
                  height: 1.0,
                  padding: const EdgeInsets.all(5),
                ),
              ),
            )
          ],
        );
      }),
    );
  }
}
