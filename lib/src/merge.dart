part of stream_transformers;

/// Combines the events from two streams into a single stream. Errors occurring
/// on any merged stream will be forwarded to the transformed stream. If the
/// source stream is a broadcast stream, then the transformed stream will also
/// be a broadcast stream.
///
/// **Example:**
///
///     var controller1 = new StreamController();
///     var controller2 = new StreamController();
///
///     var merged = controller1.stream.transform(new Merge(controller2.stream));
///
///     merged.listen(print);
///
///     controller1.add(1); // Prints: 1
///     controller2.add(2); // Prints: 2
///     controller1.add(3); // Prints: 3
///     controller2.add(4); // Prints: 4
class Merge<S, T> implements StreamTransformer<S, T> {
  /// Returns a stream that contains the events from a list of streams.
  static Stream all(Iterable<Stream> streams) {
    return new Stream.fromIterable(streams).transform(new MergeAll());
  }

  final Stream<T> _other;

  Merge(Stream<T> other) : _other = other;

  Stream<T> bind(Stream<S> stream) {
    StreamSubscription<S> subscriptionA;
    StreamSubscription<T> subscriptionB;
    var completerA = new Completer();
    var completerB = new Completer();
    StreamController controller;

    void onListen() {
      subscriptionA = stream.listen(controller.add, onError: controller.addError, onDone: completerA.complete);
      subscriptionB = _other.listen(controller.add, onError: controller.addError, onDone: completerB.complete);
    }

    void onPause() {
      subscriptionA.pause();
      subscriptionB.pause();
    }

    void onResume() {
      subscriptionA.resume();
      subscriptionB.resume();
    }

    void onCancel() {
      subscriptionA.cancel();
      subscriptionB.cancel();
    }

    controller = _createControllerLikeStream(
        stream: stream,
        onListen: onListen,
        onPause: onPause,
        onResume: onResume,
        onCancel: onCancel);

    Future.wait([completerA.future, completerB.future]).then((_) => controller.close());

    return controller.stream;

    // TODO(Dan): This would be the ideal implementation, but is causing some tests to fail.
//    return _bindStream(like: stream, onListen: (EventSink sink) {
//      return all([stream, _other]).listen(sink.add, onError: sink.addError, onDone: sink.close);
//    });
  }
}