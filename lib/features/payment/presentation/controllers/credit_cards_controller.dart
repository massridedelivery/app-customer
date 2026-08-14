import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Card networks we style differently in the UI.
enum CardBrand { visa, mastercard, amex, unknown }

CardBrand cardBrandFromNumber(String digits) {
  if (digits.isEmpty) return CardBrand.unknown;
  final first = digits[0];
  if (first == '4') return CardBrand.visa;
  if (first == '5') return CardBrand.mastercard;
  if (first == '3') return CardBrand.amex;
  return CardBrand.unknown;
}

String cardBrandLabel(CardBrand b) => switch (b) {
  CardBrand.visa => 'VISA',
  CardBrand.mastercard => 'Mastercard',
  CardBrand.amex => 'AMEX',
  CardBrand.unknown => 'CARD',
};

@immutable
class CreditCardUi {
  final String id;
  final String holder;
  final String last4;
  final String expiry; // MM/YY
  final CardBrand brand;

  const CreditCardUi({
    required this.id,
    required this.holder,
    required this.last4,
    required this.expiry,
    required this.brand,
  });
}

/// UI-only, in-memory store of saved cards. There is no list endpoint on the
/// backend yet, so this holds mock data for the credit-card screens. Swap the
/// notifier for an API-backed one once `GET /api/payment/cards` exists.
class CreditCardsNotifier extends Notifier<List<CreditCardUi>> {
  @override
  List<CreditCardUi> build() => const [];

  void add(CreditCardUi card) => state = [...state, card];

  void remove(String id) =>
      state = state.where((c) => c.id != id).toList();
}

final creditCardsProvider =
    NotifierProvider<CreditCardsNotifier, List<CreditCardUi>>(
      CreditCardsNotifier.new,
    );
