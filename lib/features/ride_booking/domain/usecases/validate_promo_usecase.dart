abstract class ValidatePromoUseCase {
  /// Returns the total discount amount; throws if the code is not applicable.
  Future<double> call(String code, double subtotal);
}
