import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart' show rootBundle, AssetBundle;

import 'item.dart';

/// CatalogBloc and related events/states for loading the product catalog from assets.

// Events
/// Base class for all catalog events.
abstract class CatalogEvent extends Equatable {
  const CatalogEvent();
  @override
  List<Object?> get props => [];
}

/// Event to load the product catalog from assets.
class LoadCatalog extends CatalogEvent {}

// States
/// Base class for all catalog states.
abstract class CatalogState extends Equatable {
  const CatalogState();
  @override
  List<Object?> get props => [];
}

/// State representing a loaded product catalog.
class CatalogLoaded extends CatalogState {
  final List<Item> items;
  const CatalogLoaded(this.items);
  @override
  List<Object?> get props => [items];
}

// Bloc
/// Bloc for loading the product catalog from a JSON asset.
class CatalogBloc extends Bloc<CatalogEvent, CatalogState> {
  final AssetBundle assetBundle;
  CatalogBloc({AssetBundle? assetBundle})
      : assetBundle = assetBundle ?? rootBundle,
        super(const CatalogLoaded([])) {
    on<LoadCatalog>(_onLoadCatalog);
  }

  /// Handles LoadCatalog event: loads and parses the catalog JSON asset.
  Future<void> _onLoadCatalog(
    LoadCatalog event,
    Emitter<CatalogState> emit,
  ) async {
    try {
      final String jsonString = await assetBundle.loadString('assets/catalog.json');
      final List<dynamic> jsonList = json.decode(jsonString);
      final items = jsonList.map((e) => Item.fromJson(e)).toList();
      emit(CatalogLoaded(items));
    } catch (_) {
      emit(const CatalogLoaded([]));
    }
  }
}
