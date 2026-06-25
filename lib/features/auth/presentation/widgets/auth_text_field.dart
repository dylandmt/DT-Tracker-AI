import 'package:flutter/material.dart';

/// Custom text field for authentication forms
class AuthTextField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final IconData? prefixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final String? Function(String?)? validator;
  final void Function(String)? onFieldSubmitted;
  final bool enabled;
  final int maxLines;
  final FocusNode? focusNode;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.labelText,
    this.hintText,
    this.prefixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.validator,
    this.onFieldSubmitted,
    this.enabled = true,
    this.maxLines = 1,
    this.focusNode,
  });

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      obscureText: widget.obscureText ? _obscureText : false,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      enabled: widget.enabled,
      maxLines: widget.obscureText ? 1 : widget.maxLines,
      validator: widget.validator,
      onFieldSubmitted: widget.onFieldSubmitted,
      decoration: InputDecoration(
        labelText: widget.labelText,
        hintText: widget.hintText,
        prefixIcon: widget.prefixIcon != null
            ? Icon(widget.prefixIcon)
            : null,
        suffixIcon: widget.obscureText
            ? IconButton(
                icon: Icon(
                  _obscureText ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
              )
            : null,
      ),
    );
  }
}

/// Email text field with preset configuration
class EmailTextField extends StatelessWidget {
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final void Function(String)? onFieldSubmitted;
  final bool enabled;
  final FocusNode? focusNode;

  const EmailTextField({
    super.key,
    required this.controller,
    this.validator,
    this.onFieldSubmitted,
    this.enabled = true,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return AuthTextField(
      controller: controller,
      labelText: 'Email',
      hintText: 'Enter your email',
      prefixIcon: Icons.email_outlined,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      validator: validator,
      onFieldSubmitted: onFieldSubmitted,
      enabled: enabled,
      focusNode: focusNode,
    );
  }
}

/// Password text field with preset configuration
class PasswordTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final String? Function(String?)? validator;
  final void Function(String)? onFieldSubmitted;
  final bool enabled;
  final TextInputAction textInputAction;
  final FocusNode? focusNode;

  const PasswordTextField({
    super.key,
    required this.controller,
    this.labelText = 'Password',
    this.hintText = 'Enter your password',
    this.validator,
    this.onFieldSubmitted,
    this.enabled = true,
    this.textInputAction = TextInputAction.done,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return AuthTextField(
      controller: controller,
      labelText: labelText,
      hintText: hintText,
      prefixIcon: Icons.lock_outlined,
      obscureText: true,
      keyboardType: TextInputType.visiblePassword,
      textInputAction: textInputAction,
      validator: validator,
      onFieldSubmitted: onFieldSubmitted,
      enabled: enabled,
      focusNode: focusNode,
    );
  }
}

/// Name text field with preset configuration
class NameTextField extends StatelessWidget {
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final void Function(String)? onFieldSubmitted;
  final bool enabled;
  final FocusNode? focusNode;

  const NameTextField({
    super.key,
    required this.controller,
    this.validator,
    this.onFieldSubmitted,
    this.enabled = true,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return AuthTextField(
      controller: controller,
      labelText: 'Full Name',
      hintText: 'Enter your full name',
      prefixIcon: Icons.person_outlined,
      keyboardType: TextInputType.name,
      textInputAction: TextInputAction.next,
      validator: validator,
      onFieldSubmitted: onFieldSubmitted,
      enabled: enabled,
      focusNode: focusNode,
    );
  }
}
