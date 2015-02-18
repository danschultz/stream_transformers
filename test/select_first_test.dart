library select_first_test;

import 'dart:async';
import 'package:guinness/guinness.dart';
import 'package:stream_transformers/stream_transformers.dart';
import 'util.dart';

void main() => describe("SelectFirst", () {
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

  describe("when selected", () {
    it("delivers events from the first stream to deliver an event", () {
      return testStream(controllerA.stream.transform(new SelectFirst(controllerB.stream)),
          behavior: () {
            controllerB.add(2);
            controllerA.add(1);
          },
          expectation: (values) => expect(values).toEqual([2]));
    });

    it("returned stream closes when selected stream is done", () {
      var completer = new Completer();
      var stream = controllerA.stream.transform(new SelectFirst(controllerB.stream));
      stream.listen(null, onDone: completer.complete);

      controllerA..add(1)..close();

      return completer.future;
    });

    it("cancels input streams when selected streams is closed", () {
      var completer = new Completer();
      var other = new StreamController(onCancel: completer.complete);

      return testStream(
          controllerA.stream.transform(new SelectFirst(other.stream)),
          behavior: () {
            other..add(1)..close();
          },
          expectation: (_) => completer.future);
    });

    it("forwards errors from selected stream", () {
      return testErrorsAreForwarded(
          controllerA.stream.transform(new SelectFirst(controllerB.stream)),
          behavior: () {
            controllerA..add(1)..addError("a");
          },
          expectation: (errors) => expect(errors).toEqual(["a"]));
    });
  });

  describe("when no events", () {
    it("returned stream closes when both streams are done", () {
      var completer = new Completer();
      var stream = controllerA.stream.transform(new SelectFirst(controllerB.stream));
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
          controllerA.stream.transform(new SelectFirst(controllerB.stream)),
          behavior: () {
            controllerA.close();
            controllerB.close();
          },
          expectation: (_) => Future.wait([completerA.future, completerB.future]));
    });

    it("cancels input streams when source stream is cancelled", () {
      var completerA = new Completer();
      var completerB = new Completer();
      var controllerA = new StreamController(onCancel: completerA.complete);
      var controllerB = new StreamController(onCancel: completerB.complete);

      return testStream(
          controllerA.stream.transform(new SelectFirst(controllerB.stream)),
          expectation: (_) => Future.wait([completerA.future, completerB.future]));
    });

    it("forwards errors from either source stream", () {
      return testErrorsAreForwarded(
          controllerA.stream.transform(new SelectFirst(controllerB.stream)),
          behavior: () {
            controllerA.addError(1);
            controllerB.addError(2);
          },
          expectation: (errors) => expect(errors).toEqual([1, 2]));
    });
  });

  it("returns a stream of the same type", () {
    var stream = controllerA.stream.transform(new SelectFirst(controllerB.stream));
    expect(stream.isBroadcast).toBe(controllerA.stream.isBroadcast);
  });
}