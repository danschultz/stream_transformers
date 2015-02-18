library concat_all_test;

import 'dart:async';
import 'package:guinness/guinness.dart';
import 'package:stream_transformers/stream_transformers.dart';
import 'util.dart';

void main() => describe("ConcatAll", () {
  describe("with a single subscription stream", () {
    testWithStreamController(() => new StreamController());
  });

  describe("with a broadcast stream", () {
    testWithStreamController(() => new StreamController.broadcast());
  });
});

void testWithStreamController(StreamController providerA()) {
  StreamController controller;

  beforeEach(() {
    controller = providerA();
  });

  afterEach(() {
    controller.close();
  });

  it("doesn't forward events until previous events are done", () {
    return testStream(controller.stream.transform(new ConcatAll()),
        behavior: () {
          var controller1 = new StreamController();
          var controller2 = new StreamController();

          controller2..add(3)..add(4);
          controller1..add(1)..add(2)..close();

          controller..add(controller1.stream)..add(controller2.stream);
        },
        expectation: (values) => expect(values).toEqual([1, 2, 3, 4]));
  });

  it("returns a stream of the same type", () {
    var stream = controller.stream.transform(new ConcatAll());
    expect(stream.isBroadcast).toBe(controller.stream.isBroadcast);
  });
}