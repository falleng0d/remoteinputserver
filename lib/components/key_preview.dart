import 'package:fluent_ui/fluent_ui.dart';

import '../controllers/input_controller.dart';
import '../services/win32_input_service.dart';

class KeyHistoryPreview extends StatefulWidget {
  final InputServerController server;

  const KeyHistoryPreview({Key? key, required this.server}) : super(key: key);

  @override
  _KeyHistoryPreviewState createState() => _KeyHistoryPreviewState();
}

class _KeyHistoryPreviewState extends State<KeyHistoryPreview> {
  List<String> keys = ['A', 'B', 'C'];

  @override
  initState() {
    super.initState();
    widget.server.setDebugEventHandler(inputEventHandler);
  }

  void inputEventHandler(InputReceivedEvent event, InputReceivedData data) {
    switch (data.runtimeType) {
      case KeyInputReceivedData:
        var d = data as KeyInputReceivedData;
        setState(() {
          // add to front of list
          keys.insert(0, "${d.virtualKeyCode} ${d.state ?? ''}");
          if (keys.length > 10) {
            keys.removeLast();
          }
        });
        break;
    }
  }

  @override
  void dispose() {
    super.dispose();
    widget.server.clearDebugEventHandler(inputEventHandler);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Flex(
            direction: Axis.vertical,
            children: [
              Container(
                constraints: const BoxConstraints(maxHeight: 40),
                margin: const EdgeInsets.fromLTRB(0, 10, 0, 0),
                child: ListView.builder(
                  itemCount: keys.length,
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (context, index) {
                    return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        constraints: const BoxConstraints(maxWidth: 40),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Center(
                          child: Text(keys[index],
                              style: const TextStyle(color: Colors.white)),
                        ));
                  },
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ],
    );
  }
}
