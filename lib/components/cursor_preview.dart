import 'package:fluent_ui/fluent_ui.dart';
import 'package:remotecontrol/components/cursor_box.dart';
import 'package:remotecontrol_lib/logger.dart';

import '../controllers/input_controller.dart';
import '../services/win32_input_service.dart';

class CursorPreview extends StatefulWidget {
  final InputServerController server;

  const CursorPreview({Key? key, required this.server}) : super(key: key);

  @override
  State<CursorPreview> createState() => _CursorPreviewState();
}

class _CursorPreviewState extends State<CursorPreview> {
  double x = 0;
  double y = 0;

  @override
  initState() {
    super.initState();
    widget.server.setDebugEventHandler(inputEventHandler);
  }

  void inputEventHandler(InputReceivedEvent event, InputReceivedData data) {
    switch (data.runtimeType) {
      case MouseInputReceivedData:
        var d = data as MouseInputReceivedData;
        moveCursor(d.ajustedDeltaX, d.ajustedDeltaY);
        break;
      case MouseKeyInputReceivedData:
        var d = data as MouseKeyInputReceivedData;
        logger.trace("Mouse key pressed: ${d.key} ${d.state ?? ''}");
        break;
    }
  }

  void setCursorPos(double x, double y) {
    setState(() {
      this.x = x;
      this.y = y;
    });
  }

  void moveCursor(double x, double y) {
    setState(() {
      this.x += x / 10;
      this.y += y / 10;
    });
  }

  @override
  void dispose() {
    super.dispose();
    widget.server.clearDebugEventHandler(inputEventHandler);
  }

  @override
  Widget build(BuildContext context) {
    return CursorBox(
      x: x,
      y: y,
    );
  }
}
