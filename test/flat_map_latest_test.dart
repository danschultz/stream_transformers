library flat_map_latest_test;

import 'dart:async';
import 'package:guinness/guinness.dart';
import 'package:stream_transformers/stream_transformers.dart';
import 'util.dart';

void main() => describe("FlatMapLatest", () {
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

  it("includes events from latest spawned stream", () {
    return testStream(controller.stream.transform(new FlatMapLatest((value) => spawnedControllers[value].stream)),
        behavior: () {
          controller.add(1);
          controller.add(2);
          spawnedControllers[2].add(4);
          return new Future(() => spawnedControllers[1].add(3));
        },
        expectation: (values) => expect(values).toEqual([4]));
  });

  it("doesn't close transformed stream when source stream is done and spawned streams are not done", () {
    return testStream(controller.stream.transform(new FlatMapLatest((value) => spawnedControllers[value].stream)),
        behavior: () {
          controller..add(1)..close();
          return new Future(() => spawnedControllers[1].add(1));
        },
        expectation: (values) => expect(values).toEqual([1]));
  });

  it("closes transformed stream when source stream is done and spawned streams are done", () {
    var spawnedStream = new Stream.periodic(new Duration(milliseconds: 50), (i) => i).take(2);
    var stream = controller.stream.transform(new FlatMapLatest((value) => spawnedStream));
    var result = stream.toList();

    controller..add(1)..close();

    return result.then((values) => expect(values).toEqual([0, 1]));
  });

  it("cancels transformed and spawned streams when input stream is closed", () {
    var completers = <Completer>[new Completer(), new Completer(), new Completer()];
    var controllers = <StreamController>[
        new StreamController(onCancel: () => completers[0].complete()),
        new StreamController(onCancel: () => completers[1].complete()),
        new StreamController(onCancel: () => completers[2].complete())];

    return testStream(
        controllers[0].stream.transform(new FlatMapLatest((value) => controllers[value].stream)),
        behavior: () => controllers[0]..add(1)..add(2)..close(),
        expectation: (values) => Future.wait(completers.map((completer) => completer.future)));
  });

  it("cancels transformed and spawned streams when transformed stream is cancelled", () {
    var completers = <Completer>[new Completer(), new Completer(), new Completer()];
    var controllers = <StreamController>[
        new StreamController(onCancel: () => completers[0].complete()),
        new StreamController(onCancel: () => completers[1].complete()),
        new StreamController(onCancel: () => completers[2].complete())];

    return testStream(
        controllers[0].stream.transform(new FlatMapLatest((value) => controllers[value].stream)),
        behavior: () => controllers[0]..add(1)..add(2),
        expectation: (values) => Future.wait(completers.map((completer) => completer.future)));
  });

  it("forwards errors from source and spawned stream", () {
    return testErrorsAreForwarded(
        controller.stream.transform(new FlatMapLatest((value) => spawnedControllers[value].stream)),
        behavior: () {
          controller..add(1)..addError(1);
          spawnedControllers[1].addError(2);
        },
        expectation: (errors) => expect(errors).toEqual([1, 2]));
  });

  it("returns a stream of the same type", () {
    var stream = controller.stream.transform(new FlatMapLatest((value) => new Stream.fromIterable([])));
    expect(stream.isBroadcast).toBe(controller.stream.isBroadcast);
  });
}