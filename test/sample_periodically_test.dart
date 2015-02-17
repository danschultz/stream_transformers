library sample_periodically_test;

import 'dart:async';
import 'package:guinness/guinness.dart';
import 'package:unittest/unittest.dart' show expectAsync;
import 'package:stream_transformers/stream_transformers.dart';
import 'util.dart';

void main() => describe("SamplePeriodically", () {
  describe("with single subscription stream", () {
    testWithStreamController(() => new StreamController());
  });

  describe("with broadcast stream", () {
    testWithStreamController(() => new StreamController.broadcast());
  });

  it("samples the source at a specified interval", () {
    var source = new Stream.periodic(new Duration(milliseconds: 50), (i) => i);
    var stream = source.transform(new SamplePeriodically(new Duration(milliseconds: 100))).take(3);
    return stream.toList().then((values) => expect(values).toEqual([0, 2, 4]));
  });

  it("cancels input streams when transformed stream is cancelled", () {
    var completerA = new Completer();
    var completerB = new Completer();

    var controller = new StreamController(onCancel: completerA.complete);
    var trigger = new StreamController(onCancel: completerB.complete);

    return testStream(
        controller.stream.transform(new SampleOn(trigger.stream)),
        expectation: (_) => Future.wait([completerA.future, completerB.future]));
  });
});

void testWithStreamController(StreamController provider()) {
  StreamController controller;
  StreamController trigger;

  beforeEach(() {
    trigger = new StreamController();
    controller = provider();
  });

  afterEach(() {
    controller.close();
    trigger.close();
  });

  it("returns a stream of the same type", () {
    var stream = controller.stream.transform(new SampleOn(trigger.stream));
    expect(stream.isBroadcast).toBe(controller.stream.isBroadcast);
  });
}