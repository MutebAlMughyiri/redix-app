/// A way a project pays, such as شبكة, as the API answers it.
class PaymentMethod {
  /// The payment method the API describes in [json].
  PaymentMethod.fromJson(Map<String, dynamic> json) : id = json['id'] as String, name = json['name'] as String, isActive = json['isActive'] as bool;

  /// The method's id.
  final String id;

  /// The method's name, as it was typed.
  final String name;

  /// False once disabled: it disappears from entry and stays on the entries that used it.
  final bool isActive;
}
