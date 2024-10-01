/* Sample P4 program fragment using stateful memories for flowlet switching */

// compare current - next with threshold, with wrap-around
extern bool WrapCompare<T>(in T current, in T next, in T threshold);

typedef bit<16> Index;

struct Metadata {
    bit<32> timestamp;
    bit<16> nextHop;
}

extern Flowlet<T, N> {
    Flowlet(bit<32> stateSize);

    // Threshold: configured from the control-plane
    T threshold();
    // Access to saved array of timestamps
    T getTimestamp(in Index index);
    void setTimestamp(in Index index, in T value);
    // Access to saved array of next hops
    N getNextHop(in Index index);
    void setNextHop(in Index index, in N value);
    // Method executed when packet arrives
    abstract void onPacket(in Index index, in T ts, inout N nextHop);
}


typedef bit<32> Timestamp;
typedef bit<16> NextHop;

control FlowletSwitching(in Index index, inout Metadata metadata) {
    Flowlet<Timestamp, NextHop>(1024) flowlet = {
        void onPacket(in Index index, in Timestamp ts, inout NextHop nextHop) {
            Timestamp savedTs = this.getTimestamp(index);
            Timestamp thresh = this.threshold();
            bool less = WrapCompare(ts, savedTs, thresh);
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
