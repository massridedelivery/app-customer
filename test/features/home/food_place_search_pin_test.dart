import 'package:customer_app/core/constants/app_assets.dart';
import 'package:customer_app/features/home/domain/models/place_prediction.dart';
import 'package:customer_app/features/home/presentation/controllers/home_controller.dart';
import 'package:customer_app/features/home/presentation/controllers/place_search_controller.dart';
import 'package:customer_app/features/home/presentation/screens/transport/food_place_search_screen.dart';
import 'package:customer_app/features/home/presentation/states/home_state.dart';
import 'package:customer_app/features/home/presentation/states/place_search_state.dart';
import 'package:customer_app/features/home/presentation/widgets/place_search_widgets.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeHomeController extends HomeController {
  @override
  HomeState build() => const HomeState();
}

class _FakeSearch extends PlaceSearchController {
  @override
  PlaceSearchState build() => const PlaceSearchState(
    results: [
      PlacePrediction(
        placeId: 'p1',
        mainText: 'เซ็นทรัล เวสต์เกต',
        secondaryText: 'บางใหญ่ นนทบุรี',
      ),
    ],
  );
}

void main() {
  testWidgets('food search results use the same red pin as the search field', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          homeControllerProvider.overrideWith(_FakeHomeController.new),
          placeSearchControllerProvider.overrideWith(_FakeSearch.new),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('th'),
          home: FoodPlaceSearchScreen(),
        ),
      ),
    );
    await tester.pump();

    final row = tester.widget<SearchItem>(find.byType(SearchItem));
    expect(row.title, 'เซ็นทรัล เวสต์เกต');
    expect(row.iconAsset, AppAssets.icLocationFill);
  });
}
