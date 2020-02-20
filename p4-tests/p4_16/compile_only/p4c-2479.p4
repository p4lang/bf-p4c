#include <tna.p4>

struct header_t {}
struct metadata_t {}

parser EmptyIngressParser(
        packet_in pkt,
        out header_t hdr,
        out metadata_t ig_md,
        out ingress_intrinsic_metadata_t ig_intr_md) {

    state start {
        transition accept;
    }
}

// ---------------------------------------------------------------------------
// Ingress Deparser
// ---------------------------------------------------------------------------
control EmptyIngressDeparser(
        packet_out pkt,
        inout header_t hdr,
        in metadata_t ig_md,
        in ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md) {

    apply {
    }
}

control EmptyIngress(
        inout header_t hdr,
        inout metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_prsr_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_tm_md) {
    apply {
    }
}

parser EmptyEgressParser(
    packet_in pkt,
    out header_t hdr,
    out metadata_t eg_md,
    out egress_intrinsic_metadata_t eg_intr_md) {
    
    state start {
        transition accept;
    }
}

control EmptyEgressDeparser(
        packet_out pkt,
        inout header_t hdr,
        in metadata_t eg_md,
        in egress_intrinsic_metadata_for_deparser_t eg_intr_dprs_md) {
    apply {
        pkt.emit(hdr);
    }
}

control Test(
        inout header_t hdr,
        inout metadata_t eg_md,
        in egress_intrinsic_metadata_t eg_intr_md,
        in egress_intrinsic_metadata_from_parser_t eg_intr_from_prsr,
        inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
    inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {
    Register<bit<8>, bit<9>>(256, 0) reg;
    RegisterAction<bit<8>, bit<9>, bit<8>>(reg) reg_set = {
        void apply(inout bit<8> val) {
            val = 1;
        }
    };
    RegisterAction<bit<8>, bit<9>, bool>(reg) reg_lookup = {
        void apply(inout bit<8> val, out bool rv) {
            rv = (val != 0);
            val = 0;
        }
    };

    Register<bit<8>, bit<9>>(256, 0) reg2;
    RegisterAction<bit<8>, bit<9>, bool>(reg2) reg2_lookup = {
        void apply(inout bit<8> val, out bool rv) {
            rv = (val == 0);
        }
    };

    action drop() {
        eg_intr_md_for_dprsr.drop_ctl = 1; // Drop packet.
    }

    apply {
        bool test = (eg_intr_md.egress_port == 0);
        
        if (test) {
            bool reg2_res = reg2_lookup.execute(eg_intr_md.egress_port);
            if (reg2_res) {
                reg_set.execute(eg_intr_md.egress_port);
            }
        } else {
            bool reg_res = reg_lookup.execute(eg_intr_md.egress_port);
            if (reg_res) {
                //drop();
            }
        }
    }
}

control SwitchEgress(
    inout header_t hdr,
    inout metadata_t eg_md,
    in egress_intrinsic_metadata_t eg_intr_md,
    in egress_intrinsic_metadata_from_parser_t eg_intr_from_prsr,
    inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
    inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {
    Test() test;
    
    apply {
        test.apply(hdr, eg_md, eg_intr_md, eg_intr_from_prsr, eg_intr_md_for_dprsr, eg_intr_md_for_oport);
    }
}

Pipeline(
    EmptyIngressParser(),
    EmptyIngress(),
    EmptyIngressDeparser(),
    EmptyEgressParser(),
    SwitchEgress(),
    EmptyEgressDeparser()
) pipe;

Switch(pipe) main;
