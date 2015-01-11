part of frappe.transformers;

/// Ignores events for a given duration, then delivers the last event in
/// the stream after the duration has passed. Errors occurring on the
/// source stream will not be ignored. If the source stream is a broadcast
/// stream, then the transformed stream will also be a broadcast stream.
///
/// **Example:**
///
///   var controller = new StreamController();
///
///   var debounced = controller.stream.transform(new Debounce(new Duration(seconds:1)));
///   debounced.listen(print);
///
///   controller.add(1);
///   controller.add(2);
///   controller.add(3);
///
///   // Prints: 3
class Debounce<T> implements StreamTransformer<T, T> {
  final Duration _duration;

  Debounce(Duration duration) : _duration = duration;

  Stream<T> bind(Stream<T> stream) {
    var isDebouncing = false;
    Timer timer;

    StreamSubscription<T> onListen(EventSink<T> sink) {
      void schedule(T value) {
        if (timer != null) {
          timer.cancel();
        }
        timer = new Timer(_duration, () => sink.add(value));
      }

      return stream.listen((event) {
        if (!isDebouncing) {
          sink.add(event);
        } else {
          schedule(event);
        }
        isDebouncing = true;
      }, onError: sink.addError);
    }

    return _bindStream(like: stream, onListen: onListen);
  }
}