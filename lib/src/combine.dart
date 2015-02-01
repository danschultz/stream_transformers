part of stream_transformers;

/// Combines the latest values of two streams using a two argument function.
/// The combining function will not be called until each stream delivers its
/// first value. After the first value of each stream is delivered, the
/// combining function will be invoked for each event from the source streams.
/// Errors occurring on the streams will be forwarded to the transformed
/// stream. If the source stream is a broadcast stream, then the transformed
/// stream will also be a broadcast stream.
///
/// **Example:**
///
///     var controller1 = new StreamController();
///     var controller2 = new StreamController();
///
///     var combined = controller1.stream.transform(new Combine(controller2.stream, (a, b) => a + b));
///
///     combined.listen(print);
///
///     controller1.add(1);
///     controller2.add(1); // Prints: 2
///     controller1.add(2); // Prints: 3
///     controller2.add(2); // Prints: 4
class Combine<A, B, R> implements StreamTransformer<A, R> {
  /// Combines a list of stream together, where the returned stream will contain
  /// `List`s that contain the current values of each of the streams.
  static Stream<List> all(List<Stream> streams) {
    return _bindStream(onListen: (EventSink<List> sink) {
      Stream<List> merged = Merge.all(streams.map((stream) => stream.map((event) => [stream, event])));
      Stream<Map<Stream, Object>> values = merged.transform(new Scan({}, (previous, current) {
        var values = new Map.from(previous);
        values[current.first] = current.last;
        return values;
      }));

      return values
          .where((values) => values.length == streams.length)
          .map((values) => streams.map((stream) => values[stream]).toList(growable: false))
          .listen((combined) => sink.add(combined), onError: sink.addError, onDone: sink.close);
    });
  }

  final Stream<B> _other;
  final Combiner<A, B, R> _combiner;

  Combine(Stream<B> other, Combiner<A, B, R> combiner) :
    _other = other,
    _combiner = combiner;

  Stream<R> bind(Stream<A> stream) {
    return _bindStream(like: stream, onListen: (EventSink<R> sink) {
      return Combine.all([stream, _other]).listen(
          (values) => sink.add(_combiner(values.first, values.last)),
          onError: sink.addError,
          onDone: sink.close);
    });
  }
}
