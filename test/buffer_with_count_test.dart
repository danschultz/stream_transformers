library buffer_with_count_test;

import 'dart:async';
import 'package:guinness/guinness.dart';
import 'package:stream_transformers/stream_transformers.dart';
import 'util.dart';

void main() => describe("BufferWithCount", () {
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

  it("buffers 2", () {
    return testStream(controller.stream.transform(new BufferWithCount(2)),
        behavior: () {
          controller.add(1);
          controller.add(2);
          controller.add(3);
          controller.add(4);
          controller.close();
        },
        expectation: (values) => expect(values).toEqual([[1, 2], [3, 4]]));
  });
  
  it("buffers 2, 1", () {
    return testStream(controller.stream.transform(new BufferWithCount(2, 1)),
        behavior: () {
          controller.add(1);
          controller.add(2);
          controller.add(3);
          controller.add(4);
          controller.close();
        },
        expectation: (values) => expect(values).toEqual([[1, 2], [2, 3], [3, 4], [4]]));
  });
  
  it("buffers 3, 2", () {
    return testStream(controller.stream.transform(new BufferWithCount(3, 2)),
        behavior: () {
          controller.add(1);
          controller.add(2);
          controller.add(3);
          controller.add(4);
          controller.add(5);
          controller.add(6);
          controller.close();
        },
        expectation: (values) => expect(values).toEqual([[1, 2, 3], [3, 4, 5], [5, 6]]));
  });
  
  it("closes transformed stream when source stream is done", () {
    var stream = controller.stream.transform(new BufferWithCount(2));
    controller..close();
    return stream.toList().then((values) => expect(values).toEqual([]));
  });

  it("cancels source listener when transformed stream is cancelled", () {
    var complete = new Completer();
    var controller = new StreamController(onCancel: complete.complete);

    return testStream(
        controller.stream.transform(new BufferWithCount(2)),
        expectation: (_) => complete.future);
  });

  it("forwards errors from either source stream", () {
    return testErrorsAreForwarded(
        controller.stream.transform(new BufferWithCount(2)),
        behavior: () {
          controller..addError(1)..close();
        },
        expectation: (errors) => expect(errors).toEqual([1]));
  });

  it("returns a stream of the same type", () {
    var stream = controller.stream.transform(new BufferWithCount(2));
    expect(stream.isBroadcast).toBe(controller.stream.isBroadcast);
  });
}