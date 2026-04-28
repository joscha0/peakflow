import 'package:flutter/widgets.dart';
import 'package:peakflow/l10n/generated/app_localizations.dart';

export 'package:peakflow/l10n/generated/app_localizations.dart';

extension AppLocalizationsBuildContext on BuildContext {
  AppLocalizations get l10n =>
      AppLocalizations.of(this) ?? lookupAppLocalizations(const Locale('en'));
}

extension AppLocalizationsSymptoms on AppLocalizations {
  String symptomLabel(String value) {
    switch (value) {
      case 'Cough':
        return symptomCough;
      case 'Cough night':
        return symptomCoughNight;
      case 'Wheezing breathing':
        return symptomWheezingBreathing;
      case 'Shortness of breath':
        return symptomShortnessOfBreath;
      case 'Difficult breathing':
        return symptomDifficultBreathing;
      case 'Chest tightness or pain':
        return symptomChestTightnessOrPain;
      case 'Unable to work':
        return symptomUnableToWork;
      default:
        return value;
    }
  }
}
