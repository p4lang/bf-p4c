#include <core.p4>
#include <tna.p4>   /* TOFINO1_ONLY */

struct metadata {
    bit<16> residual_csum;
}

header first_hdr_t {
    bit<32> data0;
    bit<16> data1;
    bit<32> data2;
    bit<8> data3;
    bit<8> data4;
}

/* We want to force the states to split something like:
split_state2.$split_0:
    *:
        # This needs to be empty checksum with no updates, just get
        checksum 0:
          type: RESIDUAL
          mask: [  ]
          swap: 0
          start: 0
          end: 1
          dest: TH0
          end_pos: 3
        # Something spilled
        0..3: W0  # ingress::hdr.split_hdr2.v5
        shift: 4
        buf_req: 4
        next: end
split_state.$split_0:
      *:
        # This needs to be empty checksum with no updates, just get
        # that just has different end_pos than for split_state2.$split_0
        checksum 0:
          type: RESIDUAL
          mask: [ ]
          swap: 0
          start: 0
          end: 1
          dest: TH0
          end_pos: 5
        # Something spilled, slightly differently than for split_state2
        0..3: W0  # ingress::hdr.split_hdr.v5
        shift: 6
        buf_req: 6
        next: end
*/
header split_hdr_t {
    bit<32> v0;
    bit<32> v1;
    bit<32> v2;
    bit<16> v3;
    bit<32> v4;
    bit<32> v5;
    bit<16> checksum;
}

header split_hdr2_t {
    bit<32> v0;
    bit<32> v1;
    bit<32> v2;
    bit<16> v3;
    bit<32> v4;
    bit<16> checksum;
    bit<32> v5;
}
struct headers {
    first_hdr_t first_hdr;
    split_hdr_t split_hdr;
    split_hdr2_t split_hdr2;
}

parser ingressParser(packet_in pkt, out headers hdr, out metadata meta,
                     out ingress_intrinsic_metadata_t ig_intr_md) {
    Checksum() split_checksum;
    Checksum() split2_checksum;
    state start {
        pkt.extract(ig_intr_md);
        pkt.advance(PORT_METADATA_SIZE);
        transition select_hdr;
    }
    state select_hdr {
        pkt.extract(hdr.first_hdr);
        transition select(hdr.first_hdr.data4) {
            0xf1 : split_state2;
            default : split_state;
        }
    }
    state split_state {
        pkt.extract(hdr.split_hdr);
        split_checksum.subtract_all_and_deposit(meta.residual_csum);
        split_checksum.subtract({hdr.split_hdr.v1});
        split_checksum.subtract({hdr.split_hdr.v2});
        split_checksum.subtract({hdr.split_hdr.checksum});

        transition accept;
    }
    state split_state2 {
        pkt.extract(hdr.split_hdr2);
        split_checksum.subtract_all_and_deposit(meta.residual_csum);
        split_checksum.subtract({hdr.split_hdr2.v1});
        split_checksum.subtract({hdr.split_hdr2.v2});
        split_checksum.subtract({hdr.split_hdr2.checksum});

        transition accept;
    }
}

control ingress(inout headers hdr, inout metadata meta,
                in ingress_intrinsic_metadata_t ig_intr_md,
                in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
                inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
                inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
    action setall() {
        hdr.split_hdr.v0 = 0x11;
        hdr.split_hdr.v1 = 0x22;
        hdr.split_hdr.v2 = 0x33;
        hdr.split_hdr.v3 = 0x44;
        hdr.split_hdr.v4 = 0x55;
        hdr.split_hdr.v5 = 0x66;
    }
    action setall2() {
        hdr.split_hdr2.v0 = 0x11;
        hdr.split_hdr2.v1 = 0x22;
        hdr.split_hdr2.v2 = 0x33;
        hdr.split_hdr2.v3 = 0x44;
        hdr.split_hdr2.v4 = 0x55;
        hdr.split_hdr2.v5 = 0x66;
    }
    action noop() { }
    table t1 {
        key = { hdr.split_hdr.v0 : exact; }
        actions = { setall; noop; }
        default_action = setall;
        size = 8;
    }
    table t2 {
        key = { hdr.split_hdr2.v1 : exact; }
        actions = { setall2; noop; }
        default_action = setall2;
        size = 8;
    }
    apply {
        ig_intr_tm_md.ucast_egress_port = 2;
        if (hdr.split_hdr.isValid()) {
            t1.apply();
        }
        if (hdr.split_hdr2.isValid()) {
            t2.apply();
        }
    }
}

control ingressDeparser(
    packet_out pkt,
    inout headers hdr,
    in metadata meta,
    in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprs) {
    
    Checksum() split_checksum;
    Checksum() split2_checksum;
    
    apply {

        if (hdr.split_hdr.isValid()) {
            hdr.split_hdr.checksum = split_checksum.update({
                hdr.split_hdr.v1,
                hdr.split_hdr.v2,
                meta.residual_csum});
        } else if (hdr.split_hdr2.isValid()) {
            hdr.split_hdr2.checksum = split2_checksum.update({
                hdr.split_hdr2.v1,
                hdr.split_hdr2.v2,
                meta.residual_csum});
        }

        pkt.emit(hdr.first_hdr);

        pkt.emit(hdr.split_hdr);
        pkt.emit(hdr.split_hdr2);
    }
}

parser egressParser(packet_in pkt, out headers hdr, out metadata meta,
                    out egress_intrinsic_metadata_t eg_intr_md) {
    state start {
        pkt.extract(eg_intr_md);
        transition accept;
    }
}

control egress(inout headers hdr, inout metadata meta, in egress_intrinsic_metadata_t eg_intr_md,
               in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
               inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprs,
               inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {
    apply {
    }
}

control egressDeparser(packet_out pkt, inout headers hdr, in metadata meta,
                       in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprs) {
    apply {
    }
}

Pipeline(ingressParser(), ingress(), ingressDeparser(),
         egressParser(), egress(), egressDeparser()) pipe;
Switch(pipe) main;