import 'dart:io';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:mini_pos_checkout_core/src/cart/cart_bloc.dart';
import 'package:mini_pos_checkout_core/src/cart/models.dart';
import 'package:mini_pos_checkout_core/src/cart/receipt.dart';
import 'package:mini_pos_checkout_core/src/catalog/catalog_bloc.dart';
import 'package:mini_pos_checkout_core/src/catalog/item.dart';

void main() {
  setUpAll(() async {
    HydratedBloc.storage = await HydratedStorage.build(
      storageDirectory: Directory.systemTemp.createTempSync(),
    );
  });

  setUp(() async {
    await HydratedBloc.storage.clear();
  });

  group('CartBloc', () {
    const coffee = Item(id: 'p01', name: 'Coffee', price: 2.50);
    const bagel = Item(id: 'p02', name: 'Bagel', price: 3.20);

    blocTest<CartBloc, CartState>(
      'Adding two different items results in correct totals',
      build: () => CartBloc(),
      act: (bloc) {
        bloc.add(const AddItem(coffee));
        bloc.add(const AddItem(bagel));
      },
      expect: () => [
        isA<CartState>(),
        isA<CartState>(),
      ],
      verify: (bloc) {
        final state = bloc.state;
        expect(state.lines.length, 2);
        final subtotal = coffee.price + bagel.price;
        final vat = subtotal * 0.15;
        final grandTotal = subtotal + vat;
        expect(state.totals.subtotal, subtotal);
        expect(state.totals.vat, vat);
        expect(state.totals.grandTotal, grandTotal);
      },
    );

    blocTest<CartBloc, CartState>(
      'Changing quantity and discount updates totals',
      build: () => CartBloc(),
      act: (bloc) {
        bloc.add(const AddItem(coffee));
        bloc.add(const ChangeQty('p01', 3)); // 3 coffees
        bloc.add(const ChangeDiscount('p01', 0.2)); // 20% discount
      },
      verify: (bloc) {
        final state = bloc.state;
        expect(state.lines.length, 1);
        final lineNet = coffee.price * 3 * (1 - 0.2);
        final subtotal = lineNet;
        final vat = subtotal * 0.15;
        final grandTotal = subtotal + vat;
        expect(state.totals.subtotal, subtotal);
        expect(state.totals.vat, vat);
        expect(state.totals.grandTotal, grandTotal);
      },
    );

    blocTest<CartBloc, CartState>(
      'Clearing cart resets state',
      build: () => CartBloc(),
      act: (bloc) {
        bloc.add(const AddItem(coffee));
        bloc.add(const AddItem(bagel));
        bloc.add(ClearCart());
      },
      verify: (bloc) {
        final state = bloc.state;
        expect(state.lines, isEmpty);
        expect(state.totals.subtotal, 0.0);
        expect(state.totals.vat, 0.0);
        expect(state.totals.grandTotal, 0.0);
      },
    );

    blocTest<CartBloc, CartState>(
      'Undo reverts the last cart action',
      build: () => CartBloc(),
      act: (bloc) {
        bloc.add(const AddItem(coffee));
        bloc.add(const AddItem(bagel));
        bloc.add(UndoCart());
      },
      verify: (bloc) {
        final state = bloc.state;
        expect(state.lines.length, 1);
        expect(state.lines.first.item, coffee);
      },
    );

    blocTest<CartBloc, CartState>(
      'Redo reapplies the undone cart action',
      build: () => CartBloc(),
      act: (bloc) {
        bloc.add(const AddItem(coffee));
        bloc.add(const AddItem(bagel));
        bloc.add(UndoCart());
        bloc.add(RedoCart());
      },
      verify: (bloc) {
        final state = bloc.state;
        expect(state.lines.length, 2);
        expect(state.lines.any((l) => l.item == bagel), isTrue);
      },
    );
  });

  test('asMoney extension formats to two decimal places', () {
    expect(12.0.asMoney, '12.00');
    expect(12.345.asMoney, '12.35');
    expect(0.asMoney, '0.00');
    expect((-5.1).asMoney, '-5.10');
  });

  test('CartBloc toJson/fromJson roundtrip', () {
    const coffee = Item(id: 'p01', name: 'Coffee', price: 2.50);
    const state = CartState(
      lines: [CartLine(item: coffee, qty: 2, discount: 0.1)],
      totals: CartTotals(subtotal: 4.5, vat: 0.675, grandTotal: 5.175),
    );
    final bloc = CartBloc();
    final json = bloc.toJson(state);
    final restored = bloc.fromJson(json!);
    expect(restored, equals(state));
  });

  blocTest<CartBloc, CartState>(
    'Undo does nothing when history is empty',
    build: () => CartBloc(),
    act: (bloc) => bloc.add(UndoCart()),
    verify: (bloc) {
      expect(bloc.state.lines, isEmpty);
    },
  );

  blocTest<CartBloc, CartState>(
    'Redo does nothing when future is empty',
    build: () => CartBloc(),
    act: (bloc) => bloc.add(RedoCart()),
    verify: (bloc) {
      expect(bloc.state.lines, isEmpty);
    },
  );

  blocTest<CartBloc, CartState>(
    'Remove item not in cart does nothing',
    build: () => CartBloc(),
    act: (bloc) => bloc.add(const RemoveItem('not-in-cart')),
    verify: (bloc) {
      expect(bloc.state.lines, isEmpty);
    },
  );

  blocTest<CartBloc, CartState>(
    'Change quantity to 0 removes the line',
    build: () => CartBloc(),
    act: (bloc) {
      bloc.add(const AddItem(Item(id: 'p01', name: 'Coffee', price: 2.50)));
      bloc.add(const ChangeQty('p01', 0));
    },
    verify: (bloc) {
      expect(bloc.state.lines, isEmpty);
    },
  );

  blocTest<CartBloc, CartState>(
    'Change discount for non-existent item does nothing',
    build: () => CartBloc(),
    act: (bloc) => bloc.add(const ChangeDiscount('not-in-cart', 0.5)),
    verify: (bloc) {
      expect(bloc.state.lines, isEmpty);
    },
  );

  test('buildReceipt with empty cart', () {
    const state = CartState(lines: [], totals: CartTotals(subtotal: 0, vat: 0, grandTotal: 0));
    final receipt = buildReceipt(state, DateTime(2023, 1, 1));
    expect(receipt.lines, isEmpty);
    expect(receipt.totals.subtotal, 0);
    expect(receipt.totals.vat, 0);
    expect(receipt.totals.grandTotal, 0);
    expect(receipt.header.dateTime, DateTime(2023, 1, 1));
  });

  test('buildReceipt with multiple lines, discounts, and VAT', () {
    const coffee = Item(id: 'p01', name: 'Coffee', price: 2.50);
    const bagel = Item(id: 'p02', name: 'Bagel', price: 3.00);
    final lines = [
      const CartLine(item: coffee, qty: 2, discount: 0.1), // 2 * 2.5 * 0.9 = 4.5
      const CartLine(item: bagel, qty: 1, discount: 0.0), // 1 * 3.0 = 3.0
    ];
    const subtotal = 4.5 + 3.0;
    const vat = subtotal * 0.15;
    const grandTotal = subtotal + vat;
    final state = CartState(
      lines: lines,
      totals: const CartTotals(subtotal: subtotal, vat: vat, grandTotal: grandTotal),
    );
    final receipt = buildReceipt(state, DateTime(2023, 1, 2));
    expect(receipt.lines.length, 2);
    expect(receipt.lines[0].name, 'Coffee');
    expect(receipt.lines[0].qty, 2);
    expect(receipt.lines[0].discount, 0.1);
    expect(receipt.lines[0].lineNet, closeTo(4.5, 0.001));
    expect(receipt.lines[1].name, 'Bagel');
    expect(receipt.lines[1].qty, 1);
    expect(receipt.lines[1].discount, 0.0);
    expect(receipt.lines[1].lineNet, closeTo(3.0, 0.001));
    expect(receipt.totals.subtotal, closeTo(subtotal, 0.001));
    expect(receipt.totals.vat, closeTo(vat, 0.001));
    expect(receipt.totals.grandTotal, closeTo(grandTotal, 0.001));
    expect(receipt.header.dateTime, DateTime(2023, 1, 2));
  });

  test('CartEvent value equality', () {
    const item = Item(id: '1', name: 'A', price: 1.0);
    expect(const AddItem(item), const AddItem(item));
    expect(const RemoveItem('x'), const RemoveItem('x'));
    expect(const ChangeQty('x', 2), const ChangeQty('x', 2));
    expect(const ChangeDiscount('x', 0.5), const ChangeDiscount('x', 0.5));
  });

  blocTest<CartBloc, CartState>(
    'Adding the same item twice increments quantity',
    build: () => CartBloc(),
    act: (bloc) {
      const item = Item(id: 'p01', name: 'Coffee', price: 2.5);
      bloc.add(const AddItem(item));
      bloc.add(const AddItem(item));
    },
    verify: (bloc) {
      expect(bloc.state.lines.length, 1);
      expect(bloc.state.lines.first.qty, 2);
    },
  );

  test('Event props are accessed for coverage', () {
    const item = Item(id: '1', name: 'A', price: 1.0);
    const AddItem(item).props;
    const RemoveItem('x').props;
    const ChangeQty('x', 2).props;
    const ChangeDiscount('x', 0.5).props;
    ClearCart().props;
    UndoCart().props;
    RedoCart().props;
    LoadCatalog().props;
  });
}
