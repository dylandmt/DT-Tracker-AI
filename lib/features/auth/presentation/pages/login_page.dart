import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_constants.dart';
import '../../../../core/notifications/notification_service.dart';
import '../../../../core/permissions/permission_handler.dart';
import '../../../../core/permissions/permission_status.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/validators.dart';
import '../../../../injection_container.dart';
import '../../utils/permission_gate.dart';
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
      listener: (context, state) async {
        if (state.isAuthenticated) {
          final hasLocation = await sl<AppPermissionHandler>().isGranted(
            AppPermission.location,
          );
          final hasNotifications = await sl<NotificationService>()
              .notificationPermissionStatus()
              .then((status) => status.isGranted);
          if (!context.mounted) return;
          context.go(
            resolvePostAuthRoute(
              hasLocation: hasLocation,
              hasNotifications: hasNotifications,
            ),
          );
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
                      AuthHeader(
                        title: context.l10n.welcomeBack,
                        subtitle: context.l10n.signInToContinueTracking,
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
                          context.l10n.password,
                        ),
                        enabled: !state.isLoading,
                        onFieldSubmitted: (_) => _onLogin(),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: AuthTextButton(
                          text: context.l10n.forgotPassword,
                          onPressed: () {
                            context.push(RouteConstants.forgotPassword);
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                      AuthButton(
                        text: context.l10n.signIn,
                        onPressed: _onLogin,
                        isLoading: state.isLoading,
                      ),
                      const SizedBox(height: 24),
                      AuthLinkButton(
                        prefixText: context.l10n.dontHaveAccount,
                        linkText: context.l10n.signUp,
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
