import 'dart:isolate';

int slowFib(int n) => n <= 1 ? 1 : slowFib(n - 1) + slowFib(n - 2);

Future<void> main() async {
  // Isolate.run executes the computation on a fresh isolate and returns the result.
  final n = 40;
  final t0 = DateTime.now();
  final result = await Isolate.run(() => slowFib(n));
  final dt = DateTime.now().difference(t0);
  print('fib($n) = $result in ${dt.inMilliseconds} ms (Isolate.run)');
}