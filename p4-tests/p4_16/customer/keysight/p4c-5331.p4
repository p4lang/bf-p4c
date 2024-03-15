#include <core.p4>
#include <t2na.p4>

# 26 "nanite.p4"
// Packet hdr definitions:
# 1 "stdhdrs.p4" 1
/*------------------------------------------------------------------------
    stdhdrs.p4 - Standard header definitions and Ethertypes, ports, etc.

    Copyright (C) 2020 by Keysight Technologies
    All Rights Reserved.
*-----------------------------------------------------------------------*/

//=====================
//      DEFINES
//=====================

// Ethertypes
# 35 "stdhdrs.p4"
header ethernet_t
{
    bit<16> dstAddrHi;
    bit<32> dstAddrLo;
    bit<8> srcAddrHi_0;
    bit<8> srcAddrHi_1;
    bit<32> srcAddrLo;
    bit<16> etherType;
}

header ptp_mac_hdr_t
{
 bit<8> udp_cksum_byte_offset;
 bit<8> cf_byte_offset;
 bit<48> updated_cf;
}

// Used to extract an entire ethernet hdr where
// the DMAC comes from pktgen meta insertion and the rest
// comes from the outer_eth written into the pktbuff but the DMAC is
// skipped and effectively "replaced" by the pktgen_generic_header_t
header pktgen_ethernet_t
{
    @padding bit<3> _pad0;
    bit<5> stream;
    @padding bit<1> _pad1;
    bit<7> queue_id;
    bit<16> batch_id;
    bit<16> packet_id;
    bit<48> srcAddr;
    bit<16> etherType;
}

header vlan_tag_t
{
    bit<3> pcp;
    bit<1> cfi;
    bit<12> vid;
    bit<16> etherType;
}

header ipv4_t
{
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

header ipv6_t
{
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

header tcp_t
{
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

header udp_t
{
    bit<16> srcPort;
    bit<16> dstPort;
    bit<16> length_;
    bit<16> checksum;
}

header vxlan_t
{
 bit<8> flags;
 bit<24> reserved;
 bit<14> vni_hi;
 bit<10> vni_lo;
 bit<8> reserved2;
}

header mpls_tag_t
{
    bit<20> label;
    bit<3> exp;
    bit<1> bos;
    bit<8> ttl;
}
# 28 "nanite.p4" 2
# 1 "ixia_hdrs.p4" 1
/*------------------------------------------------------------------------
    ixia_hdrs.p4 - Define IXIA-specific headers

    Copyright (C) 2019 by Keysight Technologies
    All Rights Reserved.
*-----------------------------------------------------------------------*/

// Big signature, 12 bytes
header ixia_big_signature_t
{
    bit<32> sig1;
    bit<32> sig2;
    bit<32> sig3;
}

header ixia_extended_instrum_t
{
 bit<3> tstamp_hires;
 bit<19> pgid_pad;
 bit<10> pgid;
 bit<16> seqnum;
}

header ixia_extended_timestamp_t
{
 bit<16> upper_tstamp;
 bit<32> tstamp;
 bit<16> pad;
}

header fabric_hdr_t
{
 bit<16> devPort;
 bit<16> etherType;
}

struct modifier32_t {
  bit<32> increment;
  bit<32> repeat; // constant
}

struct modifier16_t {
  bit<16> increment;
  bit<16> repeat; // constant
}
# 29 "nanite.p4" 2
# 1 "types.p4" 1
/*------------------------------------------------------------------------
    types.p4 - header and struct definitions

    Copyright (C) 2019 by Keysight Technologies
    All Rights Reserved.
*-----------------------------------------------------------------------*/




  typedef bit<4> mirror_type_t;


// workaround: for drop packet counting on deparser issue
const mirror_type_t MIRROR_TYPE_DROP = 0;


const mirror_type_t MIRROR_TYPE_I2E = 1;
const mirror_type_t MIRROR_TYPE_E2E = 2;
# 31 "types.p4"
// Represents 64-bit SALU values
struct reg_pair_t
{
    bit<32> lo;
    bit<32> hi;
}

struct burst_pkt_cntr_t
{
    bit<32> max_hi;
    bit<32> max_low;
    bit<4> drop;
}

struct table_udf_pkt_cntr_t
{
    bit<16> max;
    bit<16> value;
}



//==============================
// Ingress metadata
//==============================

struct port_metadata_t {
    //temporary since we have only 64-bits port metadata for tofino1
    // will be 192 bits in T2
    bit<8> field1_offset;
    bit<8> field1_length;
}

struct ingress_metadata_t
{
    port_metadata_t port_properties;
    bit<3> pipe_port;
    bit<5> fp_port;
 bit<10> rx_pgid;
    bit<15> port_pgid_index;
    bit<13> pgid_pipe_port_index;
    bit<1> rx_instrum;
    int<32> seq_delta;
    bit<32> latency;
    bit<32> lat_to_mem;
    bit<32> lat_to_mem_overflow;
    bit<32> lat_overflow;
    bit<1> known_flow;
    bit<1> seq_incr;
    bit<1> seq_big;
    bit<1> seq_dup;
    bit<1> seq_rvs;
    bit<1> latency_overflow;
    bit<1> tstamp_overflow;
    bit<32> rx_tstamp_calibrated;
    MirrorId_t mirror_id; // needed to pass non-const to deparser mirror.emit()
    bit<1> is_mirror; // TODO delete
    bit<1> pcie_cpu_port_enabled;
    PortId_t ingress_port;
    bit<8> field1;
}


//==============================
// bridged metadata
//==============================

header mirror_bridged_metadata_t
{
    bit<1> is_mirror; // this bit needs to appear in same place in bridged_metadata_t and mirror_bridged_metadata_h
    @padding bit<6> _pad;
    PortId_t ingress_port; // which f/p port pkt came in on, will go into fabric hdr to CPU
}

header ixia_bridged_md_t
{
 bit<1> is_mirror; // this bit needs to appear in same place in bridged_metadata_t and mirror_bridged_metadata_h
 bit<1> is_pktgen;
 bit<1> bank_select;
 bit<5> stream;
//#if __TARGET_TOFINO__ == 2



}



//==============================
// Egress metadata
//==============================

struct egress_metadata_t
{
    bit<3> pipe_port;
    bit<5> fp_port;
    bit<10>port_stream_index;
    bit<15> port_pgid_index;
 bit<10> tx_pgid;
    bit<1> burst_mode;
 bit<5> stream_offset;
    bit<1> tx_instrum; // the pgid to put into egress instrumentation
 table_udf_pkt_cntr_t table_udf_pkt_cntr;
    burst_pkt_cntr_t burst_pkt_cntr;
    bit<13> pgid_pipe_port_index;
 bit<7> pipe_port_stream_index;
 bit<1> bank_select_port_stats;
 bit<1> mac_timestamp_enable;
 bit<32> src_mac_max; bit<32> src_mac_incr; bit<16> src_mac_index; bit<2> src_mac_opcode; bit<32> src_mac_repeat;
 bit<32> dst_mac_max; bit<32> dst_mac_incr; bit<16> dst_mac_index; bit<2> dst_mac_opcode; bit<32> dst_mac_repeat;
 bit<16> vlan_mod;
 bit<16> vlan_tag_max; bit<16> vlan_tag_incr; bit<16> vlan_tag_index; bit<2> vlan_tag_opcode; bit<32> vlan_tag_repeat;
 bit<32> outer_l3_src_mod;
 bit<32> outer_l3_src_max; bit<32> outer_l3_src_incr; bit<16> outer_l3_src_index; bit<2> outer_l3_src_opcode; bit<32> outer_l3_src_repeat;
 bit<32> outer_l3_dst_mod;
 bit<32> outer_l3_dst_max; bit<32> outer_l3_dst_incr; bit<16> outer_l3_dst_index; bit<2> outer_l3_dst_opcode; bit<32> outer_l3_dst_repeat;
 bit<3> src_ipv6_mod_index;
 bit<3> dst_ipv6_mod_index;
 bit<16> outer_l4_src_mod;
 bit<16> outer_l4_src_max; bit<16> outer_l4_src_incr; bit<16> outer_l4_src_index; bit<2> outer_l4_src_opcode; bit<32> outer_l4_src_repeat;
 bit<16> outer_l4_dst_mod;
 bit<16> outer_l4_dst_max; bit<16> outer_l4_dst_incr; bit<16> outer_l4_dst_index; bit<2> outer_l4_dst_opcode; bit<32> outer_l4_dst_repeat;
    bit<32> outer_mpls_mod;
    bit<32> outer_mpls_tag_max; bit<32> outer_mpls_tag_incr; bit<16> outer_mpls_tag_index; bit<2> outer_mpls_tag_opcode; bit<32> outer_mpls_tag_repeat;
}

struct header_t
{
    mirror_bridged_metadata_t mirror_bridged_md;
    ixia_bridged_md_t bridged_md;
    ixia_big_signature_t big_sig;
    egress_intrinsic_metadata_t eg_intr_md;
    fabric_hdr_t fabric_hdr;
    ixia_extended_instrum_t instrum;
 ixia_extended_timestamp_t instrum_tstamp;
 ptp_mac_hdr_t ptp_mac_hdr;
    ethernet_t ptp_eth;
    pktgen_ethernet_t pktgen_header;
    ethernet_t outer_eth;
    vlan_tag_t[2] vlan_tag;
    mpls_tag_t[2] mpls_tag;
    ipv4_t outer_ipv4;
    ipv6_t outer_ipv6;
    tcp_t outer_tcp;
    udp_t outer_udp;
 vxlan_t vxlan;
 vlan_tag_t[2] inner_vlan_tag;
 ethernet_t inner_eth;
    ipv4_t inner_ipv4;
    ipv6_t inner_ipv6;
}
# 30 "nanite.p4" 2

// Ingress modules
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
            inout ingress_metadata_t ig_md,
            in ingress_intrinsic_metadata_t ig_intr_md,
            inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,
            inout ingress_intrinsic_metadata_for_tm_t ig_tm_md)
{
    // TODO: use process_common_drop_instance instead
    @Api(label="Drop Packet")
    @brief("Drop Packet")
    @name(".do_drop")
    @alias("drop")
    action do_drop()
 {
        ig_dprsr_md.drop_ctl = 0x1;
        // Tofino BUG: dropped packets don't shows less bytes than received
        // workaround: also mirror to a disabled mirror id, should be fixed post SDE 9.11
        ig_dprsr_md.mirror_type = MIRROR_TYPE_DROP;
    }

    @brief("Set egress forwarding port and traffic queue")
    @name("._set_eg_port")
    action _set_eg_port(bit<9> eg_port)
 {
        ig_tm_md.ucast_egress_port = eg_port;
        // ig_tm_md.qid = (QueueId_t)hdr.pktgen_header.stream;
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
    action _set_general_md(bit<16> rid, bit<16> xid, bit<9> yid, bit<13> h1, bit<13> h2)
 {
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
    )
 {
        ig_tm_md.mcast_grp_a = mgid;
        _set_general_md(rid, xid, yid, h1, h2);
    }

    @brief("Layer-1 port/stream forwarding table; drop, unicast or multicast.")
    @description("Layer-1 port/stream forwarding table; drop, unicast or multicast based on port and stream number.")
    @Feature(name="L1Fwding", block=ig_port_fwd, service=Fwding, service_id=PortStreamFwding,
        display_name="Port/Stream Forwarding Table")
    @Api(label="Port/Stream Forwarding Table")
    @name(".ig_port_tbl")
    table ig_port_tbl
 {
        actions =
  {
            @Api(label="Drop") do_drop;
            @Api(label="Unicast") do_set_unicast;
            @Api(label="Multicast") do_set_mcast1_md;
        }

  key =
  {
            hdr.bridged_md.stream : ternary
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
    table ig_recirc_port_tbl
 {
        actions =
  {
            @Api(label="Unicast")
   do_set_unicast;
        }
        key =
  {
            hdr.bridged_md.stream : ternary
                                      @brief("Stream number")
                                      @Api(label="Stream number",format="dec");
            ig_intr_md.ingress_port : ternary
                                      @brief("Logical datapane port number")
                                      // optimum display format is in a ront-panel numbering scheme e.g. "1/1"
                                      @Api(label="Rx Port",format=dec,xform_format="fp_ports",wr_xform="fp_to_dp_port",rd_xform="dp_to_fp_port");
        }
        size = 1024;
    }

    @name(".do_set_qid")
    action do_set_qid(QueueId_t qid)
    {
        ig_tm_md.qid = qid;
    }
    @name(".ig_port_stream_map_tbl")
    table ig_port_stream_map_tbl
    {
        actions =
        {
            do_set_qid;
        }
        key =
        {
            hdr.bridged_md.stream : ternary;
            ig_intr_md.ingress_port: ternary;
        }
        size = 1024;
    }

    apply {
        ig_port_tbl.apply();
        ig_port_stream_map_tbl.apply();
        ig_recirc_port_tbl.apply();
    }
}

control process_common_drop(inout ingress_metadata_t ig_md, inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md)
{

    @brief("Drop Packet")
    @description("Mark packet for drop")
    @name(".common_drop_pkt")
    action common_drop_pkt()
 {
        ig_dprsr_md.drop_ctl = 0x1;
        // Tofino BUG: dropped packets don't shows less bytes than received
        // workaround: also mirror to a disabled mirror id, should be fixed post SDE 9.11
        ig_dprsr_md.mirror_type = MIRROR_TYPE_DROP;
    }

    @brief("Wrapper for action common_drop_pkt()")
    @description("Wrapper for action common_drop_pkt()")
    @name(".common_drop_tbl")
    table common_drop_tbl
 {
      actions = {
          common_drop_pkt;
      }
      size = 1;
      default_action = common_drop_pkt();
    }

    apply
 {
        common_drop_tbl.apply();
    }
}
# 33 "nanite.p4" 2
# 1 "rx_pgid.p4" 1
/*------------------------------------------------------------------------
    rx_pgid.p4 - Module to detect new flows based on tracking of PGID found in Ixia instrumentation

    Copyright (C) 2019 by Keysight Technologies
    All Rights Reserved.
*-----------------------------------------------------------------------*/

control process_rx_pgid_flow_tracking(inout ingress_metadata_t ig_md)
{
    @name(".rx_pgid_flow_state_reg")
    Register<bit<8>, bit<32>>(8192, 0) rx_pgid_flow_state_reg;

    @name(".rx_pgid_flow_state_salu")
    RegisterAction<bit<8>, bit<32>, bit<8>>(rx_pgid_flow_state_reg) rx_flow_state_salu =
    {
        void apply(inout bit<8> value)
        {
   bit<8> in_value;
            value = 8w1;
   in_value = value;
        }
    };

    @name(".do_rx_pgid_track_flows")
    action do_rx_pgid_track_flows()
    {
        rx_flow_state_salu.execute((bit<32>)ig_md.pgid_pipe_port_index);
    }

    @name(".rx_pgid_flow_tbl")
    table rx_pgid_flow_tbl
    {
        actions =
        {
            do_rx_pgid_track_flows;
        }
        size = 1;
        default_action = do_rx_pgid_track_flows();
    }
    apply
    {
        rx_pgid_flow_tbl.apply();
    }
}
# 34 "nanite.p4" 2
# 1 "rx_instrum.p4" 1
/*------------------------------------------------------------------------
    rx_instrum.p4 - Programs an Rx Signature to look for in instrumented packets.
                    Based on match this will set metadata indicating that the packet is a match

    Copyright (C) 2019 by Keysight Technologies
    All Rights Reserved.
*-----------------------------------------------------------------------*/


control process_rx_signature(inout header_t hdr, in ingress_intrinsic_metadata_t ig_intr_md, inout ingress_metadata_t ig_md)
{
    @name("._nop")
 action _nop()
 {
 }

 @name(".do_set_rx_instrum")
 action do_set_rx_instrum()
 {
        ig_md.rx_instrum = 1w1;
    }

 @name(".rx_instrum_tbl") table rx_signature_tbl
 {
        actions =
  {
            _nop;
            do_set_rx_instrum;
        }
        key =
  {
            hdr.big_sig.sig1 : ternary;
            hdr.big_sig.sig2 : ternary;
            hdr.big_sig.sig3 : ternary;
            ig_intr_md.ingress_port: ternary;
        }
        size = 288;
        default_action = _nop();
    }

 apply
 {
        rx_signature_tbl.apply();
    }
}
# 35 "nanite.p4" 2
# 1 "timestamp.p4" 1
/*------------------------------------------------------------------------
    timestamp.p4 - Module to slice 48 bit timestamp into two 32 bit values to store into registers.

    Copyright (C) 2019 by Keysight Technologies
    All Rights Reserved.
*-----------------------------------------------------------------------*/
# 1 "profiles.p4" 1
/*------------------------------------------------------------------------
    profiles.p4 - Define build options via profiles

    Copyright (C) 2019 by Keysight Technologies
    All Rights Reserved.
*-----------------------------------------------------------------------*/

// prevent multiple inclusion
# 8 "timestamp.p4" 2


@name(".rx_ingress_stamp_regA")
Register<reg_pair_t, bit<32>>(8192,{0,0}) rx_ingress_stamp_regA;

control process_ig_pgid_tstampA(inout header_t hdr, inout ingress_metadata_t ig_md, in ingress_intrinsic_metadata_t ig_intr_md)
{
    @name(".store_ingress_tstampA_salu")
 RegisterAction<reg_pair_t, bit<32>, bit<32>>(rx_ingress_stamp_regA) store_ingress_tstampA_salu =
 {
        void apply(inout reg_pair_t value)
  {
            reg_pair_t in_value;
            value.hi = (bit<32>)ig_intr_md.ingress_mac_tstamp[47:32];
            value.lo = ig_intr_md.ingress_mac_tstamp[31:0];
   in_value = value;
        }
    };

 @name(".do_store_ingress_stampA") action do_store_ingress_stampA()
 {
        store_ingress_tstampA_salu.execute((bit<32>)ig_md.pgid_pipe_port_index);
    }

 @name(".rx_tstampA_tbl") table rx_tstampA_tbl
 {
        actions =
  {
            do_store_ingress_stampA;
        }
        // key =
  // {
        //     hdr.bridged_md.bank_select: exact;
        //     ig_md.rx_instrum : exact;
        // }
        size = 1;
  // const entries =
  // {
  // 	(0, 1) : do_store_ingress_stampA();
  // }
        default_action = do_store_ingress_stampA();
    }
    apply
 {
        rx_tstampA_tbl.apply();
    }
}
# 36 "nanite.p4" 2
# 1 "ig_stats.p4" 1
/*------------------------------------------------------------------------
    ig_stats.p4 - Module to compute statistics for ingress ports.
    Computes receive port and PGID flow statistics.
    Port statistics include protocol statistics
    Implements bank switching for Tx/Rx Sync.

    Copyright (C) 2019 by Keysight Technologies
    All Rights Reserved.
*-----------------------------------------------------------------------*/
# 1 "profiles.p4" 1
/*------------------------------------------------------------------------
    profiles.p4 - Define build options via profiles

    Copyright (C) 2019 by Keysight Technologies
    All Rights Reserved.
*-----------------------------------------------------------------------*/

// prevent multiple inclusion
# 11 "ig_stats.p4" 2

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

 @Feature(name="RxVxlanProtoStats", block=ig_port_stats, service=Stats, service_id=RxVxlanProtoStats, index=port,
    display_name="Rx Vxlan Stats", display_cols="Port|RxVxlanBytes|RxVxlanPackets",col_units="|bytes|packets")
    @Api(index=port, label="Rx Vxlan Stats", col_labels="Port|TxBytes|TxPackets",col_units="|bytes|packets")
    @brief("Ingress port Vxlan protocol stats counter")
    @description("Ingress port Vxlan protocol stats counter, counts Vxlan packets and bytes on each ingress port")
    @name(".ig_port_vxlan_stats_cntrA")
    Counter<bit<32>,bit<9>>(32w512,CounterType_t.PACKETS_AND_BYTES) ig_port_vxlan_stats_cntrA;


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
    @name(".do_ig_port_vxlan_statsA")
    action do_ig_port_vxlan_statsA() {
        ig_port_vxlan_stats_cntrA.count(ig_intr_md.ingress_port);
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
    @name(".ig_port_vxlan_statsA_tbl")
    table ig_port_vxlan_statsA_tbl {
        actions = {
            do_ig_port_vxlan_statsA;
        }
        size = 1;
        default_action = do_ig_port_vxlan_statsA();
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
  if(hdr.vxlan.isValid()) {
   ig_port_vxlan_statsA_tbl.apply();
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
        // key = {
        //     hdr.bridged_md.bank_select: exact;
        //     ig_md.rx_instrum : exact;
        // }
  // const entries =
  // {
  // 	(0, 1): do_ig_pgid_statsA;
  // }
        default_action = do_ig_pgid_statsA();
        size = 1;
    }
    apply {
        ig_pgid_statsA_tbl.apply();
    }
}
# 37 "nanite.p4" 2
//#include "egress_tracking.p4"
# 1 "rx_latency.p4" 1
/*------------------------------------------------------------------------
    rx_latency.p4 - Module to compute avg, min, and max latency per pgid/flow

    Copyright (C) 2023 by Keysight Technologies
    All Rights Reserved.
*-----------------------------------------------------------------------*/

control process_ig_latency(inout header_t hdr, inout ingress_metadata_t ig_md, in ingress_intrinsic_metadata_t ig_intr_md)
{

    @name(".ig_latency_total_reg")
    Register<reg_pair_t, bit<32>>(size=8192, initial_value={0,0}) ig_latency_total_reg;
    RegisterAction<reg_pair_t, bit<32>, bit<32>>(ig_latency_total_reg) ig_latency_total_salu =
    {
        void apply(inout reg_pair_t value, out bit<32> cur_value)
        {
            cur_value = value.lo;
            if(cur_value + ig_md.lat_to_mem <= 0x7FFFFFFF) {
                value.lo = value.lo + ig_md.lat_to_mem;
                value.hi = value.hi;
            } else {
                value.lo = value.lo + ig_md.lat_to_mem_overflow;
                value.hi = value.hi + 1;
            }
        }
    };

    @name(".ig_latency_max_reg")
    Register<bit<32>, bit<32>>(size=8192, initial_value=0) ig_latency_max_reg;
    RegisterAction<bit<32>, bit<32>, bit<32>>(ig_latency_max_reg) ig_latency_max_salu =
    {
        void apply(inout bit<32> value)
        {
            if(ig_md.lat_to_mem > value )
            {
                value = ig_md.lat_to_mem;
            }
        }
    };

    @name(".ig_latency_min_reg")
    Register<bit<32>, bit<32>>(size=8192, initial_value=32w0xFFFFFFF) ig_latency_min_reg;
    RegisterAction<bit<32>, bit<32>, bit<32>>(ig_latency_min_reg) ig_latency_min_salu =
    {
        void apply(inout bit<32> value)
        {
            if(ig_md.lat_to_mem < value )
            {
                value = ig_md.lat_to_mem;
            }
        }
    };

    /** calibrate latency **/
    @name(".do_calib_rx_tstamp")
    action do_calib_rx_tstamp(bit<32> offset) {
        ig_md.rx_tstamp_calibrated = hdr.instrum_tstamp.tstamp + offset;
    }

    @name(".do_calib_rx_tstamp_tbl")
    table do_calib_rx_tstamp_tbl {
        key = {
            ig_intr_md.ingress_port: ternary;
        }
        actions = {
            do_calib_rx_tstamp;
        }

        default_action = do_calib_rx_tstamp(580);



        size = 512;
    }

    apply
    {
        // calibrate
        do_calib_rx_tstamp_tbl.apply();
        // calculate latency
        ig_md.lat_to_mem = ig_intr_md.ingress_mac_tstamp[31:0] - ig_md.rx_tstamp_calibrated;

        // get absolute value of latency because we may overflow on TS
        if(ig_md.lat_to_mem < 0) {
            ig_md.lat_to_mem = -ig_md.lat_to_mem;
        }
        // calculate overflowed latency
        ig_md.lat_to_mem_overflow = ig_md.lat_to_mem + 0x80000001;

        // store total latency
        ig_latency_total_salu.execute((bit<32>)ig_md.pgid_pipe_port_index);
        ig_latency_max_salu.execute((bit<32>)ig_md.pgid_pipe_port_index);
        ig_latency_min_salu.execute((bit<32>)ig_md.pgid_pipe_port_index);
    }
}
# 39 "nanite.p4" 2

// Egress modules
# 1 "prepop_hdrs.p4" 1
/*------------------------------------------------------------------------
    prepop_hdrs.p4 - Module to modify protocol fields via MAU.
    Specifies MAC and IP addresses to insert into Ethernet and IP headers.
    Removes the pktgen header which is prepended from pktgen.

    Copyright (C) 2019 by Keysight Technologies
    All Rights Reserved.
*-----------------------------------------------------------------------*/

control process_prepopulate_ethernet_hdr(inout header_t hdr, in egress_intrinsic_metadata_t eg_intr_md)
{

    @name(".do_populate_dmac")
    action do_populate_dmac(bit<16> dmac_hi, bit<32> dmac_lo)
    {
        hdr.outer_eth.dstAddrHi = dmac_hi;
        hdr.outer_eth.dstAddrLo = dmac_lo;
    }

    // FIXME: optimize pipe usage. use prepop header instead of this to populate dmac.
    // populate dmac learnt from protocol engine
    // maybe add more than just dmac other protocols than ARP
    @name(".eg_prepop_dmac_tbl")
    table eg_prepop_dmac_tbl
    {
        actions =
        {
            do_populate_dmac;
        }
        key =
        {
            hdr.bridged_md.stream: ternary;
            eg_intr_md.egress_port: ternary;
        }
        // 16 fp port 32 streams per port
        size = 512;
    }


    @name(".do_prepopulate_ethernet_hdr")
    action do_prepopulate_ethernet_hdr(bit<16> dmac_hi, bit<32> dmac_lo,
      bit<8> smac_hi_0, bit<8> smac_hi_1, bit<32> smac_lo)
 {
  hdr.outer_eth.setValid();
        hdr.outer_eth.dstAddrHi = dmac_hi;
        hdr.outer_eth.dstAddrLo = dmac_lo;
        hdr.outer_eth.srcAddrHi_0 = smac_hi_0;
        hdr.outer_eth.srcAddrHi_1 = smac_hi_1;
        hdr.outer_eth.srcAddrLo = smac_lo;
  hdr.outer_eth.etherType = hdr.pktgen_header.etherType;
        hdr.pktgen_header.setInvalid();
    }

    @name(".eg_prepop_ethernet_hdr_tbl")
    table eg_prepop_ethernet_hdr_tbl
 {
        actions =
  {
            do_prepopulate_ethernet_hdr;
        }
        key =
  {
            hdr.bridged_md.stream: ternary
                                      @brief("Stream number")
                                      @Api(label="Stream number",format="dec");
            eg_intr_md.egress_port: ternary
                                      @brief("Egress Port")
                                      @Api(label="Egress port number (dataplane)",format="dec");
            // TODO: check table dep if checked pktgen here vs in top level calling block                                      
            hdr.bridged_md.is_pktgen: exact
                                      @brief("is_pktgen")
                                      @Api(label="Is this packet from packet generator",format="dec");
        }
        size = 1024;
    }

    apply
 {
        eg_prepop_ethernet_hdr_tbl.apply();
        eg_prepop_dmac_tbl.apply();
    }
}
# 42 "nanite.p4" 2
//#include "table_udf.p4"
# 1 "modifier.p4" 1
/*
* modifier Macros
*/
# 122 "modifier.p4"
control process_counter_udf_repeat(inout header_t hdr, in egress_intrinsic_metadata_t eg_intr_md, inout egress_metadata_t eg_md)
{
    @name("._nop")
    action _nop()
    {
    }
    DirectRegister<modifier32_t>() src_mac_stateful_repeat_reg; DirectRegisterAction<modifier32_t, bit<32>>(src_mac_stateful_repeat_reg) src_mac_repeat_alu = { void apply(inout modifier32_t value, out bit<32> read_value) { if(value.increment > 32w0) { value.increment = value.increment - 1; } else { value.increment = value.repeat; } read_value = value.increment; } }; action src_mac_modify(bit<32> step, bit<32> minimum, bit<32> maximum, bit<16> index, bit<2> opcode) { eg_md.src_mac_repeat = src_mac_repeat_alu.execute(); eg_md.src_mac_incr = step; eg_md.src_mac_max = maximum; eg_md.src_mac_index = index; eg_md.src_mac_opcode = opcode; hdr.outer_eth.srcAddrLo = minimum; }
    DirectRegister<modifier32_t>() dst_mac_stateful_repeat_reg; DirectRegisterAction<modifier32_t, bit<32>>(dst_mac_stateful_repeat_reg) dst_mac_repeat_alu = { void apply(inout modifier32_t value, out bit<32> read_value) { if(value.increment > 32w0) { value.increment = value.increment - 1; } else { value.increment = value.repeat; } read_value = value.increment; } }; action dst_mac_modify(bit<32> step, bit<32> minimum, bit<32> maximum, bit<16> index, bit<2> opcode) { eg_md.dst_mac_repeat = dst_mac_repeat_alu.execute(); eg_md.dst_mac_incr = step; eg_md.dst_mac_max = maximum; eg_md.dst_mac_index = index; eg_md.dst_mac_opcode = opcode; hdr.outer_eth.dstAddrLo = minimum; }
    DirectRegister<modifier32_t>() vlan_tag_stateful_repeat_reg; DirectRegisterAction<modifier32_t, bit<32>>(vlan_tag_stateful_repeat_reg) vlan_tag_repeat_alu = { void apply(inout modifier32_t value, out bit<32> read_value) { if(value.increment > 32w0) { value.increment = value.increment - 1; } else { value.increment = value.repeat; } read_value = value.increment; } }; action vlan_tag_modify(bit<16> step, bit<16> minimum, bit<16> maximum, bit<16> index, bit<2> opcode) { eg_md.vlan_tag_repeat = vlan_tag_repeat_alu.execute(); eg_md.vlan_tag_incr = step; eg_md.vlan_tag_max = maximum; eg_md.vlan_tag_index = index; eg_md.vlan_tag_opcode = opcode; eg_md.vlan_mod = minimum; }
    DirectRegister<modifier32_t>() outer_mpls_tag_stateful_repeat_reg; DirectRegisterAction<modifier32_t, bit<32>>(outer_mpls_tag_stateful_repeat_reg) outer_mpls_tag_repeat_alu = { void apply(inout modifier32_t value, out bit<32> read_value) { if(value.increment > 32w0) { value.increment = value.increment - 1; } else { value.increment = value.repeat; } read_value = value.increment; } }; action outer_mpls_tag_modify(bit<32> step, bit<32> minimum, bit<32> maximum, bit<16> index, bit<2> opcode) { eg_md.outer_mpls_tag_repeat = outer_mpls_tag_repeat_alu.execute(); eg_md.outer_mpls_tag_incr = step; eg_md.outer_mpls_tag_max = maximum; eg_md.outer_mpls_tag_index = index; eg_md.outer_mpls_tag_opcode = opcode; eg_md.outer_mpls_mod = minimum; }
    DirectRegister<modifier32_t>() outer_l3_src_stateful_repeat_reg; DirectRegisterAction<modifier32_t, bit<32>>(outer_l3_src_stateful_repeat_reg) outer_l3_src_repeat_alu = { void apply(inout modifier32_t value, out bit<32> read_value) { if(value.increment > 32w0) { value.increment = value.increment - 1; } else { value.increment = value.repeat; } read_value = value.increment; } }; action outer_l3_src_modify(bit<32> step, bit<32> minimum, bit<32> maximum, bit<16> index, bit<2> opcode) { eg_md.outer_l3_src_repeat = outer_l3_src_repeat_alu.execute(); eg_md.outer_l3_src_incr = step; eg_md.outer_l3_src_max = maximum; eg_md.outer_l3_src_index = index; eg_md.outer_l3_src_opcode = opcode; eg_md.outer_l3_src_mod = minimum; }
    DirectRegister<modifier32_t>() outer_l3_dst_stateful_repeat_reg; DirectRegisterAction<modifier32_t, bit<32>>(outer_l3_dst_stateful_repeat_reg) outer_l3_dst_repeat_alu = { void apply(inout modifier32_t value, out bit<32> read_value) { if(value.increment > 32w0) { value.increment = value.increment - 1; } else { value.increment = value.repeat; } read_value = value.increment; } }; action outer_l3_dst_modify(bit<32> step, bit<32> minimum, bit<32> maximum, bit<16> index, bit<2> opcode) { eg_md.outer_l3_dst_repeat = outer_l3_dst_repeat_alu.execute(); eg_md.outer_l3_dst_incr = step; eg_md.outer_l3_dst_max = maximum; eg_md.outer_l3_dst_index = index; eg_md.outer_l3_dst_opcode = opcode; eg_md.outer_l3_dst_mod = minimum; }
    DirectRegister<modifier32_t>() outer_l4_src_stateful_repeat_reg; DirectRegisterAction<modifier32_t, bit<32>>(outer_l4_src_stateful_repeat_reg) outer_l4_src_repeat_alu = { void apply(inout modifier32_t value, out bit<32> read_value) { if(value.increment > 32w0) { value.increment = value.increment - 1; } else { value.increment = value.repeat; } read_value = value.increment; } }; action outer_l4_src_modify(bit<16> step, bit<16> minimum, bit<16> maximum, bit<16> index, bit<2> opcode) { eg_md.outer_l4_src_repeat = outer_l4_src_repeat_alu.execute(); eg_md.outer_l4_src_incr = step; eg_md.outer_l4_src_max = maximum; eg_md.outer_l4_src_index = index; eg_md.outer_l4_src_opcode = opcode; eg_md.outer_l4_src_mod = minimum; }
    DirectRegister<modifier32_t>() outer_l4_dst_stateful_repeat_reg; DirectRegisterAction<modifier32_t, bit<32>>(outer_l4_dst_stateful_repeat_reg) outer_l4_dst_repeat_alu = { void apply(inout modifier32_t value, out bit<32> read_value) { if(value.increment > 32w0) { value.increment = value.increment - 1; } else { value.increment = value.repeat; } read_value = value.increment; } }; action outer_l4_dst_modify(bit<16> step, bit<16> minimum, bit<16> maximum, bit<16> index, bit<2> opcode) { eg_md.outer_l4_dst_repeat = outer_l4_dst_repeat_alu.execute(); eg_md.outer_l4_dst_incr = step; eg_md.outer_l4_dst_max = maximum; eg_md.outer_l4_dst_index = index; eg_md.outer_l4_dst_opcode = opcode; eg_md.outer_l4_dst_mod = minimum; }
    table src_mac_stream_port_table { key = { eg_intr_md.egress_port: exact; hdr.bridged_md.stream: exact; } actions = { @defaultonly _nop; src_mac_modify; } size = 1024; registers = src_mac_stateful_repeat_reg; const default_action = _nop; }
    table dst_mac_stream_port_table { key = { eg_intr_md.egress_port: exact; hdr.bridged_md.stream: exact; } actions = { @defaultonly _nop; dst_mac_modify; } size = 1024; registers = dst_mac_stateful_repeat_reg; const default_action = _nop; }
    table vlan_tag_stream_port_table { key = { eg_intr_md.egress_port: exact; hdr.bridged_md.stream: exact; } actions = { @defaultonly _nop; vlan_tag_modify; } size = 1024; registers = vlan_tag_stateful_repeat_reg; const default_action = _nop; }
    table outer_mpls_tag_stream_port_table { key = { eg_intr_md.egress_port: exact; hdr.bridged_md.stream: exact; } actions = { @defaultonly _nop; outer_mpls_tag_modify; } size = 1024; registers = outer_mpls_tag_stateful_repeat_reg; const default_action = _nop; }
    table outer_l3_src_stream_port_table { key = { eg_intr_md.egress_port: exact; hdr.bridged_md.stream: exact; } actions = { @defaultonly _nop; outer_l3_src_modify; } size = 1024; registers = outer_l3_src_stateful_repeat_reg; const default_action = _nop; }
    table outer_l3_dst_stream_port_table { key = { eg_intr_md.egress_port: exact; hdr.bridged_md.stream: exact; } actions = { @defaultonly _nop; outer_l3_dst_modify; } size = 1024; registers = outer_l3_dst_stateful_repeat_reg; const default_action = _nop; }
    table outer_l4_src_stream_port_table { key = { eg_intr_md.egress_port: exact; hdr.bridged_md.stream: exact; } actions = { @defaultonly _nop; outer_l4_src_modify; } size = 1024; registers = outer_l4_src_stateful_repeat_reg; const default_action = _nop; }
    table outer_l4_dst_stream_port_table { key = { eg_intr_md.egress_port: exact; hdr.bridged_md.stream: exact; } actions = { @defaultonly _nop; outer_l4_dst_modify; } size = 1024; registers = outer_l4_dst_stateful_repeat_reg; const default_action = _nop; }
    apply
    {
        src_mac_stream_port_table.apply();
        dst_mac_stream_port_table.apply();
        vlan_tag_stream_port_table.apply();
        outer_mpls_tag_stream_port_table.apply();
        outer_l3_src_stream_port_table.apply();
        outer_l3_dst_stream_port_table.apply();
        outer_l4_src_stream_port_table.apply();
        outer_l4_dst_stream_port_table.apply();
    }
}

control process_counter_udf_increment(inout header_t hdr, in egress_intrinsic_metadata_t eg_intr_md, inout egress_metadata_t eg_md)
{
    @name("._nop")
    action _nop()
    {
    }
    Register<modifier32_t, bit<16>>(1024) src_mac_increment_reg; RegisterAction<modifier32_t, bit<16>, bit<32>>(src_mac_increment_reg) src_mac_increment_alu1 = { void apply(inout modifier32_t value, out bit<32> read_value) { if(value.increment > eg_md.src_mac_max) { value.increment = 32w0; } read_value = value.increment; } }; RegisterAction<modifier32_t, bit<16>, bit<32>>(src_mac_increment_reg) src_mac_increment_alu2 = { void apply(inout modifier32_t value, out bit<32> read_value) { read_value = value.increment; if(value.increment == 32w0) { value.increment = eg_md.src_mac_max; } else value.increment = value.increment - eg_md.src_mac_incr; } }; RegisterAction<modifier32_t, bit<16>, bit<32>>(src_mac_increment_reg) src_mac_increment_alu = { void apply(inout modifier32_t value, out bit<32> read_value) { read_value = value.increment; if(value.increment > eg_md.src_mac_max) { value.increment = 32w0; } else value.increment = value.increment + eg_md.src_mac_incr; } }; action src_mac_increment_action1() { eg_md.src_mac_incr = 32w0; hdr.outer_eth.srcAddrLo = hdr.outer_eth.srcAddrLo + src_mac_increment_alu1.execute(eg_md.src_mac_index); } action src_mac_increment_action() { hdr.outer_eth.srcAddrLo = hdr.outer_eth.srcAddrLo + src_mac_increment_alu.execute(eg_md.src_mac_index); } action src_mac_increment_action2() { hdr.outer_eth.srcAddrLo = hdr.outer_eth.srcAddrLo + src_mac_increment_alu2.execute(eg_md.src_mac_index); }
    Register<modifier32_t, bit<16>>(1024) dst_mac_increment_reg; RegisterAction<modifier32_t, bit<16>, bit<32>>(dst_mac_increment_reg) dst_mac_increment_alu1 = { void apply(inout modifier32_t value, out bit<32> read_value) { if(value.increment > eg_md.dst_mac_max) { value.increment = 32w0; } read_value = value.increment; } }; RegisterAction<modifier32_t, bit<16>, bit<32>>(dst_mac_increment_reg) dst_mac_increment_alu2 = { void apply(inout modifier32_t value, out bit<32> read_value) { read_value = value.increment; if(value.increment == 32w0) { value.increment = eg_md.dst_mac_max; } else value.increment = value.increment - eg_md.dst_mac_incr; } }; RegisterAction<modifier32_t, bit<16>, bit<32>>(dst_mac_increment_reg) dst_mac_increment_alu = { void apply(inout modifier32_t value, out bit<32> read_value) { read_value = value.increment; if(value.increment > eg_md.dst_mac_max) { value.increment = 32w0; } else value.increment = value.increment + eg_md.dst_mac_incr; } }; action dst_mac_increment_action1() { eg_md.dst_mac_incr = 32w0; hdr.outer_eth.dstAddrLo = hdr.outer_eth.dstAddrLo + dst_mac_increment_alu1.execute(eg_md.dst_mac_index); } action dst_mac_increment_action() { hdr.outer_eth.dstAddrLo = hdr.outer_eth.dstAddrLo + dst_mac_increment_alu.execute(eg_md.dst_mac_index); } action dst_mac_increment_action2() { hdr.outer_eth.dstAddrLo = hdr.outer_eth.dstAddrLo + dst_mac_increment_alu2.execute(eg_md.dst_mac_index); }
    Register<modifier16_t, bit<16>>(1024) vlan_tag_increment_reg; RegisterAction<modifier16_t, bit<16>, bit<16>>(vlan_tag_increment_reg) vlan_tag_increment_alu1 = { void apply(inout modifier16_t value, out bit<16> read_value) { if(value.increment > eg_md.vlan_tag_max) { value.increment = 16w0; } read_value = value.increment; } }; RegisterAction<modifier16_t, bit<16>, bit<16>>(vlan_tag_increment_reg) vlan_tag_increment_alu2 = { void apply(inout modifier16_t value, out bit<16> read_value) { read_value = value.increment; if(value.increment == 16w0) { value.increment = eg_md.vlan_tag_max; } else value.increment = value.increment - eg_md.vlan_tag_incr; } }; RegisterAction<modifier16_t, bit<16>, bit<16>>(vlan_tag_increment_reg) vlan_tag_increment_alu = { void apply(inout modifier16_t value, out bit<16> read_value) { read_value = value.increment; if(value.increment > eg_md.vlan_tag_max) { value.increment = 16w0; } else value.increment = value.increment + eg_md.vlan_tag_incr; } }; action vlan_tag_increment_action1() { eg_md.vlan_tag_incr = 16w0; eg_md.vlan_mod = eg_md.vlan_mod + vlan_tag_increment_alu1.execute(eg_md.vlan_tag_index); } action vlan_tag_increment_action() { eg_md.vlan_mod = eg_md.vlan_mod + vlan_tag_increment_alu.execute(eg_md.vlan_tag_index); } action vlan_tag_increment_action2() { eg_md.vlan_mod = eg_md.vlan_mod + vlan_tag_increment_alu2.execute(eg_md.vlan_tag_index); }
    Register<modifier32_t, bit<16>>(1024) outer_mpls_tag_increment_reg; RegisterAction<modifier32_t, bit<16>, bit<32>>(outer_mpls_tag_increment_reg) outer_mpls_tag_increment_alu1 = { void apply(inout modifier32_t value, out bit<32> read_value) { if(value.increment > eg_md.outer_mpls_tag_max) { value.increment = 32w0; } read_value = value.increment; } }; RegisterAction<modifier32_t, bit<16>, bit<32>>(outer_mpls_tag_increment_reg) outer_mpls_tag_increment_alu2 = { void apply(inout modifier32_t value, out bit<32> read_value) { read_value = value.increment; if(value.increment == 32w0) { value.increment = eg_md.outer_mpls_tag_max; } else value.increment = value.increment - eg_md.outer_mpls_tag_incr; } }; RegisterAction<modifier32_t, bit<16>, bit<32>>(outer_mpls_tag_increment_reg) outer_mpls_tag_increment_alu = { void apply(inout modifier32_t value, out bit<32> read_value) { read_value = value.increment; if(value.increment > eg_md.outer_mpls_tag_max) { value.increment = 32w0; } else value.increment = value.increment + eg_md.outer_mpls_tag_incr; } }; action outer_mpls_tag_increment_action1() { eg_md.outer_mpls_tag_incr = 32w0; eg_md.outer_mpls_mod = eg_md.outer_mpls_mod + outer_mpls_tag_increment_alu1.execute(eg_md.outer_mpls_tag_index); } action outer_mpls_tag_increment_action() { eg_md.outer_mpls_mod = eg_md.outer_mpls_mod + outer_mpls_tag_increment_alu.execute(eg_md.outer_mpls_tag_index); } action outer_mpls_tag_increment_action2() { eg_md.outer_mpls_mod = eg_md.outer_mpls_mod + outer_mpls_tag_increment_alu2.execute(eg_md.outer_mpls_tag_index); }
    Register<modifier32_t, bit<16>>(1024) outer_l3_src_increment_reg; RegisterAction<modifier32_t, bit<16>, bit<32>>(outer_l3_src_increment_reg) outer_l3_src_increment_alu1 = { void apply(inout modifier32_t value, out bit<32> read_value) { if(value.increment > eg_md.outer_l3_src_max) { value.increment = 32w0; } read_value = value.increment; } }; RegisterAction<modifier32_t, bit<16>, bit<32>>(outer_l3_src_increment_reg) outer_l3_src_increment_alu2 = { void apply(inout modifier32_t value, out bit<32> read_value) { read_value = value.increment; if(value.increment == 32w0) { value.increment = eg_md.outer_l3_src_max; } else value.increment = value.increment - eg_md.outer_l3_src_incr; } }; RegisterAction<modifier32_t, bit<16>, bit<32>>(outer_l3_src_increment_reg) outer_l3_src_increment_alu = { void apply(inout modifier32_t value, out bit<32> read_value) { read_value = value.increment; if(value.increment > eg_md.outer_l3_src_max) { value.increment = 32w0; } else value.increment = value.increment + eg_md.outer_l3_src_incr; } }; action outer_l3_src_increment_action1() { eg_md.outer_l3_src_incr = 32w0; eg_md.outer_l3_src_mod = eg_md.outer_l3_src_mod + outer_l3_src_increment_alu1.execute(eg_md.outer_l3_src_index); } action outer_l3_src_increment_action() { eg_md.outer_l3_src_mod = eg_md.outer_l3_src_mod + outer_l3_src_increment_alu.execute(eg_md.outer_l3_src_index); } action outer_l3_src_increment_action2() { eg_md.outer_l3_src_mod = eg_md.outer_l3_src_mod + outer_l3_src_increment_alu2.execute(eg_md.outer_l3_src_index); }
    Register<modifier32_t, bit<16>>(1024) outer_l3_dst_increment_reg; RegisterAction<modifier32_t, bit<16>, bit<32>>(outer_l3_dst_increment_reg) outer_l3_dst_increment_alu1 = { void apply(inout modifier32_t value, out bit<32> read_value) { if(value.increment > eg_md.outer_l3_dst_max) { value.increment = 32w0; } read_value = value.increment; } }; RegisterAction<modifier32_t, bit<16>, bit<32>>(outer_l3_dst_increment_reg) outer_l3_dst_increment_alu2 = { void apply(inout modifier32_t value, out bit<32> read_value) { read_value = value.increment; if(value.increment == 32w0) { value.increment = eg_md.outer_l3_dst_max; } else value.increment = value.increment - eg_md.outer_l3_dst_incr; } }; RegisterAction<modifier32_t, bit<16>, bit<32>>(outer_l3_dst_increment_reg) outer_l3_dst_increment_alu = { void apply(inout modifier32_t value, out bit<32> read_value) { read_value = value.increment; if(value.increment > eg_md.outer_l3_dst_max) { value.increment = 32w0; } else value.increment = value.increment + eg_md.outer_l3_dst_incr; } }; action outer_l3_dst_increment_action1() { eg_md.outer_l3_dst_incr = 32w0; eg_md.outer_l3_dst_mod = eg_md.outer_l3_dst_mod + outer_l3_dst_increment_alu1.execute(eg_md.outer_l3_dst_index); } action outer_l3_dst_increment_action() { eg_md.outer_l3_dst_mod = eg_md.outer_l3_dst_mod + outer_l3_dst_increment_alu.execute(eg_md.outer_l3_dst_index); } action outer_l3_dst_increment_action2() { eg_md.outer_l3_dst_mod = eg_md.outer_l3_dst_mod + outer_l3_dst_increment_alu2.execute(eg_md.outer_l3_dst_index); }
    Register<modifier16_t, bit<16>>(1024) outer_l4_src_increment_reg; RegisterAction<modifier16_t, bit<16>, bit<16>>(outer_l4_src_increment_reg) outer_l4_src_increment_alu1 = { void apply(inout modifier16_t value, out bit<16> read_value) { if(value.increment > eg_md.outer_l4_src_max) { value.increment = 16w0; } read_value = value.increment; } }; RegisterAction<modifier16_t, bit<16>, bit<16>>(outer_l4_src_increment_reg) outer_l4_src_increment_alu2 = { void apply(inout modifier16_t value, out bit<16> read_value) { read_value = value.increment; if(value.increment == 16w0) { value.increment = eg_md.outer_l4_src_max; } else value.increment = value.increment - eg_md.outer_l4_src_incr; } }; RegisterAction<modifier16_t, bit<16>, bit<16>>(outer_l4_src_increment_reg) outer_l4_src_increment_alu = { void apply(inout modifier16_t value, out bit<16> read_value) { read_value = value.increment; if(value.increment > eg_md.outer_l4_src_max) { value.increment = 16w0; } else value.increment = value.increment + eg_md.outer_l4_src_incr; } }; action outer_l4_src_increment_action1() { eg_md.outer_l4_src_incr = 16w0; eg_md.outer_l4_src_mod = eg_md.outer_l4_src_mod + outer_l4_src_increment_alu1.execute(eg_md.outer_l4_src_index); } action outer_l4_src_increment_action() { eg_md.outer_l4_src_mod = eg_md.outer_l4_src_mod + outer_l4_src_increment_alu.execute(eg_md.outer_l4_src_index); } action outer_l4_src_increment_action2() { eg_md.outer_l4_src_mod = eg_md.outer_l4_src_mod + outer_l4_src_increment_alu2.execute(eg_md.outer_l4_src_index); }
    Register<modifier16_t, bit<16>>(1024) outer_l4_dst_increment_reg; RegisterAction<modifier16_t, bit<16>, bit<16>>(outer_l4_dst_increment_reg) outer_l4_dst_increment_alu1 = { void apply(inout modifier16_t value, out bit<16> read_value) { if(value.increment > eg_md.outer_l4_dst_max) { value.increment = 16w0; } read_value = value.increment; } }; RegisterAction<modifier16_t, bit<16>, bit<16>>(outer_l4_dst_increment_reg) outer_l4_dst_increment_alu2 = { void apply(inout modifier16_t value, out bit<16> read_value) { read_value = value.increment; if(value.increment == 16w0) { value.increment = eg_md.outer_l4_dst_max; } else value.increment = value.increment - eg_md.outer_l4_dst_incr; } }; RegisterAction<modifier16_t, bit<16>, bit<16>>(outer_l4_dst_increment_reg) outer_l4_dst_increment_alu = { void apply(inout modifier16_t value, out bit<16> read_value) { read_value = value.increment; if(value.increment > eg_md.outer_l4_dst_max) { value.increment = 16w0; } else value.increment = value.increment + eg_md.outer_l4_dst_incr; } }; action outer_l4_dst_increment_action1() { eg_md.outer_l4_dst_incr = 16w0; eg_md.outer_l4_dst_mod = eg_md.outer_l4_dst_mod + outer_l4_dst_increment_alu1.execute(eg_md.outer_l4_dst_index); } action outer_l4_dst_increment_action() { eg_md.outer_l4_dst_mod = eg_md.outer_l4_dst_mod + outer_l4_dst_increment_alu.execute(eg_md.outer_l4_dst_index); } action outer_l4_dst_increment_action2() { eg_md.outer_l4_dst_mod = eg_md.outer_l4_dst_mod + outer_l4_dst_increment_alu2.execute(eg_md.outer_l4_dst_index); }
    table src_mac_stateful { key = { eg_md.src_mac_repeat : ternary; eg_md.src_mac_incr : ternary; eg_md.src_mac_opcode : ternary; } actions = { src_mac_increment_action; src_mac_increment_action1; src_mac_increment_action2; } const entries = { (0,_,1) : src_mac_increment_action(); (0,_,2) : src_mac_increment_action2(); (_,0,_) : src_mac_increment_action1(); (_,_,_) : src_mac_increment_action1(); } size = 4; }
    table dst_mac_stateful { key = { eg_md.dst_mac_repeat : ternary; eg_md.dst_mac_incr : ternary; eg_md.dst_mac_opcode : ternary; } actions = { dst_mac_increment_action; dst_mac_increment_action1; dst_mac_increment_action2; } const entries = { (0,_,1) : dst_mac_increment_action(); (0,_,2) : dst_mac_increment_action2(); (_,0,_) : dst_mac_increment_action1(); (_,_,_) : dst_mac_increment_action1(); } size = 4; }
    table vlan_tag_stateful { key = { eg_md.vlan_tag_repeat : ternary; eg_md.vlan_tag_incr : ternary; eg_md.vlan_tag_opcode : ternary; } actions = { vlan_tag_increment_action; vlan_tag_increment_action1; vlan_tag_increment_action2; } const entries = { (0,_,1) : vlan_tag_increment_action(); (0,_,2) : vlan_tag_increment_action2(); (_,0,_) : vlan_tag_increment_action1(); (_,_,_) : vlan_tag_increment_action1(); } size = 4; }
    table outer_mpls_tag_stateful { key = { eg_md.outer_mpls_tag_repeat : ternary; eg_md.outer_mpls_tag_incr : ternary; eg_md.outer_mpls_tag_opcode : ternary; } actions = { outer_mpls_tag_increment_action; outer_mpls_tag_increment_action1; outer_mpls_tag_increment_action2; } const entries = { (0,_,1) : outer_mpls_tag_increment_action(); (0,_,2) : outer_mpls_tag_increment_action2(); (_,0,_) : outer_mpls_tag_increment_action1(); (_,_,_) : outer_mpls_tag_increment_action1(); } size = 4; }
    table outer_l3_src_stateful { key = { eg_md.outer_l3_src_repeat : ternary; eg_md.outer_l3_src_incr : ternary; eg_md.outer_l3_src_opcode : ternary; } actions = { outer_l3_src_increment_action; outer_l3_src_increment_action1; outer_l3_src_increment_action2; } const entries = { (0,_,1) : outer_l3_src_increment_action(); (0,_,2) : outer_l3_src_increment_action2(); (_,0,_) : outer_l3_src_increment_action1(); (_,_,_) : outer_l3_src_increment_action1(); } size = 4; }
    table outer_l3_dst_stateful { key = { eg_md.outer_l3_dst_repeat : ternary; eg_md.outer_l3_dst_incr : ternary; eg_md.outer_l3_dst_opcode : ternary; } actions = { outer_l3_dst_increment_action; outer_l3_dst_increment_action1; outer_l3_dst_increment_action2; } const entries = { (0,_,1) : outer_l3_dst_increment_action(); (0,_,2) : outer_l3_dst_increment_action2(); (_,0,_) : outer_l3_dst_increment_action1(); (_,_,_) : outer_l3_dst_increment_action1(); } size = 4; }
    table outer_l4_src_stateful { key = { eg_md.outer_l4_src_repeat : ternary; eg_md.outer_l4_src_incr : ternary; eg_md.outer_l4_src_opcode : ternary; } actions = { outer_l4_src_increment_action; outer_l4_src_increment_action1; outer_l4_src_increment_action2; } const entries = { (0,_,1) : outer_l4_src_increment_action(); (0,_,2) : outer_l4_src_increment_action2(); (_,0,_) : outer_l4_src_increment_action1(); (_,_,_) : outer_l4_src_increment_action1(); } size = 4; }
    table outer_l4_dst_stateful { key = { eg_md.outer_l4_dst_repeat : ternary; eg_md.outer_l4_dst_incr : ternary; eg_md.outer_l4_dst_opcode : ternary; } actions = { outer_l4_dst_increment_action; outer_l4_dst_increment_action1; outer_l4_dst_increment_action2; } const entries = { (0,_,1) : outer_l4_dst_increment_action(); (0,_,2) : outer_l4_dst_increment_action2(); (_,0,_) : outer_l4_dst_increment_action1(); (_,_,_) : outer_l4_dst_increment_action1(); } size = 4; }
    apply
    {
        src_mac_stateful.apply();
        dst_mac_stateful.apply();
        vlan_tag_stateful.apply();
        outer_mpls_tag_stateful.apply();
        outer_l3_src_stateful.apply();
        outer_l3_dst_stateful.apply();
        outer_l4_src_stateful.apply();
        outer_l4_dst_stateful.apply();
    }
}


control process_egress_headers(in header_t hdr, in egress_intrinsic_metadata_t eg_intr_md, inout egress_metadata_t eg_md)
{
    @name("._nop")
    action _nop()
    {
    }
# 209 "modifier.p4"
    action do_process_outer_ipv6_src_0_dst_0() { eg_md.outer_l3_src_mod = hdr.outer_ipv6.srcAddr0; eg_md.outer_l3_dst_mod = hdr.outer_ipv6.dstAddr0; eg_md.src_ipv6_mod_index =0; eg_md.dst_ipv6_mod_index = 0; }
    action do_process_outer_ipv6_src_0_dst_1() { eg_md.outer_l3_src_mod = hdr.outer_ipv6.srcAddr0; eg_md.outer_l3_dst_mod = hdr.outer_ipv6.dstAddr1; eg_md.src_ipv6_mod_index =0; eg_md.dst_ipv6_mod_index = 1; }
    action do_process_outer_ipv6_src_0_dst_2() { eg_md.outer_l3_src_mod = hdr.outer_ipv6.srcAddr0; eg_md.outer_l3_dst_mod = hdr.outer_ipv6.dstAddr2; eg_md.src_ipv6_mod_index =0; eg_md.dst_ipv6_mod_index = 2; }
    action do_process_outer_ipv6_src_0_dst_3() { eg_md.outer_l3_src_mod = hdr.outer_ipv6.srcAddr0; eg_md.outer_l3_dst_mod = hdr.outer_ipv6.dstAddr3; eg_md.src_ipv6_mod_index =0; eg_md.dst_ipv6_mod_index = 3; }
    action do_process_outer_ipv6_src_1_dst_0() { eg_md.outer_l3_src_mod = hdr.outer_ipv6.srcAddr1; eg_md.outer_l3_dst_mod = hdr.outer_ipv6.dstAddr0; eg_md.src_ipv6_mod_index =1; eg_md.dst_ipv6_mod_index = 0; }
    action do_process_outer_ipv6_src_1_dst_1() { eg_md.outer_l3_src_mod = hdr.outer_ipv6.srcAddr1; eg_md.outer_l3_dst_mod = hdr.outer_ipv6.dstAddr1; eg_md.src_ipv6_mod_index =1; eg_md.dst_ipv6_mod_index = 1; }
    action do_process_outer_ipv6_src_1_dst_2() { eg_md.outer_l3_src_mod = hdr.outer_ipv6.srcAddr1; eg_md.outer_l3_dst_mod = hdr.outer_ipv6.dstAddr2; eg_md.src_ipv6_mod_index =1; eg_md.dst_ipv6_mod_index = 2; }
    action do_process_outer_ipv6_src_1_dst_3() { eg_md.outer_l3_src_mod = hdr.outer_ipv6.srcAddr1; eg_md.outer_l3_dst_mod = hdr.outer_ipv6.dstAddr3; eg_md.src_ipv6_mod_index =1; eg_md.dst_ipv6_mod_index = 3; }
    action do_process_outer_ipv6_src_2_dst_0() { eg_md.outer_l3_src_mod = hdr.outer_ipv6.srcAddr2; eg_md.outer_l3_dst_mod = hdr.outer_ipv6.dstAddr0; eg_md.src_ipv6_mod_index =2; eg_md.dst_ipv6_mod_index = 0; }
    action do_process_outer_ipv6_src_2_dst_1() { eg_md.outer_l3_src_mod = hdr.outer_ipv6.srcAddr2; eg_md.outer_l3_dst_mod = hdr.outer_ipv6.dstAddr1; eg_md.src_ipv6_mod_index =2; eg_md.dst_ipv6_mod_index = 1; }
    action do_process_outer_ipv6_src_2_dst_2() { eg_md.outer_l3_src_mod = hdr.outer_ipv6.srcAddr2; eg_md.outer_l3_dst_mod = hdr.outer_ipv6.dstAddr2; eg_md.src_ipv6_mod_index =2; eg_md.dst_ipv6_mod_index = 2; }
    action do_process_outer_ipv6_src_2_dst_3() { eg_md.outer_l3_src_mod = hdr.outer_ipv6.srcAddr2; eg_md.outer_l3_dst_mod = hdr.outer_ipv6.dstAddr3; eg_md.src_ipv6_mod_index =2; eg_md.dst_ipv6_mod_index = 3; }
    action do_process_outer_ipv6_src_3_dst_0() { eg_md.outer_l3_src_mod = hdr.outer_ipv6.srcAddr3; eg_md.outer_l3_dst_mod = hdr.outer_ipv6.dstAddr0; eg_md.src_ipv6_mod_index =3; eg_md.dst_ipv6_mod_index = 0; }
    action do_process_outer_ipv6_src_3_dst_1() { eg_md.outer_l3_src_mod = hdr.outer_ipv6.srcAddr3; eg_md.outer_l3_dst_mod = hdr.outer_ipv6.dstAddr1; eg_md.src_ipv6_mod_index =3; eg_md.dst_ipv6_mod_index = 1; }
    action do_process_outer_ipv6_src_3_dst_2() { eg_md.outer_l3_src_mod = hdr.outer_ipv6.srcAddr3; eg_md.outer_l3_dst_mod = hdr.outer_ipv6.dstAddr2; eg_md.src_ipv6_mod_index =3; eg_md.dst_ipv6_mod_index = 2; }
    action do_process_outer_ipv6_src_3_dst_3() { eg_md.outer_l3_src_mod = hdr.outer_ipv6.srcAddr3; eg_md.outer_l3_dst_mod = hdr.outer_ipv6.dstAddr3; eg_md.src_ipv6_mod_index =3; eg_md.dst_ipv6_mod_index = 3; }

    table process_outer_ipv6_tbl
    {
        actions =
        {
            do_process_outer_ipv6_src_0_dst_0;
            do_process_outer_ipv6_src_0_dst_1;
            do_process_outer_ipv6_src_0_dst_2;
            do_process_outer_ipv6_src_0_dst_3;
            do_process_outer_ipv6_src_1_dst_0;
            do_process_outer_ipv6_src_1_dst_1;
            do_process_outer_ipv6_src_1_dst_2;
            do_process_outer_ipv6_src_1_dst_3;
            do_process_outer_ipv6_src_2_dst_0;
            do_process_outer_ipv6_src_2_dst_1;
            do_process_outer_ipv6_src_2_dst_2;
            do_process_outer_ipv6_src_2_dst_3;
            do_process_outer_ipv6_src_3_dst_0;
            do_process_outer_ipv6_src_3_dst_1;
            do_process_outer_ipv6_src_3_dst_2;
            do_process_outer_ipv6_src_3_dst_3;
        }
        key =
        {
            hdr.bridged_md.stream: ternary;
            eg_intr_md.egress_port: ternary;
        }
        // NOTE for IPv6 populate eg_md.l3_src/eg_md.l3_dst mod md to 0,0 default
        // this is to match with default entry of process_outer_ipv6_mods_tbl which is
        // for src_index = 0, dst_index = 0 --> calling do_process_outer_ipv6_src_0_dst_0_mods
        // which modifies src word 0 dst word 0
        // MAGIC
        default_action = do_process_outer_ipv6_src_0_dst_0();
        size = 1025;
    }

    apply
    {
        if(hdr.mpls_tag[0].isValid())
        {
            eg_md.outer_mpls_mod = (bit<32>)hdr.mpls_tag[0].label;
        }
        if(hdr.inner_vlan_tag[0].isValid())
        {
            eg_md.vlan_mod = (bit<16>)hdr.inner_vlan_tag[0].vid;
        }
        if(hdr.outer_ipv4.isValid())
        {
            eg_md.outer_l3_src_mod = hdr.outer_ipv4.srcAddr;
            eg_md.outer_l3_dst_mod = hdr.outer_ipv4.dstAddr;
        }
        if(hdr.outer_ipv6.isValid())
        {
            process_outer_ipv6_tbl.apply();
        }
        if(hdr.outer_udp.isValid())
        {
            eg_md.outer_l4_src_mod = hdr.outer_udp.srcPort;
            eg_md.outer_l4_dst_mod = hdr.outer_udp.dstPort;
        }
        if(hdr.outer_tcp.isValid())
        {
            eg_md.outer_l4_src_mod = hdr.outer_tcp.srcPort;
            eg_md.outer_l4_dst_mod = hdr.outer_tcp.dstPort;
        }
    }
}

control process_egress_header_mods(inout header_t hdr, in egress_intrinsic_metadata_t eg_intr_md, in egress_metadata_t eg_md)
{
    @name("._nop")
    action _nop()
    {
    }
# 307 "modifier.p4"
    action do_process_outer_ipv6_src_0_dst_0_mods() { hdr.outer_ipv6.srcAddr0 = eg_md.outer_l3_src_mod; hdr.outer_ipv6.dstAddr0 = eg_md.outer_l3_dst_mod; }
    action do_process_outer_ipv6_src_0_dst_1_mods() { hdr.outer_ipv6.srcAddr0 = eg_md.outer_l3_src_mod; hdr.outer_ipv6.dstAddr1 = eg_md.outer_l3_dst_mod; }
    action do_process_outer_ipv6_src_0_dst_2_mods() { hdr.outer_ipv6.srcAddr0 = eg_md.outer_l3_src_mod; hdr.outer_ipv6.dstAddr2 = eg_md.outer_l3_dst_mod; }
    action do_process_outer_ipv6_src_0_dst_3_mods() { hdr.outer_ipv6.srcAddr0 = eg_md.outer_l3_src_mod; hdr.outer_ipv6.dstAddr3 = eg_md.outer_l3_dst_mod; }
    action do_process_outer_ipv6_src_1_dst_0_mods() { hdr.outer_ipv6.srcAddr1 = eg_md.outer_l3_src_mod; hdr.outer_ipv6.dstAddr0 = eg_md.outer_l3_dst_mod; }
    action do_process_outer_ipv6_src_1_dst_1_mods() { hdr.outer_ipv6.srcAddr1 = eg_md.outer_l3_src_mod; hdr.outer_ipv6.dstAddr1 = eg_md.outer_l3_dst_mod; }
    action do_process_outer_ipv6_src_1_dst_2_mods() { hdr.outer_ipv6.srcAddr1 = eg_md.outer_l3_src_mod; hdr.outer_ipv6.dstAddr2 = eg_md.outer_l3_dst_mod; }
    action do_process_outer_ipv6_src_1_dst_3_mods() { hdr.outer_ipv6.srcAddr1 = eg_md.outer_l3_src_mod; hdr.outer_ipv6.dstAddr3 = eg_md.outer_l3_dst_mod; }
    action do_process_outer_ipv6_src_2_dst_0_mods() { hdr.outer_ipv6.srcAddr2 = eg_md.outer_l3_src_mod; hdr.outer_ipv6.dstAddr0 = eg_md.outer_l3_dst_mod; }
    action do_process_outer_ipv6_src_2_dst_1_mods() { hdr.outer_ipv6.srcAddr2 = eg_md.outer_l3_src_mod; hdr.outer_ipv6.dstAddr1 = eg_md.outer_l3_dst_mod; }
    action do_process_outer_ipv6_src_2_dst_2_mods() { hdr.outer_ipv6.srcAddr2 = eg_md.outer_l3_src_mod; hdr.outer_ipv6.dstAddr2 = eg_md.outer_l3_dst_mod; }
    action do_process_outer_ipv6_src_2_dst_3_mods() { hdr.outer_ipv6.srcAddr2 = eg_md.outer_l3_src_mod; hdr.outer_ipv6.dstAddr3 = eg_md.outer_l3_dst_mod; }
    action do_process_outer_ipv6_src_3_dst_0_mods() { hdr.outer_ipv6.srcAddr3 = eg_md.outer_l3_src_mod; hdr.outer_ipv6.dstAddr0 = eg_md.outer_l3_dst_mod; }
    action do_process_outer_ipv6_src_3_dst_1_mods() { hdr.outer_ipv6.srcAddr3 = eg_md.outer_l3_src_mod; hdr.outer_ipv6.dstAddr1 = eg_md.outer_l3_dst_mod; }
    action do_process_outer_ipv6_src_3_dst_2_mods() { hdr.outer_ipv6.srcAddr3 = eg_md.outer_l3_src_mod; hdr.outer_ipv6.dstAddr2 = eg_md.outer_l3_dst_mod; }
    action do_process_outer_ipv6_src_3_dst_3_mods() { hdr.outer_ipv6.srcAddr3 = eg_md.outer_l3_src_mod; hdr.outer_ipv6.dstAddr3 = eg_md.outer_l3_dst_mod; }

    table process_outer_ipv6_mods_tbl
    {
        actions =
        {
            _nop;
            do_process_outer_ipv6_src_0_dst_0_mods;
            do_process_outer_ipv6_src_0_dst_1_mods;
            do_process_outer_ipv6_src_0_dst_2_mods;
            do_process_outer_ipv6_src_0_dst_3_mods;
            do_process_outer_ipv6_src_1_dst_0_mods;
            do_process_outer_ipv6_src_1_dst_1_mods;
            do_process_outer_ipv6_src_1_dst_2_mods;
            do_process_outer_ipv6_src_1_dst_3_mods;
            do_process_outer_ipv6_src_2_dst_0_mods;
            do_process_outer_ipv6_src_2_dst_1_mods;
            do_process_outer_ipv6_src_2_dst_2_mods;
            do_process_outer_ipv6_src_2_dst_3_mods;
            do_process_outer_ipv6_src_3_dst_0_mods;
            do_process_outer_ipv6_src_3_dst_1_mods;
            do_process_outer_ipv6_src_3_dst_2_mods;
            do_process_outer_ipv6_src_3_dst_3_mods;
        }
        key =
        {
            eg_md.src_ipv6_mod_index : exact;
            eg_md.dst_ipv6_mod_index : exact;
        }
        const entries =
        {
            (0, 0) : do_process_outer_ipv6_src_0_dst_0_mods;
            (0, 1) : do_process_outer_ipv6_src_0_dst_1_mods;
            (0, 2) : do_process_outer_ipv6_src_0_dst_2_mods;
            (0, 3) : do_process_outer_ipv6_src_0_dst_3_mods;
            (1, 0) : do_process_outer_ipv6_src_1_dst_0_mods;
            (1, 1) : do_process_outer_ipv6_src_1_dst_1_mods;
            (1, 2) : do_process_outer_ipv6_src_1_dst_2_mods;
            (1, 3) : do_process_outer_ipv6_src_1_dst_3_mods;
            (2, 0) : do_process_outer_ipv6_src_2_dst_0_mods;
            (2, 1) : do_process_outer_ipv6_src_2_dst_1_mods;
            (2, 2) : do_process_outer_ipv6_src_2_dst_2_mods;
            (2, 3) : do_process_outer_ipv6_src_2_dst_3_mods;
            (3, 0) : do_process_outer_ipv6_src_3_dst_0_mods;
            (3, 1) : do_process_outer_ipv6_src_3_dst_1_mods;
            (3, 2) : do_process_outer_ipv6_src_3_dst_2_mods;
            (3, 3) : do_process_outer_ipv6_src_3_dst_3_mods;
        }
        default_action = _nop;
        size = 17;
    }

    apply
    {
        if(hdr.mpls_tag[0].isValid())
        {
            hdr.mpls_tag[0].label = (bit<20>)eg_md.outer_mpls_mod;
        }
        if(hdr.vlan_tag[0].isValid())
        {
            hdr.vlan_tag[0].vid = (bit<12>)eg_md.vlan_mod;
        }
        if(hdr.outer_ipv4.isValid())
        {
            hdr.outer_ipv4.srcAddr = eg_md.outer_l3_src_mod;
            hdr.outer_ipv4.dstAddr = eg_md.outer_l3_dst_mod;
        }
        if(hdr.outer_ipv6.isValid())
        {
            process_outer_ipv6_mods_tbl.apply();
        }
        if(hdr.outer_udp.isValid())
        {
            hdr.outer_udp.srcPort = eg_md.outer_l4_src_mod;
            hdr.outer_udp.dstPort = eg_md.outer_l4_dst_mod;
        }
        if(hdr.outer_tcp.isValid())
        {
            hdr.outer_tcp.srcPort = eg_md.outer_l4_src_mod;
            hdr.outer_tcp.dstPort = eg_md.outer_l4_dst_mod;
        }
    }
}
# 44 "nanite.p4" 2
# 1 "tx_instrum.p4" 1
/*------------------------------------------------------------------------
    tx_instrum.p4 - Module to compute register index for sequence number and insert timestamp and corresponding
                    sequence number into Ixia instrumentation if there is an Ixia signature in the stream.
                    The existence of a signature is programmed by the control plane per stream. 

    Copyright (C) 2019 by Keysight Technologies
    All Rights Reserved.
*-----------------------------------------------------------------------*/

control process_instrum_seqnum(inout header_t hdr, inout egress_metadata_t eg_md)
{
 @name(".tx_seq_incr_reg")
 Register<bit<32>,bit<16>>(32w16384) tx_seq_incr_reg;

 @name(".seq_incr_gen_salu")
    RegisterAction<bit<32>, bit<32>, bit<32>>(tx_seq_incr_reg) seq_incr_gen_salu =
 {
        void apply(inout bit<32> value, out bit<32> rv)
  {
            rv = 32w0;
            bit<32> in_value;
            in_value = value;
            value = in_value + 32w1;
            rv = value;
        }
    };

 @name(".do_incr_seqnum")
    action do_incr_seqnum()
 {
        hdr.instrum.seqnum = (bit<16>)seq_incr_gen_salu.execute((bit<32>)eg_md.pgid_pipe_port_index);
    }

    @name(".incr_seqnum_tbl")
    table incr_seqnum_tbl
 {
        actions =
  {
            do_incr_seqnum;
        }

  key =
  {
   eg_md.tx_instrum: exact;
  }

  const entries =
  {
   1 : do_incr_seqnum();
  }

        size = 1;
    }

 apply
 {
  incr_seqnum_tbl.apply();
 }
}

control process_eg_mac_ts(inout header_t hdr, in egress_intrinsic_metadata_t eg_intr_md, in egress_metadata_t eg_md)
{
 @name(".do_eg_insert_ptp_hdr")
 action do_eg_insert_ptp_hdr(bit<8> l4_checksum_offset, bit<8> ts_offset)
 {
  hdr.ptp_mac_hdr.setValid();
  hdr.ptp_mac_hdr.udp_cksum_byte_offset = l4_checksum_offset;
  hdr.ptp_mac_hdr.cf_byte_offset = ts_offset;
  hdr.ptp_mac_hdr.updated_cf = 48w0;
  hdr.instrum_tstamp.setInvalid();
 }

 @name(".eg_insert_ptp_hdr_tbl")
 table eg_insert_ptp_hdr_tbl
 {
  actions =
  {
   do_eg_insert_ptp_hdr;
  }

  key =
  {
   hdr.bridged_md.stream: ternary;
   eg_intr_md.egress_port: ternary;
  }
  size = 1024;
 }

 apply
 {
  if(eg_md.mac_timestamp_enable == 1w1 && eg_md.tx_instrum == 1w1)
  {
   eg_insert_ptp_hdr_tbl.apply();
  }
 }
}

control process_eg_parser_ts(inout header_t hdr, in egress_intrinsic_metadata_t eg_intr_md,
                             inout egress_metadata_t eg_md, in egress_intrinsic_metadata_from_parser_t eg_intr_from_prsr)
{
 @name(".do_populate_instrum")
    action do_populate_instrum(bit<32> offset)
 {
        hdr.instrum_tstamp.tstamp = (bit<32>)eg_intr_from_prsr.global_tstamp + offset;
    }

 @name(".eg_populate_instrum_tbl")
    table eg_populate_instrum_tbl
 {
        actions =
  {
            do_populate_instrum;
        }
  key =
  {
            eg_intr_md.egress_port: exact;
        }

        size = 128;
        default_action = do_populate_instrum(0);
    }

 apply
 {
  if(eg_md.mac_timestamp_enable == 1w0 && eg_md.tx_instrum == 1w1)
  {
   eg_populate_instrum_tbl.apply();
  }
 }
}

control calib_rx_tstamp(inout header_t hdr, in ingress_intrinsic_metadata_t ig_intr_md, inout ingress_metadata_t ig_md)
{
    @name(".do_calib_rx_tstamp")
 action do_calib_rx_tstamp(bit<32> offset)
 {
        ig_md.rx_tstamp_calibrated = hdr.instrum_tstamp.tstamp + offset;
    }

    @name(".do_calib_rx_tstamp_tbl")
 table do_calib_rx_tstamp_tbl
 {
        actions =
  {
            do_calib_rx_tstamp;
        }

        key =
  {
            ig_intr_md.ingress_port: exact;
        }
        size = 128;
        default_action = do_calib_rx_tstamp(0);
    }

    apply
 {
        do_calib_rx_tstamp_tbl.apply();
    }
}
# 45 "nanite.p4" 2
# 1 "burst_pkt_cntr.p4" 1
/*------------------------------------------------------------------------
    burst_pkt_cntr.p4  - Implement bursts by counting packets to burst size.
                         Indices larger than burst size are dropped.

    Copyright (C) 2019 by Keysight Technologies
    All Rights Reserved.
*-----------------------------------------------------------------------*/

control process_load_burst_pkt_cntr(inout header_t hdr,
                                    inout egress_metadata_t eg_md,
                                    in egress_intrinsic_metadata_t eg_intr_md)
{
 @name(".do_load_burst_pkt_cntr_counter_params")
    action do_load_burst_pkt_cntr_counter_params(bit<32> max_hi, bit<32> max_low)
 {
        eg_md.burst_pkt_cntr.max_hi = max_hi;
        eg_md.burst_pkt_cntr.max_low = max_low;
        eg_md.burst_mode = 1w1;
    }

 @name(".load_burst_pkt_cntr_params_tbl")
    table load_burst_pkt_cntr_params_tbl
 {
        actions =
  {
            do_load_burst_pkt_cntr_counter_params;
        }
        key =
  {
            hdr.bridged_md.stream: ternary;
            eg_intr_md.egress_port: ternary;
        }
        size = 1024;
    }

 apply
 {
  load_burst_pkt_cntr_params_tbl.apply();
 }
}

control process_incr_burst_pkt_cntr(inout header_t hdr, inout egress_metadata_t eg_md)
{
 @name(".burst_pkt_cntr_reg")
 Register<reg_pair_t, bit<32>>(1024, {0,0}) burst_pkt_cntr_reg;

 @name(".burst_pkt_cntr_salu")
 RegisterAction<reg_pair_t, bit<32>, bit<32>>(burst_pkt_cntr_reg) burst_pkt_cntr_salu =
 {
  void apply(inout reg_pair_t value, out bit<32> rv)
  {
   rv = 32w0;
            reg_pair_t in_value;
            in_value = value;
   rv = (bit<32>)this.predicate(
   in_value.lo != eg_md.burst_pkt_cntr.max_low,
            in_value.hi < eg_md.burst_pkt_cntr.max_hi);

   if(in_value.hi < eg_md.burst_pkt_cntr.max_hi)
   {
    value.lo = in_value.lo + 32w1;
   }

   if(!(in_value.hi < eg_md.burst_pkt_cntr.max_hi))
   {
    value.lo = in_value.lo;
   }

   if((in_value.hi < eg_md.burst_pkt_cntr.max_hi) &&
      !(in_value.lo != eg_md.burst_pkt_cntr.max_low))
   {
    value.hi = in_value.hi + 32w1;
   }

   if(!(in_value.hi < eg_md.burst_pkt_cntr.max_hi))
   {
    value.hi = in_value.hi;
   }
  }
 };

 @name("._nop")
 action _nop()
 {
    }

 @name(".do_burst_pkt_cntr")
 action do_burst_pkt_cntr()
 {
        eg_md.burst_pkt_cntr.drop = (bit<4>)burst_pkt_cntr_salu.execute((bit<32>)eg_md.port_stream_index);
    }

    @name(".nodrop")
 action nodrop()
 {
        eg_md.burst_pkt_cntr.drop = 4w0;
    }

    @name(".burst_pkt_cntr_tbl")
    table burst_pkt_cntr_tbl
 {
        actions =
  {
            nodrop;
            do_burst_pkt_cntr;
        }
        key =
  {
            eg_md.burst_mode: exact;
        }
        size = 2;
          const entries = {
            0: nodrop();
            1: do_burst_pkt_cntr();
        }
    }
    apply
 {
        burst_pkt_cntr_tbl.apply();
    }
}

control process_burst_drops(inout header_t hdr, inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {

 @name(".do_burst_drop")
    action do_burst_drop()
 {
        eg_intr_md_for_dprsr.drop_ctl = 0x1;
    }

    @name(".burst_drop_tbl")
    table burst_drop_tbl
 {
        actions =
  {
            do_burst_drop;
        }
        size = 1;
        default_action = do_burst_drop();
    }
    apply
 {
        burst_drop_tbl.apply();
    }
}
# 46 "nanite.p4" 2
# 1 "eg_stats.p4" 1
/*------------------------------------------------------------------------
    eg_stats.p4 - Module to compute statistics for egress ports.
    Computes transmit port and per stream statistics.
    Implements bank switching for Tx/Rx Sync.

    Copyright (C) 2019 by Keysight Technologies
    All Rights Reserved.
*-----------------------------------------------------------------------*/

control process_eg_stream_statsA(inout header_t hdr, inout egress_metadata_t eg_md, in egress_intrinsic_metadata_from_parser_t eg_intr_from_prsr)
{
    @Feature(name="TxStreamStatsA", block=eg_port_stats, service=Stats, service_id=TxStreamStatsA, index=stream,
    display_name="Tx Stream Stats A", display_cols="Stream|TxBytesA|TxPacketsA",col_units="|bytes|packets")
    @Api(index=port, label="Tx Stream Stats A", col_labels="Stream|TxStreamBytesA|TxStreamPacketsA",col_units="|bytes|packets")
    @brief("Egress stream stats counter bank A")
    @description("Egress stream stats counter bank A, count all eg stream stats when bank select=0")
    @name(".eg_stream_statsA_cntr")
    Counter<bit<32>, bit<10>>(1024,CounterType_t.PACKETS_AND_BYTES) eg_stream_statsA_cntr;


    @Feature(name="TxStreamTstampA", block=eg_port_stats, service=Stats, service_id=TxStreamTstampA, index=stream,
    display_name="Tx Stream Timestamp A", display_cols="Stream|Hi|Lo",col_units="|ns*2^32|ns")
    @Api(index=stream, label="Tx Stream Timestamp A", col_labels="Stream|Hi|Lo",col_units="|ns*2^32|ns")
    @brief("Egress stream timestamps bank A")
    @description("Egress stream timestamps bank A, record timestamps when bank select=0")
    @name(".tx_egress_stamp_regA")
    Register<reg_pair_t, bit<32>>(256,{0,0}) tx_egress_stamp_regA;

    @name(".do_eg_stream_statsA")
    action do_eg_stream_statsA()
 {
        eg_stream_statsA_cntr.count(eg_md.port_stream_index);
    }

 @name(".eg_stream_statsA_tbl")
    table eg_stream_statsA_tbl
 {
        actions =
  {
            do_eg_stream_statsA;
        }
  // key =
  // {
  // 	eg_md.tx_instrum: exact;
  // 	hdr.bridged_md.bank_select: exact;
  // }

  // const entries =
  // {
  // 	(1, 0): do_eg_stream_statsA();
  // }
        default_action = do_eg_stream_statsA();
        size = 1;
    }

    @name(".store_egress_tstampA_salu")
    RegisterAction<reg_pair_t, bit<32>, bit<32>>(tx_egress_stamp_regA) store_egress_tstampA_salu =
 {
        void apply(inout reg_pair_t value)
  {
            reg_pair_t in_value;
            in_value = value;
            value.hi = (bit<32>)eg_intr_from_prsr.global_tstamp[47:32];
            value.lo = eg_intr_from_prsr.global_tstamp[31:0];
        }
    };

    @name(".do_store_egress_stampA")
    action do_store_egress_stampA()
 {
        store_egress_tstampA_salu.execute((bit<32>)eg_md.pipe_port_stream_index);
    }

 @name(".tx_tstampA_tbl")
    table tx_tstampA_tbl
 {
        actions =
  {
            do_store_egress_stampA;
        }
  // key =
  // {
  // 	eg_md.tx_instrum: exact;
  // 	hdr.bridged_md.bank_select: exact;
  // }
  // const entries =
  // {
  // 	(1, 0): do_store_egress_stampA();
  // }
        default_action = do_store_egress_stampA();
        size = 1;
    }

    apply
 {
        if(eg_md.tx_instrum == 1w1 && hdr.bridged_md.bank_select == 1w0 )
        {
            eg_stream_statsA_tbl.apply();
            tx_tstampA_tbl.apply();
        }
    }
}

control process_eg_stream_statsB(inout header_t hdr, inout egress_metadata_t eg_md, in egress_intrinsic_metadata_from_parser_t eg_intr_from_prsr)
{

    @Feature(name="TxStreamStatsB", block=eg_port_stats, service=Stats, service_id=TxStreamStatsB, index=stream,
    display_name="Tx Stream Stats B", display_cols="Strean|TxBytesB|TxPacketsB",col_units="|bytes|packets")
    @Api(index=port, label="Tx Stream Stats B", col_labels="Stream|TxStreamBytesB|TxStreamPacketsB",col_units="|bytes|packets")
    @brief("Egress stream stats counter bank B")
    @description("Egress stream stats counter bank B, count all eg stream stats when bank select=1")
    @name(".eg_stream_statsB_cntr")
    Counter<bit<32>,bit<10>>(32w4096,CounterType_t.PACKETS_AND_BYTES) eg_stream_statsB_cntr;


    @Feature(name="TxStreamTstampB", block=eg_port_stats, service=Stats, service_id=TxStreamTstampB, index=stream,
    display_name="Tx Stream Timestamp B", display_cols="Stream|Hi|Lo",col_units="|ns*2^32|ns")
    @Api(index=stream, label="Tx Stream Timestamp B", col_labels="Stream|Hi|Lo",col_units="|ns*2^32|ns")
    @brief("Egress stream timestamps bank B")
    @description("Egress stream timestamps bank B, record timestamps when bank select=0")
    @name(".tx_egress_stamp_regB")
    Register<reg_pair_t, bit<32>>(256,{0,0}) tx_egress_stamp_regB;



    @name(".do_eg_stream_statsB")
    action do_eg_stream_statsB()
 {
        eg_stream_statsB_cntr.count(eg_md.port_stream_index);
    }

    @name(".eg_stream_statsB_tbl")
    table eg_stream_statsB_tbl
 {
        actions =
  {
            do_eg_stream_statsB;
        }
  // key =
  // {
  // 	eg_md.tx_instrum: exact;
  // 	hdr.bridged_md.bank_select: exact;
  // }
  // const entries =
  // {
  // 	(1, 1): do_eg_stream_statsB();
  // }
        default_action = do_eg_stream_statsB();
        size = 1;
    }

    RegisterAction<reg_pair_t, bit<32>, bit<32>>(tx_egress_stamp_regB) store_egress_tstampB_salu =
 {
        void apply(inout reg_pair_t value)
  {
            reg_pair_t in_value;
            in_value = value;
            value.hi = (bit<32>)eg_intr_from_prsr.global_tstamp[47:32];
            value.lo = eg_intr_from_prsr.global_tstamp[31:0];
        }
    };

    @name(".do_store_egress_stampB")
    action do_store_egress_stampB()
 {
        store_egress_tstampB_salu.execute((bit<32>)eg_md.pipe_port_stream_index);
    }

    @name(".tx_tstampB_tbl")
    table tx_tstampB_tbl
 {
        actions =
  {
            do_store_egress_stampB;
        }
  // key =
  // {
  // 	eg_md.tx_instrum: exact;
  // 	hdr.bridged_md.bank_select: exact;
  // }
  // const entries =
  // {
  // 	(1, 1): do_store_egress_stampB();
  // }
        default_action = do_store_egress_stampB();
         size = 1;
    }

    apply
 {
        if(eg_md.tx_instrum == 1w1 && hdr.bridged_md.bank_select == 1w1)
        {
            eg_stream_statsB_tbl.apply();
            tx_tstampB_tbl.apply();
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
# 47 "nanite.p4" 2

// Common modules
# 1 "front_panel.p4" 1
/*------------------------------------------------------------------------
    front_panel.p4 - Module to retrieve port indices based on dataplane port
    Copyright (C) 2019 by Keysight Technologies
    All Rights Reserved.
*/

control process_ingress_fp_port(inout header_t hdr, in ingress_intrinsic_metadata_t ig_intr_md, inout ingress_metadata_t ig_md)
{
    @name("._nop")
 action _nop()
 {
    }

    @name(".do_get_fp_port")
    action do_get_fp_port(bit<5> fp_port, bit<3> pipe_port, bit<10> channel_pgid_offset)
 {
        ig_md.fp_port = fp_port;
        ig_md.pipe_port = pipe_port;
  ig_md.rx_pgid = ig_md.rx_pgid + channel_pgid_offset;
    }
    @name(".ingress_get_fp_port_tbl")
    table ingress_get_fp_port_tbl
 {
        actions =
  {
            _nop;
            do_get_fp_port;
        }
        key = {
            ig_intr_md.ingress_port: ternary;
        }
        size = 256;
        default_action = _nop();
# 167 "front_panel.p4"
 }

 apply
 {
  ingress_get_fp_port_tbl.apply();
 }
}

control process_egress_fp_port(inout header_t hdr, in egress_intrinsic_metadata_t eg_intr_md, inout egress_metadata_t eg_md)
{
    @name("._nop")
 action _nop()
 {
    }

    @name(".do_get_eg_fp_port")
    action do_get_eg_fp_port(bit<5> fp_port, bit<3> pipe_port,
 bit<10> channel_pgid_offset, bit<5> channel_stream_offset)
 {
        eg_md.fp_port = fp_port;
        eg_md.pipe_port = pipe_port;
  eg_md.tx_pgid = hdr.instrum.pgid + channel_pgid_offset;
  eg_md.stream_offset = hdr.bridged_md.stream + channel_stream_offset;
    }
    @name(".egress_get_fp_port_tbl")
    table egress_get_fp_port_tbl
 {
        actions =
  {
            _nop;
            do_get_eg_fp_port;
        }
        key = {
            eg_intr_md.egress_port: ternary;
        }
        size = 256;
        default_action = _nop();
# 337 "front_panel.p4"
 }

 apply
 {
  egress_get_fp_port_tbl.apply();
 }
}

control pack_pipe_port_tx_pgid(inout header_t hdr, inout egress_metadata_t eg_md)
{
    Hash<bit<13>>(HashAlgorithm_t.IDENTITY) pack_pipe_port_tx_pgid_hash;

    @name(".do_pack_pipe_port_tx_pgid")
    action do_pack_pipe_port_tx_pgid()
 {
        {
            eg_md.pgid_pipe_port_index =
   (bit<13>)pack_pipe_port_tx_pgid_hash.get({ eg_md.pipe_port, eg_md.tx_pgid });
        }
    }

 @name(".pack_pipe_port_tx_pgid_tbl")
    table pack_pipe_port_tx_pgid_tbl
 {
        actions =
  {
            do_pack_pipe_port_tx_pgid;
        }
        size = 1;
        default_action = do_pack_pipe_port_tx_pgid();
    }

 apply
 {
        pack_pipe_port_tx_pgid_tbl.apply();
    }
}

control pack_port_pgid(inout header_t hdr, inout ingress_metadata_t ig_md)
{
    Hash<bit<15>>(HashAlgorithm_t.IDENTITY) pack_port_pgid_hash;

    @name(".do_pack_port_pgid")
    action do_pack_port_pgid()
 {
        {
            ig_md.port_pgid_index = pack_port_pgid_hash.get({ ig_md.fp_port, ig_md.rx_pgid });;
        }
    }

 @name(".pack_port_pgid_tbl")
    table pack_port_pgid_tbl
 {
        actions =
  {
            do_pack_port_pgid;
        }
        size = 1;
        default_action = do_pack_port_pgid();
    }

    apply
 {
        pack_port_pgid_tbl.apply();
    }
}


control pack_pgid_pipe_port(inout header_t hdr, inout ingress_metadata_t ig_md)
{
    Hash<bit<13>>(HashAlgorithm_t.IDENTITY) pack_pgid_pipe_port_hash;
    @name(".do_pack_pgid_pipe_port")
    action do_pack_pgid_pipe_port() {
        {
            ig_md.pgid_pipe_port_index = (bit<13>)pack_pgid_pipe_port_hash.get({ ig_md.pipe_port, ig_md.rx_pgid });
        }
    }
    @name(".pack_pgid_pipe_port_tbl")
    table pack_pgid_pipe_port_tbl
 {
        actions =
  {
            do_pack_pgid_pipe_port;
        }
        size = 1;
        default_action = do_pack_pgid_pipe_port();
    }

    apply
 {
        pack_pgid_pipe_port_tbl.apply();
    }
}
# 50 "nanite.p4" 2
# 1 "bank_select.p4" 1
/*------------------------------------------------------------------------
    bank_select.p4 - Module to simply store active bank for PGID and stream stats. This allows for Tx/Rx Sync of
    flow statistics through bank switching.

    Copyright (C) 2019 by Keysight Technologies
    All Rights Reserved.
*-----------------------------------------------------------------------*/

control process_bank_select_reg(inout header_t hdr)
{
 @name(".do_set_bank_select")
 action do_set_bank_select(bit<1> bank_select)
 {
  hdr.bridged_md.bank_select = bank_select;
 }

 @name(".bank_select_tbl")
 table bank_select_tbl
 {
  actions =
  {
   do_set_bank_select;
  }
  size = 1;
  default_action = do_set_bank_select(bank_select = 0);
 }
 apply
 {
  bank_select_tbl.apply();
 }
}

control process_bank_select_port_stats_reg(inout header_t hdr, inout egress_metadata_t eg_md)
{
 @name(".do_set_bank_select_port_stats")
 action do_set_bank_select_port_stats(bit<1> bank_select)
 {
  eg_md.bank_select_port_stats = bank_select;
 }

 @name(".bank_select_port_stats_tbl")
 table bank_select_port_stats_tbl
 {
  actions =
  {
   do_set_bank_select_port_stats;
  }
  size = 1;
  default_action = do_set_bank_select_port_stats(bank_select = 0);
 }
 apply
 {
  bank_select_port_stats_tbl.apply();
 }
}
# 51 "nanite.p4" 2
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



control process_load_cpu_parameters(in ingress_intrinsic_metadata_t ig_intr_md, inout ingress_metadata_t ig_md)
{
    @name("._nop")
 action _nop()
 {
    }

    @brief("Enable Ingress-to-CPU port fwding and assign ingress port")
    @description("Enable Ingress-to-CPU port fwding and assign ingress port")
    @name(".load_cpu_enabled_parameter")
    action load_cpu_enabled_parameter()
 {
      ig_md.pcie_cpu_port_enabled = 1w1;
    }


    @brief("Layer-1 ingress to CPU port forwarding table")
    @description("Layer-1 ingress to CPU port forwarding table; select which ingress ports can fwd to CPU")
    @Feature(name="L1IgToCpuPortFwding", block=cpu_port_fwd, service=Fwding, service_id=L1IgToCpuPortFwding,
        display_name="Ingress to CPU Forwarding Table")
    @Api(label="Ingress to CPU Forwarding Table")
    @name(".load_cpu_enabled_parameter_tbl")
    table load_cpu_enabled_parameter_tbl
 {
        actions =
  {
            @Api(label="NOP") _nop;
            @Api(label="Fwd Enabled") load_cpu_enabled_parameter;
        }
        key =
  {
            ig_intr_md.ingress_port: ternary
                                      @brief("Logical datapane Ingress port number")
                                      // optimum display format is in a ront-panel numbering scheme e.g. "1/1"
                                      @Api(label="Rx Port",format=dec,xform_format="fp_ports",wr_xform="fp_to_dp_port",rd_xform="dp_to_fp_port");
        }
  size = 2;
        default_action = _nop();
  const entries =
  {
   16 &&& 511: load_cpu_enabled_parameter();
   0 &&& 511: load_cpu_enabled_parameter();
  }
    }

 apply
 {
        load_cpu_enabled_parameter_tbl.apply();
    }
}


control process_insert_fabric_hdr(inout header_t hdr, in egress_intrinsic_metadata_t eg_intr_md)
{
 @name(".insert_fabric_hdr")
 action insert_fabric_hdr()
 {
  hdr.fabric_hdr.setValid();
  hdr.fabric_hdr.devPort = (bit<16>)hdr.mirror_bridged_md.ingress_port;
  hdr.fabric_hdr.etherType = hdr.outer_eth.etherType;
  hdr.outer_eth.etherType = 0x8100;
 }

 @name(".insert_fabric_hdr_tbl")
 table insert_fabric_hdr_tbl
 {
  actions =
  {
   insert_fabric_hdr;
  }

  key =
  {
   eg_intr_md.egress_port: exact;
  }
  size = 1;
  const entries =
  {
   16: insert_fabric_hdr();
  }

 }

    // override vid for packet going to CPU
    @name(".set_fabric_devport")
    action set_fabric_devport(bit<16> vid)
    {
        hdr.fabric_hdr.devPort = vid;
    }

    // to remap VLAN id for packets going out to CPU port
    @name(".remap_fabric_dev_port_tbl")
    table remap_fabric_dev_port_tbl
    {
        actions =
        {
            set_fabric_devport;
        }

        key =
        {
            hdr.mirror_bridged_md.ingress_port: exact;
        }
        // TODO: use variable to max fp port count for this
        size = 128;
    }

 apply
 {
  insert_fabric_hdr_tbl.apply();
        remap_fabric_dev_port_tbl.apply();
 }
}

control process_from_cpu_port_forwarding(inout header_t hdr, inout ingress_intrinsic_metadata_for_tm_t ig_tm_md)
{

    @name(".set_md_from_fabric_hdr")
    action set_md_from_fabric_hdr()
 {
        ig_tm_md.ucast_egress_port = (bit<9>)hdr.fabric_hdr.devPort;
        hdr.outer_eth.etherType = hdr.fabric_hdr.etherType;
        hdr.fabric_hdr.setInvalid();
  hdr.bridged_md.is_mirror = 1;
    }

    @name(".select_egress_port_tbl")
    table select_egress_port_tbl
 {
        actions =
  {
            set_md_from_fabric_hdr;
        }
        size = 1;
        default_action = set_md_from_fabric_hdr();
    }

    @name(".set_ucast_port")
    action set_ucast_port(bit<9> eg_port)
    {
        ig_tm_md.ucast_egress_port = eg_port;
    }

    @name(".remap_select_egress_port_tbl")
    table remap_select_egress_port_tbl
    {
        actions =
        {
            set_ucast_port;
        }

        key =
        {
            hdr.fabric_hdr.devPort: exact;
        }

        size = 128;
    }

    apply
 {
        select_egress_port_tbl.apply();
        remap_select_egress_port_tbl.apply();
    }
}


control process_to_cpu_port_forwarding(inout ingress_metadata_t ig_md, inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md)
{

    @name(".do_clone_to_cpu")
    action do_clone_to_cpu(MirrorId_t cpu_mirror_id)
 {
        ig_md.mirror_id = cpu_mirror_id;
        ig_md.is_mirror = 1;
        ig_dprsr_md.drop_ctl = 0x1;
        ig_dprsr_md.mirror_type = MIRROR_TYPE_I2E;
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
# 52 "nanite.p4" 2
# 1 "stream_map.p4" 1
/*------------------------------------------------------------------------
    stream_map.p4 - Module to map each hardware stream to a logical stream id and whether to
    timestamp the packet with the egress MAC or egress parser timestamp
    
    Copyright (C) 2020 by Keysight Technologies
    All Rights Reserved.
*-----------------------------------------------------------------------*/

control process_ig_stream_ids(inout header_t hdr)
{

 @name(".do_pack_pktgen_pipe_app")
 action do_pack_pktgen_pipe_app()
 {
  hdr.bridged_md.stream = hdr.pktgen_header.stream;
 }

 @name(".pack_pktgen_pipe_app_tbl")
 table pack_pktgen_pipe_app_tbl
 {
  actions =
  {
   do_pack_pktgen_pipe_app;
  }

  size = 1;
  default_action = do_pack_pktgen_pipe_app;
 }

 apply
 {
  pack_pktgen_pipe_app_tbl.apply();
 }
}

control process_eg_stream_map(inout header_t hdr, in egress_intrinsic_metadata_t eg_intr_md, inout egress_metadata_t eg_md)
{
 @name(".do_eg_map_stream")
 action do_eg_map_stream(bit<1> mac_timestamp_enable, bit<1> tx_instrum_enable)
 {
  eg_md.mac_timestamp_enable = mac_timestamp_enable;
  eg_md.tx_instrum = tx_instrum_enable;
 }

 @name(".eg_map_stream_tbl")
 table eg_map_stream_tbl
 {
  actions =
  {
   do_eg_map_stream;
  }

  key =
  {
   hdr.bridged_md.stream : ternary;
   eg_intr_md.egress_port : ternary;
  }

  size = 2048;
 }

 apply
 {
  eg_map_stream_tbl.apply();
 }
}

control process_pack_stream_port(inout egress_metadata_t eg_md)
{
    Hash<bit<10>>(HashAlgorithm_t.IDENTITY) port_stream_index_hash;

 @name(".do_pack_stream_port_eg")
    action do_pack_stream_port_eg()
 {
        {
            eg_md.port_stream_index = (bit<10>)port_stream_index_hash.get({ eg_md.fp_port, eg_md.stream_offset });
        }
    }

 @name(".pack_stream_port_tbl_eg")
    table pack_stream_port_tbl_eg
 {
        actions = {
            do_pack_stream_port_eg;
        }
        size = 1;
        default_action = do_pack_stream_port_eg();
    }

 apply
 {
        pack_stream_port_tbl_eg.apply();
    }
}

control process_pack_stream_pipe_port(inout egress_metadata_t eg_md)
{
    Hash<bit<7>>(HashAlgorithm_t.IDENTITY) pipe_port_stream_index_hash;

 @name(".do_pack_stream_pipe_port_eg")
    action do_pack_stream_pipe_port_eg()
 {
        {
            eg_md.pipe_port_stream_index = (bit<7>)pipe_port_stream_index_hash.get({ eg_md.pipe_port, eg_md.stream_offset });
        }
    }

 @name(".pack_stream_pipe_port_tbl_eg")
    table pack_stream_pipe_port_tbl_eg
 {
        actions = {
            do_pack_stream_pipe_port_eg;
        }
        size = 1;
        default_action = do_pack_stream_pipe_port_eg();
    }

 apply
 {
        pack_stream_pipe_port_tbl_eg.apply();
    }
}
# 53 "nanite.p4" 2

//========== TOFINO PARAMETERS ==============
// TODO - Different for TF1/TF2 and various SKUs







// See profiles.p4 for size/scale constants
# 1 "parser.p4" 1
/*------------------------------------------------------------------------
    parser.p4 - Parser/deparser declaration

    Copyright (C) 2019 by Keysight Technologies
    All Rights Reserved.
*-----------------------------------------------------------------------*/

parser TofinoIngressParser(
        packet_in packet,
out ingress_intrinsic_metadata_t ig_intr_md)
{
    state start
 {
        packet.extract(ig_intr_md);
        transition parse_port_metadata;
    }

    state parse_port_metadata
 {

        packet.advance(192);



        transition accept;
    }

}

parser SwitchIngressParser(
        packet_in packet,
        out header_t hdr,
        out ingress_metadata_t ig_md,
        out ingress_intrinsic_metadata_t ig_intr_md)
{

    //TofinoIngressParser() tofino_parser;
    ParserCounter() parser_counter;
    state start
 {
        // TODO: Initialize ig md so p4c doesn't warn
        ig_md.pipe_port = 0;
        ig_md.fp_port = 0;
        ig_md.rx_pgid = 0;
        ig_md.port_pgid_index = 0;
        ig_md.pgid_pipe_port_index = 0;
        ig_md.rx_instrum = 0;
        ig_md.seq_delta = 0;
        ig_md.latency = 0;
        ig_md.lat_to_mem = 0;
        ig_md.lat_to_mem_overflow = 0;
        ig_md.lat_overflow = 0;
        ig_md.known_flow = 0;
        ig_md.seq_incr = 0;
        ig_md.seq_big = 0;
        ig_md.seq_dup = 0;
        ig_md.seq_rvs = 0;
        ig_md.latency_overflow = 0;
        ig_md.tstamp_overflow = 0;
        ig_md.rx_tstamp_calibrated = 0;
        ig_md.is_mirror = 0; // TODO delete
        ig_md.pcie_cpu_port_enabled = 0;
        ig_md.ingress_port = 0;
        //ig_md.et_meta = {0,0,0,0,0,0,0,0,0,0,0};
        ig_md.mirror_id = 0; // needed to pass non-const to deparser mirror.emit()
        hdr.bridged_md.setValid();
        hdr.bridged_md.is_mirror = 0;
        hdr.bridged_md.is_pktgen = 0;
        hdr.bridged_md.bank_select = 0;
        hdr.bridged_md.stream = 0;
        //tofino_parser.apply(packet, ig_intr_md);
        packet.extract(ig_intr_md);
        ig_md.port_properties = port_metadata_unpack<port_metadata_t>(packet);
        parser_counter.set(ig_md.port_properties.field1_offset);
        transition select(ig_intr_md.ingress_port)
  {
            // CPU port should always do normal parsing
            16 &&& 9w0x1ff: parse_i2e_cpu;
            0 &&& 9w0x1ff: parse_i2e_cpu;
            // Pipe 1,3 are recirc pipes for Tofino 1
   // Pipe 0 is recirc pipe for Tofino 2
            // 9 bit port number is
            // [2bit Pipe Id]-[7bit Port Id]
            // For Pipe 0b01 and 0b11, we mask out pipe Id with 0b10 (X1).
            // i.e. if LSB of Pipe Id is 1 then it's from recirc pipe.
            // Consider recirc ports as pktgen ports

            9w0 &&& 9w0x180: parse_pktgen_eth;
            9w0x180 &&& 9w0x180: parse_pktgen_eth;



   9w0xff &&& 9w0xff: parse_fake_ptp;
            default: parse_outer_eth;
        }
    }

    @name(".parse_i2e_cpu")
 state parse_i2e_cpu
 {
        hdr.bridged_md.is_pktgen = 1w0;
        packet.extract(hdr.outer_eth);
        transition select(hdr.outer_eth.etherType)
  {
            0x8100: parse_fabric_only;
            0x9090: parse_fabric_only;
            default: accept;
        }
    }


    @name(".parse_pktgen_eth")
 state parse_pktgen_eth
 {
        hdr.bridged_md.is_pktgen = 1w1;
        packet.extract(hdr.pktgen_header);
        transition select(hdr.pktgen_header.etherType)
  {
            0x9090: parse_fabric;
   0x0800: parse_outer_ipv4;
   0x86dd: parse_outer_ipv6;
   0x8100: parse_vlan;
   0x88A8: parse_vlan;
   0x9100: parse_vlan;
   0x9200: parse_vlan;
   0x9300: parse_vlan;
            0x8847: parse_mpls;
   default: parse_big_sig_ig_instrum;
        }
    }

 @name(".parse_fake_ptp")
 state parse_fake_ptp
 {
  packet.extract(hdr.ptp_eth);
  packet.extract(hdr.ptp_mac_hdr);
  transition parse_outer_eth;
 }

    @name(".parse_fabric_only")
 state parse_fabric_only
 {
        packet.extract(hdr.fabric_hdr);
        transition accept;
    }

    @name(".parse_outer_eth")
 state parse_outer_eth
 {
        hdr.bridged_md.is_pktgen = 1w0;
        packet.extract(hdr.outer_eth);
        //parser_counter.set(hdr.outer_eth.srcAddrHi_0);
        transition select(hdr.outer_eth.etherType)
  {
            (0x9090): parse_fabric;
            (0x8847): parse_mpls;
            (0x0800): parse_outer_ipv4;
            (0x86dd): parse_outer_ipv6;
            (0x8100): parse_vlan;
            (0x88A8): parse_vlan;
            (0x9100): parse_vlan;
            (0x9200): parse_vlan;
            (0x9300): parse_vlan;
            default: parse_big_sig_ig_instrum;
        }
    }
    @name(".parse_outer_eth_field1")
 state parse_outer_eth_vlan
 {
        ig_md.field1 = hdr.vlan_tag[0].vid[7:0];
        transition select(hdr.vlan_tag[0].etherType)
  {
            0x0800: parse_outer_ipv4;
            0x86dd: parse_outer_ipv6;
            0x8100: parse_qinq_vlan;
            0x88A8: parse_qinq_vlan;
            0x9100: parse_qinq_vlan;
            0x9200: parse_qinq_vlan;
            0x9300: parse_qinq_vlan;
            0x8847: parse_mpls;
            default: parse_big_sig_ig_instrum;
        }
    }

    @name(".parse_fabric")
 state parse_fabric
 {
        packet.extract(hdr.fabric_hdr);
        transition select(hdr.fabric_hdr.etherType)
  {
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

 @name(".parse_vlan")
 state parse_vlan
 {
        packet.extract(hdr.vlan_tag[0]);
        parser_counter.decrement(18);
        transition select(parser_counter.is_negative(),hdr.vlan_tag[0].etherType)
  {
            (_, 0x8847): parse_mpls;
            (true, _): parse_outer_eth_vlan;
            (false, 0x0800): parse_outer_ipv4;
            (false, 0x86dd): parse_outer_ipv6;
            (false, 0x8100): parse_qinq_vlan;
            (false, 0x88A8): parse_qinq_vlan;
            (false, 0x9100): parse_qinq_vlan;
            (false, 0x9200): parse_qinq_vlan;
            (false, 0x9300): parse_qinq_vlan;

            default: parse_big_sig_ig_instrum;
        }
    }

 @name(".parse_qinq_vlan")
 state parse_qinq_vlan
 {
        packet.extract(hdr.vlan_tag[1]);
        transition select(hdr.vlan_tag[1].etherType)
  {
            0x0800: parse_outer_ipv4;
            0x86dd: parse_outer_ipv6;
            0x8847: parse_mpls;
            default: parse_big_sig_ig_instrum;
        }
    }

    @name(".parse_mpls")
    state parse_mpls
    {
        packet.extract(hdr.mpls_tag.next);
        transition select(hdr.mpls_tag.last.bos)
        {
            0: parse_mpls;
            1: parse_mpls_bos;
            default: parse_big_sig_ig_instrum;
        }
    }

    @name(".parse_mpls_bos")
    state parse_mpls_bos
    {
        // since we've already parsed the mpls tag
        // scan for first 4bits of label
        // 0x4 for ipv4 0x6 for ipv6
        transition select((packet.lookahead<bit<4>>())[3:0])
        {
            4: parse_outer_ipv4;
            6: parse_outer_ipv6;
            default: parse_big_sig_ig_instrum;
        }
    }

    @name(".parse_outer_ipv4")
 state parse_outer_ipv4
 {
        packet.extract(hdr.outer_ipv4);
        transition select(hdr.outer_ipv4.protocol)
  {
            6: parse_outer_tcp;
            17: parse_outer_udp;
            default: parse_big_sig_ig_instrum;
        }
    }

    @name(".parse_outer_ipv6")
 state parse_outer_ipv6
 {
        packet.extract(hdr.outer_ipv6);
        transition select(hdr.outer_ipv6.nextHdr)
  {
            6: parse_outer_tcp;
            17: parse_outer_udp;
            default: parse_big_sig_ig_instrum;
  }
    }

    @name(".parse_outer_tcp")
 state parse_outer_tcp
 {
        packet.extract(hdr.outer_tcp);
        transition parse_big_sig_ig_instrum;
    }

 @name(".parse_outer_udp")
 state parse_outer_udp
 {
        packet.extract(hdr.outer_udp);
        transition select(hdr.outer_udp.dstPort)
  {
   4789: parse_vxlan;
   default: parse_big_sig_ig_instrum;
  }
    }

 @name(".parse_vxlan")
 state parse_vxlan
 {
  packet.extract(hdr.vxlan);
  transition parse_inner_eth;
 }

 @name(".parse_inner_eth")
 state parse_inner_eth
 {
        packet.extract(hdr.inner_eth);
        transition select(hdr.inner_eth.etherType)
  {
            0x0800: parse_inner_ipv4;
            0x86dd: parse_inner_ipv6;
            0x8100: parse_inner_vlan;
            0x88A8: parse_inner_vlan;
            0x9100: parse_inner_vlan;
            0x9200: parse_inner_vlan;
            0x9300: parse_inner_vlan;
            default: parse_big_sig_ig_instrum;
        }
    }

 @name(".parse_inner_vlan")
 state parse_inner_vlan
 {
        packet.extract(hdr.inner_vlan_tag[0]);
        transition select(hdr.inner_vlan_tag[0].etherType)
  {
            0x0800: parse_inner_ipv4;
            0x86dd: parse_inner_ipv6;
            0x8100: parse_inner_qinq_vlan;
            0x88A8: parse_inner_qinq_vlan;
            0x9100: parse_inner_qinq_vlan;
            0x9200: parse_inner_qinq_vlan;
            0x9300: parse_inner_qinq_vlan;
            default: parse_big_sig_ig_instrum;
        }
    }

 @name(".parse_inner_qinq_vlan")
 state parse_inner_qinq_vlan
 {
        packet.extract(hdr.inner_vlan_tag[1]);
        transition select(hdr.inner_vlan_tag[1].etherType)
  {
            0x0800: parse_inner_ipv4;
            0x86dd: parse_inner_ipv6;
            default: parse_big_sig_ig_instrum;
        }
    }

    @name(".parse_inner_ipv4")
 state parse_inner_ipv4
 {
        packet.extract(hdr.inner_ipv4);
  transition parse_big_sig_ig_instrum;
    }

    @name(".parse_inner_ipv6")
 state parse_inner_ipv6
 {
        packet.extract(hdr.inner_ipv6);
  transition parse_big_sig_ig_instrum;
    }


    @name(".parse_big_sig_ig_instrum")
 state parse_big_sig_ig_instrum
 {
        packet.extract(hdr.big_sig);
        packet.extract(hdr.instrum);
  packet.extract(hdr.instrum_tstamp);
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
        out egress_intrinsic_metadata_t eg_intr_md)
{

    TofinoEgressParser() tofino_parser;

    state start
 {
        // TODO: Initialize eg md so p4c doesn't warn
        eg_md.pipe_port = 0;
        eg_md.fp_port = 0;
        eg_md.port_stream_index = 0;
        eg_md.port_pgid_index = 0;
        eg_md.tx_pgid = 0;
        eg_md.burst_mode = 0;
        eg_md.stream_offset = 0;
        eg_md.tx_instrum = 0;
        eg_md.table_udf_pkt_cntr = {0,0};
        eg_md.burst_pkt_cntr = {0,0,0};
        eg_md.pgid_pipe_port_index = 0;
        eg_md.pipe_port_stream_index = 0;
        eg_md.bank_select_port_stats = 0;
        eg_md.mac_timestamp_enable = 0;
        eg_md.src_mac_max = 0;
        eg_md.src_mac_incr = 0;
        eg_md.src_mac_index = 0;
        eg_md.src_mac_opcode = 0;
        eg_md.src_mac_repeat = 0;
        eg_md.dst_mac_max = 0;
        eg_md.dst_mac_incr = 0;
        eg_md.dst_mac_index = 0;
        eg_md.dst_mac_opcode = 0;
        eg_md.dst_mac_repeat = 0;
        eg_md.vlan_mod = 0;
        eg_md.vlan_tag_max = 0;
        eg_md.vlan_tag_incr = 0;
        eg_md.vlan_tag_index = 0;
        eg_md.vlan_tag_opcode = 0;
        eg_md.vlan_tag_repeat = 0;
        eg_md.outer_mpls_mod = 0;
        eg_md.outer_mpls_tag_max = 0;
        eg_md.outer_mpls_tag_incr = 0;
        eg_md.outer_mpls_tag_index = 0;
        eg_md.outer_mpls_tag_opcode = 0;
        eg_md.outer_mpls_tag_repeat = 0;
        eg_md.outer_l3_src_mod = 0;
        eg_md.outer_l3_src_max = 0;
        eg_md.outer_l3_src_incr = 0;
        eg_md.outer_l3_src_index = 0;
        eg_md.outer_l3_src_opcode = 0;
        eg_md.outer_l3_src_repeat = 0;
        eg_md.outer_l3_dst_mod = 0;
        eg_md.outer_l3_dst_max = 0;
        eg_md.outer_l3_dst_incr = 0;
        eg_md.outer_l3_dst_index = 0;
        eg_md.outer_l3_dst_opcode = 0;
        eg_md.outer_l3_dst_repeat = 0;
        eg_md.src_ipv6_mod_index = 0;
        eg_md.dst_ipv6_mod_index = 0;
        eg_md.outer_l4_src_mod = 0;
        eg_md.outer_l4_src_max = 0;
        eg_md.outer_l4_src_incr = 0;
        eg_md.outer_l4_src_index = 0;
        eg_md.outer_l4_src_opcode = 0;
        eg_md.outer_l4_src_repeat = 0;
        eg_md.outer_l4_dst_mod = 0;
        eg_md.outer_l4_dst_max = 0;
        eg_md.outer_l4_dst_incr = 0;
        eg_md.outer_l4_dst_index = 0;
        eg_md.outer_l4_dst_opcode = 0;
        eg_md.outer_l4_dst_repeat = 0;
        tofino_parser.apply(packet, eg_intr_md);
  ixia_bridged_md_t mirror_md = packet.lookahead<ixia_bridged_md_t>();
  transition select(mirror_md.is_mirror, eg_intr_md.egress_port) {
   (1, 16): parse_mirror;
   (0, _): parse_non_mirror;
   (1, _): parse_cpu_packet;
  }
    }

 state parse_mirror
 {
  packet.extract(hdr.mirror_bridged_md);
  packet.extract(hdr.outer_eth);
  transition accept;
 }


 state parse_non_mirror
 {
  packet.extract(hdr.bridged_md);
  transition select(hdr.bridged_md.is_pktgen, eg_intr_md.egress_port)
  {
   (1, _) : parse_pktgen_eth;
   (0, 9w0xff &&& 9w0xff) : parse_fake_ptp;
            default: parse_outer_eth;
        }
 }

 state parse_cpu_packet
 {
  packet.extract(hdr.bridged_md);
  packet.extract(hdr.outer_eth);
  transition accept;
 }


    @name(".parse_outer_eth")
 state parse_outer_eth
 {
        packet.extract(hdr.outer_eth);
        // pkts may be mirrored or not
        transition select(hdr.outer_eth.etherType) {
            0x9090: parse_fabric; // CPU to f/p - need fabric hdr to get dev_port
            0x0800: parse_outer_ipv4;
            0x86dd: parse_outer_ipv6;
            0x8100: parse_vlan;
            0x88A8: parse_vlan;
            0x9100: parse_vlan;
            0x9200: parse_vlan;
            0x9300: parse_vlan;
            0x8847: parse_mpls;
            default: parse_big_sig_ig_instrum;
        }
    }

 @name(".parse_pktgen_eth")
 state parse_pktgen_eth
 {
        packet.extract(hdr.pktgen_header);
        transition select(hdr.pktgen_header.etherType)
  {
            0x9090: parse_fabric;
   0x0800: parse_outer_ipv4;
   0x86dd: parse_outer_ipv6;
   0x8100: parse_vlan;
   0x88A8: parse_vlan;
   0x9100: parse_vlan;
   0x9200: parse_vlan;
   0x9300: parse_vlan;
            0x8847: parse_mpls;
   default: parse_big_sig_ig_instrum;
        }
    }

 @name(".parse_fake_ptp")
 state parse_fake_ptp
 {
  packet.extract(hdr.ptp_eth);
  packet.extract(hdr.ptp_mac_hdr);
  transition parse_outer_eth;
 }



    @name(".parse_fabric_only")
 state parse_fabric_only
 {
        packet.extract(hdr.fabric_hdr);
        transition accept;
    }

    // state used when sending CPU pkts to f/p ports
    @name(".parse_fabric")
 state parse_fabric
 {
        packet.extract(hdr.fabric_hdr);
        transition select(hdr.fabric_hdr.etherType)
  {
            0x0800: parse_outer_ipv4;
            0x86dd: parse_outer_ipv6;
            0x8100: parse_vlan;
            0x88A8: parse_vlan;
            0x9100: parse_vlan;
            0x9200: parse_vlan;
            0x9300: parse_vlan;
            0x8847: parse_mpls;
            default: parse_big_sig_ig_instrum;
        }
    }

 @name(".parse_vlan")
 state parse_vlan
 {
        packet.extract(hdr.vlan_tag[0]);
        transition select(hdr.vlan_tag[0].etherType)
  {
            0x0800: parse_outer_ipv4;
            0x86dd: parse_outer_ipv6;
            0x8100: parse_qinq_vlan;
            0x88A8: parse_qinq_vlan;
            0x9100: parse_qinq_vlan;
            0x9200: parse_qinq_vlan;
            0x9300: parse_qinq_vlan;
            0x8847: parse_mpls;
            default: parse_big_sig_ig_instrum;
        }
    }

 @name(".parse_qinq_vlan")
 state parse_qinq_vlan
 {
        packet.extract(hdr.vlan_tag[1]);
        transition select(hdr.vlan_tag[1].etherType)
  {
            0x0800: parse_outer_ipv4;
            0x86dd: parse_outer_ipv6;
            0x8847: parse_mpls;
            default: parse_big_sig_ig_instrum;
        }
    }

    @name(".parse_mpls")
    state parse_mpls
    {
        packet.extract(hdr.mpls_tag.next);
        transition select(hdr.mpls_tag.last.bos)
        {
            0: parse_mpls;
            1: parse_mpls_bos;
            default: parse_big_sig_ig_instrum;
        }
    }

    @name(".parse_mpls_bos")
    state parse_mpls_bos
    {
        // since we've already parsed the mpls tag
        // scan for first 4bits of label
        // 0x4 for ipv4 0x6 for ipv6
        transition select((packet.lookahead<bit<4>>())[3:0])
        {
            4: parse_outer_ipv4;
            6: parse_outer_ipv6;
            default: parse_big_sig_ig_instrum;
        }
    }
    @name(".parse_outer_ipv4")
 state parse_outer_ipv4
 {
        packet.extract(hdr.outer_ipv4);
        transition select(hdr.outer_ipv4.protocol)
  {
            6: parse_outer_tcp;
            17: parse_outer_udp;
            default: parse_big_sig_ig_instrum;
        }
    }

    @name(".parse_outer_ipv6")
 state parse_outer_ipv6
 {
        packet.extract(hdr.outer_ipv6);
        transition select(hdr.outer_ipv6.nextHdr)
  {
            6: parse_outer_tcp;
            17: parse_outer_udp;
            default: parse_big_sig_ig_instrum;
  }
    }

    @name(".parse_outer_tcp")
 state parse_outer_tcp
 {
        packet.extract(hdr.outer_tcp);
        transition parse_big_sig_ig_instrum;
    }

 @name(".parse_outer_udp")
 state parse_outer_udp
 {
        packet.extract(hdr.outer_udp);
        transition select(hdr.outer_udp.dstPort)
  {
   4789: parse_vxlan;
   default: parse_big_sig_ig_instrum;
  }
    }

 @name(".parse_vxlan")
 state parse_vxlan
 {
  packet.extract(hdr.vxlan);
  transition parse_inner_eth;
 }

 @name(".parse_inner_eth")
 state parse_inner_eth
 {
        packet.extract(hdr.inner_eth);
        transition select(hdr.inner_eth.etherType)
  {
            0x0800: parse_inner_ipv4;
            0x86dd: parse_inner_ipv6;
            0x8100: parse_inner_vlan;
            0x88A8: parse_inner_vlan;
            0x9100: parse_inner_vlan;
            0x9200: parse_inner_vlan;
            0x9300: parse_inner_vlan;
            default: parse_big_sig_ig_instrum;
        }
    }

 @name(".parse_inner_vlan")
 state parse_inner_vlan
 {
        packet.extract(hdr.inner_vlan_tag[0]);
        transition select(hdr.inner_vlan_tag[0].etherType)
  {
            0x0800: parse_inner_ipv4;
            0x86dd: parse_inner_ipv6;
            0x8100: parse_inner_qinq_vlan;
            0x88A8: parse_inner_qinq_vlan;
            0x9100: parse_inner_qinq_vlan;
            0x9200: parse_inner_qinq_vlan;
            0x9300: parse_inner_qinq_vlan;
            default: parse_big_sig_ig_instrum;
        }
    }

 @name(".parse_inner_qinq_vlan")
 state parse_inner_qinq_vlan
 {
        packet.extract(hdr.inner_vlan_tag[1]);
        transition select(hdr.inner_vlan_tag[1].etherType)
  {
            0x0800: parse_inner_ipv4;
            0x86dd: parse_inner_ipv6;
            default: parse_big_sig_ig_instrum;
        }
    }

    @name(".parse_inner_ipv4")
 state parse_inner_ipv4
 {
        packet.extract(hdr.inner_ipv4);
  transition parse_big_sig_ig_instrum;
    }

    @name(".parse_inner_ipv6")
 state parse_inner_ipv6
 {
        packet.extract(hdr.inner_ipv6);
  transition parse_big_sig_ig_instrum;
    }


    @name(".parse_big_sig_ig_instrum")
 state parse_big_sig_ig_instrum
 {
        packet.extract(hdr.big_sig);
        packet.extract(hdr.instrum);
  packet.extract(hdr.instrum_tstamp);
        transition accept;
    }
}

control SwitchIngressDeparser(
        packet_out packet,
        inout header_t hdr,
        in ingress_metadata_t ig_md,
        in ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md) {

    Mirror() mirror;
    MirrorId_t drop_mirror_id = 0;
    apply
 {
        if (ig_dprsr_md.mirror_type == MIRROR_TYPE_I2E)
  {
   // clone pkt with CPU fabr hdr info
   mirror.emit<mirror_bridged_metadata_t>(ig_md.mirror_id, {ig_md.is_mirror, 6w0, ig_md.ingress_port});
  }
        // BUG: tofino ig deprsr doesn't count bytes properly above certain MTU if packet dropped
        // workaround: use a mirror that's disabled
        // TODO: remove this after SDE 9.11+
        else if(ig_dprsr_md.mirror_type == MIRROR_TYPE_DROP)
        {
            // send to mirror that's disabled, and 0 for all bridge md
            mirror.emit<mirror_bridged_metadata_t>(drop_mirror_id, {0,0,0});
            // BUG: 9.7 compiler complains if there's a mirror without bridge md and another with bridge md
            // mirror.emit(drop_mirror_id);
        }

  packet.emit(hdr.bridged_md);
  packet.emit(hdr.pktgen_header);
        packet.emit(hdr.outer_eth);
        packet.emit(hdr.fabric_hdr);
        packet.emit(hdr.mpls_tag);
        packet.emit(hdr.vlan_tag);
        packet.emit(hdr.outer_ipv6);
        packet.emit(hdr.outer_ipv4);
        packet.emit(hdr.outer_udp);
        packet.emit(hdr.outer_tcp);
  packet.emit(hdr.vxlan);
        packet.emit(hdr.inner_eth);
  packet.emit(hdr.inner_vlan_tag);
        packet.emit(hdr.inner_ipv6);
        packet.emit(hdr.inner_ipv4);
        packet.emit(hdr.big_sig);
        packet.emit(hdr.instrum);
        packet.emit(hdr.instrum_tstamp);
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
  packet.emit(hdr.ptp_mac_hdr);
  packet.emit(hdr.pktgen_header);
        packet.emit(hdr.outer_eth);
        packet.emit(hdr.fabric_hdr);
        packet.emit(hdr.mpls_tag);
        packet.emit(hdr.vlan_tag);
        packet.emit(hdr.outer_ipv6);
        packet.emit(hdr.outer_ipv4);
        packet.emit(hdr.outer_udp);
        packet.emit(hdr.outer_tcp);
  packet.emit(hdr.vxlan);
        packet.emit(hdr.inner_eth);
  packet.emit(hdr.inner_vlan_tag);
        packet.emit(hdr.inner_ipv6);
        packet.emit(hdr.inner_ipv4);
        packet.emit(hdr.big_sig);
        packet.emit(hdr.instrum);
        packet.emit(hdr.instrum_tstamp);
    }
}
# 65 "nanite.p4" 2


control SwitchIngress(
        inout header_t hdr,
        inout ingress_metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_prsr_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_tm_md)
{
    // Ingress control instantiations
 process_rx_signature() process_rx_signature_instance;
 process_bank_select_reg() process_bank_select_reg_instance;
 //process_egress_tracking_data() process_egress_tracking_data_instance;
 process_load_cpu_parameters() process_load_cpu_parameters_instance;
 process_ig_stream_ids() process_ig_stream_ids_instance;
 //pack_pgid_for_egress_tracking()  pack_pgid_for_egress_tracking_instance;
 process_ingress_fp_port() process_ingress_fp_port_instance;
    process_pktgen_port_forwarding() process_pktgen_port_forwarding_instance;
 process_ig_port_stats() process_ig_port_stats_instance;
 pack_port_pgid() pack_port_pgid_instance;
 pack_pgid_pipe_port() pack_pgid_pipe_port_instance;
 process_rx_pgid_flow_tracking() process_rx_pgid_flow_tracking_instance;
 process_ig_pgid_tstampA() process_ig_pgid_tstampA_instance;
 process_ig_pgid_statsA() process_ig_pgid_statsA_instance;




 process_from_cpu_port_forwarding() process_from_cpu_port_forwarding_instance;
 process_to_cpu_port_forwarding() process_to_cpu_port_forwarding_instance;
 process_ig_latency() process_ig_latency_instance;
 process_common_drop() process_common_drop_instance;
    apply
    {
  // Need copy from intrinsic metadata for cloning in deparser
  ig_md.ingress_port = ig_intr_md.ingress_port;

  // Set bridged metatadata valid to append to packet
  hdr.bridged_md.setValid();

  // Look for Ixia Signature and set metadata if there is a match on the port
  process_rx_signature_instance.apply(hdr, ig_intr_md, ig_md);

  // Retrieve active bank for receive side
  process_bank_select_reg_instance.apply(hdr);

  // Retrieve egress tracking data
  //process_egress_tracking_data_instance.apply(hdr, ig_intr_md, ig_md);

  // Determine whether the ingress port is the CPU Port
  process_load_cpu_parameters_instance.apply(ig_intr_md, ig_md);

  // Pack together pktgen pipe id and app id to generate hardware stream id
  process_ig_stream_ids_instance.apply(hdr);

  // Pack egress tracking field with pgid if applicable
  //pack_pgid_for_egress_tracking_instance.apply(ig_md);

  // Map ingress port to front panel port and pipe port
  // Front panel port and pipe port are used to index ingress counters and registers
  // Map instrumentation pgid to metadata rx_pgid by adding channel offset for fanout
  process_ingress_fp_port_instance.apply(hdr, ig_intr_md, ig_md);

  // Compute indicies for pgid registers and counters using front panel port and pipe port
  pack_port_pgid_instance.apply(hdr, ig_md);
  pack_pgid_pipe_port_instance.apply(hdr, ig_md);


        if(hdr.bridged_md.is_pktgen == 1w1)
        {
            process_pktgen_port_forwarding_instance.apply(hdr, ig_md, ig_intr_md, ig_dprsr_md, ig_tm_md);
        }
  else
  {
   if(1w0 == ig_intr_md.resubmit_flag && hdr.fabric_hdr.isValid() && ig_md.pcie_cpu_port_enabled == 1w1)
   {
    // If we are receiving on the CPU port then we need to extract egress port from fabric header
    // Then need to strip fabric header from packet and restore Ethertype from fabric header
    process_from_cpu_port_forwarding_instance.apply(hdr, ig_tm_md);
    // Collect ingress port stats
    process_ig_port_stats_instance.apply(hdr, ig_intr_md, ig_prsr_md, ig_md);
   }
   else
   {
    if(ig_md.rx_instrum == 1w1)
    {
     // Store bit indicating frames received on this pgid
     process_rx_pgid_flow_tracking_instance.apply(ig_md);

     if(hdr.bridged_md.bank_select == 0)
     {
      // If signature matches store rx timestamp for PGID flow statistics
      process_ig_pgid_tstampA_instance.apply(hdr, ig_md, ig_intr_md);

      // Count PGID Bank A stats
      process_ig_pgid_statsA_instance.apply(hdr, ig_md);
     }
# 171 "nanite.p4"
     process_ig_latency_instance.apply(hdr, ig_md, ig_intr_md);
     // this is rx packet from fp with signature, thus drop
     process_common_drop_instance.apply(ig_md, ig_dprsr_md);
    }
    else
    {
     // No matching signature found on packet
     // Forward packet to CPU Egress
     process_to_cpu_port_forwarding_instance.apply(ig_md, ig_dprsr_md);
    }
    // Collect ingress port stats
    process_ig_port_stats_instance.apply(hdr, ig_intr_md, ig_prsr_md, ig_md);
   }
  }
    }

}

control SwitchEgress(
        inout header_t hdr,
        inout egress_metadata_t eg_md,
        in egress_intrinsic_metadata_t eg_intr_md,
        in egress_intrinsic_metadata_from_parser_t eg_intr_from_prsr,
        inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
        inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport)
{
 process_egress_headers() process_egress_headers_instance;
 process_insert_fabric_hdr() process_insert_fabric_hdr_instance;
 process_eg_stream_map() process_eg_stream_map_instance;
 process_load_burst_pkt_cntr() process_load_burst_pkt_cntr_instance;
 process_egress_fp_port() process_egress_fp_port_instance;
 process_eg_mac_ts() process_eg_mac_ts_instance;
 process_prepopulate_ethernet_hdr() process_prepopulate_ethernet_hdr_instance;
 process_pack_stream_port() process_pack_stream_port_instance;
 process_pack_stream_pipe_port() process_pack_stream_pipe_port_instance;
 pack_pipe_port_tx_pgid() pack_pipe_port_tx_pgid_instance;
 process_incr_burst_pkt_cntr() process_incr_burst_pkt_cntr_instance;
 process_counter_udf_repeat() process_counter_udf_repeat_instance;
 process_counter_udf_increment() process_counter_udf_increment_instance;
 process_burst_drops() process_burst_drops_instance;
 process_eg_stream_statsA() process_eg_stream_statsA_instance;
 process_eg_stream_statsB() process_eg_stream_statsB_instance;
 process_egress_header_mods() process_egress_header_mods_instance;
 process_eg_port_stats() process_eg_port_stats_instance;
 process_eg_parser_ts() process_eg_parser_ts_instance;
 apply
 {
  eg_md.burst_mode = 1w0;
  // Remap hardware stream id to logical stream id
  // Mark stream for MAC timestamping and instrumentation valid
  process_eg_stream_map_instance.apply(hdr, eg_intr_md, eg_md);
  // Load burst packet counter if applicable
  process_load_burst_pkt_cntr_instance.apply(hdr, eg_md, eg_intr_md);
  // Map the egress port to a front panel port and store stream channel offset
  // Stream channel offset is used to properly index into egress stream registers for fanout
  process_egress_fp_port_instance.apply(hdr, eg_intr_md, eg_md);

  if (hdr.bridged_md.is_pktgen == 1w1 && eg_intr_md.egress_port & 9w0x180 != 9w0)
  {
   // if packet if from pktgen/recirc and egressing to fp port (even-numbered pipe)
   // Replace pktgen header with ethernet header and populate MAC addresses
   process_prepopulate_ethernet_hdr_instance.apply(hdr, eg_intr_md);
   // Populate egress metadata from packet
   process_egress_headers_instance.apply(hdr, eg_intr_md, eg_md);
   // Remove timestamp portion of instrumentation and add PTP header for MAC timestamping if enabled (MAU hit)
   process_eg_mac_ts_instance.apply(hdr, eg_intr_md, eg_md);
   // Use Parser Timestamp if applicable
   process_eg_parser_ts_instance.apply(hdr, eg_intr_md, eg_md, eg_intr_from_prsr);


   // Apply counter udfs outer loop stutter
   process_counter_udf_repeat_instance.apply(hdr, eg_intr_md, eg_md);
   // Apply counter udfs inner loop
   process_counter_udf_increment_instance.apply(hdr, eg_intr_md, eg_md);

   // Pack the stream id and front panel port id to get an index for egress registers
   process_pack_stream_port_instance.apply(eg_md);
   process_pack_stream_pipe_port_instance.apply(eg_md);

   // Increment burst packet counter
   process_incr_burst_pkt_cntr_instance.apply(hdr, eg_md);
   // Modify packet with modifiers
   process_egress_header_mods_instance.apply(hdr, eg_intr_md, eg_md);

   // Pack pipe port and transmit pgid into index used for flow sequence registers
   pack_pipe_port_tx_pgid_instance.apply(hdr, eg_md);


   if(eg_md.burst_pkt_cntr.drop == 4w2 || eg_md.burst_pkt_cntr.drop == 4w1)
   {
    // If burst is complete mark packet for drop in egress pipeline
    process_burst_drops_instance.apply(hdr, eg_intr_md_for_dprsr);
   }
   else
   {
    // Packet from transmit engine is committed, so count stream and port stats
    process_eg_stream_statsA_instance.apply(hdr, eg_md, eg_intr_from_prsr);
    process_eg_stream_statsB_instance.apply(hdr, eg_md, eg_intr_from_prsr);
    process_eg_port_stats_instance.apply(hdr, eg_intr_md);
   }

  }
  else
  {
   // Packet from CPU path is commited so count port stats
   process_eg_port_stats_instance.apply(hdr, eg_intr_md);
  }
  process_insert_fabric_hdr_instance.apply(hdr, eg_intr_md);
 }

}

Pipeline(SwitchIngressParser(),
         SwitchIngress(),
         SwitchIngressDeparser(),
         SwitchEgressParser(),
         SwitchEgress(),
         SwitchEgressDeparser()) pipe;

// Append custom annotations to pkginfo, created in profiles.p4
@Attr(git_sha=00000000,descrip="Git Commit SHA for this program") @Attr(tofino_target=2,descrip="Tofino target for this program") @Attr(profile=300,descrip="Build profile for this program") @Attr(profile_name="UHD400 L23 STREAMS ORBIT PROFILE",descrip="Brief name for this profile") @Attr(dual_pgid_stats_banks=0,descrip="PGID stats collected into two stats banks") @Attr(num_pgids=32768,descrip="Number of PGID flows/stats supported by this program/profile")
// P4 "Standard" pkginfo annnotations
@pkginfo(name="nanite.p4",version="1")
@brief("Tofino Nanite Packet Blaster")
@description("Tofino Nanite Packet Blaster.Lovingly brought to you by talented nerds.")

@pkginfo(organization="Keysight")
@pkginfo(contact="support@keysight.com")
@pkginfo(url="www.keysight.com")
Switch(pipe) main;
