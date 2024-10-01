extern bool WrapCompare<T>(in T current, in T next, in T threshold);
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

typedef bit<32> Timestamp;
typedef bit<16> NextHop;
control FlowletSwitching(in Index index, inout Metadata metadata) {
    Flowlet<Timestamp, NextHop>(32w1024) flowlet = {
        void onPacket(in Index index, in Timestamp ts, inout NextHop nextHop) {
            Timestamp savedTs = this.getTimestamp(index);
            Timestamp thresh = this.threshold();
            bool less = WrapCompare<bit<32>>(ts, savedTs, thresh);
            if (less) 
                this.setNextHop(index, nextHop);
            else 
                nextHop = this.getNextHop(index);
            this.setTimestamp(index, ts);
        }
    };
    apply {
        flowlet.onPacket(index, metadata.timestamp, metadata.nextHop);
    }
}

