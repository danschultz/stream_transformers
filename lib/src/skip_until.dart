part of stream_transformers;

/// Waits to deliver events from a stream until the signal `Future` completes.
/// Errors that happen on the source stream will be forwarded once the `Future`
/// completes. If the source stream is a broadcast stream, then the transformed
/// stream will also be a broadcast stream.
///
/// **Example:**
///
///   var completer = new Completer();
///   var controller = new StreamController();
///
///   var skipStream = controller.stream.transform(new SkipUntil(completer.future));
///
///   skipStream.listen(print);
///
///   controller.add(1);
///   controller.add(2);
///   completer.complete();
///   controller.add(3); // Prints: 3
///   controller.add(4); // Prints: 4
class SkipUntil<T> implements StreamTransformer<T, T> {
  final Future _signal;

  SkipUntil(Future signal) : _signal = signal;

  Stream<T> bind(Stream<T> stream) {
    StreamController<bool> toggler;

    // Begin listening to the signal once the toggle stream has been listened to, otherwise
    // the returned stream might include events before the returned stream has a listener.
    toggler = new StreamController<bool>(onListen: () {
      _signal.then((_) => toggler.add(true));
    });

    return stream.transform(new When(toggler.stream));
  }
}