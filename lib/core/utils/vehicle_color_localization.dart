import '../../l10n/app_localizations.dart';

/// Returns the localized label for the English color value stored with a vehicle.
String localizedVehicleColor(AppLocalizations l10n, String color) {
  return switch (color.toLowerCase()) {
    'white' => l10n.colorWhite,
    'black' => l10n.colorBlack,
    'silver' => l10n.colorSilver,
    'gray' || 'grey' => l10n.colorGray,
    'red' => l10n.colorRed,
    'blue' => l10n.colorBlue,
    'green' => l10n.colorGreen,
    'yellow' => l10n.colorYellow,
    'orange' => l10n.colorOrange,
    'brown' => l10n.colorBrown,
    'beige' => l10n.colorBeige,
    'gold' => l10n.colorGold,
    _ => color,
  };
}
