#if __TARGET_TOFINO__ == 2
#include "t2na.p4"
#else
#include "tna.p4"
#endif

struct metadata {
    bit<32> seq_no;
    bit<32> ack_no;
    bit<16> ss;
    bit<8> ws;
    bit<1> sack;
    bit<32> ts1;
    bit<32> ts2;
}

header tcp_t {
    bit<16> src_port;
    bit<16> dst_port;
    bit<32> seq_no;
    bit<32> ack_no;
    bit<4> data_offset;
    bit<4> res;
    bit<8> flags;
    bit<16> window;
    bit<16> checksum;
    bit<16> urgent_ptr;
}

struct headers {
    tcp_t tcp;
}

parser ParserImpl(packet_in pkt,
                  out headers hdr,
                  out metadata meta,
                  out ingress_intrinsic_metadata_t ig_intr_md) {
    ParserCounter() pctr;

    state start {
        pkt.extract(ig_intr_md);
        pkt.advance(PORT_METADATA_SIZE);

        pkt.extract(hdr.tcp);

        meta.seq_no = hdr.tcp.seq_no;
        meta.ack_no = hdr.tcp.ack_no;

#if __TARGET_TOFINO__ == 2
        pctr.set(hdr.tcp.data_offset, 15 << 4, 2, 0xff, -20);  // (max, rot, mask, add)
#else
        pctr.set(hdr.tcp.data_offset, 15 << 4, 2, 0x7, -20);  // (max, rot, mask, add)
#endif

        transition next_option;
    }

    @dont_unroll
    state next_option {
        transition select(pctr.is_zero()) {
            true : accept;  // no TCP Option bytes left
            default : next_option_part2;
        }
    }

    state next_option_part2 {
        // precondition: tcp_hdr_bytes_left >= 1
        transition select(pkt.lookahead<bit<8>>()) {
            0: parse_tcp_option_end;
            1: parse_tcp_option_nop;
            2: parse_tcp_option_mss;
            3: parse_tcp_option_ws;
            4: parse_tcp_option_sack;
            8: parse_tcp_option_ts;
            default: parse_tcp_option_tlv;
        }
    }

    state parse_tcp_option_end {
        pkt.advance(8);

        pctr.decrement(1);
        transition consume_remaining_tcp_hdr_and_accept;
    }

    state consume_remaining_tcp_hdr_and_accept {
//        pkt.advance((bit<32>) (8 * (bit<9>) tcp_hdr_bytes_left));
        transition accept;
    }

    state parse_tcp_option_nop {
        pkt.advance(8);

        pctr.decrement(1);
        transition next_option;
    }

    state parse_tcp_option_mss {
        pkt.advance(16);
        meta.ss = pkt.lookahead<bit<16>>();
        pkt.advance(16);

        pctr.decrement(4);
        transition next_option;
    }

    state parse_tcp_option_ws {
        pkt.advance(16);
        meta.ws = pkt.lookahead<bit<8>>();
        pkt.advance(8);

        pctr.decrement(3);
        transition next_option;
    }

    state parse_tcp_option_sack {
        pkt.advance(16);
        meta.sack = 1;

        pctr.decrement(2);
        transition next_option;
    }

    state parse_tcp_option_ts {
        pkt.advance(16);
        meta.ts1 = pkt.lookahead<bit<32>>();
        pkt.advance(32);
        meta.ts2 = pkt.lookahead<bit<32>>();
        pkt.advance(32);

        pctr.decrement(80);
        transition next_option;
    }

#define TLV(x)                        \
    state parse_tcp_option_tlv_##x## { \
        pkt.advance(8 * (x-1));       \
        pctr.decrement(x);            \
        transition next_option;       \
    }

#define PARSE_TLV \
	    TLV(2)     \
	    TLV(3)     \
	    TLV(4)     \
	    TLV(5)     \
	    TLV(6)     \
	    TLV(7)     \
	    TLV(8)     \
	    TLV(9)     \
	    TLV(10)    \
	    TLV(11)    \
	    TLV(12)    \
	    TLV(13)    \
	    TLV(14)    \
	    TLV(15)    \
	    TLV(16)    \
	    TLV(17)    \
	    TLV(18)    \
	    TLV(19)    \
	    TLV(20)    \
	    TLV(21)    \
	    TLV(22)    \
	    TLV(23)    \
	    TLV(24)    \
	    TLV(25)    \
	    TLV(26)    \
	    TLV(27)    \
	    TLV(28)    \
	    TLV(29)    \
	    TLV(30)    \
	    TLV(31)    \
	    TLV(32)    \
	    TLV(33)    \
	    TLV(34)    \
	    TLV(35)    \
	    TLV(36)    \
	    TLV(37)    \
	    TLV(38)    \
	    TLV(39)    \
	    TLV(40) 

    PARSE_TLV

#define TLV(x) x: parse_tcp_option_tlv_##x##;

    state parse_tcp_option_tlv {
        pkt.advance(8);
        transition select(pkt.lookahead<bit<8>>()) {
            PARSE_TLV
            default: parse_tcp_option_tlv_2;
        }
    }
}

control ingress(inout headers hdr, inout metadata meta,
                in ingress_intrinsic_metadata_t ig_intr_md,
                in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
                inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
                inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
    action noop() { }

    action a1() {
        ig_intr_tm_md.ucast_egress_port = 3;
    }

    table t1 {
        key = {
            meta.seq_no : exact;
            meta.ack_no : exact;
            meta.ss : exact;
            meta.ws : exact;
            meta.sack : exact;
            meta.ts1 : exact;
            meta.ts2 : exact;
        }

        actions = { a1; noop; }
        default_action = noop;
    }

    apply {
        ig_intr_tm_md.ucast_egress_port = 2;

        t1.apply();
    }
}

control ingressDeparser(packet_out packet, inout headers hdr, in metadata meta,
                        in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprs) {
    apply {
        packet.emit(hdr);
    }
}

parser egressParser(packet_in packet, out headers hdr, out metadata meta,
                    out egress_intrinsic_metadata_t eg_intr_md) {
    state start {
        packet.extract(eg_intr_md);
        transition accept;
    }
}

control egress(inout headers hdr, inout metadata meta, in egress_intrinsic_metadata_t eg_intr_md,
               in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
               inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprs,
               inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {
    apply { }
}

control egressDeparser(packet_out packet, inout headers hdr, in metadata meta,
                       in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprs) {
    apply { }
}

Pipeline(ParserImpl(), ingress(), ingressDeparser(), egressParser(), egress(), egressDeparser()) pipe;

Switch(pipe) main;
