import 'package:fluent_ui/fluent_ui.dart';
import 'package:gap/gap.dart';

class TextButtonInput extends StatelessWidget {
  final void Function() onPressed;
  final String header;
  final String placeholder;
  final String? initialValue;
  final String buttonText;
  final AutovalidateMode? autovalidateMode;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final Icon? icon;
  final Icon? buttonIcon;
  final TextEditingController? controller;
  final bool enabled;
  final bool textInputEnabled;

  const TextButtonInput({
    super.key,
    required this.onPressed,
    required this.header,
    required this.placeholder,
    this.initialValue,
    required this.buttonText,
    this.autovalidateMode = AutovalidateMode.disabled,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.icon,
    this.buttonIcon,
    this.controller,
    this.enabled = true,
    this.textInputEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 150,
          child: InfoLabel(
            label: header,
            child: TextFormBox(
              placeholder: placeholder,
              controller: controller,
              autovalidateMode: AutovalidateMode.always,
              keyboardType: keyboardType,
              validator: validator,
              textInputAction: TextInputAction.next,
              initialValue: initialValue,
              enabled: enabled && textInputEnabled,
              prefix: icon != null
                  ? Padding(
                      padding: const EdgeInsetsDirectional.only(start: 8.0),
                      child: icon,
                    )
                  : null,
            ),
          ),
        ),
        const Gap(8),
        Padding(
          padding: const EdgeInsets.only(top: 27),
          child: SizedBox(
            width: 130,
            height: 32,
            child: FilledButton(
              onPressed: enabled ? onPressed : null,
              child: buttonIcon != null
                  ? Row(
                      children: [
                        buttonIcon!,
                        const Gap(5),
                        Text(buttonText),
                      ],
                    )
                  : Text(buttonText),
            ),
          ),
        ),
      ],
    );
  }
}
