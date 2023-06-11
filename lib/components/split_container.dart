import 'package:fluent_ui/fluent_ui.dart';

enum Direction { horizontal, vertical }

class SplitContainer extends StatelessWidget {
  final Widget left;
  final Widget right;
  final Direction direction;

  const SplitContainer({
    Key? key,
    required this.left,
    required this.right,
    this.direction = Direction.horizontal,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
        child: direction == Direction.horizontal
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [Expanded(child: left), Expanded(child: right)],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [Expanded(child: left), Expanded(child: right)],
              ));
  }
}
