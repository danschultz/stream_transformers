part of stream_transformers;

/// Starts delivering events from the source stream when the signal stream
/// delivers a value of `true`. Events are skipped when the signal stream
/// delivers a value of `false`. Errors from the source or toggle stream will be
/// forwarded to the transformed stream. If the source stream is a broadcast
/// stream, then the transformed stream will also be a broadcast stream.
///
/// **Example:**
///
///     var controller = new StreamController();
///     var signal = new StreamController();
///
///     var whenStream = controller.stream.transform(new When(signal.stream));
///
///     whenStream.listen(print);
///
///     controller.add(1);
///     signal.add(true);
///     controller.add(2); // Prints: 2
///     signal.add(false);
///     controller.add(3);
class When<T> implements StreamTransformer<T, T> {
  final Stream<bool> _toggle;

  When(Stream<bool> toggle) : _toggle = toggle;

  Stream<T> bind(Stream<T> stream) {
    var input = stream.asBroadcastStream(onCancel: (subscription) => subscription.cancel());

    return _bindStream(like: stream, onListen: (EventSink<T> sink) {
      return _toggle
          .transform(new FlatMapLatest<bool, T>((isToggled) {
            if (isToggled) {
              return _bindStream(onListen: (EventSink<T> sink) {
                return input.listen(sink.add, onError: sink.addError, onDone: sink.close);
              });
            } else {
              return new Stream.fromIterable([]);
            }
          }))
          .transform(new TakeUntil(new _EventStream(input).where((event) => event.isEnd)))
          .listen((value) => sink.add(value), onError: sink.addError);
    });
  }
}