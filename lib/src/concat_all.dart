part of stream_transformers;

/// Concatenates a stream of streams into a single stream, by delivering the first stream's
/// values, and then delivering the next stream's values after the previous stream has
/// completed.
///
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
///     var other1 = new StreamController();
///     var other2 = new StreamController();
///
///     source..add(other1.stream)..add(other2.stream);
///
///     other2..add(1)..add(2);
///     other1..add(3)..add(4)..close();
///
///     var stream = source.stream.transform(new ConcatAll());
///     stream.listen(print);
///
///     // 3
///     // 4
///     // 1
///     // 2
class ConcatAll<T extends Stream<R>, R> implements StreamTransformer<T, R> {
  ConcatAll();

  Stream<R> bind(Stream<T> stream) {
    return stream.asyncExpand((stream) => stream);
  }
}