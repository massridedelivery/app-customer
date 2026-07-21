import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_th.dart';

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
    Locale('th'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Customer App'**
  String get appName;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navRides.
  ///
  /// In en, this message translates to:
  /// **'Rides'**
  String get navRides;

  /// No description provided for @navAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get navAccount;

  /// No description provided for @goWherever.
  ///
  /// In en, this message translates to:
  /// **'Go wherever, whenever.'**
  String get goWherever;

  /// No description provided for @ridesTitle.
  ///
  /// In en, this message translates to:
  /// **'Rides'**
  String get ridesTitle;

  /// No description provided for @ridesSub.
  ///
  /// In en, this message translates to:
  /// **'Let\'s get moving'**
  String get ridesSub;

  /// No description provided for @whereTo.
  ///
  /// In en, this message translates to:
  /// **'Where to?'**
  String get whereTo;

  /// No description provided for @locating.
  ///
  /// In en, this message translates to:
  /// **'Locating...'**
  String get locating;

  /// No description provided for @failedToLocate.
  ///
  /// In en, this message translates to:
  /// **'Failed to locate'**
  String get failedToLocate;

  /// No description provided for @locationDisabled.
  ///
  /// In en, this message translates to:
  /// **'Location disabled'**
  String get locationDisabled;

  /// No description provided for @permissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Permission denied'**
  String get permissionDenied;

  /// No description provided for @yourTrips.
  ///
  /// In en, this message translates to:
  /// **'Your Trips'**
  String get yourTrips;

  /// No description provided for @noTripsYet.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t taken any trips yet.'**
  String get noTripsYet;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @thai.
  ///
  /// In en, this message translates to:
  /// **'Thai'**
  String get thai;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @confirmPickupLoc.
  ///
  /// In en, this message translates to:
  /// **'Confirm Pickup Location'**
  String get confirmPickupLoc;

  /// No description provided for @confirmDropoffLoc.
  ///
  /// In en, this message translates to:
  /// **'Confirm Dropoff Location'**
  String get confirmDropoffLoc;

  /// No description provided for @confirmPickup.
  ///
  /// In en, this message translates to:
  /// **'Confirm Pickup'**
  String get confirmPickup;

  /// No description provided for @confirmDropoff.
  ///
  /// In en, this message translates to:
  /// **'Confirm Dropoff'**
  String get confirmDropoff;

  /// No description provided for @movingMap.
  ///
  /// In en, this message translates to:
  /// **'Moving map...'**
  String get movingMap;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @hello.
  ///
  /// In en, this message translates to:
  /// **'Hello,'**
  String get hello;

  /// No description provided for @points.
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get points;

  /// No description provided for @trips.
  ///
  /// In en, this message translates to:
  /// **'Trips'**
  String get trips;

  /// No description provided for @personalInfo.
  ///
  /// In en, this message translates to:
  /// **'Personal Info'**
  String get personalInfo;

  /// No description provided for @personalInfoSub.
  ///
  /// In en, this message translates to:
  /// **'Manage name, email, and phone'**
  String get personalInfoSub;

  /// No description provided for @payment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get payment;

  /// No description provided for @paymentSub.
  ///
  /// In en, this message translates to:
  /// **'Saved cards and balance'**
  String get paymentSub;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @historySub.
  ///
  /// In en, this message translates to:
  /// **'Check past trips'**
  String get historySub;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @settingsSub.
  ///
  /// In en, this message translates to:
  /// **'Privacy and notifications'**
  String get settingsSub;

  /// No description provided for @help.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get help;

  /// No description provided for @helpSub.
  ///
  /// In en, this message translates to:
  /// **'Contact customer service'**
  String get helpSub;

  /// No description provided for @inviteFriends.
  ///
  /// In en, this message translates to:
  /// **'Invite Friends'**
  String get inviteFriends;

  /// No description provided for @inviteFriendsSub.
  ///
  /// In en, this message translates to:
  /// **'Get 100 THB discount\nwhen your friend takes their first trip'**
  String get inviteFriendsSub;

  /// No description provided for @shareCode.
  ///
  /// In en, this message translates to:
  /// **'Share Referral Code'**
  String get shareCode;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @changeLanguage.
  ///
  /// In en, this message translates to:
  /// **'Change Language'**
  String get changeLanguage;

  /// No description provided for @navFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get navFood;

  /// No description provided for @navOrder.
  ///
  /// In en, this message translates to:
  /// **'Order'**
  String get navOrder;

  /// No description provided for @orderList.
  ///
  /// In en, this message translates to:
  /// **'Order List'**
  String get orderList;

  /// No description provided for @deliverTo.
  ///
  /// In en, this message translates to:
  /// **'Deliver to'**
  String get deliverTo;

  /// No description provided for @curatedEv.
  ///
  /// In en, this message translates to:
  /// **'CURATED EXPERIENCE'**
  String get curatedEv;

  /// No description provided for @mobilityExp.
  ///
  /// In en, this message translates to:
  /// **'Experience the best of mobility'**
  String get mobilityExp;

  /// No description provided for @bookRideNow.
  ///
  /// In en, this message translates to:
  /// **'Book Ride Now'**
  String get bookRideNow;

  /// No description provided for @rides.
  ///
  /// In en, this message translates to:
  /// **'Rides'**
  String get rides;

  /// No description provided for @premiumJourney.
  ///
  /// In en, this message translates to:
  /// **'Premium every journey with expert drivers'**
  String get premiumJourney;

  /// No description provided for @callNow.
  ///
  /// In en, this message translates to:
  /// **'Call Now'**
  String get callNow;

  /// No description provided for @food.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get food;

  /// No description provided for @editorsChoice.
  ///
  /// In en, this message translates to:
  /// **'EDITORS\' CHOICE'**
  String get editorsChoice;

  /// No description provided for @recommendedRest.
  ///
  /// In en, this message translates to:
  /// **'Recommended Restaurants'**
  String get recommendedRest;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See All'**
  String get seeAll;

  /// No description provided for @liveStatus.
  ///
  /// In en, this message translates to:
  /// **'LIVE STATUS'**
  String get liveStatus;

  /// No description provided for @trackDriver.
  ///
  /// In en, this message translates to:
  /// **'Track your driver'**
  String get trackDriver;

  /// No description provided for @newPriceSure.
  ///
  /// In en, this message translates to:
  /// **'New price, cheaper for sure'**
  String get newPriceSure;

  /// No description provided for @gelPromo.
  ///
  /// In en, this message translates to:
  /// **'Add Gel then call now'**
  String get gelPromo;

  /// No description provided for @whereToToday.
  ///
  /// In en, this message translates to:
  /// **'Where shall we drop you off today?'**
  String get whereToToday;

  /// No description provided for @addAddress.
  ///
  /// In en, this message translates to:
  /// **'Add Address'**
  String get addAddress;

  /// No description provided for @recentUsage.
  ///
  /// In en, this message translates to:
  /// **'Recent Usage'**
  String get recentUsage;

  /// No description provided for @seeMore.
  ///
  /// In en, this message translates to:
  /// **'See More'**
  String get seeMore;

  /// No description provided for @bookingDetails.
  ///
  /// In en, this message translates to:
  /// **'Booking Details'**
  String get bookingDetails;

  /// No description provided for @searchDropoffHint.
  ///
  /// In en, this message translates to:
  /// **'Search for drop-off point'**
  String get searchDropoffHint;

  /// No description provided for @recent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get recent;

  /// No description provided for @recommended.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get recommended;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @selectOnMaps.
  ///
  /// In en, this message translates to:
  /// **'Select on MassMaps'**
  String get selectOnMaps;

  /// No description provided for @currentLocation.
  ///
  /// In en, this message translates to:
  /// **'Current Location'**
  String get currentLocation;

  /// No description provided for @tripCompleted.
  ///
  /// In en, this message translates to:
  /// **'Trip Completed'**
  String get tripCompleted;

  /// No description provided for @rideCompleted.
  ///
  /// In en, this message translates to:
  /// **'Ride Completed'**
  String get rideCompleted;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @tripCancelled.
  ///
  /// In en, this message translates to:
  /// **'Trip Cancelled'**
  String get tripCancelled;

  /// No description provided for @rideCancelled.
  ///
  /// In en, this message translates to:
  /// **'Ride Cancelled'**
  String get rideCancelled;

  /// No description provided for @assigningDriver.
  ///
  /// In en, this message translates to:
  /// **'Assigning driver...'**
  String get assigningDriver;

  /// No description provided for @driverArrived.
  ///
  /// In en, this message translates to:
  /// **'Driver has arrived!'**
  String get driverArrived;

  /// No description provided for @headingToDest.
  ///
  /// In en, this message translates to:
  /// **'Heading to destination...'**
  String get headingToDest;

  /// No description provided for @findingDrivers.
  ///
  /// In en, this message translates to:
  /// **'Finding nearby drivers...'**
  String get findingDrivers;

  /// No description provided for @distance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get distance;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @cancelSearch.
  ///
  /// In en, this message translates to:
  /// **'Cancel Search'**
  String get cancelSearch;

  /// No description provided for @cancelFailed.
  ///
  /// In en, this message translates to:
  /// **'Cancellation failed'**
  String get cancelFailed;

  /// No description provided for @searchingDriver.
  ///
  /// In en, this message translates to:
  /// **'Searching for nearby drivers...'**
  String get searchingDriver;

  /// No description provided for @findingDriverMsg.
  ///
  /// In en, this message translates to:
  /// **'Finding Driver...'**
  String get findingDriverMsg;

  /// No description provided for @driverComingMsg.
  ///
  /// In en, this message translates to:
  /// **'Driver is coming!'**
  String get driverComingMsg;

  /// No description provided for @arrivedMsg.
  ///
  /// In en, this message translates to:
  /// **'Arrived!'**
  String get arrivedMsg;

  /// No description provided for @pastTrips.
  ///
  /// In en, this message translates to:
  /// **'Past Trips'**
  String get pastTrips;

  /// No description provided for @tripsTravel.
  ///
  /// In en, this message translates to:
  /// **'Travel'**
  String get tripsTravel;

  /// No description provided for @tripsFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get tripsFood;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// No description provided for @cancelledLabel.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelledLabel;

  /// No description provided for @giveRating.
  ///
  /// In en, this message translates to:
  /// **'Rate'**
  String get giveRating;

  /// No description provided for @bookAgain.
  ///
  /// In en, this message translates to:
  /// **'Book Again'**
  String get bookAgain;

  /// No description provided for @whatToEatToday.
  ///
  /// In en, this message translates to:
  /// **'What would you like to eat today?'**
  String get whatToEatToday;

  /// No description provided for @exclusiveCurator.
  ///
  /// In en, this message translates to:
  /// **'EXCLUSIVE CURATOR'**
  String get exclusiveCurator;

  /// No description provided for @selectedForYou.
  ///
  /// In en, this message translates to:
  /// **'Flavors selected especially for you'**
  String get selectedForYou;

  /// No description provided for @orderNow.
  ///
  /// In en, this message translates to:
  /// **'Order Now'**
  String get orderNow;

  /// No description provided for @exploreCuisine.
  ///
  /// In en, this message translates to:
  /// **'Explore Cuisines'**
  String get exploreCuisine;

  /// No description provided for @yourFavoriteRest.
  ///
  /// In en, this message translates to:
  /// **'Your Favorite Restaurants'**
  String get yourFavoriteRest;

  /// No description provided for @selectedFromHabit.
  ///
  /// In en, this message translates to:
  /// **'Selected from ordering behavior'**
  String get selectedFromHabit;

  /// No description provided for @freeDelivery.
  ///
  /// In en, this message translates to:
  /// **'Free Delivery'**
  String get freeDelivery;

  /// No description provided for @popular.
  ///
  /// In en, this message translates to:
  /// **'Popular'**
  String get popular;

  /// No description provided for @minUnit.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get minUnit;

  /// No description provided for @kmUnit.
  ///
  /// In en, this message translates to:
  /// **'km'**
  String get kmUnit;

  /// No description provided for @trendingDishes.
  ///
  /// In en, this message translates to:
  /// **'Trending Dishes'**
  String get trendingDishes;

  /// No description provided for @likedThis.
  ///
  /// In en, this message translates to:
  /// **'liked this'**
  String get likedThis;

  /// No description provided for @pickupPoint.
  ///
  /// In en, this message translates to:
  /// **'Pickup Point'**
  String get pickupPoint;

  /// No description provided for @dropoffPoint.
  ///
  /// In en, this message translates to:
  /// **'Drop-off Point'**
  String get dropoffPoint;

  /// No description provided for @whereToGoHint.
  ///
  /// In en, this message translates to:
  /// **'Where do you want to go?'**
  String get whereToGoHint;

  /// No description provided for @noSavedPlaces.
  ///
  /// In en, this message translates to:
  /// **'No saved places yet'**
  String get noSavedPlaces;

  /// No description provided for @saveThisLocation.
  ///
  /// In en, this message translates to:
  /// **'Save this location'**
  String get saveThisLocation;

  /// No description provided for @selectPoint.
  ///
  /// In en, this message translates to:
  /// **'Select {point}'**
  String selectPoint(Object point);

  /// No description provided for @saveLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Save Location'**
  String get saveLocationTitle;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @transport.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get transport;

  /// No description provided for @cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelled;

  /// No description provided for @rateNow.
  ///
  /// In en, this message translates to:
  /// **'Rate Now'**
  String get rateNow;

  /// No description provided for @minutes.
  ///
  /// In en, this message translates to:
  /// **'mins'**
  String get minutes;

  /// No description provided for @km.
  ///
  /// In en, this message translates to:
  /// **'km'**
  String get km;

  /// No description provided for @cashLabel.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get cashLabel;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'WELCOME BACK'**
  String get welcomeBack;

  /// No description provided for @signInToAccount.
  ///
  /// In en, this message translates to:
  /// **'Sign in to your account'**
  String get signInToAccount;

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailAddress;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? '**
  String get dontHaveAccount;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get signUp;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'WELCOME'**
  String get welcome;

  /// No description provided for @enterNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter your number'**
  String get enterNumber;

  /// No description provided for @phoneLoginSub.
  ///
  /// In en, this message translates to:
  /// **'We\'ll send you a code to securely sign you in to your lifestyle concierge.'**
  String get phoneLoginSub;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @loginWithEmail.
  ///
  /// In en, this message translates to:
  /// **'Login with Email'**
  String get loginWithEmail;

  /// No description provided for @verifyIdentity.
  ///
  /// In en, this message translates to:
  /// **'Verify Identity'**
  String get verifyIdentity;

  /// No description provided for @otpSentMsg.
  ///
  /// In en, this message translates to:
  /// **'We\'ve sent a 6-digit code to your registered mobile number {phone}'**
  String otpSentMsg(String phone);

  /// No description provided for @verify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// No description provided for @resendCode.
  ///
  /// In en, this message translates to:
  /// **'RESEND CODE'**
  String get resendCode;

  /// No description provided for @needHelp.
  ///
  /// In en, this message translates to:
  /// **'Need help?'**
  String get needHelp;

  /// No description provided for @helpSubMsg.
  ///
  /// In en, this message translates to:
  /// **'If you haven\'t received the code after 2 minutes, please check your network or contact support.'**
  String get helpSubMsg;

  /// No description provided for @resendCodeIn.
  ///
  /// In en, this message translates to:
  /// **'Resend code in {time}'**
  String resendCodeIn(String time);

  /// No description provided for @otpResent.
  ///
  /// In en, this message translates to:
  /// **'A new code has been sent to your number'**
  String get otpResent;

  /// No description provided for @createYourAccount.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get createYourAccount;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get alreadyHaveAccount;

  /// No description provided for @secureRegistration.
  ///
  /// In en, this message translates to:
  /// **'SECURE REGISTRATION'**
  String get secureRegistration;

  /// No description provided for @fillAllFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all fields'**
  String get fillAllFields;

  /// No description provided for @inProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get inProgress;

  /// No description provided for @mart.
  ///
  /// In en, this message translates to:
  /// **'Mart'**
  String get mart;

  /// No description provided for @dineIn.
  ///
  /// In en, this message translates to:
  /// **'Dine-in'**
  String get dineIn;

  /// No description provided for @member.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get member;

  /// No description provided for @cashback.
  ///
  /// In en, this message translates to:
  /// **'Cashback'**
  String get cashback;

  /// No description provided for @accountSettings.
  ///
  /// In en, this message translates to:
  /// **'Account Settings'**
  String get accountSettings;

  /// No description provided for @safetyPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Safety & Privacy'**
  String get safetyPrivacy;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @sosEmergency.
  ///
  /// In en, this message translates to:
  /// **'SOS Emergency'**
  String get sosEmergency;

  /// No description provided for @sosEmergencySub.
  ///
  /// In en, this message translates to:
  /// **'Trigger emergency signal'**
  String get sosEmergencySub;

  /// No description provided for @privacyPdpa.
  ///
  /// In en, this message translates to:
  /// **'Privacy (PDPA)'**
  String get privacyPdpa;

  /// No description provided for @privacyPdpaSub.
  ///
  /// In en, this message translates to:
  /// **'Manage personal data'**
  String get privacyPdpaSub;

  /// No description provided for @orders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get orders;

  /// No description provided for @addresses.
  ///
  /// In en, this message translates to:
  /// **'Addresses'**
  String get addresses;

  /// No description provided for @promos.
  ///
  /// In en, this message translates to:
  /// **'Promos'**
  String get promos;

  /// No description provided for @wallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get wallet;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @calculatingPrice.
  ///
  /// In en, this message translates to:
  /// **'Calculating price...'**
  String get calculatingPrice;

  /// No description provided for @baseFareLabel.
  ///
  /// In en, this message translates to:
  /// **'Base fare'**
  String get baseFareLabel;

  /// No description provided for @promoLabel.
  ///
  /// In en, this message translates to:
  /// **'Coupon'**
  String get promoLabel;

  /// No description provided for @requestRideNow.
  ///
  /// In en, this message translates to:
  /// **'Request Ride Now'**
  String get requestRideNow;

  /// No description provided for @promotionTitle.
  ///
  /// In en, this message translates to:
  /// **'Promotion'**
  String get promotionTitle;

  /// No description provided for @enterPromoHint.
  ///
  /// In en, this message translates to:
  /// **'Enter promo code'**
  String get enterPromoHint;

  /// No description provided for @applyLabel.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get applyLabel;

  /// No description provided for @deliveryInfo.
  ///
  /// In en, this message translates to:
  /// **'Delivery info'**
  String get deliveryInfo;

  /// No description provided for @addressName.
  ///
  /// In en, this message translates to:
  /// **'Address name'**
  String get addressName;

  /// No description provided for @addressNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Home, Office, School'**
  String get addressNameHint;

  /// No description provided for @contactInfo.
  ///
  /// In en, this message translates to:
  /// **'Contact info'**
  String get contactInfo;

  /// No description provided for @contactName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get contactName;

  /// No description provided for @addressInfo.
  ///
  /// In en, this message translates to:
  /// **'Address info'**
  String get addressInfo;

  /// No description provided for @chooseFromMap.
  ///
  /// In en, this message translates to:
  /// **'Choose from the map'**
  String get chooseFromMap;

  /// No description provided for @noteToRider.
  ///
  /// In en, this message translates to:
  /// **'Note to rider'**
  String get noteToRider;

  /// No description provided for @noteToRiderHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. White house with green roof'**
  String get noteToRiderHint;

  /// No description provided for @cannotSaveAddress.
  ///
  /// In en, this message translates to:
  /// **'Cannot save address at this time'**
  String get cannotSaveAddress;

  /// No description provided for @setAsDefaultAddress.
  ///
  /// In en, this message translates to:
  /// **'Set as default address'**
  String get setAsDefaultAddress;

  /// No description provided for @noRecentSearches.
  ///
  /// In en, this message translates to:
  /// **'No recent searches yet'**
  String get noRecentSearches;

  /// No description provided for @recommendedEmpty.
  ///
  /// In en, this message translates to:
  /// **'No recommendations yet'**
  String get recommendedEmpty;

  /// No description provided for @searchError.
  ///
  /// In en, this message translates to:
  /// **'Search failed. Tap to retry.'**
  String get searchError;

  /// No description provided for @selectPickupFirst.
  ///
  /// In en, this message translates to:
  /// **'Please choose a pickup point first'**
  String get selectPickupFirst;

  /// No description provided for @useCurrentLocation.
  ///
  /// In en, this message translates to:
  /// **'Use current location'**
  String get useCurrentLocation;

  /// No description provided for @clearField.
  ///
  /// In en, this message translates to:
  /// **'Clear text'**
  String get clearField;

  /// No description provided for @promptPay.
  ///
  /// In en, this message translates to:
  /// **'PromptPay'**
  String get promptPay;

  /// No description provided for @selectPaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Select payment method'**
  String get selectPaymentMethod;

  /// No description provided for @couponDiscount.
  ///
  /// In en, this message translates to:
  /// **'Coupon discount'**
  String get couponDiscount;

  /// No description provided for @selectVehicleFirst.
  ///
  /// In en, this message translates to:
  /// **'Choose a vehicle type first'**
  String get selectVehicleFirst;

  /// No description provided for @couponApplied.
  ///
  /// In en, this message translates to:
  /// **'Coupon \"{code}\" applied'**
  String couponApplied(String code);

  /// No description provided for @couponRemoved.
  ///
  /// In en, this message translates to:
  /// **'Coupon removed'**
  String get couponRemoved;

  /// No description provided for @requestRideWith.
  ///
  /// In en, this message translates to:
  /// **'Request {vehicle} · ฿{fare}'**
  String requestRideWith(String vehicle, String fare);
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
      <String>['en', 'th'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'th':
      return AppLocalizationsTh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
