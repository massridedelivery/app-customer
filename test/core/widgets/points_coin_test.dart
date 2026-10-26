import 'package:customer_app/core/constants/app_assets.dart';
import 'package:customer_app/core/widgets/points_coin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('draws the tinted Mass mark at the asked size', (tester) async {
    for (final size in [16.0, 40.0]) {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: PointsCoin(key: ValueKey(size), size: size)),
        ),
      );
      expect(tester.getSize(find.byType(PointsCoin)), Size(size, size));
      final mark = tester.widget<Image>(find.byType(Image));
      expect((mark.image as AssetImage).assetName, AppAssets.pointsMark);
      expect(mark.width, closeTo(size * 0.56, 0.001));
    }
    expect(tester.takeException(), isNull);
  });
}
