library test_util;

import 'dart:async';

Function doNothing = (_) {};

Future testStream(Stream stream, {behavior(), expectation(List values)}) {
  var results = [];

  var subscription = stream.listen((value) {
    results.add(value);
  });

  return new Future(() {
    if (behavior != null) {
      return behavior();
    }
  })
  .then((_) => new Future(() {
    subscription.cancel();
  }))
  .then((_) => expectation(results));
}

Future testErrorsAreForwarded(Stream stream, {behavior(), expectation(List errors)}) {
  var errors = [];
  return testStream(stream.handleError((e) => errors.add(e)),
      behavior: behavior,
      expectation: (_) => expectation(errors));
}
