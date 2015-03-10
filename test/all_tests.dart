library all_tests;

import 'buffer_when_test.dart' as buffer_when;
import 'combine_test.dart' as combine;
import 'concat_test.dart' as concat;
import 'concat_all_test.dart' as concat_all;

void main() {
  buffer_when.main();
  combine.main();
  concat.main();
  concat_all.main();
}