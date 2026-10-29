import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_da.dart';
import 'app_localizations_en.dart';
import 'app_localizations_nb.dart';
import 'app_localizations_sv.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('da'),
    Locale('en'),
    Locale('nb'),
    Locale('sv'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Wine Cellar'**
  String get appTitle;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get signUp;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @switchToSignUp.
  ///
  /// In en, this message translates to:
  /// **'No account? Create one'**
  String get switchToSignUp;

  /// No description provided for @switchToSignIn.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get switchToSignIn;

  /// No description provided for @confirmEmailSent.
  ///
  /// In en, this message translates to:
  /// **'Check your email to confirm your account, then sign in.'**
  String get confirmEmailSent;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get invalidEmail;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordTooShort;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @systemLanguage.
  ///
  /// In en, this message translates to:
  /// **'Device language'**
  String get systemLanguage;

  /// No description provided for @signedInAs.
  ///
  /// In en, this message translates to:
  /// **'Signed in as {email}'**
  String signedInAs(String email);

  /// No description provided for @demoMode.
  ///
  /// In en, this message translates to:
  /// **'Demo mode – changes are not saved.'**
  String get demoMode;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search name, producer, region or grape'**
  String get searchHint;

  /// No description provided for @allTypes.
  ///
  /// In en, this message translates to:
  /// **'All types'**
  String get allTypes;

  /// No description provided for @allStatuses.
  ///
  /// In en, this message translates to:
  /// **'Any drinking window'**
  String get allStatuses;

  /// No description provided for @emptyCellar.
  ///
  /// In en, this message translates to:
  /// **'Your cellar is empty. Add your first wine!'**
  String get emptyCellar;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No wines match your search.'**
  String get noResults;

  /// No description provided for @addWine.
  ///
  /// In en, this message translates to:
  /// **'Add wine'**
  String get addWine;

  /// No description provided for @editWine.
  ///
  /// In en, this message translates to:
  /// **'Edit wine'**
  String get editWine;

  /// No description provided for @deleteWine.
  ///
  /// In en, this message translates to:
  /// **'Delete wine'**
  String get deleteWine;

  /// No description provided for @deleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\" from your cellar?'**
  String deleteConfirm(String name);

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @drinkOne.
  ///
  /// In en, this message translates to:
  /// **'Drink a bottle'**
  String get drinkOne;

  /// No description provided for @bottleCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 bottle} other{{count} bottles}}'**
  String bottleCount(int count);

  /// No description provided for @totalValue.
  ///
  /// In en, this message translates to:
  /// **'Value: {value}'**
  String totalValue(String value);

  /// No description provided for @wineName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get wineName;

  /// No description provided for @producer.
  ///
  /// In en, this message translates to:
  /// **'Producer'**
  String get producer;

  /// No description provided for @vintage.
  ///
  /// In en, this message translates to:
  /// **'Vintage'**
  String get vintage;

  /// No description provided for @wineType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get wineType;

  /// No description provided for @country.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get country;

  /// No description provided for @region.
  ///
  /// In en, this message translates to:
  /// **'Region'**
  String get region;

  /// No description provided for @grapes.
  ///
  /// In en, this message translates to:
  /// **'Grapes'**
  String get grapes;

  /// No description provided for @grapesHint.
  ///
  /// In en, this message translates to:
  /// **'Separate with commas'**
  String get grapesHint;

  /// No description provided for @quantity.
  ///
  /// In en, this message translates to:
  /// **'Bottles'**
  String get quantity;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price per bottle'**
  String get price;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location in cellar'**
  String get location;

  /// No description provided for @rack.
  ///
  /// In en, this message translates to:
  /// **'Rack'**
  String get rack;

  /// No description provided for @shelf.
  ///
  /// In en, this message translates to:
  /// **'Shelf'**
  String get shelf;

  /// No description provided for @position.
  ///
  /// In en, this message translates to:
  /// **'Position'**
  String get position;

  /// No description provided for @drinkingWindow.
  ///
  /// In en, this message translates to:
  /// **'Drinking window'**
  String get drinkingWindow;

  /// No description provided for @drinkFrom.
  ///
  /// In en, this message translates to:
  /// **'Drink from (year)'**
  String get drinkFrom;

  /// No description provided for @drinkUntil.
  ///
  /// In en, this message translates to:
  /// **'Drink until (year)'**
  String get drinkUntil;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get requiredField;

  /// No description provided for @invalidNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid number'**
  String get invalidNumber;

  /// No description provided for @invalidYear.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid year'**
  String get invalidYear;

  /// No description provided for @untilBeforeFrom.
  ///
  /// In en, this message translates to:
  /// **'Must not be earlier than \"drink from\"'**
  String get untilBeforeFrom;

  /// No description provided for @typeRed.
  ///
  /// In en, this message translates to:
  /// **'Red'**
  String get typeRed;

  /// No description provided for @typeWhite.
  ///
  /// In en, this message translates to:
  /// **'White'**
  String get typeWhite;

  /// No description provided for @typeRose.
  ///
  /// In en, this message translates to:
  /// **'Rosé'**
  String get typeRose;

  /// No description provided for @typeSparkling.
  ///
  /// In en, this message translates to:
  /// **'Sparkling'**
  String get typeSparkling;

  /// No description provided for @typeDessert.
  ///
  /// In en, this message translates to:
  /// **'Dessert'**
  String get typeDessert;

  /// No description provided for @typeFortified.
  ///
  /// In en, this message translates to:
  /// **'Fortified'**
  String get typeFortified;

  /// No description provided for @statusUnknown.
  ///
  /// In en, this message translates to:
  /// **'No drinking window'**
  String get statusUnknown;

  /// No description provided for @statusTooEarly.
  ///
  /// In en, this message translates to:
  /// **'Too early'**
  String get statusTooEarly;

  /// No description provided for @statusReady.
  ///
  /// In en, this message translates to:
  /// **'Ready to drink'**
  String get statusReady;

  /// No description provided for @statusPastPeak.
  ///
  /// In en, this message translates to:
  /// **'Past its best'**
  String get statusPastPeak;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retry;

  /// No description provided for @errorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Could not connect. Check your internet connection and try again.'**
  String get errorNetwork;

  /// No description provided for @errorServer.
  ///
  /// In en, this message translates to:
  /// **'The server could not complete the request. Try again later.'**
  String get errorServer;

  /// No description provided for @errorInvalidData.
  ///
  /// In en, this message translates to:
  /// **'Some of the wine information is invalid.'**
  String get errorInvalidData;

  /// No description provided for @errorUnknown.
  ///
  /// In en, this message translates to:
  /// **'Something unexpected went wrong. Please try again.'**
  String get errorUnknown;

  /// No description provided for @errorInvalidLogin.
  ///
  /// In en, this message translates to:
  /// **'Wrong email or password.'**
  String get errorInvalidLogin;

  /// No description provided for @errorEmailNotConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirm your email address before signing in.'**
  String get errorEmailNotConfirmed;

  /// No description provided for @errorUserExists.
  ///
  /// In en, this message translates to:
  /// **'An account with this email already exists.'**
  String get errorUserExists;

  /// No description provided for @errorWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'Choose a stronger password.'**
  String get errorWeakPassword;

  /// No description provided for @errorTooManyAttempts.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Wait a moment and try again.'**
  String get errorTooManyAttempts;

  /// No description provided for @purchase.
  ///
  /// In en, this message translates to:
  /// **'Purchase'**
  String get purchase;

  /// No description provided for @purchaseDate.
  ///
  /// In en, this message translates to:
  /// **'Purchase date'**
  String get purchaseDate;

  /// No description provided for @purchasedFrom.
  ///
  /// In en, this message translates to:
  /// **'Bought from'**
  String get purchasedFrom;

  /// No description provided for @purchasedFromHint.
  ///
  /// In en, this message translates to:
  /// **'E.g. a shop or an importer'**
  String get purchasedFromHint;

  /// No description provided for @chooseDate.
  ///
  /// In en, this message translates to:
  /// **'Choose date'**
  String get chooseDate;

  /// No description provided for @clearDate.
  ///
  /// In en, this message translates to:
  /// **'Clear date'**
  String get clearDate;

  /// No description provided for @myNotes.
  ///
  /// In en, this message translates to:
  /// **'My notes'**
  String get myNotes;

  /// No description provided for @addNote.
  ///
  /// In en, this message translates to:
  /// **'New note'**
  String get addNote;

  /// No description provided for @editNote.
  ///
  /// In en, this message translates to:
  /// **'Edit note'**
  String get editNote;

  /// No description provided for @deleteNote.
  ///
  /// In en, this message translates to:
  /// **'Delete note'**
  String get deleteNote;

  /// No description provided for @deleteNoteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this note?'**
  String get deleteNoteConfirm;

  /// No description provided for @noNotes.
  ///
  /// In en, this message translates to:
  /// **'No notes yet. Add one when you open a bottle!'**
  String get noNotes;

  /// No description provided for @noteDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get noteDate;

  /// No description provided for @rating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get rating;

  /// No description provided for @ratingStars.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 star} other{{count} stars}}'**
  String ratingStars(int count);

  /// No description provided for @noteText.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get noteText;

  /// No description provided for @noteHint.
  ///
  /// In en, this message translates to:
  /// **'Taste, smell, food, occasion…'**
  String get noteHint;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['da', 'en', 'nb', 'sv'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'da':
      return AppLocalizationsDa();
    case 'en':
      return AppLocalizationsEn();
    case 'nb':
      return AppLocalizationsNb();
    case 'sv':
      return AppLocalizationsSv();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
