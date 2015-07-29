part of stream_transformers;

/// Spawns a new stream from a function for each event in the source stream.
/// The returned stream will contain the events and errors from each of the
/// spawned streams until they're closed. If the source stream is a broadcast
/// stream, then the transformed stream will also be a broadcast stream.
///
/// **Example:**
///
///     var controller = new StreamController();
///     var flapMapped = controller.stream.transform(new FlatMap((value) => new Stream.fromIterable([value + 1]));
///
///     flatMapped.listen(print);
///
///     controller.add(1); // Prints: 2
///     controller.add(2); // Prints: 3
class FlatMap<S, T> implements StreamTransformer<S, T> {
  final Mapper<S, Stream<T>> _convert;

  FlatMap(Mapper<S, Stream<T>> convert) : _convert = convert;

  Stream<T> bind(Stream<S> stream) {
    var subscriptions = new Queue<StreamSubscription>();

    StreamSubscription onListen(EventSink<T> sink) {
      var openStreams = <Stream>[];
      var isDone = false;

      void closeSinkIfDone() {
        if (isDone && openStreams.isEmpty) {
          sink.close();
        }
      }

      void onData(data) {
        Stream<T> mappedStream = _convert(data);
        openStreams.add(mappedStream);
        subscriptions.add(mappedStream.listen(
            (event) => sink.add(event),
            onError: sink.addError,
            onDone: () {
              openStreams.remove(mappedStream);
              closeSinkIfDone();
            }));
      }

      return stream.listen(
          onData,
          onDone: () {
            isDone = true;
            closeSinkIfDone();
          },
          onError: (error, stackTrace) => sink.addError(error, stackTrace));
    };

    void onCancel() {
      while (subscriptions.isNotEmpty) {
        subscriptions.removeFirst().cancel();
      }
    }

    return _bindStream(like: stream, sync: true, onListen: onListen, onCancel: onCancel);
  }
}