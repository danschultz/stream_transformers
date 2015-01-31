library flat_map_test;

import 'dart:async';
import 'package:guinness/guinness.dart';
import 'package:stream_transformers/stream_transformers.dart';
import 'util.dart';

void main() => describe("FlatMap", () {
  describe("with single subscription stream", () {
    testWithStreamController(() => new StreamController());
  });

  describe("with broadcast stream", () {
    testWithStreamController(() => new StreamController.broadcast());
  });
});

void testWithStreamController(StreamController provider()) {
  StreamController controller;
  Map<int, StreamController> spawnedControllers;

  beforeEach(() {
    controller = provider();
    spawnedControllers = {
        1: new StreamController(),
        2: new StreamController()
    };
  });

  afterEach(() {
    controller.close();
    spawnedControllers.values.forEach((controller) => controller.close());
  });

  it("includes events from spawned streams", () {
    return testStream(controller.stream.transform(new FlatMap((value) => spawnedControllers[value].stream)),
        behavior: () {
          controller.add(1);
          controller.add(2);
          spawnedControllers[1].add(3);
          spawnedControllers[2].add(4);
        },
        expectation: (values) => expect(values).toEqual([3, 4]));
  });

  it("doesn't close transformed stream when source stream is done and spawned streams are not done", () {
    return testStream(controller.stream.transform(new FlatMap((value) => spawnedControllers[value].stream)),
        behavior: () {
          controller..add(1)..close();
          return new Future(() => spawnedControllers[1].add(1));
        },
        expectation: (values) => expect(values).toEqual([1]));
  });

  it("closes transformed stream if source stream is closed and has no events", () {
    var stream = controller.stream.transform(new FlatMap((value) => new Stream.fromIterable([])));
    var result = stream.toList();

    controller.close();

    return result.then((values) => expect(values).toEqual([]));
  });

  it("closes transformed stream when source stream is done and spawned streams are done", () {
    var spawnedStream = new Stream.periodic(new Duration(milliseconds: 50), (i) => i).take(2);
    var stream = controller.stream.transform(new FlatMap((value) => spawnedStream));
    var result = stream.toList();

    controller..add(1)..close();

    return result.then((values) => expect(values).toEqual([0, 1]));
  });

  it("closes transformed stream once all spawned streams are closed", () {
    var stream = controller.stream.transform(new FlatMap((value) => spawnedControllers[value].stream));
    var result = stream.toList();

    controller..add(1)..add(2);
    spawnedControllers.forEach((key, controller) {
      controller..add(key)..close();
    });

    return result.then((values) => expect(values).toEqual([1, 2]));
  });

  it("cancels subscriptions from spawned streams when transformed stream's listener is cancelled", () {
    var completers = <Completer>[new Completer(), new Completer()];
    var controllers = <StreamController>[
        new StreamController(onCancel: () => completers[0].complete()),
        new StreamController(onCancel: () => completers[1].complete())];

    return testStream(controller.stream.transform(new FlatMap((value) => controllers[value].stream)),
        behavior: () {
          controller..add(0)..add(1)..close();
        },
        expectation: (values) => Future.wait(completers.map((completer) => completer.future)));
  });

  it("returns a stream of the same type", () {
    var stream = controller.stream.transform(new FlatMap((value) => new Stream.fromIterable([])));
    expect(stream.isBroadcast).toBe(controller.stream.isBroadcast);
  });
}
