import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_constants.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/validators.dart';
import '../../domain/entities/user.dart';
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

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _secondLastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _firstNameFocusNode = FocusNode();
  final _lastNameFocusNode = FocusNode();
  final _secondLastNameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();

  UserGender? _selectedGender;
  DateTime? _selectedBirthDate;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _secondLastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    _firstNameFocusNode.dispose();
    _lastNameFocusNode.dispose();
    _secondLastNameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();

    super.dispose();
  }

  Future<void> _selectBirthDate() async {
    final now = DateTime.now();

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate ?? DateTime(now.year - 18),
      firstDate: DateTime(1900),
      lastDate: now,
    );

    if (!mounted || selectedDate == null) {
      return;
    }

    setState(() {
      _selectedBirthDate = selectedDate;
    });
  }

  void _onRegister() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    if (_selectedGender == null) {
      context.showErrorSnackBar(context.l10n.selectGender);
      return;
    }

    if (_selectedBirthDate == null) {
      context.showErrorSnackBar(context.l10n.selectBirthDate);
      return;
    }

    final secondLastName = _secondLastNameController.text.trim();

    context.read<AuthBloc>().add(
      SignUpRequested(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        secondLastName: secondLastName.isEmpty ? null : secondLastName,
        gender: _selectedGender!,
        birthDate: _selectedBirthDate!,
      ),
    );
  }

  String _formatBirthDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.isAuthenticated) {
          // A newly created account must complete the initial setup.
          context.go(RouteConstants.setup);
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
                      AuthHeader(
                        title: context.l10n.createAccount,
                        subtitle: context.l10n.signUpToStartTracking,
                      ),

                      TextFormField(
                        controller: _firstNameController,
                        focusNode: _firstNameFocusNode,
                        enabled: !state.isLoading,
                        decoration: InputDecoration(
                          labelText: context.l10n.firstName,
                          hintText: context.l10n.enterYourFirstName,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return context.l10n.enterYourFirstName;
                          }

                          return null;
                        },
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) {
                          _lastNameFocusNode.requestFocus();
                        },
                      ),

                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _lastNameController,
                        focusNode: _lastNameFocusNode,
                        enabled: !state.isLoading,
                        decoration: InputDecoration(
                          labelText: context.l10n.lastName,
                          hintText: context.l10n.enterYourLastName,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return context.l10n.enterYourLastName;
                          }

                          return null;
                        },
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) {
                          _secondLastNameFocusNode.requestFocus();
                        },
                      ),

                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _secondLastNameController,
                        focusNode: _secondLastNameFocusNode,
                        enabled: !state.isLoading,
                        decoration: InputDecoration(
                          labelText: context.l10n.secondLastName,
                          hintText: context.l10n.enterYourSecondLastName,
                        ),
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) {
                          _emailFocusNode.requestFocus();
                        },
                      ),

                      const SizedBox(height: 16),

                      DropdownButtonFormField<UserGender>(
                        initialValue: _selectedGender,
                        decoration: InputDecoration(
                          labelText: context.l10n.gender,
                        ),
                        items: [
                          DropdownMenuItem(
                            value: UserGender.male,
                            child: Text(context.l10n.male),
                          ),
                          DropdownMenuItem(
                            value: UserGender.female,
                            child: Text(context.l10n.female),
                          ),
                          DropdownMenuItem(
                            value: UserGender.other,
                            child: Text(context.l10n.other),
                          ),
                          DropdownMenuItem(
                            value: UserGender.preferNotToSay,
                            child: Text(context.l10n.preferNotToSay),
                          ),
                        ],
                        onChanged: state.isLoading
                            ? null
                            : (value) {
                                setState(() {
                                  _selectedGender = value;
                                });
                              },
                        validator: (value) {
                          if (value == null) {
                            return context.l10n.selectGender;
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      InkWell(
                        onTap: state.isLoading ? null : _selectBirthDate,
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: context.l10n.birthDate,
                            suffixIcon: const Icon(Icons.calendar_today),
                          ),
                          child: Text(
                            _selectedBirthDate == null
                                ? context.l10n.selectBirthDate
                                : _formatBirthDate(_selectedBirthDate!),
                          ),
                        ),
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
                        labelText: context.l10n.confirmPassword,
                        hintText: context.l10n.confirmYourPassword,
                        validator: (value) =>
                            Validators.validateConfirmPassword(
                              value,
                              _passwordController.text,
                            ),
                        enabled: !state.isLoading,
                        onFieldSubmitted: (_) {
                          _onRegister();
                        },
                      ),

                      const SizedBox(height: 32),

                      AuthButton(
                        text: context.l10n.signUp,
                        onPressed: _onRegister,
                        isLoading: state.isLoading,
                      ),

                      const SizedBox(height: 24),

                      AuthLinkButton(
                        prefixText: context.l10n.alreadyHaveAccount,
                        linkText: context.l10n.signIn,
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
