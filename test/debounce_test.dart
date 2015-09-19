library debounce_test;

import 'dart:async';
import 'package:guinness/guinness.dart';
import 'package:stream_transformers/stream_transformers.dart';
import 'util.dart';

void main() => describe("Debounce", () {
  describe("with single subscription stream", () {
    testWithStreamController(() => new StreamController());
  });

  describe("with broadcast stream", () {
    testWithStreamController(() => new StreamController.broadcast());
  });
});

void testWithStreamController(StreamController provider()) {
  StreamController controller;
  Duration duration;

  beforeEach(() {
    controller = provider();
    duration = new Duration(milliseconds: 50);
  });

  afterEach(() {
    controller.close();
  });

  it("provides the last event after duration passes", () {
    return testStream(controller.stream.transform(new Debounce(duration)),
        behavior: () {
          controller..add(1)..add(2)..add(3);
          return new Future.delayed(duration * 2, () => true);
        },
        expectation: (values) => expect(values).toEqual([3]));
  });

  it("closes transformed stream when source stream is done", () {
    var stream = controller.stream.transform(new Debounce(duration));
    var result = stream.toList();
    controller..add(1)..close();
    return result.then((values) {
      expect(values).toEqual([1]);
    });
  });

  it("cancels input stream when transformed stream is cancelled", () {
    var completerA = new Completer();
    var controller = new StreamController(onCancel: completerA.complete);

    return testStream(
        controller.stream.transform(new Debounce(duration)),
        expectation: (_) => completerA.future);
  });

  it("doesn't debounce errors", () {
    return testErrorsAreForwarded(
        controller.stream.transform(new Debounce(duration)),
        behavior: () {
          controller..addError(1)..addError(2)..addError(3)..close();
        },
        expectation: (errors) => expect(errors).toEqual([1, 2, 3]));
  });

  it("returns a stream of the same type", () {
    var stream = controller.stream.transform(new Debounce(duration));
    expect(stream.isBroadcast).toBe(controller.stream.isBroadcast);
  });
}
