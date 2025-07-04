import 'package:equatable/equatable.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

import '../catalog/item.dart';
import 'models.dart';

/// CartBloc and related events/states for managing the shopping cart logic.
/// Implements undo/redo, hydration, and business rules for a POS system.

// Events
/// Base class for all cart events.
abstract class CartEvent extends Equatable {
  const CartEvent();
  @override
  List<Object?> get props => [];
}

/// Event to add an item to the cart.
class AddItem extends CartEvent {
  final Item item;
  const AddItem(this.item);
  @override
  List<Object?> get props => [item];
}

/// Event to remove an item from the cart by itemId.
class RemoveItem extends CartEvent {
  final String itemId;
  const RemoveItem(this.itemId);
  @override
  List<Object?> get props => [itemId];
}

/// Event to change the quantity of an item in the cart.
class ChangeQty extends CartEvent {
  final String itemId;
  final int qty;
  const ChangeQty(this.itemId, this.qty);
  @override
  List<Object?> get props => [itemId, qty];
}

/// Event to change the discount for an item in the cart.
class ChangeDiscount extends CartEvent {
  final String itemId;
  final double discount; // 0.0 - 1.0
  const ChangeDiscount(this.itemId, this.discount);
  @override
  List<Object?> get props => [itemId, discount];
}

/// Event to clear the cart.
class ClearCart extends CartEvent {}

/// Event to undo the last cart action.
class UndoCart extends CartEvent {}

/// Event to redo the last undone cart action.
class RedoCart extends CartEvent {}

// Bloc
/// Bloc for managing cart state, business rules, undo/redo, and hydration.
class CartBloc extends HydratedBloc<CartEvent, CartState> {
  final List<CartState> _history = [];
  final List<CartState> _future = [];

  CartBloc() : super(_emptyState()) {
    on<AddItem>(_onAddItem);
    on<RemoveItem>(_onRemoveItem);
    on<ChangeQty>(_onChangeQty);
    on<ChangeDiscount>(_onChangeDiscount);
    on<ClearCart>(_onClearCart);
    on<UndoCart>(_onUndoCart);
    on<RedoCart>(_onRedoCart);
  }

  static CartState _emptyState() => CartState(lines: const [], totals: _calcTotals(const []));

  /// Calculates cart totals (subtotal, VAT, grand total) from cart lines.
  static CartTotals _calcTotals(List<CartLine> lines) {
    final subtotal = lines.fold(0.0, (sum, l) => sum + l.lineNet);
    final vat = subtotal * 0.15;
    final grandTotal = subtotal + vat;
    return CartTotals(subtotal: subtotal, vat: vat, grandTotal: grandTotal);
  }

  /// Pushes the current state to the history stack and clears the future stack.
  void _pushHistory(CartState prev) {
    _history.add(prev);
    _future.clear();
  }

  /// Handles AddItem event: adds or increments an item in the cart.
  void _onAddItem(AddItem event, Emitter<CartState> emit) {
    _pushHistory(state);
    final lines = List<CartLine>.from(state.lines);
    final idx = lines.indexWhere((l) => l.item.id == event.item.id);
    if (idx >= 0) {
      final line = lines[idx];
      lines[idx] = CartLine(item: line.item, qty: line.qty + 1, discount: line.discount);
    } else {
      lines.add(CartLine(item: event.item, qty: 1));
    }
    emit(CartState(lines: lines, totals: _calcTotals(lines)));
  }

  /// Handles RemoveItem event: removes an item from the cart.
  void _onRemoveItem(RemoveItem event, Emitter<CartState> emit) {
    _pushHistory(state);
    final lines = state.lines.where((l) => l.item.id != event.itemId).toList();
    emit(CartState(lines: lines, totals: _calcTotals(lines)));
  }

  /// Handles ChangeQty event: updates the quantity of an item.
  void _onChangeQty(ChangeQty event, Emitter<CartState> emit) {
    _pushHistory(state);
    final lines = state.lines
        .map((l) {
          if (l.item.id == event.itemId) {
            return CartLine(item: l.item, qty: event.qty, discount: l.discount);
          }
          return l;
        })
        .where((l) => l.qty > 0)
        .toList();
    emit(CartState(lines: lines, totals: _calcTotals(lines)));
  }

  /// Handles ChangeDiscount event: updates the discount for an item.
  void _onChangeDiscount(ChangeDiscount event, Emitter<CartState> emit) {
    _pushHistory(state);
    final lines = state.lines.map((l) {
      if (l.item.id == event.itemId) {
        return CartLine(item: l.item, qty: l.qty, discount: event.discount);
      }
      return l;
    }).toList();
    emit(CartState(lines: lines, totals: _calcTotals(lines)));
  }

  /// Handles ClearCart event: resets the cart to empty.
  void _onClearCart(ClearCart event, Emitter<CartState> emit) {
    _pushHistory(state);
    emit(_emptyState());
  }

  /// Handles UndoCart event: reverts to the previous cart state if possible.
  void _onUndoCart(UndoCart event, Emitter<CartState> emit) {
    if (_history.isNotEmpty) {
      _future.add(state);
      final prev = _history.removeLast();
      emit(prev);
    }
  }

  /// Handles RedoCart event: reapplies the next cart state if possible.
  void _onRedoCart(RedoCart event, Emitter<CartState> emit) {
    if (_future.isNotEmpty) {
      _history.add(state);
      final next = _future.removeLast();
      emit(next);
    }
  }

  @override
  CartState? fromJson(Map<String, dynamic> json) {
    try {
      final lines = (json['lines'] as List)
          .map((e) => CartLine(
                item: Item.fromJson(e['item']),
                qty: e['qty'],
                discount: (e['discount'] as num).toDouble(),
              ))
          .toList();
      final totals = CartTotals(
        subtotal: (json['totals']['subtotal'] as num).toDouble(),
        vat: (json['totals']['vat'] as num).toDouble(),
        grandTotal: (json['totals']['grandTotal'] as num).toDouble(),
      );
      return CartState(lines: lines, totals: totals);
    } catch (_) {
      return null;
    }
  }

  @override
  Map<String, dynamic>? toJson(CartState state) {
    return {
      'lines': state.lines
          .map((l) => {
                'item': l.item.toJson(),
                'qty': l.qty,
                'discount': l.discount,
              })
          .toList(),
      'totals': {
        'subtotal': state.totals.subtotal,
        'vat': state.totals.vat,
        'grandTotal': state.totals.grandTotal,
      },
    };
  }
}
