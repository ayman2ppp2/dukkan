import 'dart:io';

import 'package:isolate_pool_2/isolate_pool_2.dart';

class Pool {
  // This holds the singleton instance of the IsolatePool
  static IsolatePool? _pool;

  // Initialize the pool and return the same instance if already created
  static Future<IsolatePool> init() async {
    if (_pool == null) {
      // If the pool has not been initialized, create and start it
      // (Platform.numberOfProcessors ~/ 2) - 1
      _pool = IsolatePool(1);
      await _pool!.start();
    }
    return _pool!; // Return the same instance of the pool
  }
}
