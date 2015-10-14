library all_tests;

import 'buffer_when_test.dart' as buffer_when;
import 'buffer_with_count_test.dart' as buffer_with_count;
import 'combine_test.dart' as combine;
import 'concat_test.dart' as concat;
import 'concat_all_test.dart' as concat_all;
import 'debounce_test.dart' as debounce_all;
import 'do_action_test.dart' as do_action;
import 'flat_map_test.dart' as flat_map;
import 'flat_map_latest_test.dart' as flat_map_latest;
import 'merge_all_test.dart' as merge_all;
import 'merge_test.dart' as merge;
import 'sample_on_test.dart' as sample_on;
import 'sample_periodically_test.dart' as sample_periodically;
import 'scan_test.dart' as scan;
import 'select_first_test.dart' as select_first;
import 'skip_until_test.dart' as skip_until;
import 'start_with_test.dart' as start_with;
import 'take_until_test.dart' as take_until;
import 'when_test.dart' as when;
import 'zip_test.dart' as zip;

void main() {
  buffer_when.main();
  buffer_with_count.main();
  combine.main();
  concat.main();
  concat_all.main();
  debounce_all.main();
  do_action.main();
  flat_map.main();
  flat_map_latest.main();
  merge.main();
  merge_all.main();
  sample_on.main();
  sample_periodically.main();
  scan.main();
  select_first.main();
  skip_until.main();
  start_with.main();
  take_until.main();
  when.main();
  zip.main();
}