library buffer_when_test;

import 'dart:async';
import 'package:guinness/guinness.dart';
import 'package:stream_transformers/stream_transformers.dart';
import 'util.dart';

void main() => describe("BufferWhen", () {
  describe("with single subscription stream", () {
    testWithStreamController(() => new StreamController());
  });

  describe("with broadcast stream", () {
    testWithStreamController(() => new StreamController.broadcast());
  });
});

void testWithStreamController(StreamController provider()) {
  StreamController controller;
  StreamController signal;

  beforeEach(() {
    controller = provider();
    signal = new StreamController();
  });

  afterEach(() {
    controller.close();
    signal.close();
  });

  it("buffers events when signal is true", () {
    return testStream(controller.stream.transform(new BufferWhen(signal.stream)),
        behavior: () {
          controller.add(1);
          signal.add(true);
          controller.add(2);
        },
        expectation: (values) => expect(values).toEqual([1]));
  });

  it("flushes buffered events when signal is false", () {
    return testStream(controller.stream.transform(new BufferWhen(signal.stream)),
        behavior: () {
          controller.add(1);
          signal.add(true);
          controller.add(2);
          signal.add(false);
          controller.add(3);
        },
        expectation: (values) => expect(values).toEqual([1, 2, 3]));
  });

  it("cancels source and signal stream when source stream is closed", () {
    var completerA = new Completer();
    var completerB = new Completer();
    var controller = new StreamController(onCancel: completerA.complete);
    var signal = new StreamController(onCancel: completerB.complete);

    return testStream(
        controller.stream.transform(new BufferWhen(signal.stream)),
        behavior: () => controller.close(),
        expectation: (_) => Future.wait([completerA.future, completerB.future]));
  });

  it("cancels source and signal stream when source stream is cancelled", () {
    var completerA = new Completer();
    var completerB = new Completer();
    var controller = new StreamController(onCancel: completerA.complete);
    var signal = new StreamController(onCancel: completerB.complete);

    return testStream(
        controller.stream.transform(new BufferWhen(signal.stream)),
        expectation: (_) => Future.wait([completerA.future, completerB.future]));
  });

  it("forwards errors from either source stream", () {
    return testErrorsAreForwarded(
        controller.stream.transform(new BufferWhen(signal.stream)),
        behavior: () {
          controller..addError(1)..close();
        },
        expectation: (errors) => expect(errors).toEqual([1]));
  });

  it("returns a stream of the same type", () {
    var stream = controller.stream.transform(new BufferWhen(signal.stream));
    expect(stream.isBroadcast).toBe(controller.stream.isBroadcast);
  });
}