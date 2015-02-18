part of stream_transformers;

/// Prepends values to the beginning of a stream. Use [StartWith.many()] to prepend
/// multiple values.
///
/// Errors on the source stream will be forwarded to the transformed stream. If the
/// source stream is a broadcast stream, then the transformed stream will also be a
/// broadcast stream.
///
/// **Example:**
///
///     var source = new Stream.fromIterable([2, 3]);
///     var stream = source.transform(new StartWith(1));
///     stream.listen(print);
///
///     // 1
///     // 2
///     // 3
class StartWith<T> implements StreamTransformer<T, T> {
  final Stream<T> _beginning;

  StartWith._(Stream<T> beginning) : _beginning = beginning;

  factory StartWith(T value) => new StartWith._(new Stream.fromIterable([value]));

  factory StartWith.many(Iterable<T> values) => new StartWith._(new Stream.fromIterable(values));

  Stream<T> bind(Stream<T> stream) {
    var controller = _createControllerLikeStream(stream: stream);
    controller.addStream(_beginning.transform(new Merge(stream))).then((_) => controller.close());
    return controller.stream;
  }
}