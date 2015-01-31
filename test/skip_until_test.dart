library skip_until_test;

import 'dart:async';
import 'package:guinness/guinness.dart';
import 'package:stream_transformers/stream_transformers.dart';
import 'util.dart';

void main() => describe("SkipUntil", () {
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

  it("doesn't include events until signal", () {
    return testStream(controller.stream.transform(new SkipUntil(signal.stream)),
        behavior: () => new Future(() {
          controller.add(1);
          controller.add(2);

          return new Future(() {
            signal.add(true);
            controller.add(3);
          });
        }),
        expectation: (values) => expect(values).toEqual([3]));
  });

  it("closes transformed stream when source stream is done", () {
    return testStream(controller.stream.transform(new SkipUntil(signal.stream)),
        behavior: () => controller.close(),
        expectation: (values) => expect(values).toEqual([]));
  });

  it("returns a stream of the same type", () {
    var stream = controller.stream.transform(new SkipUntil(signal.stream));
    expect(stream.isBroadcast).toBe(controller.stream.isBroadcast);
  });
}