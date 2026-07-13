# DEV_LOG: 2026-07-10 (Map perf — backlog items #2/#3/#5/#6)

## Completed Tasks
- **#2 `.select` on map screens** — home_screen, pickup/dropoff/food-location selection, booking_screen, live_ride_screen no longer watch `homeControllerProvider` whole; each selects only the fields it renders (locations/addresses/selectionMode). Unrelated HomeState changes no longer rebuild GoogleMap subtrees. live_ride helper methods now take the two addresses instead of a `dynamic homeState`.
- **#3 memoized polyline decode** — live_ride_screen reuses `decodedPolylineProvider` (shared with BookingMapWidget); live_food_tracking_map gets `foodRoutePolylineProvider`. Neither decodes the route inline in build anymore (live screens rebuild every ~2s on driver location).
- **#5 shared marker bitmaps** — new `core/utils/map_marker_providers.dart` (`pickupMarkerProvider`/`dropoffMarkerProvider`, keepAlive): SVG→PNG rasterisation now happens once per session instead of once per screen visit. booking/live_ride/trip_detail/food-tracking all consume the providers; removed per-screen `_loadMarkers` + home_screen's dead marker code (unused icons it loaded but never used).
- **#6 single fit animation** — removed the duplicated 300ms-delayed `_fitMapToMarkers` calls in BookingMapWidget and live_ride_screen (double camera animation on map open).
- `flutter analyze`: no errors; fixed the unused-import fallout; home_screen's long-standing unused-field warnings are gone.

## Next Steps
- Optional: hot-restart on device and re-check pan/open smoothness; profile-mode run for numbers if needed.

# DEV_LOG: 2026-07-10 (Map perf — pan rebuild storm + terrain tiles)

## Completed Tasks
- **Map perf fix #1 — stopped the per-frame rebuild storm while panning.** `HomeController.onCameraMove` wrote `state.copyWith(mapCenter:)` on every camera frame (~60/s); `mapCenter` lives in the shared `HomeState`, which 13 widgets watch whole (several holding a `GoogleMap`), so dragging the map rebuilt the map screens themselves every frame. The live center now sits in a private `_liveMapCenter` field and is committed to state **once per gesture** in `onCameraIdle` (only while in selection mode — its only consumers, reverse-geocode + save-place, read it at that point).
- **Map perf fix #4 — `MapType.terrain` → `MapType.normal`** on home_screen + pickup/dropoff/food-location selection screens (terrain tiles are heavier to fetch/render and add nothing to ride-hailing UI).
- `flutter analyze` clean (no new issues).

## Known Issues / Notes
- Remaining map-perf backlog (analysed, not yet done): whole-state watches on map screens → `.select`; memoize polyline decode in live_ride/live_food maps; cache marker bitmaps in shared providers; remove home_screen dead marker code; double `_fitMapToMarkers` animation in BookingMapWidget.

## Next Steps
- Pick up the remaining backlog items above (biggest first: `.select` on map screens).

# DEV_LOG: 2026-07-04 (Messenger PromptPay QR flow — SCRUM-35 §3.3)

## Completed Tasks
- **Wired messenger orders into the PromptPay QR flow** (branch `feature/qr-promoptpay`) per the SCRUM-35 §3.3 target contract (`order_id`-based intents).
  - Payment layer: `createIntentForOrder` (`POST /api/payment/intent {order_id, payment_method}` — no client amount) + `getIntentByOrder` (`GET /api/payment/intent/order/{id}`, 404→null) across `IPaymentRepository` / `PaymentDataSource` / `PaymentRepositoryImpl`.
  - `PromptPayController` generalized: `startForJob(jobId)` / `startForOrder(orderId)` share one `_start()` (idempotency check + create + poll); `retry()` reuses the active target. Ride call site updated (`startForJob`).
  - `PromptPayQrScreen` generalized: takes exactly one of `jobId`/`orderId` (+ optional `onPaidRoute`); on PAID replaces itself with `/live/{jobId}` or `/messenger/tracking/{orderId}`. Route `/payment/promptpay` parses `jobId|orderId|onPaidRoute` extras.
  - `messenger_booking_screen`: after `createOrder` succeeds with PROMPTPAY → `push` the QR screen (booking stays beneath so expiry/failure can fall back); other methods go straight to tracking as before.
  - `build_runner` + `flutter analyze` clean.

## Known Issues / Notes
- **Backend still gates messenger digital payment (phase 1: CASH|COD per SCRUM-41)** — creating a messenger order/intent with PROMPTPAY returns 400 today. The flow is wired for when it opens; error paths (booking snackbar / QR error state with retry+back) cover the gated case.
- Same known limitation as ride: "จ่ายเงินสดแทน" on QR expiry pops back without a payment-method-swap endpoint; the PROMPTPAY order is left for the backend to expire.

## Next Steps
- E2E once backend enables order intents; then update SCRUM-35 acceptance for §3.3.

# DEV_LOG: 2026-07-04 (dev/prod environments — full flavors)

## Completed Tasks
- **Added dev/prod environment support** (branch `feature/make-env`) via Flutter flavors + `--dart-define-from-file`.
  - `lib/core/config/app_env.dart` — `Env` reads `String.fromEnvironment` (`FLAVOR`, `API_BASE_URL`, `WS_BASE_URL`, `APP_NAME`, optional `GOOGLE_PLACES_KEY_*`); all default to dev so a bare run still works.
  - `env/dev.json` (committed), `env/prod.json` (gitignored), `env/prod.json.example` (committed template). Prod host inferred as `driver-api.nutchaphut.dev` (resolves).
  - Wired `ApiService.baseUrl` → `Env.apiBaseUrl`, `SocketService.baseUrl` → `Env.wsBaseUrl`, and `GoogleConfig.placesApiKey` to prefer a non-empty `Env` override (falls back to baked-in keys).
  - **Android** flavors in `build.gradle.kts`: `dev` (`applicationId …customer_app.dev`, name "Customer Dev") / `prod` (name "Customer"); Maps SDK key + app label via `manifestPlaceholders`/`resValue` (manifest now uses `${mapsApiKey}` + `@string/app_name`). Installs side-by-side.
  - `Makefile` + `make.bat`: `run_dev`/`run_prod`/`build_apk_dev`/`build_apk_prod`/`build_ios_dev`/`build_ios_prod`.
  - `ios/Flutter/Dev.xcconfig` + `Prod.xcconfig` templates and `ENV_SETUP.md` documenting the one-time Xcode scheme/config steps (schemes can't be scripted safely).
  - `flutter analyze` clean.

## Known Issues / Notes
- **prod Google Maps keys are placeholders** (reuse dev key) in both the Android `prod` flavor and `Prod.xcconfig` — replace with real prod keys.
- **iOS flavors need manual Xcode setup** (build configs + `dev`/`prod` schemes + bundle-id/name/Maps-key wiring) per ENV_SETUP.md before `--flavor` works on iOS. The Dart env (URLs) already works on iOS once a scheme exists.
- With flavors defined, `flutter run`/build now **require** `--flavor dev|prod`.

## Next Steps
- Confirm the real prod API host + prod Google keys; complete the iOS Xcode steps.



## Completed Tasks
- **Fixed jank on the place-search screens.** The autocomplete results (`searchResults`) and text-search `isSearching` lived inside the shared `HomeState`, so every keystroke's `copyWith` mutated the whole home state. 13 widgets `ref.watch(homeControllerProvider)` as a whole — including screens that stay mounted *under* the pushed search route and contain a GoogleMap (`home_screen`, `home_landing_view`, `ride_landing_screen`, `ride_selection_view`). Result: every keystroke rebuilt the map screens → stutter.
  - Split the transient search state into its own autoDispose provider: new `PlaceSearchController` + `PlaceSearchState { results, isSearching }` (`presentation/controllers/place_search_controller.dart`, `presentation/states/place_search_state.dart`).
  - Removed `searchResults` from `HomeState` and `searchPlaces`/`resolvePlaceDetails`/`clearSearchResults` from `HomeController` (also un-overloaded `HomeState.isSearching`, which the map-pin-selection flow still uses).
  - Repointed `place_search_screen`, `place_search_widgets`, and `food_place_search_screen` to the new provider for results/search/resolve; recent/saved tabs still read `homeControllerProvider.select(...)` (those don't change while typing).
  - Now typing mutates only `PlaceSearchState`; the shared home state (and the maps that watch it) no longer rebuild per keystroke. `build_runner` + `flutter analyze` clean.

## Next Steps
- Optional follow-up: convert the remaining whole-object `ref.watch(homeControllerProvider)` call sites to `.select` so unrelated home-state changes don't rebuild heavy trees either.

# DEV_LOG: 2026-07-03 (Vehicle "unavailable" after cancelling coupon)

## Completed Tasks
- **Fixed: after cancelling a ride coupon, all vehicle options became unselectable.** `VehicleSelectionItem` disables on `!estimation.available`, and `VehicleEstimation.available` defaulted to **false** with `@JsonKey(name: 'available')`. The estimate endpoint doesn't reliably send that flag (docs show no `available` field; elsewhere the API uses `is_available`), so the re-estimate triggered on coupon-cancel parsed no flag → every priced vehicle defaulted to unavailable → greyed out.
  - Changed `available` to **default `true`** (a priced vehicle is selectable unless the backend explicitly says otherwise) and added a `readValue` that accepts either `available` or `is_available`. Regenerated; `flutter analyze` clean. The "explicitly unavailable" case (backend sends `false`) still greys the vehicle out — only the missing-field case flips to selectable.

## Next Steps
- Confirm the backend's real field name/semantics for vehicle availability on `POST /api/customer/jobs/estimate` and align the client if it standardises on one key.

# DEV_LOG: 2026-07-03 (Live-ride WS stuck-on-finding fix)

## Completed Tasks
- **Fixed: customer stuck on "finding driver" after the driver accepts.** The finding→confirming transition depended on a single WebSocket push with no fallback; a missed/misparsed event (or an unmapped backend status string) left the customer stranded. Three-part fix in `LiveRideController` / `LiveRideScreen`:
  1. **Polling fallback** — while no driver is assigned and the job isn't terminal, re-sync every 5s from the authoritative `GET /api/customer/jobs/active` (`getDriverProfile(silent: true)`), auto-stops once a driver is assigned. Guarantees recovery even if the WS `job_status` event is dropped.
  2. **Refetch driver on status change** — the `job_status` handler now pulls the authoritative job (driver details + canonical status) when a non-PENDING status arrives, instead of only setting a raw string. Also switched the fetch from `ref.read(...future)` (which cached the first PENDING result forever) to `ref.refresh(...future)` so every poll/event gets fresh data — this also strengthened the existing `job_accepted` path.
  3. **Defensive UI mapping** — `_getUIState` now leaves the "finding" screen when a driver is assigned (`driverId` non-empty) even if the backend reports a status string the client doesn't map (e.g. ASSIGNED/MATCHED).
- `silent` mode added to `getDriverProfile` so background polls don't toggle the loading spinner or surface transient errors.
- `flutter analyze` clean (only a pre-existing unused-`_buildCancelButton` warning).

## Known Issues / Notes
- Root-cause of the *original* missed event (dropped frame vs unmapped status string) not confirmed without live WS logs — the fix is robust either way. If logs show a specific accepted-status string, add it explicitly to `_getUIState`/`initializeWithJob`.

## Next Steps
- Confirm on-device once a driver accepts a real job; capture `SocketService: Received message` to verify the actual `job_status` shape/string.

# DEV_LOG: 2026-07-03 (Ride PromptPay — SCRUM-35)

## Completed Tasks
- **Ride PromptPay binding** per SCRUM-35 §2–§3.1 (ride only; food/messenger `order_id` intents are backend-blocked in phase 1, so intentionally not wired). Amounts are **server-derived** — the client never sends `amount`.
  - Domain: `PaymentIntent` freezed model + `PaymentIntentStatus` enum (`payment_intent.dart`); dual-key handling for `intent_id` (create) vs `id` (GET) via `readValue`.
  - Data: extended `IPaymentRepository` / `PaymentDataSource` / `PaymentRepositoryImpl` with `createIntent(jobId, PROMPTPAY)` → `POST /api/payment/intent {job_id, payment_method}`, `getIntent(id)`, `getIntentByJob(jobId)` (404→null). Errors wrapped as `ServerException`.
  - Presentation: `PromptPayController` (`@riverpod`) — creates intent (idempotency check via `getIntentByJob` to avoid duplicating an already-PAID job), polls every 3s on a 1s ticker for countdown, hard-stops at `expires_at`+grace and flips to EXPIRED locally, `retry()`, timer cleaned up in `ref.onDispose`. `PromptPayState` (freezed) exposes `isPaid`/`isExpired`/`isTerminal`.
  - `PromptPayQrScreen`: renders QR via `Image.network(qr_code_url)`, mm:ss countdown, "waiting for payment" indicator; `ref.listen` on `isPaid` → `pushReplacement('/live/{jobId}')`; EXPIRED/FAILED/error → retry (new intent) or "จ่ายเงินสดแทน" (pop back to booking).
  - Routing/booking: added `/payment/promptpay` route; ride payment picker in `vehicle_selection_sheet` now offers CASH + พร้อมเพย์ (was an empty stub); `booking_screen` routes to the QR screen when `paymentMethod == PROMPTPAY`, else straight to `/live`.
  - `build_runner` + `flutter analyze` clean (no errors).

## Known Issues / Notes
- **"จ่ายเงินสดแทน" on expiry** currently just pops back to booking (the PROMPTPAY job is left for the backend to expire) — there is no job payment-method-swap endpoint in the spec. Revisit if backend adds one.
- Assumes `qr_code_url` (Omise-hosted) is directly renderable via `Image.network` (no auth header), and that the backend holds the job until PAID before matching — per spec §3.1. Confirm on device once PromptPay is switched on backend-side.
- Card/Omise `saveCard` flow is unrelated to this ticket and untouched.

## Next Steps
- Smoke-test end-to-end once PromptPay is enabled on the backend (QR render, poll → PAID → /live, expiry → retry).

# DEV_LOG: 2026-07-02 (SOS fixes)

## Completed Tasks
- **SOS Emergency recheck + fixes** (`/api/customer/sos` confirmed correct). Fixed 4 issues:
  1. **Real location instead of hardcoded**: SOS no longer sends the fixed Bangkok coord `{13.7563, 100.5018}`. New `SosController._resolveLocation()` takes a fresh GPS fix (via `location` pkg, with service/permission handling), falling back to `HomeController.currentLocation`, then a fixed default only as a last resort so the signal is never dropped.
  2. **job_id**: dropped the literal `'job_id': null` (a `.cursorrules` violation); now attaches `authState.activeJobId` via collection-`if` so the SOS is linked to the ongoing trip when present.
  3. **substring crash**: `created_at.substring(0,10)` guarded via `_formatDate()` (handles null/short strings — was a `RangeError` risk).
  4. **Architecture**: moved trigger logic out of the widget into `SosController` (`@riverpod`); `sos_screen` is now a `ConsumerWidget`. Replaced the instance-field `FutureProvider` anti-pattern with a top-level `@riverpod sosHistory` provider.
- New file: `lib/features/profile/presentation/controllers/sos_controller.dart`. Ran `build_runner` + `flutter analyze` — no errors.

## Known Issues / Notes
- None new.

## Next Steps
- Consider surfacing a distinct message when location permission is denied (currently falls back silently to last-known/default).

# DEV_LOG: 2026-07-02

## Completed Tasks
- **Search Place → Direct Google Places API**: Reworked the place-search feature (shared by ride `place_search_screen` and food `food_place_search_screen`) to call Google Places directly instead of the BFF `/api/geospatial/place-search` proxy.
  - Added `core/constants/google_config.dart` (Places API key + base URL; key is a placeholder awaiting a real Places-enabled key) and `core/services/google_places_service.dart` — a dedicated `Dio` client (no BFF `Authorization` interceptor) implementing Autocomplete + Place Details with proper `status`-field error handling.
  - Extended `Place` model with `place_id` / `distance_meters`; added new `PlacePrediction` freezed model for autocomplete rows (no coords — resolved lazily via Details on tap).
  - **Architecture cleanup**: removed the custom `Either<Failure,...>` usage from the entire place feature (repo interface + impl, and all use cases) to comply with `.cursorrules` (repos/usecases now return data directly and throw `ServerException`). Also fixed a `.cursorrules` violation in `addSavedPlace` that injected literal `null`s into the request map (now uses collection-`if`). NOTE: `auth` and `live_ride` still use `Either` — full-codebase alignment is a separate task.
  - Added use cases `getPlaceDetails` and `getRecentPlaces`; repurposed `searchPlaces` → autocomplete.
  - `HomeState`: `searchResults` is now `List<PlacePrediction>`; added `recentPlaces`. `HomeController`: autocomplete search, `resolvePlaceDetails`, `_loadRecentPlaces`, and replaced all `.fold` call sites with try/catch (also in `saved_places_controller` and `checkout_screen`).
  - UI: removed hardcoded "recent" lists from both search screens; wired the Recent tab to BFF `recentPlaces` and Saved tab to `savedPlaces`; tapping an autocomplete row now resolves Details before selecting.
  - Ran `build_runner` and `flutter analyze` — no errors (only pre-existing info/warnings).

## Known Issues / Notes
- **Places API key required**: `google_config.dart` holds a placeholder. A **Places-API-enabled**, non-app-restricted key must be pasted before search works (app-restricted Maps SDK keys return `REQUEST_DENIED` on web-service calls). The service throws a clear Thai message until configured.
- **Recent endpoint unconfirmed**: `getRecentPlaces()` calls `GET /api/customer/places/recent` (best-guess) and degrades to an empty list on 404 — confirm the real path with the Go BFF team.

## Next Steps
- Paste the real Places API key and smoke-test Autocomplete → Details on device.
- Confirm/adjust the recent-places BFF endpoint.
- Optionally add a session token to group Autocomplete+Details billing.


## Completed Tasks
- **Refactoring Checkout Screen**: Refactored `CheckoutScreen` to strictly comply with Clean Architecture and Riverpod standards.
- **Form State Migration**: Moved all form/UI states (cutlery selection, delivery tier, floor/unit, promo code, payment method, and client-side idempotency key generation) into `CheckoutState` and managed them via the `Checkout` notifier.
- **Widget Modularization**: Split the massive 1000+ lines `CheckoutScreen` file into dedicated, modular sub-widgets under `lib/features/food_order/presentation/widgets/`:
  - [checkout_order_items.dart](file:///c:/Users/bossn/AndroidStudioProjects/customer-app/lib/features/food_order/presentation/widgets/checkout_order_items.dart): Renders cart items list and subtotals.
  - [checkout_delivery_address.dart](file:///c:/Users/bossn/AndroidStudioProjects/customer-app/lib/features/food_order/presentation/widgets/checkout_delivery_address.dart): Renders delivery address details and handles floor/unit input.
  - [checkout_delivery_options.dart](file:///c:/Users/bossn/AndroidStudioProjects/customer-app/lib/features/food_order/presentation/widgets/checkout_delivery_options.dart): Handles priority, standard, or saver delivery tier options.
  - [checkout_coupon_section.dart](file:///c:/Users/bossn/AndroidStudioProjects/customer-app/lib/features/food_order/presentation/widgets/checkout_coupon_section.dart): Handles promo code input.
  - [checkout_payment_section.dart](file:///c:/Users/bossn/AndroidStudioProjects/customer-app/lib/features/food_order/presentation/widgets/checkout_payment_section.dart): Handles cash vs card payment selection.
  - [checkout_save_the_world.dart](file:///c:/Users/bossn/AndroidStudioProjects/customer-app/lib/features/food_order/presentation/widgets/checkout_save_the_world.dart): Toggles plastic cutlery check box.
- **Boundary & Relocation Cleanups**: Relocated `CheckoutScreen` from the legacy `home` feature path to [checkout_screen.dart](file:///c:/Users/bossn/AndroidStudioProjects/customer-app/lib/features/food_order/presentation/screens/checkout_screen.dart).
- **Import Mapping**: Updated import statements in [bottom_cart_bar.dart](file:///c:/Users/bossn/AndroidStudioProjects/customer-app/lib/features/food_order/presentation/widgets/bottom_cart_bar.dart) and [food_delivery_screen.dart](file:///c:/Users/bossn/AndroidStudioProjects/customer-app/lib/features/food_delivery/presentation/screens/food_delivery_screen.dart) to match the new location of `CheckoutScreen`.
- **Compilation & Generation Verification**: Re-ran Riverpod/Freezed generators and confirmed complete compilation success by analyzing the project with `flutter analyze`.
- **Order Polling Fix**: Resolved an issue in [LiveFoodTrackingController](file:///c:/Users/bossn/AndroidStudioProjects/customer-app/lib/features/food_order/presentation/controllers/live_food_tracking_controller.dart) where the controller continued polling the order detail endpoint even after the order transitioned into a terminal status (`CANCELLED`, `RESTAURANT_REJECTED`, `COMPLETED`, `DELIVERED`), stopping redundant network requests.
- **Redesigned Cancelled Order Screen**: Redesigned the order cancellation view in [live_food_tracking_screen.dart](file:///c:/Users/bossn/AndroidStudioProjects/customer-app/lib/features/food_order/presentation/screens/live_food_tracking_screen.dart) to feature a modern, layered cancellation illustration, clean typography, detailed explanation cards matching the context (cancelled vs restaurant rejected), and primary/secondary button routing.

## Known Issues / Notes
- None.

# DEV_LOG: 2026-05-27

## Completed Tasks
- **RestaurantDetailScreen Widget Separation**: Separated UI components of [RestaurantDetailScreen](file:///c:/Users/bossn/AndroidStudioProjects/customer-app/lib/features/food_order/presentation/screens/restaurant_detail_screen.dart) into modular, clean widgets under `lib/features/food_order/presentation/widgets/` ([bottom_cart_bar.dart](file:///c:/Users/bossn/AndroidStudioProjects/customer-app/lib/features/food_order/presentation/widgets/bottom_cart_bar.dart), [restaurant_info_card.dart](file:///c:/Users/bossn/AndroidStudioProjects/customer-app/lib/features/food_order/presentation/widgets/restaurant_info_card.dart), [for_you_section.dart](file:///c:/Users/bossn/AndroidStudioProjects/customer-app/lib/features/food_order/presentation/widgets/for_you_section.dart), [category_items_list.dart](file:///c:/Users/bossn/AndroidStudioProjects/customer-app/lib/features/food_order/presentation/widgets/category_items_list.dart)) to improve codebase maintainability and readability.
- **RestaurantDetailScreen Performance Optimization**: Extracted the bottom cart bar into a separate `_BottomCartBar` smart `ConsumerWidget` to isolate rebuilds caused by the `foodCartControllerProvider`. Removed redundant `ref.watch(restaurantDetailProvider(id))` calls inside sub-sections to ensure only necessary components are rebuilt on updates.
- **RestaurantDetailScreen Refactoring**: Refactored [RestaurantDetailScreen](file:///c:/Users/bossn/AndroidStudioProjects/customer-app/lib/features/food_order/presentation/screens/restaurant_detail_screen.dart) from `ConsumerStatefulWidget` to a lightweight `ConsumerWidget`, passing `BuildContext` and `WidgetRef` down to private helper methods to strictly isolate business logic and state.
- **RestaurantDetailScreen Relocation**: Relocated `restaurant_detail_screen.dart` from the legacy `home` feature path to [restaurant_detail_screen.dart](file:///c:/Users/bossn/AndroidStudioProjects/customer-app/lib/features/food_order/presentation/screens/restaurant_detail_screen.dart) and updated import paths in [app_routes.dart](file:///c:/Users/bossn/AndroidStudioProjects/customer-app/lib/router/app_routes.dart).
- **Model Refactoring (JSON Synchronization)**: Updated [food_models.dart](file:///c:/Users/bossn/AndroidStudioProjects/customer-app/lib/features/food_order/domain/models/food_models.dart) to synchronize `HomeSectionModel`, `HomeSectionItemModel`, `MenuCategoryModel`, `MenuItemModel`, `ModifierGroupModel`, and `ModifierModel` with the latest JSON schema, adding missing fields like `overlay_img`, `review_count`, `is_more`, `style`, `created_at`, etc., and regenerated dependencies.
- **RestaurantDetailScreen Loading Fix**: Fixed a bug where `RestaurantDetail` and `FoodChatController` performed synchronous state mutations during the Riverpod `build()` phase, resulting in unhandled exceptions and infinite loading states. Resolved by deferring state loading using `Future.microtask`.
- **API Reload Optimization**: Resolved API reload loops in [FoodDeliveryScreen](file:///C:/Users/bossn/AndroidStudioProjects/customer-app/lib/features/food_delivery/presentation/screens/food_delivery_screen.dart) and [CategoryListScreen](file:///C:/Users/bossn/AndroidStudioProjects/customer-app/lib/features/home/presentation/screens/category_list_screen.dart). Replaced global state watches on `homeControllerProvider` with targeted `.select` queries to only listen to latitude/longitude coordinates and address changes. This prevents redundant, repeated API requests when other home controller states (e.g. `mapCenter` updates during camera movements, `searchResults` updates) change.
- **Models**: Created and generated Freezed models for discovery, profiles, menus, orders, cart state, and legacy mock compatibility in [food_models.dart](file:///c:/Users/bossn/AndroidStudioProjects/customer-app/lib/features/food_order/domain/models/food_models.dart).
- **Data Sources**: Implemented [FoodDiscoveryRemoteDataSource](file:///c:/Users/bossn/AndroidStudioProjects/customer-app/lib/features/food_delivery/data/datasources/food_discovery_remote_data_source.dart) and [FoodOrderRemoteDataSource](file:///c:/Users/bossn/AndroidStudioProjects/customer-app/lib/features/food_order/data/datasources/food_order_remote_data_source.dart) to consume Go BFF backend REST endpoints:
  - Discovery: `GET /api/discovery/home`, `GET /api/discovery/search`, `GET /api/discovery/categories`, `GET /api/discovery/saved`.
  - Orders: `GET /api/food/customer/restaurants/:id`, `GET /api/food/customer/restaurants/:id/menu`, `POST /api/food/customer/estimate`, `POST /api/food/customer/orders`, `GET /api/food/customer/orders/:id`, `POST /api/food/customer/orders/:id/cancel`, `POST /api/food/customer/orders/:id/review`.
- **Repositories**: Developed `FoodDiscoveryRepositoryImpl` and `FoodOrderRepositoryImpl` with robust error mapping (wrapping exceptions in `ServerException`).
- **Cart**: Created state and controller in [FoodCartController](file:///c:/Users/bossn/AndroidStudioProjects/customer-app/lib/features/food_order/presentation/controllers/food_cart_controller.dart) & [FoodCartState](file:///c:/Users/bossn/AndroidStudioProjects/customer-app/lib/features/food_order/presentation/states/food_cart_state.dart) to manage client-side cart items, enforce single-restaurant selection, and compute subtotals locally.
- **Discovery**: Integrated `FoodDiscoveryController` and updated [FoodDeliveryScreen](file:///c:/Users/bossn/AndroidStudioProjects/customer-app/lib/features/food_delivery/presentation/screens/food_delivery_screen.dart) to consume active categories and sections from the real API.
- **Category List Binding**: 
  - Bound category list navigation by updating [PopularCategoriesWidget](file:///c:/Users/bossn/AndroidStudioProjects/customer-app/lib/features/food_delivery/presentation/widgets/popular_categories_widget.dart) to pass `categoryId` to [CategoryListScreen](file:///c:/Users/bossn/AndroidStudioProjects/customer-app/lib/features/home/presentation/screens/category_list_screen.dart).
  - Refactored [CategoryListScreen](file:///c:/Users/bossn/AndroidStudioProjects/customer-app/lib/features/home/presentation/screens/category_list_screen.dart) to fetch location-aware category restaurants using `IFoodDiscoveryRepository.getCategoryRestaurants` and render real restaurant profiles instead of mock food items.
- **Search Screen Binding**:
  - Rewrote [FoodSearchController](file:///c:/Users/bossn/AndroidStudioProjects/customer-app/lib/features/food_order/presentation/controllers/food_search_controller.dart) to watch location and search for restaurants on the real `/api/discovery/search` endpoint.
  - Refactored [ItemSearchScreen](file:///c:/Users/bossn/AndroidStudioProjects/customer-app/lib/features/home/presentation/screens/item_search_screen.dart) to watch the updated state and display a list of [RestaurantProfileModel](file:///c:/Users/bossn/AndroidStudioProjects/customer-app/lib/features/food_order/domain/models/food_models.dart) search results, eliminating mock search data dependencies.
- **Menu & Details**: Refactored [RestaurantDetailScreen](file:///c:/Users/bossn/AndroidStudioProjects/customer-app/lib/features/home/presentation/screens/restaurant_detail_screen.dart) and [MenuItemBottomSheet](file:///c:/Users/bossn/AndroidStudioProjects/customer-app/lib/features/home/presentation/widgets/menu_item_bottom_sheet.dart) to show dynamic modifiers, respect availability, enforce selection limits, and calculate item prices dynamically.
- **Checkout**: Integrated `CheckoutController` and [CheckoutScreen](file:///c:/Users/bossn/AndroidStudioProjects/customer-app/lib/features/home/presentation/screens/checkout_screen.dart) to retrieve fare estimate tiers (Saver, Standard, Priority) and securely place orders using unique client-side generated idempotency keys.
- **Live Tracking**: Integrated [LiveFoodTrackingController](file:///c:/Users/bossn/AndroidStudioProjects/customer-app/lib/features/food_order/presentation/controllers/live_food_tracking_controller.dart) and [LiveFoodTrackingScreen](file:///c:/Users/bossn/AndroidStudioProjects/customer-app/lib/features/food_order/presentation/screens/live_food_tracking_screen.dart) to track active orders via real-time WebSocket statuses (`new_food_order`, `order_accepted`, `order_preparing`, etc.) with fallback HTTP polling.
- **Verification**: Ran code generation and resolved all static analysis and lint warnings.

## Known Issues / Notes
- Live courier GPS location is not streamed via WebSocket for food orders due to backend platform limitations; order tracking relies on status events and fallback polling.

# DEV_LOG: 2026-05-26

## Completed Tasks
- Refactored and simplified `FoodDeliveryScreen`:
  - Extracted 7 large inline UI widgets into separate, modular files under `lib/features/food_delivery/presentation/widgets/`.
  - Converted `FoodDeliveryScreen` into a simplified coordinator screen, reducing complexity.
  - Activated and integrated glassmorphic animated delivery tabs in the `SliverAppBar` using a smooth `AnimatedContainer` design matching the premium red brand theme.
  - Cleaned up analyzer warnings by resolving the unused `_buildTab` method.
- Refactored and relocated `FoodDeliveryScreen` to its own dedicated feature module:
  - Created Clean Architecture folder structure under `lib/features/food_delivery/` (`data`, `domain`, `presentation/screens`, `presentation/widgets`, `presentation/controllers`).
  - Relocated `food_delivery_screen.dart` to the new feature path `lib/features/food_delivery/presentation/screens/food_delivery_screen.dart`.
  - Updated router configurations in [app_routes.dart](file:///c:/Users/bossn/AndroidStudioProjects/customer-app/lib/router/app_routes.dart) to point to the new import path.
  - Formatted and ran compilation verification checks using `flutter analyze` and `dart fix`.

## Known Issues / Notes
- None.

# DEV_LOG: 2026-05-24

## Completed Tasks
- Refactored Chat models and entities to follow Clean Architecture rules:
  - Created an immutable Freezed `ChatMessage` model in [chat_message.dart](file:///c:/Users/bossn/AndroidStudioProjects/customer-app/lib/features/chat/domain/models/chat_message.dart) with normalization logic inside a static helper to handle websocket payloads and custom database models seamlessly.
  - Created a reusable freezed `ChatState` model in [chat_state.dart](file:///c:/Users/bossn/AndroidStudioProjects/customer-app/lib/features/chat/presentation/states/chat_state.dart) to manage message lists, pagination states (`isLoadingMore`, `hasReachedEnd`), loading states, and error messages.
- Implemented and integrated REST API methods for message sending:
  - Added `sendJobChatMessage` and `sendOrderChatMessage` POST endpoints to [api_repository.dart](file:///c:/Users/bossn/AndroidStudioProjects/customer-app/lib/core/data/api_repository.dart).
  - Configured `ChatController` and `FoodChatController` to invoke the corresponding REST POST endpoint when sending a message, supporting optimistic updates and failure recovery.
- Upgraded WebSocket message processing:
  - Replaced legacy parsing in both controllers with robust support for the new flat WebSocket payload (`room_id`, `type: chat_message`, etc.) where properties are at the root level.
- Integrated Cursor-based Pagination logic:
  - Added `fetchMoreMessages` pagination method to `ChatController` and `FoodChatController`, fetching historical messages using the oldest message ID as `before`.
  - Added scroll listeners to [chat_screen.dart](file:///c:/Users/bossn/AndroidStudioProjects/customer-app/lib/features/chat/presentation/screens/chat_screen.dart) and [food_chat_screen.dart](file:///c:/Users/bossn/AndroidStudioProjects/customer-app/lib/features/food_order/presentation/screens/food_chat_screen.dart) to automatically trigger `fetchMoreMessages` when scrolled near the top.
  - Implemented top loading spinners in screens during historical message loading.
  - Reversed API-returned messages (Newest First) to UI order (Oldest at Top, Newest at Bottom).
- Updated Router Paths:
  - Modified [app_routes.dart](file:///c:/Users/bossn/AndroidStudioProjects/customer-app/lib/router/app_routes.dart) to route `/chat/:id` to the Riverpod-integrated `ChatScreen` rather than the static mock screen.
- Ran Riverpod and Freezed code generation (`.\make gen`) and verified complete compilation success using `flutter analyze`.

## Known Issues / Notes
- None.

# DEV_LOG: 2026-05-22


## Completed Tasks
- Implemented POST `/api/notifications/register-device` API service inside the register feature following Clean Architecture guidelines:
  - Added `registerDevice()` to [RegisterRemoteDataSource](file:///c:/Users/bossn/AndroidStudioProjects/customer-app/lib/features/register/data/datasources/register_remote_data_source.dart) and implemented it with Dio post request.
  - Added `registerDevice()` to [RegisterRepository](file:///c:/Users/bossn/AndroidStudioProjects/customer-app/lib/features/register/domain/repositories/register_repository.dart) and implemented it in [RegisterRepositoryImpl](file:///c:/Users/bossn/AndroidStudioProjects/customer-app/lib/features/register/data/repositories/register_repository_impl.dart) with proper error wrapping.
- Implemented `registerNotification` inside [RegisterController](file:///c:/Users/bossn/AndroidStudioProjects/customer-app/lib/features/register/presentation/controllers/register_controller.dart):
  - Added `registerNotification({String? token})` helper to get device type from `PlatformUtils` (in lowercase) and register the device. If the token is not provided, it falls back to retrieving it using `getAccessToken()` from `TokenStorage`.
  - Updated `register({..., String? token})` to sequentially invoke `registerNotification` after successful user profile update.
- Resolved a syntax error in [AuthController](file:///c:/Users/bossn/AndroidStudioProjects/customer-app/lib/features/auth/presentation/controllers/auth_controller.dart) for the `'full_name'` map key value format.
- Implemented POST `/auth/logout` API service inside the profile feature following Clean Architecture guidelines:
  - Added `logout()` definition in [ProfileRemoteDataSource](file:///c:/Users/bossn/AndroidStudioProjects/customer-app/lib/features/profile/data/datasources/profile_remote_data_source.dart) and implemented it using the base ApiService.
  - Added `logout()` to [ProfileRepository](file:///c:/Users/bossn/AndroidStudioProjects/customer-app/lib/features/profile/domain/repositories/profile_repository.dart) and implemented it in [ProfileRepositoryImpl](file:///c:/Users/bossn/AndroidStudioProjects/customer-app/lib/features/profile/data/repositories/profile_repository_impl.dart) with `ServerException` error handling.
- Integrated the API logout service into the main authentication flow:
  - Updated `logout()` in [AuthController](file:///c:/Users/bossn/AndroidStudioProjects/customer-app/lib/features/auth/presentation/controllers/auth_controller.dart) to trigger the logout API call only when the user is logged in, wrapped in a try-catch for resiliency.
- Executed code generation (`build_runner`) and fixed/verified lint status with `flutter analyze`.
- Refactored `RatingScreen` inside the `live_ride` feature following Clean Architecture and Riverpod standards:
  - Created [i_rating_repository.dart](file:///c:/Users/bossn/AndroidStudioProjects/customer-app/lib/features/live_ride/domain/repositories/i_rating_repository.dart) and [rating_repository_impl.dart](file:///c:/Users/bossn/AndroidStudioProjects/customer-app/lib/features/live_ride/data/repositories/rating_repository_impl.dart) to decouple API requests from the UI layer. Complying with error-handling guidelines, it directly throws custom exceptions on failure.
  - Created [submit_rating_usecase.dart](file:///c:/Users/bossn/AndroidStudioProjects/customer-app/lib/features/live_ride/domain/usecases/submit_rating_usecase.dart) and [submit_rating_usecase_impl.dart](file:///c:/Users/bossn/AndroidStudioProjects/customer-app/lib/features/live_ride/domain/usecases/submit_rating_usecase_impl.dart) to invoke rating submissions.
  - Implemented [rating_controller.dart](file:///c:/Users/bossn/AndroidStudioProjects/customer-app/lib/features/live_ride/presentation/controllers/rating_controller.dart) to manage rating submission states (loading/error/success) using `AsyncValue.guard`.
  - Refactored [rating_screen.dart](file:///c:/Users/bossn/AndroidStudioProjects/customer-app/lib/features/live_ride/presentation/screens/rating_screen.dart) to remove business/API logic, listen to the controller's states via `ref.listen<AsyncValue<void>>`, and display loading status and validation messages gracefully.
  - Executed Riverpod code generation (`build_runner`) and code cleanup (`dart fix --apply`, `dart format`).

## Known Issues / Notes
- None.

# DEV_LOG: 2026-05-21

## Completed Tasks
- Refactored `RegisterScreen` into a dedicated feature module under `lib/features/register/` following Clean Architecture and Riverpod generator standards:
  - Created remote data source calling `/auth/register`: [register_remote_data_source.dart](file:///c:/Users/bossn/AndroidStudioProjects/customer-app/lib/features/register/data/datasources/register_remote_data_source.dart)
  - Created repository interface [register_repository.dart](file:///c:/Users/bossn/AndroidStudioProjects/customer-app/lib/features/register/domain/repositories/register_repository.dart) and its implementation [register_repository_impl.dart](file:///c:/Users/bossn/AndroidStudioProjects/customer-app/lib/features/register/data/repositories/register_repository_impl.dart) with proper error wrapping.
  - Created [register_usecase.dart](file:///c:/Users/bossn/AndroidStudioProjects/customer-app/lib/features/register/domain/usecases/register_usecase.dart).
  - Created [register_controller.dart](file:///c:/Users/bossn/AndroidStudioProjects/customer-app/lib/features/register/presentation/controllers/register_controller.dart) using `AsyncValue.guard()` and auto-logging in the user upon registration success.
  - Moved screen view to [register_screen.dart](file:///c:/Users/bossn/AndroidStudioProjects/customer-app/lib/features/register/presentation/screens/register_screen.dart) and bound it to `registerControllerProvider`.
  - Cleaned up the old `register` method in `AuthController` and deleted the old screen.
  - Executed Riverpod code generation (`build_runner`) and validated compilation with `flutter analyze`.
  - Optimized `RegisterScreen` rendering performance by isolating loading state rebuilds using `Consumer` and `ref.select`, and extracting UI helper methods into `const StatelessWidget` widgets.

## Known Issues / Notes
- None.

## Next Steps
- Implement UI-specific unit tests for `RegisterController` if requested.

# DEV_LOG: 2026-05-20


## Completed Tasks
- Scaffolding of the History Order feature under `lib/features/trips/`:
  - Created domain models using Freezed matching the backend's paginated order history structure: [history_order.dart](file:///c:/Users/bossn/AndroidStudioProjects/customer-app/lib/features/trips/domain/models/history_order.dart).
  - Created trips repository abstraction: [i_trips_repository.dart](file:///c:/Users/bossn/AndroidStudioProjects/customer-app/lib/features/trips/domain/repositories/i_trips_repository.dart).
  - Created trips repository implementation invoking the `GET /api/customer/history` endpoint: [trips_repository_impl.dart](file:///c:/Users/bossn/AndroidStudioProjects/customer-app/lib/features/trips/data/repositories/trips_repository_impl.dart).
  - Updated `TripsState` and `TripsController` with `fetchHistoryOrders` method to invoke the API: [trips_state.dart](file:///c:/Users/bossn/AndroidStudioProjects/customer-app/lib/features/trips/presentation/states/trips_state.dart) and [trips_controller.dart](file:///c:/Users/bossn/AndroidStudioProjects/customer-app/lib/features/trips/presentation/controllers/trips_controller.dart).
  - Executed Riverpod and Freezed code generation successfully (`build_runner`).
- UI Integration and Paginated List Binding in `TripsScreen`:
  - Mapped categories to the API constraints:
    - "กำลังดำเนินการอยู่" -> Calls API without sending `type` parameter (sends null/omitted query param).
    - "เดินทาง" -> Sends `type = "RIDE"`.
    - "อาหาร" -> Sends `type = "FOOD"`.
    - "ของใช้" -> Sends `type = "MART"`.
  - Integrated `ScrollController` to track scrolling position and trigger fetch of subsequent pages once reaching close to the bottom.
  - Set up loading indicators (for both main loading state and paginated loading more state) and error recovery views.
  - Created custom date formatter to format ISO date strings into Thai locale representation matching the UI design specifications (e.g. `27 ก.พ. 2569, 17:44 น.`).
  - Added clean status color mappings for `สำเร็จ` (Green) and `ถูกยกเลิก` (Red).
- Scaffolding of the Order/Trip Detail Feature:
  - Extended [i_trips_repository.dart](file:///c:/Users/bossn/AndroidStudioProjects/customer-app/lib/features/trips/domain/repositories/i_trips_repository.dart) to define detail fetching methods: `getFoodOrderDetail` and `getRideOrderDetail`.
  - Implemented the endpoints `GET /api/food/customer/orders/{id}` and `GET /api/customer/jobs/{id}` in [trips_repository_impl.dart](file:///c:/Users/bossn/AndroidStudioProjects/customer-app/lib/features/trips/data/repositories/trips_repository_impl.dart).
  - Created `TripDetailState` in [trip_detail_state.dart](file:///c:/Users/bossn/AndroidStudioProjects/customer-app/lib/features/trips/presentation/states/trip_detail_state.dart) to capture loading states, errors, and detail structures.
  - Created `TripDetailController` in [trip_detail_controller.dart](file:///c:/Users/bossn/AndroidStudioProjects/customer-app/lib/features/trips/presentation/controllers/trip_detail_controller.dart) to retrieve details dynamically based on ID.
  - Executed Riverpod and Freezed code generation successfully (`build_runner`).
- UI Integration and Navigation for `TripDetailScreen`:
  - Updated [trips_screen.dart](file:///c:/Users/bossn/AndroidStudioProjects/customer-app/lib/features/trips/presentation/screens/trips_screen.dart) onTap navigation to route to `/trip/{id}` passing the order `type` as a query parameter (e.g., `?type=RIDE` or `?type=FOOD`).
  - Updated [app_routes.dart](file:///c:/Users/bossn/AndroidStudioProjects/customer-app/lib/router/app_routes.dart) to parse the `type` query parameter and pass it into the `TripDetailScreen` constructor.
  - Converted [trip_detail_screen.dart](file:///c:/Users/bossn/AndroidStudioProjects/customer-app/lib/features/trips/presentation/screens/trip_detail_screen.dart) to a `ConsumerStatefulWidget` and bound it to `TripDetailController`.
  - Implemented dynamic loading, error state retries, and data mapping:
    - Automatically displays detailed breakdown cards for food item details (including modifier options/price), route maps, payment methods (with specific discount/charge breakdowns), driver ratings, and action options.
    - Standardized date formatting with Thai translation matching the app specifications.

## Known Issues / Notes
- The API endpoint configured is `/api/customer/history` as updated by the user.

## Next Steps
- Implement real actions for `ทำรายการอีกครั้ง` (Re-order) and feedback channels if requested.
