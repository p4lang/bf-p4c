#ifndef DATA_T_OVERRIDE
header data_t {
    bit<32> f1;
    bit<32> f2;
    bit<16> h1;
    bit<8>  b1;
    bit<8>  b2;
}
#endif

struct headers {
    data_t data;
}

#ifdef _TOFINO_NATIVE_ARCHITECTURE_P4_
header ingress_skip_t { bit<64> pad; }
#define META_DIR        out
#else
#define META_DIR        inout
#endif

parser ParserImpl(packet_in packet, out headers hdr, META_DIR metadata meta,
#ifdef _TOFINO_NATIVE_ARCHITECTURE_P4_
                  out ingress_intrinsic_metadata_t ig_intr_md
#else
                  inout standard_metadata_t standard_metadata
#endif
) {
#ifdef _TOFINO_NATIVE_ARCHITECTURE_P4_
    ingress_skip_t skip;
#endif
    state start {
#ifdef METADATA_INIT
        METADATA_INIT(meta)
#endif
#ifdef _TOFINO_NATIVE_ARCHITECTURE_P4_
        packet.extract(ig_intr_md);
        packet.extract(skip);
#endif
        packet.extract(hdr.data);
        transition accept;
    }
}
