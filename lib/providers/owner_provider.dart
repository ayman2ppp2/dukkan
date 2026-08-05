import 'package:dukkan/core/db/db.dart';
import 'package:dukkan/models/Owner.dart';
import 'package:flutter/material.dart';

class OwnerProvider extends ChangeNotifier {
  late DB db;
  List<Owner>? _testOwners;

  OwnerProvider() {
    init();
  }

  @visibleForTesting
  OwnerProvider.forTesting(this.db);

  @visibleForTesting
  OwnerProvider.detachedForTesting({List<Owner> owners = const []}) {
    _testOwners = owners;
  }

  Future<void> init() async {
    db = await DB.getInstance();
  }

  Future<List<Owner>> refreshListOfOwners() async {
    if (_testOwners != null) return _testOwners!;
    return db.getOwnersList();
  }

  void addOwner(Owner owner) {
    db.insertOwner(owner);
    refreshListOfOwners();
    notifyListeners();
  }

  void updateOwner(Owner owner) {
    // db.owners.put(owner.ownerName, owner);
  }

  Future<void> refresh() async {
    notifyListeners();
  }
}