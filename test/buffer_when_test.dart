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

  it("returns a stream of the same type", () {
    var stream = controller.stream.transform(new BufferWhen(signal.stream));
    expect(stream.isBroadcast).toBe(controller.stream.isBroadcast);
  });
}