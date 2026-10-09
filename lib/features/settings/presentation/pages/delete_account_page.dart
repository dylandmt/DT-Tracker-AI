import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_constants.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

/// Explains the irreversible account deletion flow before confirmation.
class DeleteAccountPage extends StatelessWidget {
  const DeleteAccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.isUnauthenticated) {
          context.go(RouteConstants.login);
        }
        if (state.hasError && state.errorMessage != null) {
          context.showErrorSnackBar(state.errorMessage!);
        }
      },
      builder: (context, state) {
        final isDeleting = state.accountDeletionInProgress;

        return PopScope(
          canPop: !isDeleting,
          child: Scaffold(
            appBar: AppBar(title: Text(l10n.deleteAccount)),
            body: Stack(
              children: [
                SafeArea(
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: colorScheme.errorContainer,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                Icons.warning_amber_rounded,
                                color: colorScheme.error,
                                size: 32,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              l10n.deleteAccount,
                              style: textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              l10n.deleteAccountIntro,
                              style: textTheme.bodyLarge?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 32),
                            Text(
                              l10n.deleteAccountConsequencesTitle,
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _Consequence(
                              icon: Icons.person_off_outlined,
                              text: l10n.deleteAccountAccessConsequence,
                            ),
                            const SizedBox(height: 16),
                            _Consequence(
                              icon: Icons.delete_forever_outlined,
                              text: l10n.deleteAccountServerConsequence,
                            ),
                            const SizedBox(height: 16),
                            _Consequence(
                              icon: Icons.block_outlined,
                              text: l10n.deleteAccountIrreversibleConsequence,
                            ),
                          ],
                        ),
                      ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(color: colorScheme.outlineVariant),
                          ),
                        ),
                        child: SafeArea(
                          top: false,
                          minimum: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                          child: SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: isDeleting
                                  ? null
                                  : () => _showConfirmation(context),
                              style: FilledButton.styleFrom(
                                backgroundColor: colorScheme.error,
                                foregroundColor: colorScheme.onError,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),
                              icon: const Icon(Icons.delete_outline),
                              label: Text(l10n.deleteAccount),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isDeleting)
                  Positioned.fill(
                    child: ColoredBox(
                      color: const Color(0x99000000),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 16),
                            Text(
                              l10n.deletingAccount,
                              style: TextStyle(color: colorScheme.onPrimary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showConfirmation(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteAccountConfirmationTitle),
        content: Text(l10n.deleteAccountConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
            ),
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<AuthBloc>().add(AccountDeletionRequested());
            },
            child: Text(l10n.deleteAccount),
          ),
        ],
      ),
    );
  }
}

class _Consequence extends StatelessWidget {
  const _Consequence({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: colorScheme.error),
        const SizedBox(width: 12),
        Expanded(child: Text(text)),
      ],
    );
  }
}
