# stream_transformers

This library provides a set of stream transformers for Dart's `Stream` class.

These transformers are used internally by [Frappe]. If you're looking for a more featured functional reactive programming (FRP) library for Dart, you should look there.

## Transformers

* [BufferWhen](#bufferwhen)
* [Combine](#combine)
* [Debounce](#debounce)
* [Delay](#delay)
* [FlatMap](#flatmap)
* [FlatMapLatest](#flatmaplatest)
* [Merge](#merge)
* [Scan](#scan)
* [SkipUntil](#skipuntil)
* [TakeUntil](#takeuntil)
* [When](#when)
* [Zip](#zip)

### `BufferWhen`
Pauses the delivery of events from the source stream when the signal stream delivers a value of `true`. The buffered events are delivered when the signal delivers a value of `false`. Errors originating from the source stream will not buffered. Errors originating from the signal stream are unhandled. If the source stream is a broadcast stream, then the transformed stream will also be a broadcast stream.

**Example:**

    var controller = new StreamController();
    var signal = new StreamController();

    var stream = controller.stream;

    var buffered = stream.transform(new BufferWhen(signal.stream));

    controller.add(1);
    signal.add(true);
    controller.add(2);

    buffered.listen(print); // Prints: 1

### `Combine`
Combines the latest values of two streams using a two argument function. The combining function will not be called until each stream delivers its first value. After the first value of each stream is delivered, the combining function will be invoked for each event from the source streams. Errors occurring on the streams will be forwarded to the transformed stream. If the source stream is a broadcast stream, then the transformed stream will also be a broadcast stream.

**Example:**

    var controller1 = new StreamController();
    var controller2 = new StreamController();

    var combined = controller1.stream.transform(new Combine(controller2.stream, (a, b) => a + b));

    combined.listen(print);

    controller1.add(1);
    controller2.add(1); // Prints: 2
    controller1.add(2); // Prints: 3
    controller2.add(2); // Prints: 4

Use the static function `Combine.all(List<Stream>)` to combine a list of streams together. The returned stream will contain a `List` that contains the current values of each of the streams.

**Example:**

    var controller1 = new StreamController();
    var controller2 = new StreamController();

    var combined = Combine.all([controller1.stream, controller2.stream]);

    combined.listen(print);

    controller1.add(1);
    controller2.add(2); // Prints: [1, 2]
    controller1.add(3); // Prints: [3, 2]
    controller2.add(4); // Prints: [3, 4]

### `Debounce`
Ignores events for a given duration, then delivers the last event in the stream after the duration has passed. Errors occurring on the source stream will not be ignored. If the source stream is a broadcast stream, then the transformed stream will also be a broadcast stream.

**Example:**

    var controller = new StreamController();

    var debounced = controller.stream.transform(new Debounce(new Duration(seconds:1)));
    debounced.listen(print);

    controller.add(1);
    controller.add(2);
    controller.add(3);

    // Prints: 3

### `Delay`
Throttles the delivery of each event by a given duration. Errors occurring on the source stream will not be delayed. If the source stream is a broadcast stream, then the transformed stream will also be a broadcast stream.

**Example:**

    var controller = new StreamController();
    var delayed = controller.stream.transform(new Delay(new Duration(seconds: 2)));

    // source:              asdf----
    // source.delayed(2):   --a--s--d--f---

### `FlatMap`
Spawns a new stream from a function for each event in the source stream. The returned stream will contain the events and errors from each of the spawned streams until they're closed. If the source stream is a broadcast stream, then the transformed stream will also be a broadcast stream.

**Example:**

    var controller = new StreamController();
    var flapMapped = controller.stream.transform(new FlatMap((value) => new Stream.fromIterable([value + 1]));

    flatMapped.listen(print);

    controller.add(1); // Prints: 2
    controller.add(2); // Prints: 3

### `FlatMapLatest`
Similar to `FlatMap`, but instead of including events from all spawned streams, only includes the ones from the latest stream. Think of this as stream switching.

**Example:**

    var controller = new StreamController();
    var latest = controller.stream.transform(new FlatMap((value) => new Stream.fromIterable([value + 1]));

    latest.listen(print);

    controller.add(1);
    controller.add(2); // Prints: 3

### `Merge`
Combines the events from two streams into a single stream. Errors occurring on a source stream will be forwarded to the transformed stream. If the source stream is a broadcast stream, then the transformed stream will also be a broadcast stream.

**Example:**

    var controller1 = new StreamController();
    var controller2 = new StreamController();

    var merged = controller1.stream.transform(new Merge(controller2.stream));

    merged.listen(print);

    controller1.add(1); // Prints: 1
    controller2.add(2); // Prints: 2
    controller1.add(3); // Prints: 3
    controller2.add(4); // Prints: 4

Use the static function `Merge.all(List<Stream>)` to merge all streams of a list into a single stream.

### `Scan`
Reduces the values of a stream into a single value by using an initial value and an accumulator function. The function is passed the previous accumulated value and the current value of the stream. This is useful for maintaining state using a stream. Errors occurring on the source stream will be forwarded to the transformed stream. If the source stream is a broadcast stream, then the transformed stream will also be a broadcast stream.

**Example:**

    var button = new ButtonElement();

    var clickCount = button.onClick.transform(new Scan(0, (previous, current) => previous + 1));

    clickCount.listen(print);

    // [button click] .. prints: 1
    // [button click] .. prints: 2

### `SkipUntil`
Waits to deliver events from a stream until the signal `Future` completes. Errors that happen on the source stream will be forwarded once the `Future` completes. If the source stream is a broadcast stream, then the transformed stream will also be a broadcast stream.

**Example:**

    var completer = new Completer();
    var controller = new StreamController();

    var skipStream = controller.stream.transform(new SkipUntil(completer.future));

    skipStream.listen(print);

    controller.add(1);
    controller.add(2);
    completer.complete();
    controller.add(3); // Prints: 3
    controller.add(4); // Prints: 4

### `TakeUntil`
Delivers events from the source stream until the signal `Future` completes. At which point, the transformed stream closes. This is useful for automatically cancelling a stream subscription to prevent memory leaks. Errors that happen on the source stream will be forwarded to the transformed stream. If the source stream is a broadcast stream, then the transformed stream will also be a broadcast stream.

**Example:**

    var completer = new Completer();
    var controller = new StreamController();

    var takeUntil = controller.stream.transform(new TakeUntil(completer.future));

    takeUntil.listen(print);

    controller.add(1); // Prints: 1
    controller.add(2); // Prints: 2
    completer.complete();
    controller.add(3);
    controller.add(4);

### `When`
Starts delivering events from the source stream when the signal stream delivers a value of `true`. Events are skipped when the signal stream delivers a value of `false`. Errors from the source stream will be forwarded to the transformed stream. If the source stream is a broadcast stream, then the transformed stream will also be a broadcast stream.

**Example:**

    var controller = new StreamController();
    var signal = new StreamController();

    var whenStream = controller.stream.transform(new When(signal.stream));

    whenStream.listen(print);

    controller.add(1);
    signal.add(true);
    controller.add(2); // Prints: 2
    signal.add(false);
    controller.add(3);

### `Zip`
Combines the events of two streams into one by invoking a combiner function that is invoked when each stream delivers an event at each index. The transformed stream finishes when either source stream finishes. Errors from either stream will be forwarded to the transformed stream. If the source stream is a broadcast stream, then the transformed stream will also be a broadcast stream.

**Example:**

    var controller1 = new StreamController();
    var controller2 = new StreamController();

    var zipped = controller1.stream.transform(new Zip(controller2.stream, (a, b) => a + b));

    zipped.listen(print);

    controller1.add(1);
    controller1.add(2);
    controller2.add(1); // Prints 2
    controller1.add(3);
    controller2.add(2); // Prints 4
    controller2.add(3); // Prints 6

## Running Tests
Tests are run using [test_runner].

* Install *test_runner*: `pub global activate test_runner`
* Run *test_runner* inside *stream_transformers*: `pub global run run_tests`

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/frappe-dart/stream_transformers/issues
[Frappe]: https://github.com/danschultz/frappe
[test_runner]: https://pub.dartlang.org/packages/test_runner
