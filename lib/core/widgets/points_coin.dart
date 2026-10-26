import 'package:customer_app/core/constants/app_assets.dart';
import 'package:flutter/material.dart';

/// The points icon (design C1): a gold coin with the Mass "M" mark engraved in
/// dark gold. Drawn from one tinted asset, so it stays sharp at any [size]
/// from an inline 16px up to a hero.
class PointsCoin extends StatelessWidget {
  const PointsCoin({super.key, this.size = 24});

  final double size;

  static const _rim = Color(0xFFC98A00);
  static const _faceLight = Color(0xFFFFE27A);
  static const _faceDark = Color(0xFFF0A800);
  static const _mark = Color(0xFFA86A00);

  @override
  Widget build(BuildContext context) {
    final markSize = size * 0.56;
    return SizedBox.square(
      dimension: size,
      child: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(color: _rim, shape: BoxShape.circle),
            ),
          ),
          // The face sits a little high so the darker rim shows as a lip.
          Positioned.fill(
            bottom: (size / 22).clamp(1, double.infinity),
            child: const DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_faceLight, _faceDark],
                ),
              ),
            ),
          ),
          Center(
            child: Transform.translate(
              offset: Offset(-size * 0.02, 0),
              child: Image.asset(
                AppAssets.pointsMark,
                width: markSize,
                height: markSize,
                color: _mark,
                colorBlendMode: BlendMode.srcIn,
                filterQuality: FilterQuality.medium,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
