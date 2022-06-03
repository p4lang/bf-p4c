#include <core.p4>
#include <tna.p4>   /* TOFINO1_ONLY */

struct metadata {
    bit<16> residual_csum;
}

header first_hdr_t {
    bit<32> data0;
}

header hdr1_t {
    bit<32> v0;
    bit<32> v1;
    bit<16> checksum;
}

header hdr2_t {
    bit<32> v0;
    bit<32> v1;
    bit<16> checksum;
}

struct headers {
    first_hdr_t first_hdr;
    hdr1_t hdr1;
    hdr2_t hdr2;
}

parser ingressParser(packet_in pkt, out headers hdr, out metadata meta,
                     out ingress_intrinsic_metadata_t ig_intr_md) {
    Checksum() checksum1;
    Checksum() checksum2;
    state start {
        pkt.extract(ig_intr_md);
        pkt.advance(PORT_METADATA_SIZE);
        transition select_hdr;
    }
    state select_hdr {
        pkt.extract(hdr.first_hdr);
        transition select(hdr.first_hdr.data0) {
            0xf1 : state2;
            default : state1;
        }
    }
    state state1 {
        pkt.extract(hdr.hdr1);
        checksum1.subtract_all_and_deposit(meta.residual_csum);
        checksum1.subtract({hdr.hdr1.v0});
        checksum1.subtract({hdr.hdr1.v1});
        checksum1.subtract({hdr.hdr1.checksum});

        transition accept;
    }
    state state2 {
        pkt.extract(hdr.hdr2);
        checksum2.subtract_all_and_deposit(meta.residual_csum);
        checksum2.subtract({hdr.hdr2.v0});
        checksum2.subtract({hdr.hdr2.v1});
        checksum2.subtract({hdr.hdr2.checksum});

        transition accept;
    }
}

control ingress(inout headers hdr, inout metadata meta,
                in ingress_intrinsic_metadata_t ig_intr_md,
                in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
                inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
                inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
    action setall1() {
        hdr.hdr1.v0 = 0x11;
        hdr.hdr1.v1 = 0x22;
    }
    action setall1_diff() {
        hdr.hdr1.v0 = 0x33;
        hdr.hdr1.v1 = 0x44;
    }
    action setall1_exit() {
        hdr.hdr1.v0 = 0x11;
        hdr.hdr1.v1 = 0x22;
        exit;
    }
    action setall2() {
        hdr.hdr2.v0 = 0x11;
        hdr.hdr2.v1 = 0x22;
    }
    action setall1_always_exit() {
        hdr.hdr1.v0 = 0x44;
        hdr.hdr1.v1 = 0x55;
        exit;
    }
    table t1 {
        key = { hdr.hdr1.v0 : exact; }
        actions = { setall1; setall1_exit; }
        default_action = setall1_exit;
        size = 8;
    }
    table t2 {
        key = { hdr.hdr2.v1 : exact; }
        actions = { setall2; }
        default_action = setall2;
        size = 8;
    }
    table t3 {
        key = { hdr.first_hdr.data0 : exact; }
        actions = { setall1_always_exit; }
        default_action = setall1_always_exit;
        size = 8;
    }
    table t4 {
        key = { hdr.first_hdr.data0 : exact; }
        actions = { setall1_diff; }
        default_action = setall1_diff;
        size = 8;
    }
    apply {
        ig_intr_tm_md.ucast_egress_port = 2;
        if (hdr.hdr1.isValid()) {
            // If exit action is hit we should end here and v0, v1
            // should be 0x11, 0x22
            t1.apply();
        } else if (hdr.hdr2.isValid()) {
            t2.apply();
        }
        // If exit action was not hit in t1
        // we will end here within t3 =>
        // v0, v1 should be 0x44, 0x55
        t3.apply();
        // This should not be reached
        // v0, v1 should never be 0x33, 0x44
        t4.apply();
    }
}

control ingressDeparser(
    packet_out pkt,
    inout headers hdr,
    in metadata meta,
    in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprs) {

    Checksum() checksum1;
    Checksum() checksum2;

    apply {

        // This forces the deparse_original/deparse_updated metadata
        // to be used for hdr1.checksum
        if (hdr.hdr2.isValid()) {
            hdr.hdr2.checksum = checksum2.update({
                hdr.hdr2.v0,
                hdr.hdr2.v1,
                meta.residual_csum});
        } else if (hdr.hdr1.isValid()) {
            hdr.hdr1.checksum = checksum1.update({
                hdr.hdr1.v0,
                hdr.hdr1.v1,
                meta.residual_csum});
        }

        pkt.emit(hdr.first_hdr);

        pkt.emit(hdr.hdr1);
        pkt.emit(hdr.hdr2);
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