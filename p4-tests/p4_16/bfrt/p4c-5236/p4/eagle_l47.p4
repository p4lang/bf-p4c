/*!
 * @file patch_panel.p4
 * @brief  main functions for Eagle switch.
 * @author
 * @date
 */

#if __TARGET_TOFINO__ == 2
#include <t2na.p4>
#else
#include <tna.p4>
#endif

#include "headers.p4"
#include "packet_parser_ingress.p4"
#include "packet_parser_egress.p4"
//#include "hash_generator.p4"
#include "outbound_l47.p4"
#include "inbound_l47.p4"
#include "timestamp.p4"
#include "latency_stat.p4"
#include "egress_mirror_overhead.p4"
#include "ingress_metadata_map.p4"
#include "checksum_correction.p4"
#include "l2offset_map.p4"
#include "capture_filter.p4"
#include "length_filter.p4"
#include "ingress_cmp.p4"
#include "egress_cmp.p4"

/**
 * Ingress parser
 * @param in pkt input packet
 * @param out hdr header(s) extracted from the packet
 * @param out ig_md ingress metadata
 * @param out ig_intr_md ingress intrinsic metadata
 * @return none
 */
parser SxIngParser(packet_in pkt,
       out header_t hdr,
       out ingress_metadata_t meta,
       out ingress_intrinsic_metadata_t ig_intr_md) {
    PacketParserIngress() pkt_parser;

    state start {
      pkt_parser.apply(pkt, hdr, meta, ig_intr_md);
      transition accept;
    }
}

/**
 * Ingress pipeline: Sets the destination port for incoming packets.
 * @param inout hdr extracted header(s)
 * @param inout ig_md ingress metadata
 * @param in ig_intr_md ingress intrinsic metadata
 * @param in ig_intr_prsr_md ingress intrinsic metadata for parser
 * @param in ig_intr_dprsr_md ingress intrinsic metadata for deparser
 * @param out ig_intr_md_for_tm ingress intrinsic metadata for traffic manager
 * @return none
 */

control SxIngPipeline(inout header_t hdr,
         inout ingress_metadata_t meta,
         in ingress_intrinsic_metadata_t ig_intr_md,
         in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
         inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md,
         inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md,
         in ghost_intrinsic_metadata_t g_intr_md)
{
  /*
   * Ingress per port stat counters
   */
    // Create port counters ( banked )
    @KS_stats_service_counter(Ingress Port Counter Table, port_counters)
    @KS_stats_service_columns(Ingress Packets, Ingress Bytes)
    @KS_stats_service_units(packets, bytes)
    Counter<bit<64>, bit<6>> (64, CounterType_t.PACKETS_AND_BYTES) banked_port_statsA;
    const bit<32> table_sz = 512;
    bit<8> sel_hash;
    bit<8> queue_offset;
    bit<1> l47_match = 0;
    bit<1> timestamp_calc = 0;
    bit<16> ethertype;
    bit<8> final_queue ;
    bit<32> pkt_latency;
    stats_index_t stat_index;
    bit<7> port_index;
    bit<8> mpls_offset;
    bit<32> ingress_mac_timestamp;
    bit<1> test_match;
    bit<1> l23_match;
    bit<1> insert_txtimestamp = 0;
    bit<32> collapsed_rx_mac;
    Hash<bit<32>>(HashAlgorithm_t.IDENTITY) identityHash32_rx;
    Hash<bit<32>>(HashAlgorithm_t.IDENTITY) identityHash32_rx_2;
    bit<16> rich_register = 0;
    bit<16> egress_rich_register = 0;
    bit<8>  egress_capture_group = 0;
    bit<16> seq_no = 0;
    bit<1>  capture_match = 0;
    bit<1>  match_bank_stat = 0;

    Register<bit<16>, bit<3>>(size=8, initial_value=0) sequence_no;
    RegisterAction<bit<16>, bit<3>, bit<16>>(sequence_no)
    update_seq_no = {
        void apply(inout bit<16> register_data, out bit<16> result)
        {
            result = register_data;
            if (register_data == 16w0x7ff)
                register_data = 0;
            else
                register_data = register_data + 1;
        }
    };

   /**
   * Sets egress port.
   * @param egPort egress port
   * @return none
   */
    action truncate_rx_tstamp() {
       ingress_mac_timestamp = (bit<32>)(ig_intr_md.ingress_mac_tstamp);
       ethertype = hdr.ethernet.ether_type;
       hdr.bridge.ingress_port = ig_intr_md.ingress_port[7:0];
    }

    action assign_rx_tstamp(){
      hdr.bridge.sum_mac_timestamp = collapsed_rx_mac + identityHash32_rx_2.get({ingress_mac_timestamp[15:0]});
    }

    action insertL23RxTimestamp() {
      hdr.first_payload.signature_bot[15:0] = ingress_mac_timestamp[31:16];
      @in_hash{hdr.rx_timestamp.rx_timestamp = ingress_mac_timestamp[15:0];}
      hdr.bridge.l23_rxtstmp_insert = 1;
      hdr.bridge.l23_txtstmp_insert = 0;
    }

    action setOutboundEgPort(PortId_t egPort, QueueId_t queue) {
        ig_intr_tm_md.ucast_egress_port = egPort;
        ig_intr_tm_md.qid = queue;
    }

    action setFixedPort(PortId_t egPort, QueueId_t queue) {
        ig_intr_tm_md.ucast_egress_port = egPort;
        ig_intr_tm_md.qid = queue;
        ig_intr_tm_md.bypass_egress = 1;
        hdr.bridge.setInvalid();
    }

    action setL23InboundInsertEgPort(PortId_t egPort, QueueId_t queue) {
        setOutboundEgPort(egPort, queue);
        insertL23RxTimestamp();
        meta.l23_match = 1;
    }

    action setL23OutboundEgPort(PortId_t egPort, QueueId_t queue){
        setOutboundEgPort(egPort, queue);
        hdr.bridge.l23_txtstmp_insert = 0;
    }


    action setL23OutboundInsertEgPort(PortId_t egPort, QueueId_t queue){
        setOutboundEgPort(egPort, queue);
        hdr.bridge.l23_txtstmp_insert = 1;
        meta.l23_match = 1;
    }

    action setL47OutboundEgPort(PortId_t egPort, QueueId_t queue, bit<4> pcp_cfi) {
        setOutboundEgPort(egPort, queue);
        ig_intr_tm_md.ingress_cos = hdr.vlan_tag_0.pcp_cfi[3:1];
        hdr.vlan_tag_0.pcp_cfi = pcp_cfi;
    }

    action setL47OutboundEgPortInsertTimestamp(PortId_t egPort, QueueId_t queue, bit<4> pcp_cfi) {
        setOutboundEgPort(egPort, queue);
        ig_intr_tm_md.ingress_cos = hdr.vlan_tag_0.pcp_cfi[3:1];
        hdr.bridge.l47_timestamp_insert = 1;
        hdr.vlan_tag_0.pcp_cfi = pcp_cfi;
    }
    // this is a workaround for E810
    action setL47InnerVlanOutboundEgPort(PortId_t egPort, QueueId_t queue, bit<4> pcp_cfi) {
        setOutboundEgPort(egPort, queue);
        ig_intr_tm_md.ingress_cos = hdr.vlan_tag_0.pcp_cfi[3:1];
        hdr.vlan_tag_0.pcp_cfi = pcp_cfi;
        hdr.vlan_tag_1.pcp_cfi = 0;
    }

    action setL47InnerVlanOutboundEgPortInsertTimestamp(PortId_t egPort, QueueId_t queue, bit<4> pcp_cfi) {
        setOutboundEgPort(egPort, queue);
        hdr.bridge.l47_timestamp_insert = 1;
        ig_intr_tm_md.ingress_cos = hdr.vlan_tag_0.pcp_cfi[3:1];
        hdr.vlan_tag_0.pcp_cfi = pcp_cfi;
        hdr.vlan_tag_1.pcp_cfi = 0;
    }

    action setL23CpuOutboundEgPort(PortId_t egPort, QueueId_t queue, bit<8> mac_byte) {
        setOutboundEgPort(egPort, queue);
        ig_intr_tm_md.ingress_cos = hdr.vlan_tag_0.pcp_cfi[3:1];
        hdr.ethernet.src_addr[39:32] = mac_byte;
    }

    //direct mapping of hdr.bridge.l23_tx_timestamp_insert = hdr.first_payload.rx_timestamp[4:4]
    //cause error. Workaround is to make it programmable ( fixed to 1 or 0 )
    //user need to use 2 entries for each ingress_port/engine_id option ( key could be 1 or 0 and 
    //use pick the appropriate action)
    table presetOutboundTbl {
        key = {
            hdr.vlan_tag_0.pcp_cfi:             ternary;
            hdr.vlan_tag_0.isValid():           ternary;
            hdr.vlan_tag_1.isValid():           ternary;
            meta.port_properties.port_type :    ternary;
            meta.engine_id:                     ternary;
            hdr.first_payload.signature_top:    ternary;
            hdr.first_payload.signature_bot:    ternary;
            ig_intr_md.ingress_port:            ternary;
            hdr.ethernet.src_addr[39:32]:        ternary;
        }
        actions = {
          setL23InboundInsertEgPort;
          setL23OutboundInsertEgPort;
          setL23OutboundEgPort;
          setL47OutboundEgPort;
          setL47OutboundEgPortInsertTimestamp;
          setL47InnerVlanOutboundEgPort;
          setL47InnerVlanOutboundEgPortInsertTimestamp;
          setOutboundEgPort;
          setFixedPort;
          setL23CpuOutboundEgPort;
          NoAction;
        }
        default_action = NoAction;
        size = 1024;
    }

    action removeVlan() {
        hdr.ethernet.ether_type = hdr.vlan_tag_0.ether_type;
        hdr.vlan_tag_0.setInvalid();
    }

    table removeVlanTbl {
        key = {
            hdr.vlan_tag_0.vlan_top:  exact;
            hdr.vlan_tag_0.vlan_bot:  exact;
            meta.port_properties.port_type : exact;
        }
        actions = {
            removeVlan;
            NoAction;
        }
        default_action = NoAction;
        size = 4;
    }

    // special lldp packet from our own cpu (should not have any vlan)
    action insertLLDPVlan(bit<4> vlan_top, bit<8> vlan_bot)
    {
        hdr.ethernet.ether_type = 0x8100;
        hdr.vlan_tag_0.setValid();
        hdr.vlan_tag_0.vlan_top  = vlan_top;
        hdr.vlan_tag_0.vlan_bot  = vlan_bot;
        hdr.vlan_tag_0.ether_type = ethertype;
        ig_intr_tm_md.ucast_egress_port = 2;
        hdr.bridge.pkt_type = PKT_TYPE_SKIP_EGRESS;
    }

    table mapLLDPVlanTbl {
        key = {
            ig_intr_md.ingress_port : exact;
        }
        actions = {
            insertLLDPVlan;
            NoAction;
        }
        default_action = NoAction;
        size = 512;
    }

    // each front panel should map to a single multicast group that has
    // at least 2 ports, a default CN port and CPU port
    action set_mcast_grp(MulticastGroupId_t mcg) {
        ig_intr_tm_md.mcast_grp_a = mcg;
        ig_intr_dprsr_md.mirror_type = 0;
        hdr.bridge.pkt_type = PKT_TYPE_BROADCAST;
    }

    //only match on l47_match and l23_match = 0
    // the only configurable item from user is the port number
    table multicastFilterTbl {
        key = {
            ig_intr_md.ingress_port : exact;
            l47_match: exact;
            ethertype: ternary;
            hdr.ipv4.isValid(): ternary;
            hdr.ipv4.protocol : ternary;
            hdr.ipv6.isValid(): ternary;
            hdr.ipv6.next_hdr : ternary;
        }
        actions = {
            set_mcast_grp;
            NoAction;
        }
        default_action = NoAction;
        size = 256;
    }

    table multicastTbl {
        key = {
            ig_intr_md.ingress_port : exact;
            l47_match: exact;
        }
        actions = {
            set_mcast_grp;
            NoAction;
        }
        default_action = NoAction;
        size = 64;
    }

    action insert_seq_no()
    {
        meta.mirror.capture_seq_no = seq_no;
        //meta.mirror.l2_offset = hdr.bridge.l2_offset;
    }

    action set_capture_mirror_session(MirrorId_t mirror_session) {
        ig_intr_dprsr_md.mirror_type = MIRROR_TYPE_I2E;
        meta.mirror_session = mirror_session;
        meta.mirror.pkt_type = PKT_TYPE_CAPTURE;
        meta.mirror.mac_timestamp = ingress_mac_timestamp;
        seq_no = update_seq_no.execute(meta.port_properties.capture_group[5:3]);
        capture_match = 1;
    }

    table ingressCaptureTbl {
        key = {
            ig_intr_md.ingress_port : exact;
            meta.port_properties.capture_group : exact;
            rich_register : exact;
        }
        actions = {
            set_capture_mirror_session;
            NoAction;
        }
        default_action = NoAction;
        size = 32;
    }

    action collapse_rx_tstamp(){
      collapsed_rx_mac = identityHash32_rx.get({ingress_mac_timestamp[31:16]});
    }

    action mpls_1()
    {
      mpls_offset = 1;
    }

   action mpls_2()
   {
      mpls_offset = 2;
   }

   action mpls_3()
   {
      mpls_offset = 3;
   }

   action mpls_4()
   {
      mpls_offset = 4;
   }

   action mpls_5()
   {
      mpls_offset = 5;
   }

   action mpls_0()
   {
      mpls_offset = 0;
   }

    table mapMplsTbl {
        key = {
         hdr.mpls_0.isValid(): ternary;
         hdr.mpls_1.isValid(): ternary;
         hdr.mpls_2.isValid(): ternary;
         hdr.mpls_3.isValid(): ternary;
         hdr.mpls_4.isValid(): ternary;
        }
        actions = {
         mpls_1;
         mpls_2;
         mpls_3;
         mpls_4;
         mpls_5;
         mpls_0;
        }
        const entries = {
         ( true,  false, false, false, false ): mpls_1;
         ( _,     true,  false, false, false ): mpls_2;
         ( _,     _,     true,  false, false ): mpls_3;
         ( _,     _,     _,     true,  false ): mpls_4;
         ( _,     _,     _,     _,     true  ): mpls_5;
         ( false, false, false, false, false ): mpls_0;
        }
   }
    action map_port_indexA(bit<6> index)
    {
        banked_port_statsA.count(index);
    }

    table bankedPortTableA {
        key = {
            ig_intr_md.ingress_port : exact;
        }
        actions = {
            map_port_indexA;
            NoAction;
        }
        default_action = NoAction;
        size = 64;
    }

    action do_set_egress_group(bit<3> group) {
        hdr.bridge.capture_group = group;
        egress_capture_group[5:3] = group;
    }

    table set_egress_group {
        key = {
            ig_intr_tm_md.ucast_egress_port : exact;
        }
        actions = { 
            do_set_egress_group;
            NoAction;
         }
        default_action = NoAction;
        size = 512;
    }

    action set_rich_bridge()
    {
        hdr.bridge.rich_register = egress_rich_register[2:0];
    }
/***************************************************
  /*
   * main execution body for ingress pipeline
   */
    apply
    {
        ingress_cmp.apply(g_intr_md, meta, rich_register);
        truncate_rx_tstamp();
        mapMplsTbl.apply();
        bankedPortTableA.apply();
        ingress_metadata_map.apply(hdr, ig_intr_md, meta);  
        //lookup will do the mod operation
        //If L23 type packets
        collapse_rx_tstamp();
        assign_rx_tstamp();
        if (meta.cpu_lldp == 1)
            mapLLDPVlanTbl.apply();
        else {
            if (presetOutboundTbl.apply().hit == false)
            {
                //vlan is inserted regardless of l47 match
                inbound_l47_gen_lookup.apply(hdr, ig_intr_md, ig_intr_tm_md, meta, ethertype, 
                         l47_match, timestamp_calc, stat_index);
                if ( multicastFilterTbl.apply().hit == false)
                    multicastTbl.apply();  
            } else {
                removeVlanTbl.apply();
            } 
        } 
        //set egress group for capture
        set_egress_group.apply();
        egress_cmp.apply(g_intr_md, meta, egress_capture_group, egress_rich_register);
        l2_offset_map.apply(hdr, mpls_offset, meta);
        ingressCaptureTbl.apply();
        if (capture_match == 1w1)
            insert_seq_no();
        capture_filter.apply(hdr, ig_intr_md, ig_intr_tm_md, meta, l23_match, l47_match, capture_match);
        set_rich_bridge();
            //calculate latency assuming it is l47 payload
        inbound_l47_calc_latency.apply(hdr, ig_intr_md, ingress_mac_timestamp, pkt_latency);
        if (timestamp_calc == 1 && l47_match == 1)
            latency_stat.apply(0, stat_index, pkt_latency);
   }
}
/**
 * Ingress deparser
 * @param out pkt packet to be emitted to the egress pipeline
 * @param in ig_md ingress metadata
 * @param in ig_intr_dprsr_md ingress intrinsic metadata for deparser
 * @return none
 */
control SxIngDeparser(packet_out pkt,
          inout header_t hdr,
          in ingress_metadata_t meta,
          in ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md) {

    Mirror() mirror;

    apply{
        if (ig_dprsr_md.mirror_type == MIRROR_TYPE_I2E)
        {
            mirror.emit<mirror_h>(meta.mirror_session, meta.mirror);
        }
        pkt.emit(hdr);
    }
}


/************************************************************************************/
//EGRESS PIPELINE
/************************************************************************************/
parser SxEgrParser(packet_in pkt,
       out eg_header_t hdr,
       out egress_metadata_t eg_md,
       out egress_intrinsic_metadata_t eg_intr_md) {

    PacketParserEgress() pkt_parser;

    state start {
        pkt.extract(eg_intr_md);  // need to extract egress intrinsic metadata
        mirror_h mirror_md = pkt.lookahead<mirror_h>();
        transition select(mirror_md.pkt_type) {
            PKT_TYPE_CAPTURE        : parseCapture;
            PKT_TYPE_SKIP_EGRESS    : parseSkip;
            PKT_TYPE_BROADCAST      : parseBroadcast;
            default                 : parseBridge;
        }
    }

    // this is the packet that is mirror either from ingress or egress
    state parseCapture {
        pkt.extract(eg_md.ing_port_mirror);
        eg_md.pkt_type = PKT_TYPE_CAPTURE;
        hdr.capture.setValid();
        transition accept;
    }
    
    state parseSkip {
        pkt.extract(eg_md.bridge);
        transition accept;
    }

    state parseBroadcast {
        pkt.extract(eg_md.bridge);
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type) {
            ETHERTYPE_VLAN: parseVlan;
            ETHERTYPE_SVLAN: parseVlan;
            default : parseInsertVlan;
        }
    }

    state parseVlan {
       pkt.extract(hdr.vlan_tag_0);
       transition accept;
    }

    state parseInsertVlan {
        hdr.vlan_tag_0.setValid();
        hdr.vlan_tag_0.ether_type = hdr.ethernet.ether_type;
        hdr.vlan_tag_0.vlan_top = 0xf;
        hdr.vlan_tag_0.vlan_bot = 0xff;
        hdr.ethernet.ether_type = 0x8100;
        transition accept;
    }

    state parseBridge {
        pkt.extract(eg_md.bridge);
        pkt_parser.apply(pkt, hdr, eg_md);
        transition accept;
    }
}

/**
 * Egress pipeline
 * @param inout hdr extracted header(s)
 * @param inout eg_md egress metadata
 * @param in eg_intr_md egress intrinsic metadata
 * @param in eg_intr_prsr_md egress intrinsic metadata for parser
 * @param in eg_intr_dprsr_md egress intrinsic metadata for deparser
 * @param out eg_intr_md_for_oport egress intrinsic metadata for output port
 * @return none
 */
control SxEgrPipeline(inout eg_header_t hdr,
          inout egress_metadata_t eg_md,
          in egress_intrinsic_metadata_t eg_intr_md,
          in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
          inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprs,
          inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {

    bit<32> global_tstamp;
    bit<32> collapsed_tstamp;
    @KS_stats_service_counter(Egress Port Counter Table, port_counters)
    @KS_stats_service_columns(Egress Packets, Egress Bytes)
    @KS_stats_service_units(packets, bytes)
    Counter<bit<64>, bit<6>> (64, CounterType_t.PACKETS_AND_BYTES) banked_port_statsA;
    bit<7> port_index;
    bit<16> eg_seq_no = 0;
    bit<1>  match = 0;
    bit<1>  match_bank_stat = 0;
    bit<8>  rich_register;
    bit<1>  local_error = 0;

    Register<bit<8>, bit<3>>(size=8, initial_value=0) last_rich;
    RegisterAction<bit<8>, bit<3>, bit<8>>(last_rich)
    update_last = {
        void apply(inout bit<8> register_data, out bit<8> result)
        {
            if (register_data == (bit<8>)eg_md.bridge.rich_register)
                register_data = register_data - 1;
            else
                register_data = (bit<8>)eg_md.bridge.rich_register;
            result = register_data;
        }
    };
      
    RegisterAction<bit<8>, bit<3>, bit<8>>(last_rich)
    update_special = {
        void apply(inout bit<8> register_data, out bit<8> result)
        {
            if (register_data == (bit<8>)eg_md.bridge.rich_register)
                register_data = register_data + 1;
            else
                register_data = (bit<8>)eg_md.bridge.rich_register;
            result = register_data;
        }
    };

    action map_port_indexA(bit<6> stat_index)
    {
        banked_port_statsA.count(stat_index);
    }

    table bankedPortTableA {
        key = {
            eg_intr_md.egress_port : exact;
        }
        actions = {
            map_port_indexA;
            NoAction;
        }
        default_action = NoAction;
        size = 64;
    }

    action map_collapsed()
    {
        collapsed_tstamp = (bit<32>)(eg_intr_md_from_prsr.global_tstamp[15:0]);
    }

    action map_timestamp()
    {
        global_tstamp = (bit<32>)(eg_intr_md_from_prsr.global_tstamp);
    }

    Register<bit<16>, bit<3>>(size=8, initial_value=0) sequence_no;
    RegisterAction<bit<16>, bit<3>, bit<16>>(sequence_no)
    update_seq_no = {
        void apply(inout bit<16> register_data, out bit<16> result)
        {
            result = register_data;
            if (register_data == 16w0x7ff)
                register_data = 0;
            else
                register_data = register_data + 1;
        }
    };

    action set_capture_mirror_session(MirrorId_t mirror_session) {
        eg_intr_md_for_dprs.mirror_type = MIRROR_TYPE_E2E;
        eg_md.mirror_session = mirror_session;
        eg_md.mirror.mac_timestamp = global_tstamp;
        eg_md.mirror.pkt_type = PKT_TYPE_CAPTURE;
        //propagate the trigger and filters from ingress pipeline to egress 
        eg_md.mirror.filter = eg_md.bridge.filter;
        eg_md.mirror.trigger = eg_md.bridge.trigger;
        eg_seq_no = update_seq_no.execute(eg_md.bridge.capture_group);
        match = 1;
#if __TARGET_TOFINO__ != 1
// E2E mirroring for Tofino2 & future ASICs, or you'll see extra bytes prior to ethernet
        eg_intr_md_for_dprs.mirror_io_select = 1;
#endif
  }

    table captureTbl {
        key = {
            eg_intr_md.egress_port : exact;
            eg_md.bridge.capture_group : exact;
            rich_register : exact;
        }
        actions = {
            set_capture_mirror_session;
            NoAction;
        }
        default_action = NoAction;
        size = 32;
    }

    action insert_capture_parity( bit<16> calculated)
    {
        hdr.capture.seq_no = calculated[11:0];
        hdr.capture.seq_no_2 = calculated[11:0];
        //hdr.capture.parity_2 = parity;
        hdr.capture.timestamp = eg_md.ing_port_mirror.mac_timestamp;
    }

    table insertOverheadTbl {
    key = {
        eg_md.ing_port_mirror.capture_seq_no : exact;
    }
    actions = {
        insert_capture_parity;
    }
      size = 2048;
    }

    action insert_seq_no()
    {
       eg_md.mirror.capture_seq_no = eg_seq_no;
    }
    Register<bit<16>, bit<9>>(size=512, initial_value=4096) last_sequence_no;
    RegisterAction<bit<16>, bit<9>, bit<1>>(last_sequence_no)
    last_seq_no = {
        void apply(inout bit<16> register_data, out bit<1> result)
        {
            if (register_data == eg_md.ing_port_mirror.capture_seq_no)
                result = 1w1;
            else
                result = 1w0;
            register_data = eg_md.ing_port_mirror.capture_seq_no + 1;
        }
    };
    Register<bit<8>, bit<9>>(size=512, initial_value=0) err_sequence_no;
    RegisterAction<bit<8>, bit<9>, bit<8>>(err_sequence_no)
    err_seq_no = {
        void apply(inout bit<8> register_data, out bit<8> result)
        {
            if ( local_error == 1w1 )
              register_data = register_data + 1;
        }
    };

    action set_cos_value(bit<4> pfc_cos)
    {
    	hdr.vlan_tag_0.pcp_cfi = pfc_cos;
    }

    action set_mac_value(bit<8> mac_byte) {
        hdr.ethernet.dst_addr[39:32] = mac_byte;
    }

    table egressMulticastCosTbl {
        key = {
            eg_intr_md.egress_port 	    : exact;
            eg_md.bridge.ingress_port 	: exact;
            eg_md.bridge.pkt_type 	    : exact;
        }
        actions = {
            set_cos_value;
            set_mac_value;
            NoAction;
        }
        default_action = NoAction;
        size = 128;
    }

    /*******************************************/
    apply { 
        if (!egressMulticastCosTbl.apply().hit) {
            map_timestamp();
            map_collapsed();
            calculate_checksum.apply(eg_md, hdr, collapsed_tstamp, global_tstamp);
            //only inserting global timestamp
            //for l23, mac timestamp is inserted at ingress pipeline
            if(eg_md.bridge.l47_timestamp_insert == 1)
                outbound_l47_insert_timestamp.apply(hdr, eg_md, global_tstamp);
            else
                timestamp_insertion.apply(hdr, eg_md, global_tstamp);
        }
    
        if (eg_md.bridge.isValid())
        {
          if (eg_md.bridge.rich_register == 1)
            rich_register = update_special.execute(eg_md.bridge.capture_group);
          else
            rich_register = update_last.execute(eg_md.bridge.capture_group);
        }
        // this has to be at the end, such that egress-capture only act on
        // actual packet ( after mirrored packet appear and not the packet that
        // is being mirrored)
        if (hdr.capture.isValid())
        {
            insertOverheadTbl.apply();
            length_filter.apply(hdr, eg_md, eg_intr_md);
            local_error = last_seq_no.execute(eg_intr_md.egress_port);
        }
        else
        {
            captureTbl.apply();
            insert_seq_no();;
        }
        bankedPortTableA.apply();
        err_seq_no.execute(eg_intr_md.egress_port);
    }
}

/*
 * Egress deparser
 * @param out pkt packet to be emitted to the egress pipeline
 * @param inout hdr header(s) extracted
 * @param in eg_md egress metadata
 * @param in eg_intr_dprsr_md egress intrinsic metadata for deparser
 * @return none
 */
control SxEgrDeparser(packet_out pkt,
          inout eg_header_t hdr,
          in egress_metadata_t eg_md,
          in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprs) {

    Mirror() mirror;
    apply{
        if (eg_intr_md_for_dprs.mirror_type == MIRROR_TYPE_E2E) {
            mirror.emit<mirror_h>(eg_md.mirror_session,  eg_md.mirror);
        }
        pkt.emit(hdr);
    }
}

/************************************************************************************/
//GHOST thread
/************************************************************************************/

control SxQueueMonitor(in ghost_intrinsic_metadata_t g_intr_md )
{
    RegisterAction<bit<16>, bit<11>, bit<16>>(ping_reg) ping_update = {
        void apply(inout bit<16> value) { value = g_intr_md.qlength[14:0] ++1w0; } };

    RegisterAction<bit<16>, bit<11>, bit<16>>(pong_reg) pong_update = {
        void apply(inout bit<16> value) { value = g_intr_md.qlength[14:0] ++1w0; } };

    RegisterAction<bit<16>, bit<11>, bit<16>>(ping_egress_reg) ping_egress_update = {
        void apply(inout bit<16> value) { value = g_intr_md.qlength[14:0] ++1w0; } };

    RegisterAction<bit<16>, bit<11>, bit<16>>(pong_egress_reg) pong_egress_update = {
        void apply(inout bit<16> value) { value = g_intr_md.qlength[14:0] ++1w0; } };

    action ping_do_update(bit<11> idx) {
        ping_update.execute(idx);
    }

    @stage(QUEUE_REG_STAGE1)
    table ping_update_tbl {
        key = {
            g_intr_md.pipe_id : exact;
            g_intr_md.qid : exact;
        }
        actions = {
            ping_do_update;
        }
        size = 32;
    }

    action pong_do_update(bit<11> idx) {
        pong_update.execute(idx);
    }

    @stage(QUEUE_REG_STAGE1)
    table pong_update_tbl {
        key = {
            g_intr_md.pipe_id : exact;
            g_intr_md.qid : exact;
        }
        actions = {
            pong_do_update;
        }
        size = 32;
    }

    action eg_ping_do_update(bit<11> idx) {
        ping_egress_update.execute(idx);
    }

    @stage(EG_QUEUE_REG_STAGE1)
    table eg_ping_update_tbl {
        key = {
            g_intr_md.pipe_id : exact;
            g_intr_md.qid : exact;
        }
        actions = {
            eg_ping_do_update;
        }
        size = 32;
    }
    action eg_pong_do_update(bit<11> idx) {
        pong_egress_update.execute(idx);
    }

    @stage(EG_QUEUE_REG_STAGE1)
    table eg_pong_update_tbl {
        key = {
            g_intr_md.pipe_id : exact;
            g_intr_md.qid : exact;
        }
        actions = {
            eg_pong_do_update;
        }
        size = 32;
    }

//---------------------------------------------------------        
  // to supply 2 groups to ping pong, we need 2 sets of identical registers
  // such that we can access both per packet access
    RegisterAction<bit<16>, bit<11>, bit<16>>(ping_reg2) ping_update2 = {
        void apply(inout bit<16> value) { value = g_intr_md.qlength[15:0]; } };

    RegisterAction<bit<16>, bit<11>, bit<16>>(pong_reg2) pong_update2 = {
        void apply(inout bit<16> value) { value = g_intr_md.qlength[15:0]; } };

    RegisterAction<bit<16>, bit<11>, bit<16>>(ping_egress_reg2) ping_egress_update2 = {
        void apply(inout bit<16> value) { value = g_intr_md.qlength[15:0]; } };

    RegisterAction<bit<16>, bit<11>, bit<16>>(pong_egress_reg2) pong_egress_update2 = {
        void apply(inout bit<16> value) { value = g_intr_md.qlength[15:0]; } };

    action ping_do_update2(bit<11> idx) {
        ping_update2.execute(idx);
    }

    @stage(QUEUE_REG_STAGE2)
    table ping_update2_tbl {
        key = {
            g_intr_md.pipe_id : exact;
            g_intr_md.qid : exact;
        }
        actions = {
            ping_do_update2;
        }
        size = 32;
    }

    action pong_do_update2(bit<11> idx) {
        pong_update2.execute(idx);
    }

    @stage(QUEUE_REG_STAGE2)
    table pong_update2_tbl {
        key = {
            g_intr_md.pipe_id : exact;
            g_intr_md.qid : exact;
        }
        actions = {
            pong_do_update2;
        }
        size = 32;
    }

    action eg_ping_do_update2(bit<11> idx) {
        ping_egress_update2.execute(idx);
    }

    @stage(EG_QUEUE_REG_STAGE2)
    table eg_ping_update2_tbl {
        key = {
            g_intr_md.pipe_id : exact;
            g_intr_md.qid : exact;
        }
        actions = {
            eg_ping_do_update2;
        }
        size = 32;
    }
    action eg_pong_do_update2(bit<11> idx) {
        pong_egress_update2.execute(idx);
    }

    @stage(EG_QUEUE_REG_STAGE2)
    table eg_pong_update2_tbl {
        key = {
            g_intr_md.pipe_id : exact;
            g_intr_md.qid : exact;
        }
        actions = {
            eg_pong_do_update2;
        }
        size = 32;
    }
  //---------------------------------------------------------        
  // to supply 2 groups to ping pong, we need 2 sets of identical registers
  // such that we can access both per packet access
  RegisterAction<bit<16>, bit<11>, bit<16>>(ping_reg3) ping_update3 = {
        void apply(inout bit<16> value) { value = g_intr_md.qlength[14:0] ++ 1w0; } };

    RegisterAction<bit<16>, bit<11>, bit<16>>(pong_reg3) pong_update3 = {
        void apply(inout bit<16> value) { value = g_intr_md.qlength[14:0] ++ 1w0; } };

    RegisterAction<bit<16>, bit<11>, bit<16>>(ping_egress_reg3) ping_egress_update3 = {
        void apply(inout bit<16> value) { value = g_intr_md.qlength[14:0] ++ 1w0; } };

    RegisterAction<bit<16>, bit<11>, bit<16>>(pong_egress_reg3) pong_egress_update3 = {
        void apply(inout bit<16> value) { value = g_intr_md.qlength[14:0] ++ 1w0; } };

    action ping_do_update3(bit<11> idx) {
        ping_update3.execute(idx);
    }

    @stage(QUEUE_REG_STAGE3)
    table ping_update3_tbl {
        key = {
            g_intr_md.pipe_id : exact;
            g_intr_md.qid : exact;
        }
        actions = {
            ping_do_update3;
        }
        size = 32;
    }

    action pong_do_update3(bit<11> idx) {
        pong_update3.execute(idx);
    }

    @stage(QUEUE_REG_STAGE3)
    table pong_update3_tbl {
        key = {
            g_intr_md.pipe_id : exact;
            g_intr_md.qid : exact;
        }
        actions = {
            pong_do_update3;
        }
        size = 32;
    }

    action eg_ping_do_update3(bit<11> idx) {
        ping_egress_update3.execute(idx);
    }

    @stage(EG_QUEUE_REG_STAGE3)
    table eg_ping_update3_tbl {
        key = {
            g_intr_md.pipe_id : exact;
            g_intr_md.qid : exact;
        }
        actions = {
            eg_ping_do_update3;
        }
        size = 32;
    }
    action eg_pong_do_update3(bit<11> idx) {
        pong_egress_update3.execute(idx);
    }

    @stage(EG_QUEUE_REG_STAGE3)
    table eg_pong_update3_tbl {
        key = {
            g_intr_md.pipe_id : exact;
            g_intr_md.qid : exact;
        }
        actions = {
            eg_pong_do_update3;
        }
        size = 32;
    } 
    /***********************************************/
    //DUMMY
    /*RegisterAction<bit<32>, bit<1>, bit<32>>(gt_stage3) gt_update_s3 = {
        void apply(inout bit<32> value) { value = value + 1; } };

    action gt_update_act_s3() {
        gt_update_s3.execute(0);
    }

    @stage(QUEUE_REG_STAGE4)
    table gt_update_s3_tbl {
        actions = {
            gt_update_act_s3;
        }
        size = 2;
    }*/

    RegisterAction<bit<32>, bit<1>, bit<32>>(gt_stage4) gt_update_s4 = {
        void apply(inout bit<32> value) { value = value + 1; } };

    action gt_update_act_s4() {
        gt_update_s4.execute(0);
    }

    @stage(QUEUE_REG_STAGE4)
    table gt_update_s4_tbl {
        actions = {
            gt_update_act_s4;
        }
        size = 2;
    }

    RegisterAction<bit<32>, bit<1>, bit<32>>(gt_stage5) gt_update_s5 = {
        void apply(inout bit<32> value) { value = value + 1; } };

    action gt_update_act_s5() {
        gt_update_s5.execute(0);
    }

    @stage(QUEUE_REG_STAGE5)
    table gt_update_s5_tbl {
        actions = {
            gt_update_act_s5;
        }
        size = 2;
    }

    RegisterAction<bit<32>, bit<1>, bit<32>>(gt_stage6) gt_update_s6 = {
        void apply(inout bit<32> value) { value = value + 1; } };

    action gt_update_act_s6() {
        gt_update_s6.execute(0);
    }

    @stage(QUEUE_REG_STAGE6)
    table gt_update_s6_tbl {
        actions = {
            gt_update_act_s6;
        }
        size = 2;
    }

    RegisterAction<bit<32>, bit<1>, bit<32>>(gt_stage7) gt_update_s7 = {
        void apply(inout bit<32> value) { value = value + 1; } };

    action gt_update_act_s7() {
        gt_update_s7.execute(0);
    }
    @stage(QUEUE_REG_STAGE7)
    table gt_update_s7_tbl {
        actions = {
            gt_update_act_s7;
        }
        size = 2;
    }

    RegisterAction<bit<32>, bit<1>, bit<32>>(gt_stage8) gt_update_s8 = {
        void apply(inout bit<32> value) { value = value + 1; } };

    action gt_update_act_s8() {
        gt_update_s8.execute(0);
    }
    @stage(QUEUE_REG_STAGE8)
    table gt_update_s8_tbl {
        actions = {
            gt_update_act_s8;
        }
        size = 2;
    }

    RegisterAction<bit<32>, bit<1>, bit<32>>(gt_stage8) gt_update_s9 = {
        void apply(inout bit<32> value) { value = value + 1; } };

    action gt_update_act_s9() {
        gt_update_s9.execute(0);
    }
    @stage(QUEUE_REG_STAGE8)
    table gt_update_s9_tbl {
        actions = {
            gt_update_act_s9;
        }
        size = 2;
    }
    /***********************************************************/
    apply {
        if (g_intr_md.ping_pong == 1) {
            ping_update_tbl.apply();
            ping_update2_tbl.apply();
            ping_update3_tbl.apply();
            //gt_update_s2_tbl.apply();
            //gt_update_s3_tbl.apply();
            gt_update_s4_tbl.apply();
            gt_update_s5_tbl.apply();
            gt_update_s6_tbl.apply();
            gt_update_s7_tbl.apply();
            gt_update_s8_tbl.apply();
            gt_update_s9_tbl.apply();
            eg_ping_update_tbl.apply();
            eg_ping_update2_tbl.apply();
            eg_ping_update3_tbl.apply();
        } else {
            pong_update_tbl.apply();
            pong_update2_tbl.apply();
            pong_update3_tbl.apply();
            //gt_update_s2_tbl.apply();
            //gt_update_s3_tbl.apply();
            gt_update_s4_tbl.apply();
            gt_update_s5_tbl.apply();
            gt_update_s6_tbl.apply();
            gt_update_s7_tbl.apply();
            gt_update_s8_tbl.apply();
            gt_update_s9_tbl.apply();
            eg_pong_update_tbl.apply();
            eg_pong_update2_tbl.apply();
            eg_pong_update3_tbl.apply();
        }
    }
}
/*
 * Pipeline construction
 */

Pipeline(SxIngParser(), SxIngPipeline(), SxIngDeparser(), SxEgrParser(),
  SxEgrPipeline(), SxEgrDeparser(), SxQueueMonitor()) pipe;
Switch(pipe) main;
