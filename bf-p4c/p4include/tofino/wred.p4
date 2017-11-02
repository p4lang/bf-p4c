extern wred<T> {
    wred(T lower_bound, T upper_bound, @optional bit<32> instance_count);
    T execute(in T val, @optional in bit<32> index);
}
