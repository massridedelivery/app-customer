import 'package:customer_app/core/managers/providers.dart';
import 'package:customer_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:customer_app/features/auth/presentation/screens/login_screen.dart';
import 'package:customer_app/features/auth/presentation/screens/otp_screen.dart';
import 'package:customer_app/features/auth/presentation/screens/phone_login_screen.dart';
import 'package:customer_app/features/register/presentation/screens/register_screen.dart';
import 'package:customer_app/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:customer_app/features/auth/presentation/screens/forgot_password_otp_screen.dart';
import 'package:customer_app/features/auth/presentation/screens/new_password_screen.dart';
// Removing finding_rider_screen import
import 'package:customer_app/features/active_orders/presentation/controllers/active_orders_controller.dart';
import 'package:customer_app/features/food_order/presentation/screens/food_chat_screen.dart';
import 'package:customer_app/features/food_order/presentation/screens/food_rating_screen.dart';
import 'package:customer_app/features/food_order/presentation/screens/food_receipt_screen.dart';
import 'package:customer_app/features/food_order/presentation/screens/live_food_tracking_screen.dart';
import 'package:customer_app/features/food_order/presentation/screens/resume_food_order_screen.dart';
import 'package:customer_app/features/home/presentation/screens/category_list_screen.dart';
import 'package:customer_app/features/food_delivery/presentation/screens/food_delivery_screen.dart';
import 'package:customer_app/features/home/presentation/screens/home_screen.dart';
import 'package:customer_app/features/home/presentation/screens/item_search_screen.dart';
import 'package:customer_app/features/food_order/presentation/screens/restaurant_detail_screen.dart';
import 'package:customer_app/features/home/presentation/screens/transport/dropoff_selection_screen.dart';
import 'package:customer_app/features/home/presentation/screens/transport/food_location_selection_screen.dart';
import 'package:customer_app/features/home/presentation/screens/transport/food_place_search_screen.dart';
import 'package:customer_app/features/home/presentation/screens/transport/pickup_selection_screen.dart';
import 'package:customer_app/features/home/presentation/screens/transport/place_search_screen.dart';
import 'package:customer_app/features/home/presentation/screens/transport/ride_landing_screen.dart';
import 'package:customer_app/features/chat/presentation/screens/chat_screen.dart';
import 'package:customer_app/features/live_ride/presentation/screens/live_ride_screen.dart';
import 'package:customer_app/features/live_ride/presentation/screens/rating_screen.dart';
import 'package:customer_app/features/messenger/presentation/screens/messenger_booking_screen.dart';
import 'package:customer_app/features/messenger/presentation/screens/messenger_chat_screen.dart';
import 'package:customer_app/features/messenger/presentation/screens/messenger_review_screen.dart';
import 'package:customer_app/features/messenger/presentation/screens/messenger_tracking_screen.dart';
import 'package:customer_app/features/main/presentation/screens/main_screen.dart'
    as customer_app_main;
import 'package:customer_app/features/onboarding/presentation/screens/location_setup_screen.dart';
import 'package:customer_app/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:customer_app/features/onboarding/presentation/screens/splash_screen.dart';
import 'package:customer_app/features/payment/presentation/screens/add_card_screen.dart';
import 'package:customer_app/features/payment/presentation/screens/promptpay_qr_screen.dart';
import 'package:customer_app/features/profile/presentation/screens/profile_screen.dart';
import 'package:customer_app/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:customer_app/features/profile/presentation/screens/loyalty_screen.dart';
import 'package:customer_app/features/profile/presentation/screens/saved_places_screen.dart';
import 'package:customer_app/features/profile/presentation/screens/address_form_screen.dart';
import 'package:customer_app/features/profile/presentation/screens/promo_list_screen.dart';
import 'package:customer_app/features/profile/presentation/screens/referral_screen.dart';
import 'package:customer_app/features/profile/presentation/screens/sos_screen.dart';
import 'package:customer_app/features/profile/presentation/screens/privacy_pdpa_screen.dart';
import 'package:customer_app/features/profile/presentation/screens/promo_detail_screen.dart';
import 'package:customer_app/features/ride_booking/presentation/screens/booking_screen.dart';
import 'package:customer_app/features/trips/presentation/screens/trip_detail_screen.dart'
    as customer_app_trip_detail;
import 'package:customer_app/features/trips/presentation/screens/trips_screen.dart';
import 'package:customer_app/features/trips/domain/models/history_order.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:customer_app/features/live_ride/domain/models/driver_profile_model.dart';

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;
  bool _splashShown = false;

  /// Destination to restore once the splash gate releases: a deeplink that
  /// arrived before the app was ready on cold start (or an auth change that
  /// re-gated the splash). Set silently from redirect — no notifyListeners —
  /// and consumed exactly once.
  String? pendingDeepLink;

  bool get splashShown => _splashShown;

  set splashShown(bool value) {
    if (_splashShown != value) {
      _splashShown = value;
      notifyListeners();
    }
  }

  RouterNotifier(this._ref) {
    _ref.listen(authControllerProvider, (previous, next) {
      // If the user's authentication state changes (e.g., login/logout),
      // we reset splashShown so they see the splash screen again.
      if (previous?.isAuthenticated != next.isAuthenticated) {
        // A link stashed before logout must not leak into the next session.
        if (!next.isAuthenticated) {
          pendingDeepLink = null;
        }
        _splashShown = false;
        notifyListeners();
      }
    });
  }
}

final routerNotifierProvider = Provider<RouterNotifier>(
  (ref) => RouterNotifier(ref),
);

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    // Malformed or unknown deeplinks land on /main instead of an error page.
    onException: (context, state, router) => router.go('/main'),
    refreshListenable: notifier,
    observers: [ActiveOrdersObserver(ref)],
    redirect: (context, state) {
      final authState = ref.read(authControllerProvider);
      final isAuthenticated = authState.isAuthenticated;
      final activeJobId = authState.activeJobId;
      final currentPath = state.matchedLocation;

      final isAuthPath = currentPath.startsWith('/auth');
      final isSplash = currentPath == '/splash';
      final isOnboarding =
          currentPath == '/onboarding' || currentPath == '/location_setup';

      final hasCompletedOnboarding = ref
          .read(appStorageProvider)
          .hasCompletedOnboarding;

      final splashShown = notifier.splashShown;

      // Log for debugging
      debugPrint(
        'Router Redirect: isAuthenticated=$isAuthenticated, splashShown=$splashShown, activeJobId=$activeJobId, currentPath=$currentPath, pendingDeepLink=${notifier.pendingDeepLink}',
      );

      // MANDATORY: If the splash hasn't been shown yet, stay on /splash.
      if (!splashShown) {
        if (!isSplash) {
          // Keep the intended destination (a deeplink that just arrived before
          // the app was ready) so the splash can send them back there instead
          // of dumping them on /main.
          if (!isAuthPath && !isOnboarding && state.uri.path.isNotEmpty) {
            notifier.pendingDeepLink = Uri(
              path: state.uri.path,
              queryParameters: state.uri.queryParameters.isEmpty
                  ? null
                  : state.uri.queryParameters,
            ).toString();
          }
          return '/splash';
        }
        return null; // Stay on /splash
      }

      if (isAuthenticated) {
        // Leaving the splash: consume the stashed destination first. The
        // returned location runs through this redirect again, so the
        // active-job recovery below still gets the final say on it.
        if (isSplash) {
          final pending = notifier.pendingDeepLink;
          if (pending != null) {
            notifier.pendingDeepLink = null;
            return pending;
          }
        }

        // Recovery logic: if there's an active job, and we're not already on the live/rating screen, go there.
        if (activeJobId != null) {
          final isLivePath = currentPath.startsWith('/live');
          final isRatingPath = currentPath.startsWith('/rating');
          final isChatPath = currentPath.startsWith('/chat');
          final isFoodOrderPath = currentPath.startsWith('/food-order');
          // Customer can hold a ride + messenger orders at once (SCRUM-45);
          // don't hijack the messenger surfaces back to the live ride.
          final isMessengerPath = currentPath.startsWith('/messenger');

          if (!isLivePath &&
              !isRatingPath &&
              !isChatPath &&
              !isFoodOrderPath &&
              !isMessengerPath) {
            return '/live/$activeJobId';
          }
        }

        if (isAuthPath || isSplash || isOnboarding) {
          return '/main';
        }
      } else {
        // Not authenticated
        if (isSplash) {
          // This should only happen if splashShown = true (handled above)
          // but we still need to decide where to go next from splash.
          if (!hasCompletedOnboarding) {
            return '/onboarding';
          } else {
            return '/auth';
          }
        }

        if (!hasCompletedOnboarding) {
          if (!isOnboarding) {
            return '/onboarding';
          }
        } else {
          if (!isAuthPath && isOnboarding) {
            return '/auth';
          }
          if (!isAuthPath && !isOnboarding) {
            return '/auth';
          }
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/location_setup',
        builder: (context, state) => const LocationSetupScreen(),
      ),
      GoRoute(
        path: '/auth',
        builder: (context, state) => const PhoneLoginScreen(),
        routes: [
          GoRoute(
            path: 'email_login',
            builder: (context, state) => const LoginScreen(),
          ),
          GoRoute(
            path: 'register',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>? ?? {};
              final phone = extra['phone'] as String? ?? '';
              return RegisterScreen(phone: phone);
            },
          ),
          GoRoute(
            path: 'otp',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>? ?? {};
              final phone = extra['phone'] as String? ?? '';
              final refId = extra['refId'] as String? ?? '';
              final isRegistered = extra['isRegistered'] as bool? ?? false;
              return OtpScreen(
                phone: phone,
                refId: refId,
                isRegistered: isRegistered,
              );
            },
          ),
          GoRoute(
            path: 'forgot-password',
            builder: (context, state) => const ForgotPasswordScreen(),
          ),
          GoRoute(
            path: 'forgot-password-otp',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>? ?? {};
              final email = extra['email'] as String? ?? '';
              final refId = extra['refId'] as String? ?? '';
              return ForgotPasswordOtpScreen(email: email, refId: refId);
            },
          ),
          GoRoute(
            path: 'new-password',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>? ?? {};
              final email = extra['email'] as String? ?? '';
              final resetToken = extra['resetToken'] as String? ?? '';
              return NewPasswordScreen(email: email, resetToken: resetToken);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/main',
        builder: (context, state) {
          final tabStr = state.uri.queryParameters['tab'];
          final initialTab = int.tryParse(tabStr ?? '') ?? 0;
          final statusStr = state.uri.queryParameters['status'];
          HistoryStatus? initialHistoryStatus;
          if (statusStr != null) {
            if (statusStr == 'ongoing') {
              initialHistoryStatus = HistoryStatus.ongoing;
            } else if (statusStr == 'completed') {
              initialHistoryStatus = HistoryStatus.completed;
            } else if (statusStr == 'canceled') {
              initialHistoryStatus = HistoryStatus.canceled;
            }
          }
          return customer_app_main.MainScreen(
            initialTab: initialTab,
            initialHistoryStatus: initialHistoryStatus,
          );
        },
      ),
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
      GoRoute(
        path: '/category-list',
        builder: (context, state) {
          // Query params (not extra) so the screen is deeplinkable.
          final title = state.uri.queryParameters['title'] ?? 'รายการเมนู';
          final categoryId = state.uri.queryParameters['categoryId'];
          return CategoryListScreen(title: title, categoryId: categoryId);
        },
      ),
      GoRoute(
        path: '/item-search',
        builder: (context, state) => const ItemSearchScreen(),
      ),
      GoRoute(
        path: '/place-search',
        builder: (context, state) => const PlaceSearchScreen(),
      ),
      GoRoute(
        path: '/select-pickup',
        builder: (context, state) => const PickupSelectionScreen(),
      ),
      GoRoute(
        path: '/select-dropoff',
        builder: (context, state) => const DropoffSelectionScreen(),
      ),
      GoRoute(
        path: '/food-place-search',
        builder: (context, state) => const FoodPlaceSearchScreen(),
      ),
      GoRoute(
        path: '/food-location-selection',
        builder: (context, state) {
          final fromAddAddress =
              state.uri.queryParameters['from'] == 'add-address';
          return FoodLocationSelectionScreen(isFromAddAddress: fromAddAddress);
        },
      ),
      GoRoute(
        path: '/ride-landing',
        builder: (context, state) => const RideLandingScreen(),
      ),
      GoRoute(
        path: '/food-delivery',
        builder: (context, state) => const FoodDeliveryScreen(),
      ),
      GoRoute(
        path: '/restaurant/:id',
        builder: (context, state) {
          final restaurantId = state.pathParameters['id']!;
          return RestaurantDetailScreen(restaurantId: restaurantId);
        },
      ),
      GoRoute(
        path: '/food-order/tracking/:id',
        builder: (context, state) {
          final orderId = state.pathParameters['id']!;
          return LiveFoodTrackingScreen(orderId: orderId);
        },
      ),
      GoRoute(
        path: '/food-order/chat/:id',
        builder: (context, state) {
          final orderId = state.pathParameters['id']!;
          return FoodChatScreen(orderId: orderId);
        },
      ),
      GoRoute(
        path: '/food-order/receipt/:id',
        builder: (context, state) {
          final orderId = state.pathParameters['id']!;
          return FoodReceiptScreen(orderId: orderId);
        },
      ),
      GoRoute(
        path: '/food-order/rating/:id',
        builder: (context, state) {
          final orderId = state.pathParameters['id']!;
          return FoodRatingScreen(orderId: orderId);
        },
      ),
      GoRoute(
        path: '/food-order/resume',
        builder: (context, state) => const ResumeFoodOrderScreen(),
      ),
      GoRoute(
        path: '/booking',
        builder: (context, state) => const BookingScreen(),
      ),
      GoRoute(
        path: '/messenger-booking',
        builder: (context, state) => const MessengerBookingScreen(),
      ),
      GoRoute(
        path: '/messenger/tracking/:id',
        builder: (context, state) {
          final orderId = state.pathParameters['id']!;
          return MessengerTrackingScreen(orderId: orderId);
        },
      ),
      GoRoute(
        path: '/messenger/chat/:id',
        builder: (context, state) {
          final orderId = state.pathParameters['id']!;
          return MessengerChatScreen(orderId: orderId);
        },
      ),
      GoRoute(
        path: '/messenger/review/:id',
        builder: (context, state) {
          final orderId = state.pathParameters['id']!;
          return MessengerReviewScreen(orderId: orderId);
        },
      ),
      GoRoute(
        path: '/live/:id',
        builder: (context, state) {
          final jobId = state.pathParameters['id'];
          return LiveRideScreen(jobId: jobId);
        },
      ),
      GoRoute(
        path: '/chat/:id',
        builder: (context, state) {
          final jobId = state.pathParameters['id']!;
          return ChatScreen(jobId: jobId);
        },
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/edit-profile',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/loyalty',
        builder: (context, state) => const LoyaltyScreen(),
      ),
      GoRoute(
        path: '/saved-places',
        builder: (context, state) => const SavedPlacesScreen(),
      ),
      GoRoute(
        path: '/add-address',
        builder: (context, state) => const AddressFormScreen(),
      ),
      GoRoute(
        path: '/promos',
        builder: (context, state) => const PromoListScreen(),
        routes: [
          // Nested so a deeplink to a promo gets the list as its back stack.
          GoRoute(
            path: ':id',
            builder: (context, state) {
              final promoId = state.pathParameters['id']!;
              return PromoDetailScreen(promoId: promoId);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/referral',
        builder: (context, state) => const ReferralScreen(),
      ),
      GoRoute(path: '/sos', builder: (context, state) => const SOSScreen()),
      GoRoute(
        path: '/privacy',
        builder: (context, state) => const PrivacyPdpaScreen(),
      ),
      GoRoute(
        path: '/add-card',
        builder: (context, state) => const AddCardScreen(),
      ),
      GoRoute(
        path: '/payment/promptpay',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          final jobId = extra['jobId'] as String?;
          final orderId = extra['orderId'] as String?;
          final onPaidRoute = extra['onPaidRoute'] as String?;
          return PromptPayQrScreen(
            jobId: jobId,
            orderId: orderId,
            onPaidRoute: onPaidRoute,
          );
        },
      ),
      GoRoute(
        path: '/rating/:id',
        builder: (context, state) {
          final jobId = state.pathParameters['id']!;
          final driverProfile = state.extra as DriverProfileModel?;
          return RatingScreen(jobId: jobId, driverProfile: driverProfile);
        },
      ),
      GoRoute(path: '/trips', builder: (context, state) => const TripsScreen()),
      GoRoute(
        path: '/trip/:id',
        builder: (context, state) {
          final tripId = state.pathParameters['id']!;
          final orderType = state.uri.queryParameters['type'];
          return customer_app_trip_detail.TripDetailScreen(
            tripId: tripId,
            orderType: orderType,
          );
        },
      ),
    ],
  );
});

class ActiveOrdersObserver extends NavigatorObserver {
  final Ref ref;

  ActiveOrdersObserver(this.ref);

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    final previousName = previousRoute?.settings.name;
    if (previousName == '/main' ||
        previousName == '/food-delivery' ||
        previousName == '/' ||
        previousName == '/home') {
      Future.microtask(() {
        ref.read(activeOrdersControllerProvider.notifier).refresh();
      });
    }
  }
}
