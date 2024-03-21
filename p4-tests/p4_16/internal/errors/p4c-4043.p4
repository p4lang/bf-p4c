#include <t2na.p4>

#define ETHERTYPE_PFC  0x8808
#define UDP_PORT_SFC_PAUSE  1674
#define TCP_FLAGS_SFC_PAUSE 1
#define SFC_QUEUE_IDX_SIZE 512
#define SFC_PAUSE_DURATION_SIZE 1024

header ethernet_h {
    bit<48> dst_addr;
    bit<48> src_addr;
    bit<16> ether_type;
}

header pfc_h {
    bit<16> opcode;
    bit<8> reserved_zero;
    bit<8> class_enable_vec;
    bit<16> tstamp0;
    bit<16> tstamp1;
    bit<16> tstamp2;
    bit<16> tstamp3;
    bit<16> tstamp4;
    bit<16> tstamp5;
    bit<16> tstamp6;
    bit<16> tstamp7;
}

header ipv4_h {
    bit<4> version;
    bit<4> ihl;
    bit<8> diffserv;
    bit<16> total_len;
    bit<16> identification;
    bit<3> flags;
    bit<13> frag_offset;
    bit<8> ttl;
    bit<8> protocol;
    bit<16> hdr_checksum;
    bit<32> src_addr;
    bit<32> dst_addr;
}

header ipv4_option_h {
    bit<8> type;
    bit<8> length;
    bit<16> value;
}

header tcp_h {
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

header udp_h {
    bit<16> src_port;
    bit<16> dst_port;
    bit<16> length;
    bit<16> checksum;
}

header sfc_pause_h {
    bit<8> version;
    bit<8> dscp;
    bit<16> duration_us;
}

enum bit<3> SfcPacketType {
    Unset           = 0,
    None            = 1,  // No SFC packet
    Data            = 2,  // Normal SFC data packet, SFC is enabled
    Trigger         = 3,  // SFC pause packet after mirroring, SFC is enabled
    Signal          = 4,  // SFC pause packet after SFC pause packet construction, SFC is enabled
    TcSignalEnabled = 5   // No SFC packet, but a packet on a SignalingEnabledTC
}

struct switch_header_t {
    ethernet_h  ethernet;
    pfc_h       pfc;
    ipv4_h      ipv4;
    ipv4_option_h ipv4_option;
    tcp_h       tcp;
    udp_h       udp;
    sfc_pause_h sfc_pause;
}
struct switch_ingress_metadata_t {
    PortId_t    port;
}
struct switch_qos_metadata_t {
    bit<8>      queue_register_idx;
    bit<19>     qdepth;
}
struct switch_sfc_egress_metadata_t {
    SfcPacketType       type;
    bit<16>     q_drain_length;
    bit<8>      pause_dscp;
    bit<8>      queue_register_idx;
    bit<16>     pause_duration_us;
}
struct switch_egress_metadata_t {
    SfcPacketType       type;
    bit<16>     pkt_length;
    PortId_t    port;
    switch_qos_metadata_t qos;
    switch_sfc_egress_metadata_t sfc;
}

enum bit<2> LinkToType { Unknown = 0, Switch = 1, Server = 2 }

struct sfc_qd_threshold_register_t {
    bit<32> qdepth_drain_cells;
    bit<32> target_qdepth;
}

parser SwitchIngressParser(
        packet_in pkt,
        out switch_header_t hdr,
        out switch_ingress_metadata_t ig_md,
        out ingress_intrinsic_metadata_t ig_intr_md) {
    state start {
        pkt.extract(ig_intr_md);
        ig_md.port = ig_intr_md.ingress_port;
        transition accept;
    }
}

control SwitchIngress(
        inout switch_header_t hdr,
        inout switch_ingress_metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_intr_from_prsr,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm,
        in ghost_intrinsic_metadata_t g_intr_md
        ) {
    apply {
    }
}

control SwitchIngressDeparser(
    packet_out pkt,
    inout switch_header_t hdr,
    in switch_ingress_metadata_t ig_md,
    in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) {

    apply {
    }
}

parser SwitchEgressParser(
        packet_in pkt,
        out switch_header_t hdr,
        out switch_egress_metadata_t eg_md,
        out egress_intrinsic_metadata_t eg_intr_md) {

    state start {
        pkt.extract(eg_intr_md);
        eg_md.pkt_length = eg_intr_md.pkt_length;
        eg_md.port = eg_intr_md.egress_port;
        eg_md.qos.qdepth = eg_intr_md.deq_qdepth;
        transition accept;
    }
}

/*
 *
 * Dependencies:
 *   after:
 *     - EgressPortMapping
 */
control EgressSfc(in egress_intrinsic_metadata_t eg_intr_md,
                  in switch_qos_metadata_t qos,
                  inout switch_header_t hdr,
                  inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
                  inout switch_sfc_egress_metadata_t sfc)
                 (bit<32> queue_idx_size,
                  bit<32> pause_duration_table_size) {

    DirectCounter<bit<8>>(CounterType_t.PACKETS_AND_BYTES) stats_time_conversion;

    // Egress thread: queue depth value
    Register<sfc_qd_threshold_register_t, bit<8>>(queue_idx_size) reg_qdepth;

    /*
     * SfcPacketType.Data packet: write queue depth
     * How set qdepth_drain_cells for testing:
     * Override qdepth_drain_cells only if in the existing value the msb is not set.
     * Since the qdepth value in eg_md is 19 bits only, and the register is 32 bit,
     * the msb can only be set through the control plane. For testing, the control
     * has to write a qdepth_drain_cells value with the msb set, then data packets
     * will not override the value in the register. If the msb is not set, they will,
     * as is expected for operating SFC.
     */
    RegisterAction<sfc_qd_threshold_register_t, bit<8>, int<32>>(reg_qdepth) qd_write = {
        void apply(inout sfc_qd_threshold_register_t value) {
            // For testing: if the msb is set, keep the existing value.
            // Since qdepth is bit<19> it should never set this bit just by writing a normal value.
            if (value.qdepth_drain_cells < 32w0x80000000) {
                if (value.target_qdepth < 0x80000000) {
                    value.qdepth_drain_cells = (bit<32>)(qos.qdepth |-| (bit<19>)value.target_qdepth)[18:6];
                    // expect error@-1: "Expression too complex for RegisterAction - result of an instruction cannot be sliced"
                } else if (value.target_qdepth < 0x40000000) {
                    value.qdepth_drain_cells = (bit<32>)(qos.qdepth |-| (bit<19>)value.target_qdepth)[18:5];
                    // expect error@-1: "Expression too complex for RegisterAction - result of an instruction cannot be sliced"
                } else if (value.target_qdepth < 0x20000000) {
                    value.qdepth_drain_cells = (bit<32>)(qos.qdepth |-| (bit<19>)value.target_qdepth)[18:4];
                    // expect error@-1: "Expression too complex for RegisterAction - result of an instruction cannot be sliced"
                }
            }
        }
    };

    action data_qd_write() {
        qd_write.execute(sfc.queue_register_idx);
    }

    // SfcPacketType.Trigger: read queue depth
    RegisterAction<sfc_qd_threshold_register_t, bit<8>, bit<16>>(reg_qdepth) qd_read = {
        void apply(inout sfc_qd_threshold_register_t value, out bit<16> rv) {
            rv = (bit<16>)value.qdepth_drain_cells;
        }
    };

    action trigger_qd_read() {
        sfc.q_drain_length = qd_read.execute(sfc.queue_register_idx);
    }

    action do_time_conversion_count() {
        stats_time_conversion.count();
    }
    /*
     * 176 bytes per cell, converting draining time to 1us precision
     * 25GBE => 25,000,000,000/8/1,000,000/176 = 17.76 cells/us
     * 50GBE => 50,000,000,000/8/1,000,000/176 = 35.5 cells/us
     * 100GBE => 100,000,000,000/8/1,000,000/176 = 71 cells/us
     * Approximation of dividers
     * 25GBE: 16
     * 50GBE: 32
     * 100GBE: 64
     * For all conversions, the resulting value is guaranteed to be smaller than
     * 16 bits, which means the type case should be lossless.
     * we think 16 bit with microseconds as the unit is enough. 
     * The maximum switch buffer can support with this pause_duration_us are as follows:
     * 25GBE: 65535 us *25GBE/8.0 = 204,796KB
     * 50GBE: 65535 us *50GBE/8.0 = 409,593KB
     * 100GBE: 65535 us *100GBE/8.0 = 819,187KB  
     * As long as the switch buffer size is less than the above values, we are safe to use 16-bit pause_duration_us.
     */
    bit<8> sfc_pause_packet_dscp;
    action do_set_pause(bit<8> _sfc_pause_dscp) {
        do_time_conversion_count();
        sfc.pause_dscp = hdr.ipv4.diffserv >> 2;
        sfc_pause_packet_dscp = _sfc_pause_dscp;
    }
    action do_calc_cells_to_pause_25g(bit<8> _sfc_pause_dscp) {
        do_set_pause(_sfc_pause_dscp);
        sfc.pause_duration_us = (bit<16>)qd_read.execute(sfc.queue_register_idx);
    }
    action do_calc_cells_to_pause_50g(bit<8> _sfc_pause_dscp) {
        do_set_pause(_sfc_pause_dscp);
        sfc.pause_duration_us = (bit<16>)qd_read.execute(sfc.queue_register_idx);
    }
    action do_calc_cells_to_pause_100g(bit<8> _sfc_pause_dscp) {
        do_set_pause(_sfc_pause_dscp);
        sfc.pause_duration_us = (bit<16>)qd_read.execute(sfc.queue_register_idx);
    }

    /*
     * time_conversion_factor = 1000/(512*linkspeed)
     * if link speed is 25Gbps, time_conversion_factor = 48.8
     * if link speed is 50Gbps, time_conversion_factor = 97.6
     * if link speed is 100Gbps, time_conversion_factor = 195.2
     * Approximation of multipliers
     * 25GBE: 48 = 32 + 16
     * 50GBE: 92 = 64 + 32
     * 100GBE: 196 = 128 + 64
     * 25GBE: 48 = 32 + 16; the max pause_time_us to avoid overflow is 1365; for safety, 1200;
     * 50GBE: 92 = 64 + 32; the max pause_time_us to avoid overflow is 712; for safety, 700;
     * 100GBE: 196 = 128 + 64; the max pause_time_us to avoid overflow is 334; for safety, 320;
     */
    bit<16> multiplier_second_part;
    LinkToType link_to_type;

    action do_calc_pause_to_pfc_time_25g(LinkToType _link_to_type){
        do_time_conversion_count();
        multiplier_second_part = sfc.pause_duration_us << 4;
        sfc.pause_duration_us = sfc.pause_duration_us << 5;
        link_to_type = _link_to_type;    
    }
    action do_calc_pause_to_pfc_time_50g(LinkToType _link_to_type){
        do_time_conversion_count();
        multiplier_second_part = sfc.pause_duration_us << 5;
        sfc.pause_duration_us = sfc.pause_duration_us << 6;
	    link_to_type = _link_to_type;    
    }
    action do_calc_pause_to_pfc_time_100g(LinkToType _link_to_type){
        do_time_conversion_count();
        multiplier_second_part = sfc.pause_duration_us << 6;
        sfc.pause_duration_us = sfc.pause_duration_us << 7;
	    link_to_type = _link_to_type;    
   }

    // Todo, this is hardcode
    action testing_conversion(bit<16> pause_duration){
        do_time_conversion_count();
        sfc.pause_duration_us = pause_duration; //0x000a; //0xdac;  	
    }	

    table pause_time_conversion{
        key = {
            sfc.type : ternary@name("sfc_type");
            sfc.queue_register_idx: exact@name("queue_register_index");
            sfc.pause_duration_us: range@name("pause_duration_us");
        }

        actions = {
            do_time_conversion_count;
            do_calc_cells_to_pause_25g;
            do_calc_cells_to_pause_50g;
            do_calc_cells_to_pause_100g;
            do_calc_pause_to_pfc_time_25g;
            do_calc_pause_to_pfc_time_50g;
            do_calc_pause_to_pfc_time_100g;
            testing_conversion;
        }
        const default_action = do_time_conversion_count;
        counters = stats_time_conversion;
        size = 64;
    }
    

    action do_convert_to_pfc_pause(bit<8> pfc_prio_enable_bitmap) {
        hdr.ipv4.setInvalid();
        hdr.udp.setInvalid();
        hdr.sfc_pause.setInvalid();
        //PFC pkts (802.1Qbb 66B) -- dstmac(6B),srcmac(6B),TYPE(2B8808),Opcode(2B0101),CEV(2B),Time0-7(8*2B),Pad(28B),CRC(4B)            
        hdr.ethernet.src_addr = 0x000000000000;//ori_dst_mac;
        hdr.ethernet.ether_type = ETHERTYPE_PFC;

        hdr.pfc.setValid();
        hdr.pfc.opcode = 16w0x0101;
        hdr.pfc.class_enable_vec = pfc_prio_enable_bitmap;
        hdr.pfc.tstamp0 = sfc.pause_duration_us + multiplier_second_part;
        hdr.pfc.tstamp1 = sfc.pause_duration_us + multiplier_second_part;
        hdr.pfc.tstamp2 = sfc.pause_duration_us + multiplier_second_part;
        hdr.pfc.tstamp3 = sfc.pause_duration_us + multiplier_second_part;
        hdr.pfc.tstamp4 = sfc.pause_duration_us + multiplier_second_part;
        hdr.pfc.tstamp5 = sfc.pause_duration_us + multiplier_second_part;
        hdr.pfc.tstamp6 = sfc.pause_duration_us + multiplier_second_part;
        hdr.pfc.tstamp7 = sfc.pause_duration_us + multiplier_second_part;
    }

    table convert_to_pfc_pause {
        key = {
            sfc.pause_dscp : ternary@name("pause_dscp");
        }
        actions = {
            NoAction;
            do_convert_to_pfc_pause;
        }
        default_action = NoAction;
        size = 64;
    }

    action do_gen_pause() {
        bit<48> ori_src_mac;
        bit<48> ori_dst_mac;
        ori_src_mac = hdr.ethernet.src_addr;
        ori_dst_mac = hdr.ethernet.dst_addr;
        hdr.ethernet.src_addr = ori_dst_mac;
        hdr.ethernet.dst_addr = ori_src_mac;

        //L3
        bit<32> orig_src_ip;
        bit<32> orig_dst_ip;
        // bit<8> data_packet_dscp;
	      orig_src_ip = hdr.ipv4.src_addr;
        orig_dst_ip = hdr.ipv4.dst_addr;
        hdr.ipv4.src_addr = orig_dst_ip;
        hdr.ipv4.dst_addr = orig_src_ip;
        hdr.ipv4.total_len = 46;
        hdr.ipv4.hdr_checksum = 0;
        eg_intr_md_for_dprsr.mtu_trunc_len = 64;
    }

    action gen_sfc_pause_for_rocev2(){
        do_gen_pause();
        hdr.ipv4.diffserv = sfc_pause_packet_dscp;
        hdr.ipv4_option.setInvalid();	
        // udp
        hdr.udp.length = 26;
        hdr.udp.dst_port = UDP_PORT_SFC_PAUSE;
        hdr.udp.checksum = 0;
        // sfc star packet format
        hdr.sfc_pause.setValid();
        hdr.sfc_pause.dscp = sfc.pause_dscp;
        hdr.sfc_pause.duration_us = sfc.pause_duration_us;
    }

    action gen_sfc_pause_for_tcp(){
        do_gen_pause();
        hdr.ipv4_option.setInvalid();
        hdr.ipv4.diffserv = 0;
        //tcp header     
        bit<16> orig_src_port;
        bit<16> orig_dst_port;
        orig_src_port = hdr.tcp.src_port;
        orig_dst_port = hdr.tcp.dst_port;
        hdr.tcp.src_port = orig_dst_port;
        hdr.tcp.dst_port = orig_src_port;
        hdr.tcp.checksum = 0;
        //yle: use the last bit in the reservation field to let tcp stack know
        // this is an SFC packet. 
        // TCP_FLAGS_SFC_PAUSE = 1
        hdr.tcp.res = TCP_FLAGS_SFC_PAUSE; 
        //yle: reuse seq_no as the pause_time
        hdr.tcp.seq_no = (bit<32>)sfc.pause_duration_us;
    }

    Register<bit<32>, PortId_t>(512,0) sfc_count;
    RegisterAction<bit<32>, PortId_t, bit<32>>(sfc_count) sfc_count_increase = {
        void apply(inout bit<32> value, out bit<32> read_value) {
            value = value + 1;
        }
    };
    Register<bit<32>, PortId_t>(512,0) recirculation_port_pkt_count;
    RegisterAction<bit<32>, PortId_t, bit<32>>(recirculation_port_pkt_count) recirculation_port_pkt_count_increase = {
        void apply(inout bit<32> value, out bit<32> read_value) {
            value = value + 1;
        }
    };


    apply {
	recirculation_port_pkt_count_increase.execute(eg_intr_md.egress_port);
        if (sfc.type == SfcPacketType.Data) {
            data_qd_write();
        } else if (sfc.type == SfcPacketType.Trigger) {
            trigger_qd_read();
        }

   	pause_time_conversion.apply();
        
	if (sfc.type == SfcPacketType.Trigger) {
        if (hdr.udp.isValid()) {
            gen_sfc_pause_for_rocev2();
        } else {
            gen_sfc_pause_for_tcp();
        }
	    sfc_count_increase.execute(eg_intr_md.egress_port);
        } else if (sfc.type == SfcPacketType.Signal && link_to_type == LinkToType.Server) {
            if (hdr.sfc_pause.isValid()) {
                convert_to_pfc_pause.apply();
            }
        }
    }
}

control SwitchEgressDeparser(
        packet_out pkt,
        inout switch_header_t hdr,
        in switch_egress_metadata_t eg_md,
        in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {

    apply {
    }
}

control SwitchEgress(
    inout switch_header_t hdr,
    inout switch_egress_metadata_t eg_md,
    in egress_intrinsic_metadata_t eg_intr_md,
    in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
    inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
    inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {
    EgressSfc(SFC_QUEUE_IDX_SIZE, SFC_PAUSE_DURATION_SIZE) sfc;

    apply {
        sfc.apply(eg_intr_md, eg_md.qos, hdr, eg_intr_md_for_dprsr, eg_md.sfc);
    }
}

Pipeline(SwitchIngressParser(),
         SwitchIngress(),
         SwitchIngressDeparser(),
         SwitchEgressParser(),
         SwitchEgress(),
         SwitchEgressDeparser()) pipe;

Switch(pipe) main;


