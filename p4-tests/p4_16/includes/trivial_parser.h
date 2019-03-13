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

parser ParserImpl(packet_in packet, out headers hdr,
#if defined(_V1_MODEL_P4_)
                  inout metadata meta,
                  inout standard_metadata_t standard_metadata
#else
                  out metadata meta,
                  out ingress_intrinsic_metadata_t ig_intr_md
#endif
) {
    state start {
#ifdef METADATA_INIT
        METADATA_INIT(meta)
#endif
#if !defined(_V1_MODEL_P4_)
        packet.extract(ig_intr_md);
        packet.advance(PORT_METADATA_SIZE);
#endif
        packet.extract(hdr.data);
        transition accept;
    }
}
