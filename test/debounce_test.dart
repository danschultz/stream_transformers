library debounce_test;

import 'dart:async';
import 'package:guinness/guinness.dart';
import 'package:unittest/unittest.dart' show expectAsync;
import 'package:stream_transformers/stream_transformers.dart';
import 'util.dart';

void main() => describe("Debounce", () {
  describe("with single subscription stream", () {
    testWithStreamController(() => new StreamController());
  });

  describe("with broadcast stream", () {
    testWithStreamController(() => new StreamController.broadcast());
  });
});

void testWithStreamController(StreamController provider()) {
  StreamController controller;
  Duration duration;

  beforeEach(() {
    controller = provider();
    duration = new Duration(milliseconds: 50);
  });

  afterEach(() {
    controller.close();
  });

  it("provides the first and last events after duration passes", () {
    return testStream(controller.stream.transform(new Debounce(duration)),
        behavior: () {
          controller..add(1)..add(2)..add(3);
          return new Future.delayed(new Duration(seconds: 1), () {});
        },
        expectation: (values) => expect(values).toEqual([1, 3]));
  });

  it("closes transformed stream when source stream is done", () {
    var stream = controller.stream.transform(new Debounce(duration));
    var result = stream.toList();
    controller..add(1)..close();
    return result.then((values) {
      expect(values).toEqual([1]);
    });
  });

  it("doesn't debounce errors", () {
    var errors = [];
    var stream = controller.stream.transform(new Debounce(duration));
    var subscription = stream.listen((_) {}, onError: (e) => errors.add(e), onDone: expectAsync(() {
      expect(errors).toEqual([1, 2, 3]);
    }));
    controller..addError(1)..addError(2)..addError(3)..close();
  });

  it("returns a stream of the same type", () {
    var stream = controller.stream.transform(new Debounce(duration));
    expect(stream.isBroadcast).toBe(controller.stream.isBroadcast);
  });
}