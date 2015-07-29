part of stream_transformers;

/// Combines the events of two streams into one by invoking a combiner function
/// that is invoked when each stream delivers an event at each index. The
/// transformed stream finishes when either source stream finishes. Errors from
/// either stream will be forwarded to the transformed stream. If the source
/// stream is a broadcast stream, then the transformed stream will also be a
/// broadcast stream.
///
/// **Example:**
///
///     var controller1 = new StreamController();
///     var controller2 = new StreamController();
///
///     var zipped = controller1.stream.transform(new Zip(controller2.stream, (a, b) => a + b));
///
///     zipped.listen(print);
///
///     controller1.add(1);
///     controller1.add(2);
///     controller2.add(1); // Prints 2
///     controller1.add(3);
///     controller2.add(2); // Prints 4
///     controller2.add(3); // Prints 6
class Zip<A, B, R> implements StreamTransformer<A, R> {
  final Stream<B> _other;
  final Combiner<A, B, R> _combiner;

  Zip(Stream<B> other, Combiner<A, B, R> combiner) :
    _other = other,
    _combiner = combiner;

  Stream<R> bind(Stream<A> stream) {
    Queue appendToQueue(Queue queue, element) => queue..add(element);

    var input = stream.asBroadcastStream(onCancel: (subscription) => subscription.cancel());
    var other = _other.asBroadcastStream(onCancel: (subscription) => subscription.cancel());

    var bufferA = input.transform(new Scan<A, dynamic>(new Queue<A>(), appendToQueue));
    var bufferB = other.transform(new Scan<B, dynamic>(new Queue<B>(), appendToQueue));

    var combined = Combine.all([bufferA, bufferB]) as Stream<List<Queue>>;

    var done = Merge.all([
        new _EventStream(input).where((event) => event.isEnd),
        new _EventStream(other).where((event) => event.isEnd)])
            .handleError((e) => e)
            .take(1);

    return _bindStream(like: stream, onListen: (EventSink<R> sink) {
      return combined
          .where((queues) => queues.first.isNotEmpty && queues.last.isNotEmpty)
          .map((queues) => _combiner(queues.first.removeFirst(), queues.last.removeFirst()))
          .transform(new TakeUntil(done))
          .listen((value) => sink.add(value), onError: sink.addError, onDone: () => sink.close());
    });
  }
}