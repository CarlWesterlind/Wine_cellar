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
  String get searchHint => 'Søg vin, producent, drue…';

  @override
  String get emptyCellar =>
      'Tilføj din første vin for at holde styr på dine flasker.';

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

  @override
  String get purchase => 'Køb';

  @override
  String get purchaseDate => 'Købsdato';

  @override
  String get purchasedFrom => 'Købt hos';

  @override
  String get purchasedFromHint => 'F.eks. en vinhandel eller importør';

  @override
  String get chooseDate => 'Vælg dato';

  @override
  String get clearDate => 'Ryd dato';

  @override
  String get myNotes => 'Mine noter';

  @override
  String get addNote => 'Ny note';

  @override
  String get editNote => 'Rediger note';

  @override
  String get deleteNote => 'Slet note';

  @override
  String get deleteNoteConfirm => 'Slet denne note?';

  @override
  String get noNotes => 'Ingen noter endnu. Skriv en, når du åbner en flaske!';

  @override
  String get noteDate => 'Dato';

  @override
  String get rating => 'Bedømmelse';

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
  String get noteText => 'Note';

  @override
  String get noteHint => 'Smag, duft, mad, anledning…';

  @override
  String get edit => 'Rediger';

  @override
  String get appearance => 'Udseende';

  @override
  String get themeSystem => 'Som telefonen';

  @override
  String get themeLight => 'Lyst';

  @override
  String get themeDark => 'Mørkt';

  @override
  String get emptyCellarTitle => 'Din kælder er tom';

  @override
  String get clearSearch => 'Ryd søgning';

  @override
  String get clearFilters => 'Vis alle vine';

  @override
  String get all => 'Alle';

  @override
  String get scanLabelTitle => 'Fotografér etiketten';

  @override
  String get scanLabelBody => 'AI læser etiketten og udfylder resten for dig.';

  @override
  String get takePhoto => 'Tag foto';

  @override
  String get choosePhoto => 'Vælg billede';

  @override
  String get addBackTitle => 'Tilføj bagsiden?';

  @override
  String get addBackBody =>
      'Bagsiden har ofte druer og flere detaljer, hvilket hjælper AI\'en.';

  @override
  String get skip => 'Spring over';

  @override
  String get addBack => 'Tilføj bagsiden';

  @override
  String get readingLabel => 'Læser etiketten…';

  @override
  String aiFilledFields(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'AI udfyldte $count felter. Tjek dem, før du gemmer.',
      one: 'AI udfyldte 1 felt. Tjek det, før du gemmer.',
    );
    return '$_temp0';
  }

  @override
  String get filledByAi => 'Forslag fra AI';

  @override
  String get lowConfidence =>
      'AI\'en er usikker på denne etiket. Tjek oplysningerne grundigt.';

  @override
  String get demoScan =>
      'Demotilstand: dette er et eksempel, ikke en rigtig AI-læsning.';

  @override
  String get changePhoto => 'Skift billede';

  @override
  String get removePhoto => 'Fjern billede';

  @override
  String get scanAgain => 'Læs etiketten igen';

  @override
  String get sommelier => 'Sommelier';

  @override
  String get aiDisclaimer => 'Forslag fra AI. De kan indeholde fejl.';

  @override
  String get tastingProfile => 'Smagsprofil';

  @override
  String get foodPairing => 'Passer til';

  @override
  String get servingTemperature => 'Serveringstemperatur';

  @override
  String get decanting => 'Dekantering';

  @override
  String get aboutProducer => 'Om producenten';

  @override
  String get removeSommelier => 'Fjern AI-forslagene';

  @override
  String get winePhoto => 'Foto af flasken';

  @override
  String get errorNotWineLabel =>
      'Det ligner ikke en vinetiket. Prøv et andet foto.';

  @override
  String get errorUnreadable =>
      'Etiketten kunne ikke læses. Prøv et skarpere foto i godt lys.';

  @override
  String errorDailyLimit(int limit) {
    return 'Du har nået grænsen på $limit scanninger om dagen. Prøv igen i morgen, eller udfyld oplysningerne selv.';
  }

  @override
  String get errorImageTooLarge => 'Billedet er for stort. Prøv et andet.';

  @override
  String get errorUnsupportedImage =>
      'Billedformatet understøttes ikke. Brug JPEG eller PNG.';

  @override
  String get errorAiUnavailable =>
      'Etiketlæseren er ikke tilgængelig lige nu. Prøv igen om lidt.';

  @override
  String get navCellar => 'Kælder';

  @override
  String get navMap => 'Kort';

  @override
  String get navStats => 'Statistik';

  @override
  String get navHistory => 'Historik';

  @override
  String get drinkDate => 'Dato';

  @override
  String get occasion => 'Lejlighed eller selskab';

  @override
  String get occasionHint => 'F.eks. juleaften, middag med Anna';

  @override
  String get noteOptional => 'Note (valgfri)';

  @override
  String get drink => 'Drik';

  @override
  String get drankBottle => 'Drak en flaske.';

  @override
  String bottleDrunk(String name) {
    return 'En flaske $name drukket';
  }

  @override
  String get undo => 'Fortryd';

  @override
  String get putBack => 'Læg tilbage i kælderen';

  @override
  String get putBackConfirm =>
      'Lægge flasken tilbage i kælderen og fjerne den fra historikken?';

  @override
  String get emptyHistoryTitle => 'Ingen flasker drukket endnu';

  @override
  String get emptyHistory =>
      'Når du drikker en flaske, vises den her med dato og lejlighed.';

  @override
  String drunkTimes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count flasker drukket',
      one: '1 flaske drukket',
    );
    return '$_temp0';
  }

  @override
  String wineCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count vine',
      one: '1 vin',
    );
    return '$_temp0';
  }

  @override
  String get bottles => 'Flasker';

  @override
  String get wines => 'Vine';

  @override
  String get cellarValue => 'Kælderens værdi';

  @override
  String get averagePrice => 'Gennemsnit pr. flaske';

  @override
  String get byType => 'Flasker pr. type';

  @override
  String get byCountry => 'Flasker pr. land';

  @override
  String get byGrape => 'Flasker pr. drue';

  @override
  String get otherItems => 'Øvrige';

  @override
  String get drinkThisYear => 'Sidste år at drikke';

  @override
  String get statsEmptyTitle => 'Ingen statistik endnu';

  @override
  String get statsEmpty => 'Statistikken vises, når du har flasker i kælderen.';

  @override
  String get addRack => 'Nyt reol';

  @override
  String get editRack => 'Rediger reol';

  @override
  String get deleteRack => 'Slet reol';

  @override
  String deleteRackConfirm(String name) {
    return 'Slet reol $name? Vinene bliver i kælderen.';
  }

  @override
  String get rackName => 'Navn';

  @override
  String get rackNameHint => 'F.eks. A eller Køkken';

  @override
  String get rackShelves => 'Hylder';

  @override
  String get rackSlots => 'Pladser pr. hylde';

  @override
  String rackSizeError(int max) {
    return 'Angiv et tal fra 1 til $max';
  }

  @override
  String get rackNameTaken => 'Der findes allerede en reol med det navn';

  @override
  String get noRacksTitle => 'Ingen reoler endnu';

  @override
  String get noRacks =>
      'Tilføj en reol med hylder og pladser for at se, hvor hver flaske ligger.';

  @override
  String rackUsage(int used, int capacity) {
    return '$used af $capacity pladser brugt';
  }

  @override
  String emptySlot(int shelf, int slot) {
    return 'Hylde $shelf, plads $slot, tom';
  }

  @override
  String filledSlot(int shelf, int slot, String wine) {
    return 'Hylde $shelf, plads $slot: $wine';
  }

  @override
  String placeWine(int shelf, int slot) {
    return 'Placer en vin på hylde $shelf, plads $slot';
  }

  @override
  String get noWinesToPlace => 'Tilføj en vin til kælderen først.';

  @override
  String get notInGrid => 'I reolen, uden plads';

  @override
  String get moreOptions => 'Flere valg';

  @override
  String get exportCsv => 'Eksporter til regneark';

  @override
  String get exportFileName => 'vinkaelderen';

  @override
  String shelfShort(int shelf) {
    return 'Hylde $shelf';
  }
}
