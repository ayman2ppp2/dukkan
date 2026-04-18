import 'package:dukkan/core/db.dart';
import 'package:dukkan/util/models/Owner.dart';
import 'package:flutter/material.dart';

class OwnerProvider extends ChangeNotifier {
  late DB db;

  OwnerProvider() {
    init();
  }

  Future<void> init() async {
    db = await DB.getInstance();
  }

  Future<List<Owner>> refreshListOfOwners() async {
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