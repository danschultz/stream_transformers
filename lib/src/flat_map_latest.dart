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
    StreamSubscription latest;

    Future cancelLatest() {
      if (latest != null) {
        return latest.cancel();
      } else {
        return null;
      }
    }

    StreamSubscription<S> onListen(EventSink<T> sink) {
      return stream.listen((event) {
        cancelLatest();

        Stream<T> mappedStream = _convert(event);
        latest = mappedStream.listen(sink.add, onError: sink.addError);
      });
    }

    return bindStream(like: stream, onListen: onListen, onCancel: () => cancelLatest(), onDone: () => cancelLatest());
  }
}