import 'package:equatable/equatable.dart';

import '../catalog/item.dart';

/// Models for cart lines, totals, and state in the Mini-POS Checkout Core.

class CartLine extends Equatable {
  /// Represents a line in the cart (item, quantity, discount).
  final Item item;
  final int qty;
  final double discount; // 0.0 - 1.0 (e.g., 0.2 for 20%)

  const CartLine({
    required this.item,
    required this.qty,
    this.discount = 0.0,
  });

  double get lineNet => item.price * qty * (1 - discount);

  @override
  List<Object?> get props => [item, qty, discount];
}

/// Represents the subtotal, VAT, and grand total for the cart.
class CartTotals extends Equatable {
  final double subtotal;
  final double vat;
  final double grandTotal;

  const CartTotals({
    required this.subtotal,
    required this.vat,
    required this.grandTotal,
  });

  @override
  List<Object?> get props => [subtotal, vat, grandTotal];
}

/// Represents the full state of the cart (lines and totals).
class CartState extends Equatable {
  final List<CartLine> lines;
  final CartTotals totals;

  const CartState({
    required this.lines,
    required this.totals,
  });

  @override
  List<Object?> get props => [lines, totals];
}

/// Extension to format numbers as money (e.g., 12.34 -> '12.34').
extension MoneyExtension on num {
  String get asMoney => toStringAsFixed(2);
}
