part of stream_transformers;

typedef R Combiner<A, B, R>(A a, B b);
typedef T Mapper<S, T>(S value);