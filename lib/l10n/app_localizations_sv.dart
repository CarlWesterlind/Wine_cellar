// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Swedish (`sv`).
class AppLocalizationsSv extends AppLocalizations {
  AppLocalizationsSv([String locale = 'sv']) : super(locale);

  @override
  String get appTitle => 'Vinkällaren';

  @override
  String get signIn => 'Logga in';

  @override
  String get signUp => 'Skapa konto';

  @override
  String get email => 'E-post';

  @override
  String get password => 'Lösenord';

  @override
  String get switchToSignUp => 'Inget konto? Skapa ett';

  @override
  String get switchToSignIn => 'Har du redan ett konto? Logga in';

  @override
  String get confirmEmailSent =>
      'Kolla din e-post för att bekräfta kontot och logga sedan in.';

  @override
  String get invalidEmail => 'Ange en giltig e-postadress';

  @override
  String get passwordTooShort => 'Lösenordet måste vara minst 6 tecken';

  @override
  String get signOut => 'Logga ut';

  @override
  String get settings => 'Inställningar';

  @override
  String get language => 'Språk';

  @override
  String get systemLanguage => 'Enhetens språk';

  @override
  String signedInAs(String email) {
    return 'Inloggad som $email';
  }

  @override
  String get demoMode => 'Demoläge – ändringar sparas inte.';

  @override
  String get searchHint => 'Sök namn, producent, region eller druva';

  @override
  String get allTypes => 'Alla typer';

  @override
  String get allStatuses => 'Alla drickfönster';

  @override
  String get emptyCellar => 'Din källare är tom. Lägg till ditt första vin!';

  @override
  String get noResults => 'Inga viner matchar sökningen.';

  @override
  String get addWine => 'Lägg till vin';

  @override
  String get editWine => 'Redigera vin';

  @override
  String get deleteWine => 'Ta bort vin';

  @override
  String deleteConfirm(String name) {
    return 'Ta bort \"$name\" från källaren?';
  }

  @override
  String get cancel => 'Avbryt';

  @override
  String get delete => 'Ta bort';

  @override
  String get save => 'Spara';

  @override
  String get drinkOne => 'Drick en flaska';

  @override
  String bottleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count flaskor',
      one: '1 flaska',
    );
    return '$_temp0';
  }

  @override
  String totalValue(String value) {
    return 'Värde: $value';
  }

  @override
  String get wineName => 'Namn';

  @override
  String get producer => 'Producent';

  @override
  String get vintage => 'Årgång';

  @override
  String get wineType => 'Typ';

  @override
  String get country => 'Land';

  @override
  String get region => 'Region';

  @override
  String get grapes => 'Druvor';

  @override
  String get grapesHint => 'Separera med kommatecken';

  @override
  String get quantity => 'Antal flaskor';

  @override
  String get price => 'Pris per flaska';

  @override
  String get location => 'Plats i källaren';

  @override
  String get rack => 'Ställ';

  @override
  String get shelf => 'Hylla';

  @override
  String get position => 'Position';

  @override
  String get drinkingWindow => 'Drickfönster';

  @override
  String get drinkFrom => 'Drick från (år)';

  @override
  String get drinkUntil => 'Drick senast (år)';

  @override
  String get requiredField => 'Obligatoriskt';

  @override
  String get invalidNumber => 'Ange ett giltigt tal';

  @override
  String get invalidYear => 'Ange ett giltigt år';

  @override
  String get untilBeforeFrom => 'Får inte vara tidigare än \"drick från\"';

  @override
  String get typeRed => 'Rött';

  @override
  String get typeWhite => 'Vitt';

  @override
  String get typeRose => 'Rosé';

  @override
  String get typeSparkling => 'Mousserande';

  @override
  String get typeDessert => 'Dessertvin';

  @override
  String get typeFortified => 'Starkvin';

  @override
  String get statusUnknown => 'Inget drickfönster';

  @override
  String get statusTooEarly => 'För tidigt';

  @override
  String get statusReady => 'Redo att drickas';

  @override
  String get statusPastPeak => 'Förbi sin topp';

  @override
  String get retry => 'Försök igen';

  @override
  String get errorNetwork =>
      'Kunde inte ansluta. Kontrollera internetanslutningen och försök igen.';

  @override
  String get errorServer =>
      'Servern kunde inte slutföra begäran. Försök igen senare.';

  @override
  String get errorInvalidData => 'En del av vinets uppgifter är ogiltiga.';

  @override
  String get errorUnknown => 'Något oväntat gick fel. Försök igen.';

  @override
  String get errorInvalidLogin => 'Fel e-post eller lösenord.';

  @override
  String get errorEmailNotConfirmed =>
      'Bekräfta din e-postadress innan du loggar in.';

  @override
  String get errorUserExists =>
      'Det finns redan ett konto med den här e-postadressen.';

  @override
  String get errorWeakPassword => 'Välj ett starkare lösenord.';

  @override
  String get errorTooManyAttempts =>
      'För många försök. Vänta en stund och försök igen.';

  @override
  String get purchase => 'Köp';

  @override
  String get purchaseDate => 'Köpdatum';

  @override
  String get purchasedFrom => 'Köpt hos';

  @override
  String get purchasedFromHint => 'T.ex. Systembolaget eller en importör';

  @override
  String get chooseDate => 'Välj datum';

  @override
  String get clearDate => 'Rensa datum';

  @override
  String get myNotes => 'Mina anteckningar';

  @override
  String get addNote => 'Ny anteckning';

  @override
  String get editNote => 'Redigera anteckning';

  @override
  String get deleteNote => 'Ta bort anteckning';

  @override
  String get deleteNoteConfirm => 'Ta bort den här anteckningen?';

  @override
  String get noNotes =>
      'Inga anteckningar än. Skriv en när du öppnar en flaska!';

  @override
  String get noteDate => 'Datum';

  @override
  String get rating => 'Betyg';

  @override
  String ratingStars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stjärnor',
      one: '1 stjärna',
    );
    return '$_temp0';
  }

  @override
  String get noteText => 'Anteckning';

  @override
  String get noteHint => 'Smak, doft, mat, tillfälle…';

  @override
  String get edit => 'Redigera';
}
