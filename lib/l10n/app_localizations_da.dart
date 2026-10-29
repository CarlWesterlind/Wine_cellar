// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Danish (`da`).
class AppLocalizationsDa extends AppLocalizations {
  AppLocalizationsDa([String locale = 'da']) : super(locale);

  @override
  String get appTitle => 'Vinkælderen';

  @override
  String get signIn => 'Log ind';

  @override
  String get signUp => 'Opret konto';

  @override
  String get email => 'E-mail';

  @override
  String get password => 'Adgangskode';

  @override
  String get switchToSignUp => 'Ingen konto? Opret en';

  @override
  String get switchToSignIn => 'Har du allerede en konto? Log ind';

  @override
  String get confirmEmailSent =>
      'Tjek din e-mail for at bekræfte din konto, og log derefter ind.';

  @override
  String get invalidEmail => 'Indtast en gyldig e-mailadresse';

  @override
  String get passwordTooShort => 'Adgangskoden skal være mindst 6 tegn';

  @override
  String get signOut => 'Log ud';

  @override
  String get settings => 'Indstillinger';

  @override
  String get language => 'Sprog';

  @override
  String get systemLanguage => 'Enhedens sprog';

  @override
  String signedInAs(String email) {
    return 'Logget ind som $email';
  }

  @override
  String get demoMode => 'Demotilstand – ændringer gemmes ikke.';

  @override
  String get searchHint => 'Søg navn, producent, region eller drue';

  @override
  String get allTypes => 'Alle typer';

  @override
  String get allStatuses => 'Alle drikkevinduer';

  @override
  String get emptyCellar => 'Din kælder er tom. Tilføj din første vin!';

  @override
  String get noResults => 'Ingen vine matcher søgningen.';

  @override
  String get addWine => 'Tilføj vin';

  @override
  String get editWine => 'Rediger vin';

  @override
  String get deleteWine => 'Slet vin';

  @override
  String deleteConfirm(String name) {
    return 'Slet \"$name\" fra kælderen?';
  }

  @override
  String get cancel => 'Annuller';

  @override
  String get delete => 'Slet';

  @override
  String get save => 'Gem';

  @override
  String get drinkOne => 'Drik en flaske';

  @override
  String bottleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count flasker',
      one: '1 flaske',
    );
    return '$_temp0';
  }

  @override
  String totalValue(String value) {
    return 'Værdi: $value';
  }

  @override
  String get wineName => 'Navn';

  @override
  String get producer => 'Producent';

  @override
  String get vintage => 'Årgang';

  @override
  String get wineType => 'Type';

  @override
  String get country => 'Land';

  @override
  String get region => 'Region';

  @override
  String get grapes => 'Druer';

  @override
  String get grapesHint => 'Adskil med komma';

  @override
  String get quantity => 'Antal flasker';

  @override
  String get price => 'Pris pr. flaske';

  @override
  String get location => 'Placering i kælderen';

  @override
  String get rack => 'Reol';

  @override
  String get shelf => 'Hylde';

  @override
  String get position => 'Position';

  @override
  String get drinkingWindow => 'Drikkevindue';

  @override
  String get drinkFrom => 'Drik fra (år)';

  @override
  String get drinkUntil => 'Drik senest (år)';

  @override
  String get notes => 'Noter';

  @override
  String get requiredField => 'Påkrævet';

  @override
  String get invalidNumber => 'Indtast et gyldigt tal';

  @override
  String get invalidYear => 'Indtast et gyldigt år';

  @override
  String get untilBeforeFrom => 'Må ikke være tidligere end \"drik fra\"';

  @override
  String get typeRed => 'Rød';

  @override
  String get typeWhite => 'Hvid';

  @override
  String get typeRose => 'Rosé';

  @override
  String get typeSparkling => 'Mousserende';

  @override
  String get typeDessert => 'Dessertvin';

  @override
  String get typeFortified => 'Hedvin';

  @override
  String get statusUnknown => 'Intet drikkevindue';

  @override
  String get statusTooEarly => 'For tidligt';

  @override
  String get statusReady => 'Klar til at drikke';

  @override
  String get statusPastPeak => 'Over toppen';

  @override
  String get retry => 'Prøv igen';

  @override
  String get errorNetwork =>
      'Kunne ikke oprette forbindelse. Tjek din internetforbindelse, og prøv igen.';

  @override
  String get errorServer =>
      'Serveren kunne ikke gennemføre anmodningen. Prøv igen senere.';

  @override
  String get errorInvalidData => 'Nogle af vinens oplysninger er ugyldige.';

  @override
  String get errorUnknown => 'Noget uventet gik galt. Prøv igen.';

  @override
  String get errorInvalidLogin => 'Forkert e-mail eller adgangskode.';

  @override
  String get errorEmailNotConfirmed =>
      'Bekræft din e-mailadresse, før du logger ind.';

  @override
  String get errorUserExists =>
      'Der findes allerede en konto med denne e-mailadresse.';

  @override
  String get errorWeakPassword => 'Vælg en stærkere adgangskode.';

  @override
  String get errorTooManyAttempts =>
      'For mange forsøg. Vent lidt, og prøv igen.';
}
