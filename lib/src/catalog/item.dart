import 'package:equatable/equatable.dart';

/// Product item model for the Mini-POS Checkout Core.
class Item extends Equatable {
  final String id;
  final String name;
  final double price;

  const Item({
    required this.id,
    required this.name,
    required this.price,
  });

  factory Item.fromJson(Map<String, dynamic> json) => Item(
        id: json['id'] as String,
        name: json['name'] as String,
        price: (json['price'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'price': price,
      };

  /// Represents a product in the catalog.
  @override
  List<Object?> get props => [id, name, price];
}
