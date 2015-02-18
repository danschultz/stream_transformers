library merge_all_test;

import 'dart:async';
import 'package:guinness/guinness.dart';
import 'package:stream_transformers/stream_transformers.dart';
import 'util.dart';

void main() => describe("MergeAll", () {
  describe("with a single subscription stream", () {
    testWithStreamController(() => new StreamController());
  });

  describe("with a broadcast stream", () {
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

  it("forwards events from a stream of a single stream", () {
    return testStream(controller.stream.transform(new MergeAll()),
        behavior: () {
          var controller1 = new StreamController();
          controller.add(controller1.stream);
          controller1..add(1)..add(2);
        },
        expectation: (values) => expect(values).toEqual([1, 2]));
  });

  it("forwards events from a stream of a multiple streams", () {
    return testStream(controller.stream.transform(new MergeAll()),
        behavior: () {
          var controller1 = new StreamController();
          var controller2 = new StreamController();
          controller..add(controller1.stream)..add(controller2.stream);
          controller1..add(1)..add(2);
          controller2..add(3)..add(4);
        },
        expectation: (values) => expect(values).toEqual([1, 2, 3, 4]));
  });

  it("returned stream closes when contained streams are done", () {
    var completer = new Completer();
    var stream = controller.stream.transform(new MergeAll());
    stream.listen(null, onDone: completer.complete);

    var controller1 = new StreamController();
    var controller2 = new StreamController();

    controller..add(controller1.stream)..add(controller2.stream);
    controller1.close();
    controller2.close();

    return completer.future;
  });

  it("cancels contained streams when those streams are closed", () {
    var completerA = new Completer();
    var completerB = new Completer();
    var controllerA = new StreamController(onCancel: completerA.complete);
    var controllerB = new StreamController(onCancel: completerB.complete);

    return testStream(
        controller.stream.transform(new MergeAll()),
        behavior: () {
          controller..add(controllerA.stream)..add(controllerB.stream);
          controllerA.close();
          controllerB.close();
        },
        expectation: (_) => Future.wait([completerA.future, completerB.future]));
  });

  it("cancels contained streams when source stream closes", () {
    var completerA = new Completer();
    var completerB = new Completer();
    var controllerA = new StreamController(onCancel: completerA.complete);
    var controllerB = new StreamController(onCancel: completerB.complete);

    return testStream(
        controller.stream.transform(new MergeAll()),
        behavior: () {
          controller..add(controllerA.stream)..add(controllerB.stream)..close();
        },
        expectation: (_) => Future.wait([completerA.future, completerB.future]));
  });

  it("cancels input streams when source stream is cancelled", () {
    var completerA = new Completer();
    var completerB = new Completer();
    var controllerA = new StreamController(onCancel: completerA.complete);
    var controllerB = new StreamController(onCancel: completerB.complete);

    return testStream(
        controller.stream.transform(new MergeAll()),
        behavior: () {
          controller..add(controllerA.stream)..add(controllerB.stream);
        },
        expectation: (_) => Future.wait([completerA.future, completerB.future]));
  });

  it("forwards errors from source stream", () {
    return testErrorsAreForwarded(
        controller.stream.transform(new MergeAll()),
        behavior: () {
          controller.addError(1);
        },
        expectation: (errors) => expect(errors).toEqual([1]));
  });

  it("forwards errors from contained streams", () {
    var controller1 = new StreamController();
    var controller2 = new StreamController();

    return testErrorsAreForwarded(
        controller.stream.transform(new MergeAll()),
        behavior: () {
          controller..add(controller1.stream)..add(controller2.stream);
          controller1.addError(1);
          controller2.addError(2);
        },
        expectation: (errors) => expect(errors).toEqual([1, 2]));
  });

  it("returns a stream of the same type", () {
    var stream = controller.stream.transform(new MergeAll());
    expect(stream.isBroadcast).toBe(controller.stream.isBroadcast);
  });
}