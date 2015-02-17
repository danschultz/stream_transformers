part of stream_transformers;

/// Takes the latest value of the source stream at a specified interval.
///
/// Errors that happen on the source stream will be forwarded to the transformed
/// stream. If the source stream is a broadcast stream, then the transformed
/// stream will also be a broadcast stream.
///
/// **Example:**
///
///     // values start at 0
///     var source = new Stream.periodic(new Duration(seconds: 1), (i) => i);
///     var stream = source.stream.transform(new SamplePeriodically(new Duration(seconds: 2))).take(3);
///
///     stream.listen(print);
///
///     // 0
///     // 2
///     // 4
class SamplePeriodically<T> implements StreamTransformer<T, T> {
  final Duration _duration;

  SamplePeriodically(Duration duration) : _duration = duration;

  Stream<T> bind(Stream<T> stream) {
    return stream.transform(new SampleOn(new Stream.periodic(_duration)));
  }
}