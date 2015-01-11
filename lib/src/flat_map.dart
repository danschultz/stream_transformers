part of stream_transformers;

/// Spawns a new stream from a function for each event in the source stream.
/// The returned stream will contain the events and errors from each of the
/// spawned streams until they're closed. If the source stream is a broadcast
/// stream, then the transformed stream will also be a broadcast stream.
///
/// **Example:**
///
///   var controller = new StreamController();
///   var flapMapped = controller.stream.transform(new FlatMap((value) => new Stream.fromIterable([value + 1]));
///
///   flatMapped.listen(print);
///
///   controller.add(1); // Prints: 2
///   controller.add(2); // Prints: 3
class FlatMap<S, T> implements StreamTransformer {
  final StreamConverter<S, T> _convert;

  FlatMap(StreamConverter<S, T> convert) : _convert = convert;

  Stream<T> bind(Stream<S> stream) {
    var subscriptions = new Queue<StreamSubscription>();

    var onListen = (EventSink<T> sink) {
      return stream.listen((data) {
        Stream<T> mappedStream = _convert(data);
        subscriptions.add(mappedStream.listen((event) {
          sink.add(event);
        }, onError: sink.addError));
      });
    };

    var cleanup = () => cancelSubscriptions(subscriptions).then((_) => subscriptions.clear());

    return bindStream(like: stream, onListen: onListen, onDone: () => cleanup(), onCancel: () => cleanup());
  }
}