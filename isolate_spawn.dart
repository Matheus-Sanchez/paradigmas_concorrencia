import 'dart:isolate';
import 'dart:typed_data';

// Entry point for a spawned isolate. It receives the SendPort of the main isolate.
void worker(SendPort mainSendPort) async {
  // Create a port to receive messages from main.
  final workerReceive = ReceivePort();
  // Tell main how to send messages to this worker.
  mainSendPort.send(workerReceive.sendPort);

  await for (final message in workerReceive) {
    if (message is int) {
      // Simple CPU-bound computation: fibonacci
      int fib(int n) => n <= 1 ? 1 : fib(n - 1) + fib(n - 2);
      final result = fib(message);
      mainSendPort.send(result);
    } else if (message is TransferableTypedData) {
      // Receive a large buffer efficiently
      final buffer = message.materialize().asUint8List();
      // Do some processing (sum bytes)
      int sum = 0;
      for (final b in buffer) { sum += b; }
      mainSendPort.send(sum);
    } else if (message == 'exit') {
      mainSendPort.send('bye');
      break;
    }
  }
}

Future<void> main() async {
  final mainReceive = ReceivePort();
  // Spawn a new isolate
  final isolate = await Isolate.spawn(worker, mainReceive.sendPort);

  // First message from the worker will be a SendPort for sending requests
  final workerSendPort = await mainReceive.first as SendPort;

  // Request 1: CPU-bound fibonacci
  final response1 = ReceivePort();
  workerSendPort.send(40); // compute fib(40)
  // Collect a single response
  print('fib(40) = ${await mainReceive.first}');

  // Request 2: Large data with TransferableTypedData (no deep copy)
  final large = Uint8List.fromList(List.generate(1_000_00, (i) => i % 256));
  final ttd = TransferableTypedData.fromList([large]);
  workerSendPort.send(ttd);
  final sum = await mainReceive.first;
  print('sum(large) = $sum');

  // Ask worker to exit
  workerSendPort.send('exit');
  final bye = await mainReceive.first;
  print('worker said: $bye');

  // Kill the isolate (in case it didn't exit)
  isolate.kill(priority: Isolate.immediate);
}