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
class FlatMap<S, T> implements StreamTransformer {
  final StreamConverter<S, T> _convert;

  FlatMap(StreamConverter<S, T> convert) : _convert = convert;

  Stream<T> bind(Stream<S> stream) {
    var subscriptions = new Queue<StreamSubscription>();

    StreamSubscription onListen(EventSink<T> sink) {
      var openStreams = <Stream>[];

      void closeSinkIfDone(EventSink sink, Iterable<Stream> streams) {
        if (streams.isEmpty) {
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
              closeSinkIfDone(sink, openStreams);
            }));
      }

      return stream.listen(
          onData,
          onDone: () => closeSinkIfDone(sink, openStreams),
          onError: (error, stackTrace) => sink.addError(error, stackTrace));
    };

    void onCancel() {
      while (subscriptions.isNotEmpty) {
        subscriptions.removeFirst().cancel();
      }
    }

    return _bindStream(like: stream, onListen: onListen, onCancel: onCancel);
  }
}