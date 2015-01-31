library take_until_test;

import 'dart:async';
import 'package:guinness/guinness.dart';
import 'package:stream_transformers/stream_transformers.dart';
import 'util.dart';

void main() => describe("TakeUntil", () {
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
  });

  it("includes events until signal", () {
    return testStream(controller.stream.transform(new TakeUntil(signal.stream)),
        behavior: () {
          return new Future(() => controller..add(1)..add(2))
              .then((_) => new Future(() => signal.add(true)))
              .then((_) => controller.add(3));
        },
        expectation: (values) => expect(values).toEqual([1, 2]));
  });

  it("closes transformed stream when source stream is done", () {
    var stream = controller.stream.transform(new TakeUntil(signal.stream));
    var result = stream.toList();
    controller.close();
    return result.then((values) => expect(values).toEqual([]));
  });

  it("cancels signal subscription when transformed stream listener is cancelled", () {
    var completer = new Completer();
    var signal = new StreamController(onCancel: () => completer.complete());

    return testStream(controller.stream.transform(new TakeUntil(signal.stream)),
        expectation: (values) => completer.future);
  });

  it("forwards errors from source and signal stream", () {
    return testErrorsAreForwarded(
        controller.stream.transform(new TakeUntil(signal.stream)),
        behavior: () {
          controller.addError(1);
          signal.addError(2);
        },
        expectation: (errors) => expect(errors).toEqual([1, 2]));
  });

  it("returns a stream of the same type", () {
    var stream = controller.stream.transform(new TakeUntil(signal.stream));
    expect(stream.isBroadcast).toBe(controller.stream.isBroadcast);
  });
}