import 'dart:math';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:get/get.dart';

class CursorBox extends StatelessWidget {
  final double _x, _y;
  final Alignment anchor;
  final double cursorSize;

  const CursorBox({
    Key? key,
    required double x,
    required double y,
    this.anchor = Alignment.center,
    this.cursorSize = 10,
  })  : _y = y,
        _x = x,
        super(key: key);

  double x(BoxConstraints constraints) {
    if (anchor == Alignment.center) {
      double centerX = constraints.maxWidth / 2;
      return min(centerX + _x, constraints.maxWidth - cursorSize);
    }

    return _x;
  }

  double y(BoxConstraints constraints) {
    if (anchor == Alignment.center) {
      double centerY = constraints.maxHeight / 2;
      return min(centerY + _y, constraints.maxHeight - cursorSize);
    }

    return _y;
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
                    color: context.theme.primaryColor,
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
