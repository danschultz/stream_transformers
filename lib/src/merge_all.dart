part of stream_transformers;

/// Combines the events from a stream of streams into a single stream.
///
/// The returned stream will contain the errors occurring on any stream. If the source
/// stream is a broadcast stream, then the transformed stream will also be a broadcast
/// stream.
///
/// **Example:**
///
///     var source = new StreamController();
///     var stream1 = new Stream.fromIterable([1, 2]);
///     var stream2 = new Stream.fromIterable([3, 4]);
///
///     var merged = source.stream.transform(new MergeAll());
///     source..add(stream1)..add(stream2);
///
///     merged.listen(print);
///
///     // 1
///     // 2
///     // 3
///     // 4
class MergeAll<T extends Stream> implements StreamTransformer<T, T> {
  MergeAll();

  Stream<T> bind(Stream<T> stream) {
    return stream.transform(new FlatMap((stream) => stream));
  }
}