import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:customer_app/core/configs/theme.dart';
import 'package:customer_app/core/managers/providers.dart';
import 'package:customer_app/core/services/push_notification_service.dart';
import 'package:customer_app/core/services/socket_service.dart';
import 'package:customer_app/router/app_routes.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:customer_app/core/localization/locale_controller.dart';

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Wires FCM handlers and (when logged in) registers the device token.
    ref.read(pushNotificationServiceProvider).init();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Drives the socket from the app's foreground/background state.
  ///
  /// Backgrounded, the OS closes the socket and then denies the retries that
  /// follow (they fail at DNS), so the service stands down instead of spending
  /// its reconnect budget on attempts that cannot succeed. Coming back, it
  /// re-arms with a fresh budget. `inactive` is deliberately ignored — it fires
  /// for transient interruptions like the app switcher or an incoming call,
  /// where dropping a healthy socket would be pure waste.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    final socket = ref.read(socketServiceProvider);
    switch (state) {
      case AppLifecycleState.resumed:
        if (ref.read(tokenStorageProvider).hasToken) socket.ensureConnected();
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        socket.suspend();
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final locale = ref.watch(localeControllerProvider);

    return MaterialApp.router(
      title: 'Customer App',
      theme: AppTheme.light,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      locale: locale,
      // App-wide: tapping empty space dismisses the keyboard. Interactive
      // widgets (fields, buttons, list items) still win their own taps; only
      // taps that no widget claims fall through to here and unfocus.
      builder: (context, child) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: child,
      ),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('th')],
    );
  }
}
