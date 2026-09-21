import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_constants.dart';
import '../../../../core/onboarding/onboarding_controller.dart';
import '../../../../injection_container.dart';
import '../../../../l10n/app_localizations.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({required this.userId, super.key});

  final String userId;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _controller = PageController();
  var _index = 0;

  Future<void> _finish() async {
    await sl<OnboardingController>().completeGeneral(widget.userId);
    if (mounted) context.go(RouteConstants.splash);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final slides = [
      (
        Icons.directions_car_filled,
        l10n.onboardingVehiclesTitle,
        l10n.onboardingVehiclesBody,
      ),
      (Icons.map_outlined, l10n.onboardingMapTitle, l10n.onboardingMapBody),
      (
        Icons.notifications_active_outlined,
        l10n.onboardingAlertsTitle,
        l10n.onboardingAlertsBody,
      ),
      (
        Icons.verified_user_outlined,
        l10n.onboardingReadyTitle,
        l10n.onboardingReadyBody,
      ),
    ];
    final isLast = _index == slides.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(onPressed: _finish, child: Text(l10n.skip)),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: slides.length,
                  onPageChanged: (value) => setState(() => _index = value),
                  itemBuilder: (_, index) {
                    final slide = slides[index];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          slide.$1,
                          size: 96,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 32),
                        Text(
                          slide.$2,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          slide.$3,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  slides.length,
                  (index) => Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index == _index
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: isLast
                    ? _finish
                    : () => _controller.nextPage(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                      ),
                child: Text(isLast ? l10n.getStarted : l10n.next),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
