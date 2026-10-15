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
  /// **'Invite friends'**
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
