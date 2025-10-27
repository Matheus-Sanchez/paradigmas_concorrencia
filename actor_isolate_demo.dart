import 'dart:isolate';

// Minimal Actor-like pattern using an Isolate with a mailbox.
class Actor {
  late final Isolate _iso;
  late final SendPort _send;
  final _ready = ReceivePort();
  final _responses = ReceivePort();

  Future<void> start() async {
    _iso = await Isolate.spawn(_actorMain, [_ready.sendPort, _responses.sendPort]);
    _send = await _ready.first as SendPort;
  }

  Future<T> ask<T>(Object message) async {
    // Tag each message with a unique response port to correlate replies
    final rp = ReceivePort();
    _send.send([message, rp.sendPort]);
    final resp = await rp.first as T;
    rp.close();
    return resp;
  }

  void stop() {
    _iso.kill(priority: Isolate.immediate);
    _ready.close();
    _responses.close();
  }

  // Actor behavior in the spawned isolate
  static void _actorMain(List args) {
    final SendPort readyPort = args[0] as SendPort;
    final SendPort mainResponses = args[1] as SendPort;
    final inbox = ReceivePort();
    readyPort.send(inbox.sendPort);

    int state = 0; // Private state, not shared.
    inbox.listen((msg) {
      final data = msg as List;
      final Object command = data[0];
      final SendPort replyTo = data[1] as SendPort;

      if (command is String) {
        switch (command) {
          case 'inc':
            state++;
            replyTo.send(state);
            break;
          case 'get':
            replyTo.send(state);
            break;
          default:
            replyTo.send('unknown');
        }
      } else {
        replyTo.send('unsupported');
      }
    });
  }
}

Future<void> main() async {
  final counter = Actor();
  await counter.start();
  print(await counter.ask<int>('inc')); // 1
  print(await counter.ask<int>('inc')); // 2
  print(await counter.ask<int>('get')); // 2
  counter.stop();
}