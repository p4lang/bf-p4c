/* TOFINO1_ONLY */

#include <core.p4>
#include <tna.p4>

# 92 "pktgen9_16.p4" 2


// Get added to main pkginfo:



// Packet hdr definitions:
# 1 "stdhdrs.p4" 1
/*------------------------------------------------------------------------
    stdhdrs.p4 - Define standard protocol headers

    Copyright (C) 2019 by Keysight Technologies
    All Rights Reserved.
*-----------------------------------------------------------------------*/
//=====================
//      DEFINES
//=====================

// Ethertypes
# 32 "stdhdrs.p4"
header ethernet_t {
    bit<8> dstAddr0;
    bit<8> dstAddr1;
    bit<8> dstAddr2;
    bit<8> dstAddr3;
    bit<8> dstAddr4;
    bit<8> dstAddr5;
    bit<8> srcAddr0;
    bit<8> srcAddr1;
    bit<8> srcAddr2;
    bit<8> srcAddr3;
    bit<8> srcAddr4;
    bit<8> srcAddr5;
    bit<16> etherType;
}

header ipv4_t {
    bit<4> version;
    bit<4> ihl;
    bit<8> diffserv;
    bit<16> totalLen;
    bit<16> identification;
    bit<3> flags;
    bit<13> fragOffset;
    bit<8> ttl;
    bit<8> protocol;
    bit<16> hdrChecksum;
    bit<32> srcAddr;
    bit<32> dstAddr;
}

header ipv6_t {
    bit<4> version;
    bit<8> trafficClass;
    bit<20> flowLabel;
    bit<16> payloadLen;
    bit<8> nextHdr;
    bit<8> hopLimit;
    bit<32> srcAddr0;
    bit<32> srcAddr1;
    bit<32> srcAddr2;
    bit<32> srcAddr3;
    bit<32> dstAddr0;
    bit<32> dstAddr1;
    bit<32> dstAddr2;
    bit<32> dstAddr3;
}

header tcp_t {
    bit<16> srcPort;
    bit<16> dstPort;
    bit<32> seqNo;
    bit<32> ackNo;
    bit<4> dataOffset;
    bit<4> res;
    bit<8> flags;
    bit<16> window;
    bit<16> checksum;
    bit<16> urgentPtr;
}

header udp_t {
    bit<16> srcPort;
    bit<16> dstPort;
    bit<16> length_;
    bit<16> checksum;
}
# 119 "stdhdrs.p4"
header pktgen_generic_header_t {
    bit<3> _pad0;
    bit<2> pipe_id;
    bit<3> app_id;
    bit<8> key_msb;
    bit<16> batch_id;
    bit<16> packet_id;
}

header vlan_tag_t {
    bit<3> pcp;
    bit<1> cfi;
    bit<12> vid;
    bit<16> etherType;
}
# 100 "pktgen9_16.p4" 2
# 1 "ixia_hdrs.p4" 1
/*------------------------------------------------------------------------
    ixia_hdrs.p4 - Define IXIA-specific headers

    Copyright (C) 2019 by Keysight Technologies
    All Rights Reserved.
*-----------------------------------------------------------------------*/

// Big signature, 12 bytes
header ixia_big_signature_t {
    bit<32> sig1;
    bit<32> sig2;
    bit<32> sig3;
}


// Replace part of fixed signature from ig-to-eg with br md
header ixia_big_sig_br_md_t {
    // 16 bits:
    bit<7> _pad0;
    PortId_t ingress_port; // 9 bits. WARNING - using this in egress introduces an extra parser state
                            // ok to populte in ig as long as you don't use it in eg

    // 16 bits:
    bit<11> _pad1;
    bit<5>stream;

    // these words could also carry br_md; beware of added parsing states
    bit<32> word2;
    bit<32> word3;
}


header fabric_hdr_t {
    bit<16> devPort;
    bit<16> etherType;
}

// Extended instrumentation, 12 bytes
header ixia_extended_instrum_t {
    bit<3> tstamp_hires;
    bit<19> pgpad;
    bit<10> pgid;
    bit<32> seqnum;
    bit<32> tstamp;
}
# 101 "pktgen9_16.p4" 2
# 1 "types.p4" 1
/*------------------------------------------------------------------------
    types.p4 - header and struct definitions

    Copyright (C) 2019 by Keysight Technologies
    All Rights Reserved.
*-----------------------------------------------------------------------*/


  typedef bit<3> mirror_type_t;



const mirror_type_t MIRROR_TYPE_I2E = 1;
const mirror_type_t MIRROR_TYPE_E2E = 2;


// Represents 64-bit SALU values
struct reg_pair_t {
    bit<32> lo;
    bit<32> hi;
}

struct burst_pkt_cntr_t {
    bit<32> max;
    bit<1> drop;
}

struct g_pkt_cntr_t {
    bit<16> max;
    bit<16> value;
}

struct imix_t {
    bit<16> random;
}

struct timestamp_t {
    bit<32> lower;
    bit<32> upper;
}

// UDF counter params loaded in ingress and passed as bridged MD, to save a stage in egress
struct udf_cntr_params_brdg_t {
}

// UDF counter params loaded in egress
struct udf_cntr_params_t {
    bit<32> nested_repeat; // Length of the outer loop
    bit<32> nested_step; // Increment or decrement outer loop
    bit<2> bit_mask; // 8, 16, 24, or 32 bit masks
    bit<32> repeat; // Length of the inner loop
    bit<32> step; // Increment or decrement value of inner loop
    bit<32> stutter; // stutter value for inner loop
    bit<1> enable; // Indicates to MAUs that UDF is enabled
}

// UDF counter variables modified in egress
struct udf_cntr_vars_t {
    bit<32> final_value; // intermediate value for pipeline
    bit<32> nested_final_value; // intermediate value for pipeline
    bit<4> rollover_true;
    bit<4> update_inner_true;
}

//==============================
// Ingress metadata
//==============================

struct ingress_metadata_t {
    bit<10>port_stream_index;
    bit<4> pipe_port;
    bit<5> fp_port;
    bit<15> port_pgid_index;
    bit<14> pgid_pipe_port_index;
    bit<1> rx_instrum;
    int<32> seq_delta;
    int<32> latency;
    bit<32> lat_to_mem;
    bit<32> lat_to_mem_overflow;
    bit<32> lat_overflow;
    bit<2> eg_stream_color;
    bit<1> known_flow;
    bit<1> seq_incr;
    bit<1> seq_big;
    bit<1> seq_dup;
    bit<1> seq_rvs;
    bit<1> latency_overflow;
    bit<1> tstamp_overflow;
    imix_t imix;
    timestamp_t rx_packet_timestamp;
    bit<32> rx_tstamp_calibrated;
    MirrorId_t mirror_id; // needed to pass non-const to deparser mirror.emit()
    bit<1> is_mirror; // TODO delete
    bit<1> pcie_cpu_port_enabled;
    PortId_t ingress_port;
}

//==============================
// bridged metadata
//==============================
# 111 "types.p4"
header mirror_bridged_metadata_t {
    @padding bit<7> _pad;
    PortId_t ingress_port; // copied in ingress to convey to egress
}


header bridged_metadata_t {
  bit<1> is_mirror; // this bit needs to appear in same place in bridged_metadata_t and mirror_bridged_metadata_h
  bit<1> is_pktgen;
  bit<1> bank_select;



  bit<4> _pad;



    @padding bit<1> _pad2; // TODO - change to ingress_port_msb if ALU can handle





}

//==============================
// Egress metadata
//==============================

struct egress_metadata_t {
    bit<4> pipe_port;
    bit<5> fp_port;
    bit<10>port_stream_index;
    bit<15> port_pgid_index;
    bit<1> burst_mode;
    bit<10> txpgid;
    bit<1> tx_instrum; // the pgid to put into egress instrumentation
    burst_pkt_cntr_t burst_pkt_cntr;
    bit<14> pgid_pipe_port_index;
    timestamp_t tx_packet_timestamp;
    udf_cntr_params_t udf1_cntr_params; // counter params
    udf_cntr_params_t udf2_cntr_params; // counter params
    udf_cntr_vars_t udf1_cntr_vars; // egress stateful UDF vars
    udf_cntr_vars_t udf2_cntr_vars; // egress stateful UDF vars
    bit<16> g_pkt_cntr_value;
    bit<16> g_pkt_cntr_max;
}

struct header_t {




    mirror_bridged_metadata_t mirror_bridged_md; // need to carry ingress_port   

    bridged_metadata_t bridged_md;
    ixia_big_signature_t big_sig;

    ixia_big_sig_br_md_t big_sig_br_md;

    egress_intrinsic_metadata_t eg_intr_md;
    fabric_hdr_t fabric_hdr;
    ixia_extended_instrum_t instrum;
    ethernet_t outer_eth;
    ipv4_t outer_ipv4;
    ipv6_t outer_ipv6;
    tcp_t outer_tcp;
    tcp_t outer_tcpv6;
    udp_t outer_udp;
    udp_t outer_udpv6;
    vlan_tag_t[2] vlan_tag;
}
# 102 "pktgen9_16.p4" 2

//========== TOFINO PARAMETERS ==============
// TODO - Different for TF1/TF2 and various SKUs
# 117 "pktgen9_16.p4"
// See profiles.p4 for size/scale constants
# 1 "parser.p4" 1
/*------------------------------------------------------------------------
    parser.p4 - Parser/deparser declaration

    Copyright (C) 2019 by Keysight Technologies
    All Rights Reserved.
*-----------------------------------------------------------------------*/

parser TofinoIngressParser(
        packet_in packet,
        out ingress_intrinsic_metadata_t ig_intr_md) {
    state start {
        packet.extract(ig_intr_md);
        transition parse_port_metadata;
    }

    state parse_port_metadata {



        packet.advance(64);

        transition accept;
    }

}
parser SwitchIngressParser(
        packet_in packet,
        out header_t hdr,
        out ingress_metadata_t ig_md,
        out ingress_intrinsic_metadata_t ig_intr_md) {

    Checksum() ipv4_checksum;
    TofinoIngressParser() tofino_parser;

    state start {
        tofino_parser.apply(packet, ig_intr_md);
        transition select(ig_intr_md.ingress_port) {
            68 &&& 9w0x7f: parse_pktgen_eth;
            // CPU port should always do normal parsing
            64 &&& 9w0x7f: parse_i2e_cpu;
            // Pipe 1,3 are recirc pipes
            // 9 bit port number is
            // [2bit Pipe Id]-[7bit Port Id]
            // For Pipe 0b01 and 0b11, we mask out pipe Id with 0b10 (X1).
            // i.e. if LSB of Pipe Id is 1 then it's from recirc pipe.
            // Consider recirc ports as pktgen ports
            9w128 &&& 9w0x80: parse_pktgen_eth;
            default: parse_outer_eth;
        }
    }

    @name(".parse_i2e_cpu") state parse_i2e_cpu {
        hdr.bridged_md.is_pktgen = 1w0;
        packet.extract(hdr.outer_eth);
        transition select(hdr.outer_eth.etherType) {
            0x9090: parse_fabric_only;
            default: accept;
        }
    }
    @name(".parse_pktgen_eth") state parse_pktgen_eth {
        hdr.bridged_md.is_pktgen = 1w1;
# 77 "parser.p4"
        packet.extract(hdr.outer_eth);
        transition select(hdr.outer_eth.etherType) {
            0x9090: parse_fabric;
            0x0800: parse_outer_ipv4;
            0x86dd: parse_outer_ipv6;
            0x8100: parse_vlan;
            0x88A8: parse_vlan;
            0x9100: parse_vlan;
            0x9200: parse_vlan;
            0x9300: parse_vlan;
            default: parse_big_sig_ig_instrum;
        }

    }

    @name(".parse_fabric_only") state parse_fabric_only {
        packet.extract(hdr.fabric_hdr);
        transition accept;
    }

    @name(".parse_outer_eth") state parse_outer_eth {
        hdr.bridged_md.is_pktgen = 1w0;
        packet.extract(hdr.outer_eth);
        transition select(hdr.outer_eth.etherType) {
            0x9090: parse_fabric;
            0x0800: parse_outer_ipv4;
            0x86dd: parse_outer_ipv6;
            0x8100: parse_vlan;
            0x88A8: parse_vlan;
            0x9100: parse_vlan;
            0x9200: parse_vlan;
            0x9300: parse_vlan;
            default: parse_big_sig_ig_instrum;
        }
    }

    @name(".parse_fabric") state parse_fabric {
        packet.extract(hdr.fabric_hdr);
        transition select(hdr.fabric_hdr.etherType) {
            0x0800: parse_outer_ipv4;
            0x86dd: parse_outer_ipv6;
            0x8100: parse_vlan;
            0x88A8: parse_vlan;
            0x9100: parse_vlan;
            0x9200: parse_vlan;
            0x9300: parse_vlan;
            default: parse_big_sig_ig_instrum;
        }
    }
    @name(".parse_outer_ipv4") state parse_outer_ipv4 {
        packet.extract(hdr.outer_ipv4);
        transition select(hdr.outer_ipv4.protocol) {
            6: parse_outer_tcpv6;
            17: parse_outer_udpv6;
            default: parse_big_sig_ig_instrum;
        }
    }
    @name(".parse_outer_ipv6") state parse_outer_ipv6 {
        packet.extract(hdr.outer_ipv6);
        transition select(hdr.outer_ipv6.nextHdr) {
            6: parse_outer_tcp;
            17: parse_outer_udp;
            default: parse_big_sig_ig_instrum;
        }
    }
    @name(".parse_outer_tcp") state parse_outer_tcp {
        packet.extract(hdr.outer_tcp);
        transition parse_big_sig_ig_instrum;
    }
    @name(".parse_outer_tcpv6") state parse_outer_tcpv6 {
        packet.extract(hdr.outer_tcpv6);
        transition parse_big_sig_ig_instrum;
    }
    @name(".parse_outer_udp") state parse_outer_udp {
        packet.extract(hdr.outer_udp);
        transition parse_big_sig_ig_instrum;
    }
    @name(".parse_outer_udpv6") state parse_outer_udpv6 {
        packet.extract(hdr.outer_udpv6);
        transition parse_big_sig_ig_instrum;
    }
    @name(".parse_qinq_vlan") state parse_qinq_vlan {
        packet.extract(hdr.vlan_tag[1]);
        transition select(hdr.vlan_tag[1].etherType) {
            0x0800: parse_outer_ipv4;
            0x86dd: parse_outer_ipv6;
            default: parse_big_sig_ig_instrum;
        }
    }
    @name(".parse_vlan") state parse_vlan {
        packet.extract(hdr.vlan_tag[0]);
        transition select(hdr.vlan_tag[0].etherType) {
            0x0800: parse_outer_ipv4;
            0x86dd: parse_outer_ipv6;
            0x8100: parse_qinq_vlan;
            0x88A8: parse_qinq_vlan;
            0x9100: parse_qinq_vlan;
            0x9200: parse_qinq_vlan;
            0x9300: parse_qinq_vlan;
            default: parse_big_sig_ig_instrum;
        }
    }

    @name(".parse_big_sig_ig_instrum") state parse_big_sig_ig_instrum {




        packet.extract(hdr.big_sig_br_md);





        packet.extract(hdr.instrum);



        transition accept;
    }
}

parser TofinoEgressParser(
        packet_in packet,
        out egress_intrinsic_metadata_t eg_intr_md) {
    state start {
        packet.extract(eg_intr_md);
        transition accept;
    }
}

parser SwitchEgressParser(
        packet_in packet,
        out header_t hdr,
        out egress_metadata_t eg_md,
        out egress_intrinsic_metadata_t eg_intr_md) {

    TofinoEgressParser() tofino_parser;

    state start {
        tofino_parser.apply(packet, eg_intr_md);
        packet.extract(hdr.bridged_md);






        transition parse_outer_eth;

    }
# 247 "parser.p4"
    @name(".parse_outer_eth") state parse_outer_eth {
        packet.extract(hdr.outer_eth);
# 262 "parser.p4"
        // pkts may be mirrored or not
        transition select(hdr.bridged_md.is_mirror, hdr.outer_eth.etherType) {
            (1, 0x9090): parse_fabric_only; // 



            (1, _): parse_mirror_hdr; // mirrored to CPU

            (0, 0x9090): parse_fabric; // CPU to f/p - need fabric hdr to get dev_port
            (0, 0x0800): parse_outer_ipv4; // normal instrum pkts :
            (0, 0x86dd): parse_outer_ipv6;
            (0, 0x8100): parse_vlan;
            (0, 0x88A8): parse_vlan;
            (0, 0x9100): parse_vlan;
            (0, 0x9200): parse_vlan;
            (0, 0x9300): parse_vlan;
            (0, _): parse_big_sig_ig_instrum;
        }


    }

    @name(".parse_fabric_only") state parse_fabric_only {

        packet.extract(hdr.mirror_bridged_md);

        packet.extract(hdr.fabric_hdr);
        transition accept;
    }


    state parse_mirror_hdr {
        packet.extract(hdr.mirror_bridged_md);
        transition accept;
    }


    // state used when sending CPU pkts to f/p ports
    @name(".parse_fabric") state parse_fabric {
        packet.extract(hdr.fabric_hdr);
        transition select(hdr.fabric_hdr.etherType) {
            0x0800: parse_outer_ipv4;
            0x86dd: parse_outer_ipv6;
            0x8100: parse_vlan;
            0x88A8: parse_vlan;
            0x9100: parse_vlan;
            0x9200: parse_vlan;
            0x9300: parse_vlan;
            default: parse_big_sig_ig_instrum;
        }
    }

    @name(".parse_outer_ipv4") state parse_outer_ipv4 {
        packet.extract(hdr.outer_ipv4);
        transition select(hdr.outer_ipv4.protocol) {
            6: parse_outer_tcpv6;
            17: parse_outer_udpv6;
            default: parse_big_sig_ig_instrum;
        }
    }
    @name(".parse_outer_ipv6") state parse_outer_ipv6 {
        packet.extract(hdr.outer_ipv6);
        transition select(hdr.outer_ipv6.nextHdr) {
            6: parse_outer_tcp;
            17: parse_outer_udp;
            default: parse_big_sig_ig_instrum;
        }
    }
    @name(".parse_outer_tcp") state parse_outer_tcp {
        packet.extract(hdr.outer_tcp);
        transition parse_big_sig_ig_instrum;
    }
    @name(".parse_outer_tcpv6") state parse_outer_tcpv6 {
        packet.extract(hdr.outer_tcpv6);
        transition parse_big_sig_ig_instrum;
    }
    @name(".parse_outer_udp") state parse_outer_udp {
        packet.extract(hdr.outer_udp);
        transition parse_big_sig_ig_instrum;
    }
    @name(".parse_outer_udpv6") state parse_outer_udpv6 {
        packet.extract(hdr.outer_udpv6);
        transition parse_big_sig_ig_instrum;
    }
    @name(".parse_qinq_vlan") state parse_qinq_vlan {
        packet.extract(hdr.vlan_tag[1]);
        transition select(hdr.vlan_tag[1].etherType) {
            0x0800: parse_outer_ipv4;
            0x86dd: parse_outer_ipv6;
            default: parse_big_sig_ig_instrum;
        }
    }
    @name(".parse_vlan") state parse_vlan {
        packet.extract(hdr.vlan_tag[0]);
        transition select(hdr.vlan_tag[0].etherType) {
            0x0800: parse_outer_ipv4;
            0x86dd: parse_outer_ipv6;
            0x8100: parse_qinq_vlan;
            0x88A8: parse_qinq_vlan;
            0x9100: parse_qinq_vlan;
            0x9200: parse_qinq_vlan;
            0x9300: parse_qinq_vlan;
            default: parse_big_sig_ig_instrum;
        }
    }

    @name(".parse_big_sig_ig_instrum")
    state parse_big_sig_ig_instrum {

        packet.extract(hdr.big_sig);
        packet.extract(hdr.instrum);

        transition accept;
    }

}

control SwitchIngressDeparser(
        packet_out packet,
        inout header_t hdr,
        in ingress_metadata_t ig_md,
        in ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md) {

    Mirror() mirror;

    apply {
    #if __TARGET_TOFINO__ == 1
        if (ig_dprsr_md.mirror_type == MIRROR_TYPE_I2E) {
    #elif __TARGET_TOFINO__ >= 2
        if (ig_dprsr_md.mirror_type == (bit<4>) MIRROR_TYPE_I2E) {
    #endif
          // clone pkt with CPU fabr hdr info



          mirror.emit(ig_md.mirror_id);

        }

        packet.emit(hdr.bridged_md);

        packet.emit(hdr.mirror_bridged_md);

        packet.emit(hdr.outer_eth);
        packet.emit(hdr.fabric_hdr);



        packet.emit(hdr.vlan_tag);
        packet.emit(hdr.outer_ipv6);
        packet.emit(hdr.outer_ipv4);
        packet.emit(hdr.outer_udp);
        packet.emit(hdr.outer_tcp);




        packet.emit(hdr.big_sig_br_md);


        packet.emit(hdr.instrum);
    }
}

control SwitchEgressDeparser(
        packet_out packet,
        inout header_t hdr,
        in egress_metadata_t eg_md,
        in egress_intrinsic_metadata_for_deparser_t eg_dprsr_md) {
    Checksum() ipv4_checksum;

    apply {
      // TODO ipv6 checksum
        hdr.outer_ipv4.hdrChecksum = ipv4_checksum.update(
                {hdr.outer_ipv4.version,
                 hdr.outer_ipv4.ihl,
                 hdr.outer_ipv4.diffserv,
                 hdr.outer_ipv4.totalLen,
                 hdr.outer_ipv4.identification,
                 hdr.outer_ipv4.flags,
                 hdr.outer_ipv4.fragOffset,
                 hdr.outer_ipv4.ttl,
                 hdr.outer_ipv4.protocol,
                 hdr.outer_ipv4.srcAddr,
                 hdr.outer_ipv4.dstAddr
                });
        packet.emit(hdr.outer_eth);
        packet.emit(hdr.fabric_hdr);



        packet.emit(hdr.vlan_tag);
        packet.emit(hdr.outer_ipv6);
        packet.emit(hdr.outer_ipv4);
        packet.emit(hdr.outer_udp);
        packet.emit(hdr.outer_tcp);
        packet.emit(hdr.big_sig);
        packet.emit(hdr.instrum);
    }
}
# 119 "pktgen9_16.p4" 2


# 1 "bank_select.p4" 1
/*------------------------------------------------------------------------
    bank_select.p4 - Module to simply store active bank for PGID and stream stats. This allows for Tx/Rx Sync of
    flow statistics through bank switching.

    Copyright (C) 2019 by Keysight Technologies
    All Rights Reserved.
*-----------------------------------------------------------------------*/

control process_bank_select_reg(inout header_t hdr) {
    @name(".do_set_bank_select")
    action do_set_bank_select(bit<1> bank_select) {
        hdr.bridged_md.bank_select = bank_select;
    }
    @name(".bank_select_tbl")
    table bank_select_tbl {
        actions = {
            do_set_bank_select;
        }
        size = 1;
        default_action = do_set_bank_select(bank_select = 0);
    }
    apply {
        bank_select_tbl.apply();
    }
}
# 122 "pktgen9_16.p4" 2
# 1 "counter_udf.p4" 1
/*------------------------------------------------------------------------
    counter_udf.p4 - Module to modify protocol fields via nested counters.
    Specifies protocol fields for each UDF(User Defined Field). 

    Copyright (C) 2019 by Keysight Technologies
    All Rights Reserved.
*-----------------------------------------------------------------------*/

/*
 * Load UDF1 counter parameters
 */
control process_load_udf1_cntr_params(inout header_t hdr, in egress_intrinsic_metadata_t eg_intr_md, inout egress_metadata_t eg_md) {
    @name(".do_load_udf1_cntr_params")
    action do_load_udf1_cntr_params(bit<32> nested_repeat, bit<32> nested_step, bit<2> bit_mask,
            bit<32> repeat, bit<32> step, bit<32> stutter, bit<1> enable) {
        eg_md.udf1_cntr_params.nested_repeat = nested_repeat;
        eg_md.udf1_cntr_params.nested_step = nested_step;
        eg_md.udf1_cntr_params.bit_mask = bit_mask;
        eg_md.udf1_cntr_params.repeat = repeat;
        eg_md.udf1_cntr_params.step = step;
        eg_md.udf1_cntr_params.enable = enable;
        eg_md.udf1_cntr_params.stutter = stutter;
    }

    @Feature(name="Udf1CounterParams", block=counter_udf, service=Udf, service_id=Udf1CounterParams, display_name="Udf1 Counter Params")

    @Api(label="Udf1 Counter Params")
    @brief("Udf1 Counter Params")
    @description("Udf1 Counter Params per stream")
    @name(".load_udf1_cntr_params_tbl")
    table load_udf1_cntr_params_tbl {
        actions = {
            do_load_udf1_cntr_params;
        }
        key = {
             hdr.big_sig_br_md.stream: ternary
                                      @brief("Stream number")
                                      @Api(label="Stream number",format="dec");
            eg_intr_md.egress_port: ternary
                                      @brief("Egress Port")
                                      @Api(label="Egress port number (dataplane)",format="dec");
        }
        size = 1024;
    }
    apply {
        load_udf1_cntr_params_tbl.apply();
    }
}

/*
 * Load UDF2 counter parameters
 */
 control process_load_udf2_cntr_params(inout header_t hdr, in egress_intrinsic_metadata_t eg_intr_md,
         inout egress_metadata_t eg_md) {
    @name(".do_load_udf2_cntr_params")
    action do_load_udf2_cntr_params(bit<32> nested_repeat, bit<32> nested_step, bit<2> bit_mask,
            bit<32> repeat, bit<32> step, bit<32> stutter, bit<1> enable) {
        eg_md.udf2_cntr_params.nested_repeat = nested_repeat;
        eg_md.udf2_cntr_params.nested_step = nested_step;
        eg_md.udf2_cntr_params.bit_mask = bit_mask;
        eg_md.udf2_cntr_params.repeat = repeat;
        eg_md.udf2_cntr_params.step = step;
        eg_md.udf2_cntr_params.stutter = stutter;
        eg_md.udf2_cntr_params.enable = enable;
    }

    @Feature(name="Udf2ounterParams", block=counter_udf, service=Udf, service_id=Udf2CounterParams, display_name="Udf2 Counter Params")

    @Api(label="Udf2 Counter Params")
    @brief("Udf2 Counter Params")
    @description("Udf2 Counter Params per stream")
    @name(".load_udf2_cntr_params_tbl")
    table load_udf2_cntr_params_tbl {
        actions = {
            do_load_udf2_cntr_params;
        }
        key = {
             hdr.big_sig_br_md.stream: ternary
                                      @brief("Stream number")
                                      @Api(label="Stream number",format="dec");
            eg_intr_md.egress_port: ternary
                                      @brief("Egress Port")
                                      @Api(label="Egress port number (dataplane)",format="dec");
        }
        size = 1024;
    }
    apply {
        load_udf2_cntr_params_tbl.apply();
    }
}

control process_compute_conditional_cntr_udf(inout header_t hdr, inout egress_metadata_t eg_md) {

    @name(".udf1_cntr_conditional_reg")
    Register<reg_pair_t, bit<32>>(1024,{0,0}) udf1_cntr_conditional_reg;

    @name(".udf2_cntr_conditional_reg")
    Register<reg_pair_t, bit<32>>(1024,{0,0}) udf2_cntr_conditional_reg;

    @name(".udf1_cntr_compute_conditional_salu")
    RegisterAction<reg_pair_t, bit<32>, bit<32>>(udf1_cntr_conditional_reg) udf1_cntr_compute_conditional_salu = {
        void apply(inout reg_pair_t value, out bit<32> rv) {
            rv = 32w0;
            reg_pair_t in_value;
            in_value = value;
            // Predicate is a four bit value encoding both condition_lo and condition_hi
            // See Stateful Processing in 10K Series PDF Slide 24 for details 
            rv = (bit<32>)this.predicate(
              in_value.lo + 32w1 <= eg_md.udf1_cntr_params.repeat, // UDF inner loop pattern is not finished
              in_value.hi + 32w1 <= eg_md.udf1_cntr_params.stutter); // UDF inner loop stutter is not finished

            // If inner loop pattern is not finished and stutter is finished
            if (in_value.lo + 32w1 <= eg_md.udf1_cntr_params.repeat &&
                !(in_value.hi + 32w1 <= eg_md.udf1_cntr_params.stutter)) {
                // ... then increment inner loop counter
                value.lo = in_value.lo + 32w1;
            }

            // If inner loop pattern is finished and stutter is finished 
            if (!(in_value.lo + 32w1 <= eg_md.udf1_cntr_params.repeat) &&
                !(in_value.hi + 32w1 <= eg_md.udf1_cntr_params.stutter)) {
                // ... then reset inner loop counter 
                value.lo = (bit<32>)0;
            }
            // If stutter is not finished
            if (in_value.hi + 32w1 <= eg_md.udf1_cntr_params.stutter) {
                //... then increment stutter counter
                value.hi = in_value.hi + 32w1;
            }

            // Else if stutter is finished 
            if (!(in_value.hi + 32w1 <= eg_md.udf1_cntr_params.stutter)) {
                // Reset stutter counter
                value.hi = (bit<32>)0;
            }
        }
    };

    @name(".udf2_cntr_compute_conditional_salu")
    RegisterAction<reg_pair_t, bit<32>, bit<32>>(udf2_cntr_conditional_reg) udf2_cntr_compute_conditional_salu = {
        void apply(inout reg_pair_t value, out bit<32> rv) {
            rv = 32w0;
            reg_pair_t in_value;
            in_value = value;
            // Predicate is a four bit value encoding both condition_lo and condition_hi
            // See Stateful Processing in 10K Series PDF Slide 24 for details 
            rv = (bit<32>)this.predicate(
              in_value.lo + 32w1 <= eg_md.udf2_cntr_params.repeat, // UDF inner loop pattern is not finished
              in_value.hi + 32w1 <= eg_md.udf2_cntr_params.stutter); // UDF inner loop stutter is not finished
            // If inner loop pattern is not finished and stutter is finished
            if (in_value.lo + 32w1 <= eg_md.udf2_cntr_params.repeat &&
                !(in_value.hi + 32w1 <= eg_md.udf2_cntr_params.stutter)) {
                // ... then increment inner loop counter
                value.lo = in_value.lo + 32w1;
            }

            // If inner loop pattern is finished and stutter is finished 
            if (!(in_value.lo + 32w1 <= eg_md.udf2_cntr_params.repeat) &&
                !(in_value.hi + 32w1 <= eg_md.udf2_cntr_params.stutter)) {
                // ... then reset inner loop counter 
                value.lo = 32w0;
            }

            // If stutter is not finished
            if (in_value.hi + 32w1 <= eg_md.udf2_cntr_params.stutter) {
                //... then increment stutter counter
                value.hi = in_value.hi + 32w1;
            }

            // Else if stutter is finished 
            if (!(in_value.hi + 32w1 <= eg_md.udf2_cntr_params.stutter)) {
                // Reset stutter counter
                value.hi = 32w0;
            }
        }
    };

    @name(".do_udf1_cntr_compute_conditional")
    action do_udf1_cntr_compute_conditional() {
        eg_md.udf1_cntr_vars.update_inner_true = (bit<4>)udf1_cntr_compute_conditional_salu.execute((bit<32>)eg_md.port_stream_index);
    }
    @name(".compute_conditional_udf1_cntr_tbl")
    table compute_conditional_udf1_cntr_tbl {
        actions = {
            do_udf1_cntr_compute_conditional;
        }
        key = {
            eg_md.udf1_cntr_params.enable: exact;
        }
        size = 1;
    }

    @name(".do_udf2_cntr_compute_conditional")
    action do_udf2_cntr_compute_conditional() {
        eg_md.udf2_cntr_vars.update_inner_true = (bit<4>)udf2_cntr_compute_conditional_salu.execute((bit<32>)eg_md.port_stream_index);
    }
    @name(".compute_conditional_udf2_cntr_tbl")
    table compute_conditional_udf2_cntr_tbl {
        actions = {
            do_udf2_cntr_compute_conditional;
        }
        key = {
            eg_md.udf2_cntr_params.enable: exact;
        }
        size = 1;
    }
    apply {
        compute_conditional_udf1_cntr_tbl.apply();
        compute_conditional_udf2_cntr_tbl.apply();
    }
}

control process_compute_inner_cntr_udf(inout header_t hdr, inout egress_metadata_t eg_md) {
    @name(".udf1_inner_cntr_reg")
    Register<reg_pair_t, bit<32>>(1024,{0,0}) udf1_inner_cntr_reg;

    @name(".udf2_inner_cntr_reg")
    Register<reg_pair_t, bit<32>>(1024,{0,0}) udf2_inner_cntr_reg;

    @name(".udf1_inner_cntr_salu")
    RegisterAction<reg_pair_t, bit<32>, bit<32>>(udf1_inner_cntr_reg) udf1_inner_cntr_salu = {
        void apply(inout reg_pair_t value, out bit<32> rv) {
            rv = 32w0;
            reg_pair_t in_value;
            in_value = value;
            rv = in_value.lo;
            // Inner repeat count has not rolled over and stutter is done 
            if (eg_md.udf1_cntr_vars.update_inner_true == 4w2) {
                // Update inner loop counter
                value.lo = in_value.lo + eg_md.udf1_cntr_params.step;
            }
            // Inner repeat count has rolled over and stutter is done
            if (eg_md.udf1_cntr_vars.update_inner_true == 4w1) {
                // Reset inner loop counter
                value.lo = (bit<32>)0;
            }
        }
    };

    @name(".udf2_inner_cntr_salu")
    RegisterAction<reg_pair_t, bit<32>, bit<32>>(udf2_inner_cntr_reg) udf2_inner_cntr_salu = {
        void apply(inout reg_pair_t value, out bit<32> rv) {
            rv = 32w0;
            reg_pair_t in_value;
            in_value = value;
            rv = in_value.lo;
            // Inner repeat count has not rolled over and stutter is done 
            if (eg_md.udf2_cntr_vars.update_inner_true == 4w2) {
                // Update inner loop counter
                value.lo = in_value.lo + eg_md.udf2_cntr_params.step;
            }
            // Inner repeat count has rolled over and stutter is done
            if (eg_md.udf2_cntr_vars.update_inner_true == 4w1) {
                // Reset inner loop counter
                value.lo = (bit<32>)0;
            }
        }
    };

    @name(".do_compute_udf1_inner_cntr")
    action do_compute_udf1_inner_cntr() {
        eg_md.udf1_cntr_vars.final_value = udf1_inner_cntr_salu.execute((bit<32>)eg_md.port_stream_index);
    }
    @name(".compute_udf1_inner_cntr_tbl")
    table compute_udf1_inner_cntr_tbl {
        actions = {
            do_compute_udf1_inner_cntr;
        }
        key = {
            eg_md.udf1_cntr_params.enable: exact;
        }
        size = 1;
    }

    @name(".do_compute_udf2_inner_cntr") action do_compute_udf2_inner_cntr() {
        eg_md.udf2_cntr_vars.final_value = udf2_inner_cntr_salu.execute((bit<32>)eg_md.port_stream_index);
    }
    @name(".compute_udf2_inner_cntr_tbl")
    table compute_udf2_inner_cntr_tbl {
        actions = {
            do_compute_udf2_inner_cntr;
        }
        key = {
            eg_md.udf2_cntr_params.enable: exact;
        }
        size = 1;
    }

    apply {
        compute_udf1_inner_cntr_tbl.apply();
        compute_udf2_inner_cntr_tbl.apply();
    }
}

control process_intermediate_inner_cntr_udf(inout header_t hdr, inout egress_metadata_t eg_md) {
    @name(".udf1_cntr_udf_rollover_reg")
    Register<reg_pair_t, bit<32>>(1024,{0,0}) udf1_cntr_udf_rollover_reg;

    @name(".udf2_cntr_udf_rollover_reg")
    Register<reg_pair_t, bit<32>>(1024,{0,0}) udf2_cntr_udf_rollover_reg;

    // programmed with thresholds from control plane
    // if the UDF is incrementing the initial value of register_lo is max_value + 1 and register_hi is MAX_UINT32
    // if the UDF is decrementing the initial value of register_lo is 0 and register_hi is min_value - 1
    @name(".udf1_cntr_udf_rollover_salu")
    RegisterAction<reg_pair_t, bit<32>, bit<32>>(udf1_cntr_udf_rollover_reg) udf1_cntr_udf_rollover_salu = {
        void apply(inout reg_pair_t value, out bit<32> rv) {
            rv = 32w0;
            reg_pair_t in_value;
            in_value = value;
            rv = (bit<32>)this.predicate(
              eg_md.udf1_cntr_vars.final_value < in_value.lo, // Check if inner counter is less than maximum value for incrementing counter
              eg_md.udf1_cntr_vars.final_value > in_value.hi); // Check if inner counter is greater than minimum value for decrementing counter
        }
    };

    // programmed with threshold from control plane
    // if the UDF is incrementing the initial value of register_lo is max_value + 1 and register_hi is MAX_UINT32
    // if the UDF is decrementing the initial value of register_lo is 0 and register_hi is min_value - 1
    @name(".udf2_cntr_udf_rollover_salu")
    RegisterAction<reg_pair_t, bit<32>, bit<32>>(udf2_cntr_udf_rollover_reg) udf2_cntr_udf_rollover_salu = {
        void apply(inout reg_pair_t value, out bit<32> rv) {
            rv = 32w0;
            reg_pair_t in_value;
            in_value = value;
            rv = (bit<32>)this.predicate(
                  eg_md.udf2_cntr_vars.final_value < in_value.lo, // Check if inner counter is less than maximum value for incrementing counter
                  eg_md.udf2_cntr_vars.final_value > in_value.hi); // Check if inner counter is greater than minimum value for decrementing counter
        }
    };

    @name(".do_udf1_cntr_udf_rollover")
    action do_udf1_cntr_udf_rollover() {
        eg_md.udf1_cntr_vars.rollover_true = (bit<4>)udf1_cntr_udf_rollover_salu.execute((bit<32>)eg_md.port_stream_index);
    }

    @name(".udf1_cntr_udf_rollover_tbl")
    table udf1_cntr_udf_rollover_tbl {
        actions = {
            do_udf1_cntr_udf_rollover;
        }
        key = {
            eg_md.udf1_cntr_params.enable: exact;
        }
        size = 1;
    }

    @name(".do_udf2_cntr_udf_rollover")
    action do_udf2_cntr_udf_rollover() {
        eg_md.udf2_cntr_vars.rollover_true = (bit<4>)udf2_cntr_udf_rollover_salu.execute((bit<32>)eg_md.port_stream_index);
    }
    @name(".udf2_cntr_udf_rollover_tbl")
    table udf2_cntr_udf_rollover_tbl {
        actions = {
            do_udf2_cntr_udf_rollover;
        }
        key = {
            eg_md.udf2_cntr_params.enable: exact;
        }
        size = 1;
    }

    apply {
        udf1_cntr_udf_rollover_tbl.apply();
        udf2_cntr_udf_rollover_tbl.apply();
    }
}

control process_intermediate_outer_cntr_udf(inout header_t hdr, inout egress_metadata_t eg_md) {
    @name(".udf1_nested_cntr_udf_reg")
    Register<reg_pair_t, bit<32>>(1024,{0,0}) udf1_nested_cntr_udf_reg;

    @name(".udf2_nested_cntr_udf_reg")
    Register<reg_pair_t, bit<32>>(1024,{0,0}) udf2_nested_cntr_udf_reg;

    @name(".udf1_nested_cntr_udf_salu")
    RegisterAction<reg_pair_t, bit<32>, bit<32>>(udf1_nested_cntr_udf_reg) udf1_nested_cntr_udf_salu = {
        void apply(inout reg_pair_t value, out bit<32> rv) {
            rv = 32w0;
            reg_pair_t in_value;
            in_value = value;
            rv = in_value.hi;
             // Outer repeat count has not rolled over
            if (in_value.lo + 32w1 <= eg_md.udf1_cntr_params.nested_repeat) {
                // Increment nested counter
                value.hi = in_value.hi + eg_md.udf1_cntr_params.nested_step;
            }
             // Outer repeat count has rolled over
            if (!(in_value.lo + 32w1 <= eg_md.udf1_cntr_params.nested_repeat)) {
                // Reset nested counter
                value.hi = (bit<32>)0;
            }
             // Outer repeat count has not rolled over
            if (in_value.lo + 32w1 <= eg_md.udf1_cntr_params.nested_repeat) {
                // Update outer repeat count 
                value.lo = in_value.lo + 32w1;
            }
             // Outer repeat count has rolled over
            if (!(in_value.lo + 32w1 <= eg_md.udf1_cntr_params.nested_repeat)) {
                // Reset outer repeat count
                value.lo = (bit<32>)0;
            }
        }
    };
    @name(".udf1_nested_cntr_udf_read_salu")
    RegisterAction<reg_pair_t, bit<32>, bit<32>>(udf1_nested_cntr_udf_reg) udf1_nested_cntr_udf_read_salu = {
        void apply(inout reg_pair_t value, out bit<32> rv) {
            rv = 32w0;
            reg_pair_t in_value;
            in_value = value;
            value.hi = in_value.hi;
            rv = value.hi;
        }
    };
    @name(".udf2_nested_cntr_udf_salu")
    RegisterAction<reg_pair_t, bit<32>, bit<32>>(udf2_nested_cntr_udf_reg) udf2_nested_cntr_udf_salu = {
        void apply(inout reg_pair_t value, out bit<32> rv) {
            rv = 32w0;
            reg_pair_t in_value;
            in_value = value;
            rv = in_value.hi;
            if (in_value.lo + 32w1 <= eg_md.udf2_cntr_params.nested_repeat) {
                value.hi = in_value.hi + eg_md.udf2_cntr_params.nested_step;
            }
            if (!(in_value.lo + 32w1 <= eg_md.udf2_cntr_params.nested_repeat)) {
                value.hi = (bit<32>)0;
            }
            if (in_value.lo + 32w1 <= eg_md.udf2_cntr_params.nested_repeat) {
                value.lo = in_value.lo + 32w1;
            }
            if (!(in_value.lo + 32w1 <= eg_md.udf2_cntr_params.nested_repeat)) {
                value.lo = (bit<32>)0;
            }
        }
    };
    @name(".udf2_nested_cntr_udf_read_salu")
    RegisterAction<reg_pair_t, bit<32>, bit<32>>(udf2_nested_cntr_udf_reg) udf2_nested_cntr_udf_read_salu = {
        void apply(inout reg_pair_t value, out bit<32> rv) {
            rv = 32w0;
            reg_pair_t in_value;
            in_value = value;
            value.hi = in_value.hi;
            rv = value.hi;
        }
    };

    @name(".do_udf1_nested_cntr_udf_read")
    action do_udf1_nested_cntr_udf_read() {
        eg_md.udf1_cntr_vars.nested_final_value = udf1_nested_cntr_udf_read_salu.execute((bit<32>)eg_md.port_stream_index);
    }
    @name(".udf1_nested_cntr_udf_read_tbl")
    table udf1_nested_cntr_udf_read_tbl {
        actions = {
            do_udf1_nested_cntr_udf_read;
        }
        key = {
            eg_md.udf1_cntr_params.enable: exact;
        }
        size = 1;
    }

    @name(".do_udf1_nested_cntr_udf")
    action do_udf1_nested_cntr_udf() {
        eg_md.udf1_cntr_vars.nested_final_value = udf1_nested_cntr_udf_salu.execute((bit<32>)eg_md.port_stream_index);
    }
    @name(".udf1_nested_cntr_udf_tbl")
    table udf1_nested_cntr_udf_tbl {
        actions = {
            do_udf1_nested_cntr_udf;
        }
        key = {
            eg_md.udf1_cntr_params.enable: exact;
        }
        size = 1;
    }

    @name(".do_udf2_nested_cntr_udf_read")
    action do_udf2_nested_cntr_udf_read() {
        eg_md.udf2_cntr_vars.nested_final_value = udf2_nested_cntr_udf_read_salu.execute((bit<32>)eg_md.port_stream_index);
    }
    @name(".udf2_nested_cntr_udf_read_tbl")
    table udf2_nested_cntr_udf_read_tbl {
        actions = {
            do_udf2_nested_cntr_udf_read;
        }
        key = {
            eg_md.udf2_cntr_params.enable: exact;
        }
        size = 1;
    }

    @name(".do_udf2_nested_cntr_udf")
    action do_udf2_nested_cntr_udf() {
        eg_md.udf2_cntr_vars.nested_final_value = udf2_nested_cntr_udf_salu.execute((bit<32>)eg_md.port_stream_index);
    }
    @name(".udf2_nested_cntr_udf_tbl")
    table udf2_nested_cntr_udf_tbl {
        actions = {
            do_udf2_nested_cntr_udf;
        }
        key = {
            eg_md.udf2_cntr_params.enable: exact;
        }
        size = 1;
    }

    apply {
        if (eg_md.udf1_cntr_vars.update_inner_true == 4w1) {
            udf1_nested_cntr_udf_tbl.apply();
        } else {
            udf1_nested_cntr_udf_read_tbl.apply();
        }
        if (eg_md.udf2_cntr_vars.update_inner_true == 4w1) {
            udf2_nested_cntr_udf_tbl.apply();
        } else {
            udf2_nested_cntr_udf_read_tbl.apply();
        }
    }
}

control process_update_cntr_udf(inout header_t hdr, in egress_intrinsic_metadata_t eg_intr_md, inout egress_metadata_t eg_md) {
    @name(".do_udf1_cntr_udf_update")
    action do_udf1_cntr_udf_update(bit<32> update_value) {
        eg_md.udf1_cntr_vars.final_value = eg_md.udf1_cntr_vars.final_value + update_value;
    }

    // Will be two entries per stream
    // One for normal condition, and one for rollover condition
    // In normal condition, update_value = inital value of UDF 
    // In rollover condition for incrementing UDF, update_value = (min - (max - init) + step)
    // For decrementing UDF, update_value = initial value of UDF
    // In rollover condition for decrementing UDF, update_value = (max + (init - min) + step)

    @Feature(name="Udf1UpdateParams", block=counter_udf, service=Udf, service_id=Udf1UpdateParams, display_name="Udf1 Counter Update Parameters")

    @Api(label="Udf1 Counter Update Parameters")
    @brief("Udf1 Counter Update Parameters")
    @description("Udf1 Counter Update Parameters, two entries per stream")
    @name(".update_udf1_cntr_udf_tbl")
    table update_udf1_cntr_udf_tbl {
        actions = {
            do_udf1_cntr_udf_update;
        }
        key = {
            eg_md.udf2_cntr_params.enable: exact
                                      @brief("enable")
                                      @Api(label="Enable header update",format="dec");
            eg_md.udf2_cntr_vars.rollover_true: exact
                                      @brief("rollover")
                                      @Api(label="Counter is rolling over",format="dec");
            hdr.big_sig_br_md.stream: ternary
                                      @brief("Stream number")
                                      @Api(label="Stream number",format="dec");
            eg_intr_md.egress_port: ternary
                                      @brief("Egress Port")
                                      @Api(label="Egress port number (dataplane)",format="dec");
        }
        size = 64;
    }

    @name(".do_udf2_cntr_udf_update")
    action do_udf2_cntr_udf_update(bit<32> update_value) {
        eg_md.udf2_cntr_vars.final_value = eg_md.udf2_cntr_vars.final_value + update_value;
    }

    // Will be two entries per stream
    // One for normal condition, and one for rollover condition
    // In normal condition, update_value = inital value of UDF 
    // In rollover condition for incrementing UDF, update_value = (min - (max - init) + step)
    // For decrementing UDF, update_value = initial value of UDF
    // In rollover condition for decrementing UDF, update_value = (max + (init - min) + step)
    @Feature(name="Udf2UpdateParams", block=counter_udf, service=Udf, service_id=Udf2UpdateParams, display_name="Udf2 Counter Update Parameters")

    @Api(label="Udf2 Counter Update Parameters")
    @brief("Udf2 Counter Update Parameters")
    @description("Udf2 Counter Update Parameters, two entries per stream")
    @name(".update_udf2_cntr_udf_tbl")
    table update_udf2_cntr_udf_tbl {
        actions = {
            do_udf2_cntr_udf_update;
        }
        key = {
            eg_md.udf2_cntr_params.enable: exact
                                      @brief("enable")
                                      @Api(label="Enable header update",format="dec");
            eg_md.udf2_cntr_vars.rollover_true: exact
                                      @brief("rollover")
                                      @Api(label="Counter is rolling over",format="dec");
            hdr.big_sig_br_md.stream: ternary
                                      @brief("Stream number")
                                      @Api(label="Stream number",format="dec");
            eg_intr_md.egress_port: ternary
                                      @brief("Egress Port")
                                      @Api(label="Egress port number (dataplane)",format="dec");
        }
        size = 64;
    }
    apply {
        update_udf1_cntr_udf_tbl.apply();
        update_udf2_cntr_udf_tbl.apply();
    }
}

control process_update_cntr_udf_nested(inout header_t hdr, in egress_intrinsic_metadata_t eg_intr_md, inout egress_metadata_t eg_md) {
    @name(".do_udf1_cntr_udf_update_nested")
    action do_udf1_cntr_udf_update_nested() {
        eg_md.udf1_cntr_vars.final_value = eg_md.udf1_cntr_vars.final_value + eg_md.udf1_cntr_vars.nested_final_value;
    }
    @name(".update_udf1_cntr_udf_nested_tbl")
    table update_udf1_cntr_udf_nested_tbl {
        actions = {
            do_udf1_cntr_udf_update_nested;
        }
        key = {
            eg_md.udf1_cntr_params.enable: exact;
        }
        size = 1;
    }

    @name(".do_udf2_cntr_udf_update_nested")
    action do_udf2_cntr_udf_update_nested() {
        eg_md.udf2_cntr_vars.final_value = eg_md.udf2_cntr_vars.final_value + eg_md.udf2_cntr_vars.nested_final_value;
    }
    @name(".update_udf2_cntr_udf_nested_tbl")
    table update_udf2_cntr_udf_nested_tbl {
        actions = {
            do_udf2_cntr_udf_update_nested;
        }
        key = {
            eg_md.udf2_cntr_params.enable: exact;
        }
        size = 1;
    }
    apply {
        update_udf1_cntr_udf_nested_tbl.apply();
        update_udf2_cntr_udf_nested_tbl.apply();
    }
}


control process_cntr_udf(inout header_t hdr, in egress_intrinsic_metadata_t eg_intr_md, inout egress_metadata_t eg_md) {
    @name(".do_udf1_cntr_ipv4_src_32")
    action do_udf1_cntr_ipv4_src_32() {
        hdr.outer_ipv4.srcAddr[31:0] = eg_md.udf1_cntr_vars.final_value[31:0];
    }
    @name(".do_udf1_cntr_ipv4_src_24")
    action do_udf1_cntr_ipv4_src_24() {
        hdr.outer_ipv4.srcAddr[23:0] = eg_md.udf1_cntr_vars.final_value[23:0];
    }
    @name(".do_udf1_cntr_ipv4_src_16")
    action do_udf1_cntr_ipv4_src_16() {
        hdr.outer_ipv4.srcAddr[15:0] = eg_md.udf1_cntr_vars.final_value[15:0];
    }
    @name(".do_udf1_cntr_ipv4_src_8")
    action do_udf1_cntr_ipv4_src_8() {
        hdr.outer_ipv4.srcAddr[7:0] = eg_md.udf1_cntr_vars.final_value[7:0];
    }

    @Feature(name="Udf1HdrUpdate", block=counter_udf, service=Udf, service_id=Udf1HdrUpdate, display_name="Udf1 Header Update Action Table")

    @Api(label="Udf1 Header Update Action Table")
    @brief("Udf1 Header Update Action Table")
    @description("Udf1 Header Update Action Table, specify which header fields to modify based on UDF1 counter values")
    @name(".udf1_cntr_udf_tbl")
    table udf1_cntr_udf_tbl {
        actions = {
            do_udf1_cntr_ipv4_src_32;
            do_udf1_cntr_ipv4_src_24;
            do_udf1_cntr_ipv4_src_16;
            do_udf1_cntr_ipv4_src_8;
        }
        key = {
            eg_md.udf1_cntr_params.bit_mask : exact;
            eg_md.udf1_cntr_params.enable : exact;
            hdr.big_sig_br_md.stream: ternary
                                      @brief("Stream number")
                                      @Api(label="Stream number",format="dec");
            eg_intr_md.egress_port: ternary
                                      @brief("Egress Port")
                                      @Api(label="Egress port number (dataplane)",format="dec");
        }
        size = 1024;
    }

    @name(".do_udf2_cntr_ipv4_dest_32")
    action do_udf2_cntr_ipv4_dest_32() {
        hdr.outer_ipv4.dstAddr[31:0] = eg_md.udf2_cntr_vars.final_value[31:0];
    }
    @name(".do_udf2_cntr_ipv4_dest_24")
    action do_udf2_cntr_ipv4_dest_24() {
        hdr.outer_ipv4.dstAddr[23:0] = eg_md.udf2_cntr_vars.final_value[23:0];
    }
    @name(".do_udf2_cntr_ipv4_dest_16")
    action do_udf2_cntr_ipv4_dest_16() {
        hdr.outer_ipv4.dstAddr[15:0] = eg_md.udf2_cntr_vars.final_value[15:0];
    }
    @name(".do_udf2_cntr_ipv4_dest_8")
    action do_udf2_cntr_ipv4_dest_8() {
        hdr.outer_ipv4.dstAddr[7:0] = eg_md.udf2_cntr_vars.final_value[7:0];
    }

    @Feature(name="Udf2HdrUpdate", block=counter_udf, service=Udf, service_id=Udf2HdrUpdate, display_name="Udf2 Header Update Action Table")

    @Api(label="Udf2 Header Update Action Table")
    @brief("Udf2 Header Update Action Table")
    @description("Udf2 Header Update Action Table, specify which header fields to modify based on UDF2 counter values")
    @name(".udf2_cntr_udf_tbl")
    table udf2_cntr_udf_tbl {
        actions = {
            do_udf2_cntr_ipv4_dest_32;
            do_udf2_cntr_ipv4_dest_24;
            do_udf2_cntr_ipv4_dest_16;
            do_udf2_cntr_ipv4_dest_8;
        }
        key = {
            eg_md.udf2_cntr_params.bit_mask : exact;
            eg_md.udf2_cntr_params.enable : exact;
            hdr.big_sig_br_md.stream: ternary
                                      @brief("Stream number")
                                      @Api(label="Stream number",format="dec");
            eg_intr_md.egress_port: ternary
                                      @brief("Egress Port")
                                      @Api(label="Egress port number (dataplane)",format="dec");
        }
        size = 1024;
    }

    apply {
        udf1_cntr_udf_tbl.apply();
        udf2_cntr_udf_tbl.apply();
    }
}
# 123 "pktgen9_16.p4" 2
# 1 "eg_stats.p4" 1
/*------------------------------------------------------------------------
    eg_stats.p4 - Module to compute statistics for egress ports.
    Computes transmit port and per stream statistics.
    Implements bank switching for Tx/Rx Sync.

    Copyright (C) 2019 by Keysight Technologies
    All Rights Reserved.
*-----------------------------------------------------------------------*/

control process_eg_stream_stats(inout header_t hdr, inout egress_metadata_t eg_md) {
    @Feature(name="TxStreamStatsA", block=eg_port_stats, service=Stats, service_id=TxStreamStatsA, index=stream,
    display_name="Tx Stream Stats A", display_cols="Stream|TxBytesA|TxPacketsA",col_units="|bytes|packets")
    @Api(index=port, label="Tx Stream Stats A", col_labels="Stream|TxStreamBytesA|TxStreamPacketsA",col_units="|bytes|packets")
    @brief("Egress stream stats counter bank A")
    @description("Egress stream stats counter bank A, count all eg stream stats when bank select=0")
    @name(".eg_stream_statsA_cntr")
    Counter<bit<32>,bit<10>>(1024,CounterType_t.PACKETS_AND_BYTES) eg_stream_statsA_cntr;

    @Feature(name="TxStreamStatsB", block=eg_port_stats, service=Stats, service_id=TxStreamStatsB, index=stream,
    display_name="Tx Stream Stats B", display_cols="Strean|TxBytesB|TxPacketsB",col_units="|bytes|packets")
    @Api(index=port, label="Tx Stream Stats B", col_labels="Stream|TxStreamBytesB|TxStreamPacketsB",col_units="|bytes|packets")
    @brief("Egress stream stats counter bank B")
    @description("Egress stream stats counter bank B, count all eg stream stats when bank select=1")
    @name(".eg_stream_statsB_cntr")
    Counter<bit<32>,bit<10>>(1024,CounterType_t.PACKETS_AND_BYTES) eg_stream_statsB_cntr;

    @Feature(name="TxStreamTstampA", block=eg_port_stats, service=Stats, service_id=TxStreamTstampA, index=stream,
    display_name="Tx Stream Timestamp A", display_cols="Stream|Hi|Lo",col_units="|ns*2^32|ns")
    @Api(index=stream, label="Tx Stream Timestamp A", col_labels="Stream|Hi|Lo",col_units="|ns*2^32|ns")
    @brief("Egress stream timestamps bank A")
    @description("Egress stream timestamps bank A, record timestamps when bank select=0")
    @name(".tx_egress_stamp_regA")
    Register<reg_pair_t, bit<32>>(1024,{0,0}) tx_egress_stamp_regA;

    @Feature(name="TxStreamTstampB", block=eg_port_stats, service=Stats, service_id=TxStreamTstampB, index=stream,
    display_name="Tx Stream Timestamp B", display_cols="Stream|Hi|Lo",col_units="|ns*2^32|ns")
    @Api(index=stream, label="Tx Stream Timestamp B", col_labels="Stream|Hi|Lo",col_units="|ns*2^32|ns")
    @brief("Egress stream timestamps bank B")
    @description("Egress stream timestamps bank B, record timestamps when bank select=0")
    @name(".tx_egress_stamp_regB")
    Register<reg_pair_t, bit<32>>(1024,{0,0}) tx_egress_stamp_regB;


    // pseudo-feature to declare a regex and label for multiple stats
    @Feature(name="StreamStats", block=eg_port_stats, service=Stats, service_id=".*StreamStats.*",
      index=stream, display_name="All Stream Stats")
    @Api(index=stream, label="All Stream Stats")
    @brief("Fake entity - not instantatiated, do not attempt to access except via service_id")
    @description("Fake entity to receive annotation for service_id regex")
    Counter<bit<32>,bit<10>>(1024,CounterType_t.PACKETS_AND_BYTES) eg_fake_stream_stats_cntr;
    @name(".store_egress_tstampB_salu")

    @name(".do_eg_stream_statsA")
    action do_eg_stream_statsA() {
        eg_stream_statsA_cntr.count(eg_md.port_stream_index);
    }
    @name(".eg_stream_statsA_tbl")
    table eg_stream_statsA_tbl {
        actions = {
            do_eg_stream_statsA;
        }
        size = 1;
        default_action = do_eg_stream_statsA();
    }

    @name(".do_eg_stream_statsB")
    action do_eg_stream_statsB() {
        eg_stream_statsB_cntr.count(eg_md.port_stream_index);
    }
    @name(".eg_stream_statsB_tbl")
    table eg_stream_statsB_tbl {
        actions = {
            do_eg_stream_statsB;
        }
        size = 1;
        default_action = do_eg_stream_statsB();
    }

    @name(".store_egress_tstampA_salu")
    RegisterAction<reg_pair_t, bit<32>, bit<32>>(tx_egress_stamp_regA) store_egress_tstampA_salu = {
        void apply(inout reg_pair_t value) {
            reg_pair_t in_value;
            in_value = value;
            value.hi = eg_md.tx_packet_timestamp.upper;
            value.lo = eg_md.tx_packet_timestamp.lower;
        }
    };
    @name(".do_store_egress_stampA")
    action do_store_egress_stampA() {
        store_egress_tstampA_salu.execute((bit<32>)eg_md.port_stream_index);
    }
    @name(".tx_tstampA_tbl")
    table tx_tstampA_tbl {
        actions = {
            do_store_egress_stampA;
        }
        size = 1;
        default_action = do_store_egress_stampA();
    }

    RegisterAction<reg_pair_t, bit<32>, bit<32>>(tx_egress_stamp_regB) store_egress_tstampB_salu = {
        void apply(inout reg_pair_t value) {
            reg_pair_t in_value;
            in_value = value;
            value.hi = eg_md.tx_packet_timestamp.upper;
            value.lo = eg_md.tx_packet_timestamp.lower;
        }
    };
    @name(".do_store_egress_stampB")
    action do_store_egress_stampB() {
        store_egress_tstampB_salu.execute((bit<32>)eg_md.port_stream_index);
    }
    @name(".tx_tstampB_tbl")
    table tx_tstampB_tbl {
        actions = {
            do_store_egress_stampB;
        }
        size = 1;
        default_action = do_store_egress_stampB();
    }
    apply {
        if (hdr.bridged_md.bank_select == 1w1) {
            eg_stream_statsB_tbl.apply();
            tx_tstampB_tbl.apply();
        } else {
            eg_stream_statsA_tbl.apply();
            tx_tstampA_tbl.apply();
        }
    }
}

control process_eg_port_stats(inout header_t hdr, in egress_intrinsic_metadata_t eg_intr_md) {

    @Feature(name="TxPortStats", block=eg_port_stats, service=Stats, service_id=TxPortStats, index=port, display_name="Tx Port Stats", display_cols="Port|TxBytes|TxPackets",col_units="|bytes|packets")

    @Api(index=port, label="Tx Port Stats", col_labels="Port|TxBytes|TxPackets",col_units="|bytes|packets")
    @brief("Egress port stats counter")
    @description("Egress port stats counter, count all egress port stats regardless of bank select")
    @name(".eg_port_stats_cntrA")
    Counter<bit<32>,bit<9>>(32w512,CounterType_t.PACKETS_AND_BYTES) eg_port_stats_cntrA;

    @Feature(name="PortStats", block=port_stats, service=Stats, service_id=".*PortStats.*", index=port, display_name="All Port Stats")

    @Api(index=port, label="All Port Stats")
    @brief("Fake entity - not instantatiated, do not attempt to access except via service_id")
    @description("Fake entity to receive annotation for service_id regex")
    @name(".fake_port_stats_cntr")
    Counter<bit<32>,bit<9>>(32w512,CounterType_t.PACKETS_AND_BYTES) fake_port_stats_cntr;

    @name(".do_eg_port_statsA")
    action do_eg_port_statsA() {
        eg_port_stats_cntrA.count(eg_intr_md.egress_port);
    }
    @name(".eg_port_statsA_tbl")
    table eg_port_statsA_tbl {
        actions = {
            do_eg_port_statsA;
        }
        size = 1;
        default_action = do_eg_port_statsA();
    }
    apply {
        eg_port_statsA_tbl.apply();
    }
}
# 124 "pktgen9_16.p4" 2
# 1 "front_panel.p4" 1
/*------------------------------------------------------------------------
    front_panel.p4 - Module to retrieve port indices based on dataplane port
    Copyright (C) 2019 by Keysight Technologies
    All Rights Reserved.
*/


control process_ingress_fp_port(inout header_t hdr, in ingress_intrinsic_metadata_t ig_intr_md, inout ingress_metadata_t ig_md) {
    @name("._nop") action _nop() {
    }

    @name(".do_get_fp_port")
    action do_get_fp_port(bit<5> fp_port, bit<4> pipe_port) {
        ig_md.fp_port = fp_port;
        ig_md.pipe_port = pipe_port;
    }
    @name(".ingress_get_fp_port_tbl")
    table ingress_get_fp_port_tbl {
        actions = {
            _nop;
            do_get_fp_port;
        }
        key = {
            ig_intr_md.ingress_port: ternary;
        }
        size = 256;
        default_action = _nop();
        // Static table mapping dataplane ports to f/p ports, channels
        // TODO - refactor per channelized ports; use 32Q platform values
        // or, continue to program algorithmically to accomodate variants of platform port mapping
        const entries = {
            // To support Tofino sim;
            // TODO: remove from production code
            68 &&& 511: do_get_fp_port(0,0); // packet generator - to allow counter testing w/o recirc
            1 &&& 511: do_get_fp_port(1,0); // veth2
            2 &&& 511: do_get_fp_port(2,0); // veth4
            3 &&& 511: do_get_fp_port(3,0); // veth6
            4 &&& 511: do_get_fp_port(4,0); // veth8
            5 &&& 511: do_get_fp_port(5,0); // veth10
            6 &&& 511: do_get_fp_port(6,0); // veth12
            7 &&& 511: do_get_fp_port(7,0); // veth14
            8 &&& 511: do_get_fp_port(8,0); // veth16

            // 32Q Super Montara platform, 100G f/p ports only:
            // NOTE - the second action params are bogus, revisit
            260 &&& 511: do_get_fp_port(1,0);
            268 &&& 511: do_get_fp_port(2,0);
            276 &&& 511: do_get_fp_port(3,0);
            284 &&& 511: do_get_fp_port(4,0);
            292 &&& 511: do_get_fp_port(5,0);
            300 &&& 511: do_get_fp_port(6,0);
            308 &&& 511: do_get_fp_port(7,0);
            316 &&& 511: do_get_fp_port(8,0);
            56 &&& 511: do_get_fp_port(9,0);
            48 &&& 511: do_get_fp_port(10,0);
            40 &&& 511: do_get_fp_port(11,0);
            32 &&& 511: do_get_fp_port(12,0);
            24 &&& 511: do_get_fp_port(13,0);
            16 &&& 511: do_get_fp_port(14,0);
            8 &&& 511: do_get_fp_port(15,0);
            0 &&& 511: do_get_fp_port(16,0);
            4 &&& 511: do_get_fp_port(17,0);
            12 &&& 511: do_get_fp_port(18,0);
            20 &&& 511: do_get_fp_port(19,0);
            28 &&& 511: do_get_fp_port(20,0);
            36 &&& 511: do_get_fp_port(21,0);
            44 &&& 511: do_get_fp_port(22,0);
            52 &&& 511: do_get_fp_port(23,0);
            60 &&& 511: do_get_fp_port(24,0);
            312 &&& 511: do_get_fp_port(25,0);
            304 &&& 511: do_get_fp_port(26,0);
            296 &&& 511: do_get_fp_port(27,0);
            288 &&& 511: do_get_fp_port(28,0);
            272 &&& 511: do_get_fp_port(29,0);
            280 &&& 511: do_get_fp_port(30,0);
            256 &&& 511: do_get_fp_port(31,0);
            264 &&& 511: do_get_fp_port(32,0);
            64 &&& 511: do_get_fp_port(33,0);

            // 32Q Super Montara platform, 100G recirc ports only:
            184 &&& 511: do_get_fp_port(1,0);
            176 &&& 511: do_get_fp_port(2,0);
            168 &&& 511: do_get_fp_port(3,0);
            160 &&& 511: do_get_fp_port(4,0);
            152 &&& 511: do_get_fp_port(5,0);
            144 &&& 511: do_get_fp_port(6,0);
            136 &&& 511: do_get_fp_port(7,0);
            128 &&& 511: do_get_fp_port(8,0);
            132 &&& 511: do_get_fp_port(9,0);
            140 &&& 511: do_get_fp_port(10,0);
            148 &&& 511: do_get_fp_port(11,0);
            156 &&& 511: do_get_fp_port(12,0);
            164 &&& 511: do_get_fp_port(13,0);
            172 &&& 511: do_get_fp_port(14,0);
            180 &&& 511: do_get_fp_port(15,0);
            188 &&& 511: do_get_fp_port(16,0);
            440 &&& 511: do_get_fp_port(17,0);
            432 &&& 511: do_get_fp_port(18,0);
            424 &&& 511: do_get_fp_port(19,0);
            416 &&& 511: do_get_fp_port(20,0);
            408 &&& 511: do_get_fp_port(21,0);
            400 &&& 511: do_get_fp_port(22,0);
            392 &&& 511: do_get_fp_port(23,0);
            384 &&& 511: do_get_fp_port(24,0);
            388 &&& 511: do_get_fp_port(25,0);
            396 &&& 511: do_get_fp_port(26,0);
            404 &&& 511: do_get_fp_port(27,0);
            412 &&& 511: do_get_fp_port(28,0);
            420 &&& 511: do_get_fp_port(29,0);
            428 &&& 511: do_get_fp_port(30,0);
            436 &&& 511: do_get_fp_port(31,0);
            444 &&& 511: do_get_fp_port(32,0);
        }
    }
    apply {
        ingress_get_fp_port_tbl.apply();
    }
}

control process_egress_fp_port(inout header_t hdr, in egress_intrinsic_metadata_t eg_intr_md, inout egress_metadata_t eg_md) {
    @name("._nop") action _nop() {
    }
    @name(".do_get_eg_fp_port")
    action do_get_eg_fp_port(bit<5> fp_port, bit<4> pipe_port) {
        eg_md.fp_port = fp_port;
        eg_md.pipe_port = pipe_port;
    }

    @name(".egress_get_fp_port_tbl")
    @placement_priority(100) // do this earliest since fp_port needs to get packet into port_stream_index  used as register indices throughout
    table egress_get_fp_port_tbl {
        actions = {
            _nop;
            do_get_eg_fp_port;
        }
        key = {
            eg_intr_md.egress_port: ternary;
        }
        size = 256;
        default_action = _nop();
        // Static table mapping dataplane ports to f/p ports, channels
        // TODO - refactor per channelized ports; use 32Q platform values
        // or, continue to program algorithmically to accomodate variants of platform port mapping
        const entries = {
            // To support Tofino sim;
            // TODO: remove from production code
            68 &&& 511: do_get_eg_fp_port(0,0); // packet generator - to allow counter testing w/o recirc
            1 &&& 511: do_get_eg_fp_port(1,0); // veth2
            2 &&& 511: do_get_eg_fp_port(2,0); // veth4
            3 &&& 511: do_get_eg_fp_port(3,0); // veth6
            4 &&& 511: do_get_eg_fp_port(4,0); // veth8
            5 &&& 511: do_get_eg_fp_port(5,0); // veth10
            6 &&& 511: do_get_eg_fp_port(6,0); // veth12
            7 &&& 511: do_get_eg_fp_port(7,0); // veth14
            8 &&& 511: do_get_eg_fp_port(8,0); // veth16

            // 32Q Super Montara platform, 100G f/p ports only:
            // NOTE - the second action params are bogus, revisit
            260 &&& 511: do_get_eg_fp_port(1,0);
            268 &&& 511: do_get_eg_fp_port(2,0);
            276 &&& 511: do_get_eg_fp_port(3,0);
            284 &&& 511: do_get_eg_fp_port(4,0);
            292 &&& 511: do_get_eg_fp_port(5,0);
            300 &&& 511: do_get_eg_fp_port(6,0);
            308 &&& 511: do_get_eg_fp_port(7,0);
            316 &&& 511: do_get_eg_fp_port(8,0);
            56 &&& 511: do_get_eg_fp_port(9,0);
            48 &&& 511: do_get_eg_fp_port(10,0);
            40 &&& 511: do_get_eg_fp_port(11,0);
            32 &&& 511: do_get_eg_fp_port(12,0);
            24 &&& 511: do_get_eg_fp_port(13,0);
            16 &&& 511: do_get_eg_fp_port(14,0);
            8 &&& 511: do_get_eg_fp_port(15,0);
            0 &&& 511: do_get_eg_fp_port(16,0);
            4 &&& 511: do_get_eg_fp_port(17,0);
            12 &&& 511: do_get_eg_fp_port(18,0);
            20 &&& 511: do_get_eg_fp_port(19,0);
            28 &&& 511: do_get_eg_fp_port(20,0);
            36 &&& 511: do_get_eg_fp_port(21,0);
            44 &&& 511: do_get_eg_fp_port(22,0);
            52 &&& 511: do_get_eg_fp_port(23,0);
            60 &&& 511: do_get_eg_fp_port(24,0);
            312 &&& 511: do_get_eg_fp_port(25,0);
            304 &&& 511: do_get_eg_fp_port(26,0);
            296 &&& 511: do_get_eg_fp_port(27,0);
            288 &&& 511: do_get_eg_fp_port(28,0);
            272 &&& 511: do_get_eg_fp_port(29,0);
            280 &&& 511: do_get_eg_fp_port(30,0);
            256 &&& 511: do_get_eg_fp_port(31,0);
            264 &&& 511: do_get_eg_fp_port(32,0);
            64 &&& 511: do_get_eg_fp_port(33,0);

            // 32Q Super Montara platform, 100G recirc ports only:
            184 &&& 511: do_get_eg_fp_port(1,0);
            176 &&& 511: do_get_eg_fp_port(2,0);
            168 &&& 511: do_get_eg_fp_port(3,0);
            160 &&& 511: do_get_eg_fp_port(4,0);
            152 &&& 511: do_get_eg_fp_port(5,0);
            144 &&& 511: do_get_eg_fp_port(6,0);
            136 &&& 511: do_get_eg_fp_port(7,0);
            128 &&& 511: do_get_eg_fp_port(8,0);
            132 &&& 511: do_get_eg_fp_port(9,0);
            140 &&& 511: do_get_eg_fp_port(10,0);
            148 &&& 511: do_get_eg_fp_port(11,0);
            156 &&& 511: do_get_eg_fp_port(12,0);
            164 &&& 511: do_get_eg_fp_port(13,0);
            172 &&& 511: do_get_eg_fp_port(14,0);
            180 &&& 511: do_get_eg_fp_port(15,0);
            188 &&& 511: do_get_eg_fp_port(16,0);
            440 &&& 511: do_get_eg_fp_port(17,0);
            432 &&& 511: do_get_eg_fp_port(18,0);
            424 &&& 511: do_get_eg_fp_port(19,0);
            416 &&& 511: do_get_eg_fp_port(20,0);
            408 &&& 511: do_get_eg_fp_port(21,0);
            400 &&& 511: do_get_eg_fp_port(22,0);
            392 &&& 511: do_get_eg_fp_port(23,0);
            384 &&& 511: do_get_eg_fp_port(24,0);
            388 &&& 511: do_get_eg_fp_port(25,0);
            396 &&& 511: do_get_eg_fp_port(26,0);
            404 &&& 511: do_get_eg_fp_port(27,0);
            412 &&& 511: do_get_eg_fp_port(28,0);
            420 &&& 511: do_get_eg_fp_port(29,0);
            428 &&& 511: do_get_eg_fp_port(30,0);
            436 &&& 511: do_get_eg_fp_port(31,0);
            444 &&& 511: do_get_eg_fp_port(32,0);
        }
    }
    apply {
        egress_get_fp_port_tbl.apply();
    }
}
# 125 "pktgen9_16.p4" 2
# 1 "g_pkt_cntr.p4" 1
/*------------------------------------------------------------------------
    g_pkt_cntr.p4 - Count global packets in egress pipeline per stream and port. 
                  - Implement bursts by counting packets to burst size.
                    Indices larger than burst size are dropped.

    Copyright (C) 2019 by Keysight Technologies
    All Rights Reserved.
*-----------------------------------------------------------------------*/

  control process_load_burst_pkt_cntr(inout header_t hdr,
          inout egress_metadata_t eg_md,
          in egress_intrinsic_metadata_t eg_intr_md) {

    @name(".do_load_burst_pkt_cntr_counter_params")
    action do_load_burst_pkt_cntr_counter_params(bit<32> max_val) {
        eg_md.burst_pkt_cntr.max = max_val;
        eg_md.burst_mode = 1w1;
    }

    @Feature(name="BurstPktCntrParams", block=counter_udf, service=Udf, service_id=BurstPktCntrParams, display_name="Udf Burst Packet Counter Parameters")

    @Api(label="Udf Burst Packet Counter Parameters")
    @brief("Udf Burst Packet Counter Parameters")
    @description("Udf Burst Packet Counter Parameters, one set per port/stream")
    @name(".load_burst_pkt_cntr_params_tbl")
    table load_burst_pkt_cntr_params_tbl {
        actions = {
            do_load_burst_pkt_cntr_counter_params;
        }
        key = {
             hdr.big_sig_br_md.stream: ternary
                                      @brief("Stream number")
                                      @Api(label="Stream number",format="dec");
            eg_intr_md.egress_port: ternary
                                      @brief("Egress Port")
                                      @Api(label="Egress port number (dataplane)",format="dec");
        }
        size = 1024;
    }
    apply {
        load_burst_pkt_cntr_params_tbl.apply();
    }
}


@name(".g_pkt_cntr_reg") Register<bit<16>,bit<8>>(32w1024) g_pkt_cntr_reg;

control process_incr_g_pkt_cntr(inout header_t hdr, inout egress_metadata_t eg_md) {
    @name(".g_pkt_cntr_salu")
    RegisterAction<bit<16>, bit<32>, bit<16>>(g_pkt_cntr_reg) g_pkt_cntr_salu = {
        void apply(inout bit<16> value, out bit<16> rv) {
            rv = 16w0;
            bit<16> in_value;
            in_value = value;
            rv = in_value;
            if (in_value < eg_md.g_pkt_cntr_max) {
                value = 16w1 + in_value;
            }
            if (!(in_value < eg_md.g_pkt_cntr_max)) {
                value = (bit<16>)0;
            }
        }
    };
    @name(".do_g_pkt_cntr")
    action do_g_pkt_cntr() {
        eg_md.g_pkt_cntr_value = g_pkt_cntr_salu.execute((bit<32>)eg_md.port_stream_index);
    }

    @name(".g_pkt_cntr_tbl")
    table g_pkt_cntr_tbl {
        actions = {
            do_g_pkt_cntr;
        }
        size = 1;
        default_action = do_g_pkt_cntr();
    }
    apply {
        g_pkt_cntr_tbl.apply();
    }
}

@name(".burst_pkt_cntr_reg") Register<bit<32>,bit<16>>(32w1024) burst_pkt_cntr_reg;

control process_incr_burst_pkt_cntr(inout header_t hdr, inout egress_metadata_t eg_md) {
    @name(".burst_pkt_cntr_salu")
    RegisterAction<bit<32>, bit<32>, bit<32>>(burst_pkt_cntr_reg) burst_pkt_cntr_salu = {
        void apply(inout bit<32> value, out bit<32> rv) {
            rv = 32w0;
            bit<32> alu_hi = 32w0;
            bit<32> in_value;
            in_value = value;
            if (in_value < eg_md.burst_pkt_cntr.max) {
                alu_hi = (bit<32>)0;
            }
            if (!(in_value < eg_md.burst_pkt_cntr.max)) {
                alu_hi = (bit<32>)1;
            }
            if (in_value < eg_md.burst_pkt_cntr.max) {
                value = 32w1 + in_value;
            }
            if (!(in_value < eg_md.burst_pkt_cntr.max)) {
                value = in_value;
            }
            rv = alu_hi;
        }
    };
    @name("._nop") action _nop() {
    }
    @name(".do_burst_pkt_cntr")
    action do_burst_pkt_cntr() {
        eg_md.burst_pkt_cntr.drop = (bit<1>)burst_pkt_cntr_salu.execute((bit<32>)eg_md.port_stream_index);
    }

    @name(".burst_pkt_cntr_tbl")
    table burst_pkt_cntr_tbl {
        actions = {
            _nop;
            do_burst_pkt_cntr;
        }
        key = {
            eg_md.burst_mode: exact;
        }
        size = 2;
        // default_action = _nop(); OBSOLETE - left for reference, delete later
        // Replace default action & control-plane programming with const entries:
          const entries = {
            0: _nop();
            1: do_burst_pkt_cntr();
        }
    }
    apply {
        burst_pkt_cntr_tbl.apply();
    }
}

control process_burst_drops(inout header_t hdr, inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {
    @name(".do_burst_drop")
    action do_burst_drop() {
        eg_intr_md_for_dprsr.drop_ctl = 0x1;
    }

    @name(".burst_drop_tbl")
    table burst_drop_tbl {
        actions = {
            do_burst_drop;
        }
        size = 1;
        default_action = do_burst_drop();
    }
    apply {
        burst_drop_tbl.apply();
    }
}

  control process_load_g_pkt_cntr(inout header_t hdr,
          inout egress_metadata_t eg_md,
          in egress_intrinsic_metadata_t eg_intr_md) {
    @name(".do_load_g_pkt_cntr_counter_params")
    action do_load_g_pkt_cntr_counter_params(bit<16> max_val) {

        eg_md.g_pkt_cntr_max = max_val;
    }

    @Feature(name="GlobalPktCntrParams", block=counter_udf, service=Udf, service_id=GlobalPktCntrParams, display_name="Udf Global Packet Counter Parameters")

    @Api(label="Udf Global Packet Counter Parameters")
    @brief("Udf Global Packet Counter Parameters")
    @description("Udf Global Packet Counter Parameters, one set per port/stream")
    @name(".load_g_pkt_cntr_params_tbl")
    table load_g_pkt_cntr_params_tbl {
        actions = {
            do_load_g_pkt_cntr_counter_params;
        }
        key = {
             hdr.big_sig_br_md.stream: ternary
                                      @brief("Stream number")
                                      @Api(label="Stream number",format="dec");
            eg_intr_md.egress_port: ternary
                                      @brief("Egress Port")
                                      @Api(label="Egress port number (dataplane)",format="dec");
        }
        size = 1024;
        default_action = do_load_g_pkt_cntr_counter_params(max_val = 0);
    }
    apply {
        load_g_pkt_cntr_params_tbl.apply();
    }
}
# 126 "pktgen9_16.p4" 2
# 1 "ig_port_fwd.p4" 1
/*------------------------------------------------------------------------
    ig_port_fwd.p4 - Module to modify ingress metadata to route frames
    Specifies either unicast port, multicast group, or drop
    This is used to routes frames from the packet generator ports to the recirculation ports.
    This is also used to route frames from the recirculation ports to the front panel ports

    Copyright (C) 2019 by Keysight Technologies
    All Rights Reserved.
*-----------------------------------------------------------------------*/
control process_pktgen_port_forwarding(inout header_t hdr,
            in ingress_intrinsic_metadata_t ig_intr_md,
            inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,
            inout ingress_intrinsic_metadata_for_tm_t ig_tm_md) {
    @Api(label="Drop Packet")
    @brief("Drop Packet")
    @name(".do_drop")
    @alias("drop")
    action do_drop() {
        ig_dprsr_md.drop_ctl = 0x1;
    }

    @brief("Set egress forwarding port and traffic queue")
    @name("._set_eg_port")
    action _set_eg_port(bit<9> eg_port) {
        ig_tm_md.ucast_egress_port = eg_port;
        ig_tm_md.qid = (QueueId_t)hdr.big_sig_br_md.stream;
    }

    @brief("Unicast to port")
    @description("Set egress forwarding port specified by table entry; TM queue is implicitly assigned the same value as the stream")

    @Api(label="Unicast to port")
    @name(".do_set_unicast")
    @alias("unicast")
    action do_set_unicast(
      @brief("Egress Port")
      @description ("Egress port specification")
      @Api(label=Port,format="dec")
      bit<9> eg_port)
    {
        _set_eg_port(eg_port);
    }


    // helper function, gets compiled out
    // Set mcast metadata and implicitly set unicast port to drop
    action _set_general_md(bit<16> rid, bit<16> xid, bit<9> yid, bit<13> h1, bit<13> h2) {
        ig_tm_md.rid = rid;
        ig_tm_md.level1_exclusion_id = xid;
        ig_tm_md.level2_exclusion_id = yid;
        ig_tm_md.level1_mcast_hash = h1;
        ig_tm_md.level2_mcast_hash = h2;
        _set_eg_port(9w511);
    }

// set mcast level 1 metadata including mgid and generic mc
@brief("Set packet multicast group ID and other params")
@description("Set packet multicast group params: mgid1, rid, xid, yid, h1, h2; must be configured in the PRE")
@name(".do_set_mcast1_md")
@alias("multicast")
action do_set_mcast1_md(
        @Api(label="Mgid1",format="dec")
        @brief("Multicast Group ID 1")
        @description("Send this packet to specified multicast group")
        bit<16> mgid,

        @Api(label="RID",format="dec")
        @brief("Replication ID")
        @description("ID for a specific replication instance")
        bit<16> rid,

        @Api(label="L1 XID",format="dec")
        @brief("Level 1 Multicast Exclusion ID")
        @description("Level 1 Multicast Exclusion ID; do not perform Level 1 replication to these ports")
        bit<16> xid,

        @Api(label="L2 YID",format="dec")
        @brief("Level 2 Multicast Exclusion ID")
        @description("Level 2 Multicast Exclusion ID; do not perform Level 2 replication to these ports")
        bit<9> yid,

        @Api(label="Hash1",format="hex")
        @brief("Hash 1 entropy source for multicast")
        @brief("Hash 1 entropy source for multicast")
        bit<13> h1,

        @Api(label="Hash2",format="hex")
        @brief("Hash 2 entropy source for multicast")
        @brief("Hash 2 entropy source for multicast")
        bit<13> h2
    ) {
        ig_tm_md.mcast_grp_a = mgid;
        _set_general_md(rid, xid, yid, h1, h2);
    }

    @brief("Layer-1 port/stream forwarding table; drop, unicast or multicast.")
    @description("Layer-1 port/stream forwarding table; drop, unicast or multicast based on port and stream number.")
    @Feature(name="L1Fwding", block=ig_port_fwd, service=Fwding, service_id=PortStreamFwding,
        display_name="Port/Stream Forwarding Table")
    @Api(label="Port/Stream Forwarding Table")
    @name(".ig_port_tbl")
    table ig_port_tbl {
        actions = {
            @Api(label="Drop") do_drop;
            @Api(label="Unicast") do_set_unicast;
            @Api(label="Multicast") do_set_mcast1_md;
        }
        key = {
            hdr.big_sig_br_md.stream : ternary
                                      @brief("Stream number")
                                      @Api(label="Stream number",format="dec");
            ig_intr_md.ingress_port : ternary
                                      @brief("Logical datapane port number")
                                      // optimum display format is in a ront-panel numbering scheme e.g. "1/1"
                                      @Api(label="Rx Port",format=dec,xform_format="fp_ports",wr_xform="fp_to_dp_port",rd_xform="dp_to_fp_port");
        }
        size = 2048;
    }

    @brief("Layer-1 port/stream recirculation forwarding table; unicast or nop.")
    @description("Layer-1 port/stream recirculation table; forward selected port/steam to unicast port")
    @Feature(name="L1RecircFwding", block=ig_port_fwd, service=Fwding, service_id=PortStreamRecircFwding,
        display_name="Port/Stream Recirculation Forwarding Table")
    @Api(label="Port/Stream Recirculation Forwarding Table")
    @name(".ig_recirc_port_tbl")
    table ig_recirc_port_tbl {
        actions = {
            @Api(label="Unicast") do_set_unicast;
        }
        key = {
            hdr.big_sig_br_md.stream : ternary
                                      @brief("Stream number")
                                      @Api(label="Stream number",format="dec");
            ig_intr_md.ingress_port : ternary
                                      @brief("Logical datapane port number")
                                      // optimum display format is in a ront-panel numbering scheme e.g. "1/1"
                                      @Api(label="Rx Port",format=dec,xform_format="fp_ports",wr_xform="fp_to_dp_port",rd_xform="dp_to_fp_port");
        }
        size = 1024;
    }

    apply {
        ig_port_tbl.apply();
        ig_recirc_port_tbl.apply();
    }
}

control process_common_drop(inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md) {

    @brief("Drop Packet")
    @description("Mark packet for drop")
    @name(".common_drop_pkt")
    action common_drop_pkt() {
        ig_dprsr_md.drop_ctl = 0x1;
    }

    @brief("Wrapper for action common_drop_pkt()")
    @description("Wrapper for action common_drop_pkt()")
    @name(".common_drop_tbl")
    table common_drop_tbl {
      actions = {
          common_drop_pkt;
      }
      size = 1;
      default_action = common_drop_pkt();
    }

    apply {
        common_drop_tbl.apply();
    }
}
# 127 "pktgen9_16.p4" 2
# 1 "ig_stats.p4" 1
/*------------------------------------------------------------------------
    ig_stats.p4 - Module to compute statistics for ingress ports.
    Computes receive port and PGID flow statistics.
    Port statistics include protocol statistics
    Implements bank switching for Tx/Rx Sync.

    Copyright (C) 2019 by Keysight Technologies
    All Rights Reserved.
*-----------------------------------------------------------------------*/

control process_ig_port_stats(inout header_t hdr, in ingress_intrinsic_metadata_t ig_intr_md, in ingress_intrinsic_metadata_from_parser_t ig_prsr_md, inout ingress_metadata_t ig_md) {
    @Feature(name="RxPortStats", block=eg_port_stats, service=Stats, service_id=RxPortStats, index=port,
    display_name="Rx Port Stats", display_cols="Port|RxBytes|RxPackets",col_units="|bytes|packets")
    @Api(index=port, label="Rx Port Stats", col_labels="Port|RxBytes|RxPackets",col_units="|bytes|packets")
    @brief("Ingress port stats counter ")
    @description("Ingress port stats counter, count all ingress port stats regardless of bank select")
    @name(".ig_port_stats_cntrA")
    Counter<bit<32>,bit<9>>(32w512,CounterType_t.PACKETS_AND_BYTES) ig_port_stats_cntrA;

    @Feature(name="RxChkSumErrProtoStats", block=ig_port_stats, service=Stats, service_id=RxChkSumErrProtoStats, index=port,
    display_name="Rx Checksum Error Stats", display_cols="Port|RxChkSumErrBytes|RxChkSumErrPackets",col_units="|bytes|packets")
    @Api(index=port, label="Rx Checksum Error Stats", col_labels="Port|RxErrBytes|RxErrPackets",col_units="|bytes|packets")
    @brief("Ingress port Checksum Error protocol stats counter")
    @description("Ingress port Checksum Error protocol stats counter, counts Checksum Error packets and bytes on each ingress port")
    @name(".ig_port_stats_cntr_checksum_errors")
    Counter<bit<32>,bit<9>>(32w512,CounterType_t.PACKETS_AND_BYTES) ig_port_stats_cntr_checksum_errors;

    @Feature(name="RxIPv4ProtoStats", block=ig_port_stats, service=Stats, service_id=RxIPv4ProtoStats, index=port,
    display_name="Rx IPv4 Stats", display_cols="Port|RxIPv4Bytes|RxIPv4Packets",col_units="|bytes|packets")
    @Api(index=port, label="Rx IPv4 Stats", col_labels="Port|TxBytes|TxPackets",col_units="|bytes|packets")
    @brief("Ingress port IPv4 protocol stats counter")
    @description("Ingress port IPv4 protocol stats counter, counts IPv4 packets and bytes on each ingress port")
    @name(".ig_port_ipv4_stats_cntrA")
    Counter<bit<32>,bit<9>>(32w512,CounterType_t.PACKETS_AND_BYTES) ig_port_ipv4_stats_cntrA;

    @Feature(name="RxIPv6ProtoStats", block=ig_port_stats, service=Stats, service_id=RxIPv6ProtoStats, index=port,
    display_name="Rx IPv6 Stats", display_cols="Port|RxIPv6Bytes|RxIPv6Packets",col_units="|bytes|packets")
    @Api(index=port, label="Rx IPv6 Stats", col_labels="Port|TxBytes|TxPackets",col_units="|bytes|packets")
    @brief("Ingress port IPv6 protocol stats counter")
    @description("Ingress port IPv6 protocol stats counter, counts IPv6 packets and bytes on each ingress port")
    @name(".ig_port_ipv6_stats_cntrA")
    Counter<bit<32>,bit<9>>(32w512,CounterType_t.PACKETS_AND_BYTES) ig_port_ipv6_stats_cntrA;

    @Feature(name="RxQinQProtoStats", block=ig_port_stats, service=Stats, service_id=RxQinQProtoStats, index=port,
    display_name="Rx QinQ Stats", display_cols="Port|RxQinQBytes|RxQinQPackets",col_units="|bytes|packets")
    @Api(index=port, label="Rx QinQ Stats", col_labels="Port|TxBytes|TxPackets",col_units="|bytes|packets")
    @brief("Ingress port QinQ protocol stats counter")
    @description("Ingress port QinQ protocol stats counter, counts QinQ packets and bytes on each ingress port")
    @name(".ig_port_qinq_stats_cntrA")
    Counter<bit<32>,bit<9>>(32w512,CounterType_t.PACKETS_AND_BYTES) ig_port_qinq_stats_cntrA;

    @Feature(name="RxTCPProtoStats", block=ig_port_stats, service=Stats, service_id=RxTCPProtoStats, index=port,
    display_name="Rx TCP Stats", display_cols="Port|RxTCPBytes|RxTCPPackets",col_units="|bytes|packets")
    @Api(index=port, label="Rx TCP Stats", col_labels="Port|TxBytes|TxPackets",col_units="|bytes|packets")
    @brief("Ingress port TCP protocol stats counter")
    @description("Ingress port TCP protocol stats counter, counts TCP packets and bytes on each ingress port")
    @name(".ig_port_tcp_stats_cntrA")
    Counter<bit<32>,bit<9>>(32w512,CounterType_t.PACKETS_AND_BYTES) ig_port_tcp_stats_cntrA;

    @Feature(name="RxUDPProtoStats", block=ig_port_stats, service=Stats, service_id=RxUDPProtoStats, index=port,
    display_name="Rx UDP Stats", display_cols="Port|RxUDPBytes|RxUDPPackets",col_units="|bytes|packets")
    @Api(index=port, label="Rx UDP Stats", col_labels="Port|TxBytes|TxPackets",col_units="|bytes|packets")
    @brief("Ingress port UDP protocol stats counter")
    @description("Ingress port UDP protocol stats counter, counts UDP packets and bytes on each ingress port")
    @name(".ig_port_udp_stats_cntrA")
    Counter<bit<32>,bit<9>>(32w512,CounterType_t.PACKETS_AND_BYTES) ig_port_udp_stats_cntrA;

    @Feature(name="RxVlanProtoStats", block=ig_port_stats, service=Stats, service_id=RxVlanProtoStats, index=port,
    display_name="Rx Vlan Stats", display_cols="Port|RxVlanBytes|RxVlanPackets",col_units="|bytes|packets")
    @Api(index=port, label="Rx Vlan Stats", col_labels="Port|TxBytes|TxPackets",col_units="|bytes|packets")
    @brief("Ingress port Vlan protocol stats counter")
    @description("Ingress port Vlan protocol stats counter, counts Vlan packets and bytes on each ingress port")
    @name(".ig_port_vlan_stats_cntrA")
    Counter<bit<32>,bit<9>>(32w512,CounterType_t.PACKETS_AND_BYTES) ig_port_vlan_stats_cntrA;

    @Feature(name="RxProtoStats", block=ig_port_stats, service=Stats, service_id="Rx.*ProtoStats.*", index=port,
    display_name="All Rx Protocol Stats")
    @Api(index=port, label="All Rx Protocol Stats")
    @brief("Fake entity - not instantatiated, do not attempt to access except via service_id")
    @description("Fake entity to receive annotation for service_id regex")
    @name(".ig_fake_protocol_stats_cntr")
    Counter<bit<32>,bit<9>>(32w512,CounterType_t.PACKETS_AND_BYTES) ig_fake_protocol_stats_cntr;

    @name(".do_ig_port_ipv4_statsA")
    action do_ig_port_ipv4_statsA() {
        ig_port_ipv4_stats_cntrA.count(ig_intr_md.ingress_port);
    }
    @name(".do_ig_port_ipv6_statsA")
    action do_ig_port_ipv6_statsA() {
        ig_port_ipv6_stats_cntrA.count(ig_intr_md.ingress_port);
    }
    @name(".do_ig_port_qinq_statsA")
    action do_ig_port_qinq_statsA() {
        ig_port_qinq_stats_cntrA.count(ig_intr_md.ingress_port);
    }
    @name(".do_ig_port_statsA")
    action do_ig_port_statsA() {
        ig_port_stats_cntrA.count(ig_intr_md.ingress_port);
    }
    @name(".do_ig_port_stats_checksum_errors")
    action do_ig_port_stats_checksum_errors() {
        ig_port_stats_cntr_checksum_errors.count(ig_intr_md.ingress_port);
    }
    @name(".do_ig_port_tcp_statsA")
    action do_ig_port_tcp_statsA() {
        ig_port_tcp_stats_cntrA.count(ig_intr_md.ingress_port);
    }
    @name(".do_ig_port_udp_statsA")
    action do_ig_port_udp_statsA() {
        ig_port_udp_stats_cntrA.count(ig_intr_md.ingress_port);
    }
    @name(".do_ig_port_vlan_statsA")
    action do_ig_port_vlan_statsA() {
        ig_port_vlan_stats_cntrA.count(ig_intr_md.ingress_port);
    }
    @name(".ig_port_ipv4_statsA_tbl")
    table ig_port_ipv4_statsA_tbl {
        actions = {
            do_ig_port_ipv4_statsA;
        }
        size = 1;
        default_action = do_ig_port_ipv4_statsA();
    }
    @name(".ig_port_ipv6_statsA_tbl")
    table ig_port_ipv6_statsA_tbl {
        actions = {
            do_ig_port_ipv6_statsA;
        }
        size = 1;
        default_action = do_ig_port_ipv6_statsA();
    }
    @name(".ig_port_qinq_statsA_tbl")
    table ig_port_qinq_statsA_tbl {
        actions = {
            do_ig_port_qinq_statsA;
        }
        size = 1;
        default_action = do_ig_port_qinq_statsA();
    }
    @name(".ig_port_statsA_tbl")
    table ig_port_statsA_tbl {
        actions = {
            do_ig_port_statsA;
        }
        size = 1;
        default_action = do_ig_port_statsA();
    }
    @name(".ig_port_stats_checksum_errors_tbl")
    table ig_port_stats_checksum_errors_tbl {
        actions = {
            do_ig_port_stats_checksum_errors;
        }
        size = 1;
        default_action = do_ig_port_stats_checksum_errors();
    }
    @name(".ig_port_tcp_statsA_tbl")
    table ig_port_tcp_statsA_tbl {
        actions = {
            do_ig_port_tcp_statsA;
        }
        size = 1;
        default_action = do_ig_port_tcp_statsA();
    }
    @name(".ig_port_udp_statsA_tbl")
    table ig_port_udp_statsA_tbl {
        actions = {
            do_ig_port_udp_statsA;
        }
        size = 1;
        default_action = do_ig_port_udp_statsA();
    }
    @name(".ig_port_vlan_statsA_tbl")
    table ig_port_vlan_statsA_tbl {
        actions = {
            do_ig_port_vlan_statsA;
        }
        size = 1;
        default_action = do_ig_port_vlan_statsA();
    }
    apply {
        ig_port_statsA_tbl.apply();
        if (hdr.vlan_tag[0].isValid() && hdr.vlan_tag[1].isValid()) {
            ig_port_qinq_statsA_tbl.apply();
        } else {
            if (hdr.vlan_tag[0].isValid()) {
                ig_port_vlan_statsA_tbl.apply();
            }
        }
        if (hdr.outer_ipv4.isValid()) {
            ig_port_ipv4_statsA_tbl.apply();
        }
        if (hdr.outer_ipv6.isValid()) {
            ig_port_ipv6_statsA_tbl.apply();
        }
        if (hdr.outer_udp.isValid()) {
            ig_port_udp_statsA_tbl.apply();
        }
        if (hdr.outer_tcp.isValid()) {
            ig_port_tcp_statsA_tbl.apply();
        }
        if (ig_prsr_md.parser_err & 16w0x1000 == 16w0x1000) {
            ig_port_stats_checksum_errors_tbl.apply();
        }
    }
}

control process_ig_pgid_statsA(inout header_t hdr, inout ingress_metadata_t ig_md) {
    @Feature(name="RxPgidStatsA", block=eg_port_stats, service=Stats, service_id=RxPgidStatsA, index=pgid,
    display_name="Rx PGID Stats A", display_cols="PGID|RxBytesA|RxPacketsA",col_units="|bytes|packets")
    @Api(index=pgid, label="Rx PGID Stats A", col_labels="PGID|RxBytes|RxPackets",col_units="|bytes|packets")
    @brief("Ingress PGID stats counter Bank A")
    @description("Ingress PGID stats counter Bank A, counts packets and bytes per PGID when bank select=0")
    @name(".ig_pgid_stats_cntrA")
    Counter<bit<32>,bit<15>>(32w32768,CounterType_t.PACKETS_AND_BYTES) ig_pgid_stats_cntrA;

    @name(".do_ig_pgid_statsA")
    action do_ig_pgid_statsA() {
        ig_pgid_stats_cntrA.count(ig_md.port_pgid_index);
    }
    @name(".ig_pgid_statsA_tbl")
    table ig_pgid_statsA_tbl {
        actions = {
            do_ig_pgid_statsA;
        }
        key = {
            hdr.bridged_md.bank_select: exact;
            ig_md.rx_instrum : exact;
        }
        size = 1;
    }
    apply {
        ig_pgid_statsA_tbl.apply();
    }
}

control process_ig_pgid_statsB(inout header_t hdr, inout ingress_metadata_t ig_md) {
    @Feature(name="RxPgidStatsB", block=eg_port_stats, service=Stats, service_id=RxPgidStatsB, index=pgid,
    display_name="Rx PGID Stats B", display_cols="PGID|RxBytesB|RxPacketsB",col_units="|bytes|packets")
    @Api(index=pgid, label="Rx PGID Stats B", col_labels="PGID|RxBytes|RxPackets",col_units="|bytes|packets")
    @brief("Ingress PGID stats counter Bank B")
    @description("Ingress PGID stats counter Bank B, counts packets and bytes per PGID when bank select=1")
    @name(".ig_pgid_stats_cntrB")
    Counter<bit<32>,bit<15>>(32w32768,CounterType_t.PACKETS_AND_BYTES) ig_pgid_stats_cntrB;

    @name(".do_ig_pgid_statsB")
    action do_ig_pgid_statsB() {
        ig_pgid_stats_cntrB.count(ig_md.port_pgid_index);
    }
    @name(".ig_pgid_statsB_tbl")
    table ig_pgid_statsB_tbl {
        actions = {
            do_ig_pgid_statsB;
        }
        key = {
            hdr.bridged_md.bank_select: exact;
            ig_md.rx_instrum : exact;
        }
        size = 1;
    }
    apply {
        ig_pgid_statsB_tbl.apply();
    }
}
# 128 "pktgen9_16.p4" 2
# 1 "imix.p4" 1
/*------------------------------------------------------------------------
    imix.p4 - Module to implement IMIX per stream through truncation.
    Computes random number and range matches on number to select a mirror session
    Control plane configures a mirror session per frame size in mix.
    Control plane then computes ranges for each frame size based on the weights in the mix.

    Copyright (C) 2019 by Keysight Technologies
    All Rights Reserved.
*-----------------------------------------------------------------------*/

control process_generate_random_number(inout header_t hdr, inout ingress_metadata_t ig_md) {
    Random<bit<16>>() rand16;
    @name(".generate_random_number") action generate_random_number() {
        ig_md.imix.random = rand16.get();
    }
    @name(".generate_random_number_tbl") table generate_random_number_tbl {
        actions = {
            generate_random_number;
        }
        size = 1;
        default_action = generate_random_number();
    }
    apply {
        generate_random_number_tbl.apply();
    }
}
# 129 "pktgen9_16.p4" 2
# 1 "pcie_cpu_port.p4" 1
/*------------------------------------------------------------------------
    pcie_cpu_port.p4 - Module to extract PCIE CPU Port from control plane and input into metadata.
                       This is needed because each Tofino chip variant has a different PCIE CPU port.
                       Module handles switching of frame between PCPU and PCIE CPU Port.
                       This involves stripping the fabric header on frame from the PCPU and inserting fabric header
                       on frame to the PCPU.

    Copyright (C) 2019 by Keysight Technologies
    All Rights Reserved.
*-----------------------------------------------------------------------*/

control process_load_cpu_parameters(inout header_t hdr, in ingress_intrinsic_metadata_t ig_intr_md, inout ingress_metadata_t ig_md) {
    @name("._nop") action _nop() {
    }

    @brief("Enable Ingress-to-CPU port fwding and assign ingress port")
    @description("Enable Ingress-to-CPU port fwding and assign ingress port")
    @name(".load_cpu_enabled_parameter")
    action load_cpu_enabled_parameter() {
      ig_md.pcie_cpu_port_enabled = 1w1;
    }


    @brief("Layer-1 ingress to CPU port forwarding table")
    @description("Layer-1 ingress to CPU port forwarding table; select which ingress ports can fwd to CPU")
    @Feature(name="L1IgToCpuPortFwding", block=cpu_port_fwd, service=Fwding, service_id=L1IgToCpuPortFwding,
        display_name="Ingress to CPU Forwarding Table")
    @Api(label="Ingress to CPU Forwarding Table")
    @name(".load_cpu_enabled_parameter_tbl")
    table load_cpu_enabled_parameter_tbl {
        actions = {
            @Api(label="NOP") _nop;
            @Api(label="Fwd Enabled") load_cpu_enabled_parameter;
        }
        key = {
            ig_intr_md.ingress_port: ternary
                                      @brief("Logical datapane Ingress port number")
                                      // optimum display format is in a ront-panel numbering scheme e.g. "1/1"
                                      @Api(label="Rx Port",format=dec,xform_format="fp_ports",wr_xform="fp_to_dp_port",rd_xform="dp_to_fp_port");
        }
        default_action = _nop();
    }
    apply {
        load_cpu_enabled_parameter_tbl.apply();
    }
}

control process_cpu_fabric_hdr(inout header_t hdr,
            in egress_intrinsic_metadata_t eg_intr_md){

    @brief("Populate fabric header for packets bound to CPU")
    @description("Populate fabric header for packets bound to CPU")
    @name(".set_fabric_hdr")
    action set_fabric_hdr() {
        hdr.fabric_hdr.setValid();
    // Copy ingress port from mirror digest to fabric hdr






        hdr.fabric_hdr.devPort = (bit<16>)hdr.mirror_bridged_md.ingress_port;


        hdr.fabric_hdr.etherType = hdr.outer_eth.etherType;
        hdr.outer_eth.etherType = 0x9090;
    }

    @name("._nop") action _nop() {
    }


    @brief("Layer-1 egress to CPU port forwarding table")
    @description("Layer-1 egress to CPU port forwarding table; based on egress port populate fabric hdr to CPU")
    @Feature(name="L1EgToCpuFwding", block=cpu_port_fwd, service=Fwding, service_id=L1EgToCpuFwding,
        display_name="Egress to CPU Forwarding Table")
    @Api(label="Egress to CPU Forwarding Table")
    @name(".set_fabric_hdr_tbl")
    table set_fabric_hdr_tbl {
        actions = {
            set_fabric_hdr;
            _nop;
        }
        key = {
            eg_intr_md.egress_port: ternary
                                      @brief("Logical datapane Egress port number")
                                      // optimum display format is in a ront-panel numbering scheme e.g. "1/1"
                                      @Api(label="Tx Port",format=dec,xform_format="fp_ports",wr_xform="fp_to_dp_port",rd_xform="dp_to_fp_port");
        }
        size = 1;
        default_action = _nop();
    }

    apply {
        set_fabric_hdr_tbl.apply();
    }
}

control process_from_cpu_port_forwarding(inout header_t hdr,
            inout ingress_intrinsic_metadata_for_tm_t ig_tm_md
            ) {

    @name(".set_md_from_fabric_hdr")
    action set_md_from_fabric_hdr() {
        ig_tm_md.ucast_egress_port = (bit<9>)hdr.fabric_hdr.devPort;
        hdr.outer_eth.etherType = hdr.fabric_hdr.etherType;
        hdr.fabric_hdr.setInvalid();
    }

    @name(".select_egress_port_tbl")
    table select_egress_port_tbl {
        actions = {
            set_md_from_fabric_hdr;
        }
        size = 1;
        default_action = set_md_from_fabric_hdr();
    }

    apply {
        select_egress_port_tbl.apply();
    }
}

control process_to_cpu_port_forwarding(inout header_t hdr,
            inout ingress_metadata_t ig_md,
            in ingress_intrinsic_metadata_t ig_intr_md,
            inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md) {

    @name(".do_clone_to_cpu")
    action do_clone_to_cpu(MirrorId_t cpu_mirror_id) {
        ig_md.mirror_id = cpu_mirror_id;
        ig_md.is_mirror = 1;
        ig_dprsr_md.drop_ctl = 0x1;
    #if __TARGET_TOFINO__ == 1
        ig_dprsr_md.mirror_type = MIRROR_TYPE_I2E;
    #elif __TARGET_TOFINO__ >= 2
        ig_dprsr_md.mirror_type = (bit<4>) MIRROR_TYPE_I2E;
    #endif




        hdr.mirror_bridged_md.setValid();
        hdr.mirror_bridged_md.ingress_port = ig_intr_md.ingress_port;

    }

    @name(".send_to_cpu_tbl")
     table send_to_cpu_tbl {
      actions = {
          do_clone_to_cpu;
      }
      size = 1;
      default_action = do_clone_to_cpu(100);
  }

  apply {
      send_to_cpu_tbl.apply();
  }
}
# 130 "pktgen9_16.p4" 2
# 1 "prepop_hdrs.p4" 1
/*------------------------------------------------------------------------
    prepop_hdrs.p4 - Module to modify protocol fields via MAU.
    Specifies MAC and IP addresses to insert into Ethernet and IP headers.
    Removes the pktgen header which is prepended from pktgen.

    Copyright (C) 2019 by Keysight Technologies
    All Rights Reserved.
*-----------------------------------------------------------------------*/

  control process_prepopulate_hdr_g_reg(inout header_t hdr, in egress_intrinsic_metadata_t eg_intr_md) {
    @name(".do_prepopulate_ether_ip")
    action do_prepopulate_ether_ip(bit<8> dmac0, bit<8> dmac1, bit<8> dmac2, bit<8> dmac3, bit<8> dmac4, bit<8> dmac5,
                                   bit<8> smac0, bit<8> smac1, bit<8> smac2, bit<8> smac3, bit<8> smac4, bit<8> smac5,
                                   bit<32> dipv4, bit<32> sipv4) {
        hdr.outer_eth.dstAddr0 = dmac0;
        hdr.outer_eth.dstAddr1 = dmac1;
        hdr.outer_eth.dstAddr2 = dmac2;
        hdr.outer_eth.dstAddr3 = dmac3;
        hdr.outer_eth.dstAddr4 = dmac4;
        hdr.outer_eth.dstAddr5 = dmac5;
        hdr.outer_eth.srcAddr0 = smac0;
        hdr.outer_eth.srcAddr1 = smac1;
        hdr.outer_eth.srcAddr2 = smac2;
        hdr.outer_eth.srcAddr3 = smac3;
        hdr.outer_eth.srcAddr4 = smac4;
        hdr.outer_eth.srcAddr5 = smac5;





        hdr.outer_ipv4.dstAddr = dipv4;
        hdr.outer_ipv4.srcAddr = sipv4;
    }

    @Feature(name="PrepopulateEtherIp", block=counter_udf, service=Udf, service_id=PrepopulateEtherIp, display_name="UDF  Prepopulate static values Per Stream")

    @Api(label="UDF  Prepopulate static values Per Stream")
    @brief("UDF  Prepopulate static values Per Stream")
    @description("UUDF  Prepopulate static values Per Stream, one set per port/stream")
    @name(".eg_prepop_hdr_and_g_reg_tbl")
    table eg_prepop_hdr_and_g_reg_tbl {
        actions = {
            do_prepopulate_ether_ip;
        }
        key = {
            hdr.big_sig_br_md.stream: ternary
                                      @brief("Stream number")
                                      @Api(label="Stream number",format="dec");
            eg_intr_md.egress_port: ternary
                                      @brief("Egress Port")
                                      @Api(label="Egress port number (dataplane)",format="dec");
            hdr.bridged_md.is_pktgen: exact
                                      @brief("is_pktgen")
                                      @Api(label="Is this packet from packet generator",format="dec");
        }
        size = 1024;
    }
    apply {
        eg_prepop_hdr_and_g_reg_tbl.apply();
    }
}
# 131 "pktgen9_16.p4" 2
# 1 "rx_instrum.p4" 1
/*------------------------------------------------------------------------
    rx_instrum.p4 - Module to compute PGID register index for packet, and PGID counter index based on port indices
                    and PGID in frame

    Copyright (C) 2019 by Keysight Technologies
    All Rights Reserved.
*-----------------------------------------------------------------------*/


control process_rx_instrum(inout header_t hdr, in ingress_intrinsic_metadata_t ig_intr_md, inout ingress_metadata_t ig_md) {
    @name("._nop") action _nop() {
    }
    @name(".do_set_rx_instrum") action do_set_rx_instrum() {
        ig_md.rx_instrum = 1w1;
    }
    @name(".rx_instrum_tbl") table rx_instrum_tbl {
        actions = {
            _nop;
            do_set_rx_instrum;
        }
        key = {
            hdr.big_sig.sig1 : ternary;
            hdr.big_sig.sig2 : ternary;
            hdr.big_sig.sig3 : ternary;
            ig_intr_md.ingress_port: ternary;
        }
        size = 288;
        default_action = _nop();
    }
    apply {
        rx_instrum_tbl.apply();
    }
}
# 132 "pktgen9_16.p4" 2
# 1 "rx_latency.p4" 1
/*------------------------------------------------------------------------
    rx_latency.p4 - Module to compute timestamp deltas

    Copyright (C) 2019 by Keysight Technologies
    All Rights Reserved.
*-----------------------------------------------------------------------*/

control process_rx_latency(inout header_t hdr, in ingress_intrinsic_metadata_t ig_intr_md, in ingress_intrinsic_metadata_from_parser_t ig_prsr_md, inout ingress_metadata_t ig_md) {
    @name(".rx_latency_calc")
    action rx_latency_calc() {
        ig_md.latency = (int<32>)(bit<32>)ig_prsr_md.global_tstamp - (int<32>)(bit<32>)ig_md.rx_tstamp_calibrated;
    }
    @name(".rx_latency_store_overflow")
    action rx_latency_store_overflow(bit<32> lat_overflow) {
        ig_md.lat_overflow = lat_overflow;
    }
    @name(".rx_latency_calc_tbl")
    table rx_latency_calc_tbl {
        actions = {
            rx_latency_calc;
        }
        size = 1;
        default_action = rx_latency_calc();
    }
    @name(".rx_latency_store_overflow_tbl")
    table rx_latency_store_overflow_tbl {
        actions = {
            rx_latency_store_overflow;
        }
        size = 1;
        default_action = rx_latency_store_overflow(lat_overflow = 0);
    }
    apply {
        rx_latency_calc_tbl.apply();
        rx_latency_store_overflow_tbl.apply();
    }
}

control pack_port_pgid(inout header_t hdr, inout ingress_metadata_t ig_md) {
    Hash<bit<15>>(HashAlgorithm_t.IDENTITY) pack_port_pgid_hash;
    @name(".do_pack_port_pgid")
    action do_pack_port_pgid() {
        {
            ig_md.port_pgid_index = pack_port_pgid_hash.get({ ig_md.fp_port, hdr.instrum.pgid });;
        }
    }
    @name(".pack_port_pgid_tbl")
    table pack_port_pgid_tbl {
        actions = {
            do_pack_port_pgid;
        }
        size = 1;
        default_action = do_pack_port_pgid();
    }
    apply {
        pack_port_pgid_tbl.apply();
    }
}


control pack_pgid_pipe_port(inout header_t hdr, inout ingress_metadata_t ig_md) {
    Hash<bit<14>>(HashAlgorithm_t.IDENTITY) pack_pgid_pipe_port_hash;
    @name(".do_pack_pgid_pipe_port")
    action do_pack_pgid_pipe_port() {
        {
            ig_md.port_pgid_index = (bit<15>)pack_pgid_pipe_port_hash.get({ ig_md.fp_port, hdr.instrum.pgid }); // TODO check casting;
        }
    }
    @name(".pack_pgid_pipe_port_tbl")
    table pack_pgid_pipe_port_tbl {
        actions = {
            do_pack_pgid_pipe_port;
        }
        size = 1;
        default_action = do_pack_pgid_pipe_port();
    }
    apply {
        pack_pgid_pipe_port_tbl.apply();
    }
}

control process_abs_value_rx_latency(inout header_t hdr, inout ingress_metadata_t ig_md) {
    @name(".do_negate_dv")
    action do_negate_dv() {
        ig_md.lat_to_mem = 32w0 - (bit<32>)ig_md.latency;
    }
    @name(".do_no_negate_dv")
    action do_no_negate_dv() {
        ig_md.lat_to_mem = (bit<32>)ig_md.latency;
    }
    table rx_dv_abs_negate_tbl {
        actions = {
            do_negate_dv;
        }
        size = 1;
        default_action = do_negate_dv();
    }
    table rx_dv_abs_no_negate_tbl {
        actions = {
            do_no_negate_dv;
        }
        size = 1;
        default_action = do_no_negate_dv();
    }
    apply {
        if (ig_md.latency >= 0) { // TODO check math
            rx_dv_abs_no_negate_tbl.apply();
        } else {
            rx_dv_abs_negate_tbl.apply();
        }
    }
}

control process_value_rx_latency_overflow(inout header_t hdr, inout ingress_metadata_t ig_md) {
    @name(".do_rx_calc_lat_high_totA")
    action do_rx_calc_lat_high_totA() {
        ig_md.lat_to_mem_overflow = ig_md.lat_to_mem - ig_md.lat_overflow;
    }
    @name(".rx_lat_tot_high_detectA_tbl")
    table rx_lat_tot_high_detectA_tbl {
        actions = {
            do_rx_calc_lat_high_totA;
        }
        size = 1;
        default_action = do_rx_calc_lat_high_totA();
    }
    apply {
        rx_lat_tot_high_detectA_tbl.apply();
    }
}
control process_ig_lat_stats(inout header_t hdr, inout ingress_metadata_t ig_md) {

    @Feature(name="RxPgidFirstTstamp", block=ig_pgid_lat_stats, service=Stats, service_id=RxPgidFirstTstamp, index=pgid, display_name="Rx First Timestamp", display_cols="PGID|FirstTstamp",col_units="|nsec")

    @Api(index=pgid,label="Rx First Timestamp", col_labels="PGID|FirstTstamp",col_units="|nsec")
    @brief("Ingress first timestamp per PGID")
    @description("Ingress first timestamp per PGID; should clear between each test run")
    @name(".rx_first_stamp_reg")
    Register<reg_pair_t, bit<32>>(16384,{0,0}) rx_first_stamp_reg;

    @Feature(name="RxPgidLastTstamp", block=ig_pgid_lat_stats, service=Stats, service_id=RxPgidLastTstamp, index=pgid, display_name="Rx Last Timestamp", display_cols="PGID|LastTstamp",col_units="|nsec")

    @Api(index=pgid,label="Rx Last Timestamp", col_labels="PGID|LastTstamp",col_units="|nsec")
    @brief("Ingress Last timestamp per PGID")
    @description("Ingress Last timestamp per PGID; should clear between each test run")
    @name(".rx_last_stamp_reg")
    Register<reg_pair_t, bit<32>>(16384,{0,0}) rx_last_stamp_reg;

    @Feature(name="RxPgidMaxLat", block=ig_pgid_lat_stats, service=Stats, service_id=RxPgidMaxLat, index=pgid, display_name="Rx Max Latency", display_cols="PGID|MaxLat",col_units="|nsec")

    @Api(index=pgid,label="Rx Max Latency", col_labels="PGID|MaxLat",col_units="|nsec")
    @brief("PGID Max latency register")
    @description("PGID Max latency register, holds the maximum latency for a given flow")
    @name(".rx_lat_maxA_reg")
    Register<bit<32>,bit<16>>(16384) rx_lat_maxA_reg;

    @Feature(name="RxPgidMinLat", block=ig_pgid_lat_stats, service=Stats, service_id=RxPgidMinLat, index=pgid, display_name="Rx Min Latency", display_cols="PGID|MinLat",col_units="|nsec")

    @Api(index=pgid,label="Rx Min Latency", col_labels="PGID|MinLat",col_units="|nsec")
    @brief("PGID Min latency register")
    @description("PGID Min latency register, holds the minimum latency for a given flow")
    @name(".rx_lat_minA_reg")
    Register<bit<32>,bit<16>>(16384) rx_lat_minA_reg;

    @Feature(name="RxPgidTotLatA", block=ig_pgid_lat_stats, service=Stats, service_id=RxPgidTotLatA, index=pgid, display_name="Rx Tot Latency A", display_cols="PGID|TotLatHiA|TotLatLoA",col_units="|nsec*2^32|nsec")

    @Api(index=pgid,label="Rx Tot Latency A", col_labels="PGID|TotLatHiA|TotLatLoA",col_units="|nsec*2^32|nsec")
    @brief("PGID Tot latency register bank A")
    @description("PGID Tot latency register bank A, holds the minimum latency for a given flow;double-precision")
    @name(".rx_lat_totA_reg")
    Register<reg_pair_t, bit<32>>(16384,{0,0}) rx_lat_totA_reg;

    @Feature(name="RxPgidTotLatB", block=ig_pgid_lat_stats, service=Stats, service_id=RxPgidTotLatB, index=pgid, display_name="Rx Tot Latency B", display_cols="PGID|TotLatHiB|TotLatLoB",col_units="|nsec*2^32|nsec")

    @Api(index=pgid,label="Rx Tot Latency B", col_labels="PGID|TotLatHiB|TotLatLoB",col_units="|nsec*2^32|nsec")
    @brief("PGID Tot latency register bank B")
    @description("PGID Tot latency register bank B, holds the minimum latency for a given flow;double-precision")
    @name(".rx_lat_totB_reg")
    Register<reg_pair_t, bit<32>>(16384,{0,0}) rx_lat_totB_reg;

    // pseudo-feature to declare a regex and label for multiple stats
    @feature(name="LatencyStats", block=ig_pgid_lat_stats, service=Stats, service_id=".*Pgid.*(Lat|Tstamp).*", index=pgid, display_name="All Latency Stats")

    @brief("Fake entity - not instantatiated, do not attempt to access except via service_id")
    @description("Fake entity to receive annotation for service_id regex")
    Register<bit<32>,bit<32>>(32768, 0) rx_fake_latency_reg;

    @name(".lat_max_detectorA_salu")
    RegisterAction<bit<32>, bit<32>, bit<32>>(rx_lat_maxA_reg) lat_max_detectorA_salu = {
        void apply(inout bit<32> value) {
            bit<32> in_value;
            in_value = value;
            if (ig_md.lat_to_mem > in_value) {
                value = ig_md.lat_to_mem;
            }
            if (!(ig_md.lat_to_mem > in_value)) {
                value = in_value;
            }
        }
    };
    @name(".lat_min_detectorA_salu")
    RegisterAction<bit<32>, bit<32>, bit<32>>(rx_lat_minA_reg) lat_min_detectorA_salu = {
        void apply(inout bit<32> value) {
            bit<32> in_value;
            in_value = value;
            if (ig_md.lat_to_mem < in_value) {
                value = ig_md.lat_to_mem;
            }
            if (!(ig_md.lat_to_mem < in_value)) {
                value = in_value;
            }
        }
    };
    @name(".lat_tot_detectorA_salu")
    RegisterAction<reg_pair_t, bit<32>, bit<32>>(rx_lat_totA_reg) lat_tot_detectorA_salu = {
        void apply(inout reg_pair_t value) {
            reg_pair_t in_value;
            in_value = value;
            if (ig_md.lat_to_mem + in_value.lo <= 32w0x7fffffff) {
                value.hi = in_value.hi;
            }
            if (!(ig_md.lat_to_mem + in_value.lo <= 32w0x7fffffff)) {
                value.hi = in_value.hi + 32w1;
            }
            if (ig_md.lat_to_mem + in_value.lo <= 32w0x7fffffff) {
                value.lo = ig_md.lat_to_mem + in_value.lo;
            }
            if (!(ig_md.lat_to_mem + in_value.lo <= 32w0x7fffffff)) {
                value.lo = ig_md.lat_to_mem_overflow + in_value.lo;
            }
        }
    };
    @name(".lat_tot_detectorB_salu")
    RegisterAction<reg_pair_t, bit<32>, bit<32>>(rx_lat_totB_reg) lat_tot_detectorB_salu = {
        void apply(inout reg_pair_t value) {
            reg_pair_t in_value;
            in_value = value;
            if (ig_md.lat_to_mem + in_value.lo <= 32w0x7fffffff) {
                value.hi = in_value.hi;
            }
            if (!(ig_md.lat_to_mem + in_value.lo <= 32w0x7fffffff)) {
                value.hi = in_value.hi + 32w1;
            }
            if (ig_md.lat_to_mem + in_value.lo <= 32w0x7fffffff) {
                value.lo = ig_md.lat_to_mem + in_value.lo;
            }
            if (!(ig_md.lat_to_mem + in_value.lo <= 32w0x7fffffff)) {
                value.lo = ig_md.lat_to_mem_overflow + in_value.lo;
            }
        }
    };
    @name(".store_first_tstamp_salu")
    RegisterAction<reg_pair_t, bit<32>, bit<32>>(rx_first_stamp_reg) store_first_tstamp_salu = {
        void apply(inout reg_pair_t value) {
            reg_pair_t in_value;
            in_value = value;
            value.hi = ig_md.rx_packet_timestamp.upper;
            value.lo = ig_md.rx_packet_timestamp.lower;
        }
    };
    @name(".store_last_tstamp_salu")
    RegisterAction<reg_pair_t, bit<32>, bit<32>>(rx_last_stamp_reg) store_last_tstamp_salu = {
        void apply(inout reg_pair_t value) {
            reg_pair_t in_value;
            in_value = value;
            if (hdr.instrum.tstamp > in_value.lo) {
                value.hi = in_value.hi;
            }
            if (!(hdr.instrum.tstamp > in_value.lo)) {
                value.hi = in_value.hi + 32w1;
            }
            if (hdr.instrum.tstamp > in_value.lo) {
                value.lo = hdr.instrum.tstamp;
            }
            if (!(hdr.instrum.tstamp > in_value.lo)) {
                value.lo = hdr.instrum.tstamp;
            }
        }
    };
    @name(".do_rx_detect_lat_maxA")
    action do_rx_detect_lat_maxA() {
        lat_max_detectorA_salu.execute((bit<32>)ig_md.pgid_pipe_port_index);
    }
    @name(".do_rx_detect_lat_minA")
    action do_rx_detect_lat_minA() {
        lat_min_detectorA_salu.execute((bit<32>)ig_md.pgid_pipe_port_index);
    }
    @name(".do_rx_calc_lat_totA")
    action do_rx_calc_lat_totA() {
        lat_tot_detectorA_salu.execute((bit<32>)ig_md.pgid_pipe_port_index);
    }
    @name(".do_rx_calc_lat_totB")
    action do_rx_calc_lat_totB() {
        lat_tot_detectorB_salu.execute((bit<32>)ig_md.pgid_pipe_port_index);
    }
    @name(".do_store_first_stamp")
    action do_store_first_stamp() {
        store_first_tstamp_salu.execute((bit<32>)ig_md.pgid_pipe_port_index);
    }
    @name(".do_store_last_stamp")
    action do_store_last_stamp() {
        store_last_tstamp_salu.execute((bit<32>)ig_md.pgid_pipe_port_index);
    }
    table rx_lat_max_detectA_tbl {
        actions = {
            do_rx_detect_lat_maxA;
        }
        size = 1;
        default_action = do_rx_detect_lat_maxA();
    }
    table rx_lat_min_detectA_tbl {
        actions = {
            do_rx_detect_lat_minA;
        }
        size = 1;
        default_action = do_rx_detect_lat_minA();
    }
    table rx_lat_tot_detectA_tbl {
        actions = {
            do_rx_calc_lat_totA;
        }
        key = {
            hdr.bridged_md.bank_select: exact;
            ig_md.rx_instrum : exact;
        }
        size = 1;
    }
    @name(".rx_lat_tot_detectB_tbl")
    table rx_lat_tot_detectB_tbl {
        actions = {
            do_rx_calc_lat_totB;
        }
        key = {
            hdr.bridged_md.bank_select: exact;
            ig_md.rx_instrum : exact;
        }
        size = 1;
    }
    @name(".rx_store_first_tstamp_tbl")
    table rx_store_first_tstamp_tbl {
        actions = {
            do_store_first_stamp;
        }
        size = 1;
        default_action = do_store_first_stamp();
    }
    @name(".rx_store_last_tstamp_tbl")
    table rx_store_last_tstamp_tbl {
        actions = {
            do_store_last_stamp;
        }
        size = 1;
        default_action = do_store_last_stamp();
    }
    apply {
        rx_store_last_tstamp_tbl.apply();
        rx_lat_max_detectA_tbl.apply();
        rx_lat_min_detectA_tbl.apply();
        rx_lat_tot_detectA_tbl.apply();
        rx_lat_tot_detectB_tbl.apply();
        if (ig_md.known_flow == 1w0) {
            rx_store_first_tstamp_tbl.apply();
        }
    }
}
# 133 "pktgen9_16.p4" 2
# 1 "rx_pgid.p4" 1
/*------------------------------------------------------------------------
    rx_pgid.p4 - Module to detect new flows based on tracking of PGID found in Ixia instrumentation

    Copyright (C) 2019 by Keysight Technologies
    All Rights Reserved.
*-----------------------------------------------------------------------*/

@name(".rx_pgid_flow_state_reg") Register<bit<1>, bit<32>>(32768, 0) rx_pgid_flow_state_reg;

control process_rx_pgid_flow_tracking(inout header_t hdr, inout ingress_metadata_t ig_md) {
    @name(".rx_pgid_known_flow_tracker_salu") RegisterAction<bit<1>, bit<32>, bit<1>>(rx_pgid_flow_state_reg) rx_pgid_known_flow_tracker_salu = {
        void apply(inout bit<1> value, out bit<1> rv) {
            rv = 1w0;
            bit<1> in_value;
            in_value = value;
            value = 1w1;
            rv = value;
        }
    };
    @name(".do_rx_pgid_track_flows") action do_rx_pgid_track_flows() {
        ig_md.known_flow = rx_pgid_known_flow_tracker_salu.execute((bit<32>)ig_md.pgid_pipe_port_index);
    }
    @name(".rx_pgid_flow_tbl") table rx_pgid_flow_tbl {
        actions = {
            do_rx_pgid_track_flows;
        }
        default_action = do_rx_pgid_track_flows;
        size = 1;
    }
    apply {
        rx_pgid_flow_tbl.apply();
    }
}
# 134 "pktgen9_16.p4" 2
# 1 "rx_seqnum.p4" 1
/*------------------------------------------------------------------------
    rx_seqnum.p4 -  Module to compute basic sequence stats. Compares sequence number in Ixia instrumentation to
                    previously received sequence number and calculates small, big, reverse, duplicate sequence
                    counters. Also stores maximum received sequence number.

    Copyright (C) 2019 by Keysight Technologies
    All Rights Reserved.
*-----------------------------------------------------------------------*/

control process_ig_seq_stats(inout header_t hdr, inout ingress_metadata_t ig_md) {

    @Feature(name="RxPgidBigSeqErrCntr", block=ig_pgid_seq_stats, service=Stats, service_id=RxPgidBigSeqErrCntr, index=pgid, display_name="Rx Big Sequence Errors", display_cols="PGID|BigSeqErrBytes|BigSeqErrPkts",col_units="|bytes|packets")

    @Api(index=pgid, label="Rx Big Sequence Errors", col_labels="PGID|BigSeqErrBytes|BigSeqErrPkts",col_units="|bytes|packets")
    @brief("Ingress Large Sequence Error Stats counter")
    @description("Ingress Large Sequence Error Stats counter, count stats regardless of bank select")
    @name(".rx_seq_big_cntrA")
    Counter<bit<32>,bit<15>>(32768,CounterType_t.PACKETS_AND_BYTES) rx_seq_big_cntrA;

    @Feature(name="RxPgidDupSeqErrCntr", block=ig_pgid_seq_stats, service=Stats, service_id=RxPgidDupSeqErrCntr, index=pgid, display_name="Rx Duplicate Sequence Errors", display_cols="PGID|DupSeqErrBytes|DupSeqErrPkts",col_units="|bytes|packets")

    @Api(index=pgid, label="Rx Duplicate Sequence Errors", col_labels="PGID|DupSeqErrBytes|DupSeqErrPkts",col_units="|bytes|packets")
    @brief("Ingress Duplicate Sequence Error Stats counter")
    @description("Ingress Duplicate Sequence Error Stats counter, count stats regardless of bank select")
    @name(".rx_seq_dup_cntrA")
    Counter<bit<32>,bit<15>>(32768,CounterType_t.PACKETS_AND_BYTES) rx_seq_dup_cntrA;

    @Feature(name="RxPgidRvsSeqErrCntr", block=ig_pgid_seq_stats, service=Stats, service_id=RxPgidRvsSeqErrCntr, index=pgid, display_name="Rx Reverse Sequence Errors", display_cols="PGID|RvsSeqErrBytes|RvsSeqErrPkts",col_units="|bytes|packets")

    @Api(index=pgid, label="Rx Reverse Sequence Errors", col_labels="PGID|RvsSeqErrBytes|RvsSeqErrPkts",col_units="|bytes|packets")
    @brief("Ingress Reverse Sequence Error Stats counter")
    @description("Ingress Reverse Sequence Error Stats counter, count stats regardless of bank select")
    @name(".rx_seq_rvs_cntrA")
    Counter<bit<32>,bit<15>>(32768,CounterType_t.PACKETS_AND_BYTES) rx_seq_rvs_cntrA;

    @Feature(name="RxPgidSmSeqErrCntr", block=ig_pgid_seq_stats, service=Stats, service_id=RxPgidSmSeqErrCntr, index=pgid, display_name="Rx Small Sequence Errors", display_cols="PGID|SmSeqErrBytes|SmSeqErrPkts",col_units="|bytes|packets")

    @Api(index=pgid, label="Rx Small Sequence Errors", col_labels="PGID|SmSeqErrBytes|SmSeqErrPkts",col_units="|bytes|packets")
    @brief("Ingress Small Sequence Error Stats counter")
    @description("Ingress Small Sequence Error Stats counter, count stats regardless of bank select")
    @name(".rx_seq_sm_cntrA")
    Counter<bit<32>,bit<15>>(32768,CounterType_t.PACKETS_AND_BYTES) rx_seq_sm_cntrA;

    @brief("Sequence large threshold register")
    @description("Sequence large threshold register, programmed by control plane to set global large squence error threshold")
    @name(".rx_seq_big_threshold_reg")
    Register<bit<32>,bit<16>>(32w1) rx_seq_big_threshold_reg;

    @brief("Sequence delta register, used as intermediate computation")
    @description("Sequence delta register, used as intermediate computation.     Holds the difference between two sucessive sequence numbers for a given flow")

    @name(".rx_seq_delta_reg")
    Register<bit<32>,bit<16>>(16384) rx_seq_delta_reg;

    @brief("Sequence duplicate register")
    @description("Sequence duplicate register, used as intermediate computation;     set to 1 if two successive sequence numbers are identical")

    @name(".rx_seq_dup_reg")
    Register<bit<32>,bit<16>>(32w1) rx_seq_dup_reg;

    @brief("Sequence increment register")
    @description("Sequence increment register, used as intermediate computation;     set to 1 if two successive sequence numbers exhibit an increment of 1")

    @name(".rx_seq_incr_reg")
    Register<bit<32>,bit<16>>(32w1) rx_seq_incr_reg;

    @Feature(name="RxPgidMaxSeqNum", block=ig_pgid_seq_stats, service=Stats, service_id=RxPgidMaxSeqNum, index=pgid, display_name="Rx Max Sequence Number", display_cols="PGID|MaxSeqNum",col_units="|sequence_num")

    @Api(index=pgid, label="Rx Max Sequence Number", col_labels="PGID|MaxSeqNum",col_units="|sequence_num")
    @brief("Max sequence nunmber per pgid")
    @description("Max sequence nunmber per pgid")
    @name(".rx_seq_max_reg")
    Register<bit<32>,bit<16>>(16384) rx_seq_max_reg;

    @brief("Sequence reverse register")
    @description("Sequence reverse register, used as intermediate computation;     set to 1 if two successive sequence numbers exhibit a decrease.")

    @name(".rx_seq_rvs_reg")
    Register<bit<32>,bit<16>>(32w1) rx_seq_rvs_reg;

    // pseudo-feature to declare a regex and label for multiple stats
    @feature(name="SequenceStats", block=ig_pgid_seq_stats, service=Stats, service_id=".*Pgid.*Seq.*", index=pgid, display_name="All Sequence Stats")

    @brief("Fake entity - not instantatiated, do not attempt to access except via service_id")
    @description("Fake entity to receive annotation for service_id regex")
    Register<bit<32>,bit<32>>(32768, 0) rx_fake_sequence_reg;

    @name(".seq_big_detector_salu")
    RegisterAction<bit<32>, bit<32>, bit<32>>(rx_seq_big_threshold_reg) seq_big_detector_salu = {
        void apply(inout bit<32> value, out bit<32> rv) {
            rv = 32w0;
            bit<32> alu_hi = 32w0;
            bit<32> in_value;
            in_value = value;
            if ((bit<32>)ig_md.seq_delta >= in_value) {
                alu_hi = (bit<32>)1;
            }
            if (!((bit<32>)ig_md.seq_delta >= in_value)) {
                alu_hi = (bit<32>)0;
            }
            rv = alu_hi;
        }
    };
    @name(".seq_delta_calc_salu")
    RegisterAction<bit<32>, bit<32>, bit<32>>(rx_seq_delta_reg) seq_delta_calc_salu = {
        void apply(inout bit<32> value, out bit<32> rv) {
            rv = 32w0;
            bit<32> alu_hi = 32w0;
            bit<32> in_value;
            in_value = value;
            alu_hi = hdr.instrum.seqnum - in_value;
            value = hdr.instrum.seqnum;
            rv = alu_hi;
        }
    };
    @name(".seq_dup_detector_salu")
    RegisterAction<bit<32>, bit<32>, bit<32>>(rx_seq_dup_reg) seq_dup_detector_salu = {
        void apply(inout bit<32> value, out bit<32> rv) {
            rv = 32w0;
            bit<32> alu_hi = 32w0;
            bit<32> in_value;
            in_value = value;
            if (ig_md.seq_delta == 32s0) {
                alu_hi = (bit<32>)1;
            }
            if (!(ig_md.seq_delta == 32s0)) {
                alu_hi = (bit<32>)0;
            }
            rv = alu_hi;
        }
    };
    @name(".seq_incr_detector_salu")
    RegisterAction<bit<32>, bit<32>, bit<32>>(rx_seq_incr_reg) seq_incr_detector_salu = {
        void apply(inout bit<32> value, out bit<32> rv) {
            rv = 32w0;
            bit<32> alu_hi = 32w0;
            bit<32> in_value;
            in_value = value;
            if (ig_md.seq_delta == 32s1) {
                alu_hi = (bit<32>)1;
            }
            if (!(ig_md.seq_delta == 32s1)) {
                alu_hi = (bit<32>)0;
            }
            rv = alu_hi;
        }
    };
    @name(".seq_max_detector_salu")
    RegisterAction<bit<32>, bit<32>, bit<32>>(rx_seq_max_reg) seq_max_detector_salu = {
        void apply(inout bit<32> value) {
            bit<32> in_value;
            in_value = value;
            if (hdr.instrum.seqnum > in_value) {
                value = hdr.instrum.seqnum;
            }
            if (!(hdr.instrum.seqnum > in_value)) {
                value = in_value;
            }
        }
    };
    @name(".seq_rvs_detector_salu")
    RegisterAction<bit<32>, bit<32>, bit<32>>(rx_seq_rvs_reg) seq_rvs_detector_salu = {
        void apply(inout bit<32> value, out bit<32> rv) {
            rv = 32w0;
            bit<32> alu_hi = 32w0;
            bit<32> in_value;
            in_value = value;
            if (ig_md.seq_delta < 32s0) {
                alu_hi = (bit<32>)1;
            }
            if (!(ig_md.seq_delta < 32s0)) {
                alu_hi = (bit<32>)0;
            }
            rv = alu_hi;
        }
    };
    @name(".store_prev_seq_delta_salu")
    RegisterAction<bit<32>, bit<32>, bit<32>>(rx_seq_delta_reg) store_prev_seq_delta_salu = {
        void apply(inout bit<32> value) {
            bit<32> in_value;
            in_value = value;
            value = hdr.instrum.seqnum;
        }
    };
    @name(".store_prev_seq_max_salu")
    RegisterAction<bit<32>, bit<32>, bit<32>>(rx_seq_max_reg) store_prev_seq_max_salu = {
        void apply(inout bit<32> value) {
            bit<32> in_value;
            in_value = value;
            value = hdr.instrum.seqnum;
        }
    };
    @name(".do_count_seq_bigA")
    action do_count_seq_bigA() {
        rx_seq_big_cntrA.count(ig_md.port_pgid_index);
    }
    @name(".do_rx_detect_seq_big")
    action do_rx_detect_seq_big() {
        ig_md.seq_big = (bit<1>)seq_big_detector_salu.execute(32w0);
    }
    @name(".do_store_prev_seq_delta")
    action do_store_prev_seq_delta() {
        store_prev_seq_delta_salu.execute((bit<32>)ig_md.pgid_pipe_port_index);
    }
    @name(".do_rx_calc_seq_delta")
    action do_rx_calc_seq_delta() {
        ig_md.seq_delta = (int<32>)seq_delta_calc_salu.execute((bit<32>)ig_md.pgid_pipe_port_index);
    }
    @name(".do_count_seq_dupA")
    action do_count_seq_dupA() {
        rx_seq_dup_cntrA.count(ig_md.port_pgid_index);
    }
    @name(".do_rx_detect_seq_dup")
    action do_rx_detect_seq_dup() {
        ig_md.seq_dup = (bit<1>)seq_dup_detector_salu.execute(32w0);
    }
    @name(".do_rx_detect_seq_incr")
    action do_rx_detect_seq_incr() {
        ig_md.seq_incr = (bit<1>)seq_incr_detector_salu.execute(32w0);
    }
    @name(".do_store_prev_seq_max")
    action do_store_prev_seq_max() {
        store_prev_seq_max_salu.execute((bit<32>)ig_md.pgid_pipe_port_index);
    }
    @name(".do_rx_detect_seq_max")
    action do_rx_detect_seq_max() {
        seq_max_detector_salu.execute((bit<32>)ig_md.pgid_pipe_port_index);
    }
    @name(".do_count_seq_rvsA")
    action do_count_seq_rvsA() {
        rx_seq_rvs_cntrA.count(ig_md.port_pgid_index);
    }
    @name(".do_rx_detect_seq_rvs")
    action do_rx_detect_seq_rvs() {
        ig_md.seq_rvs = (bit<1>)seq_rvs_detector_salu.execute(32w0);
    }
    @name(".do_count_seq_smA")
    action do_count_seq_smA() {
        rx_seq_sm_cntrA.count(ig_md.port_pgid_index);
    }
    table rx_seq_big_count_tblA {
        actions = {
            do_count_seq_bigA;
        }
        size = 1;
        default_action = do_count_seq_bigA();
    }
    table rx_seq_big_detect_tbl {
        actions = {
            do_rx_detect_seq_big;
        }
        size = 1;
        default_action = do_rx_detect_seq_big();
    }
    table rx_seq_delta_calc_tbl {
        actions = {
            do_store_prev_seq_delta;
            do_rx_calc_seq_delta;
        }
        key = {
            ig_md.known_flow: exact;
        }
        size = 2;
        const entries = {
            (0): do_store_prev_seq_delta();
            (1): do_rx_calc_seq_delta();
        }
    }
    table rx_seq_dup_count_tblA {
        actions = {
            do_count_seq_dupA;
        }
        size = 1;
        default_action = do_count_seq_dupA();
    }
    table rx_seq_dup_detect_tbl {
        actions = {
            do_rx_detect_seq_dup;
        }
        size = 1;
        default_action = do_rx_detect_seq_dup();
    }
    table rx_seq_incr_detect_tbl {
        actions = {
            do_rx_detect_seq_incr;
        }
        size = 1;
        default_action = do_rx_detect_seq_incr();
    }
    table rx_seq_max_detect_tbl {
        actions = {
            do_store_prev_seq_max;
            do_rx_detect_seq_max;
        }
        key = {
            ig_md.known_flow: exact;
        }
        size = 2;
        const entries = {
            (0): do_store_prev_seq_max();
            (1): do_rx_detect_seq_max();
        }
    }
    table rx_seq_rvs_count_tblA {
        actions = {
            do_count_seq_rvsA;
        }
        size = 1;
        default_action = do_count_seq_rvsA();
    }
    table rx_seq_rvs_detect_tbl {
        actions = {
            do_rx_detect_seq_rvs;
        }
        size = 1;
        default_action = do_rx_detect_seq_rvs();
    }
    table rx_seq_sm_count_tblA {
        actions = {
            do_count_seq_smA;
        }
        size = 1;
        default_action = do_count_seq_smA();
    }
    apply {
        rx_seq_max_detect_tbl.apply();
        rx_seq_delta_calc_tbl.apply();
        if (ig_md.known_flow == 1w1) {
            rx_seq_incr_detect_tbl.apply();
            rx_seq_dup_detect_tbl.apply();
            rx_seq_rvs_detect_tbl.apply();
            rx_seq_big_detect_tbl.apply();
            if (ig_md.seq_dup == 1w1) {
                rx_seq_dup_count_tblA.apply();
            } else {
                if (ig_md.seq_rvs == 1w1) {
                    rx_seq_rvs_count_tblA.apply();
                } else {
                    if (ig_md.seq_big == 1w1) {
                        rx_seq_big_count_tblA.apply();
                    } else {
                        if (ig_md.seq_incr == 1w0) {
                            rx_seq_sm_count_tblA.apply();
                        }
                    }
                }
            }
        }
    }
}
# 135 "pktgen9_16.p4" 2
# 1 "substreams.p4" 1
/*------------------------------------------------------------------------
    substreams.p4 - Pack stream & fp port numbers into composite port_stream_index's

    Copyright (C) 2019 by Keysight Technologies
    All Rights Reserved.
*-----------------------------------------------------------------------*/

control process_stream_ids(inout header_t hdr) {



    @name(".do_pack_pipeapp") action do_pack_pipeapp() {
        {



            hdr.big_sig_br_md.stream = hdr.outer_eth.dstAddr0[4:0];

        }
    }
    @name(".pack_pipeapp_tbl") table pack_pipeapp_tbl {
        actions = {
            do_pack_pipeapp;
        }
        size = 1;
        default_action = do_pack_pipeapp();
    }
    apply {
        pack_pipeapp_tbl.apply();
    }
}

control process_pack_stream_port(inout header_t hdr, in ingress_intrinsic_metadata_t ig_intr_md, inout ingress_metadata_t ig_md) {
    Hash<bit<10>>(HashAlgorithm_t.IDENTITY) port_stream_index_hash;
    @name(".do_pack_stream_port") action do_pack_stream_port() {
        {
            ig_md.port_stream_index = (bit<10>)port_stream_index_hash.get({ ig_md.fp_port, hdr.big_sig_br_md.stream });
        }
    }
    @name(".pack_stream_port_tbl") table pack_stream_port_tbl {
        actions = {
            do_pack_stream_port;
        }
        size = 1;
        default_action = do_pack_stream_port();
    }
    apply {
        pack_stream_port_tbl.apply();
    }
}

control process_pack_stream_port_eg(inout header_t hdr, in egress_intrinsic_metadata_t eg_intr_md, inout egress_metadata_t eg_md) {
    Hash<bit<10>>(HashAlgorithm_t.IDENTITY) port_stream_index_hash;
    @name(".do_pack_stream_port_eg")
    action do_pack_stream_port_eg() {
        {
            eg_md.port_stream_index = (bit<10>)port_stream_index_hash.get({ eg_md.fp_port, hdr.big_sig_br_md.stream });
        }
    }
    @placement_priority(99)
    @name(".pack_stream_port_tbl_eg")
    table pack_stream_port_tbl_eg {
        actions = {
            do_pack_stream_port_eg;
        }
        size = 1;
        default_action = do_pack_stream_port_eg();
    }
    apply {
        pack_stream_port_tbl_eg.apply();
    }
}
// Remap streams for IMIX
  control process_remap_streams(inout header_t hdr,
        in ingress_intrinsic_metadata_t ig_intr_md) {
    @name("._nop")
    action _nop() {
    }

    @name(".do_remap_stream")
    action do_remap_stream(bit<5> stream_id) {
        hdr.big_sig_br_md.stream = stream_id;
    }

    @Feature(name="StreamRemap", block=substream, service=Udf, service_id=StreamRemap, display_name="Remap Streams Table")

    @Api(label="Remap Streams Table")
    @brief("Remap Streams Table")
    @description("Remap Streams Table, used for IMIX")
    @name(".ig_remap_stream_tbl")
    table ig_remap_stream_tbl {
        actions = {
            _nop;
            do_remap_stream;
        }
        key = {
            hdr.big_sig_br_md.stream: ternary
                                      @brief("Stream number")
                                      @Api(label="Stream number",format="dec");
            ig_intr_md.ingress_port: ternary
                                      @brief("Ingress Port")
                                      @Api(label="Ingress port number (dataplane)",format="dec");
        }
        size = 1024;
    }

    apply {
        ig_remap_stream_tbl.apply();
    }
}
# 136 "pktgen9_16.p4" 2
# 1 "timestamp.p4" 1
/*------------------------------------------------------------------------
    timestamp.p4 - Module to slice 48 bit timestamp into two 32 bit values to store into registers.

    Copyright (C) 2019 by Keysight Technologies
    All Rights Reserved.
*-----------------------------------------------------------------------*/

control process_egress_tstamp_lower(in egress_intrinsic_metadata_from_parser_t eg_intr_from_prsr, inout egress_metadata_t eg_md) {
    Hash<bit<32>>(HashAlgorithm_t.IDENTITY) eg_tstamp_hash_lo;
    @name(".do_extract_eg_tstamp_lower") action do_extract_eg_tstamp_lower() {
        @field_list_field_slice("eg_intr_md_from_parser_aux.egress_global_tstamp", 31, 0) {
            eg_md.tx_packet_timestamp.lower = eg_tstamp_hash_lo.get({ eg_intr_from_prsr.global_tstamp[31:0] });
        }
    }
    @name(".extract_eg_tstamp_lower_tbl") table extract_eg_tstamp_lower_tbl {
        actions = {
            do_extract_eg_tstamp_lower;
        }
        size = 1;
        default_action = do_extract_eg_tstamp_lower();
    }
    apply {
        extract_eg_tstamp_lower_tbl.apply();
    }
}

control process_egress_tstamp_upper(in egress_intrinsic_metadata_from_parser_t eg_intr_from_prsr, inout egress_metadata_t eg_md) {
    Hash<bit<32>>(HashAlgorithm_t.IDENTITY) eg_tstamp_hash_hi;
    @name(".do_extract_eg_tstamp_upper") action do_extract_eg_tstamp_upper() {
        @field_list_field_slice("eg_intr_md_from_parser_aux.egress_global_tstamp", 47, 32) {
            eg_md.tx_packet_timestamp.upper = eg_tstamp_hash_hi.get({ eg_intr_from_prsr.global_tstamp[47:32] });
        }
    }
    @name(".extract_eg_tstamp_upper_tbl") table extract_eg_tstamp_upper_tbl {
        actions = {
            do_extract_eg_tstamp_upper;
        }
        size = 1;
        default_action = do_extract_eg_tstamp_upper();
    }
    apply {
        extract_eg_tstamp_upper_tbl.apply();
    }
}

control process_ingress_tstamp_lower(inout header_t hdr, inout ingress_metadata_t ig_md, in ingress_intrinsic_metadata_from_parser_t ig_prsr_md) {
    Hash<bit<32>>(HashAlgorithm_t.IDENTITY) ig_tstamp_hash_lo;
    @name(".do_extract_ig_tstamp_lower") action do_extract_ig_tstamp_lower() {
        @field_list_field_slice("ig_intr_md_from_parser_aux.ingress_global_tstamp", 31, 0) {
            ig_md.rx_packet_timestamp.lower = ig_tstamp_hash_lo.get({ ig_prsr_md.global_tstamp[31:0] });
        }
    }
    @name(".extract_ig_tstamp_lower_tbl") table extract_ig_tstamp_lower_tbl {
        actions = {
            do_extract_ig_tstamp_lower;
        }
        size = 1;
        default_action = do_extract_ig_tstamp_lower();
    }
    apply {
        extract_ig_tstamp_lower_tbl.apply();
    }
}

control process_ingress_tstamp_upper(inout header_t hdr, inout ingress_metadata_t ig_md, in ingress_intrinsic_metadata_from_parser_t ig_prsr_md) {
    Hash<bit<32>>(HashAlgorithm_t.IDENTITY) ig_tstamp_hash_hi;
    @name(".do_extract_ig_tstamp_upper") action do_extract_ig_tstamp_upper() {
        @field_list_field_slice("ig_intr_md_from_parser_aux.ingress_global_tstamp", 47, 32) {
            ig_md.rx_packet_timestamp.upper = ig_tstamp_hash_hi.get({ ig_prsr_md.global_tstamp[47:32] });
        }
    }
    @name(".extract_ig_tstamp_upper_tbl") table extract_ig_tstamp_upper_tbl {
        actions = {
            do_extract_ig_tstamp_upper;
        }
        size = 1;
        default_action = do_extract_ig_tstamp_upper();
    }
    apply {
        extract_ig_tstamp_upper_tbl.apply();
    }
}


@name(".rx_ingress_stamp_regA") Register<reg_pair_t, bit<32>>(16384,{0,0}) rx_ingress_stamp_regA;

control process_ig_pgid_tstampA(inout header_t hdr, inout ingress_metadata_t ig_md) {
    @name(".store_ingress_tstampA_salu") RegisterAction<reg_pair_t, bit<32>, bit<32>>(rx_ingress_stamp_regA) store_ingress_tstampA_salu = {
        void apply(inout reg_pair_t value) {
            reg_pair_t in_value;
            in_value = value;
            value.hi = ig_md.rx_packet_timestamp.upper;
            value.lo = ig_md.rx_packet_timestamp.lower;
        }
    };
    @name(".do_store_ingress_stampA") action do_store_ingress_stampA() {
        store_ingress_tstampA_salu.execute((bit<32>)ig_md.pgid_pipe_port_index);
    }
    @name(".rx_tstampA_tbl") table rx_tstampA_tbl {
        actions = {
            do_store_ingress_stampA;
        }
        key = {
            hdr.bridged_md.bank_select: exact;
            ig_md.rx_instrum : exact;
        }
        size = 1;
    }
    apply {
        rx_tstampA_tbl.apply();
    }
}


@name(".rx_ingress_stamp_regB") Register<reg_pair_t, bit<32>>(16384,{0,0}) rx_ingress_stamp_regB;

control process_ig_pgid_tstampB(inout header_t hdr, inout ingress_metadata_t ig_md) {
    @name(".store_ingress_tstampB_salu") RegisterAction<reg_pair_t, bit<32>, bit<32>>(rx_ingress_stamp_regB) store_ingress_tstampB_salu = {
        void apply(inout reg_pair_t value) {
            reg_pair_t in_value;
            in_value = value;
            value.hi = ig_md.rx_packet_timestamp.upper;
            value.lo = ig_md.rx_packet_timestamp.lower;
        }
    };
    @name(".do_store_ingress_stampB") action do_store_ingress_stampB() {
        store_ingress_tstampB_salu.execute((bit<32>)ig_md.pgid_pipe_port_index);
    }
    @name(".rx_tstampB_tbl") table rx_tstampB_tbl {
        actions = {
            do_store_ingress_stampB;
        }
        key = {
            hdr.bridged_md.bank_select: exact;
            ig_md.rx_instrum : exact;
        }
        size = 1;
    }
    apply {
        rx_tstampB_tbl.apply();
    }
}
# 137 "pktgen9_16.p4" 2
# 1 "tx_instrum.p4" 1
/*------------------------------------------------------------------------
    tx_instrum.p4 - Module to compute register index for sequence number and insert timestamp and corresponding
                    sequence number into Ixia instrumentation if there is an Ixia signature in the stream.
                    The existence of a signature is programmed by the control plane per stream. 

    Copyright (C) 2019 by Keysight Technologies
    All Rights Reserved.
*-----------------------------------------------------------------------*/

control calib_rx_tstamp(inout header_t hdr, in ingress_intrinsic_metadata_t ig_intr_md, inout ingress_metadata_t ig_md) {
    @name(".do_calib_rx_tstamp") action do_calib_rx_tstamp(bit<32> offset) {
        ig_md.rx_tstamp_calibrated = hdr.instrum.tstamp + offset;
    }
    @name("._nop") action _nop() {
    }
    @name(".do_calib_rx_tstamp_tbl") table do_calib_rx_tstamp_tbl {
        actions = {
            do_calib_rx_tstamp;
            _nop;
        }
        key = {
            ig_intr_md.ingress_port: exact;
        }
        size = 128;
        default_action = _nop();
    }
    apply {
        do_calib_rx_tstamp_tbl.apply();
    }
}

control calib_tx_tstamp(inout header_t hdr, in egress_intrinsic_metadata_t eg_intr_md) {
    @name(".do_calib_tx_tstamp") action do_calib_tx_tstamp(bit<32> offset) {
        hdr.instrum.tstamp = hdr.instrum.tstamp + offset;
    }
    @name("._nop") action _nop() {
    }
    @name(".do_calib_tx_tstamp_tbl") table do_calib_tx_tstamp_tbl {
        actions = {
            do_calib_tx_tstamp;
            _nop;
        }
        key = {
            eg_intr_md.egress_port: exact;
        }
        size = 128;
        default_action = _nop();
    }
    apply {
        do_calib_tx_tstamp_tbl.apply();
    }
}


control process_tx_instrum_pktgen(inout header_t hdr, in egress_intrinsic_metadata_t eg_intr_md, inout egress_metadata_t eg_md) {
    @name("._nop") action _nop() {
    }
    @name(".set_tx_instrum_pktgen")
    action set_tx_instrum_pktgen() {
        eg_md.tx_instrum = 1w1;
    }

    // TODO - if add this to a service API, need a new one ("analytics"?)
    @name(".set_tx_instrum_pktgen_tbl")
    table set_tx_instrum_pktgen_tbl {
        actions = {
            _nop;
            set_tx_instrum_pktgen;
        }
        key = {
            hdr.big_sig_br_md.stream : ternary;
            eg_intr_md.egress_port: ternary;
        }
        size = 1024;
        default_action = _nop();
        // Static entries for front-panel ports
        // TODO: provide all channelized ports; or remove const entries and program from control-plane
        const entries = {
            // Tofino sim ports, remove for produciron for sure
            (0 &&& 0, 1 &&& 511): set_tx_instrum_pktgen();
            (0 &&& 0, 2 &&& 511): set_tx_instrum_pktgen();
            (0 &&& 0, 3 &&& 511): set_tx_instrum_pktgen();
            (0 &&& 0, 4 &&& 511): set_tx_instrum_pktgen();
            (0 &&& 0, 5 &&& 511): set_tx_instrum_pktgen();
            (0 &&& 0, 6 &&& 511): set_tx_instrum_pktgen();
            (0 &&& 0, 7 &&& 511): set_tx_instrum_pktgen();
            (0 &&& 0, 8 &&& 511): set_tx_instrum_pktgen();

            // 32Q Super Montara platform, 100G f/p ports only; need channels 1-3 added
            (0 &&& 0, 260 &&& 511): set_tx_instrum_pktgen();
            (0 &&& 0, 268 &&& 511): set_tx_instrum_pktgen();
            (0 &&& 0, 276 &&& 511): set_tx_instrum_pktgen();
            (0 &&& 0, 284 &&& 511): set_tx_instrum_pktgen();
            (0 &&& 0, 292 &&& 511): set_tx_instrum_pktgen();
            (0 &&& 0, 300 &&& 511): set_tx_instrum_pktgen();
            (0 &&& 0, 308 &&& 511): set_tx_instrum_pktgen();
            (0 &&& 0, 316 &&& 511): set_tx_instrum_pktgen();
            (0 &&& 0, 56 &&& 511): set_tx_instrum_pktgen();
            (0 &&& 0, 48 &&& 511): set_tx_instrum_pktgen();
            (0 &&& 0, 40 &&& 511): set_tx_instrum_pktgen();
            (0 &&& 0, 32 &&& 511): set_tx_instrum_pktgen();
            (0 &&& 0, 24 &&& 511): set_tx_instrum_pktgen();
            (0 &&& 0, 16 &&& 511): set_tx_instrum_pktgen();
            (0 &&& 0, 8 &&& 511): set_tx_instrum_pktgen();
            (0 &&& 0, 0 &&& 511): set_tx_instrum_pktgen();
            (0 &&& 0, 4 &&& 511): set_tx_instrum_pktgen();
            (0 &&& 0, 12 &&& 511): set_tx_instrum_pktgen();
            (0 &&& 0, 20 &&& 511): set_tx_instrum_pktgen();
            (0 &&& 0, 28 &&& 511): set_tx_instrum_pktgen();
            (0 &&& 0, 36 &&& 511): set_tx_instrum_pktgen();
            (0 &&& 0, 44 &&& 511): set_tx_instrum_pktgen();
            (0 &&& 0, 52 &&& 511): set_tx_instrum_pktgen();
            (0 &&& 0, 60 &&& 511): set_tx_instrum_pktgen();
            (0 &&& 0, 312 &&& 511): set_tx_instrum_pktgen();
            (0 &&& 0, 304 &&& 511): set_tx_instrum_pktgen();
            (0 &&& 0, 296 &&& 511): set_tx_instrum_pktgen();
            (0 &&& 0, 288 &&& 511): set_tx_instrum_pktgen();
            (0 &&& 0, 272 &&& 511): set_tx_instrum_pktgen();
            (0 &&& 0, 280 &&& 511): set_tx_instrum_pktgen();
            (0 &&& 0, 256 &&& 511): set_tx_instrum_pktgen();
            (0 &&& 0, 264 &&& 511): set_tx_instrum_pktgen();
        }
    }
    apply {
        set_tx_instrum_pktgen_tbl.apply();
    }
}


control pack_stream_pgid(inout header_t hdr, inout egress_metadata_t eg_md) {
    Hash<bit<14>>(HashAlgorithm_t.IDENTITY) pack_stream_pgid_hash;
    @name(".do_pack_stream_pgid")
    action do_pack_stream_pgid() {
        {



            eg_md.pgid_pipe_port_index = (bit<14>)pack_stream_pgid_hash.get({ hdr.outer_eth.dstAddr0[(3 -1):0], hdr.instrum.pgid });

        }
    }
    @name(".pack_stream_pgid_tbl")
    table pack_stream_pgid_tbl {
        actions = {
            do_pack_stream_pgid;
        }
        size = 1;
        default_action = do_pack_stream_pgid();
    }
    apply {
        pack_stream_pgid_tbl.apply();
    }
}


@name(".tx_seq_incr_reg") Register<bit<32>,bit<16>>(32w16384) tx_seq_incr_reg;

control process_tx_instrum(inout header_t hdr, inout egress_metadata_t eg_md, in egress_intrinsic_metadata_from_parser_t eg_intr_from_prsr) {
    @name(".seq_incr_gen_salu")
    RegisterAction<bit<32>, bit<32>, bit<32>>(tx_seq_incr_reg) seq_incr_gen_salu = {
        void apply(inout bit<32> value, out bit<32> rv) {
            rv = 32w0;
            bit<32> in_value;
            in_value = value;
            value = in_value + 32w1;
            rv = value;
        }
    };

    @name(".do_populate_instrum")
    action do_populate_instrum() {
        hdr.instrum.tstamp = (bit<32>)eg_intr_from_prsr.global_tstamp;
    }
    @name(".eg_populate_instrum_tbl")
    table eg_populate_instrum_tbl {
        actions = {
            do_populate_instrum;
        }
        size = 1;
        default_action = do_populate_instrum();
    }

    @name(".do_incr_seqnum")
    action do_incr_seqnum() {
        hdr.instrum.seqnum = seq_incr_gen_salu.execute((bit<32>)eg_md.pgid_pipe_port_index);
    }
    @name(".incr_seqnum_tbl")
    table incr_seqnum_tbl {
        actions = {
            do_incr_seqnum;
        }
        size = 1;
        default_action = do_incr_seqnum();
    }
    apply {
        incr_seqnum_tbl.apply();
        eg_populate_instrum_tbl.apply();
    }
}
# 138 "pktgen9_16.p4" 2
# 1 "udf_vlist_mac_ip_tbl.p4" 1
/*------------------------------------------------------------------------
    udf_vlist_mac_ip_tbl.p4 - Module to modify protocol fields via MAU.
    Specifies protocol fields based on packet index.

    Copyright (C) 2019 by Keysight Technologies
    All Rights Reserved.
*-----------------------------------------------------------------------*/


  @pa_no_overlay("egress","hdr.outer_ipv4.srcAddr")
  @pa_no_overlay("egress","hdr.outer_ipv4.dstAddr")


control process_udf_vlist_mac_ip(inout header_t hdr, in egress_intrinsic_metadata_t eg_intr_md, inout egress_metadata_t eg_md) {
    @name("._nop") action _nop() {
    }
    @name(".do_modify_mac_ipv4")
    action do_modify_mac_ipv4(bit<8> dmac0, bit<8> dmac1, bit<8> dmac2, bit<8> dmac3, bit<8> dmac4, bit<8> dmac5,
                              bit<8> smac0, bit<8> smac1, bit<8> smac2, bit<8> smac3, bit<8> smac4, bit<8> smac5,
                              bit<12> vid0, bit<12> vid1, bit<32> dipv4, bit<32> sipv4,
                              bit<32> dipv6_0, bit<32> dipv6_1, bit<32> dipv6_2, bit<32> dipv6_3,
                              bit<32> sipv6_0, bit<32> sipv6_1, bit<32> sipv6_2, bit<32> sipv6_3,
                              bit<10> pgid, bit<32> sig3) {
        hdr.outer_eth.dstAddr0 = dmac0;
        hdr.outer_eth.dstAddr1 = dmac1;
        hdr.outer_eth.dstAddr2 = dmac2;
        hdr.outer_eth.dstAddr3 = dmac3;
        hdr.outer_eth.dstAddr4 = dmac4;
        hdr.outer_eth.dstAddr5 = dmac5;
        hdr.outer_eth.srcAddr0 = smac0;
        hdr.outer_eth.srcAddr1 = smac1;
        hdr.outer_eth.srcAddr2 = smac2;
        hdr.outer_eth.srcAddr3 = smac3;
        hdr.outer_eth.srcAddr4 = smac4;
        hdr.outer_eth.srcAddr5 = smac5;
        hdr.vlan_tag[0].vid = vid0;
        hdr.vlan_tag[1].vid = vid1;
        hdr.outer_ipv4.dstAddr = dipv4;
        hdr.outer_ipv4.srcAddr = sipv4;


      // TODO - the code below requires the @pa_no_overlay above to prevent the
      // compiler from reusing associated PHV fields. Normally ipv4 and ipv6 headers are
      // mutually-exclusive. Doing the code below implies PHVs are reserved for both headers
      // thoughout the pipeline, which is wasteful of PHVs.
      // To avoid such "waste,", we would need to split into separate actions, which will either require
      // control-plane changes to populate different actions; OR,
      // write to intermediate meta, then have control execute either one action or the other
      // to copy to the actual valid hdr; but this may exceed # stages available.
        hdr.outer_ipv6.dstAddr0 = dipv6_0;
        hdr.outer_ipv6.srcAddr0 = sipv6_0;
        hdr.outer_ipv6.dstAddr1 = dipv6_1;
        hdr.outer_ipv6.srcAddr1 = sipv6_1;
        hdr.outer_ipv6.dstAddr2 = dipv6_2;
        hdr.outer_ipv6.srcAddr2 = sipv6_2;
        hdr.outer_ipv6.dstAddr3 = dipv6_3;
        hdr.outer_ipv6.srcAddr3 = sipv6_3;

        hdr.instrum.pgid = pgid;
        hdr.big_sig.sig3 = sig3;
    }

    @Feature(name="UdfVlistMacIp", block=vlist_udf, service=Udf, service_id=UdfVlistMacIp, display_name="Udf Vlist Parameters")

    @Api(label="Udf Vlist Parameters")
    @brief("Udf Vlist Parameters")
    @description("Udf Vlist Parameters per stream/eg_port cycled by g_pkt_cntr")
    @name(".udf_vlist_mac_ip_tbl")
    table udf_vlist_mac_ip_tbl {
        actions = {
            _nop;
            do_modify_mac_ipv4;
        }
        key = {
             hdr.big_sig_br_md.stream: ternary
                                      @brief("Stream number")
                                      @Api(label="Stream number",format="dec");
            eg_intr_md.egress_port: ternary
                                      @brief("Egress Port")
                                      @Api(label="Egress port number (dataplane)",format="dec");
            eg_md.g_pkt_cntr_value: ternary
                                      @brief("g_pkt_cntr")
                                      @Api(label="Global Packet Counter",format="dec");
        }
        size = 32768;
        default_action = _nop();
    }
    apply {
        udf_vlist_mac_ip_tbl.apply();
    }
}
# 139 "pktgen9_16.p4" 2


control SwitchIngress(
        inout header_t hdr,
        inout ingress_metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_prsr_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_tm_md) {

    @name(".calib_rx_tstamp") calib_rx_tstamp() calib_rx_tstamp_0;
    @name(".process_rx_instrum") process_rx_instrum() process_rx_instrum_0;
    @name(".process_bank_select_reg") process_bank_select_reg() process_bank_select_reg_0;
    @name(".process_generate_random_number") process_generate_random_number() process_generate_random_number_0;
    @name(".process_ingress_fp_port") process_ingress_fp_port() process_ingress_fp_port_0;
    @name(".process_load_cpu_parameters") process_load_cpu_parameters() process_load_cpu_parameters_0;
    @name(".process_stream_ids") process_stream_ids() process_stream_ids_0;
    @name(".process_ig_port_stats") process_ig_port_stats() process_ig_port_stats_0;
    @name(".process_rx_latency") process_rx_latency() process_rx_latency_0;
    @name(".pack_port_pgid") pack_port_pgid() pack_port_pgid_0;
    @name(".pack_pgid_pipe_port") pack_pgid_pipe_port() pack_pgid_pipe_port_0;
    @name(".process_abs_value_rx_latency") process_abs_value_rx_latency() process_abs_value_rx_latency_0;
    @name(".process_ig_pgid_statsA") process_ig_pgid_statsA() process_ig_pgid_statsA_0;
    @name(".process_value_rx_latency_overflow") process_value_rx_latency_overflow() process_value_rx_latency_overflow_0;
    @name(".process_ingress_tstamp_lower") process_ingress_tstamp_lower() process_ingress_tstamp_lower_0;
    @name(".process_ingress_tstamp_upper") process_ingress_tstamp_upper() process_ingress_tstamp_upper_0;
    @name(".process_ig_pgid_tstampA") process_ig_pgid_tstampA() process_ig_pgid_tstampA_0;
    @name(".process_ig_pgid_tstampB") process_ig_pgid_tstampB() process_ig_pgid_tstampB_0;
    @name(".process_rx_pgid_flow_tracking") process_rx_pgid_flow_tracking() process_rx_pgid_flow_tracking_0;
    @name(".process_ig_lat_stats") process_ig_lat_stats() process_ig_lat_stats_0;
    @name(".process_ig_seq_stats") process_ig_seq_stats() process_ig_seq_stats_0;
    @name(".process_ig_pgid_statsB") process_ig_pgid_statsB() process_ig_pgid_statsB_0;
    @name(".process_pack_stream_port") process_pack_stream_port() process_pack_stream_port_0;
    @name(".process_pktgen_port_forwarding") process_pktgen_port_forwarding() process_pktgen_port_forwarding_0;
    @name(".process_from_cpu_port_forwarding") process_from_cpu_port_forwarding() process_from_cpu_port_forwarding_0;
    @name(".process_common_drop") process_common_drop() process_common_drop_0;
    @name(".process_remap_streams") process_remap_streams() process_remap_streams_0;

    apply {
        ig_md.ingress_port = ig_intr_md.ingress_port; // need copy for cloning in deparser
        hdr.bridged_md.setValid();
        calib_rx_tstamp_0.apply(hdr, ig_intr_md, ig_md);
        process_rx_instrum_0.apply(hdr, ig_intr_md, ig_md);
        process_bank_select_reg_0.apply(hdr);
        process_generate_random_number_0.apply(hdr, ig_md);
        process_ingress_fp_port_0.apply(hdr, ig_intr_md, ig_md);
        process_load_cpu_parameters_0.apply(hdr, ig_intr_md, ig_md);
        process_stream_ids_0.apply(hdr);
        process_ig_port_stats_0.apply(hdr, ig_intr_md, ig_prsr_md, ig_md);
        process_rx_latency_0.apply(hdr, ig_intr_md, ig_prsr_md, ig_md);
        pack_port_pgid_0.apply(hdr, ig_md);
        pack_pgid_pipe_port_0.apply(hdr, ig_md);
        process_abs_value_rx_latency_0.apply(hdr, ig_md);
        process_ig_pgid_statsA_0.apply(hdr, ig_md);
        process_value_rx_latency_overflow_0.apply(hdr, ig_md);
        process_ingress_tstamp_lower_0.apply(hdr, ig_md, ig_prsr_md);
        process_ingress_tstamp_upper_0.apply(hdr, ig_md, ig_prsr_md);
        process_ig_pgid_tstampA_0.apply(hdr, ig_md);
        process_ig_pgid_tstampB_0.apply(hdr, ig_md);

        if (hdr.bridged_md.is_pktgen == 1w1) {

            hdr.big_sig_br_md.setValid();

            process_pktgen_port_forwarding_0.apply(hdr, ig_intr_md, ig_dprsr_md, ig_tm_md);
        } else {
            if (1w0 == ig_intr_md.resubmit_flag && hdr.fabric_hdr.isValid() &&
                    ig_md.pcie_cpu_port_enabled == 1w1
               )
            {
                process_from_cpu_port_forwarding_0.apply(hdr, ig_tm_md);
            } else {
                if (ig_md.rx_instrum == 1w1) {
                    process_rx_pgid_flow_tracking_0.apply(hdr, ig_md);
                    process_ig_seq_stats_0.apply(hdr, ig_md);
                    process_ig_lat_stats_0.apply(hdr, ig_md);
                    process_common_drop_0.apply(ig_dprsr_md);
                } else {
                    process_to_cpu_port_forwarding.apply(hdr, ig_md, ig_intr_md, ig_dprsr_md);
                }
            }
        }
        process_remap_streams_0.apply(hdr, ig_intr_md);
        process_ig_pgid_statsB_0.apply(hdr, ig_md);
        process_pack_stream_port_0.apply(hdr, ig_intr_md, ig_md);

    }



}
control SwitchEgress(
        inout header_t hdr,
        inout egress_metadata_t eg_md,
        in egress_intrinsic_metadata_t eg_intr_md,
        in egress_intrinsic_metadata_from_parser_t eg_intr_from_prsr,
        inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
        inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {


    @name(".process_load_udf1_cntr_params") process_load_udf1_cntr_params() process_load_udf1_cntr_params_0;
    @name(".process_egress_tstamp_lower") process_egress_tstamp_lower() process_egress_tstamp_lower_0;
    @name(".process_load_burst_pkt_cntr") process_load_burst_pkt_cntr() process_load_burst_pkt_cntr_0;
    @name(".process_incr_g_pkt_cntr") process_incr_g_pkt_cntr() process_incr_g_pkt_cntr_0;
    @name(".process_prepopulate_hdr_g_reg") process_prepopulate_hdr_g_reg() process_prepopulate_hdr_g_reg_0;
    @name(".process_tx_instrum_pktgen") process_tx_instrum_pktgen() process_tx_instrum_pktgen_0;
    @name(".process_load_udf2_cntr_params") process_load_udf2_cntr_params() process_load_udf2_cntr_params_0;
    @name(".process_compute_conditional_cntr_udf") process_compute_conditional_cntr_udf() process_compute_conditional_cntr_udf_0;
    @name(".process_compute_inner_cntr_udf") process_compute_inner_cntr_udf() process_compute_inner_cntr_udf_0;
    @name(".process_incr_burst_pkt_cntr") process_incr_burst_pkt_cntr() process_incr_burst_pkt_cntr_0;
    @name(".process_udf_vlist_mac_ip") process_udf_vlist_mac_ip() process_udf_vlist_mac_ip_0;
    @name(".process_intermediate_inner_cntr_udf") process_intermediate_inner_cntr_udf() process_intermediate_inner_cntr_udf_0;
    @name(".process_egress_tstamp_upper") process_egress_tstamp_upper() process_egress_tstamp_upper_0;
    @name(".pack_stream_pgid") pack_stream_pgid() pack_stream_pgid_0;
    @name(".process_intermediate_outer_cntr_udf") process_intermediate_outer_cntr_udf() process_intermediate_outer_cntr_udf_0;
    @name(".process_update_cntr_udf") process_update_cntr_udf() process_update_cntr_udf_0;
    @name(".process_update_cntr_udf_nested") process_update_cntr_udf_nested() process_update_cntr_udf_nested_0;
    @name(".process_burst_drops") process_burst_drops() process_burst_drops_0;
    @name(".process_tx_instrum") process_tx_instrum() process_tx_instrum_0;
    @name(".process_eg_stream_stats") process_eg_stream_stats() process_eg_stream_stats_0;
    @name(".calib_tx_tstamp") calib_tx_tstamp() calib_tx_tstamp_0;
    @name(".process_cntr_udf") process_cntr_udf() process_cntr_udf_0;
    @name(".process_eg_port_stats") process_eg_port_stats() process_eg_port_stats_0;
    @name(".process_cpu_fabric_hdr") process_cpu_fabric_hdr() process_cpu_fabric_hdr_0;
    @name(".process_egress_fp_port") process_egress_fp_port() process_egress_fp_port_0;
    @name("process_pack_stream_port_eg") process_pack_stream_port_eg() process_pack_stream_port_eg_0;
    @name(".process_load_g_pkt_cntr") process_load_g_pkt_cntr() process_load_g_pkt_cntr_0;

    apply {
      process_egress_fp_port_0.apply(hdr, eg_intr_md, eg_md);
      process_pack_stream_port_eg_0.apply(hdr, eg_intr_md, eg_md); // result used as index into many tables/registers
        process_egress_tstamp_lower_0.apply(eg_intr_from_prsr, eg_md);
        // if packet if from pktgen/recirc and egressing to fp port (even-numbered pipe)
        if (hdr.bridged_md.is_pktgen == 1w1 && eg_intr_md.egress_port & 9w128 == 9w0) {
            process_load_g_pkt_cntr_0.apply(hdr, eg_md, eg_intr_md);
            process_load_burst_pkt_cntr_0.apply(hdr, eg_md, eg_intr_md);
            process_load_udf1_cntr_params_0.apply(hdr, eg_intr_md, eg_md);
            process_load_udf2_cntr_params_0.apply(hdr, eg_intr_md, eg_md);
            process_incr_g_pkt_cntr_0.apply(hdr, eg_md);
            process_incr_burst_pkt_cntr_0.apply(hdr, eg_md);
            process_prepopulate_hdr_g_reg_0.apply(hdr, eg_intr_md);
            process_tx_instrum_pktgen_0.apply(hdr, eg_intr_md, eg_md);
            process_compute_conditional_cntr_udf_0.apply(hdr, eg_md);
            process_compute_inner_cntr_udf_0.apply(hdr, eg_md);
            process_udf_vlist_mac_ip_0.apply(hdr, eg_intr_md, eg_md);
            process_intermediate_inner_cntr_udf_0.apply(hdr, eg_md);
            process_egress_tstamp_upper_0.apply(eg_intr_from_prsr, eg_md);
            pack_stream_pgid_0.apply(hdr, eg_md);
            process_intermediate_outer_cntr_udf_0.apply(hdr, eg_md);
            process_update_cntr_udf_0.apply(hdr, eg_intr_md, eg_md);
            process_update_cntr_udf_nested_0.apply(hdr, eg_intr_md, eg_md);

            if (eg_md.burst_pkt_cntr.drop == 1w1) {
        // TODO: HACK - w/o ctrl plane, always dropping; RESTORE CODE!
               // process_burst_drops_0.apply(hdr, eg_intr_md_for_dprsr);
        // END HACK
            } else {
                if (eg_md.tx_instrum == 1w1) {

                      // Replace "stowaway" br md with fixed sig
                      hdr.big_sig.setValid();
                      hdr.big_sig.sig1 = 0x87736749; // or could look up in tbl if need  variable sig
                      hdr.big_sig.sig2 = 0x42871180;
                      hdr.big_sig.sig2 = 0x08711805;
                      // NOTE - vlist rewrites sig3 anyway
                      hdr.big_sig_br_md.setInvalid();

                    process_tx_instrum_0.apply(hdr, eg_md, eg_intr_from_prsr);
                    process_eg_stream_stats_0.apply(hdr, eg_md);
                    calib_tx_tstamp_0.apply(hdr, eg_intr_md); // apply additive offset to tx time stamp
                }
                process_cntr_udf_0.apply(hdr, eg_intr_md, eg_md);
                process_eg_port_stats_0.apply(hdr, eg_intr_md);
            }
        } else {
            // if not from pktgen then assume it's control-plane pkt from CPU;
            // copy egress port from fabric hdr from CPU
            process_cpu_fabric_hdr_0.apply(hdr, eg_intr_md);
            // tally e.g. stats
            process_eg_port_stats_0.apply(hdr, eg_intr_md);
        }
    }




}

Pipeline(SwitchIngressParser(),
         SwitchIngress(),
         SwitchIngressDeparser(),
         SwitchEgressParser(),
         SwitchEgress(),
         SwitchEgressDeparser()) pipe;

/**
 * Below code appends global annotations to pkginfo by annotating "main()"
 */

// P4 "Standard" pkginfo annnotations to main()
@pkginfo(name="pktgen9_16.p4",version="1")
@brief("Tofino Nanite Packet Blaster")
@description("Tofino Nanite Packet Blaster.Lovingly brought to you by talented nerds.")

@pkginfo(organization="KeySight")
@pkginfo(contact="support@keysight.com")
@pkginfo(url="www.keysight.com")

// User-defined pkginfo annotations to main() 
// merge package-level attributes, conditionally set and/or #included

@Attr(target_type=TOFINO1,access=ro,descrip="Target device type")
@Attr(pktgen_apps_per_pipe=8,access=ro,descrip="Number of packet-generator apps per pipe")
@Attr(profile=1,access=ro,descrip="Build profile for this program") @Attr(num_pgids=32768,access=ro,descrip="Number of PGID flows/stats supported by this program/profile") @Attr(num_stats_banks=2,access=ro,descrip="Number of statistics banks supported by this program/profile")
@Attr("OPTIMIZATION_LVL"=14,access=ro,descrip="Optimization Level used to control various contituent optimizations") @Attr("OPTMZ_BR_MD_IN_SIG"=,access=ro,descrip="Optimization: Pack bridged md into signature from ig-to-eg, restore in eg") @Attr("OPTMZ_NO_PKTGEN_ETH"=1,access=ro,descrip="Optimization: use outer_eth to extract pktgen hdr, extract app_id and pipe using slices, not hashes") @Attr("OPTMZ_MERGED_MIRROR_MD"=,access=ro,descrip="Optimiztion: Use unified hdr for bridged_md and mirror_md, merge eg_parse states)")
Switch(pipe) main;
