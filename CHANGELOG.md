# Changelog

## 0.3.0 (02/30/2015)
- Add `Concat` [[#15](https://github.com/danschultz/stream_transformers/issues/15)]
- Add `ConcatAll` [[#16](https://github.com/danschultz/stream_transformers/issues/16)]
- Add `DoAction` [[#4](https://github.com/danschultz/stream_transformers/issues/4)]
- Add `MergeAll` [[#2](https://github.com/danschultz/stream_transformers/issues/2)]
- Add `SampleOn` [[#1](https://github.com/danschultz/stream_transformers/issues/1)]
- Add `SamplePeriodically` [[#3](https://github.com/danschultz/stream_transformers/issues/3)]
- Add `SelectFirst` [[#13](https://github.com/danschultz/stream_transformers/issues/13)]
- Add `StartWith` [[#14](https://github.com/danschultz/stream_transformers/issues/14)]
- `FlatMap` now closes only when its source is closed.

## 0.2.0 (02/01/2015)
- Changed the behavior of debounce to debounce the first value [[#5](https://github.com/danschultz/stream_transformers/issues/5)]
- Rename `StreamConverter` to `Mapper`, and generalized type signature to `R Mapper<A,R>(A value)` [[#10](https://github.com/danschultz/stream_transformers/issues/10)]
- Make sure errors for transformers are forwarded as documented
- Make sure internal subscriptions are cancelled when the transformed stream subscriptions are cancelled

## 0.1.0+3 (01/25/2015)
- Fixed [issue #6](https://github.com/danschultz/stream_transformers/issues/6) where `Scan` doesn't include the initial value in the transformed stream.

## 0.1.0+1 (01/14/2015)
- Fixed an issue where `When` and `Zip` transformers would not return the same stream type.

## 0.1.0 (01/10/2015)
Initial version

- Add `BufferWhen` transformer
- Add `Combine` transformer
- Add `Debounce` transformer
- Add `Delay` transformer
- Add `FlatMap` transformer
- Add `FlatMapLatest` transformer
- Add `Merge` transformer
- Add `Scan` transformer
- Add `SkipUntil` transformer
- Add `TakeUntil` transformer
- Add `When` transformer
- Add `Zip` transformer
