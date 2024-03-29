import 'package:fluent_ui/fluent_ui.dart';
import 'package:gap/gap.dart';
import 'package:remotecontrol_lib/logger.dart';

class LogBox extends StatefulWidget {
  const LogBox({super.key});

  @override
  State<LogBox> createState() => _LogBoxState();
}

class _LogBoxState extends State<LogBox> {
  final _logController = TextEditingController();
  late final ScrollController _scrollController;
  void Function(Level, String)? _logHandlder;
  bool isScrollToEnd = true;

  void log(String message) {
    // run only if widget is mounted
    if (!mounted) return;

    setState(() {
      _logController.text = '${_logController.text}$message\n';
      // keep at maximum 500 lines of text
      final lines = _logController.text.split('\n');
      if (lines.length > 500) {
        _logController.text = lines.skip(lines.length - 400).join('\n');
      }

      if (isScrollToEnd && _scrollController.hasClients) {
        Future.delayed(const Duration(milliseconds: 10), () async {
          // TODO: Disable text selection when scrolling
          await _scrollToEnd();
        });
        _logHandlder = (_, message) => log(message);
      }
    });
  }

  Future<void> _scrollToEnd() async {
    if (_scrollController.hasClients) {
      var maxScroll = _scrollController.position.maxScrollExtent;
      await _scrollController.animateTo(maxScroll,
          duration: const Duration(milliseconds: 100), curve: Curves.easeOut);
    }

    return;
  }

  _LogBoxState() {
    _scrollController = ScrollController();
  }

  @override
  void initState() {
    super.initState();

    if (_logHandlder == null) {
      _logHandlder = (_, message) => log(message);
      logger.subscribe(Level.trace, _logHandlder!);
    }
  }

  @override
  void dispose() {
    super.dispose();
    if (_logHandlder != null) {
      logger.unsubscribe(Level.trace, _logHandlder!);
    }
    _logController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: const Alignment(0.95, 0),
      fit: StackFit.passthrough,
      children: [
        TextBox(
          expands: true,
          maxLines: null,
          minLines: null,
          scrollController: _scrollController,
          controller: _logController,
          suffixMode: OverlayVisibilityMode.always,
          placeholder: 'Events will display here',
          textAlignVertical: TextAlignVertical.top,
          readOnly: true,
        ),
        _logController.text.isEmpty ? Container() : buildClearButton(),
      ],
    );
  }

  Padding buildClearButton() {
    final theme = FluentTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 5, right: 5),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          IconButton(
            icon: const Icon(FluentIcons.chrome_close),
            onPressed: () => setState(() => _logController.clear()),
          ),
          const Gap(5),
          IconButton(
            icon: const Icon(FluentIcons.double_chevron_down),
            key: const Key('scroll-to-end'),
            onPressed: () => setState(() {
              isScrollToEnd = !isScrollToEnd;
              if (isScrollToEnd) {
                _scrollToEnd();
              }
            }),
            style: ButtonStyle(
              backgroundColor: ButtonState.resolveWith((states) {
                return states.isDisabled
                    ? ButtonThemeData.buttonColor(context, states)
                    : uncheckedInputColor(theme, states);
              }),
            ),
          ),
        ],
      ),
    );
  }

  Color uncheckedInputColor(FluentThemeData style, Set<ButtonStates> states) {
    if (style.brightness == Brightness.light) {
      if (isScrollToEnd) return const Color(0xFF221D08).withOpacity(0.155);
      if (states.isDisabled) return style.inactiveColor;
      if (states.isPressing) return const Color(0xFF221D08).withOpacity(0.155);
      if (states.isHovering) return const Color(0xFF221D08).withOpacity(0.055);
      return Colors.transparent;
    } else {
      if (isScrollToEnd) return const Color(0xFFFFF3E8).withOpacity(0.080);
      if (states.isDisabled) return style.inactiveColor;
      if (states.isPressing) return const Color(0xFFFFF3E8).withOpacity(0.080);
      if (states.isHovering) return const Color(0xFFFFF3E8).withOpacity(0.12);
      return Colors.transparent;
    }
  }
}
