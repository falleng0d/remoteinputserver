import 'package:fluent_ui/fluent_ui.dart';

enum Direction { horizontal, vertical }

class SplitContainer extends StatelessWidget {
  final Widget left;
  final Widget right;
  final Direction direction;
  final bool expandLeft, expandRight;

  const SplitContainer({
    Key? key,
    required this.left,
    required this.right,
    this.direction = Direction.horizontal,
    this.expandLeft = true,
    this.expandRight = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Flexible(
        child: direction == Direction.horizontal
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Flexible(
                    fit: expandLeft ? FlexFit.tight : FlexFit.loose,
                    child: left,
                  ),
                  Flexible(
                    fit: expandRight ? FlexFit.tight : FlexFit.loose,
                    child: right,
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Flexible(
                    fit: expandLeft ? FlexFit.tight : FlexFit.loose,
                    child: left,
                  ),
                  Flexible(
                    fit: expandRight ? FlexFit.tight : FlexFit.loose,
                    child: right,
                  ),
                ],
              ));
  }
}
