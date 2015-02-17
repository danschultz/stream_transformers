library sample_on_test;

import 'dart:async';
import 'package:guinness/guinness.dart';
import 'package:unittest/unittest.dart' show expectAsync;
import 'package:stream_transformers/stream_transformers.dart';
import 'util.dart';

void main() => describe("SampleOn", () {
  describe("with single subscription stream", () {
    testWithStreamController(() => new StreamController());
  });

  describe("with broadcast stream", () {
    testWithStreamController(() => new StreamController.broadcast());
  });

  it("works with periodic streams", () {
    var source = new Stream.periodic(new Duration(milliseconds: 50), (i) => i);
    var sampler = new Stream.periodic(new Duration(milliseconds: 100), (i) => i).take(3);

    var stream = source.transform(new SampleOn(sampler));
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

  it("delivers the latest value when sample stream delivers a value", () {
    return testStream(controller.stream.transform(new SampleOn(trigger.stream)),
        behavior: () {
          controller.add(1);
          trigger.add(true);
        },
        expectation: (values) => expect(values).toEqual([1]));
  });

  it("redelivers the latest value when sample stream has a value", () {
    return testStream(controller.stream.transform(new SampleOn(trigger.stream)),
        behavior: () {
          controller.add(1);
          trigger.add(true);
          trigger.add(true);
        },
        expectation: (values) => expect(values).toEqual([1, 1]));
  });

  it("doesn't deliver a value if source stream is empty", () {
    return testStream(controller.stream.transform(new SampleOn(trigger.stream)),
        behavior: () {
          trigger.add(true);
          controller.add(1);
        },
        expectation: (values) => expect(values).toEqual([]));
  });

  it("closes transformed stream when source stream is done", () {
    var stream = controller.stream.transform(new SampleOn(trigger.stream));
    var result = stream.toList();
    controller.close();
    return result.then((values) => expect(values).toEqual([]));
  });

  it("returns a stream of the same type", () {
    var stream = controller.stream.transform(new DoAction(null));
    expect(stream.isBroadcast).toBe(controller.stream.isBroadcast);
  });
}