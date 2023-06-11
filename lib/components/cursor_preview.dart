import 'package:fluent_ui/fluent_ui.dart';
import 'package:remotecontrol/components/cursor_box.dart';

class CursorPreview extends StatelessWidget {
  const CursorPreview({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const CursorBox(
      x: -100,
      y: -20,
    );
  }
}
