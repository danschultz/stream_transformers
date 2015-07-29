part of stream_transformers;

/// Takes the latest value of the source stream whenever the trigger stream
/// produces an event.
///
/// Errors that happen on the source stream will be forwarded to the transformed
/// stream. If the source stream is a broadcast stream, then the transformed
/// stream will also be a broadcast stream.
///
/// **Example:**
///
///     // values start at 0
///     var source = new Stream.periodic(new Duration(seconds: 1), (i) => i);
///     var trigger = new Stream.periodic(new Duration(seconds: 2), (i) => i);
///
///     var stream = source.stream.transform(new SampleOn(trigger.stream)).take(3);
///
///     stream.listen(print);
///
///     // 0
///     // 2
///     // 4
class SampleOn<T> implements StreamTransformer<T, T> {
  final Stream _trigger;

  SampleOn(Stream trigger) : _trigger = trigger;

  Stream<T> bind(Stream<T> stream) {
    var trigger = _trigger.asBroadcastStream(onCancel: (subscription) => subscription.cancel());
    StreamSubscription triggerSubscription;

    StreamSubscription onListen(EventSink<T> sink) {
      var triggerDone = new StreamController();

      // The trigger always needs to have a subscription when the returned stream is being listened to.
      // This prevents cases where the returned stream will contain data events after the trigger
      // delivers an event.
      triggerSubscription = trigger.listen(null, onDone: () => triggerDone.add(true));

      return stream
          .transform(new FlatMapLatest<T, T>((value) {
            return _bindStream(onListen: (EventSink<T> sink) {
              return trigger.listen((_) => sink.add(value), onError: sink.addError, onDone: sink.close);
            });
          }))
          .transform(new TakeUntil(triggerDone.stream))
          .listen(sink.add, onError: sink.addError, onDone: sink.close);
    }

    return _bindStream(like: stream, onListen: onListen, onCancel: () => triggerSubscription.cancel());
  }
}