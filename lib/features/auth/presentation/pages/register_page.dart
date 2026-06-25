import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_constants.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/validators.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/auth_button.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_text_field.dart';

/// Registration page for creating new accounts
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _nameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  void _onRegister() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
            SignUpRequested(
              email: _emailController.text.trim(),
              password: _passwordController.text,
              displayName: _nameController.text.trim().isNotEmpty
                  ? _nameController.text.trim()
                  : null,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.isAuthenticated) {
          context.go(RouteConstants.home);
        } else if (state.hasError && state.errorMessage != null) {
          context.showErrorSnackBar(state.errorMessage!);
          context.read<AuthBloc>().add(ClearAuthError());
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
          ),
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const AuthHeader(
                        title: 'Create Account',
                        subtitle: 'Sign up to start tracking',
                      ),
                      NameTextField(
                        controller: _nameController,
                        focusNode: _nameFocusNode,
                        validator: Validators.validateDisplayName,
                        enabled: !state.isLoading,
                        onFieldSubmitted: (_) {
                          _emailFocusNode.requestFocus();
                        },
                      ),
                      const SizedBox(height: 16),
                      EmailTextField(
                        controller: _emailController,
                        focusNode: _emailFocusNode,
                        validator: Validators.validateEmail,
                        enabled: !state.isLoading,
                        onFieldSubmitted: (_) {
                          _passwordFocusNode.requestFocus();
                        },
                      ),
                      const SizedBox(height: 16),
                      PasswordTextField(
                        controller: _passwordController,
                        focusNode: _passwordFocusNode,
                        validator: Validators.validatePassword,
                        textInputAction: TextInputAction.next,
                        enabled: !state.isLoading,
                        onFieldSubmitted: (_) {
                          _confirmPasswordFocusNode.requestFocus();
                        },
                      ),
                      const SizedBox(height: 16),
                      PasswordTextField(
                        controller: _confirmPasswordController,
                        focusNode: _confirmPasswordFocusNode,
                        labelText: 'Confirm Password',
                        hintText: 'Confirm your password',
                        validator: (value) => Validators.validateConfirmPassword(
                          value,
                          _passwordController.text,
                        ),
                        enabled: !state.isLoading,
                        onFieldSubmitted: (_) => _onRegister(),
                      ),
                      const SizedBox(height: 32),
                      AuthButton(
                        text: 'Sign Up',
                        onPressed: _onRegister,
                        isLoading: state.isLoading,
                      ),
                      const SizedBox(height: 24),
                      AuthLinkButton(
                        prefixText: 'Already have an account?',
                        linkText: 'Sign In',
                        onPressed: () {
                          context.pop();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
