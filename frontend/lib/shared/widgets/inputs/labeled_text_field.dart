import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';

class LabeledTextField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final bool readOnly;
  final VoidCallback? onTap;
  final IconData? icon;
  final EdgeInsetsGeometry padding;
  final bool obscureText;
  final TextInputAction? textInputAction;
  final bool isRequired;

  const LabeledTextField({
    Key? key,
    required this.label,
    required this.controller,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.readOnly = false,
    this.onTap,
    this.icon,
    this.padding = const EdgeInsets.only(bottom: 16),
    this.obscureText = false,
    this.textInputAction,
    this.isRequired = false,
  }) : super(key: key);

  @override
  State<LabeledTextField> createState() => _LabeledTextFieldState();
}

class _LabeledTextFieldState extends State<LabeledTextField> {
  String? errorText;
  late FocusNode _focusNode;
  late bool _obscureText;

  final maskFormatter = MaskTextInputFormatter(
    mask: '+7 (###) ### ## ##',
    filter: {"#": RegExp(r'\d')},
  );

  bool get isPhone => widget.keyboardType == TextInputType.phone;
  bool get isINN =>
      widget.keyboardType == TextInputType.number &&
          widget.label.toLowerCase().contains('инн');

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _obscureText = widget.obscureText;

    _focusNode.addListener(() {
      if (isPhone && _focusNode.hasFocus) {
        if (widget.controller.text.isEmpty) {
          widget.controller.text = '+7 ';
          widget.controller.selection = TextSelection.fromPosition(
            TextPosition(offset: widget.controller.text.length),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  String? _validatePhone(String? value) {
    if (value == null ||
        value.trim().isEmpty ||
        value == '+7 ' ||
        value == '+7') {
      return 'Введите номер телефона';
    }
    if (!maskFormatter.isFill()) {
      return 'Введите полный номер телефона';
    }
    return null;
  }

  String? _validateINN(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Введите ИНН';
    } else if (value.length != 10 && value.length != 12) {
      return 'ИНН должен содержать 10 или 12 цифр';
    } else if (!RegExp(r'^\d+$').hasMatch(value)) {
      return 'ИНН должен содержать только цифры';
    }
    return null;
  }

  String? _runValidators(String? value, {bool fromValidator = false}) {
    String? newError;
    if (isPhone) {
      newError = _validatePhone(value);
    } else if (isINN) {
      newError = _validateINN(value);
    } else if (widget.validator != null) {
      newError = widget.validator!(value);
    }

    void updateError() {
      if (errorText != newError) {
        setState(() => errorText = newError);
      }
    }

    if (fromValidator) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) updateError();
      });
    } else {
      updateError();
    }

    return newError;
  }

  void _onChanged(String val) {
    _runValidators(val);
  }

  @override
  Widget build(BuildContext context) {
    final inputFormatters = <TextInputFormatter>[];

    if (isPhone) {
      inputFormatters.add(maskFormatter);
    } else if (isINN) {
      inputFormatters.add(FilteringTextInputFormatter.digitsOnly);
      inputFormatters.add(LengthLimitingTextInputFormatter(12));
    }

    return Padding(
      padding: widget.padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 6, left: 4),
            child: RichText(
              text: TextSpan(
                text: widget.label,
                style: AppTextStyles.formLabel.copyWith(color: AppColors.textDark),
                children: [
                  if (widget.isRequired)
                    const TextSpan(
                      text: ' *',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12.84),
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              child: SizedBox(
                height: 50,
                child: TextFormField(
                  focusNode: _focusNode,
                  controller: widget.controller,
                  keyboardType: widget.keyboardType,
                  readOnly: widget.readOnly,
                  obscureText: _obscureText,
                  onTap: widget.onTap,
                  inputFormatters: inputFormatters,
                  textInputAction: widget.textInputAction,
                  decoration: InputDecoration(
                    hintText: isPhone ? '+7 (980) 001 01 01' : widget.label,
                    hintStyle: AppTextStyles.formLabel,
                    prefixIcon: widget.icon != null
                        ? Icon(widget.icon, size: 20, color: AppColors.primary)
                        : null,
                    suffixIcon: widget.obscureText
                        ? Tooltip(
                            message: _obscureText ? 'Показать пароль' : 'Скрыть пароль',
                            preferBelow: false,
                            child: IconButton(
                              onPressed: () {
                                setState(() {
                                  _obscureText = !_obscureText;
                                });
                              },
                              icon: Icon(
                                _obscureText
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: AppColors.primary,
                              ),
                            ),
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.circular(12.84),
                    ),
                    contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    errorText: null,
                    errorStyle: const TextStyle(height: 0, fontSize: 0),
                    fillColor: AppColors.white,
                    filled: true,
                  ),
                  style: AppTextStyles.formInput,
                  onChanged: _onChanged,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: (value) => _runValidators(value, fromValidator: true),
                ),
              ),
            ),
          ),
          if (errorText != null)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 12),
              child: Text(
                errorText!,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                  height: 1.2,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
