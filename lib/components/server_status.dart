import 'package:fluent_ui/fluent_ui.dart';

enum ServerStatus { online, offline }

class ServerStatusText extends StatelessWidget {
  final ServerStatus status;

  const ServerStatusText(
      this.status, {
        Key? key,
      }) : super(key: key);

  get statusColor {
    switch (status) {
      case ServerStatus.online:
        return Colors.green;
      case ServerStatus.offline:
        return Colors.red;
    }
  }

  get statusText {
    switch (status) {
      case ServerStatus.online:
        return "Online";
      case ServerStatus.offline:
        return "Offline";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          "Status: ",
          style: TextStyle(
            fontSize: 16,
          ),
        ),
        Text(
          statusText,
          style: TextStyle(
            color: statusColor,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Container(
          margin: const EdgeInsets.only(left: 7),
          width: 17.0,
          height: 17.0,
          decoration: BoxDecoration(
            color: statusColor,
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }
}
