typedef bit<16> Index;
struct Metadata {
    bit<32> timestamp;
    bit<16> nextHop;
}

extern Flowlet<T, N> {
    Flowlet(bit<32> stateSize);
    T threshold();
    T getTimestamp(in Index index);
    void setTimestamp(in Index index, in T value);
    N getNextHop(in Index index);
    void setNextHop(in Index index, in N value);
    abstract void onPacket(in Index index, in T ts, inout N nextHop);
}

