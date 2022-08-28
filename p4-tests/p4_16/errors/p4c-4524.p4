//p4_16
//HULA implementation 
//automatic load balancing

#include <core.p4> //library for switch
#include <tna.p4>  //library for tofino native architecture

// headers.p4
/*******************************************************************************
 * BAREFOOT NETWORKS CONFIDENTIAL & PROPRIETARY
 *
 * Copyright (c) 2019-present Barefoot Networks, Inc.
 *
 * All Rights Reserved.
 *
 * NOTICE: All information contained herein is, and remains the property of
 * Barefoot Networks, Inc. and its suppliers, if any. The intellectual and
 * technical concepts contained herein are proprietary to Barefoot Networks, Inc.
 * and its suppliers and may be covered by U.S. and Foreign Patents, patents in
 * process, and are protected by trade secret or copyright law.  Dissemination of
 * this information or reproduction of this material is strictly forbidden unless
 * prior written permission is obtained from Barefoot Networks, Inc.
 *
 * No warranty, explicit or implicit is provided, unless granted under a written
 * agreement with Barefoot Networks, Inc.
 *
 ******************************************************************************/

#ifndef _HEADERS_
#define _HEADERS_

typedef bit<48> mac_addr_t;
typedef bit<32> ipv4_addr_t;
typedef bit<128> ipv6_addr_t;
typedef bit<12> vlan_id_t;

typedef bit<16> ether_type_t;
const ether_type_t ETHERTYPE_IPV4 = 16w0x0800;
const ether_type_t ETHERTYPE_ARP = 16w0x0806;
const ether_type_t ETHERTYPE_IPV6 = 16w0x86dd;
const ether_type_t ETHERTYPE_VLAN = 16w0x8100;

typedef bit<8> ip_protocol_t;
const ip_protocol_t IP_PROTOCOLS_ICMP = 1;
const ip_protocol_t IP_PROTOCOLS_TCP = 6;
const ip_protocol_t IP_PROTOCOLS_UDP = 17;

header ethernet_h {
    mac_addr_t dst_addr;
    mac_addr_t src_addr;
    bit<16> ether_type;
}

header vlan_tag_h {
    bit<3> pcp;
    bit<1> cfi;
    vlan_id_t vid;
    bit<16> ether_type;
}

header mpls_h {
    bit<20> label;
    bit<3> exp;
    bit<1> bos;
    bit<8> ttl;
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
    ipv4_addr_t src_addr;
    ipv4_addr_t dst_addr;
}

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
    bit<16> hdr_length;
    bit<16> checksum;
}

header icmp_h {
    bit<8> type_;
    bit<8> code;
    bit<16> hdr_checksum;
}

// Address Resolution Protocol -- RFC 6747
header arp_h {
    bit<16> hw_type;
    bit<16> proto_type;
    bit<8> hw_addr_len;
    bit<8> proto_addr_len;
    bit<16> opcode;
    // ...
}

// Segment Routing Extension (SRH) -- IETFv7
header ipv6_srh_h {
    bit<8> next_hdr;
    bit<8> hdr_ext_len;
    bit<8> routing_type;
    bit<8> seg_left;
    bit<8> last_entry;
    bit<8> flags;
    bit<16> tag;
}

// VXLAN -- RFC 7348
header vxlan_h {
    bit<8> flags;
    bit<24> reserved;
    bit<24> vni;
    bit<8> reserved2;
}

// Generic Routing Encapsulation (GRE) -- RFC 1701
header gre_h {
    bit<1> C;
    bit<1> R;
    bit<1> K;
    bit<1> S;
    bit<1> s;
    bit<3> recurse;
    bit<5> flags;
    bit<3> version;
    bit<16> proto;
}

//HULA Header
header hula_t { 
	bit<24> dst_tor;
	bit<8> path_util;
}

struct headers_t {
    ethernet_h ethernet;
    vlan_tag_h vlan_tag;
    ipv4_h ipv4;
    ipv6_h ipv6;
    tcp_h tcp;
    udp_h udp;
    hula_t hula;
    // Add more headers here.
}

struct empty_header_t {}

struct empty_metadata_t {}

#endif /* _HEADERS_ */

// util.p4
/*******************************************************************************
 * BAREFOOT NETWORKS CONFIDENTIAL & PROPRIETARY
 *
 * Copyright (c) 2019-present Barefoot Networks, Inc.
 *
 * All Rights Reserved.
 *
 * NOTICE: All information contained herein is, and remains the property of
 * Barefoot Networks, Inc. and its suppliers, if any. The intellectual and
 * technical concepts contained herein are proprietary to Barefoot Networks, Inc.
 * and its suppliers and may be covered by U.S. and Foreign Patents, patents in
 * process, and are protected by trade secret or copyright law.  Dissemination of
 * this information or reproduction of this material is strictly forbidden unless
 * prior written permission is obtained from Barefoot Networks, Inc.
 *
 * No warranty, explicit or implicit is provided, unless granted under a written
 * agreement with Barefoot Networks, Inc.
 *
 ******************************************************************************/

#ifndef _UTIL_
#define _UTIL_

parser TofinoIngressParser(
        packet_in pkt,
        out ingress_intrinsic_metadata_t ig_intr_md) {
    state start {
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
        transition accept;
    }
}

parser TofinoEgressParser(
        packet_in pkt,
        out egress_intrinsic_metadata_t eg_intr_md) {
    state start {
        pkt.extract(eg_intr_md);
        transition accept;
    }
}

// Skip egress
control BypassEgress(inout ingress_intrinsic_metadata_for_tm_t ig_tm_md) {

    action set_bypass_egress() {
        ig_tm_md.bypass_egress = 1w1;
    }

    table bypass_egress {
        actions = {
            set_bypass_egress();
        }
        const default_action = set_bypass_egress;
    }

    apply {
        bypass_egress.apply();
    }
}

// Empty egress parser/control blocks
parser EmptyEgressParser(
        packet_in pkt,
        out empty_header_t hdr,
        out empty_metadata_t eg_md,
        out egress_intrinsic_metadata_t eg_intr_md) {
    state start {
        transition accept;
    }
}

control EmptyEgressDeparser(
        packet_out pkt,
        inout empty_header_t hdr,
        in empty_metadata_t eg_md,
        in egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md) {
    apply {}
}

control EmptyEgress(
        inout empty_header_t hdr,
        inout empty_metadata_t eg_md,
        in egress_intrinsic_metadata_t eg_intr_md,
        in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
        inout egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
        inout egress_intrinsic_metadata_for_output_port_t eg_intr_oport_md) {
    apply {}
}

#endif /* _UTIL */


typedef bit<9>  egressSpec_t;
typedef bit<48> macAddr_t;
typedef bit<32> ip4Addr_t;
typedef bit<9> port_id_t;
typedef bit<16> port_id_t_chgd;
typedef bit<8> util_t;
typedef bit<24> tor_id_t;
typedef bit<48> time_t;
typedef bit<64> time_t_chgd;

/* Constants about the topology and switches. */
const port_id_t NUM_PORTS = 255;
const tor_id_t NUM_TORS = 512;
const bit<32> EGDE_HOSTS = 4;

/* Declaration for the various packet types. */
const bit<16> TYPE_IPV4 = 0x800;
const bit<8> PROTO_HULA = 0x42;
const bit<8> PROTO_TCP = 0x06;

/* Tracking things for flowlets */
const time_t_chgd FLOWLET_TOUT = 64w1 << 3; // 48w1 << 3;
const util_t PROBE_FREQ_FACTOR = 6;
const time_t_chgd KEEP_ALIVE_THRESH = 64w1 << PROBE_FREQ_FACTOR; // 48w1 << PROBE_FREQ_FACTOR;
const time_t PROBE_FREQ = 48w1 << PROBE_FREQ_FACTOR; // Here for documentation. Unused.

/*************************************************************************
*********************** H E A D E R S  ***********************************
*************************************************************************/
//headers definitions and such are in headers.p4
//struct headers_t {}

struct metadata_headers_t {
    bit<9> nxt_hop;
    bit<32> self_id;
    bit<32> dst_tor;
	bit<32> packet_length;
	
	bit<16> checksum_ipv4_tmp;
	bit<16> checksum_tcp_tmp;

	bool checksum_upd_ipv4;
	bool checksum_upd_tcp;

	bool checksum_err_ipv4_igprs;
}

/*************************************************************************
*********************** P A R S E R  ***********************************
*************************************************************************/

parser iParser(packet_in packet,
              out headers_t hdr,
              out metadata_headers_t meta,
		      out ingress_intrinsic_metadata_t ig_intr_md) { //required for switch
	TofinoIngressParser() tofino_parser;
	Checksum() ipv4_checksum;
	Checksum() tcp_checksum;

    state start {
	packet.extract(ig_intr_md);
	// tofino_parser.apply(packet, standard_metadata);
	packet.advance(PORT_METADATA_SIZE);
        transition parse_ethernet;
    }

    state parse_ethernet {
        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type) {
            TYPE_IPV4: parse_ipv4;
            default: accept;
        }
    }

    state parse_ipv4 {
        packet.extract(hdr.ipv4);
		ipv4_checksum.add(hdr.ipv4);
		meta.checksum_err_ipv4_igprs = ipv4_checksum.verify();

		tcp_checksum.subtract({hdr.ipv4.src_addr});
		tcp_checksum.subtract({hdr.ipv4.dst_addr});
		// meta.dst_ipv4 = hdr.ipv4.dst_addr;
        transition select(hdr.ipv4.protocol) {
          PROTO_HULA: parse_hula;
          PROTO_TCP: parse_tcp;
          default: accept;
        }
    }

    state parse_hula {
        packet.extract(hdr.hula);
        transition accept;
    }

    state parse_tcp {
        packet.extract(hdr.tcp);
		tcp_checksum.subtract({hdr.tcp.checksum});
		tcp_checksum.subtract({hdr.tcp.src_port});
		meta.checksum_tcp_tmp = tcp_checksum.get();

        transition accept;
    }

}

/*************************************************************************
**************  I N G R E S S   P R O C E S S I N G   *******************
*************************************************************************/

control Ingress(inout headers_t                                  hdr,
                inout metadata_headers_t                         meta,
				in ingress_intrinsic_metadata_t                  ig_intr_md,
				in ingress_intrinsic_metadata_from_parser_t      ig_prsr_md,
				inout ingress_intrinsic_metadata_for_deparser_t  ig_dprsr_md,
				inout ingress_intrinsic_metadata_for_tm_t        ig_tm_md)
{	
	action checksum_upd_udp(bool update) {
		meta.checksum_upd_tcp = update;
	}

    Hash<bit<32>>(HashAlgorithm_t.CRC16) flw_hash;

    /****** Registers to keep track of utilization. *******/

    // Keep track of the port utilization
    Register<util_t, bit<32>>((bit<32>) NUM_PORTS) port_util; 
    // Last time port_util was updated for a port.
    Register<time_t_chgd, bit<32>>((bit<32>) NUM_PORTS) port_util_last_updated;

    // Keep track of the last time a probe from dst_tor came.
    Register<time_t_chgd, bit<32>>((bit<32>) NUM_TORS) update_time;
    // Best hop for for each tor
    Register<port_id_t_chgd, bit<32>>((bit<32>) NUM_TORS) best_hop;
    // Last time a packet from a flowlet was observed.
    Register<time_t_chgd, bit<32>>((bit<32>) 1024) flowlet_time;
    // The next hop a flow should take.
    Register<port_id_t_chgd, bit<32>>((bit<32>) 1024) flowlet_hop;
    // Keep track of the minimum utilized path
    Register<util_t, bit<32>> ((bit<32>) NUM_TORS) min_path_util;

    //RegisterAction<bit<32>, bit<32>, time_t_chgd>(port_util) port_util_action = {
    RegisterAction<util_t, bit<32>, util_t>(port_util) port_util_action = {
        void apply(inout util_t util) {
            time_t_chgd last_update;
            time_t curr_time = ig_prsr_md.global_tstamp;
            bit<32> port = (bit<32>) ig_intr_md.ingress_port;
            last_update = port_util_last_updated.read(port);
            util = port_util.read(port);
            bit<8> delta_t = (bit<8>) ((bit<64>)curr_time - last_update);
            util = (((bit<8>) meta.packet_length + util) << PROBE_FREQ_FACTOR) - delta_t;
            util = util >> PROBE_FREQ_FACTOR;
            //port_util.write(port, util);
        }
    };
    RegisterAction<time_t_chgd, bit<32>, time_t_chgd>(port_util_last_updated) port_util_last_updated_action = {
       void apply(inout time_t_chgd curr_time) { //pass in T value
             curr_time = (time_t_chgd) ig_prsr_md.global_tstamp;
	     //port_util_last_updated.write(port, curr_time);
        }
    };
    RegisterAction<time_t_chgd, bit<32>, time_t_chgd>(update_time) update_time_action = {
	void apply (inout time_t_chgd up_time) {
	     time_t_chgd curr_time = (time_t_chgd) ig_prsr_md.global_tstamp; //64bit=48bit
	     bit<32> dst_tor = (bit<32>) hdr.hula.dst_tor;
	     util_t mpu;
	     util_t tx_util;
	     tx_util = port_util.read((bit<32>) ig_intr_md.ingress_port);
	     mpu = min_path_util.read(dst_tor);
	     up_time = update_time.read(dst_tor);
	     //if the current link util is higher then that is the path util
	     if(hdr.hula.path_util < tx_util) {
	     	hdr.hula.path_util = tx_util;
	     }
	     bool cond = (hdr.hula.path_util < mpu || curr_time - up_time > KEEP_ALIVE_THRESH);
	     up_time = cond ? curr_time : up_time;
	     //update_time.write(dst_tor, up_time);
	}
    };
    RegisterAction<port_id_t_chgd, bit<32>, port_id_t_chgd>(best_hop) best_hop_action = {
	void apply (inout port_id_t_chgd bh_temp) {
	     bit<32> dst_tor = (bit<32>) hdr.hula.dst_tor;
	     bh_temp = best_hop.read(dst_tor);
	     //best_hop.write(dst_tor, bh_temp);
	}
    };
    RegisterAction<util_t, bit<32>, util_t>(min_path_util) min_path_util_action = {
	void apply (inout util_t mpu) {
	     time_t_chgd curr_time = (time_t_chgd) ig_prsr_md.global_tstamp;
	     util_t tx_util;
	     time_t_chgd up_time;
	     tx_util = port_util.read((bit<32>) ig_intr_md.ingress_port);
	     bit<32> dst_tor = (bit<32>) hdr.hula.dst_tor;
	     mpu = min_path_util.read(dst_tor);
	     up_time = update_time.read(dst_tor);
	     //if current link util is higher then that is the path util
	     if(hdr.hula.path_util < tx_util) {
		hdr.hula.path_util = tx_util;
	     }
	     //if the path util from probe is lower than min path util, update best hop
	     bool cond = (hdr.hula.path_util < mpu || curr_time - up_time > KEEP_ALIVE_THRESH);
	     mpu = cond ? hdr.hula.path_util : mpu;
	     //min_path_util.write(dst_tor, mpu);

	    //SHOULD MPU BE AN OUTPUT OR CAN I SET THE HDR VARIABLE IN THIS??
	    mpu = min_path_util.read(dst_tor);
	    hdr.hula.path_util = mpu;
	}
    };
    RegisterAction<time_t_chgd, bit<32>, time_t_chgd>(flowlet_time) flowlet_time_action = {
	void apply (inout time_t_chgd curr_time) {
	     curr_time =(time_t_chgd) ig_prsr_md.global_tstamp;
	     bit<32> dst_tor = (bit<32>) hdr.hula.dst_tor;
	     time_t_chgd flow_t;
	     port_id_t_chgd best_h;
	     bit<32> flow_hash = (bit<32>)(flw_hash.get( {
		hdr.ipv4.src_addr,
		hdr.ipv4.dst_addr,
		hdr.ipv4.protocol,
		hdr.tcp.src_port,
		hdr.tcp.dst_port } ));
 	     flow_t = flowlet_time.read(flow_hash);
	     port_id_t_chgd flow_h;
	     best_h =(port_id_t_chgd) best_hop.read(meta.dst_tor);
	     bit<16> tmp;
	     tmp = flowlet_hop.read(flow_hash);
	     tmp = ((bit<64>)(curr_time - flow_t) > FLOWLET_TOUT) ? best_h : tmp; 
	     // flowlet_time.write(flow_hash, curr_time);

	     flow_h = flowlet_hop.read(flow_hash);
	     ig_tm_md.ucast_egress_port = (port_id_t) flow_h; //standard_metadata.egress_port
	}
};
    RegisterAction<port_id_t_chgd, bit<32>, port_id_t_chgd>(flowlet_hop) flowlet_hop_action = {
	void apply (inout port_id_t_chgd tmp) {
	     time_t_chgd curr_time = (time_t_chgd)hdr.hula.dst_tor;
	     bit<32> dst_tor = (bit<32>) hdr.hula.dst_tor;
	     time_t_chgd flow_t;
	     port_id_t_chgd best_h;
	     bit<32> flow_hash = (bit<32>)(flw_hash.get( {
		hdr.ipv4.src_addr,
		hdr.ipv4.dst_addr,
		hdr.ipv4.protocol,
		hdr.tcp.src_port,
		hdr.tcp.dst_port } ));
	     flow_t = flowlet_time.read(flow_hash);
	     best_h = best_hop.read(meta.dst_tor);
	     tmp = flowlet_hop.read(flow_hash);
	     tmp = ((bit<64>)curr_time - flow_t > FLOWLET_TOUT) ? best_h : tmp;
	     //flowlet_hop.write(flow_hash, tmp);
	}
    };

    action drop() {
        ig_dprsr_md.drop_ctl = 1; //disable packet replicaiton --bit 1 disables copy-to-cpu
    }

    /******************************************************/

    /**** Core HULA logic *****/ 

    action hula_handle_probe() {
  //      time_t_chgd curr_time = (time_t_chgd) ig_prsr_md.global_tstamp;
        bit<32> dst_tor = (bit<32>) hdr.hula.dst_tor;
/*
        util_t tx_util;
        util_t mpu;
        time_t_chgd up_time;

        tx_util = port_util.read( (bit<32>) ig_intr_md.ingress_port);
        mpu = min_path_util.read( dst_tor);
        up_time = update_time.read( dst_tor);

        // If the current link util is higher, then that is the path util.
        if(hdr.hula.path_util < tx_util) {
            hdr.hula.path_util = tx_util;
        }

        // If the path util from probe is lower than minimum path util,
        // update best hop.
        bool cond = (hdr.hula.path_util < mpu || curr_time - up_time > KEEP_ALIVE_THRESH);

        mpu = cond ? hdr.hula.path_util : mpu;
        min_path_util.write(dst_tor, mpu);
	
        up_time = cond ? curr_time : up_time;
        update_time.write(dst_tor, up_time);


        port_id_t_chgd bh_temp;
        bh_temp = best_hop.read( dst_tor);
        bh_temp = cond ? (port_id_t_chgd) ig_intr_md.ingress_port : bh_temp;
        best_hop.write(dst_tor, bh_temp);
*/
	update_time_action.execute(dst_tor);
	best_hop_action.execute(dst_tor);
	min_path_util_action.execute(dst_tor);

//        mpu = min_path_util.read( dst_tor);
//        hdr.hula.path_util = mpu;
    }
 //   Hash<bit<32>>(HashAlgorithm_t.CRC16) flw_hash;
    action hula_handle_data_packet() {
/*        time_t_chgd curr_time = (time_t_chgd) ig_prsr_md.global_tstamp;
        bit<32> dst_tor = (bit<32>) hdr.hula.dst_tor;

        util_t tx_util;
        tx_util = port_util.read((bit<32>) ig_intr_md.ingress_port);

       // bit<32> flow_hash;
        time_t_chgd flow_t;
        port_id_t_chgd flow_h;
        port_id_t_chgd best_h;

//        Hash(flow_hash, HashAlgorithm_t.CRC16, 32w0, {hdr.ipv4.src_addr, hdr.ipv4.dst_addr, hdr.ipv4.protocol, hdr.tcp.src_port, hdr.tcp.dst_port}, 32w1 << 10 - 1);
*/
	bit<32> flow_hash = (bit<32>)(flw_hash.get({
		hdr.ipv4.src_addr,
		hdr.ipv4.dst_addr,
		hdr.ipv4.protocol,
		hdr.tcp.src_port,
		hdr.tcp.dst_port }));

//        flow_t = flowlet_time.read(flow_hash);

        /*if (curr_time - flow_t > FLOWLET_TOUT) {*/
/*        best_h = best_hop.read(meta.dst_tor);
        port_id_t_chgd tmp;
	tmp = flowlet_hop.read( flow_hash);
        tmp = (curr_time - flow_t > FLOWLET_TOUT) ? best_h : tmp;
        flowlet_hop.write(flow_hash, tmp); // flowlet_hop.write(flow_hash, tmp); // write(in I, T value)
	//flow_hash = tmp;
        /*}*/
/*
        flow_h = flowlet_hop.read(flow_hash);
        ig_tm_md.ucast_egress_port = (port_id_t) flow_h; //standard_metadata.egress_port
        flowlet_time.write(flow_hash, curr_time);
*/
	flowlet_hop_action.execute(flow_hash);
	flowlet_time_action.execute(flow_hash);
    }

    table hula_logic {
        key = {
          hdr.ipv4.protocol: exact;
        }
        actions = {
          hula_handle_probe;
          hula_handle_data_packet;
          drop;
        }
        size = 4;
        default_action = drop();
    }

    /***********************************************/

    /***** Implement mapping from dstAddr to dst_tor ********/
    // Uses the destination address to compute the destination tor and the id of
    // current switch. The table is configured by the control plane.
    action set_dst_tor(tor_id_t dst_tor, tor_id_t self_id) {
        meta.dst_tor = (bit<32>) dst_tor;
        meta.self_id = (bit<32>) self_id;
    }

    // Used when matching a probe packet.
    action dummy_dst_tor() {
        meta.dst_tor = 0;
        meta.self_id = 1;
    }

    table get_dst_tor {
        key= {
          hdr.ipv4.dst_addr: exact;
        }
        actions = {
          set_dst_tor;
          dummy_dst_tor;
        }
        default_action = dummy_dst_tor;
    }

    /***********************/

    /********* Implement forwarding for edge nodes. ********/
    action simple_forward(egressSpec_t port) {
        ig_tm_md.ucast_egress_port = port; //was supposed to be egress_spec
    }

    table edge_forward {
        key = {
          hdr.ipv4.dst_addr: exact;
        }
        actions = {
          simple_forward;
          drop;
        }
        size = EGDE_HOSTS;
        default_action = drop();
    }

    /******************************************************/

    action update_ingress_statistics() {
      bit<32> port= (bit<32>) ig_intr_md.ingress_port; 
      port_util_action.execute(port); //bring in I index
      
      //last_update=(bit<64>)port_util_last_updated_action.execute(port); 
      //not bringing last_update into port_util_action anymore

      port_util_last_updated_action.execute(port);
      //pass in I index for U
    }

    apply {
        drop();
        get_dst_tor.apply();
        update_ingress_statistics();
        if (hdr.ipv4.isValid()) {
	  //tbl_hash1.apply();
          hula_logic.apply();
          if (hdr.hula.isValid()) {
            ig_tm_md.mcast_grp_a = (bit<16>)ig_intr_md.ingress_port;
          }
          if (meta.dst_tor == meta.self_id) {
              edge_forward.apply();
          }
        }
    }
}
/*************************************************************************
*************   C H E C K S U M    C O M P U T A T I O N   **************
*************************************************************************/

/*control VerifyChecksum(inout headers hdr, inout metadata meta) {
    apply {  }
}
*/
//***Deparser****//
control IngressDeparser(packet_out pkt,
			inout headers_t  hdr,
			in metadata_headers_t meta,
			in ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md)
{
	Checksum() ipv4_checksum;
	Checksum() tcp_checksum;

	apply {
		// updating and checking of the checksum is done in the deparser.
		if (meta.checksum_upd_ipv4) {
			hdr.ipv4.hdr_checksum = ipv4_checksum.update(
				{hdr.ipv4.version,
				 hdr.ipv4.ihl,
				 hdr.ipv4.diffserv,
				 hdr.ipv4.total_len,
				 hdr.ipv4.identification,
				 hdr.ipv4.flags,
				 hdr.ipv4.frag_offset,
				 hdr.ipv4.ttl,
				 hdr.ipv4.protocol,
				 hdr.ipv4.src_addr,
				 hdr.ipv4.dst_addr});
		}
		if (meta.checksum_upd_tcp) {
			hdr.tcp.checksum = tcp_checksum.update(
				{hdr.tcp.src_port,
				hdr.tcp.dst_port,
				hdr.tcp.seq_no,
				hdr.tcp.ack_no,
				hdr.tcp.data_offset,
				hdr.tcp.res,
				hdr.tcp.flags,
				hdr.tcp.window,
				hdr.tcp.urgent_ptr});
		}

		pkt.emit(hdr);
	}
}

/*************************************************************************
****************  E G R E S S   P R O C E S S I N G   *******************
*************************************************************************/

//this is empty but what the switch requires :/
//the empty headers are within util.p4

struct egress_headers_t {
}
struct egress_metadata_t {
}
//***Parser***//
parser EgressParser(packet_in                       pkt,
					out egress_headers_t            hdr,
					out egress_metadata_t           meta,
					out egress_intrinsic_metadata_t eg_intr_md)
{
	state start {  //mandatory state for tna
		pkt.extract(eg_intr_md);
		transition accept;
	}
}


/*************************************************************************
***********************  S W I T C H  *******************************
*************************************************************************/

Pipeline(
	iParser(),
	Ingress(),
	IngressDeparser(),
	EmptyEgressParser(),
	EmptyEgress(),
	EmptyEgressDeparser()
) pipe;
Switch(pipe) main;
