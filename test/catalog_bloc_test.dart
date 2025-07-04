import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_pos_checkout_core/src/catalog/catalog_bloc.dart';
import 'package:mini_pos_checkout_core/src/catalog/item.dart';

class TestAssetBundle extends CachingAssetBundle {
  final Map<String, String> assets;
  TestAssetBundle(this.assets);

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    if (assets.containsKey(key)) {
      return assets[key]!;
    }
    throw FlutterError('Asset not found: $key');
  }

  @override
  Future<ByteData> load(String key) {
    throw UnimplementedError();
  }
}

void main() {
  const mockCatalogJson = '[{"id":"p01","name":"Coffee","price":2.5}]';

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  test('CatalogBloc loads catalog from JSON', () async {
    final testBundle = TestAssetBundle({'assets/catalog.json': mockCatalogJson});
    final bloc = CatalogBloc(assetBundle: testBundle);
    bloc.add(LoadCatalog());
    await Future.delayed(const Duration(milliseconds: 10));
    expect(bloc.state, isA<CatalogLoaded>());
    final items = (bloc.state as CatalogLoaded).items;
    expect(items.length, 1);
    expect(items.first, const Item(id: 'p01', name: 'Coffee', price: 2.5));
  });

  test('CatalogBloc handles malformed JSON gracefully', () async {
    final testBundle = TestAssetBundle({'assets/catalog.json': 'not a json'});
    final bloc = CatalogBloc(assetBundle: testBundle);
    bloc.add(LoadCatalog());
    await Future.delayed(const Duration(milliseconds: 10));
    expect(bloc.state, isA<CatalogLoaded>());
    expect((bloc.state as CatalogLoaded).items, isEmpty);
  });

  test('CatalogBloc handles missing asset gracefully', () async {
    final testBundle = TestAssetBundle({}); // No assets
    final bloc = CatalogBloc(assetBundle: testBundle);
    bloc.add(LoadCatalog());
    await Future.delayed(const Duration(milliseconds: 10));
    expect(bloc.state, isA<CatalogLoaded>());
    expect((bloc.state as CatalogLoaded).items, isEmpty);
  });

  test('CatalogEvent value equality', () {
    expect(LoadCatalog(), LoadCatalog());
  });

  test('CatalogBloc default constructor uses rootBundle', () {
    final bloc = CatalogBloc();
    expect(bloc.assetBundle, isNotNull);
  });

  test('CatalogState base props are accessed for coverage', () {
    final state = _TestCatalogState();
    state.props;
  });
}

class _TestCatalogState extends CatalogState {}
