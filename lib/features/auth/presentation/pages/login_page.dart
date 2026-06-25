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

/// Login page for email/password authentication
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  void _onLogin() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
            SignInRequested(
              email: _emailController.text.trim(),
              password: _passwordController.text,
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
                        title: 'Welcome Back',
                        subtitle: 'Sign in to continue tracking',
                      ),
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
                        validator: (value) => Validators.validateRequired(
                          value,
                          'Password',
                        ),
                        enabled: !state.isLoading,
                        onFieldSubmitted: (_) => _onLogin(),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: AuthTextButton(
                          text: 'Forgot Password?',
                          onPressed: () {
                            context.push(RouteConstants.forgotPassword);
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                      AuthButton(
                        text: 'Sign In',
                        onPressed: _onLogin,
                        isLoading: state.isLoading,
                      ),
                      const SizedBox(height: 24),
                      AuthLinkButton(
                        prefixText: "Don't have an account?",
                        linkText: 'Sign Up',
                        onPressed: () {
                          context.push(RouteConstants.register);
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
