import 'package:dt_tracker_ai/l10n/app_localizations_en.dart';
import 'package:dt_tracker_ai/l10n/app_localizations_es.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'dashboard and authentication labels resolve in English and Spanish',
    () {
      final english = AppLocalizationsEn();
      final spanish = AppLocalizationsEs();

      expect(english.homeGreeting('Sam'), 'Hello, Sam');
      expect(spanish.homeGreeting('Sam'), 'Hola, Sam');
      expect(english.continueWithGoogle, 'Continue with Google');
      expect(spanish.continueWithGoogle, 'Continuar con Google');
      expect(english.invalidYear, 'Enter a valid year');
      expect(spanish.invalidYear, 'Ingresa un ano valido');
    },
  );
}
