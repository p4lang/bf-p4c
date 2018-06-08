header data_t {
    bit<32> f1;
    bit<32> f2;
    bit<16> h1;
    bit<8>  b1;
    bit<8>  b2;
}

struct headers {
    data_t data;
}

header ingress_skip_t { bit<192> skip; };
parser ingressParser(packet_in packet, out headers hdr, out metadata meta,
                     out ingress_intrinsic_metadata_t ig_intr_md) {
    ingress_skip_t skip;
    state start {
        packet.extract(ig_intr_md);
        packet.extract(skip);
        transition data;
    }
    state data {
        packet.extract(hdr.data);
#ifdef METADATA_INIT
        METADATA_INIT(meta)
#endif
        transition accept;
    }
}
