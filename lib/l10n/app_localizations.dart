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
  /// **'Code {code} can\'t be used on this trip'**
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

  /// No description provided for @msgrSelectPickupError.
  ///
  /// In en, this message translates to:
  /// **'Please choose a pickup point'**
  String get msgrSelectPickupError;

  /// No description provided for @msgrSelectDropoffError.
  ///
  /// In en, this message translates to:
  /// **'Please choose a drop-off point'**
  String get msgrSelectDropoffError;

  /// No description provided for @msgrRecipientNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter the recipient\'s name'**
  String get msgrRecipientNameRequired;

  /// No description provided for @msgrRecipientPhoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter the recipient\'s phone number'**
  String get msgrRecipientPhoneRequired;

  /// No description provided for @msgrRecipientPhoneInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid recipient phone number'**
  String get msgrRecipientPhoneInvalid;

  /// No description provided for @msgrPhoneInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid phone number'**
  String get msgrPhoneInvalid;

  /// No description provided for @msgrCalculatingPleaseWait.
  ///
  /// In en, this message translates to:
  /// **'Calculating the price, please wait'**
  String get msgrCalculatingPleaseWait;

  /// No description provided for @msgrTitle.
  ///
  /// In en, this message translates to:
  /// **'Messenger'**
  String get msgrTitle;

  /// No description provided for @msgrHeroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Parcel pickup and delivery — anywhere, anytime'**
  String get msgrHeroSubtitle;

  /// No description provided for @msgrSelectPickup.
  ///
  /// In en, this message translates to:
  /// **'Choose pickup point'**
  String get msgrSelectPickup;

  /// No description provided for @msgrSelectDropoff.
  ///
  /// In en, this message translates to:
  /// **'Choose drop-off point'**
  String get msgrSelectDropoff;

  /// No description provided for @msgrDeliveryTypeTitle.
  ///
  /// In en, this message translates to:
  /// **'How should we deliver?'**
  String get msgrDeliveryTypeTitle;

  /// No description provided for @msgrDeliveryOptionsHint.
  ///
  /// In en, this message translates to:
  /// **'Choose a drop-off and enter the weight to see delivery options'**
  String get msgrDeliveryOptionsHint;

  /// No description provided for @msgrNoService.
  ///
  /// In en, this message translates to:
  /// **'No messenger service available right now'**
  String get msgrNoService;

  /// No description provided for @msgrVehicleType.
  ///
  /// In en, this message translates to:
  /// **'Vehicle type'**
  String get msgrVehicleType;

  /// No description provided for @msgrPackageSize.
  ///
  /// In en, this message translates to:
  /// **'Parcel size'**
  String get msgrPackageSize;

  /// No description provided for @msgrSizeTierLimits.
  ///
  /// In en, this message translates to:
  /// **'≤ {weight} kg\n{length}×{width}×{height} cm'**
  String msgrSizeTierLimits(
    String weight,
    String length,
    String width,
    String height,
  );

  /// No description provided for @msgrFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get msgrFree;

  /// No description provided for @msgrSizeTier.
  ///
  /// In en, this message translates to:
  /// **'Size {tier}'**
  String msgrSizeTier(String tier);

  /// No description provided for @msgrPackageInfo.
  ///
  /// In en, this message translates to:
  /// **'Parcel details'**
  String get msgrPackageInfo;

  /// No description provided for @msgrWeightLabel.
  ///
  /// In en, this message translates to:
  /// **'Weight (kg) *'**
  String get msgrWeightLabel;

  /// No description provided for @msgrWeightHint.
  ///
  /// In en, this message translates to:
  /// **'Up to {max} kg'**
  String msgrWeightHint(String max);

  /// No description provided for @msgrWeightRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter the parcel weight'**
  String get msgrWeightRequired;

  /// No description provided for @msgrWeightOverTier.
  ///
  /// In en, this message translates to:
  /// **'Too heavy for size {tier} (max {max} kg)'**
  String msgrWeightOverTier(String tier, String max);

  /// No description provided for @msgrDimensionsOptional.
  ///
  /// In en, this message translates to:
  /// **'Parcel dimensions (optional)'**
  String get msgrDimensionsOptional;

  /// No description provided for @msgrLengthCm.
  ///
  /// In en, this message translates to:
  /// **'Length (cm)'**
  String get msgrLengthCm;

  /// No description provided for @msgrWidthCm.
  ///
  /// In en, this message translates to:
  /// **'Width (cm)'**
  String get msgrWidthCm;

  /// No description provided for @msgrHeightCm.
  ///
  /// In en, this message translates to:
  /// **'Height (cm)'**
  String get msgrHeightCm;

  /// No description provided for @msgrInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid'**
  String get msgrInvalid;

  /// No description provided for @msgrOverMaxCm.
  ///
  /// In en, this message translates to:
  /// **'Over {max} cm'**
  String msgrOverMaxCm(String max);

  /// No description provided for @msgrRecipientInfo.
  ///
  /// In en, this message translates to:
  /// **'Recipient details'**
  String get msgrRecipientInfo;

  /// No description provided for @msgrRecipientNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Recipient name *'**
  String get msgrRecipientNameLabel;

  /// No description provided for @msgrRecipientPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Recipient phone *'**
  String get msgrRecipientPhoneLabel;

  /// No description provided for @msgrRecipientPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 0812345678'**
  String get msgrRecipientPhoneHint;

  /// No description provided for @msgrNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Note to driver (optional)'**
  String get msgrNotesLabel;

  /// No description provided for @msgrNotesHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Fragile'**
  String get msgrNotesHint;

  /// No description provided for @msgrPayerTitle.
  ///
  /// In en, this message translates to:
  /// **'Who pays the delivery fee?'**
  String get msgrPayerTitle;

  /// No description provided for @msgrPayerSender.
  ///
  /// In en, this message translates to:
  /// **'Sender (you)'**
  String get msgrPayerSender;

  /// No description provided for @msgrPayerSenderSub.
  ///
  /// In en, this message translates to:
  /// **'Sender pays now'**
  String get msgrPayerSenderSub;

  /// No description provided for @msgrPayerRecipient.
  ///
  /// In en, this message translates to:
  /// **'Recipient'**
  String get msgrPayerRecipient;

  /// No description provided for @msgrPayerRecipientSub.
  ///
  /// In en, this message translates to:
  /// **'Recipient pays on delivery'**
  String get msgrPayerRecipientSub;

  /// No description provided for @msgrRecipientPaysNote.
  ///
  /// In en, this message translates to:
  /// **'The driver collects the fee from the recipient on delivery — you don\'t pay now'**
  String get msgrRecipientPaysNote;

  /// No description provided for @msgrPaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment method'**
  String get msgrPaymentMethod;

  /// No description provided for @msgrCod.
  ///
  /// In en, this message translates to:
  /// **'Cash on delivery'**
  String get msgrCod;

  /// No description provided for @msgrCodAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'COD amount (THB) *'**
  String get msgrCodAmountLabel;

  /// No description provided for @msgrCodAmountHint.
  ///
  /// In en, this message translates to:
  /// **'Up to 100,000 THB'**
  String get msgrCodAmountHint;

  /// No description provided for @msgrCodAmountRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter the COD amount'**
  String get msgrCodAmountRequired;

  /// No description provided for @msgrCodAmountMax.
  ///
  /// In en, this message translates to:
  /// **'Maximum 100,000 THB'**
  String get msgrCodAmountMax;

  /// No description provided for @msgrSelectPromoOptional.
  ///
  /// In en, this message translates to:
  /// **'Choose a promo code (optional)'**
  String get msgrSelectPromoOptional;

  /// No description provided for @msgrCalculating.
  ///
  /// In en, this message translates to:
  /// **'Calculating price...'**
  String get msgrCalculating;

  /// No description provided for @msgrPriceHint.
  ///
  /// In en, this message translates to:
  /// **'Choose a drop-off and enter the weight to see the price'**
  String get msgrPriceHint;

  /// No description provided for @msgrPriceSummary.
  ///
  /// In en, this message translates to:
  /// **'Price summary'**
  String get msgrPriceSummary;

  /// No description provided for @msgrDistanceDuration.
  ///
  /// In en, this message translates to:
  /// **'{km} km (~{minutes} min)'**
  String msgrDistanceDuration(String km, String minutes);

  /// No description provided for @msgrTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get msgrTotal;

  /// No description provided for @msgrDeliveryFee.
  ///
  /// In en, this message translates to:
  /// **'Delivery fee'**
  String get msgrDeliveryFee;

  /// No description provided for @msgrSizeFee.
  ///
  /// In en, this message translates to:
  /// **'Size fee'**
  String get msgrSizeFee;

  /// No description provided for @msgrExpressFee.
  ///
  /// In en, this message translates to:
  /// **'Express fee'**
  String get msgrExpressFee;

  /// No description provided for @msgrDiscount.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get msgrDiscount;

  /// No description provided for @msgrExtraFee.
  ///
  /// In en, this message translates to:
  /// **'Additional fee'**
  String get msgrExtraFee;

  /// No description provided for @msgrCallMessengerPrice.
  ///
  /// In en, this message translates to:
  /// **'Book messenger • ฿{amount}'**
  String msgrCallMessengerPrice(String amount);

  /// No description provided for @msgrCallMessenger.
  ///
  /// In en, this message translates to:
  /// **'Book messenger'**
  String get msgrCallMessenger;

  /// No description provided for @msgrLoadVehiclesFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load vehicle types. Please try again.'**
  String get msgrLoadVehiclesFailed;

  /// No description provided for @msgrNoDeliveryModes.
  ///
  /// In en, this message translates to:
  /// **'Delivery isn\'t available right now. Please try again later.'**
  String get msgrNoDeliveryModes;

  /// No description provided for @msgrEstimateFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t estimate the price. Please try again.'**
  String get msgrEstimateFailed;

  /// No description provided for @msgrDeliveryModeUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The selected delivery option is no longer available. Please choose again and retry.'**
  String get msgrDeliveryModeUnavailable;

  /// No description provided for @msgrCreateOrderFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t create the order. Please try again.'**
  String get msgrCreateOrderFailed;

  /// No description provided for @msgrPaidCannotCancel.
  ///
  /// In en, this message translates to:
  /// **'This order is already paid and can\'t be cancelled in the app. Please contact customer support for a refund.'**
  String get msgrPaidCannotCancel;

  /// No description provided for @msgrOrderAlreadyPaid.
  ///
  /// In en, this message translates to:
  /// **'This order is already paid'**
  String get msgrOrderAlreadyPaid;

  /// No description provided for @msgrRatingRequired.
  ///
  /// In en, this message translates to:
  /// **'Please rate your driver first'**
  String get msgrRatingRequired;

  /// No description provided for @msgrCancelTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel delivery'**
  String get msgrCancelTitle;

  /// No description provided for @msgrCancelConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel?'**
  String get msgrCancelConfirm;

  /// No description provided for @msgrCancelReasonHint.
  ///
  /// In en, this message translates to:
  /// **'Reason (optional)'**
  String get msgrCancelReasonHint;

  /// No description provided for @msgrNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get msgrNo;

  /// No description provided for @msgrYesCancel.
  ///
  /// In en, this message translates to:
  /// **'Yes, cancel'**
  String get msgrYesCancel;

  /// No description provided for @msgrCancelledSnack.
  ///
  /// In en, this message translates to:
  /// **'Delivery cancelled'**
  String get msgrCancelledSnack;

  /// No description provided for @msgrPayCashInstead.
  ///
  /// In en, this message translates to:
  /// **'Pay cash instead'**
  String get msgrPayCashInstead;

  /// No description provided for @msgrPayCashConfirm.
  ///
  /// In en, this message translates to:
  /// **'Pay the driver in cash at pickup/drop-off instead of scanning the QR?'**
  String get msgrPayCashConfirm;

  /// No description provided for @msgrYesPayCash.
  ///
  /// In en, this message translates to:
  /// **'Yes, pay cash'**
  String get msgrYesPayCash;

  /// No description provided for @msgrSwitchedToCash.
  ///
  /// In en, this message translates to:
  /// **'Switched to cash — pay the driver directly'**
  String get msgrSwitchedToCash;

  /// No description provided for @msgrCannotLoad.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load data'**
  String get msgrCannotLoad;

  /// No description provided for @msgrPickupPoint.
  ///
  /// In en, this message translates to:
  /// **'Pickup point'**
  String get msgrPickupPoint;

  /// No description provided for @msgrDropoffPoint.
  ///
  /// In en, this message translates to:
  /// **'Drop-off point'**
  String get msgrDropoffPoint;

  /// No description provided for @msgrScanDriverQr.
  ///
  /// In en, this message translates to:
  /// **'Scan the driver\'s QR to pay the ฿{amount} delivery fee'**
  String msgrScanDriverQr(String amount);

  /// No description provided for @msgrChatWithDriver.
  ///
  /// In en, this message translates to:
  /// **'Chat with driver'**
  String get msgrChatWithDriver;

  /// No description provided for @msgrRated.
  ///
  /// In en, this message translates to:
  /// **'Rated  ⭐ {rating}'**
  String msgrRated(String rating);

  /// No description provided for @msgrSummaryAndRate.
  ///
  /// In en, this message translates to:
  /// **'Summary & rating'**
  String get msgrSummaryAndRate;

  /// No description provided for @msgrStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get msgrStatusCancelled;

  /// No description provided for @msgrCancelReason.
  ///
  /// In en, this message translates to:
  /// **'Reason: {reason}'**
  String msgrCancelReason(String reason);

  /// No description provided for @msgrDriverId.
  ///
  /// In en, this message translates to:
  /// **'Driver #{id}'**
  String msgrDriverId(String id);

  /// No description provided for @msgrStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Finding a driver...'**
  String get msgrStatusPending;

  /// No description provided for @msgrStatusAccepted.
  ///
  /// In en, this message translates to:
  /// **'Driver accepted, heading to pickup'**
  String get msgrStatusAccepted;

  /// No description provided for @msgrStatusArrivedAtPickup.
  ///
  /// In en, this message translates to:
  /// **'Driver has arrived at pickup'**
  String get msgrStatusArrivedAtPickup;

  /// No description provided for @msgrStatusPickedUp.
  ///
  /// In en, this message translates to:
  /// **'Parcel picked up, on the way'**
  String get msgrStatusPickedUp;

  /// No description provided for @msgrStatusDelivered.
  ///
  /// In en, this message translates to:
  /// **'Parcel delivered'**
  String get msgrStatusDelivered;

  /// No description provided for @msgrStatusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress...'**
  String get msgrStatusInProgress;

  /// No description provided for @msgrStatusSubPending.
  ///
  /// In en, this message translates to:
  /// **'Looking for a driver near you...'**
  String get msgrStatusSubPending;

  /// No description provided for @msgrStatusSubAccepted.
  ///
  /// In en, this message translates to:
  /// **'Your driver is on the way to pick up the parcel'**
  String get msgrStatusSubAccepted;

  /// No description provided for @msgrStatusSubPickedUp.
  ///
  /// In en, this message translates to:
  /// **'Delivering your parcel to the drop-off'**
  String get msgrStatusSubPickedUp;

  /// No description provided for @msgrStatusSubDelivered.
  ///
  /// In en, this message translates to:
  /// **'Your parcel has been delivered'**
  String get msgrStatusSubDelivered;

  /// No description provided for @msgrSizeWeight.
  ///
  /// In en, this message translates to:
  /// **'Size {size} • {weight} kg'**
  String msgrSizeWeight(String size, String weight);

  /// No description provided for @msgrCodAmountChip.
  ///
  /// In en, this message translates to:
  /// **'Cash on delivery ฿{amount}'**
  String msgrCodAmountChip(String amount);

  /// No description provided for @msgrDeliveryFeeDistance.
  ///
  /// In en, this message translates to:
  /// **'Delivery fee ({km} km)'**
  String msgrDeliveryFeeDistance(String km);

  /// No description provided for @msgrDeliveryFeeWithMethod.
  ///
  /// In en, this message translates to:
  /// **'Delivery fee ({method})'**
  String msgrDeliveryFeeWithMethod(String method);

  /// No description provided for @msgrGoodsCod.
  ///
  /// In en, this message translates to:
  /// **'Goods payment on delivery'**
  String get msgrGoodsCod;

  /// No description provided for @msgrCollectAtPickup.
  ///
  /// In en, this message translates to:
  /// **'Collected at pickup'**
  String get msgrCollectAtPickup;

  /// No description provided for @msgrCollectAtDelivery.
  ///
  /// In en, this message translates to:
  /// **'Collected on delivery'**
  String get msgrCollectAtDelivery;

  /// No description provided for @msgrFeePaid.
  ///
  /// In en, this message translates to:
  /// **'Delivery fee paid'**
  String get msgrFeePaid;

  /// No description provided for @msgrFeePayer.
  ///
  /// In en, this message translates to:
  /// **'Fee paid by: {who}'**
  String msgrFeePayer(String who);

  /// No description provided for @msgrPaymentSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment summary'**
  String get msgrPaymentSummaryTitle;

  /// No description provided for @msgrNotSpecified.
  ///
  /// In en, this message translates to:
  /// **'Not specified'**
  String get msgrNotSpecified;

  /// No description provided for @msgrLoadDataFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load data'**
  String get msgrLoadDataFailed;

  /// No description provided for @msgrDeliveryRoute.
  ///
  /// In en, this message translates to:
  /// **'Delivery route'**
  String get msgrDeliveryRoute;

  /// No description provided for @msgrFeeSummary.
  ///
  /// In en, this message translates to:
  /// **'Delivery fee summary'**
  String get msgrFeeSummary;

  /// No description provided for @msgrCodWithTag.
  ///
  /// In en, this message translates to:
  /// **'Cash on delivery (COD)'**
  String get msgrCodWithTag;

  /// No description provided for @msgrPayOnDeliveryWith.
  ///
  /// In en, this message translates to:
  /// **'Pay on delivery ({method})'**
  String msgrPayOnDeliveryWith(String method);

  /// No description provided for @msgrTotalWith.
  ///
  /// In en, this message translates to:
  /// **'Total ({method})'**
  String msgrTotalWith(String method);

  /// No description provided for @msgrConfirmAndRate.
  ///
  /// In en, this message translates to:
  /// **'Confirm & rate'**
  String get msgrConfirmAndRate;

  /// No description provided for @msgrAlreadyReviewed.
  ///
  /// In en, this message translates to:
  /// **'You\'ve already rated this order'**
  String get msgrAlreadyReviewed;

  /// No description provided for @msgrReviewThanks.
  ///
  /// In en, this message translates to:
  /// **'Review sent. Thanks for your feedback!'**
  String get msgrReviewThanks;

  /// No description provided for @msgrRateDeliveryTitle.
  ///
  /// In en, this message translates to:
  /// **'Rate delivery'**
  String get msgrRateDeliveryTitle;

  /// No description provided for @msgrSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get msgrSkip;

  /// No description provided for @msgrHowWasDriver.
  ///
  /// In en, this message translates to:
  /// **'How was your driver?'**
  String get msgrHowWasDriver;

  /// No description provided for @msgrRateThisDelivery.
  ///
  /// In en, this message translates to:
  /// **'Rate this parcel delivery'**
  String get msgrRateThisDelivery;

  /// No description provided for @msgrCommentOptional.
  ///
  /// In en, this message translates to:
  /// **'Additional comments (optional)'**
  String get msgrCommentOptional;

  /// No description provided for @msgrCommentHint.
  ///
  /// In en, this message translates to:
  /// **'Tell us about your delivery...'**
  String get msgrCommentHint;

  /// No description provided for @msgrSubmitReview.
  ///
  /// In en, this message translates to:
  /// **'Submit review'**
  String get msgrSubmitReview;

  /// No description provided for @msgrSkipForNow.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get msgrSkipForNow;

  /// No description provided for @msgrSelectPromo.
  ///
  /// In en, this message translates to:
  /// **'Choose a promo code'**
  String get msgrSelectPromo;

  /// No description provided for @msgrApplyCode.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get msgrApplyCode;

  /// No description provided for @msgrEnterPromo.
  ///
  /// In en, this message translates to:
  /// **'Enter promo code'**
  String get msgrEnterPromo;

  /// No description provided for @msgrLoadPromosFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load promo codes'**
  String get msgrLoadPromosFailed;

  /// No description provided for @msgrNoPromos.
  ///
  /// In en, this message translates to:
  /// **'No promo codes yet'**
  String get msgrNoPromos;

  /// No description provided for @msgrAvailableCoupons.
  ///
  /// In en, this message translates to:
  /// **'Available coupons'**
  String get msgrAvailableCoupons;

  /// No description provided for @msgrSendFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t send the message. Please try again.'**
  String get msgrSendFailed;

  /// No description provided for @msgrYourDriver.
  ///
  /// In en, this message translates to:
  /// **'Your driver'**
  String get msgrYourDriver;

  /// No description provided for @msgrLoadMessagesFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load messages'**
  String get msgrLoadMessagesFailed;

  /// No description provided for @msgrTypeMessage.
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get msgrTypeMessage;

  /// No description provided for @rideDriversNearby.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 driver nearby} other{{count} drivers nearby}}'**
  String rideDriversNearby(int count);

  /// No description provided for @rideNoDriversNow.
  ///
  /// In en, this message translates to:
  /// **'No drivers available right now'**
  String get rideNoDriversNow;

  /// No description provided for @rideDiscountOff.
  ///
  /// In en, this message translates to:
  /// **'฿{amount} off'**
  String rideDiscountOff(String amount);

  /// No description provided for @rideDropoffUnspecified.
  ///
  /// In en, this message translates to:
  /// **'Drop-off not specified'**
  String get rideDropoffUnspecified;

  /// No description provided for @rideCouponNeedRoute.
  ///
  /// In en, this message translates to:
  /// **'Choose pickup and drop-off before using a coupon'**
  String get rideCouponNeedRoute;

  /// No description provided for @rideCouponInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid promo code'**
  String get rideCouponInvalid;

  /// No description provided for @rideCouponApplyFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t use this coupon. Please try again.'**
  String get rideCouponApplyFailed;

  /// No description provided for @rideCouponSelectTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a coupon'**
  String get rideCouponSelectTitle;

  /// No description provided for @rideCouponUse.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get rideCouponUse;

  /// No description provided for @rideCouponLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load coupons'**
  String get rideCouponLoadFailed;

  /// No description provided for @rideCouponAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available coupons'**
  String get rideCouponAvailable;

  /// No description provided for @rideCouponNoneAvailable.
  ///
  /// In en, this message translates to:
  /// **'No coupons available right now'**
  String get rideCouponNoneAvailable;

  /// No description provided for @rideFareEstimateFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t calculate the fare. Please try again.'**
  String get rideFareEstimateFailed;

  /// No description provided for @rideRequestFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t request a ride. Please try again.'**
  String get rideRequestFailed;

  /// No description provided for @liveNoDriverTitle.
  ///
  /// In en, this message translates to:
  /// **'No driver found yet'**
  String get liveNoDriverTitle;

  /// No description provided for @liveNoDriverBody.
  ///
  /// In en, this message translates to:
  /// **'No drivers are available right now. Keep searching, or change the service type?'**
  String get liveNoDriverBody;

  /// No description provided for @liveKeepSearching.
  ///
  /// In en, this message translates to:
  /// **'Keep searching'**
  String get liveKeepSearching;

  /// No description provided for @liveChangeService.
  ///
  /// In en, this message translates to:
  /// **'Change service'**
  String get liveChangeService;

  /// No description provided for @liveAutoCancelNoDriver.
  ///
  /// In en, this message translates to:
  /// **'Your ride was cancelled because no drivers are available right now'**
  String get liveAutoCancelNoDriver;

  /// No description provided for @liveAutoCancelled.
  ///
  /// In en, this message translates to:
  /// **'Your ride was cancelled automatically'**
  String get liveAutoCancelled;

  /// No description provided for @liveCancelledWithFee.
  ///
  /// In en, this message translates to:
  /// **'Ride cancelled • Cancellation fee ฿{fee}'**
  String liveCancelledWithFee(String fee);

  /// No description provided for @liveTripNumber.
  ///
  /// In en, this message translates to:
  /// **'Trip #{id}'**
  String liveTripNumber(String id);

  /// No description provided for @liveCancelRide.
  ///
  /// In en, this message translates to:
  /// **'Cancel ride'**
  String get liveCancelRide;

  /// No description provided for @liveCancelFeeConfirm.
  ///
  /// In en, this message translates to:
  /// **'Your driver has accepted. Cancelling now costs a ฿{fee} cancellation fee.\nCancel anyway?'**
  String liveCancelFeeConfirm(String fee);

  /// No description provided for @liveCancelMayFeeConfirm.
  ///
  /// In en, this message translates to:
  /// **'Your driver has accepted. Cancelling now may incur a cancellation fee.\nCancel anyway?'**
  String get liveCancelMayFeeConfirm;

  /// No description provided for @liveCancelRideQuestion.
  ///
  /// In en, this message translates to:
  /// **'Cancel ride?'**
  String get liveCancelRideQuestion;

  /// No description provided for @liveNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get liveNo;

  /// No description provided for @liveConfirmCancel.
  ///
  /// In en, this message translates to:
  /// **'Yes, cancel'**
  String get liveConfirmCancel;

  /// No description provided for @liveTripCancelledSub.
  ///
  /// In en, this message translates to:
  /// **'This trip has been cancelled'**
  String get liveTripCancelledSub;

  /// No description provided for @liveFindingNearYou.
  ///
  /// In en, this message translates to:
  /// **'Looking for drivers near you...'**
  String get liveFindingNearYou;

  /// No description provided for @liveDriverOnTheWay.
  ///
  /// In en, this message translates to:
  /// **'Your driver is on the way'**
  String get liveDriverOnTheWay;

  /// No description provided for @liveWaitAtPickup.
  ///
  /// In en, this message translates to:
  /// **'Please wait at the pickup point'**
  String get liveWaitAtPickup;

  /// No description provided for @livePleaseBoard.
  ///
  /// In en, this message translates to:
  /// **'Please get in'**
  String get livePleaseBoard;

  /// No description provided for @liveHeadingToDestTitle.
  ///
  /// In en, this message translates to:
  /// **'On the way to your destination'**
  String get liveHeadingToDestTitle;

  /// No description provided for @liveEtaHeadingToDropoff.
  ///
  /// In en, this message translates to:
  /// **'Heading to your drop-off'**
  String get liveEtaHeadingToDropoff;

  /// No description provided for @liveEtaDriverComing.
  ///
  /// In en, this message translates to:
  /// **'Driver is coming to pick you up'**
  String get liveEtaDriverComing;

  /// No description provided for @liveNoDriverPhone.
  ///
  /// In en, this message translates to:
  /// **'Driver\'s phone number isn\'t available'**
  String get liveNoDriverPhone;

  /// No description provided for @liveChat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get liveChat;

  /// No description provided for @liveCall.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get liveCall;

  /// No description provided for @liveTripSummary.
  ///
  /// In en, this message translates to:
  /// **'Trip summary'**
  String get liveTripSummary;

  /// No description provided for @liveTotalFare.
  ///
  /// In en, this message translates to:
  /// **'Total fare'**
  String get liveTotalFare;

  /// No description provided for @livePayCard.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get livePayCard;

  /// No description provided for @livePaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment method'**
  String get livePaymentMethod;

  /// No description provided for @livePayCod.
  ///
  /// In en, this message translates to:
  /// **'Cash on delivery'**
  String get livePayCod;

  /// No description provided for @livePayUnspecified.
  ///
  /// In en, this message translates to:
  /// **'Not specified'**
  String get livePayUnspecified;

  /// No description provided for @livePaymentSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment summary'**
  String get livePaymentSummaryTitle;

  /// No description provided for @liveFareSummary.
  ///
  /// In en, this message translates to:
  /// **'Fare summary'**
  String get liveFareSummary;

  /// No description provided for @liveFare.
  ///
  /// In en, this message translates to:
  /// **'Fare'**
  String get liveFare;

  /// No description provided for @liveTollFee.
  ///
  /// In en, this message translates to:
  /// **'Tolls'**
  String get liveTollFee;

  /// No description provided for @liveWaitingFee.
  ///
  /// In en, this message translates to:
  /// **'Waiting fee'**
  String get liveWaitingFee;

  /// No description provided for @liveDiscount.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get liveDiscount;

  /// No description provided for @liveDriverTip.
  ///
  /// In en, this message translates to:
  /// **'Driver tip'**
  String get liveDriverTip;

  /// No description provided for @liveTotalToPay.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get liveTotalToPay;

  /// No description provided for @liveTipTitle.
  ///
  /// In en, this message translates to:
  /// **'Tip your driver (optional)'**
  String get liveTipTitle;

  /// No description provided for @liveTipNote.
  ///
  /// In en, this message translates to:
  /// **'The tip is charged to your selected payment method'**
  String get liveTipNote;

  /// No description provided for @liveConfirmAndRate.
  ///
  /// In en, this message translates to:
  /// **'Confirm and rate'**
  String get liveConfirmAndRate;

  /// No description provided for @liveChatDriver.
  ///
  /// In en, this message translates to:
  /// **'Driver'**
  String get liveChatDriver;

  /// No description provided for @liveChatSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Trip chat'**
  String get liveChatSubtitle;

  /// No description provided for @liveChatSendFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t send your message. Please try again.'**
  String get liveChatSendFailed;

  /// No description provided for @liveChatLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load messages'**
  String get liveChatLoadFailed;

  /// No description provided for @liveChatHint.
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get liveChatHint;

  /// No description provided for @ratingRequired.
  ///
  /// In en, this message translates to:
  /// **'Please rate your driver first'**
  String get ratingRequired;

  /// No description provided for @ratingTagGoodDriving.
  ///
  /// In en, this message translates to:
  /// **'Good driving'**
  String get ratingTagGoodDriving;

  /// No description provided for @ratingTagPolite.
  ///
  /// In en, this message translates to:
  /// **'Polite'**
  String get ratingTagPolite;

  /// No description provided for @ratingTagCleanCar.
  ///
  /// In en, this message translates to:
  /// **'Clean car'**
  String get ratingTagCleanCar;

  /// No description provided for @ratingTagOnTime.
  ///
  /// In en, this message translates to:
  /// **'On time'**
  String get ratingTagOnTime;

  /// No description provided for @ratingTagSafeDriving.
  ///
  /// In en, this message translates to:
  /// **'Safe driving'**
  String get ratingTagSafeDriving;

  /// No description provided for @ratingTitle.
  ///
  /// In en, this message translates to:
  /// **'Review your trip'**
  String get ratingTitle;

  /// No description provided for @ratingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get ratingSkip;

  /// No description provided for @ratingDriverNameUnknown.
  ///
  /// In en, this message translates to:
  /// **'Driver name unavailable'**
  String get ratingDriverNameUnknown;

  /// No description provided for @ratingYourDriver.
  ///
  /// In en, this message translates to:
  /// **'Your driver'**
  String get ratingYourDriver;

  /// No description provided for @ratingRateDriver.
  ///
  /// In en, this message translates to:
  /// **'Rate your driver'**
  String get ratingRateDriver;

  /// No description provided for @ratingCommentTitle.
  ///
  /// In en, this message translates to:
  /// **'Additional comments'**
  String get ratingCommentTitle;

  /// No description provided for @ratingCommentHint.
  ///
  /// In en, this message translates to:
  /// **'Tell us what you liked or didn\'t like...'**
  String get ratingCommentHint;

  /// No description provided for @ratingSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit review'**
  String get ratingSubmit;

  /// No description provided for @ratingSkipForNow.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get ratingSkipForNow;

  /// No description provided for @tripFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get tripFilterAll;

  /// No description provided for @tripFilterFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get tripFilterFood;

  /// No description provided for @tripFilterRide.
  ///
  /// In en, this message translates to:
  /// **'Rides'**
  String get tripFilterRide;

  /// No description provided for @tripFilterMessenger.
  ///
  /// In en, this message translates to:
  /// **'Parcels'**
  String get tripFilterMessenger;

  /// No description provided for @tripTitleTo.
  ///
  /// In en, this message translates to:
  /// **'{from} to {to}'**
  String tripTitleTo(String from, String to);

  /// No description provided for @tripFoodOrderTo.
  ///
  /// In en, this message translates to:
  /// **'Food order to {address}'**
  String tripFoodOrderTo(String address);

  /// No description provided for @tripMartItemsTo.
  ///
  /// In en, this message translates to:
  /// **'Shopping: {items} to {address}'**
  String tripMartItemsTo(String items, String address);

  /// No description provided for @tripMartOrderTo.
  ///
  /// In en, this message translates to:
  /// **'Mart order to {address}'**
  String tripMartOrderTo(String address);

  /// No description provided for @tripOrderNumber.
  ///
  /// In en, this message translates to:
  /// **'Order #{id}'**
  String tripOrderNumber(String id);

  /// No description provided for @tripParcelDropoffFallback.
  ///
  /// In en, this message translates to:
  /// **'parcel drop-off'**
  String get tripParcelDropoffFallback;

  /// No description provided for @tripParcelTo.
  ///
  /// In en, this message translates to:
  /// **'Parcel to {address}'**
  String tripParcelTo(String address);

  /// No description provided for @tripStatusFindingDriver.
  ///
  /// In en, this message translates to:
  /// **'Finding a driver'**
  String get tripStatusFindingDriver;

  /// No description provided for @tripStatusDriverAccepted.
  ///
  /// In en, this message translates to:
  /// **'Driver accepted'**
  String get tripStatusDriverAccepted;

  /// No description provided for @tripStatusDriverAtPickup.
  ///
  /// In en, this message translates to:
  /// **'Driver at pickup'**
  String get tripStatusDriverAtPickup;

  /// No description provided for @tripStatusOnTrip.
  ///
  /// In en, this message translates to:
  /// **'On trip'**
  String get tripStatusOnTrip;

  /// No description provided for @tripStatusPreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing food'**
  String get tripStatusPreparing;

  /// No description provided for @tripStatusReadyForPickup.
  ///
  /// In en, this message translates to:
  /// **'Ready for pickup'**
  String get tripStatusReadyForPickup;

  /// No description provided for @tripStatusDriverAssigned.
  ///
  /// In en, this message translates to:
  /// **'Driver assigned'**
  String get tripStatusDriverAssigned;

  /// No description provided for @tripStatusDelivering.
  ///
  /// In en, this message translates to:
  /// **'Delivering'**
  String get tripStatusDelivering;

  /// No description provided for @tripStatusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get tripStatusInProgress;

  /// No description provided for @tripStatusAtParcelPickup.
  ///
  /// In en, this message translates to:
  /// **'At parcel pickup'**
  String get tripStatusAtParcelPickup;

  /// No description provided for @tripStatusParcelEnRoute.
  ///
  /// In en, this message translates to:
  /// **'Out for delivery'**
  String get tripStatusParcelEnRoute;

  /// No description provided for @tripDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Trip details'**
  String get tripDetailTitle;

  /// No description provided for @tripNotFound.
  ///
  /// In en, this message translates to:
  /// **'Booking not found'**
  String get tripNotFound;

  /// No description provided for @tripNoMapData.
  ///
  /// In en, this message translates to:
  /// **'No map data'**
  String get tripNoMapData;

  /// No description provided for @tripBookingDate.
  ///
  /// In en, this message translates to:
  /// **'Booking date'**
  String get tripBookingDate;

  /// No description provided for @tripBookingCode.
  ///
  /// In en, this message translates to:
  /// **'Booking ID'**
  String get tripBookingCode;

  /// No description provided for @tripBookingCodeCopied.
  ///
  /// In en, this message translates to:
  /// **'Booking ID copied'**
  String get tripBookingCodeCopied;

  /// No description provided for @tripDriverUnknown.
  ///
  /// In en, this message translates to:
  /// **'Driver not specified'**
  String get tripDriverUnknown;

  /// No description provided for @tripRestaurant.
  ///
  /// In en, this message translates to:
  /// **'Restaurant'**
  String get tripRestaurant;

  /// No description provided for @tripRouteDetails.
  ///
  /// In en, this message translates to:
  /// **'Route details'**
  String get tripRouteDetails;

  /// No description provided for @tripFoodItems.
  ///
  /// In en, this message translates to:
  /// **'Food items'**
  String get tripFoodItems;

  /// No description provided for @tripServiceRide.
  ///
  /// In en, this message translates to:
  /// **'Ride'**
  String get tripServiceRide;

  /// No description provided for @tripTollFee.
  ///
  /// In en, this message translates to:
  /// **'Tolls'**
  String get tripTollFee;

  /// No description provided for @tripWaitingFee.
  ///
  /// In en, this message translates to:
  /// **'Waiting fee'**
  String get tripWaitingFee;

  /// No description provided for @tripFoodTotal.
  ///
  /// In en, this message translates to:
  /// **'Food / items'**
  String get tripFoodTotal;

  /// No description provided for @tripDeliveryFee.
  ///
  /// In en, this message translates to:
  /// **'Delivery fee'**
  String get tripDeliveryFee;

  /// No description provided for @tripNetTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get tripNetTotal;

  /// No description provided for @tripRebook.
  ///
  /// In en, this message translates to:
  /// **'Book again'**
  String get tripRebook;

  /// No description provided for @tripHelpReport.
  ///
  /// In en, this message translates to:
  /// **'Get help / Report a problem'**
  String get tripHelpReport;

  /// No description provided for @tripRatingThanks.
  ///
  /// In en, this message translates to:
  /// **'Thanks for your review'**
  String get tripRatingThanks;

  /// No description provided for @tripRatingAlreadyRated.
  ///
  /// In en, this message translates to:
  /// **'You\'ve rated this trip'**
  String get tripRatingAlreadyRated;

  /// No description provided for @tripRatingPromptTitle.
  ///
  /// In en, this message translates to:
  /// **'Help us improve your experience'**
  String get tripRatingPromptTitle;

  /// No description provided for @tripRatingPromptSub.
  ///
  /// In en, this message translates to:
  /// **'by rating this trip'**
  String get tripRatingPromptSub;

  /// No description provided for @authTabPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get authTabPhone;

  /// No description provided for @authEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authEmail;

  /// No description provided for @authRequestOtp.
  ///
  /// In en, this message translates to:
  /// **'Request OTP'**
  String get authRequestOtp;

  /// No description provided for @authShowPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get authShowPassword;

  /// No description provided for @authHidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get authHidePassword;

  /// No description provided for @authWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get authWelcome;

  /// No description provided for @authLoginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to book rides, send parcels and order food'**
  String get authLoginSubtitle;

  /// No description provided for @authNoAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get authNoAccount;

  /// No description provided for @authAccountDeletedTitle.
  ///
  /// In en, this message translates to:
  /// **'Account deleted'**
  String get authAccountDeletedTitle;

  /// No description provided for @authAccountSuspendedTitle.
  ///
  /// In en, this message translates to:
  /// **'Account suspended'**
  String get authAccountSuspendedTitle;

  /// No description provided for @authAccountDeletedBody.
  ///
  /// In en, this message translates to:
  /// **'Contact us if you have any questions, or sign up again with the same phone number to start a new account.'**
  String get authAccountDeletedBody;

  /// No description provided for @authAccountSuspendedBody.
  ///
  /// In en, this message translates to:
  /// **'This account can\'t be used right now. Please contact us.'**
  String get authAccountSuspendedBody;

  /// No description provided for @authContactSupportPhone.
  ///
  /// In en, this message translates to:
  /// **'Contact support {phone}'**
  String authContactSupportPhone(String phone);

  /// No description provided for @authCallSupport.
  ///
  /// In en, this message translates to:
  /// **'Call support'**
  String get authCallSupport;

  /// No description provided for @authOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get authOk;

  /// No description provided for @authInvalidOtp.
  ///
  /// In en, this message translates to:
  /// **'Incorrect OTP. Please try again.'**
  String get authInvalidOtp;

  /// No description provided for @authChangePasswordFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t change your password. Please try again.'**
  String get authChangePasswordFailed;

  /// No description provided for @authGenericError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get authGenericError;

  /// No description provided for @authInvalidServerResponse.
  ///
  /// In en, this message translates to:
  /// **'Invalid response from the server'**
  String get authInvalidServerResponse;

  /// No description provided for @authInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Incorrect email or password'**
  String get authInvalidCredentials;

  /// No description provided for @authEmailAlreadyRegistered.
  ///
  /// In en, this message translates to:
  /// **'This email already has an account. Please sign in.'**
  String get authEmailAlreadyRegistered;

  /// No description provided for @authRegisterFailed.
  ///
  /// In en, this message translates to:
  /// **'Sign-up failed. Please try again.'**
  String get authRegisterFailed;

  /// No description provided for @onboardSplashTagline.
  ///
  /// In en, this message translates to:
  /// **'Elevating city services'**
  String get onboardSplashTagline;

  /// No description provided for @onboardRideTitle.
  ///
  /// In en, this message translates to:
  /// **'Book a ride'**
  String get onboardRideTitle;

  /// No description provided for @onboardRideDesc.
  ///
  /// In en, this message translates to:
  /// **'Book a ride and get service from\ndrivers in your neighbourhood'**
  String get onboardRideDesc;

  /// No description provided for @onboardDriverTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm your driver'**
  String get onboardDriverTitle;

  /// No description provided for @onboardDriverDesc.
  ///
  /// In en, this message translates to:
  /// **'Our wide driver network gets you\nwhere you need to go — easy, safe and affordable'**
  String get onboardDriverDesc;

  /// No description provided for @onboardTrackTitle.
  ///
  /// In en, this message translates to:
  /// **'Track your trip'**
  String get onboardTrackTitle;

  /// No description provided for @onboardTrackDesc.
  ///
  /// In en, this message translates to:
  /// **'See your driver\'s details in advance and\nfollow their live location on the map'**
  String get onboardTrackDesc;

  /// No description provided for @onboardGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started!'**
  String get onboardGetStarted;

  /// No description provided for @onboardNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardNext;

  /// No description provided for @onboardSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardSkip;

  /// No description provided for @profilePrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get profilePrivacyPolicy;

  /// No description provided for @profileContactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact support'**
  String get profileContactSupport;

  /// No description provided for @profileManageAccount.
  ///
  /// In en, this message translates to:
  /// **'Manage account'**
  String get profileManageAccount;

  /// No description provided for @profileDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get profileDeleteAccount;

  /// No description provided for @profileVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String profileVersion(String version);

  /// No description provided for @profileDeleteAccountConfirm.
  ///
  /// In en, this message translates to:
  /// **'Deleting your account permanently removes all your data and can\'t be undone. Delete your account?'**
  String get profileDeleteAccountConfirm;

  /// No description provided for @profileAccountDeleted.
  ///
  /// In en, this message translates to:
  /// **'Your account has been deleted'**
  String get profileAccountDeleted;

  /// No description provided for @profileDeleteAccountFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t delete your account. Please try again.'**
  String get profileDeleteAccountFailed;

  /// No description provided for @profileLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load data'**
  String get profileLoadFailed;

  /// No description provided for @profileClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get profileClose;

  /// No description provided for @profilePdpaTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy (PDPA)'**
  String get profilePdpaTitle;

  /// No description provided for @profilePdpaRightsTitle.
  ///
  /// In en, this message translates to:
  /// **'Your PDPA rights'**
  String get profilePdpaRightsTitle;

  /// No description provided for @profilePdpaRightsBody.
  ///
  /// In en, this message translates to:
  /// **'You have the right to manage your personal data under the PDPA (Personal Data Protection Act).'**
  String get profilePdpaRightsBody;

  /// No description provided for @profilePdpaDataManagement.
  ///
  /// In en, this message translates to:
  /// **'Data management'**
  String get profilePdpaDataManagement;

  /// No description provided for @profilePdpaExportTitle.
  ///
  /// In en, this message translates to:
  /// **'Export my data'**
  String get profilePdpaExportTitle;

  /// No description provided for @profilePdpaExportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Download all your personal data as JSON'**
  String get profilePdpaExportSubtitle;

  /// No description provided for @profilePdpaConsentHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Consent history'**
  String get profilePdpaConsentHistoryTitle;

  /// No description provided for @profilePdpaConsentHistorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'View your consent status'**
  String get profilePdpaConsentHistorySubtitle;

  /// No description provided for @profilePdpaDangerZone.
  ///
  /// In en, this message translates to:
  /// **'Danger zone'**
  String get profilePdpaDangerZone;

  /// No description provided for @profilePdpaDeletionTitle.
  ///
  /// In en, this message translates to:
  /// **'Request account deletion'**
  String get profilePdpaDeletionTitle;

  /// No description provided for @profilePdpaDeletionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Request deletion of your account and all data (can\'t be undone)'**
  String get profilePdpaDeletionSubtitle;

  /// No description provided for @profilePdpaExporting.
  ///
  /// In en, this message translates to:
  /// **'Exporting data...'**
  String get profilePdpaExporting;

  /// No description provided for @profilePdpaExportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Data exported. Check your email.'**
  String get profilePdpaExportSuccess;

  /// No description provided for @profilePdpaExportFailed.
  ///
  /// In en, this message translates to:
  /// **'Can\'t export your data right now'**
  String get profilePdpaExportFailed;

  /// No description provided for @profilePdpaConsentTitle.
  ///
  /// In en, this message translates to:
  /// **'Consent'**
  String get profilePdpaConsentTitle;

  /// No description provided for @profilePdpaConsentPolicyVersion.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy v2.1'**
  String get profilePdpaConsentPolicyVersion;

  /// No description provided for @profilePdpaConsentStatus.
  ///
  /// In en, this message translates to:
  /// **'Status: Consented ✓'**
  String get profilePdpaConsentStatus;

  /// No description provided for @profilePdpaDeletionReasonPrompt.
  ///
  /// In en, this message translates to:
  /// **'Please tell us why you want to delete your account'**
  String get profilePdpaDeletionReasonPrompt;

  /// No description provided for @profilePdpaDeletionReasonHint.
  ///
  /// In en, this message translates to:
  /// **'Reason...'**
  String get profilePdpaDeletionReasonHint;

  /// No description provided for @profilePdpaSubmitRequest.
  ///
  /// In en, this message translates to:
  /// **'Submit request'**
  String get profilePdpaSubmitRequest;

  /// No description provided for @profilePdpaDeletionReceived.
  ///
  /// In en, this message translates to:
  /// **'Request received. Our team will process it within 30 days.'**
  String get profilePdpaDeletionReceived;

  /// No description provided for @profilePdpaDeletionFailed.
  ///
  /// In en, this message translates to:
  /// **'Can\'t submit your request right now'**
  String get profilePdpaDeletionFailed;

  /// No description provided for @profileReferralTitle.
  ///
  /// In en, this message translates to:
  /// **'Refer a friend'**
  String get profileReferralTitle;

  /// No description provided for @profileReferralHeadline.
  ///
  /// In en, this message translates to:
  /// **'Invite friends to MASS'**
  String get profileReferralHeadline;

  /// No description provided for @profileReferralSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Get 100 points every time a friend signs up and rides'**
  String get profileReferralSubtitle;

  /// No description provided for @profileReferralFriendsInvited.
  ///
  /// In en, this message translates to:
  /// **'Friends invited'**
  String get profileReferralFriendsInvited;

  /// No description provided for @profileReferralPointsEarned.
  ///
  /// In en, this message translates to:
  /// **'Points earned'**
  String get profileReferralPointsEarned;

  /// No description provided for @profileReferralYourCode.
  ///
  /// In en, this message translates to:
  /// **'Your referral code'**
  String get profileReferralYourCode;

  /// No description provided for @profileReferralCodeCopied.
  ///
  /// In en, this message translates to:
  /// **'Code copied!'**
  String get profileReferralCodeCopied;

  /// No description provided for @profileReferralCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get profileReferralCopy;

  /// No description provided for @profileReferralShareMessage.
  ///
  /// In en, this message translates to:
  /// **'Try Mass Move! Use code {code} to get a discount 🚀'**
  String profileReferralShareMessage(String code);

  /// No description provided for @profileReferralInviteCopied.
  ///
  /// In en, this message translates to:
  /// **'Invite message copied'**
  String get profileReferralInviteCopied;

  /// No description provided for @profileReferralShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get profileReferralShare;

  /// No description provided for @profileReferralHaveCode.
  ///
  /// In en, this message translates to:
  /// **'Have a referral code?'**
  String get profileReferralHaveCode;

  /// No description provided for @profileReferralHaveCodeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the code a friend sent you to get bonus points'**
  String get profileReferralHaveCodeSubtitle;

  /// No description provided for @profileReferralCodeHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. MASS-XXXX'**
  String get profileReferralCodeHint;

  /// No description provided for @profileReferralApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get profileReferralApply;

  /// No description provided for @profileReferralApplySuccess.
  ///
  /// In en, this message translates to:
  /// **'Code applied! Bonus points added.'**
  String get profileReferralApplySuccess;

  /// No description provided for @profileReferralApplyInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid or already-used code'**
  String get profileReferralApplyInvalid;

  /// No description provided for @profileSosTitle.
  ///
  /// In en, this message translates to:
  /// **'SOS safety'**
  String get profileSosTitle;

  /// No description provided for @profileSosHoldHint.
  ///
  /// In en, this message translates to:
  /// **'Press and hold to send an emergency alert'**
  String get profileSosHoldHint;

  /// No description provided for @profileSosCallCenter.
  ///
  /// In en, this message translates to:
  /// **'Call support center {phone}'**
  String profileSosCallCenter(String phone);

  /// No description provided for @profileSosInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Emergency info'**
  String get profileSosInfoTitle;

  /// No description provided for @profileSosInfoBody.
  ///
  /// In en, this message translates to:
  /// **'When you press SOS, we alert our admins and the driver on your trip, and the details are recorded for your safety.'**
  String get profileSosInfoBody;

  /// No description provided for @profileSosHistory.
  ///
  /// In en, this message translates to:
  /// **'SOS history'**
  String get profileSosHistory;

  /// No description provided for @profileSosNoHistory.
  ///
  /// In en, this message translates to:
  /// **'No SOS history'**
  String get profileSosNoHistory;

  /// No description provided for @profileSosEvent.
  ///
  /// In en, this message translates to:
  /// **'SOS event'**
  String get profileSosEvent;

  /// No description provided for @profileSosResolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get profileSosResolved;

  /// No description provided for @profileSosOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get profileSosOpen;

  /// No description provided for @profileSosConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Send SOS alert'**
  String get profileSosConfirmTitle;

  /// No description provided for @profileSosConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Send an emergency alert? Our team will be notified right away.'**
  String get profileSosConfirmBody;

  /// No description provided for @profileSosSend.
  ///
  /// In en, this message translates to:
  /// **'Send SOS'**
  String get profileSosSend;

  /// No description provided for @profileSosSent.
  ///
  /// In en, this message translates to:
  /// **'SOS sent. Our team has been notified.'**
  String get profileSosSent;

  /// No description provided for @profileSosSendFailed.
  ///
  /// In en, this message translates to:
  /// **'Can\'t send SOS right now'**
  String get profileSosSendFailed;

  /// No description provided for @profileLoyaltyLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to load data'**
  String get profileLoyaltyLoadFailed;

  /// No description provided for @profileLoyaltyPointsBalance.
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get profileLoyaltyPointsBalance;

  /// No description provided for @profileLoyaltyCashbackBalance.
  ///
  /// In en, this message translates to:
  /// **'Cashback (฿)'**
  String get profileLoyaltyCashbackBalance;

  /// No description provided for @profileLoyaltyRedeemPoints.
  ///
  /// In en, this message translates to:
  /// **'Redeem points'**
  String get profileLoyaltyRedeemPoints;

  /// No description provided for @profileLoyaltyPointsHistory.
  ///
  /// In en, this message translates to:
  /// **'Points history'**
  String get profileLoyaltyPointsHistory;

  /// No description provided for @profileLoyaltyCashbackHistory.
  ///
  /// In en, this message translates to:
  /// **'Cashback history'**
  String get profileLoyaltyCashbackHistory;

  /// No description provided for @profileLoyaltyYouHavePoints.
  ///
  /// In en, this message translates to:
  /// **'You have {points} points'**
  String profileLoyaltyYouHavePoints(String points);

  /// No description provided for @profileLoyaltyRedeemAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Points to redeem'**
  String get profileLoyaltyRedeemAmountLabel;

  /// No description provided for @profileLoyaltyRedeemSuccess.
  ///
  /// In en, this message translates to:
  /// **'Points redeemed!'**
  String get profileLoyaltyRedeemSuccess;

  /// No description provided for @profileLoyaltyRedeem.
  ///
  /// In en, this message translates to:
  /// **'Redeem'**
  String get profileLoyaltyRedeem;

  /// No description provided for @profileLoyaltyCashbackRate.
  ///
  /// In en, this message translates to:
  /// **'{percent}% back'**
  String profileLoyaltyCashbackRate(String percent);

  /// No description provided for @profileLoyaltyPoints.
  ///
  /// In en, this message translates to:
  /// **'{points} points'**
  String profileLoyaltyPoints(String points);

  /// No description provided for @profileLoyaltyNextTier.
  ///
  /// In en, this message translates to:
  /// **'Next tier: {tier}'**
  String profileLoyaltyNextTier(String tier);

  /// No description provided for @profileLoyaltyPointsToGo.
  ///
  /// In en, this message translates to:
  /// **'{points} points to go'**
  String profileLoyaltyPointsToGo(String points);

  /// No description provided for @profileSavedPlacesTitle.
  ///
  /// In en, this message translates to:
  /// **'Delivery addresses'**
  String get profileSavedPlacesTitle;

  /// No description provided for @profileDeleteAddressTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete address'**
  String get profileDeleteAddressTitle;

  /// No description provided for @profileDeleteAddressConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this address?'**
  String get profileDeleteAddressConfirm;

  /// No description provided for @profileDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get profileDelete;

  /// No description provided for @profileDeleteAddressFailed.
  ///
  /// In en, this message translates to:
  /// **'Can\'t delete right now'**
  String get profileDeleteAddressFailed;

  /// No description provided for @profileNoAddressInfo.
  ///
  /// In en, this message translates to:
  /// **'No address details'**
  String get profileNoAddressInfo;

  /// No description provided for @profileNoSavedAddresses.
  ///
  /// In en, this message translates to:
  /// **'No saved addresses yet'**
  String get profileNoSavedAddresses;

  /// No description provided for @profileNoSavedAddressesHint.
  ///
  /// In en, this message translates to:
  /// **'Add an address for faster delivery'**
  String get profileNoSavedAddressesHint;

  /// No description provided for @profileEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get profileEditTitle;

  /// No description provided for @profileFullNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get profileFullNameHint;

  /// No description provided for @profileFillAllFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all required fields'**
  String get profileFillAllFields;

  /// No description provided for @profileAvatarUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t upload photo. Please try again.'**
  String get profileAvatarUploadFailed;

  /// No description provided for @payTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get payTryAgain;

  /// No description provided for @payBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get payBack;

  /// No description provided for @payVoidedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This payment was cancelled — for example, you switched to cash or the trip was cancelled.'**
  String get payVoidedSubtitle;

  /// No description provided for @payFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment failed'**
  String get payFailedTitle;

  /// No description provided for @payFailedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Please try creating a new payment.'**
  String get payFailedSubtitle;

  /// No description provided for @payAwaitingPayment.
  ///
  /// In en, this message translates to:
  /// **'Waiting for payment...'**
  String get payAwaitingPayment;

  /// No description provided for @payCardOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the payment page'**
  String get payCardOpenFailed;

  /// No description provided for @payCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Pay by card'**
  String get payCardTitle;

  /// No description provided for @payCardStartFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t start the payment'**
  String get payCardStartFailed;

  /// No description provided for @payCardVoidedTitle.
  ///
  /// In en, this message translates to:
  /// **'No card payment needed'**
  String get payCardVoidedTitle;

  /// No description provided for @payCardExpiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment expired'**
  String get payCardExpiredTitle;

  /// No description provided for @payCardExpiredSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Please start the payment again.'**
  String get payCardExpiredSubtitle;

  /// No description provided for @payStartOver.
  ///
  /// In en, this message translates to:
  /// **'Start over'**
  String get payStartOver;

  /// No description provided for @payCardUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Card payment unavailable'**
  String get payCardUnavailableTitle;

  /// No description provided for @payCardUnavailableSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Card payments aren\'t supported right now. Please choose another method.'**
  String get payCardUnavailableSubtitle;

  /// No description provided for @payChooseAnotherMethod.
  ///
  /// In en, this message translates to:
  /// **'Choose another method'**
  String get payChooseAnotherMethod;

  /// No description provided for @payCardPayInBrowser.
  ///
  /// In en, this message translates to:
  /// **'Complete payment on the page that opened'**
  String get payCardPayInBrowser;

  /// No description provided for @payCardPayInBrowserHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your card details on the secure payment page. When you\'re done, come back to the app and we\'ll confirm automatically.'**
  String get payCardPayInBrowserHint;

  /// No description provided for @payCardReopen.
  ///
  /// In en, this message translates to:
  /// **'Reopen payment page'**
  String get payCardReopen;

  /// No description provided for @payCardIPaid.
  ///
  /// In en, this message translates to:
  /// **'I\'ve paid · Check status'**
  String get payCardIPaid;

  /// No description provided for @payPromptPayTitle.
  ///
  /// In en, this message translates to:
  /// **'Pay with PromptPay'**
  String get payPromptPayTitle;

  /// No description provided for @payQrVoidedTitle.
  ///
  /// In en, this message translates to:
  /// **'This QR no longer needs to be paid'**
  String get payQrVoidedTitle;

  /// No description provided for @payQrCreateFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t create QR'**
  String get payQrCreateFailed;

  /// No description provided for @payPayCashInstead.
  ///
  /// In en, this message translates to:
  /// **'Pay cash instead'**
  String get payPayCashInstead;

  /// No description provided for @payQrExpiredTitle.
  ///
  /// In en, this message translates to:
  /// **'QR expired'**
  String get payQrExpiredTitle;

  /// No description provided for @payQrExpiredSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create a new QR or switch to cash.'**
  String get payQrExpiredSubtitle;

  /// No description provided for @payQrCreateNew.
  ///
  /// In en, this message translates to:
  /// **'Create new QR'**
  String get payQrCreateNew;

  /// No description provided for @payQrNotFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment QR not found'**
  String get payQrNotFoundTitle;

  /// No description provided for @payQrNotFoundSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Please try again.'**
  String get payQrNotFoundSubtitle;

  /// No description provided for @payAmountChangedNotice.
  ///
  /// In en, this message translates to:
  /// **'The amount has changed. Please scan this new QR instead of the old one.'**
  String get payAmountChangedNotice;

  /// No description provided for @payQrScanHint.
  ///
  /// In en, this message translates to:
  /// **'Scan this QR with your banking app to pay'**
  String get payQrScanHint;

  /// No description provided for @payQrExpiresIn.
  ///
  /// In en, this message translates to:
  /// **'QR expires in {time}'**
  String payQrExpiresIn(String time);

  /// No description provided for @payQrLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load QR'**
  String get payQrLoadFailed;

  /// No description provided for @payAddCreditCard.
  ///
  /// In en, this message translates to:
  /// **'Add credit card'**
  String get payAddCreditCard;

  /// No description provided for @payNoCreditCards.
  ///
  /// In en, this message translates to:
  /// **'No credit cards yet'**
  String get payNoCreditCards;

  /// No description provided for @payNoCreditCardsHint.
  ///
  /// In en, this message translates to:
  /// **'Add a card for easier payments'**
  String get payNoCreditCardsHint;

  /// No description provided for @payCardHolder.
  ///
  /// In en, this message translates to:
  /// **'Card holder'**
  String get payCardHolder;

  /// No description provided for @payCardExpires.
  ///
  /// In en, this message translates to:
  /// **'Expires'**
  String get payCardExpires;

  /// No description provided for @payCardAdded.
  ///
  /// In en, this message translates to:
  /// **'Card added'**
  String get payCardAdded;

  /// No description provided for @payCardDevNotice.
  ///
  /// In en, this message translates to:
  /// **'In development — can\'t be used for real payments yet, and card details aren\'t stored permanently.'**
  String get payCardDevNotice;

  /// No description provided for @payCardNumber.
  ///
  /// In en, this message translates to:
  /// **'Card number'**
  String get payCardNumber;

  /// No description provided for @payCardNameOnCard.
  ///
  /// In en, this message translates to:
  /// **'Name on card'**
  String get payCardNameOnCard;

  /// No description provided for @payCardNameHint.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get payCardNameHint;

  /// No description provided for @payCardExpiryDate.
  ///
  /// In en, this message translates to:
  /// **'Expiry date'**
  String get payCardExpiryDate;

  /// No description provided for @payCardSave.
  ///
  /// In en, this message translates to:
  /// **'Save card'**
  String get payCardSave;

  /// No description provided for @payCreateIntentFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t create the payment'**
  String get payCreateIntentFailed;

  /// No description provided for @payCheckStatusFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t check the payment status'**
  String get payCheckStatusFailed;

  /// No description provided for @payCheckIntentFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t check the payment'**
  String get payCheckIntentFailed;

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

  /// No description provided for @couponRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove code'**
  String get couponRemove;

  /// No description provided for @homeAllowLocation.
  ///
  /// In en, this message translates to:
  /// **'Tap to use your current location'**
  String get homeAllowLocation;

  /// No description provided for @promoRejectFullyRedeemed.
  ///
  /// In en, this message translates to:
  /// **'This code has been fully redeemed'**
  String get promoRejectFullyRedeemed;

  /// No description provided for @promoRejectNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'This code isn\'t available right now'**
  String get promoRejectNotAvailable;

  /// No description provided for @promoRejectMinSpendAmount.
  ///
  /// In en, this message translates to:
  /// **'Spend at least ฿{amount} to use this code'**
  String promoRejectMinSpendAmount(String amount);

  /// No description provided for @couponNotAppliedReason.
  ///
  /// In en, this message translates to:
  /// **'Code {code} can\'t be used: {reason}'**
  String couponNotAppliedReason(String code, String reason);

  /// No description provided for @promoEnded.
  ///
  /// In en, this message translates to:
  /// **'This promotion has ended'**
  String get promoEnded;

  /// No description provided for @homeLocationPromptTitle.
  ///
  /// In en, this message translates to:
  /// **'Turn on location'**
  String get homeLocationPromptTitle;

  /// No description provided for @homeLocationPromptBody.
  ///
  /// In en, this message translates to:
  /// **'Allow location so Mass Move can use where you are as your pickup and delivery address automatically.'**
  String get homeLocationPromptBody;

  /// No description provided for @homeLocationPromptAllow.
  ///
  /// In en, this message translates to:
  /// **'Turn on'**
  String get homeLocationPromptAllow;

  /// No description provided for @homeLocationPromptLater.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get homeLocationPromptLater;

  /// No description provided for @referralRewardSummary.
  ///
  /// In en, this message translates to:
  /// **'Your friend gets ฿{friendValue} off · you get {points} points after their first order'**
  String referralRewardSummary(String friendValue, int points);

  /// No description provided for @referralShareText.
  ///
  /// In en, this message translates to:
  /// **'Use code {code} on Mass Move and get ฿{value} off 🎉'**
  String referralShareText(String code, String value);

  /// No description provided for @referralStatInvited.
  ///
  /// In en, this message translates to:
  /// **'Invited'**
  String get referralStatInvited;

  /// No description provided for @referralStatCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get referralStatCompleted;

  /// No description provided for @referralStatPoints.
  ///
  /// In en, this message translates to:
  /// **'Points earned'**
  String get referralStatPoints;

  /// No description provided for @referralStatPending.
  ///
  /// In en, this message translates to:
  /// **'Waiting on {count} friends\' first order ({points} points)'**
  String referralStatPending(int count, int points);

  /// No description provided for @referralApplySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter a friend\'s code to get ฿{value} off your first order'**
  String referralApplySubtitle(String value);

  /// No description provided for @referralApplyBefore.
  ///
  /// In en, this message translates to:
  /// **'Enter by {date}'**
  String referralApplyBefore(String date);

  /// No description provided for @referralUseWelcomeCode.
  ///
  /// In en, this message translates to:
  /// **'Don\'t forget to use {code} on your first order for ฿{value} off'**
  String referralUseWelcomeCode(String code, String value);

  /// No description provided for @referralApplySuccessPromo.
  ///
  /// In en, this message translates to:
  /// **'You got code {code}: ฿{value} off 🎁'**
  String referralApplySuccessPromo(String code, String value);

  /// No description provided for @referralErrInvalidCode.
  ///
  /// In en, this message translates to:
  /// **'Invalid code'**
  String get referralErrInvalidCode;

  /// No description provided for @referralErrSelf.
  ///
  /// In en, this message translates to:
  /// **'You can\'t use your own code'**
  String get referralErrSelf;

  /// No description provided for @referralErrAlreadyUsed.
  ///
  /// In en, this message translates to:
  /// **'You\'ve already used a referral code'**
  String get referralErrAlreadyUsed;

  /// No description provided for @referralErrNotNewCustomer.
  ///
  /// In en, this message translates to:
  /// **'Referral codes are for new customers before their first order'**
  String get referralErrNotNewCustomer;

  /// No description provided for @referralErrWindowClosed.
  ///
  /// In en, this message translates to:
  /// **'The time to enter a referral code has passed'**
  String get referralErrWindowClosed;

  /// No description provided for @referralErrCodeFull.
  ///
  /// In en, this message translates to:
  /// **'This code has reached its limit'**
  String get referralErrCodeFull;

  /// No description provided for @referralErrExpired.
  ///
  /// In en, this message translates to:
  /// **'This code has expired'**
  String get referralErrExpired;

  /// No description provided for @referralErrDisabled.
  ///
  /// In en, this message translates to:
  /// **'Referral codes aren\'t available right now'**
  String get referralErrDisabled;

  /// No description provided for @promoRejectReferredOnly.
  ///
  /// In en, this message translates to:
  /// **'This code is for referred friends only'**
  String get promoRejectReferredOnly;

  /// No description provided for @authSendCode.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get authSendCode;

  /// No description provided for @authEmailCodeHint.
  ///
  /// In en, this message translates to:
  /// **'We\'ll email you a 6-digit code — it works for signing in and signing up'**
  String get authEmailCodeHint;

  /// No description provided for @authEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid email address'**
  String get authEmailInvalid;

  /// No description provided for @authOtpRateLimited.
  ///
  /// In en, this message translates to:
  /// **'Too many code requests. Please try again later'**
  String get authOtpRateLimited;

  /// No description provided for @authEmailUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Email sign-in isn\'t available yet. Please use your phone number'**
  String get authEmailUnavailable;

  /// No description provided for @authEmailSendFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t send the email. Please try again'**
  String get authEmailSendFailed;

  /// No description provided for @authEmailOtpSentTo.
  ///
  /// In en, this message translates to:
  /// **'Code sent to {email} · Ref {ref}'**
  String authEmailOtpSentTo(String email, String ref);

  /// No description provided for @authEmailOtpSpamHint.
  ///
  /// In en, this message translates to:
  /// **'Can\'t find it? Check your Spam folder · The code is valid for 10 minutes'**
  String get authEmailOtpSpamHint;

  /// No description provided for @authEmailNewAccountWarning.
  ///
  /// In en, this message translates to:
  /// **'This email has no account yet — a new one will be created. If you signed up with a phone number, sign in with that number instead'**
  String get authEmailNewAccountWarning;

  /// No description provided for @authOtpInvalid.
  ///
  /// In en, this message translates to:
  /// **'Incorrect code'**
  String get authOtpInvalid;

  /// No description provided for @authOtpTooManyAttempts.
  ///
  /// In en, this message translates to:
  /// **'Too many wrong attempts. Please request a new code'**
  String get authOtpTooManyAttempts;

  /// No description provided for @authOtpExpired.
  ///
  /// In en, this message translates to:
  /// **'The code has expired. Please request a new one'**
  String get authOtpExpired;

  /// No description provided for @authSmsEmailFallback.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t get the SMS? Get the code by email'**
  String get authSmsEmailFallback;

  /// No description provided for @referralCodeFull.
  ///
  /// In en, this message translates to:
  /// **'Your code has reached its friend limit'**
  String get referralCodeFull;

  /// No description provided for @referralReferredBy.
  ///
  /// In en, this message translates to:
  /// **'You signed up with code {code}'**
  String referralReferredBy(String code);
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
