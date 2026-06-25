import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/validators.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/auth_button.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_text_field.dart';

/// Forgot password page for sending password reset emails
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _onSendReset() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
            PasswordResetRequested(
              email: _emailController.text.trim(),
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.status == AuthStatus.passwordResetSent) {
          setState(() {
            _emailSent = true;
          });
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
                child: _emailSent
                    ? _buildSuccessContent(context)
                    : _buildFormContent(context, state),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFormContent(BuildContext context, AuthState state) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AuthHeader(
            title: 'Reset Password',
            subtitle: 'Enter your email to receive a password reset link',
          ),
          EmailTextField(
            controller: _emailController,
            validator: Validators.validateEmail,
            enabled: !state.isLoading,
            onFieldSubmitted: (_) => _onSendReset(),
          ),
          const SizedBox(height: 32),
          AuthButton(
            text: 'Send Reset Link',
            onPressed: _onSendReset,
            isLoading: state.isLoading,
          ),
          const SizedBox(height: 16),
          AuthButton(
            text: 'Back to Sign In',
            onPressed: () => context.pop(),
            isOutlined: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessContent(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(
          Icons.mark_email_read_outlined,
          size: 80,
          color: colorScheme.primary,
        ),
        const SizedBox(height: 24),
        Text(
          'Check Your Email',
          style: textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'We\'ve sent a password reset link to:',
          style: textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          _emailController.text.trim(),
          style: textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(
                'Check your inbox and follow the link to reset your password.',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'If you don\'t see the email, check your spam folder.',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        AuthButton(
          text: 'Back to Sign In',
          onPressed: () => context.pop(),
        ),
        const SizedBox(height: 16),
        AuthButton(
          text: 'Resend Email',
          onPressed: () {
            setState(() {
              _emailSent = false;
            });
          },
          isOutlined: true,
        ),
      ],
    );
  }
}
