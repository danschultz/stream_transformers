# stream_transformers

[![Build Status](https://travis-ci.org/danschultz/stream_transformers.svg)](https://travis-ci.org/danschultz/stream_transformers)
[![Coverage Status](https://coveralls.io/repos/danschultz/stream_transformers/badge.svg?branch=master)](https://coveralls.io/r/danschultz/stream_transformers?branch=master)

This library provides a set of stream transformers for Dart's `Stream` class.

These transformers are used internally by [Frappe]. If you're looking for a more featured functional reactive programming (FRP) library for Dart, you should look there.

## Transformers

* [BufferWhen](#bufferwhen)
* [Combine](#combine)
* [Concat](#concat)
* [ConcatAll](#concatall)
* [Debounce](#debounce)
* [Delay](#delay)
* [DoAction](#doaction)
* [FlatMap](#flatmap)
* [FlatMapLatest](#flatmaplatest)
* [Merge](#merge)
* [MergeAll](#mergeall)
* [SampleOn](#sampleon)
* [SamplePeriodically](#sampleperiodically)
* [Scan](#scan)
* [SelectFirst](#selectfirst)
* [SkipUntil](#skipuntil)
* [StartWith](#startwith)
* [TakeUntil](#takeuntil)
* [When](#when)
* [Zip](#zip)

### `BufferWhen`
Pauses the delivery of events from the source stream when the signal stream delivers a value of `true`. The buffered events are delivered when the signal delivers a value of `false`. Errors originating from the source and signal streams will be forwarded to the transformed stream and will not be buffered. If the source stream is a broadcast stream, then the transformed stream will also be a broadcast stream.

**Example:**

```dart
var controller = new StreamController();
var signal = new StreamController();

var stream = controller.stream;

var buffered = stream.transform(new BufferWhen(signal.stream));

controller.add(1);
signal.add(true);
controller.add(2);

buffered.listen(print); // Prints: 1
```

### `Combine`
Combines the latest values of two streams using a two argument function. The combining function will not be called until each stream delivers its first value. After the first value of each stream is delivered, the combining function will be invoked for each event from the source streams. Errors occurring on the streams will be forwarded to the transformed stream. If the source stream is a broadcast stream, then the transformed stream will also be a broadcast stream.

**Example:**

```dart
var controller1 = new StreamController();
var controller2 = new StreamController();

var combined = controller1.stream.transform(new Combine(controller2.stream, (a, b) => a + b));

combined.listen(print);

controller1.add(1);
controller2.add(1); // Prints: 2
controller1.add(2); // Prints: 3
controller2.add(2); // Prints: 4
```

Use the static function `Combine.all(List<Stream>)` to combine a list of streams together. The returned stream will contain a `List` that contains the current values of each of the streams.

**Example:**

```dart
var controller1 = new StreamController();
var controller2 = new StreamController();

var combined = Combine.all([controller1.stream, controller2.stream]);

combined.listen(print);

controller1.add(1);
controller2.add(2); // Prints: [1, 2]
controller1.add(3); // Prints: [3, 2]
controller2.add(4); // Prints: [3, 4]
```

### `Concat`
Concatenates two streams into one stream by delivering the values of the source stream, and then delivering the values of the other stream once the source stream completes. This means that it's possible that events from the second stream might not be included if the source stream hasn't completed. Use `Concat.all()` to concatenate many streams.

Errors will be forwarded from either stream, whether or not the source stream has completed. If the source stream is a broadcast stream, then the transformed stream will also be a broadcast stream.

**Example:**

```dart
var source = new StreamController();
var other = new StreamController();

var stream = source.stream.transform(new Concat(other.stream));
stream.listen(print);

other..add(1)..add(2);
source..add(3)..add(4)..close();

// 3
// 4
// 1
// 2
```

### `ConcatAll`
Concatenates a stream of streams into a single stream, by delivering the first stream's values, and then delivering the next stream's values after the previous stream has completed.

This means that it's possible that events from the second stream might not be included if the source stream hasn't completed. Use `Concat.all()` to concatenate many streams.

Errors will be forwarded from either stream, whether or not the source stream has completed. If the source stream is a broadcast stream, then the transformed stream will also be a broadcast stream.

**Example:**

```dart
var source = new StreamController();
var other1 = new StreamController();
var other2 = new StreamController();

source..add(other1.stream)..add(other2.stream);

other2..add(1)..add(2);
other1..add(3)..add(4)..close();

var stream = source.stream.transform(new ConcatAll());
stream.listen(print);

// 3
// 4
// 1
// 2
```

### `Debounce`
Delivers the last event in the stream after the duration has passed without receiving an event.

Errors occurring on the source stream will not be ignored. If the source stream is a broadcast stream, then the transformed stream will also be a broadcast stream.

```
source:             asdf----asdf----
source.debounce(2): -----f-------f--
```

**Example:**

```dart
var controller = new StreamController();

var debounced = controller.stream.transform(new Debounce(new Duration(seconds:1)));
debounced.listen(print);

controller.add(1);
controller.add(2);
controller.add(3);

// Prints: 3
```

### `Delay`
Throttles the delivery of each event by a given duration. Errors occurring on the source stream will not be delayed. If the source stream is a broadcast stream, then the transformed stream will also be a broadcast stream.

**Example:**

```dart
var controller = new StreamController();
var delayed = controller.stream.transform(new Delay(new Duration(seconds: 2)));

// source:              asdf----
// source.delayed(2):   --a--s--d--f---
```

### `DoAction`
Invokes a side-effect function for each value, error and done event in the stream.

This is useful for debugging, but also invoking `preventDefault` for browser events. Side effects will only be invoked once if the transformed stream has multiple subscribers.

Errors occurring on the source stream will be forwarded to the returned stream, even when passing an error handler to `DoAction`. If the source stream is a broadcast stream, then the transformed stream will also be a broadcast stream.

**Example:**

```dart
var controller = new StreamController();
var sideEffect = new DoAction((value) => print("Do Next: $value"),
    onError: (error) => print("Do Error: $error"),
    onDone: () => print("Do Done"));
var stream = controller.stream.transform(sideEffect);

stream.listen((value) => print("Next: $value"),
    onError: (e) => print("Error: $e"),
    onDone: () => print("Done"));

controller..add(1)..add(2)..close();

// Do Next: 1
// Next: 1
// Do Next: 2
// Next: 2
// Do Done
// Done
```

### `FlatMap`
Spawns a new stream from a function for each event in the source stream. The returned stream will contain the events and errors from each of the spawned streams until they're closed. If the source stream is a broadcast stream, then the transformed stream will also be a broadcast stream.

**Example:**

```dart
var controller = new StreamController();
var flapMapped = controller.stream.transform(new FlatMap((value) => new Stream.fromIterable([value + 1]));

flatMapped.listen(print);

controller.add(1); // Prints: 2
controller.add(2); // Prints: 3
```

### `FlatMapLatest`
Similar to `FlatMap`, but instead of including events from all spawned streams, only includes the ones from the latest stream. Think of this as stream switching.

**Example:**

```dart
var controller = new StreamController();
var latest = controller.stream.transform(new FlatMapLatest((value) => new Stream.fromIterable([value + 1]));

latest.listen(print);

controller.add(1);
controller.add(2); // Prints: 3
```

### `Merge`
Combines the events from two streams into a single stream. Errors occurring on a source stream will be forwarded to the transformed stream. If the source stream is a broadcast stream, then the transformed stream will also be a broadcast stream.

**Example:**

```dart
var controller1 = new StreamController();
var controller2 = new StreamController();

var merged = controller1.stream.transform(new Merge(controller2.stream));

merged.listen(print);

controller1.add(1); // Prints: 1
controller2.add(2); // Prints: 2
controller1.add(3); // Prints: 3
controller2.add(4); // Prints: 4
```

Use the static function `Merge.all(List<Stream>)` to merge all streams of a list into a single stream.

### `MergeAll`
Combines the events from a stream of streams into a single stream.

The returned stream will contain the errors occurring on any stream. If the source stream is a broadcast stream, then the transformed stream will also be a broadcast stream.

**Example:**

```dart
var source = new StreamController();
var stream1 = new Stream.fromIterable([1, 2]);
var stream2 = new Stream.fromIterable([3, 4]);

var merged = source.stream.transform(new MergeAll());
source..add(stream1)..add(stream2);

merged.listen(print);

// 1
// 2
// 3
// 4
```

### `SampleOn`
Takes the latest value of the source stream whenever the trigger stream produces an event.

Errors that happen on the source stream will be forwarded to the transformed stream. If the source stream is a broadcast stream, then the transformed stream will also be a broadcast stream.

**Example:**

```dart
// values start at 0
var source = new Stream.periodic(new Duration(seconds: 1), (i) => i);
var trigger = new Stream.periodic(new Duration(seconds: 2), (i) => i);

var stream = source.stream.transform(new SampleOn(trigger.stream)).take(3);

stream.listen(print);

// 0
// 2
// 4
```

### `SamplePeriodically`
Takes the latest value of the source stream at a specified interval.

Errors that happen on the source stream will be forwarded to the transformed stream. If the source stream is a broadcast stream, then the transformed stream will also be a broadcast stream.

**Example:**

```dart
// values start at 0
var source = new Stream.periodic(new Duration(seconds: 1), (i) => i);
var stream = source.stream.transform(new SamplePeriodically(new Duration(seconds: 2)).take(3);

stream.listen(print);

// 0
// 2
// 4
```

### `Scan`
Reduces the values of a stream into a single value by using an initial value and an accumulator function. The function is passed the previous accumulated value and the current value of the stream. This is useful for maintaining state using a stream. Errors occurring on the source stream will be forwarded to the transformed stream. If the source stream is a broadcast stream, then the transformed stream will also be a broadcast stream.

**Example:**

```dart
var button = new ButtonElement();

var clickCount = button.onClick.transform(new Scan(0, (previous, current) => previous + 1));

clickCount.listen(print);

// [button click] .. prints: 1
// [button click] .. prints: 2
```

### `SelectFirst`
Forwards events from the first stream to deliver an event.

Errors are forwarded from both streams until a stream is selected. Once a stream is selected, only errors from the selected stream are forwarded. If the source stream is a broadcast stream, then the transformed stream will also be a broadcast stream.

**Example:**

```dart
var stream1 = new Stream.periodic(new Duration(seconds: 1)).map((_) => "Stream 1");
var stream2 = new Stream.periodic(new Duration(seconds: 2)).map((_) => "Stream 2");

var selected = stream1.transform(new SelectFirst(stream2)).take(1);
selected.listen(print);

// Stream 1
```

### `SkipUntil`
Waits to deliver events from a stream until the signal `Stream` delivers a value. Errors that happen on the source stream will be forwarded once the `Stream` delivers its value. Errors happening on the signal stream will be forwarded immediately. If the source stream is a broadcast stream, then the transformed stream will also be a broadcast stream.

**Example:**

```dart
var signal = new StreamController();
var controller = new StreamController();

var skipStream = controller.stream.transform(new SkipUntil(signal.stream));

skipStream.listen(print);

controller.add(1);
controller.add(2);
signal.add(true);
controller.add(3); // Prints: 3
controller.add(4); // Prints: 4
```

### `StartWith`
Prepends values to the beginning of a stream. Use `StartWith.many` to prepend multiple values.

Errors on the source stream will be forwarded to the transformed stream. If the source stream is a broadcast stream, then the transformed stream will also be a broadcast stream.

**Example:**

```dart
var source = new Stream.fromIterable([2, 3]);
var stream = source.transform(new StartWith(1));
stream.listen(print);

// 1
// 2
// 3
```

### `TakeUntil`
Delivers events from the source stream until the signal `Stream` produces a value. At which point, the transformed stream closes. The returned stream will continue to deliver values if the signal stream closes without a value.

This is useful for automatically cancelling a stream subscription to prevent memory leaks. Errors that happen on the source and signal stream will be forwarded to the transformed stream. If the source stream is a broadcast stream, then the transformed stream will also be a broadcast stream.

**Example:**

```dart
var signal = new StreamController();
var controller = new StreamController();

var takeUntil = controller.stream.transform(new TakeUntil(signal.stream));

takeUntil.listen(print);

controller.add(1); // Prints: 1
controller.add(2); // Prints: 2
signal.add(true);
controller.add(3);
controller.add(4);
```

### `When`
Starts delivering events from the source stream when the signal stream delivers a value of `true`. Events are skipped when the signal stream delivers a value of `false`. Errors from the source or toggle stream will be forwarded to the transformed stream. If the source stream is a broadcast stream, then the transformed stream will also be a broadcast stream.

**Example:**

```dart
var controller = new StreamController();
var signal = new StreamController();

var whenStream = controller.stream.transform(new When(signal.stream));

whenStream.listen(print);

controller.add(1);
signal.add(true);
controller.add(2); // Prints: 2
signal.add(false);
controller.add(3);
```

### `Zip`
Combines the events of two streams into one by invoking a combiner function that is invoked when each stream delivers an event at each index. The transformed stream finishes when either source stream finishes. Errors from either stream will be forwarded to the transformed stream. If the source stream is a broadcast stream, then the transformed stream will also be a broadcast stream.

**Example:**

```dart
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
```

## Running Tests
Tests are run using [test_runner].

* Install *test_runner*: `pub global activate test_runner`
* Run *test_runner* inside *stream_transformers*: `pub global run run_tests`

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/frappe-dart/stream_transformers/issues
[Frappe]: https://github.com/danschultz/frappe
[test_runner]: https://pub.dartlang.org/packages/test_runner
