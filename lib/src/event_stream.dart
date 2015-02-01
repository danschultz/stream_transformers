part of stream_transformers;

/// A stream that normalizes *next* and *end* events into a single event stream,
/// making it easier for instance to know when a stream has finished.
///
/// Keeping this private for now, but might make it public in the future.
class _EventStream<T> extends StreamView<_Event<T>> {
  _EventStream(Stream stream) : super(_bindStream(onListen: (EventSink sink) {
    return stream.listen(
        (data) => sink.add(new _Event.next(data)),
        onError: sink.addError,
        onDone: () => sink..add(new _Event.end())..close());
  }));
}

class _Event<T> {
  final _EventType type;
  final T value;

  bool get hasValue => type == isNext;

  bool get isNext => type == _EventType.NEXT;
  bool get isEnd => type == _EventType.END;

  _Event(this.type, this.value);

  factory _Event.next(T value) => new _Event(_EventType.NEXT, value);

  factory _Event.end() => new _Event(_EventType.END, null);
}

class _EventType {
  static const NEXT = const _EventType("next");
  static const END = const _EventType("end");

  final String value;

  const _EventType(this.value);
}
