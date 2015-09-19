#!/bin/bash

# Fast fail the script on failures.
set -e

# Verify that the libraries are error free.
dartanalyzer --fatal-warnings \
  lib/stream_transformers.dart \
  test/all_tests.dart

# Run the tests.
dart -c test/all_tests.dart
