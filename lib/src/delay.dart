part of stream_transformers;

/// Throttles the delivery of each event by a given duration. Errors occurring
/// on the source stream will not be delayed. If the source stream is a broadcast
/// stream, then the transformed stream will also be a broadcast stream.
///
/// **Example:**
///
///     var controller = new StreamController();
///     var delayed = controller.stream.transform(new Delay(new Duration(seconds: 2)));
///
///     // source:              asdf----
///     // source.delayed(2):   --a--s--d--f---
class Delay<T> implements StreamTransformer<T, T> {
  final Duration _duration;

  Delay(Duration duration) : _duration = duration;

  Stream<T> bind(Stream<T> stream) {
    return stream.asyncMap((event) => new Future.delayed(_duration, () => event));
  }
}