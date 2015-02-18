library concat_test;

import 'dart:async';
import 'package:guinness/guinness.dart';
import 'package:stream_transformers/stream_transformers.dart';
import 'util.dart';

void main() => describe("Concat", () {
  describe("with a single subscription stream", () {
    testWithStreamController(() => new StreamController());
  });

  describe("with a broadcast stream", () {
    testWithStreamController(() => new StreamController.broadcast());
  });
});

void testWithStreamController(StreamController providerA()) {
  StreamController controllerA;
  StreamController controllerB;

  beforeEach(() {
    controllerA = providerA();
    controllerB = new StreamController();
  });

  afterEach(() {
    controllerA.close();
    controllerB.close();
  });

  it("doesn't forward events until previous events are done", () {
    return testStream(controllerA.stream.transform(new Concat(controllerB.stream)),
        behavior: () {
          controllerB..add(2)..add(3);
          controllerA..add(1)..close();
        },
        expectation: (values) => expect(values).toEqual([1, 2, 3]));
  });

  it("returned stream closes when both streams are done", () {
    var completer = new Completer();
    var stream = controllerA.stream.transform(new Concat(controllerB.stream));
    stream.listen(null, onDone: completer.complete);

    controllerA.close();
    controllerB.close();

    return completer.future;
  });

  it("cancels input streams when source streams are closed", () {
    var completerA = new Completer();
    var completerB = new Completer();
    var controllerA = new StreamController(onCancel: completerA.complete);
    var controllerB = new StreamController(onCancel: completerB.complete);

    return testStream(
        controllerA.stream.transform(new Concat(controllerB.stream)),
        behavior: () {
          controllerA.close();
          controllerB.close();
        },
        expectation: (_) => Future.wait([completerA.future, completerB.future]));
  });

  it("cancels active streams when source stream is cancelled", () {
    var completer = new Completer();
    var controller = new StreamController(onCancel: completer.complete);

    return testStream(
        controller.stream.transform(new Concat(controllerB.stream)),
        expectation: (_) => completer.future);
  });

  it("forwards errors from active stream", () {
    return testErrorsAreForwarded(
        controllerA.stream.transform(new Concat(controllerB.stream)),
        behavior: () {
          controllerA.addError(1);
          controllerB.addError(2);
        },
        expectation: (errors) => expect(errors).toEqual([1, 2]));
  });

  it("returns a stream of the same type", () {
    var stream = controllerA.stream.transform(new Concat(controllerB.stream));
    expect(stream.isBroadcast).toBe(controllerA.stream.isBroadcast);
  });
}