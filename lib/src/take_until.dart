part of stream_transformers;

/// Delivers events from the source stream until the signal `Future` completes.
/// At which point, the transformed stream closes. This is useful for automatically
/// cancelling a stream subscription to prevent memory leaks. Errors that happen
/// on the source stream will be forwarded to the transformed stream. If the source
/// stream is a broadcast stream, then the transformed stream will also be a
/// broadcast stream.
///
/// **Example:**
///
///   var completer = new Completer();
///   var controller = new StreamController();
///
///   var takeUntil = controller.stream.transform(new TakeUntil(completer.future));
///
///   takeUntil.listen(print);
///
///   controller.add(1); // Prints: 1
///   controller.add(2); // Prints: 2
///   completer.complete();
///   controller.add(3);
///   controller.add(4);
class TakeUntil<T> implements StreamTransformer<T, T> {
  final Future _signal;

  TakeUntil(Future signal) : _signal = signal;

  Stream<T> bind(Stream<T> stream) {
    StreamController<T> controller;

    StreamSubscription<T> streamSubscription;
    StreamSubscription<bool> closeSubscription;

    void onListen() {
      streamSubscription = stream.listen(controller.add, onError: controller.addError, onDone: () {
        controller.close();
        closeSubscription.cancel();
      });

      // Forward the completion handler from the signal into a stream controller. This allows
      // events from Futures and Streams to be scheduled together, and prevents scenarios where
      // the stream receives events and doesn't forward them when they're received in close
      // proximity to when the future completes.
      var closeController = new StreamController();
      _signal.then((_) {
        closeController.add(true);
      });
      closeSubscription = closeController.stream.take(1).listen((_) {
        streamSubscription.cancel();
        controller.close();
      });
    }

    controller = _createControllerLikeStream(stream: stream,
        onListen: () => onListen(),
        onCancel: () {
          streamSubscription.cancel();
          closeSubscription.cancel();
        },
        onPause: () => streamSubscription.pause(),
        onResume: () => streamSubscription.resume());
    return controller.stream;
  }
}