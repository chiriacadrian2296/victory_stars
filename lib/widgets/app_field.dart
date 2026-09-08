import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_style.dart';

/// The small muted caption that sits above every field. Its own widget
/// because it appeared, hand-written and very slightly different, above
/// roughly fifteen fields across the app.
class AppFieldLabel extends StatelessWidget {
  const AppFieldLabel(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(fontSize: 13, color: context.colors.muted),
    );
  }
}

/// The app's one text input.
///
/// A plain [TextField] can follow two thirds of the field rule from the
/// theme alone (dark when empty, lit while focused) but not the third:
/// staying lit once it *holds* something. Only the widget with the
/// controller knows that, which is why every typed field goes through here
/// rather than through `TextField` directly — otherwise a filled name box
/// and a filled date picker, side by side in the same form, disagree about
/// whether being filled means anything.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.controller,
    this.hintText,
    this.minLines,
    this.maxLines = 1,
    this.autofocus = false,
    this.textInputAction,
    this.onChanged,
    this.prefixIcon,
  });

  final TextEditingController controller;
  final String? hintText;
  final int? minLines;
  final int? maxLines;
  final bool autofocus;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final Widget? prefixIcon;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late final FocusNode _focusNode = FocusNode()..addListener(_onFocusChanged);

  void _onFocusChanged() => setState(() {});

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    // Rebuilt against the controller rather than on every keystroke's own
    // setState: the border only has to change on the empty↔non-empty edge,
    // and this way a caller that doesn't pass onChanged still gets it.
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: widget.controller,
      builder: (context, value, _) {
        final state = fieldStateOf(
          hasValue: value.text.trim().isNotEmpty,
          focused: _focusNode.hasFocus,
        );
        // The glow can't go through InputDecoration, so it's painted behind
        // the field; the border itself still comes from the decoration so
        // the text/hint keep their normal insets.
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(kRadiusField),
            boxShadow: state == FieldState.focused
                ? goldGlow(colors, strength: 0.7, size: 40)
                : null,
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            autofocus: widget.autofocus,
            minLines: widget.minLines,
            maxLines: widget.maxLines,
            textInputAction: widget.textInputAction,
            onChanged: widget.onChanged,
            style: TextStyle(color: colors.text, fontSize: 15),
            decoration: InputDecoration(
              hintText: widget.hintText,
              prefixIcon: widget.prefixIcon,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(kRadiusField),
                borderSide: BorderSide(
                  color: fieldBorderColor(colors, state),
                  width: fieldBorderWidth(state),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// The app's one "tap to choose" field — a date, a constellation, a life
/// area, an icon. Looks and lights exactly like [AppTextField], because to
/// a user it's the same object: a box that's either empty or holds your
/// answer.
///
/// Its content is either [text] (with [icon] beside it) or, when
/// [iconOnly] is set, just the icon centered — the icon picker has nothing
/// readable to show once chosen, and an icon alone reads better there than
/// an icon next to an empty label slot.
class AppPickerField extends StatelessWidget {
  const AppPickerField({
    super.key,
    this.label,
    required this.hint,
    required this.icon,
    required this.text,
    required this.onTap,
    this.trailing,
    this.iconOnly = false,
  });

  /// Omitted when the surrounding form already labels this field some other
  /// way (a section heading, a row of two).
  final String? label;

  final String hint;
  final IconData icon;

  /// Null means empty — which is exactly what decides whether this field
  /// is lit.
  final String? text;

  final VoidCallback onTap;

  /// An affordance at the right edge, e.g. a chevron on a picker that opens
  /// a full list.
  final Widget? trailing;

  final bool iconOnly;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final filled = text != null;
    final state = fieldStateOf(hasValue: filled, focused: false);

    final field = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(kRadiusField),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: fieldDecoration(colors, state),
        child: iconOnly && filled
            ? Center(child: Icon(icon, size: 22, color: colors.gold))
            : Row(
                children: [
                  Icon(
                    icon,
                    size: filled ? 20 : 16,
                    color: filled ? colors.gold : colors.muted,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      text ?? hint,
                      style: TextStyle(
                        color: filled ? colors.text : colors.muted,
                        fontSize: 15,
                        fontWeight: filled
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  ?trailing,
                ],
              ),
      ),
    );

    if (label == null) return field;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppFieldLabel(label!),
        const SizedBox(height: 6),
        field,
      ],
    );
  }
}
