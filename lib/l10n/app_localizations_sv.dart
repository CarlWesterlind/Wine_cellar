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
  String get searchHint => 'Sök vin, producent, druva…';

  @override
  String get emptyCellar =>
      'Lägg till ditt första vin för att börja hålla koll på dina flaskor.';

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

  @override
  String get appearance => 'Utseende';

  @override
  String get themeSystem => 'Som telefonen';

  @override
  String get themeLight => 'Ljust';

  @override
  String get themeDark => 'Mörkt';

  @override
  String get emptyCellarTitle => 'Din källare är tom';

  @override
  String get clearSearch => 'Rensa sökning';

  @override
  String get clearFilters => 'Visa alla viner';

  @override
  String get all => 'Alla';

  @override
  String get scanLabelTitle => 'Fotografera etiketten';

  @override
  String get scanLabelBody => 'AI läser etiketten och fyller i resten åt dig.';

  @override
  String get takePhoto => 'Ta foto';

  @override
  String get choosePhoto => 'Välj bild';

  @override
  String get addBackTitle => 'Lägga till baksidan?';

  @override
  String get addBackBody =>
      'Baksidan har ofta druvor och fler detaljer, vilket hjälper AI:n.';

  @override
  String get skip => 'Hoppa över';

  @override
  String get addBack => 'Lägg till baksidan';

  @override
  String get readingLabel => 'Läser etiketten…';

  @override
  String aiFilledFields(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'AI fyllde i $count fält. Kontrollera dem innan du sparar.',
      one: 'AI fyllde i 1 fält. Kontrollera det innan du sparar.',
    );
    return '$_temp0';
  }

  @override
  String get filledByAi => 'Förslag från AI';

  @override
  String get lowConfidence =>
      'AI:n är osäker på den här etiketten. Kontrollera uppgifterna noga.';

  @override
  String get demoScan =>
      'Demoläge: detta är ett exempelresultat, inte en riktig AI-läsning.';

  @override
  String get changePhoto => 'Byt bild';

  @override
  String get removePhoto => 'Ta bort bild';

  @override
  String get scanAgain => 'Läs etiketten igen';

  @override
  String get sommelier => 'Sommelier';

  @override
  String get aiDisclaimer => 'Förslag från AI. De kan innehålla fel.';

  @override
  String get tastingProfile => 'Smakprofil';

  @override
  String get foodPairing => 'Passar till';

  @override
  String get servingTemperature => 'Serveringstemperatur';

  @override
  String get decanting => 'Dekantering';

  @override
  String get aboutProducer => 'Om producenten';

  @override
  String get removeSommelier => 'Ta bort AI-förslagen';

  @override
  String get winePhoto => 'Foto av flaskan';

  @override
  String get errorNotWineLabel =>
      'Det ser inte ut som en vinetikett. Prova ett annat foto.';

  @override
  String get errorUnreadable =>
      'Etiketten gick inte att läsa. Prova ett skarpare foto i bra ljus.';

  @override
  String errorDailyLimit(int limit) {
    return 'Du har nått gränsen på $limit skanningar per dag. Försök igen i morgon eller fyll i uppgifterna själv.';
  }

  @override
  String get errorImageTooLarge => 'Fotot är för stort. Prova ett annat.';

  @override
  String get errorUnsupportedImage =>
      'Bildformatet stöds inte. Använd JPEG eller PNG.';

  @override
  String get errorAiUnavailable =>
      'Etikettläsaren är inte tillgänglig just nu. Försök igen om en stund.';

  @override
  String get navCellar => 'Källare';

  @override
  String get navMap => 'Karta';

  @override
  String get navStats => 'Statistik';

  @override
  String get navHistory => 'Historik';

  @override
  String get drinkDate => 'Datum';

  @override
  String get occasion => 'Tillfälle eller sällskap';

  @override
  String get occasionHint => 'T.ex. julafton, middag med Anna';

  @override
  String get noteOptional => 'Anteckning (valfri)';

  @override
  String get drink => 'Drick';

  @override
  String get drankBottle => 'Drack en flaska.';

  @override
  String bottleDrunk(String name) {
    return 'En flaska $name drucken';
  }

  @override
  String get undo => 'Ångra';

  @override
  String get putBack => 'Lägg tillbaka i källaren';

  @override
  String get putBackConfirm =>
      'Lägga tillbaka flaskan i källaren och ta bort den ur historiken?';

  @override
  String get emptyHistoryTitle => 'Inga flaskor druckna än';

  @override
  String get emptyHistory =>
      'När du dricker en flaska visas den här med datum och tillfälle.';

  @override
  String drunkTimes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count flaskor druckna',
      one: '1 flaska drucken',
    );
    return '$_temp0';
  }

  @override
  String wineCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count viner',
      one: '1 vin',
    );
    return '$_temp0';
  }

  @override
  String get bottles => 'Flaskor';

  @override
  String get wines => 'Viner';

  @override
  String get cellarValue => 'Källarens värde';

  @override
  String get averagePrice => 'Snittpris per flaska';

  @override
  String get byType => 'Flaskor per typ';

  @override
  String get byCountry => 'Flaskor per land';

  @override
  String get byGrape => 'Flaskor per druva';

  @override
  String get otherItems => 'Övriga';

  @override
  String get drinkThisYear => 'Sista året att dricka';

  @override
  String get statsEmptyTitle => 'Ingen statistik än';

  @override
  String get statsEmpty => 'Statistiken visas när du har flaskor i källaren.';

  @override
  String get addRack => 'Nytt ställ';

  @override
  String get editRack => 'Redigera ställ';

  @override
  String get deleteRack => 'Ta bort ställ';

  @override
  String deleteRackConfirm(String name) {
    return 'Ta bort ställ $name? Vinerna finns kvar i källaren.';
  }

  @override
  String get rackName => 'Namn';

  @override
  String get rackNameHint => 'T.ex. A eller Köket';

  @override
  String get rackShelves => 'Hyllor';

  @override
  String get rackSlots => 'Platser per hylla';

  @override
  String rackSizeError(int max) {
    return 'Ange ett tal från 1 till $max';
  }

  @override
  String get rackNameTaken => 'Det finns redan ett ställ med det namnet';

  @override
  String get noRacksTitle => 'Inga ställ än';

  @override
  String get noRacks =>
      'Lägg till ett ställ med hyllor och platser för att se var varje flaska ligger.';

  @override
  String rackUsage(int used, int capacity) {
    return '$used av $capacity platser använda';
  }

  @override
  String emptySlot(int shelf, int slot) {
    return 'Hylla $shelf, plats $slot, tom';
  }

  @override
  String filledSlot(int shelf, int slot, String wine) {
    return 'Hylla $shelf, plats $slot: $wine';
  }

  @override
  String placeWine(int shelf, int slot) {
    return 'Placera ett vin på hylla $shelf, plats $slot';
  }

  @override
  String get noWinesToPlace => 'Lägg till ett vin i källaren först.';

  @override
  String get notInGrid => 'I stället, utan plats';

  @override
  String get moreOptions => 'Fler val';

  @override
  String get exportCsv => 'Exportera till kalkylark';

  @override
  String get exportFileName => 'vinkallaren';

  @override
  String shelfShort(int shelf) {
    return 'Hylla $shelf';
  }
}
