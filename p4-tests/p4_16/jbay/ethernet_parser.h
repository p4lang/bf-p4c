typedef bit<48> mac_addr_t;

header ethernet_h {
    mac_addr_t dst_addr;
    mac_addr_t src_addr;
    bit<16> ether_type;
}

struct headers {
    ethernet_h  ethernet;
}

header ingress_skip_t { bit<192> skip; };

parser ingressParser(packet_in packet, out headers hdr, out metadata meta,
                     out ingress_intrinsic_metadata_t ig_intr_md) {
    ingress_skip_t skip;
    state start {
#ifdef METADATA_INIT
        METADATA_INIT(meta)
#endif
        packet.extract(ig_intr_md);
        transition skip_skip;
    }

    state skip_skip {
        packet.extract(skip);
        transition parse_ethernet;
    }

    state parse_ethernet {
        packet.extract(hdr.ethernet);
        transition accept;
    }
}
