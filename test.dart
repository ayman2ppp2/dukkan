import 'dart:isolate';

Future<void> main(List<String> args) async {
  var ss = ReceivePort();
  // var iso = await Isolate.spawn();
  print(await Isolate.run(heavy));
  print('here');
  // iso;
}

int heavy() {
  Future.delayed(Duration(seconds: 40));
  return 99;
}
