part of stream_transformers;

/// Reduces the values of a stream into a single value by using an initial
/// value and an accumulator function. The function is passed the previous
/// accumulated value and the current value of the stream. This is useful
/// for maintaining state using a stream. Errors occurring on the source
/// stream will be forwarded to the transformed stream. If the source stream
/// is a broadcast stream, then the transformed stream will also be a
/// broadcast stream.
///
/// **Example:**
///
///     var button = new ButtonElement();
///
///     var clickCount = button.onClick.transform(new Scan(0, (previous, current) => previous + 1));
///
///     clickCount.listen(print);
///
///     // [button click] .. prints: 1
///     // [button click] .. prints: 2
class Scan<A, R> implements StreamTransformer<A, R> {
  final R _initialValue;
  final Function _combine;

  Scan(R initialValue, R combine(R previous, A current)) :
    _initialValue = initialValue,
    _combine = combine;

  Stream<R> bind(Stream<A> stream) {
    return _bindStream(like: stream, onListen: (EventSink<R> sink) {
      var value = _initialValue;
      sink.add(value);

      void onData(A data) {
        value = _combine(value, data);
        sink.add(value);
      }

      return stream.listen(onData, onError: sink.addError, onDone: sink.close);
    });
  }
}
