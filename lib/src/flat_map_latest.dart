part of stream_transformers;

/// Similar to `FlatMap`, but instead of including events from all spawned
/// streams, only includes the ones from the latest stream. Think of this
/// as stream switching.
///
/// **Example:**
///
///   var controller = new StreamController();
///   var latest = controller.stream.transform(new FlatMap((value) => new Stream.fromIterable([value + 1]));
///
///   latest.listen(print);
///
///   controller.add(1);
///   controller.add(2); // Prints: 3
class FlatMapLatest<S, T> implements StreamTransformer<S, T> {
  final StreamConverter<S, T> _convert;

  FlatMapLatest(StreamConverter<S, T> convert) : _convert = convert;

  Stream<T> bind(Stream<S> stream) {
    var input = stream.asBroadcastStream();

    return _bindStream(like: stream, onListen: (EventSink<T> sink) {
      return input
          .transform(new FlatMap((value) => _convert(value).transform(new TakeUntil(input))))
          .listen((value) => sink.add(value), onError: sink.addError, onDone: () => sink.close());
    });
  }
}