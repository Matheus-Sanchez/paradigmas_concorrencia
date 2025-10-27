import 'dart:async';

// A coroutine producing a stream
Stream<int> naturalsUpTo(int n, {Duration delay = const Duration(milliseconds: 50)}) async* {
  for (var i = 1; i <= n; i++) {
    await Future.delayed(delay);
    yield i;
  }
}

// A coroutine consuming a stream
Future<void> sumStream() async {
  final stream = naturalsUpTo(5);
  var sum = 0;
  await for (final v in stream) {
    sum += v;
  }
  print('sum = $sum');
}

Future<void> main() async {
  // Futures with async/await
  Future<int> compute(int x) async {
    await Future.delayed(Duration(milliseconds: 100));
    return x * x;
  }

  final a = compute(2);
  final b = compute(3);
  print('awaiting both...');
  final results = await Future.wait([a, b]);
  print('Future.wait results: $results');

  await sumStream();
}