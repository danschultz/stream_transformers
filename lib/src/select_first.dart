part of stream_transformers;

/// Forwards events from the first stream to deliver an event.
///
/// Errors are forwarded from both streams until a stream is selected. Once a stream is selected,
/// only errors from the selected stream are forwarded. If the source stream is a broadcast stream,
/// then the transformed stream will also be a broadcast stream.
///
/// **Example:**
///
///     var stream1 = new Stream.periodic(new Duration(seconds: 1)).map((_) => "Stream 1");
///     var stream2 = new Stream.periodic(new Duration(seconds: 2)).map((_) => "Stream 2");
///
///     var selected = stream1.transform(new SelectFirst(stream2)).take(1);
///     selected.listen(print);
///
///     // Stream 1
class SelectFirst implements StreamTransformer {
  final Stream _other;

  SelectFirst(Stream other) : _other = other;

  Stream bind(Stream stream) {
    return _bindStream(like: stream, onListen: (EventSink sink) {
      var input = stream.asBroadcastStream(onCancel: (subscription) => subscription.cancel());
      var other = _other.asBroadcastStream(onCancel: (subscription) => subscription.cancel());

      var a = input.map((value) => {"value": value, "stream": input});
      var b = other.map((value) => {"value": value, "stream": other});

      var selected = a.transform(new Merge(b)).take(1);
      var forwarded = selected.transform(new FlatMap((selected) {
        var firstValue = selected["value"];
        var stream = selected["stream"];
        return new Stream.fromIterable([firstValue]).transform(new Merge(stream));
      }));

      return forwarded.listen(sink.add, onError: sink.addError, onDone: sink.close);
    });
  }
}