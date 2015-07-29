part of stream_transformers;

/// Waits to deliver events from a stream until the signal `Stream` delivers a
/// value. Errors that happen on the source stream will be forwarded once the
/// `Stream` delivers its value. Errors happening on the signal stream will be
/// forwarded immediately. If the source stream is a broadcast stream, then the
/// transformed stream will also be a broadcast stream.
///
/// **Example:**
///
///     var signal = new StreamController();
///     var controller = new StreamController();
///
///     var skipStream = controller.stream.transform(new SkipUntil(signal.stream));
///
///     skipStream.listen(print);
///
///     controller.add(1);
///     controller.add(2);
///     signal.add(true);
///     controller.add(3); // Prints: 3
///     controller.add(4); // Prints: 4
class SkipUntil<T> implements StreamTransformer<T, T> {
  final Stream _signal;

  SkipUntil(Stream signal) : _signal = signal;

  Stream<T> bind(Stream<T> stream) {
    return stream.transform(new When<T>(_signal.map((_) => true)));
  }
}