// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Wine Cellar';

  @override
  String get signIn => 'Sign in';

  @override
  String get signUp => 'Create account';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get switchToSignUp => 'No account? Create one';

  @override
  String get switchToSignIn => 'Already have an account? Sign in';

  @override
  String get confirmEmailSent =>
      'Check your email to confirm your account, then sign in.';

  @override
  String get invalidEmail => 'Enter a valid email address';

  @override
  String get passwordTooShort => 'Password must be at least 6 characters';

  @override
  String get signOut => 'Sign out';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get systemLanguage => 'Device language';

  @override
  String signedInAs(String email) {
    return 'Signed in as $email';
  }

  @override
  String get demoMode => 'Demo mode – changes are not saved.';

  @override
  String get searchHint => 'Search wine, producer, grape…';

  @override
  String get emptyCellar =>
      'Add your first wine to start keeping track of your bottles.';

  @override
  String get noResults => 'No wines match your search.';

  @override
  String get addWine => 'Add wine';

  @override
  String get editWine => 'Edit wine';

  @override
  String get deleteWine => 'Delete wine';

  @override
  String deleteConfirm(String name) {
    return 'Delete \"$name\" from your cellar?';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get save => 'Save';

  @override
  String get drinkOne => 'Drink a bottle';

  @override
  String bottleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bottles',
      one: '1 bottle',
    );
    return '$_temp0';
  }

  @override
  String totalValue(String value) {
    return 'Value: $value';
  }

  @override
  String get wineName => 'Name';

  @override
  String get producer => 'Producer';

  @override
  String get vintage => 'Vintage';

  @override
  String get wineType => 'Type';

  @override
  String get country => 'Country';

  @override
  String get region => 'Region';

  @override
  String get grapes => 'Grapes';

  @override
  String get grapesHint => 'Separate with commas';

  @override
  String get quantity => 'Bottles';

  @override
  String get price => 'Price per bottle';

  @override
  String get location => 'Location in cellar';

  @override
  String get rack => 'Rack';

  @override
  String get shelf => 'Shelf';

  @override
  String get position => 'Position';

  @override
  String get drinkingWindow => 'Drinking window';

  @override
  String get drinkFrom => 'Drink from (year)';

  @override
  String get drinkUntil => 'Drink until (year)';

  @override
  String get requiredField => 'Required';

  @override
  String get invalidNumber => 'Enter a valid number';

  @override
  String get invalidYear => 'Enter a valid year';

  @override
  String get untilBeforeFrom => 'Must not be earlier than \"drink from\"';

  @override
  String get typeRed => 'Red';

  @override
  String get typeWhite => 'White';

  @override
  String get typeRose => 'Rosé';

  @override
  String get typeSparkling => 'Sparkling';

  @override
  String get typeDessert => 'Dessert';

  @override
  String get typeFortified => 'Fortified';

  @override
  String get statusUnknown => 'No drinking window';

  @override
  String get statusTooEarly => 'Too early';

  @override
  String get statusReady => 'Ready to drink';

  @override
  String get statusPastPeak => 'Past its best';

  @override
  String get retry => 'Try again';

  @override
  String get errorNetwork =>
      'Could not connect. Check your internet connection and try again.';

  @override
  String get errorServer =>
      'The server could not complete the request. Try again later.';

  @override
  String get errorInvalidData => 'Some of the wine information is invalid.';

  @override
  String get errorUnknown =>
      'Something unexpected went wrong. Please try again.';

  @override
  String get errorInvalidLogin => 'Wrong email or password.';

  @override
  String get errorEmailNotConfirmed =>
      'Confirm your email address before signing in.';

  @override
  String get errorUserExists => 'An account with this email already exists.';

  @override
  String get errorWeakPassword => 'Choose a stronger password.';

  @override
  String get errorTooManyAttempts =>
      'Too many attempts. Wait a moment and try again.';

  @override
  String get purchase => 'Purchase';

  @override
  String get purchaseDate => 'Purchase date';

  @override
  String get purchasedFrom => 'Bought from';

  @override
  String get purchasedFromHint => 'E.g. a shop or an importer';

  @override
  String get chooseDate => 'Choose date';

  @override
  String get clearDate => 'Clear date';

  @override
  String get myNotes => 'My notes';

  @override
  String get addNote => 'New note';

  @override
  String get editNote => 'Edit note';

  @override
  String get deleteNote => 'Delete note';

  @override
  String get deleteNoteConfirm => 'Delete this note?';

  @override
  String get noNotes => 'No notes yet. Add one when you open a bottle!';

  @override
  String get noteDate => 'Date';

  @override
  String get rating => 'Rating';

  @override
  String ratingStars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stars',
      one: '1 star',
    );
    return '$_temp0';
  }

  @override
  String get noteText => 'Note';

  @override
  String get noteHint => 'Taste, smell, food, occasion…';

  @override
  String get edit => 'Edit';

  @override
  String get appearance => 'Appearance';

  @override
  String get themeSystem => 'Same as phone';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get emptyCellarTitle => 'Your cellar is empty';

  @override
  String get clearSearch => 'Clear search';

  @override
  String get clearFilters => 'Show all wines';

  @override
  String get all => 'All';
}
