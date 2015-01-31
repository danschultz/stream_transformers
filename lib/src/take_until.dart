part of stream_transformers;

/// Delivers events from the source stream until the signal `Stream` produces a value.
/// At which point, the transformed stream closes. The returned stream will continue
/// to deliver values if the signal stream closes without a value.
///
/// This is useful for automatically cancelling a stream subscription to prevent memory
/// leaks. Errors that happen on the source and signal stream will be forwarded to the
/// transformed stream. If the source stream is a broadcast stream, then the transformed
/// stream will also be a broadcast stream.
///
/// **Example:**
///
///     var signal = new StreamController();
///     var controller = new StreamController();
///
///     var takeUntil = controller.stream.transform(new TakeUntil(signal.stream));
///
///     takeUntil.listen(print, onDone: () => print("done"));
///
///     controller.add(1); // Prints: 1
///     controller.add(2); // Prints: 2
///     signal.add(true); // Prints: done
///     controller.add(3);
///     controller.add(4);
class TakeUntil<T> implements StreamTransformer<T, T> {
  final Stream _signal;

  TakeUntil(Stream signal) : _signal = signal;

  factory TakeUntil.fromFuture(Future future) => new TakeUntil(new Stream.fromFuture(future));

  Stream<T> bind(Stream<T> stream) {
    StreamSubscription signalSubscription;

    StreamSubscription onListen(EventSink<T> sink) {
      StreamSubscription inputSubscription;

      void done() {
        inputSubscription.cancel();
        sink.close();
      }

      signalSubscription = _signal.take(1).listen((_) => done(), onError: sink.addError);

      inputSubscription = stream.listen(
          (value) => sink.add(value),
          onError: sink.addError,
          onDone: () => done());

      return inputSubscription;
    }

    return _bindStream(like: stream, onListen: onListen, onCancel: () => signalSubscription.cancel());
  }
}