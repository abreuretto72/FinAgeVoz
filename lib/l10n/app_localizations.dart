import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pt.dart';

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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
    Locale('en'),
    Locale('pt'),
  ];

  /// Camera option in attachment picker
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// Gallery option for JPG images
  ///
  /// In en, this message translates to:
  /// **'Gallery (JPG)'**
  String get gallery;

  /// File picker option for PDF or JPG
  ///
  /// In en, this message translates to:
  /// **'File (PDF/JPG)'**
  String get file;

  /// Attachments dialog title
  ///
  /// In en, this message translates to:
  /// **'Attachments'**
  String get attachments;

  /// Add button label
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// Close button label
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// Medicine list screen title
  ///
  /// In en, this message translates to:
  /// **'My Medicines'**
  String get myMedicines;

  /// Empty state message
  ///
  /// In en, this message translates to:
  /// **'No medicines registered.'**
  String get noMedicinesRegistered;

  /// Button to add new medicine
  ///
  /// In en, this message translates to:
  /// **'Register Medicine'**
  String get registerMedicine;

  /// Action to mark medicine as taken
  ///
  /// In en, this message translates to:
  /// **'Mark as Taken'**
  String get markAsTaken;

  /// Placeholder message for future feature
  ///
  /// In en, this message translates to:
  /// **'Coming soon: Mark as taken'**
  String get comingSoonMarkTaken;

  /// Action to edit medicine details
  ///
  /// In en, this message translates to:
  /// **'Edit Medicine'**
  String get editMedicine;

  /// Action to manage medicine dosage schedule
  ///
  /// In en, this message translates to:
  /// **'Manage Posology'**
  String get managePosology;

  /// Confirmation dialog title
  ///
  /// In en, this message translates to:
  /// **'Discard changes?'**
  String get discardChanges;

  /// Confirmation dialog message
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes. Do you want to exit?'**
  String get unsavedChangesMessage;

  /// Cancel button
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Exit button
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get exit;

  /// Dosage label
  ///
  /// In en, this message translates to:
  /// **'Dose'**
  String get dose;

  /// Frequency label
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get frequency;

  /// Label for scheduled times list
  ///
  /// In en, this message translates to:
  /// **'Defined times:'**
  String get definedTimes;

  /// Validation error message
  ///
  /// In en, this message translates to:
  /// **'Add at least one time'**
  String get addAtLeastOneTime;

  /// Treatment duration section title
  ///
  /// In en, this message translates to:
  /// **'Treatment Duration'**
  String get treatmentDuration;

  /// Start date label
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// Checkbox for ongoing treatment
  ///
  /// In en, this message translates to:
  /// **'Continuous Use'**
  String get continuousUse;

  /// End date label
  ///
  /// In en, this message translates to:
  /// **'End (Optional)'**
  String get endOptional;

  /// Other settings section
  ///
  /// In en, this message translates to:
  /// **'Others'**
  String get others;

  /// Checkbox for food requirement
  ///
  /// In en, this message translates to:
  /// **'Take with food?'**
  String get takeWithFood;

  /// Checkbox for confirmation prompt
  ///
  /// In en, this message translates to:
  /// **'Require confirmation?'**
  String get requireConfirmation;

  /// Subtitle explaining confirmation
  ///
  /// In en, this message translates to:
  /// **'I will ask if you took it'**
  String get requireConfirmationSubtitle;

  /// Attachments section title
  ///
  /// In en, this message translates to:
  /// **'Attachments (Prescriptions, Instructions)'**
  String get attachmentsPrescriptions;

  /// Agenda screen title
  ///
  /// In en, this message translates to:
  /// **'Smart Agenda'**
  String get smartAgenda;

  /// Empty state for calendar day
  ///
  /// In en, this message translates to:
  /// **'No events this day'**
  String get noEventsThisDay;

  /// Action to confirm payment
  ///
  /// In en, this message translates to:
  /// **'Confirm Payment'**
  String get confirmPayment;

  /// Action to view item details
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetails;

  /// Action to share PDF report
  ///
  /// In en, this message translates to:
  /// **'Share PDF'**
  String get sharePdf;

  /// Action to print
  ///
  /// In en, this message translates to:
  /// **'Print'**
  String get print;

  /// Empty state message for filtered results
  ///
  /// In en, this message translates to:
  /// **'No items found for the selected filters.'**
  String get noItemsFoundForFilters;

  /// Google sign-in button
  ///
  /// In en, this message translates to:
  /// **'Login with Google'**
  String get loginWithGoogle;

  /// Manual sync button
  ///
  /// In en, this message translates to:
  /// **'Sync Now'**
  String get syncNow;

  /// Auto-sync toggle title
  ///
  /// In en, this message translates to:
  /// **'Automatic Sync'**
  String get automaticSync;

  /// Auto-sync toggle subtitle
  ///
  /// In en, this message translates to:
  /// **'Sync data every 5 minutes when connected'**
  String get automaticSyncSubtitle;

  /// FAQ section title
  ///
  /// In en, this message translates to:
  /// **'How does it work?'**
  String get howItWorks;

  /// Subscription screen title
  ///
  /// In en, this message translates to:
  /// **'My Subscription'**
  String get mySubscription;

  /// Upgrade button
  ///
  /// In en, this message translates to:
  /// **'UPGRADE NOW'**
  String get upgradeNow;

  /// Manage subscription button
  ///
  /// In en, this message translates to:
  /// **'Manage Subscription'**
  String get manageSubscription;

  /// Restore purchases button
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restore;

  /// Voice command to pay a bill
  ///
  /// In en, this message translates to:
  /// **'pay bill'**
  String get cmdPayBill;

  /// Voice command synonym for payment
  ///
  /// In en, this message translates to:
  /// **'make payment'**
  String get cmdMakePayment;

  /// Voice command to add expense
  ///
  /// In en, this message translates to:
  /// **'add expense'**
  String get cmdAddExpense;

  /// Voice command to add income
  ///
  /// In en, this message translates to:
  /// **'add income'**
  String get cmdAddIncome;

  /// Voice command to display balance
  ///
  /// In en, this message translates to:
  /// **'show balance'**
  String get cmdShowBalance;

  /// Voice command to stop listening
  ///
  /// In en, this message translates to:
  /// **'stop'**
  String get cmdStop;

  /// Voice command synonym for stop
  ///
  /// In en, this message translates to:
  /// **'done'**
  String get cmdDone;

  /// Voice command to confirm
  ///
  /// In en, this message translates to:
  /// **'ok'**
  String get cmdOk;

  /// Posology form unsaved changes warning
  ///
  /// In en, this message translates to:
  /// **'There is unsaved posology data. Do you want to exit?'**
  String get unsavedPosologyMessage;

  /// Empty state for attachments list
  ///
  /// In en, this message translates to:
  /// **'No attachments.'**
  String get noAttachments;

  /// Save button
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Delete button
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Title for new posology screen
  ///
  /// In en, this message translates to:
  /// **'New Posology'**
  String get newPosology;

  /// Title for edit posology screen
  ///
  /// In en, this message translates to:
  /// **'Edit Posology'**
  String get editPosology;

  /// Quantity label
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantity;

  /// Unit label
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get unit;

  /// Frequency type label
  ///
  /// In en, this message translates to:
  /// **'Frequency Type'**
  String get frequencyType;

  /// Interval frequency option
  ///
  /// In en, this message translates to:
  /// **'Interval of Hours (e.g., every 8h)'**
  String get intervalHours;

  /// Fixed times frequency option
  ///
  /// In en, this message translates to:
  /// **'Fixed Times (e.g., 08:00, 20:00)'**
  String get fixedTimes;

  /// Times per day frequency option
  ///
  /// In en, this message translates to:
  /// **'N times per day'**
  String get timesPerDay;

  /// As needed frequency option
  ///
  /// In en, this message translates to:
  /// **'As needed (SOS)'**
  String get asNeeded;

  /// Interval hours question
  ///
  /// In en, this message translates to:
  /// **'Every how many hours?'**
  String get everyHowManyHours;

  /// Hours suffix
  ///
  /// In en, this message translates to:
  /// **'hours'**
  String get hours;

  /// Times per day question
  ///
  /// In en, this message translates to:
  /// **'How many times per day?'**
  String get howManyTimesPerDay;

  /// Validation error
  ///
  /// In en, this message translates to:
  /// **'Invalid'**
  String get invalid;

  /// Required field validation
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No end date set
  ///
  /// In en, this message translates to:
  /// **'No end date'**
  String get noEndDate;

  /// Extra instructions field
  ///
  /// In en, this message translates to:
  /// **'Extra Instructions (e.g., empty stomach)'**
  String get extraInstructions;

  /// Snackbar message to add times
  ///
  /// In en, this message translates to:
  /// **'Add times'**
  String get addTimes;
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
      <String>['en', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
