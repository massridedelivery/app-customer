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
