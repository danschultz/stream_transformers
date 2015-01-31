library zip_test;

import 'dart:async';
import 'package:guinness/guinness.dart';
import 'package:stream_transformers/stream_transformers.dart';
import 'util.dart';

void main() => describe("Zip", () {
  describe("with single subscription stream", () {
    testWithStreamController(() => new StreamController());
  });

  describe("with broadcast stream", () {
    testWithStreamController(() => new StreamController.broadcast());
  });
});

void testWithStreamController(StreamController provider()) {
  StreamController controllerA;
  StreamController controllerB;

  beforeEach(() {
    controllerA = provider();
    controllerB = new StreamController();
  });

  afterEach(() {
    controllerA.close();
    controllerB.close();
  });

  it("combine each pair of events", () {
    return testStream(controllerA.stream.transform(new Zip(controllerB.stream, (a, b) => a + b)),
        behavior: () {
          controllerA.add(1);
          controllerB.add(1);

          controllerA.add(2);
          controllerB.add(2);

          controllerA.add(3);
          controllerA.add(4);
          controllerA.add(5);

          controllerB.add(3);
        },
        expectation: (values) => expect(values).toEqual([2, 4, 6]));
  });

  it("returned stream closes when source stream is done", () {
    var stream = controllerA.stream.transform(new Zip(controllerB.stream, (a, b) => a + b));
    controllerA.close();
    return stream.isEmpty;
  });

  it("returned stream closes when other stream is done", () {
    var stream = controllerA.stream.transform(new Zip(controllerB.stream, (a, b) => a + b));
    controllerB.close();
    return stream.isEmpty;
  });

  it("returns a stream of the same type", () {
    var stream = controllerA.stream.transform(new Zip(controllerB.stream, (a, b) => a + b));
    expect(stream.isBroadcast).toBe(controllerA.stream.isBroadcast);
  });
}