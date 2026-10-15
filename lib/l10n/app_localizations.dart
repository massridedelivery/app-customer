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
  /// **'Mass Delivery'**
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

  /// No description provided for @noFoodOrdersYet.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t ordered any food yet.'**
  String get noFoodOrdersYet;

  /// No description provided for @noDeliveriesYet.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t sent any parcels yet.'**
  String get noDeliveriesYet;

  /// No description provided for @noOrdersYet.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have any orders yet.'**
  String get noOrdersYet;

  /// No description provided for @fareEstimateFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t calculate the fare'**
  String get fareEstimateFailed;

  /// No description provided for @choosePickupAction.
  ///
  /// In en, this message translates to:
  /// **'Choose pickup'**
  String get choosePickupAction;

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

  /// No description provided for @msgVehicleBike.
  ///
  /// In en, this message translates to:
  /// **'Bike'**
  String get msgVehicleBike;

  /// No description provided for @msgVehicleCar.
  ///
  /// In en, this message translates to:
  /// **'Car'**
  String get msgVehicleCar;

  /// No description provided for @msgSizeSmall.
  ///
  /// In en, this message translates to:
  /// **'Small'**
  String get msgSizeSmall;

  /// No description provided for @msgSizeMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get msgSizeMedium;

  /// No description provided for @msgSizeLarge.
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get msgSizeLarge;

  /// No description provided for @gelPromo.
  ///
  /// In en, this message translates to:
  /// **'Add Gel then call now'**
  String get gelPromo;

  /// No description provided for @readyToGo.
  ///
  /// In en, this message translates to:
  /// **'Ready to go'**
  String get readyToGo;

  /// No description provided for @readyCallNow.
  ///
  /// In en, this message translates to:
  /// **'All set — ride now'**
  String get readyCallNow;

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

  /// No description provided for @pickupNotReady.
  ///
  /// In en, this message translates to:
  /// **'Finding your pickup location — enable location or set a pickup point first.'**
  String get pickupNotReady;

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

  /// No description provided for @fullNameHint.
  ///
  /// In en, this message translates to:
  /// **'First name - Last name'**
  String get fullNameHint;

  /// No description provided for @forgotPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Don\'t worry! Just enter your email and we\'ll send you a code to reset your password.'**
  String get forgotPasswordSubtitle;

  /// No description provided for @sendResetCode.
  ///
  /// In en, this message translates to:
  /// **'Send Code'**
  String get sendResetCode;

  /// No description provided for @resetOtpSentMsg.
  ///
  /// In en, this message translates to:
  /// **'A verification code (OTP) has been sent to your email\n{email}'**
  String resetOtpSentMsg(String email);

  /// No description provided for @setNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Set New Password'**
  String get setNewPassword;

  /// No description provided for @setNewPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Please choose a strong, hard-to-guess password to keep your account secure.'**
  String get setNewPasswordSubtitle;

  /// No description provided for @newPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPasswordLabel;

  /// No description provided for @confirmNewPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get confirmNewPasswordLabel;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @passwordChangedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Your password has been changed. Please sign in with your new password.'**
  String get passwordChangedSuccess;

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

  /// No description provided for @creditCard.
  ///
  /// In en, this message translates to:
  /// **'Credit Card'**
  String get creditCard;

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
  /// **'No recent trips yet'**
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

  /// No description provided for @couponNotAppliedToFare.
  ///
  /// In en, this message translates to:
  /// **'Code {code} hasn\'t been taken off the fare'**
  String couponNotAppliedToFare(String code);

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

  /// No description provided for @map.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get map;

  /// No description provided for @experienceTitle.
  ///
  /// In en, this message translates to:
  /// **'Why Mass Move'**
  String get experienceTitle;

  /// No description provided for @expRidesTitle.
  ///
  /// In en, this message translates to:
  /// **'A ride for every journey'**
  String get expRidesTitle;

  /// No description provided for @expRidesSub.
  ///
  /// In en, this message translates to:
  /// **'Motorbike, car, taxi, or premium — choose what fits each trip'**
  String get expRidesSub;

  /// No description provided for @expSafetyTitle.
  ///
  /// In en, this message translates to:
  /// **'Safety comes first'**
  String get expSafetyTitle;

  /// No description provided for @expSafetySub.
  ///
  /// In en, this message translates to:
  /// **'Background-checked drivers and safety features that look after you the whole way'**
  String get expSafetySub;

  /// No description provided for @expFareTitle.
  ///
  /// In en, this message translates to:
  /// **'Transparent fares, no surprises'**
  String get expFareTitle;

  /// No description provided for @expFareSub.
  ///
  /// In en, this message translates to:
  /// **'Know the price up front before you ride — no hidden charges'**
  String get expFareSub;

  /// No description provided for @experiencePremiumTitle.
  ///
  /// In en, this message translates to:
  /// **'Premium rides'**
  String get experiencePremiumTitle;

  /// No description provided for @experiencePremiumSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Cars with every comfort on board'**
  String get experiencePremiumSubtitle;

  /// No description provided for @experienceAirportTitle.
  ///
  /// In en, this message translates to:
  /// **'To the airport, on time'**
  String get experienceAirportTitle;

  /// No description provided for @experienceAirportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Book ahead and never miss a flight'**
  String get experienceAirportSubtitle;

  /// No description provided for @experienceSafetyTitle.
  ///
  /// In en, this message translates to:
  /// **'Safe on every route'**
  String get experienceSafetyTitle;

  /// No description provided for @experienceSafetySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Live location sharing + SOS button'**
  String get experienceSafetySubtitle;

  /// No description provided for @experienceValueTitle.
  ///
  /// In en, this message translates to:
  /// **'Great value, cheaper for sure'**
  String get experienceValueTitle;

  /// No description provided for @experienceValueSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Transparent fares — know the price before you ride'**
  String get experienceValueSubtitle;

  /// No description provided for @locationPermissionHint.
  ///
  /// In en, this message translates to:
  /// **'Allow location access to use your current location as the pickup.'**
  String get locationPermissionHint;

  /// No description provided for @locationServiceOffHint.
  ///
  /// In en, this message translates to:
  /// **'Turn on location services to use your current location.'**
  String get locationServiceOffHint;

  /// No description provided for @locationUnavailableHint.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t get your current location.'**
  String get locationUnavailableHint;

  /// No description provided for @allowLocation.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get allowLocation;

  /// No description provided for @couponValidUntil.
  ///
  /// In en, this message translates to:
  /// **'Valid until {date}'**
  String couponValidUntil(String date);

  /// No description provided for @promoValidUntilShort.
  ///
  /// In en, this message translates to:
  /// **'Until {date}'**
  String promoValidUntilShort(String date);

  /// No description provided for @promoValidUntilFull.
  ///
  /// In en, this message translates to:
  /// **'Valid until {date}, {time}'**
  String promoValidUntilFull(String date, String time);

  /// No description provided for @orderedAt.
  ///
  /// In en, this message translates to:
  /// **'Ordered: {date}'**
  String orderedAt(String date);

  /// No description provided for @etaArrivingSoonAround.
  ///
  /// In en, this message translates to:
  /// **'Arriving soon · around {time}'**
  String etaArrivingSoonAround(String time);

  /// No description provided for @etaMinutesArriveAround.
  ///
  /// In en, this message translates to:
  /// **'About {minutes} min · arrives around {time}'**
  String etaMinutesArriveAround(int minutes, String time);

  /// No description provided for @deliverByAround.
  ///
  /// In en, this message translates to:
  /// **'Delivered by about {time}'**
  String deliverByAround(String time);

  /// No description provided for @pickupInMinutes.
  ///
  /// In en, this message translates to:
  /// **'Pickup in {minutes} min'**
  String pickupInMinutes(int minutes);

  /// No description provided for @etaIn.
  ///
  /// In en, this message translates to:
  /// **'In'**
  String get etaIn;

  /// No description provided for @etaAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get etaAbout;

  /// No description provided for @etaArriveApprox.
  ///
  /// In en, this message translates to:
  /// **'arrives ~{time}'**
  String etaArriveApprox(String time);

  /// No description provided for @etaExpectedArrival.
  ///
  /// In en, this message translates to:
  /// **'Expected arrival'**
  String get etaExpectedArrival;

  /// No description provided for @etaExpectedAround.
  ///
  /// In en, this message translates to:
  /// **'Expected around {time}'**
  String etaExpectedAround(String time);

  /// No description provided for @homeChooseDeliveryLocation.
  ///
  /// In en, this message translates to:
  /// **'Deliver to'**
  String get homeChooseDeliveryLocation;

  /// No description provided for @homePleaseChooseLocation.
  ///
  /// In en, this message translates to:
  /// **'Choose a location'**
  String get homePleaseChooseLocation;

  /// No description provided for @homeWhatToOrder.
  ///
  /// In en, this message translates to:
  /// **'What are you craving?'**
  String get homeWhatToOrder;

  /// No description provided for @homeServiceRide.
  ///
  /// In en, this message translates to:
  /// **'Ride'**
  String get homeServiceRide;

  /// No description provided for @homeServiceRideSub.
  ///
  /// In en, this message translates to:
  /// **'Your first ride'**
  String get homeServiceRideSub;

  /// No description provided for @homeServiceFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get homeServiceFood;

  /// No description provided for @homeServiceFoodSub.
  ///
  /// In en, this message translates to:
  /// **'Best prices daily'**
  String get homeServiceFoodSub;

  /// No description provided for @homeServiceMessenger.
  ///
  /// In en, this message translates to:
  /// **'Messenger'**
  String get homeServiceMessenger;

  /// No description provided for @homeServiceMessengerSub.
  ///
  /// In en, this message translates to:
  /// **'Parcels & packages'**
  String get homeServiceMessengerSub;

  /// No description provided for @homeServiceParcel.
  ///
  /// In en, this message translates to:
  /// **'Parcel delivery'**
  String get homeServiceParcel;

  /// No description provided for @homeYourArea.
  ///
  /// In en, this message translates to:
  /// **'your area'**
  String get homeYourArea;

  /// No description provided for @homeComingSoonInYourArea.
  ///
  /// In en, this message translates to:
  /// **'Coming soon to your area'**
  String get homeComingSoonInYourArea;

  /// No description provided for @homeZoneComingSoonMessage.
  ///
  /// In en, this message translates to:
  /// **'{service} is coming soon to {area}. Drivers may not be available yet.'**
  String homeZoneComingSoonMessage(String service, String area);

  /// No description provided for @homeYourLocation.
  ///
  /// In en, this message translates to:
  /// **'Your location: {area}'**
  String homeYourLocation(String area);

  /// No description provided for @homeArticlesTitle.
  ///
  /// In en, this message translates to:
  /// **'Tips & insights from MASS'**
  String get homeArticlesTitle;

  /// No description provided for @homeArticleCatServices.
  ///
  /// In en, this message translates to:
  /// **'Our services'**
  String get homeArticleCatServices;

  /// No description provided for @homeArticleCatTips.
  ///
  /// In en, this message translates to:
  /// **'Tips'**
  String get homeArticleCatTips;

  /// No description provided for @homeArticleCatSafety.
  ///
  /// In en, this message translates to:
  /// **'Safety'**
  String get homeArticleCatSafety;

  /// No description provided for @homeArticleMassTitle.
  ///
  /// In en, this message translates to:
  /// **'What is MASS? Meet the Thai super app that does it all'**
  String get homeArticleMassTitle;

  /// No description provided for @homeArticleFoodTitle.
  ///
  /// In en, this message translates to:
  /// **'5 tips for food delivery that\'s great value and as tasty as dining in'**
  String get homeArticleFoodTitle;

  /// No description provided for @homeArticleRideTitle.
  ///
  /// In en, this message translates to:
  /// **'Ride safe with MASS Ride: safety features you should know'**
  String get homeArticleRideTitle;

  /// No description provided for @homePromosForYou.
  ///
  /// In en, this message translates to:
  /// **'Promotions for you'**
  String get homePromosForYou;

  /// No description provided for @homeRecentTrips.
  ///
  /// In en, this message translates to:
  /// **'Recent trips'**
  String get homeRecentTrips;

  /// No description provided for @homeSelectedLocation.
  ///
  /// In en, this message translates to:
  /// **'Selected location'**
  String get homeSelectedLocation;

  /// No description provided for @homeActiveRide.
  ///
  /// In en, this message translates to:
  /// **'Your ride'**
  String get homeActiveRide;

  /// No description provided for @homeActiveFood.
  ///
  /// In en, this message translates to:
  /// **'Food order'**
  String get homeActiveFood;

  /// No description provided for @homeViewStatus.
  ///
  /// In en, this message translates to:
  /// **'View status'**
  String get homeViewStatus;

  /// No description provided for @homeStatusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress...'**
  String get homeStatusInProgress;

  /// No description provided for @homeStatusFindingDriver.
  ///
  /// In en, this message translates to:
  /// **'Finding a driver...'**
  String get homeStatusFindingDriver;

  /// No description provided for @homeFoodStatusPlaced.
  ///
  /// In en, this message translates to:
  /// **'Placing your order...'**
  String get homeFoodStatusPlaced;

  /// No description provided for @homeFoodStatusConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Order confirmed'**
  String get homeFoodStatusConfirmed;

  /// No description provided for @homeFoodStatusPreparing.
  ///
  /// In en, this message translates to:
  /// **'The restaurant is preparing your food...'**
  String get homeFoodStatusPreparing;

  /// No description provided for @homeFoodStatusReady.
  ///
  /// In en, this message translates to:
  /// **'Ready - waiting for pickup'**
  String get homeFoodStatusReady;

  /// No description provided for @homeFoodStatusRiderAssigned.
  ///
  /// In en, this message translates to:
  /// **'Rider assigned'**
  String get homeFoodStatusRiderAssigned;

  /// No description provided for @homeFoodStatusOnTheWay.
  ///
  /// In en, this message translates to:
  /// **'Your food is on the way'**
  String get homeFoodStatusOnTheWay;

  /// No description provided for @homeRideStatusAccepted.
  ///
  /// In en, this message translates to:
  /// **'Driver accepted'**
  String get homeRideStatusAccepted;

  /// No description provided for @homeRideStatusArrived.
  ///
  /// In en, this message translates to:
  /// **'Driver has arrived at pickup'**
  String get homeRideStatusArrived;

  /// No description provided for @homeRideStatusOnTrip.
  ///
  /// In en, this message translates to:
  /// **'On the way'**
  String get homeRideStatusOnTrip;

  /// No description provided for @homeParcelStatusAccepted.
  ///
  /// In en, this message translates to:
  /// **'Driver accepted the job'**
  String get homeParcelStatusAccepted;

  /// No description provided for @homeParcelStatusArrived.
  ///
  /// In en, this message translates to:
  /// **'Driver is at the pickup point'**
  String get homeParcelStatusArrived;

  /// No description provided for @homeParcelStatusDelivering.
  ///
  /// In en, this message translates to:
  /// **'Delivering your parcel'**
  String get homeParcelStatusDelivering;

  /// No description provided for @homeChooseAddress.
  ///
  /// In en, this message translates to:
  /// **'Choose address'**
  String get homeChooseAddress;

  /// No description provided for @homeUseThisPickup.
  ///
  /// In en, this message translates to:
  /// **'Use this pickup point'**
  String get homeUseThisPickup;

  /// No description provided for @homeUseThisFoodDropoff.
  ///
  /// In en, this message translates to:
  /// **'Deliver food here'**
  String get homeUseThisFoodDropoff;

  /// No description provided for @homeUseThisDestination.
  ///
  /// In en, this message translates to:
  /// **'Use this destination'**
  String get homeUseThisDestination;

  /// No description provided for @homePlaceNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Home, Work, Gym'**
  String get homePlaceNameHint;

  /// No description provided for @homeChooseParcelDropoff.
  ///
  /// In en, this message translates to:
  /// **'Choose drop-off point'**
  String get homeChooseParcelDropoff;

  /// No description provided for @homeChooseParcelPickup.
  ///
  /// In en, this message translates to:
  /// **'Choose pickup point'**
  String get homeChooseParcelPickup;

  /// No description provided for @homeSearchParcelDropoff.
  ///
  /// In en, this message translates to:
  /// **'Search for a drop-off point'**
  String get homeSearchParcelDropoff;

  /// No description provided for @homeSearchParcelPickup.
  ///
  /// In en, this message translates to:
  /// **'Search for a pickup point'**
  String get homeSearchParcelPickup;

  /// No description provided for @homeFoodLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Delivery location'**
  String get homeFoodLocationTitle;

  /// No description provided for @homeFoodWhereHint.
  ///
  /// In en, this message translates to:
  /// **'Where should we deliver?'**
  String get homeFoodWhereHint;

  /// No description provided for @homeChooseOnMap.
  ///
  /// In en, this message translates to:
  /// **'Choose on map'**
  String get homeChooseOnMap;

  /// No description provided for @homeNoRecentPlaces.
  ///
  /// In en, this message translates to:
  /// **'No recent places yet'**
  String get homeNoRecentPlaces;

  /// No description provided for @homeNoSavedPlaces.
  ///
  /// In en, this message translates to:
  /// **'No saved places yet'**
  String get homeNoSavedPlaces;

  /// No description provided for @homeSearchFoodHint.
  ///
  /// In en, this message translates to:
  /// **'Search restaurants or dishes'**
  String get homeSearchFoodHint;

  /// No description provided for @homeErrorDetail.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String homeErrorDetail(String error);

  /// No description provided for @homeSearchFoodPrompt.
  ///
  /// In en, this message translates to:
  /// **'Search for what you\'re craving'**
  String get homeSearchFoodPrompt;

  /// No description provided for @homeNoResultsFor.
  ///
  /// In en, this message translates to:
  /// **'No results for \"{query}\"'**
  String homeNoResultsFor(String query);

  /// No description provided for @homeRestaurants.
  ///
  /// In en, this message translates to:
  /// **'Restaurants'**
  String get homeRestaurants;

  /// No description provided for @homeRestaurant.
  ///
  /// In en, this message translates to:
  /// **'Restaurant'**
  String get homeRestaurant;

  /// No description provided for @homeCategoryNotFound.
  ///
  /// In en, this message translates to:
  /// **'Category not found'**
  String get homeCategoryNotFound;

  /// No description provided for @homeNoRestaurantsInCategory.
  ///
  /// In en, this message translates to:
  /// **'No restaurants in this category'**
  String get homeNoRestaurantsInCategory;

  /// No description provided for @homeClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get homeClosed;

  /// No description provided for @homeStartingPrice.
  ///
  /// In en, this message translates to:
  /// **'From ฿{price}'**
  String homeStartingPrice(String price);

  /// No description provided for @homeSelectAtLeast.
  ///
  /// In en, this message translates to:
  /// **'Select at least {count}'**
  String homeSelectAtLeast(int count);

  /// No description provided for @homeOptionalAddOns.
  ///
  /// In en, this message translates to:
  /// **'Optional add-ons'**
  String get homeOptionalAddOns;

  /// No description provided for @homeUpToItems.
  ///
  /// In en, this message translates to:
  /// **'(up to {count})'**
  String homeUpToItems(int count);

  /// No description provided for @homeSpecialInstructions.
  ///
  /// In en, this message translates to:
  /// **'Special instructions'**
  String get homeSpecialInstructions;

  /// No description provided for @homeOptional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get homeOptional;

  /// No description provided for @homeNoteHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. less spicy, no fried garlic'**
  String get homeNoteHint;

  /// No description provided for @homeAddToCart.
  ///
  /// In en, this message translates to:
  /// **'Add to cart - ฿{total}'**
  String homeAddToCart(String total);

  /// No description provided for @commonComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get commonComingSoon;

  /// No description provided for @commonComingSoonMessage.
  ///
  /// In en, this message translates to:
  /// **'This service is launching soon.'**
  String get commonComingSoonMessage;

  /// No description provided for @commonGotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get commonGotIt;

  /// No description provided for @commonCantConnect.
  ///
  /// In en, this message translates to:
  /// **'Can\'t connect to the internet'**
  String get commonCantConnect;

  /// No description provided for @commonNoInternet.
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get commonNoInternet;

  /// No description provided for @commonWeakConnection.
  ///
  /// In en, this message translates to:
  /// **'Weak or unstable connection'**
  String get commonWeakConnection;

  /// No description provided for @commonCheckWifi.
  ///
  /// In en, this message translates to:
  /// **'Check your Wi-Fi or mobile data'**
  String get commonCheckWifi;

  /// No description provided for @commonSlowConnection.
  ///
  /// In en, this message translates to:
  /// **'Slow connection, things may not run smoothly'**
  String get commonSlowConnection;

  /// No description provided for @commonGoToSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get commonGoToSettings;

  /// No description provided for @commonCheckAgain.
  ///
  /// In en, this message translates to:
  /// **'Check again'**
  String get commonCheckAgain;

  /// No description provided for @commonLoginFirst.
  ///
  /// In en, this message translates to:
  /// **'Please log in'**
  String get commonLoginFirst;

  /// No description provided for @commonLoginToUse.
  ///
  /// In en, this message translates to:
  /// **'Log in to use this service'**
  String get commonLoginToUse;

  /// No description provided for @commonContinueBrowsing.
  ///
  /// In en, this message translates to:
  /// **'Continue browsing'**
  String get commonContinueBrowsing;

  /// No description provided for @commonLoadError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong while loading'**
  String get commonLoadError;

  /// No description provided for @commonNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get commonNext;

  /// No description provided for @commonBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get commonBack;

  /// No description provided for @commonCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get commonCopy;

  /// No description provided for @promoUseCoupon.
  ///
  /// In en, this message translates to:
  /// **'Use'**
  String get promoUseCoupon;

  /// No description provided for @promoApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get promoApply;

  /// No description provided for @promoEnterCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Enter a coupon code'**
  String get promoEnterCodeHint;

  /// No description provided for @promoViewDetails.
  ///
  /// In en, this message translates to:
  /// **'View details ›'**
  String get promoViewDetails;

  /// No description provided for @promoMinSpend.
  ///
  /// In en, this message translates to:
  /// **'Min. ฿{amount}'**
  String promoMinSpend(String amount);

  /// No description provided for @promoMaxDiscount.
  ///
  /// In en, this message translates to:
  /// **'Up to ฿{amount}'**
  String promoMaxDiscount(String amount);

  /// No description provided for @promoStubOff.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get promoStubOff;

  /// No description provided for @promoHeadlinePercent.
  ///
  /// In en, this message translates to:
  /// **'{value}% off'**
  String promoHeadlinePercent(String value);

  /// No description provided for @promoHeadlineBaht.
  ///
  /// In en, this message translates to:
  /// **'฿{value} off'**
  String promoHeadlineBaht(String value);

  /// No description provided for @promoHeadlineFallback.
  ///
  /// In en, this message translates to:
  /// **'Promotion'**
  String get promoHeadlineFallback;

  /// No description provided for @promoScopeAll.
  ///
  /// In en, this message translates to:
  /// **'All services'**
  String get promoScopeAll;

  /// No description provided for @promoScopeRide.
  ///
  /// In en, this message translates to:
  /// **'Rides only'**
  String get promoScopeRide;

  /// No description provided for @promoScopeFood.
  ///
  /// In en, this message translates to:
  /// **'Food only'**
  String get promoScopeFood;

  /// No description provided for @promoScopeMessenger.
  ///
  /// In en, this message translates to:
  /// **'Messenger only'**
  String get promoScopeMessenger;

  /// No description provided for @promoTabEverything.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get promoTabEverything;

  /// No description provided for @promoTabGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get promoTabGeneral;

  /// No description provided for @promoTabRide.
  ///
  /// In en, this message translates to:
  /// **'Ride'**
  String get promoTabRide;

  /// No description provided for @promoTabMessenger.
  ///
  /// In en, this message translates to:
  /// **'Messenger'**
  String get promoTabMessenger;

  /// No description provided for @promoMyPromos.
  ///
  /// In en, this message translates to:
  /// **'My promotions'**
  String get promoMyPromos;

  /// No description provided for @promoLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading promotions...'**
  String get promoLoading;

  /// No description provided for @promoNoneNow.
  ///
  /// In en, this message translates to:
  /// **'No promotions right now'**
  String get promoNoneNow;

  /// No description provided for @promoNotFound.
  ///
  /// In en, this message translates to:
  /// **'This promotion wasn\'t found'**
  String get promoNotFound;

  /// No description provided for @promoInvalidCode.
  ///
  /// In en, this message translates to:
  /// **'Invalid promotion code'**
  String get promoInvalidCode;

  /// No description provided for @promoCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Promo code'**
  String get promoCodeLabel;

  /// No description provided for @promoCodeCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied {code}!'**
  String promoCodeCopied(String code);

  /// No description provided for @promoTerms.
  ///
  /// In en, this message translates to:
  /// **'Terms & conditions'**
  String get promoTerms;

  /// No description provided for @promoRejectedFallback.
  ///
  /// In en, this message translates to:
  /// **'This coupon can\'t be used for this order'**
  String get promoRejectedFallback;

  /// No description provided for @promoRejectNewUser.
  ///
  /// In en, this message translates to:
  /// **'This coupon is for new customers only'**
  String get promoRejectNewUser;

  /// No description provided for @promoRejectExpired.
  ///
  /// In en, this message translates to:
  /// **'This coupon has expired'**
  String get promoRejectExpired;

  /// No description provided for @promoRejectNotStarted.
  ///
  /// In en, this message translates to:
  /// **'This coupon isn\'t active yet'**
  String get promoRejectNotStarted;

  /// No description provided for @promoRejectLimit.
  ///
  /// In en, this message translates to:
  /// **'You\'ve reached the usage limit for this coupon'**
  String get promoRejectLimit;

  /// No description provided for @promoRejectMinSpend.
  ///
  /// In en, this message translates to:
  /// **'Your order hasn\'t reached this coupon\'s minimum'**
  String get promoRejectMinSpend;

  /// No description provided for @promoRejectNotFound.
  ///
  /// In en, this message translates to:
  /// **'Coupon code not found'**
  String get promoRejectNotFound;

  /// No description provided for @promoRejectWrongService.
  ///
  /// In en, this message translates to:
  /// **'This coupon can\'t be used for this service'**
  String get promoRejectWrongService;

  /// No description provided for @errGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errGeneric;

  /// No description provided for @errLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load data'**
  String get errLoadFailed;

  /// No description provided for @errTimeout.
  ///
  /// In en, this message translates to:
  /// **'The connection timed out. Please try again.'**
  String get errTimeout;

  /// No description provided for @errConnection.
  ///
  /// In en, this message translates to:
  /// **'Can\'t reach the server. Check your internet connection and try again.'**
  String get errConnection;

  /// No description provided for @errUnauthorized.
  ///
  /// In en, this message translates to:
  /// **'You\'re not authorized. Please log in again.'**
  String get errUnauthorized;

  /// No description provided for @errNotFound.
  ///
  /// In en, this message translates to:
  /// **'The requested information wasn\'t found.'**
  String get errNotFound;

  /// No description provided for @errTooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many requests. Please try again.'**
  String get errTooManyRequests;

  /// No description provided for @errServer.
  ///
  /// In en, this message translates to:
  /// **'The system is temporarily unavailable. Please try again later.'**
  String get errServer;

  /// No description provided for @errBadRequest.
  ///
  /// In en, this message translates to:
  /// **'Invalid request. Please check and try again.'**
  String get errBadRequest;

  /// No description provided for @errPlaceSearch.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t search for places'**
  String get errPlaceSearch;

  /// No description provided for @errPlaceDetails.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t get place details'**
  String get errPlaceDetails;

  /// No description provided for @errRecentPlaces.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load recent places'**
  String get errRecentPlaces;

  /// No description provided for @errSavedPlaces.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load saved places'**
  String get errSavedPlaces;

  /// No description provided for @errSavePlace.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save the place'**
  String get errSavePlace;

  /// No description provided for @errSetDefaultPlace.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t set the default place'**
  String get errSetDefaultPlace;

  /// No description provided for @errGetDefaultPlace.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t get the default place'**
  String get errGetDefaultPlace;
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
