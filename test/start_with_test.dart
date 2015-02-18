library start_with_test;

import 'dart:async';
import 'package:guinness/guinness.dart';
import 'package:unittest/unittest.dart' show expectAsync;
import 'package:stream_transformers/stream_transformers.dart';
import 'util.dart';

void main() => describe("StartWith", () {
  describe("with single subscription stream", () {
    testWithStreamController(() => new StreamController());
  });

  describe("with broadcast stream", () {
    testWithStreamController(() => new StreamController.broadcast());
  });

  it("prepends when source is a Stream.fromIterable()", () {
    var source = new Stream.fromIterable([2, 3]);
    return source.transform(new StartWith(1)).toList().then((values) => expect(values).toEqual([1, 2, 3]));
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

  it("prepends values to the stream", () {
    return testStream(controller.stream.transform(new StartWith(1)),
    behavior: () {
      controller..add(2)..add(3);
    },
    expectation: (values) => expect(values).toEqual([1, 2, 3]));
  });

  it("prepends many values to the stream", () {
    return testStream(controller.stream.transform(new StartWith.many([1, 2])),
    behavior: () {
      controller..add(3)..add(4);
    },
    expectation: (values) => expect(values).toEqual([1, 2, 3, 4]));
  });

  it("closes transformed stream when source stream is done", () {
    var stream = controller.stream.transform(new StartWith(1));
    var result = stream.toList();
    controller..add(2)..close();
    return result.then((values) {
      expect(values).toEqual([1, 2]);
    });
  });

  it("cancels input stream when transformed stream is cancelled", () {
    var completerA = new Completer();
    var controller = new StreamController(onCancel: completerA.complete);

    return testStream(
        controller.stream.transform(new StartWith(1)),
        expectation: (_) => completerA.future);
  });

  it("forwards errors from the source stream", () {
    return testErrorsAreForwarded(
        controller.stream.transform(new StartWith(1)),
        behavior: () {
          controller.addError(1);
        },
        expectation: (errors) => expect(errors).toEqual([1]));
  });

  it("returns a stream of the same type", () {
    var stream = controller.stream.transform(new StartWith(1));
    expect(stream.isBroadcast).toBe(controller.stream.isBroadcast);
  });
}