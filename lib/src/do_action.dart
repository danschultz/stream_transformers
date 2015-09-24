part of stream_transformers;

/// Invokes a side-effect function for each value, error and done event in the stream.
///
/// This is useful for debugging, but also invoking `preventDefault` for browser events.
/// Side effects will only be invoked once if the transformed stream has multiple
/// subscribers.
///
/// Errors occurring on the source stream will be forwarded to the returned stream, even
/// when passing an error handler to `DoAction`. If the source stream is a broadcast
/// stream, then the transformed stream will also be a broadcast stream.
///
/// **Example:**
///
///     var controller = new StreamController();
///     var sideEffect = new DoAction((value) => print("Do Next: $value"),
///         onError: (error) => print("Do Error: $error"),
///         onDone: () => print("Do Done"));
///     var stream = controller.stream.transform(sideEffect);
///
///     stream.listen((value) => print("Next: $value"),
///         onError: (e) => print("Error: $e"),
///         onDone: () => print("Done"));
///
///     controller..add(1)..add(2)..close();
///
///     // Do Next: 1
///     // Next: 1
///     // Do Next: 2
///     // Next: 2
///     // Do Done
///     // Done
class DoAction<T> implements StreamTransformer<T, T> {
  final Function _onData;
  final Function _onError;
  final Function _onDone;

  DoAction(void onData(T value), {Function onError, void onDone()}) :
    _onData = onData,
    _onError = onError,
    _onDone = onDone;

  Stream<T> bind(Stream<T> stream) {
    var input = stream.asBroadcastStream(onCancel: (subscription) => subscription.cancel());
    StreamSubscription subscription;
    return _bindStream(like: stream, onListen: (EventSink<T> sink) {
      subscription = input.listen(_onData, onError: _onError, onDone: _onDone);
      return input.listen(sink.add, onError: sink.addError, onDone: sink.close);
    }, onCancel: () => subscription.cancel());
  }
}