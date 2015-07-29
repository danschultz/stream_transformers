part of stream_transformers;

/// Pauses the delivery of events from the source stream when the signal stream
/// delivers a value of `true`. The buffered events are delivered when the signal
/// delivers a value of `false`. Errors originating from the source and signal
/// streams will be forwarded to the transformed stream and will not be buffered.
/// If the source stream is a broadcast stream, then the transformed stream will
/// also be a broadcast stream.
///
/// **Example:**
///
///     var controller = new StreamController();
///     var signal = new StreamController();
///
///     var stream = controller.stream;
///
///     var buffered = stream.transform(new BufferWhen(signal.stream));
///
///     controller.add(1);
///     signal.add(true);
///     controller.add(2);
///
///     buffered.listen(print); // Prints: 1
class BufferWhen<T> implements StreamTransformer<T, T> {
  final Stream<bool> _signal;

  BufferWhen(Stream<bool> signal) : _signal = signal;

  Stream<T> bind(Stream<T> stream) {
    StreamSubscription signalSubscription;
    StreamSubscription streamSubscription;
    StreamController<T> controller;

    void done() {
      signalSubscription.cancel();
      streamSubscription.cancel();
      controller.close();
    }

    void onListen() {
      streamSubscription = stream.listen(controller.add, onError: controller.addError, onDone: done);
      signalSubscription = _signal.listen((isBuffering) {
        if (isBuffering) {
          streamSubscription.pause();
        } else {
          streamSubscription.resume();
        }
      });
    }

    void onPause() {
      signalSubscription.pause();
      streamSubscription.pause();
    }

    void onResume() {
      signalSubscription.resume();
      streamSubscription.resume();
    }

    controller = _createControllerLikeStream(
        stream: stream,
        onListen: onListen,
        onResume: onResume,
        onPause: onPause,
        onCancel: done);

    return controller.stream;
  }
}