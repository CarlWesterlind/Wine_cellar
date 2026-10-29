// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Norwegian Bokmål (`nb`).
class AppLocalizationsNb extends AppLocalizations {
  AppLocalizationsNb([String locale = 'nb']) : super(locale);

  @override
  String get appTitle => 'Vinkjelleren';

  @override
  String get signIn => 'Logg inn';

  @override
  String get signUp => 'Opprett konto';

  @override
  String get email => 'E-post';

  @override
  String get password => 'Passord';

  @override
  String get switchToSignUp => 'Ingen konto? Opprett en';

  @override
  String get switchToSignIn => 'Har du allerede en konto? Logg inn';

  @override
  String get confirmEmailSent =>
      'Sjekk e-posten din for å bekrefte kontoen, og logg deretter inn.';

  @override
  String get invalidEmail => 'Skriv inn en gyldig e-postadresse';

  @override
  String get passwordTooShort => 'Passordet må være minst 6 tegn';

  @override
  String get signOut => 'Logg ut';

  @override
  String get settings => 'Innstillinger';

  @override
  String get language => 'Språk';

  @override
  String get systemLanguage => 'Enhetens språk';

  @override
  String signedInAs(String email) {
    return 'Logget inn som $email';
  }

  @override
  String get demoMode => 'Demomodus – endringer lagres ikke.';

  @override
  String get searchHint => 'Søk vin, produsent, drue…';

  @override
  String get emptyCellar =>
      'Legg til din første vin for å holde oversikt over flaskene dine.';

  @override
  String get noResults => 'Ingen viner samsvarer med søket.';

  @override
  String get addWine => 'Legg til vin';

  @override
  String get editWine => 'Rediger vin';

  @override
  String get deleteWine => 'Slett vin';

  @override
  String deleteConfirm(String name) {
    return 'Slette \"$name\" fra kjelleren?';
  }

  @override
  String get cancel => 'Avbryt';

  @override
  String get delete => 'Slett';

  @override
  String get save => 'Lagre';

  @override
  String get drinkOne => 'Drikk en flaske';

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
    return 'Verdi: $value';
  }

  @override
  String get wineName => 'Navn';

  @override
  String get producer => 'Produsent';

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
  String get grapesHint => 'Skill med komma';

  @override
  String get quantity => 'Antall flasker';

  @override
  String get price => 'Pris per flaske';

  @override
  String get location => 'Plassering i kjelleren';

  @override
  String get rack => 'Reol';

  @override
  String get shelf => 'Hylle';

  @override
  String get position => 'Posisjon';

  @override
  String get drinkingWindow => 'Drikkevindu';

  @override
  String get drinkFrom => 'Drikk fra (år)';

  @override
  String get drinkUntil => 'Drikk senest (år)';

  @override
  String get requiredField => 'Påkrevd';

  @override
  String get invalidNumber => 'Skriv inn et gyldig tall';

  @override
  String get invalidYear => 'Skriv inn et gyldig år';

  @override
  String get untilBeforeFrom => 'Kan ikke være tidligere enn \"drikk fra\"';

  @override
  String get typeRed => 'Rød';

  @override
  String get typeWhite => 'Hvit';

  @override
  String get typeRose => 'Rosé';

  @override
  String get typeSparkling => 'Musserende';

  @override
  String get typeDessert => 'Dessertvin';

  @override
  String get typeFortified => 'Sterkvin';

  @override
  String get statusUnknown => 'Intet drikkevindu';

  @override
  String get statusTooEarly => 'For tidlig';

  @override
  String get statusReady => 'Klar til å drikkes';

  @override
  String get statusPastPeak => 'Over toppen';

  @override
  String get retry => 'Prøv igjen';

  @override
  String get errorNetwork =>
      'Kunne ikke koble til. Sjekk internettforbindelsen og prøv igjen.';

  @override
  String get errorServer =>
      'Serveren kunne ikke fullføre forespørselen. Prøv igjen senere.';

  @override
  String get errorInvalidData => 'Noen av vinens opplysninger er ugyldige.';

  @override
  String get errorUnknown => 'Noe uventet gikk galt. Prøv igjen.';

  @override
  String get errorInvalidLogin => 'Feil e-post eller passord.';

  @override
  String get errorEmailNotConfirmed =>
      'Bekreft e-postadressen din før du logger inn.';

  @override
  String get errorUserExists =>
      'Det finnes allerede en konto med denne e-postadressen.';

  @override
  String get errorWeakPassword => 'Velg et sterkere passord.';

  @override
  String get errorTooManyAttempts =>
      'For mange forsøk. Vent litt og prøv igjen.';

  @override
  String get purchase => 'Kjøp';

  @override
  String get purchaseDate => 'Kjøpsdato';

  @override
  String get purchasedFrom => 'Kjøpt hos';

  @override
  String get purchasedFromHint => 'F.eks. Vinmonopolet eller en importør';

  @override
  String get chooseDate => 'Velg dato';

  @override
  String get clearDate => 'Fjern dato';

  @override
  String get myNotes => 'Mine notater';

  @override
  String get addNote => 'Nytt notat';

  @override
  String get editNote => 'Rediger notat';

  @override
  String get deleteNote => 'Slett notat';

  @override
  String get deleteNoteConfirm => 'Slette dette notatet?';

  @override
  String get noNotes => 'Ingen notater ennå. Skriv et når du åpner en flaske!';

  @override
  String get noteDate => 'Dato';

  @override
  String get rating => 'Vurdering';

  @override
  String ratingStars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stjerner',
      one: '1 stjerne',
    );
    return '$_temp0';
  }

  @override
  String get noteText => 'Notat';

  @override
  String get noteHint => 'Smak, duft, mat, anledning…';

  @override
  String get edit => 'Rediger';

  @override
  String get appearance => 'Utseende';

  @override
  String get themeSystem => 'Som telefonen';

  @override
  String get themeLight => 'Lyst';

  @override
  String get themeDark => 'Mørkt';

  @override
  String get emptyCellarTitle => 'Kjelleren din er tom';

  @override
  String get clearSearch => 'Tøm søk';

  @override
  String get clearFilters => 'Vis alle viner';

  @override
  String get all => 'Alle';
}
