extern lpf<T> {
    lpf(@optional bit<32> instance_count);
    T execute(in T val, @optional in bit<32> index);
}
