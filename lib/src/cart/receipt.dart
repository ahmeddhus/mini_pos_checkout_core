import 'models.dart';

/// Receipt models and builder for the Mini-POS Checkout Core.
class Receipt {
  final ReceiptHeader header;
  final List<ReceiptLine> lines;
  final ReceiptTotals totals;

  /// DTO for a receipt, including header, lines, and totals.
  Receipt({
    required this.header,
    required this.lines,
    required this.totals,
  });
}

/// Header for a receipt (date/time).
class ReceiptHeader {
  final DateTime dateTime;

  /// DTO for a receipt header.
  ReceiptHeader({required this.dateTime});
}

/// Line item for a receipt (name, qty, price, discount, line net).
class ReceiptLine {
  final String name;
  final int qty;
  final double price;
  final double discount;
  final double lineNet;

  /// DTO for a receipt line.
  ReceiptLine({
    required this.name,
    required this.qty,
    required this.price,
    required this.discount,
    required this.lineNet,
  });
}

/// Totals for a receipt (subtotal, VAT, grand total).
class ReceiptTotals {
  final double subtotal;
  final double vat;
  final double grandTotal;

  /// DTO for receipt totals.
  ReceiptTotals({
    required this.subtotal,
    required this.vat,
    required this.grandTotal,
  });
}

/// Builds a Receipt DTO from the current cart state and a timestamp.
Receipt buildReceipt(CartState state, DateTime dateTime) {
  final header = ReceiptHeader(dateTime: dateTime);
  final lines = state.lines
      .map((l) => ReceiptLine(
            name: l.item.name,
            qty: l.qty,
            price: l.item.price,
            discount: l.discount,
            lineNet: l.lineNet,
          ))
      .toList();
  final totals = ReceiptTotals(
    subtotal: state.totals.subtotal,
    vat: state.totals.vat,
    grandTotal: state.totals.grandTotal,
  );
  return Receipt(header: header, lines: lines, totals: totals);
}
