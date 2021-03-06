library when_test;

import 'dart:async';
import 'package:guinness/guinness.dart';
import 'package:stream_transformers/stream_transformers.dart';
import 'util.dart';

void main() => describe("When", () {
  describe("with single subscription stream", () {
    testWithStreamController(() => new StreamController());
  });

  describe("with broadcast stream", () {
    testWithStreamController(() => new StreamController.broadcast());
  });
});

void testWithStreamController(StreamController provider()) {
  StreamController controller;
  StreamController toggle;

  beforeEach(() {
    controller = provider();
    toggle = new StreamController();
  });

  afterEach(() {
    controller.close();
  });

  it("includes events when signal is true", () {
    return testStream(controller.stream.transform(new When(toggle.stream)),
        behavior: () => new Future(() {
          controller.add(1);
          toggle.add(true);
          controller.add(2);
        }),
        expectation: (values) => expect(values).toEqual([2]));
  });

  it("excludes events when signal is false", () {
    return testStream(controller.stream.transform(new When(toggle.stream)),
        behavior: () => new Future(() {
          controller.add(1);
          toggle.add(true);
          controller.add(2);
          toggle.add(false);
          controller.add(3);
        }),
        expectation: (values) => expect(values).toEqual([2]));
  });

  it("doesn't close when signal stream closes", () {
    return testStream(controller.stream.transform(new When(toggle.stream)),
        behavior: () => new Future(() {
          controller.add(1);
          toggle..add(true)..close();
          return new Future(() => controller.add(2));
        }),
        expectation: (values) => expect(values).toEqual([2]));
  });

  it("cancels source and signal subscription when transformed stream listener is cancelled", () {
    var completers = <Completer>[new Completer(), new Completer()];
    var controller = new StreamController(onCancel: () => completers[0].complete());
    var toggle = new StreamController(onCancel: () => completers[1].complete());

    return testStream(
        controller.stream.transform(new When(toggle.stream)),
        expectation: (values) => Future.wait(completers.map((completer) => completer.future)));
  });

  it("forwards errors from source and toggle stream", () {
    return testErrorsAreForwarded(
        controller.stream.transform(new When(toggle.stream)),
        behavior: () {
          controller.addError(1);
          toggle.addError(2);
        },
        expectation: (errors) => expect(errors).toEqual([1, 2]));
  });

  it("returns a stream of the same type", () {
    var stream = controller.stream.transform(new When(toggle.stream));
    expect(stream.isBroadcast).toBe(controller.stream.isBroadcast);
  });
}