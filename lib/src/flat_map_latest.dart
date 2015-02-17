part of stream_transformers;

/// Similar to `FlatMap`, but instead of including events from all spawned
/// streams, only includes the ones from the latest stream. Think of this
/// as stream switching.
///
/// **Example:**
///
///     var controller = new StreamController();
///     var latest = controller.stream.transform(new FlatMapLatest((value) => new Stream.fromIterable([value + 1]));
///
///     latest.listen(print);
///
///     controller.add(1);
///     controller.add(2); // Prints: 3
class FlatMapLatest<S, T> implements StreamTransformer<S, T> {
  final Mapper<S, Stream<T>> _convert;

  FlatMapLatest(Mapper<S, Stream<T>> convert) : _convert = convert;

  Stream<T> bind(Stream<S> stream) {
    var input = stream.asBroadcastStream(onCancel: (subscription) => subscription.cancel());
    StreamSubscription doneSubscription;

    StreamSubscription onListen(EventSink<T> sink) {
      var done = new StreamController.broadcast();
      doneSubscription = input.listen((value) => done.add(true), onError: (_) {}, onDone: () => done.close());

      return input
          .transform(new FlatMap((value) => _convert(value).transform(new TakeUntil(done.stream))))
          .listen((value) => sink.add(value), onError: sink.addError, onDone: () => sink.close());
    }

    return _bindStream(like: stream, onListen: onListen, onCancel: () => doneSubscription.cancel());
  }
}