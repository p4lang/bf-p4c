#include <core.p4>
#include <tna.p4>

typedef bit<128> ipv6_addr_t;
typedef bit<8> ip_protocol_t;

const ip_protocol_t IP_PROTOCOLS_SRV6 = 43;
const ip_protocol_t IP_PROTOCOLS_NONXT = 59;

header ipv6_h {
    bit<4> version;
    bit<8> traffic_class;
    bit<20> flow_label;
    bit<16> payload_len;
    bit<8> next_hdr;
    bit<8> hop_limit;
    ipv6_addr_t src_addr;
    ipv6_addr_t dst_addr;
}

header srh_h {
    bit<8> next_hdr;
    bit<8> hdr_ext_len;
    bit<8> routing_type;
    bit<8> segment_left;
    bit<8> last_entry;
    bit<8> flags;
    bit<16> tag;
}

header srh_segment_list_t {
    bit<128> sid;
}

header ingress_skip_t {
#if __TARGET_TOFINO__ >= 2
        bit<192> pad;
#else
        bit<64> pad;
#endif
}

struct header_t {
    ipv6_h ipv6;
    srh_h srh;
    srh_segment_list_t[5] srh_segment_list;
    srh_h inner_srh;
}


typedef bit<128> srv6_sid_t;
struct srv6_metadata_t {
    srv6_sid_t sid; // SRH[SL]
    bit<16> rewrite; // Rewrite index
    bool psp; // Penultimate Segment Pop
    bool usp; // Ultimate Segment Pop
    bool decap;
    bool encap;
}

struct ingress_metadata_t {
    srv6_metadata_t srv6;
}

parser ParserI(
        packet_in pkt,
        out header_t hdr,
        out ingress_metadata_t ig_md,
        out ingress_intrinsic_metadata_t ig_intr_md) {

    ingress_skip_t skip;
    state start {
        pkt.extract(ig_intr_md);
        pkt.extract(skip);
        transition parse_ipv6;
    }

    state parse_ipv6 {
        pkt.extract(hdr.ipv6);
        transition select(hdr.ipv6.next_hdr) {
            IP_PROTOCOLS_SRV6 : parse_srh;
            default : accept;
        }
    }

    state parse_srh {
        pkt.extract(hdr.srh);
        transition parse_srh_segment_0;
    }

//FIXME(msharif): ig_md.srv6.sid is NOT set correctly.
#define IG_PARSE_SRH_SEGMENT(curr, next)                                    \
    state parse_srh_segment_##curr {                                        \
        pkt.extract(hdr.srh_segment_list[curr]);                            \
        transition select(hdr.srh.last_entry) {                             \
            curr : parse_srh_next_header;                                   \
            /* (_, next) :  set_active_segment_##curr;*/                    \
            default : parse_srh_segment_##next;                             \
        }                                                                   \
    }                                                                       \
                                                                            \
    state set_active_segment_##curr {                                       \
        /* ig_md.srv6.sid = hdr.srh_segment_list[curr].sid; */              \
        transition parse_srh_segment_##next;                                \
    }

IG_PARSE_SRH_SEGMENT(0, 1)
IG_PARSE_SRH_SEGMENT(1, 2)
IG_PARSE_SRH_SEGMENT(2, 3)
IG_PARSE_SRH_SEGMENT(3, 4)

    state parse_srh_segment_4 {
        pkt.extract(hdr.srh_segment_list[4]);
        transition parse_srh_next_header;
    }

    state set_active_segment_4 {
        ig_md.srv6.sid = hdr.srh_segment_list[4].sid;
        transition parse_srh_next_header;
    }
    state parse_srh_next_header {
        transition select(hdr.srh.next_hdr) {
            IP_PROTOCOLS_SRV6 : parse_inner_srh;
            IP_PROTOCOLS_NONXT : accept;
            default : reject;
        }
    }

    state parse_inner_srh {
        pkt.extract(hdr.inner_srh);
        transition accept;
    }

}

control IngressP(
        inout header_t hdr,
        inout ingress_metadata_t ig_md,

        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
    apply { }
}

control DeparserI(
        packet_out pkt,
        inout header_t hdr,
        in ingress_metadata_t ig_md,
        in ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md) {
    apply {
        pkt.emit(hdr.ipv6);
        pkt.emit(hdr.srh);
        pkt.emit(hdr.srh_segment_list);
        pkt.emit(hdr.inner_srh);
    }
}

struct metadata { }

parser ParserE(packet_in b,
               out header_t hdr,
               out metadata meta,
               out egress_intrinsic_metadata_t eg_intr_md) {
    state start {
        transition accept;  // XXX can't have empty parser in P4-16
    } 
}

control EgressP(
        inout header_t hdr,
        inout metadata meta,
        in egress_intrinsic_metadata_t eg_intr_md,
        in egress_intrinsic_metadata_from_parser_t eg_intr_prsr_md,
        inout egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
        inout egress_intrinsic_metadata_for_output_port_t eg_intr_oport_md) {
    apply { }
}

control DeparserE(packet_out b,
                  inout header_t hdr,
                  in metadata meta,
                  in egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md) {
    apply { }
}

Pipeline(ParserI(), IngressP(), DeparserI(), ParserE(), EgressP(), DeparserE()) pipe0;
Switch(pipe0) main;
