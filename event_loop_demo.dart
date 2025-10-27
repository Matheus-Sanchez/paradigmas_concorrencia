import 'dart:async';

Future<void> main() async {
  print('A) start');

  // Event-queue task (Timer)
  Timer.run(() => print('E) timer.run'));

  // Microtask has priority over event tasks
  scheduleMicrotask(() => print('B) microtask 1'));
  scheduleMicrotask(() {
    print('C) microtask 2');
    scheduleMicrotask(() => print('D) nested microtask 3'));
  });

  // Future creates an event-queue task (then handled after microtasks)
  Future(() => print('F) future event 1')).then((_) => print('G) future then'));
  Future(() => print('H) future event 2'));
  print('I) end of main');

  // Expected order (single isolate):
  // A, I, B, C, D, E, F, G, H
}