library do_action_test;

import 'dart:async';
import 'package:guinness/guinness.dart';
import 'package:stream_transformers/stream_transformers.dart';
import 'util.dart';

void main() => describe("DoAction", () {
  describe("with single subscription stream", () {
    testWithStreamController(() => new StreamController());
  });

  describe("with broadcast stream", () {
    testWithStreamController(() => new StreamController.broadcast());
  });
});

void testWithStreamController(StreamController provider()) {
  StreamController controller;

  beforeEach(() {
    controller = provider();
  });

  afterEach(() {
    controller.close();
  });

  it("invokes onData with values from the source stream", () {
    var actionValues = [];
    return testStream(controller.stream.transform(new DoAction(actionValues.add)),
        behavior: () => controller.add(1),
        expectation: (values) {
          expect(actionValues).toEqual([1]);
          expect(values).toEqual([1]);
        });
  });

  it("invokes handlers once with multiple subscribers", () {
    var actionValues = [];
    var stream = controller.stream.transform(new DoAction(actionValues.add)).asBroadcastStream();
    var values1 = stream.toList();
    var values2 = stream.toList();
    controller..add(1)..close();
    return Future.wait([values1, values2]).then((values) {
      expect(values).toEqual([[1], [1]]);
      expect(actionValues).toEqual([1]);
    });
  });

  it("invokes onError with errors from the source stream", () {
    var errors = [];
    return testStream(controller.stream.transform(new DoAction(null, onError: errors.add)).handleError((e) => e),
        behavior: () => controller..addError("a")..add(1),
        expectation: (values) {
          expect(errors).toEqual(["a"]);
          expect(values).toEqual([1]);
        });
  });

  it("invokes onDone when source stream is done", () {
    var completer = new Completer();
    return testStream(controller.stream.transform(new DoAction(null, onDone: completer.complete)),
        behavior: () => controller..close(),
        expectation: (values) => completer.future);
  });

  it("closes transformed stream when source stream is done", () {
    var stream = controller.stream.transform(new DoAction(null));
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
        controller.stream.transform(new DoAction(null)),
        expectation: (_) => completerA.future);
  });

  it("returns a stream of the same type", () {
    var stream = controller.stream.transform(new DoAction(null));
    expect(stream.isBroadcast).toBe(controller.stream.isBroadcast);
  });
}
