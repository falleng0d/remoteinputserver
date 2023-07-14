import 'dart:math';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:remotecontrol/components/cursor_box.dart';
import 'package:remotecontrol_lib/logger.dart';
import 'package:remotecontrol_lib/virtualkeys.dart';

import '../controllers/input_controller.dart';
import '../services/win32_input_service.dart';
import 'measure_size.dart';

class CursorPreview extends StatefulWidget {
  final InputServerController server;

  const CursorPreview({Key? key, required this.server}) : super(key: key);

  @override
  State<CursorPreview> createState() => _CursorPreviewState();
}

class _CursorPreviewState extends State<CursorPreview> {
  double x = 0;
  double y = 0;
  Size size = Size.zero;
  ButtonActionType actionType = ButtonActionType.PRESS;

  @override
  initState() {
    super.initState();
    widget.server.setDebugEventHandler(inputEventHandler);
  }

  void inputEventHandler(InputReceivedEvent event, InputReceivedData data) {
    switch (data.runtimeType) {
      case MouseMoveReceivedData:
        var d = data as MouseMoveReceivedData;
        moveCursor(d.ajustedDeltaX, d.ajustedDeltaY);
        break;
      case MouseButtonReceivedData:
        var d = data as MouseButtonReceivedData;
        logger.trace("Mouse key pressed: ${d.key} ${d.state ?? 'PRESS'}");
        setState(() {
          actionType = d.state ?? ButtonActionType.PRESS;
        });
        break;
    }
  }

  Color stateToColor(ButtonActionType state) {
    switch (state) {
      case ButtonActionType.DOWN:
        return Colors.red;
      default:
        return Colors.blue;
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
      this.x = min(size.width / 2, max(this.x + (x / 10), -size.width / 2));
      this.y = min(size.height / 2, max(this.y + (y / 10), -size.height / 2));
    });
  }

  @override
  void dispose() {
    super.dispose();
    widget.server.clearDebugEventHandler(inputEventHandler);
  }

  @override
  Widget build(BuildContext context) {
    // x > -(width/2) and x < width/2

    return MeasureSize(
      onChange: (size) {
        setState(() {
          this.size = size;
        });
      },
      child: CursorBox(x: x, y: y, cursorColor: stateToColor(actionType)),
    );
  }
}
