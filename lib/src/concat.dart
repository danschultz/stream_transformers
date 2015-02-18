part of stream_transformers;

/// Concatenates two streams into one stream by delivering the values of the source stream,
/// and then delivering the values of the other stream once the source stream completes.
/// This means that it's possible that events from the second stream might not be included
/// if the source stream hasn't completed. Use `Concat.all()` to concatenate many streams.
///
/// Errors will be forwarded from either stream, whether or not the source stream has
/// completed. If the source stream is a broadcast stream, then the transformed stream will
/// also be a broadcast stream.
///
/// **Example:**
///
///     var source = new StreamController();
///     var other = new StreamController();
///
///     var stream = source.stream.transform(new Concat(other.stream));
///     stream.listen(print);
///
///     other..add(1)..add(2);
///     source..add(3)..add(4)..close();
///
///     // 3
///     // 4
///     // 1
///     // 2
class Concat<T> implements StreamTransformer<T, T> {
  static Stream all(Iterable<Stream> streams) {
    return _bindStream(like: streams.first, onListen: (EventSink sink) {
      return new Stream.fromIterable(streams).transform(new ConcatAll())
          .listen(sink.add, onError: sink.addError, onDone: sink.close);
    });
  }

  final Stream<T> _other;

  Concat(Stream<T> other) : _other = other;

  Stream<T> bind(Stream<T> stream) {
    return all([stream, _other]);
  }
}