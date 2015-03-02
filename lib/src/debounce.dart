part of stream_transformers;

/// Delivers the last event in the stream after the duration has passed
/// without receiving an event.
///
/// Errors occurring on the source stream will not be ignored. If the
/// source stream is a broadcast stream, then the transformed stream will
/// also be a broadcast stream.
///
///     source:             asdf----asdf----
///     source.debounce(2): -----f-------f--
///
/// **Example:**
///
///     var controller = new StreamController();
///
///     var debounced = controller.stream.transform(new Debounce(new Duration(seconds:1)));
///     debounced.listen(print);
///
///     controller.add(1);
///     controller.add(2);
///     controller.add(3);
///
///     // Prints: 3
class Debounce<T> implements StreamTransformer<T, T> {
  final Duration _duration;

  Debounce(Duration duration) : _duration = duration;

  Stream<T> bind(Stream<T> stream) {
    return stream.transform(new FlatMapLatest((value) => new Stream.periodic(_duration, (_) => value).take(1)));
  }
}