import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';

/// An info label lets the user know what an element of the ui
/// do as a short description of its functionality. It can be
/// either rendered above its child or on the side of it.
///
/// ![InfoLabel above a TextBox](https://docs.microsoft.com/en-us/windows/uwp/design/controls-and-patterns/images/text-box-ex1.png)
class InfoLabel2 extends StatelessWidget {
  /// Creates an info label.
  InfoLabel2({
    Key? key,
    this.child,
    required String label,
    TextStyle? labelStyle,
    this.isHeader = true,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  })  : label = TextSpan(text: label, style: labelStyle),
        super(key: key);

  /// Creates an info label.
  const InfoLabel2.rich({
    Key? key,
    this.child,
    required this.label,
    this.isHeader = true,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  }) : super(key: key);

  final InlineSpan label;

  /// The widget to apply the label.
  final Widget? child;

  /// Whether to render [header] above [child] or on the side of it.
  final bool isHeader;

  final CrossAxisAlignment crossAxisAlignment;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<InlineSpan>('label', label));
  }

  @override
  Widget build(BuildContext context) {
    final labelWidget = Text.rich(
      label,
      style: FluentTheme.maybeOf(context)?.typography.body,
    );
    return Flex(
      direction: isHeader ? Axis.vertical : Axis.horizontal,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: crossAxisAlignment,
      children: [
        if (isHeader)
          Padding(
            padding: const EdgeInsetsDirectional.only(bottom: 4.0),
            child: labelWidget,
          ),
        if (child != null) Flexible(child: child!),
        if (!isHeader)
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 4.0),
            child: labelWidget,
          ),
      ],
    );
  }
}
