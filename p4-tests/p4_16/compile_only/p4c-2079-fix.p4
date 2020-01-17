#include <core.p4>
#include <tna.p4>

@flexible
header codel_h {
    bit<32> ingress_st_time;
    bit<32> time_now;
    bit<32> queue_st_delay;
    bit<32> sojourn_remainder;

    bit<7> _pad1;
    bool sojourn_violation;

    bit<7> _pad2;
    bool first_sojourn_violation;

    bit<4> _pad3;
    // bit<4> predicate;
    bool predicate;

    bit<7> _pad4;
    bool drop;
}


struct pair_b32 {
    bit<32>     second;  // math unit can only use alu_lo writing to lo half of memory
    bit<32>     first;
}

struct pair_bool {
    bit<8>     first;
    bit<8>     second;
}

control CodelIngress (inout codel_h codel_hdr,
                      in bit<32> global_tstamp
                     ) {

    action act_init_ingress(int<32> sojourn_target) {
        codel_hdr.setValid();
        codel_hdr.drop = false;
        codel_hdr.ingress_st_time = global_tstamp + (bit<32>)sojourn_target;
    }

    table tbl_init_ingress {
        actions = { act_init_ingress; }
    }

    apply {
        tbl_init_ingress.apply();
    }
}

control CodelEgress (inout codel_h codel_hdr,
                     in bit<18> enq_tstamp,
                     in bit<18> deq_timedelta,
                     in bit<32> global_tstamp) 
                     (bit<32> control_interval){
    
    DirectRegister<pair_bool>() test_reg_dir;
    DirectRegisterAction<pair_bool, bool>(test_reg_dir) codel_drop_state = {
        void apply(inout pair_bool value, out bool first_sojourn_violation){

            if (value.first == 0) {
                value.second = (bit<8>)(bit<1>)codel_hdr.sojourn_violation;
            } else {
                value.second = 0;
            }

            value.first = (bit<8>)(bit<1>)codel_hdr.sojourn_violation;

            first_sojourn_violation = value.second != 0;
        }
    };

    MathUnit<bit<32>>(MathOp_t.RSQRT, 20) minus_square;

    DirectRegister<pair_b32>() test_reg_dir2;
    DirectRegisterAction<pair_b32, bool>(test_reg_dir2) codel_decide = {
        void apply(inout pair_b32 value, out bool predicate){

            if (codel_hdr.first_sojourn_violation) {
                value.first = 0;
            } else {
                value.first = codel_hdr.time_now + control_interval;
            }

            if (value.second < codel_hdr.time_now 
                && codel_hdr.first_sojourn_violation) {
                value.second = value.second + 1;
            } else {
                value.second = minus_square.execute(value.first);
            }

            predicate = (value.second < codel_hdr.time_now 
                         && codel_hdr.first_sojourn_violation);
        }
    };
    
    apply {
        codel_hdr.time_now = global_tstamp[31:0];
        codel_hdr.queue_st_delay = (codel_hdr.ingress_st_time - global_tstamp)[31:0];

        if (codel_hdr.sojourn_remainder == 0) {
            codel_hdr.sojourn_violation = true;
        } else {
            codel_hdr.sojourn_violation = false;
        }

        codel_drop_state.execute();

        if (codel_hdr.sojourn_violation == false) {
            codel_hdr.predicate = codel_decide.execute();

            if (codel_hdr.predicate) {
                codel_hdr.drop = true;
            }
        }
    }
}

typedef bit<48> mac_addr_t;

header ethernet_h {
    mac_addr_t dst_addr;
    mac_addr_t src_addr;
    bit<16> ether_type;
}

struct header_t {
    ethernet_h ethernet;
}

// const bit<32> SOJOURN_TARGET   =   5000000;
const bit<32> CONTROL_INTERVAL = 100000000;
const bit<32> INTERFACE_CPU    =      1500;
const bit<32> INTERFACE_CNT    =       512;

enum bit<8> internal_header_t {
    NONE      = 0x0,
    CODEL_HDR = 0x1
}

header internal_h {
    internal_header_t header_type;
}

/* Example bridge metadata */

struct metadata_t { 
    internal_h internal_hdr;
    codel_h codel_hdr;
}


// ---------------------------------------------------------------------------
// Ingress Parser
// ---------------------------------------------------------------------------
parser SwitchIngressParser(
        packet_in pkt,
        out header_t hdr,
        out metadata_t ig_md,
        out ingress_intrinsic_metadata_t ig_intr_md) {

    state start {
        ig_md.internal_hdr.setValid();
        ig_md.internal_hdr.header_type = internal_header_t.NONE;
        ig_md.codel_hdr.setInvalid();

        transition intr_md;
    }

    state intr_md {
        pkt.extract(ig_intr_md);
        transition select(ig_intr_md.resubmit_flag) {
            1 : parse_resubmit;
            0 : parse_port_metadata;
        }
    }

    state parse_resubmit {
        // Parse resubmitted packet here.
        transition reject;
    }

    state parse_port_metadata {
        pkt.advance(PORT_METADATA_SIZE);
        transition parse_ethernet;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition accept;
    }
}

// ---------------------------------------------------------------------------
// Ingress 
// ---------------------------------------------------------------------------
control SwitchIngress(
        inout header_t hdr,
        inout metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_prsr_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_tm_md) {

    CodelIngress() codel_ingress;

    action set_output_port(PortId_t port_id) {
        ig_tm_md.ucast_egress_port = port_id;
    }

    table output_port {
        actions = {
            set_output_port;
        }
    }

    apply {
        codel_ingress.apply(codel_hdr = ig_md.codel_hdr,
                            global_tstamp = (bit<32>)ig_prsr_md.global_tstamp);
        output_port.apply();
        ig_md.internal_hdr.header_type = internal_header_t.CODEL_HDR;
    }
}

// ---------------------------------------------------------------------------
// Ingress Deparser
// ---------------------------------------------------------------------------
control SwitchIngressDeparser(packet_out pkt,
                              inout header_t hdr,
                              in metadata_t ig_md,
                              in ingress_intrinsic_metadata_for_deparser_t 
                                ig_intr_dprsr_md
                              ) {
    apply {
        pkt.emit(ig_md.internal_hdr);
        pkt.emit(ig_md.codel_hdr);
        pkt.emit(hdr);
    }
}

// ---------------------------------------------------------------------------
// Egress Parser
// ---------------------------------------------------------------------------
parser SwitchEgressParser(
        packet_in pkt,
        out header_t hdr,
        out metadata_t eg_md,
        out egress_intrinsic_metadata_t eg_intr_md) {

    state start {
        pkt.extract(eg_intr_md);
        transition parse_internal_hdr;
    }

    state parse_internal_hdr {
        pkt.extract(eg_md.internal_hdr);
        eg_md.codel_hdr.setInvalid();
        transition select(eg_md.internal_hdr.header_type) {
            internal_header_t.NONE: accept;
            internal_header_t.CODEL_HDR: parse_example_bridge_hdr;
            default: reject;
        }
    }

    state parse_example_bridge_hdr {
        pkt.extract(eg_md.codel_hdr);
        transition parse_ethernet;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition accept;
    }
}


// ---------------------------------------------------------------------------
// Egress 
// ---------------------------------------------------------------------------
control SwitchEgress(
        inout header_t hdr,
        inout metadata_t eg_md,
        in egress_intrinsic_metadata_t eg_intr_md,
        in egress_intrinsic_metadata_from_parser_t eg_intr_from_prsr,
        inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
        inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {

    CodelEgress(control_interval = CONTROL_INTERVAL) codel_egress;

    apply {
        codel_egress.apply(codel_hdr = eg_md.codel_hdr, 
                           enq_tstamp = (bit<18>)eg_intr_md.enq_tstamp,
                           deq_timedelta = (bit<18>)eg_intr_md.deq_timedelta,
                           global_tstamp = (bit<32>)eg_intr_from_prsr.global_tstamp);
        
        eg_intr_md_for_dprsr.drop_ctl = 2w0 ++ (bit<1>) eg_md.codel_hdr.drop;
        // Debug
        hdr.ethernet.src_addr[31:0] = eg_md.codel_hdr.queue_st_delay;
    }
}

// ---------------------------------------------------------------------------
// Egress Deparser
// ---------------------------------------------------------------------------
control SwitchEgressDeparser(packet_out pkt,
                              inout header_t hdr,
                              in metadata_t eg_md,
                              in egress_intrinsic_metadata_for_deparser_t 
                                eg_intr_dprsr_md
                              ) {

    apply {
        pkt.emit(hdr);
    }
}


Pipeline(SwitchIngressParser(),
       SwitchIngress(),
       SwitchIngressDeparser(),
       SwitchEgressParser(),
       SwitchEgress(),
       SwitchEgressDeparser()) pipe;

Switch(pipe) main;
