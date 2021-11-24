/* -*- P4_16 -*- */

#include <core.p4>
#if __TARGET_TOFINO__ != 1
#include <t2na.p4>
#else
#include <tna.p4>
#endif
typedef bit<8>  pkt_type_t;
const pkt_type_t PKT_TYPE_NORMAL  = 1;
const pkt_type_t PKT_TYPE_MIRROR  = 2;
const pkt_type_t PKT_TYPE_CAPTURE = 3;
const pkt_type_t PKT_TYPE_CAPTURE_FINAL = 5;
/*************************************************************************
 ************* C O N S T A N T S    A N D   T Y P E S  *******************
**************************************************************************/
const bit<16> ETHERTYPE_TPID = 0x8100;
const bit<16> ETHERTYPE_IPV4 = 0x0800;

typedef bit<8> ip_protocol_t;
const ip_protocol_t IP_PROTOCOLS_ICMP = 1;
const ip_protocol_t IP_PROTOCOLS_IGMP = 2;
const ip_protocol_t IP_PROTOCOLS_IPV4 = 4;
const ip_protocol_t IP_PROTOCOLS_IPV6 = 41;
const ip_protocol_t IP_PROTOCOLS_TCP = 6;
const ip_protocol_t IP_PROTOCOLS_UDP = 17;
const ip_protocol_t IP_PROTOCOLS_OSPF = 89;
const ip_protocol_t IP_PROTOCOLS_GRE = 47;
/*************************************************************************
 ***********************  H E A D E R S  *********************************
 *************************************************************************/

/*  Define all the headers the program will recognize             */
/*  The actual sets of headers processed by each gress can differ */
/* Ingress mirroring information */



typedef bit<4> port_type_t;
const port_type_t FRONTPANEL_PORT = 1;
const port_type_t L23_PORT = 2;
const port_type_t L47_PORT = 3;
const port_type_t CAPTURE_PORT = 4;
const port_type_t RESUBMIT_PORT = 5;

#if __TARGET_TOFINO__ == 1
typedef bit<3> mirror_type_t;
#else
typedef bit<4> mirror_type_t;
#endif
const mirror_type_t MIRROR_TYPE_I2E = 1;
const mirror_type_t MIRROR_TYPE_E2E = 2;

/* Standard ethernet header */
header ethernet_h {
    bit<48>   dst_addr;
    bit<48>   src_addr;
    bit<16>   ether_type;
}

header vlan_tag_h {
    bit<3>   pcp;
    bit<1>   cfi;
    bit<12>  vid;
    bit<16>  ether_type;
}

header ipv4_h {
    bit<4>   version;
    bit<4>   ihl;
    bit<8>   diffserv;
    bit<16>  total_len;
    bit<16>  identification;
    bit<3>   flags;
    bit<13>  frag_offset;
    bit<8>   ttl;
    bit<8>   protocol;
    bit<16>  hdr_checksum;
    bit<32>  src_addr;
    bit<32>  dst_addr;
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

header l23signature_h {
    bit<32> signature_top;
    bit<32> signature_bot;
    bit<32> rx_timestamp;
    bit<32> pgid;
    bit<32> sequence;
    bit<32> txtstamp;
}

header capture_h {
    bit<24> seq_no;
    bit<8>  reserved;
    bit<32> timestamp;
}

header mirror_h {
   pkt_type_t pkt_type;
   bit<32> mac_timestamp;
}

#if __TARGET_TOFINO__ == 1
typedef bit<32> signature_t;
#else
typedef bit<64> signature_t;
#endif

struct port_metadata_t {
    //temporary since we have only 64-bits port metadata for tofino1
    // will be 192 bits in T2
    signature_t port_signature;
    port_type_t port_type;
    bit<8> capture_port;
}

@flexible
header example_bridge_h {
   pkt_type_t pkt_type;
   bit<1> l47_timestamp_insert;
   bit<1> l23_txtstmp_insert;
   bit<1> l23_rxtstmp_insert;
   bit<1> rich_register_v;
   bit<8> rich_register;
}

struct my_ingress_headers_t {
    example_bridge_h  bridge;
    capture_h    capture;
    ethernet_h   ethernet;
    vlan_tag_h   vlan_tag;
    ipv4_h       ipv4;
    tcp_h        tcp;
    udp_h        udp;
    l23signature_h first_payload;
}

struct my_ingress_metadata_t {
    port_metadata_t port_properties;
    bit<16> l47_ib_ethertype;
    MirrorId_t  mirror_session;
    bit<32>  mac_timestamp;
    pkt_type_t pkt_type;
}

struct my_egress_headers_t {
    example_bridge_h  bridge;
    capture_h    capture;
    ethernet_h   ethernet;
    vlan_tag_h   vlan_tag;
    ipv4_h       ipv4;
    tcp_h        tcp;
    udp_h        udp;
    l23signature_h first_payload;
}

    /********  G L O B A L   E G R E S S   M E T A D A T A  *********/

struct my_egress_metadata_t {
    example_bridge_h  bridge;
    mirror_h  ing_port_mirror;
    MirrorId_t  mirror_session;
    pkt_type_t pkt_type;
}


/*************************************************************************
 **************  I N G R E S S   P R O C E S S I N G   *******************
 *************************************************************************/
    /***********************  P A R S E R  **************************/
parser IngressParser(packet_in        pkt,
    /* User */
    out my_ingress_headers_t          hdr,
    out my_ingress_metadata_t         meta,
    /* Intrinsic */
    out ingress_intrinsic_metadata_t  ig_intr_md)
{
    /* This is a mandatory state, required by Tofino Architecture */
     state start {
        pkt.extract(ig_intr_md);
        meta.port_properties = port_metadata_unpack<port_metadata_t>(pkt);
        meta.pkt_type = PKT_TYPE_NORMAL;
        meta.mac_timestamp = 0;
        meta.mirror_session = 0;
        meta.l47_ib_ethertype = 0;
        hdr.bridge.setValid();
        hdr.bridge.pkt_type = PKT_TYPE_NORMAL;
        hdr.bridge.l47_timestamp_insert = 0;
        hdr.bridge.l23_txtstmp_insert = 0;
        hdr.bridge.l23_rxtstmp_insert = 0;
        hdr.bridge.rich_register = 0;
        hdr.bridge.rich_register_v = 1w0;
        transition select(meta.port_properties.port_type)
        {
            CAPTURE_PORT : parse_capture_depth;
            RESUBMIT_PORT: parse_capture;
            default: parse_ethernet;
        }
    }

    state parse_capture_depth {
        pkt.extract(hdr.capture);
        transition accept;
    }

    state parse_capture {
        pkt.extract(hdr.capture);
        meta.pkt_type = PKT_TYPE_CAPTURE;
        hdr.bridge.pkt_type = PKT_TYPE_CAPTURE_FINAL;
        transition accept;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type) {
            ETHERTYPE_TPID:  parse_vlan_tag;
            ETHERTYPE_IPV4:  parse_ipv4;
            default: accept;
        }
    }

    state parse_vlan_tag {
        pkt.extract(hdr.vlan_tag);
        transition select(hdr.vlan_tag.ether_type) {
            ETHERTYPE_IPV4:  parse_ipv4;
            default: accept;
        }
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        transition select(hdr.ipv4.protocol) {
            IP_PROTOCOLS_TCP: parseTcp;
            IP_PROTOCOLS_UDP: parseUdp;
            default: parseL23;
      }
    }

    state parseTcp {
      pkt.extract(hdr.tcp);
      pkt.extract(hdr.first_payload);
      transition accept;
    }

    state parseUdp {
      pkt.extract(hdr.udp);
      pkt.extract(hdr.first_payload);
      transition accept;
    }

    state parseL23 {
      pkt.extract(hdr.first_payload);
      transition accept;
    }

}

    /***************** M A T C H - A C T I O N  *********************/
typedef bit<3> capture_index_t;
/*******************************************************************/
control update_register(in bit<16> full_length, in bit<8> capture_ov,
	in PortId_t inport, in pkt_type_t pkt_type, inout bit<8> rich_register )
{
    bit<16> debt0;
    bit<16> debt1;
    bit<16> debt2;
    bit<16> debt3;
    bit<16> debt4;
    bit<16> negated_length;
    bit<16> load_length;
    bit<16> cap_length_1 = 0;
    bit<16> cap_length_2 = 0;
    bit<16> cap_length_3 = 0;
    bit<16> cap_length_4 = 0;
    bit<16> cap_length_5 = 0;
    bit<8>  reg0=0;
    bit<8>  reg1=1;
    bit<8>  reg2=2;
    bit<8>  new_rich;
    bit<8>  capture_port;
    bit<16> portion;
    bit<16> padded_length;
    Counter<bit<64>, bit<8>>( 8, CounterType_t.PACKETS) debug_stats;

    Register<bit<8>, bit<3>>(size=1, initial_value=0) random_assign;
    RegisterAction<bit<8>, bit<2>, bit<8>>(random_assign)
    random_assign_reg = {
        void apply(inout bit<8> register_data, out bit<8> result)
        {
            result = register_data;
            if (register_data == 4)
                register_data = 0;
            else
                register_data = register_data + 1;
        }
    };


    action pad_out_length()
    {
        padded_length = portion;
    }

    action lookupIndex(bit<8> port)
    {
        capture_port = capture_ov;//port;
        padded_length = full_length + portion;
        debug_stats.count(port);
    }

    action lookupCapturePort()
    {
        capture_port = random_assign_reg.execute(0);
        pad_out_length();
    }

    table captureLookupTbl {
        key = {
            inport : exact;
        }
        actions = {
            lookupIndex;
            lookupCapturePort;
        }
        default_action = lookupCapturePort;
        size = 32;
    }

    Register<bit<16>, capture_index_t>(size=1, initial_value=0x0fff) active_debt_reg0;
    RegisterAction<bit<16>, capture_index_t, bit<16>>(active_debt_reg0)
    increase_reg0 = {
        void apply(inout bit<16> register_data, out bit<16> result)
        {
            result = register_data;
            register_data = cap_length_1 + result;
        }
    };

    Register<bit<16>, bit<3>>(size=1, initial_value=0x0fff) active_debt_reg1;
    RegisterAction<bit<16>, capture_index_t, bit<16>>(active_debt_reg1)
    increase_reg1 = {
        void apply(inout bit<16> register_data, out bit<16> result)
        {
            result = min(debt0, register_data);
            register_data = cap_length_2 + register_data;
        }
    };

    Register<bit<16>, bit<3>>(size=1, initial_value=0x0fff) active_debt_reg2;
    RegisterAction<bit<16>, capture_index_t, bit<16>>(active_debt_reg2)
    increase_reg2 = {
        void apply(inout bit<16> register_data, out bit<16> result)
        {
            result = min(debt1, register_data);
            register_data = cap_length_3 + register_data;
        }
    };

    Register<bit<16>, bit<3>>(size=1, initial_value=0x0fff) active_debt_reg3;
    RegisterAction<bit<16>, capture_index_t, bit<16>>(active_debt_reg3)
    increase_reg3 = {
        void apply(inout bit<16> register_data, out bit<16> result)
        {
            result = min(debt2, register_data);
            register_data = cap_length_4 + register_data;
        }
    };

    Register<bit<16>, bit<3>>(size=1, initial_value=0x0fff) active_debt_reg4;
    RegisterAction<bit<16>, capture_index_t, bit<16>>(active_debt_reg4)
    increase_reg4 = {
        void apply(inout bit<16> register_data, out bit<16> result)
        {
            result = min(debt3, register_data);
            register_data = cap_length_5 + register_data;
        }
    };


    action negate_pad()
    {
        negated_length = ~(padded_length);
        load_length = padded_length << 2;
    }

    action capture_port_1()
    {
        cap_length_1 = load_length;
        cap_length_2 = negated_length + 1;
        cap_length_3 = negated_length + 1;
        cap_length_4 = negated_length + 1;
        cap_length_5 = negated_length + 1;
    }

    action capture_port_2()
    {
        cap_length_2 = load_length;
        cap_length_1 = negated_length + 1;
        cap_length_3 = negated_length + 1;
        cap_length_4 = negated_length + 1;
        cap_length_5 = negated_length + 1;
    }

    action capture_port_3()
    {
        cap_length_3 = load_length;
        cap_length_2 = negated_length + 1;
        cap_length_1 = negated_length + 1;
        cap_length_4 = negated_length + 1;
        cap_length_5 = negated_length + 1;
    }

    action capture_port_4()
    {
        cap_length_4 = load_length;
        cap_length_2 = negated_length + 1;
        cap_length_3 = negated_length + 1;
        cap_length_1 = negated_length + 1;
        cap_length_5 = negated_length + 1;
    }

    action capture_port_5()
    {
        cap_length_5 = load_length;
        cap_length_2 = negated_length + 1;
        cap_length_3 = negated_length + 1;
        cap_length_4 = negated_length + 1;
        cap_length_1 = negated_length + 1;
    }

    action comp_port_1_2()
    {
        cap_length_1 = negated_length + 1;
        cap_length_2 = padded_length;
        cap_length_3 = 0;
        cap_length_4 = 0;
        cap_length_5 = 0;
    }

    action comp_port_1_3()
    {
        cap_length_1 = negated_length + 1;
        cap_length_2 = 0;
        cap_length_3 = padded_length;
        cap_length_4 = 0;
        cap_length_5 = 0;
    }

    action comp_port_1_4()
    {
        cap_length_1 = negated_length + 1;
        cap_length_2 = 0;
        cap_length_3 = 0;
        cap_length_4 = padded_length;
        cap_length_5 = 0;
    }

    action comp_port_1_5()
    {
        cap_length_1 = negated_length + 1;
        cap_length_2 = 0;
        cap_length_3 = 0;
        cap_length_4 = 0;
        cap_length_5 = padded_length;
    }

    action comp_port_2_1()
    {
        cap_length_1 = padded_length;
        cap_length_2 = negated_length + 1;
        cap_length_3 = 0;
        cap_length_4 = 0;
        cap_length_5 = 0;
    }

    action comp_port_2_3()
    {
        cap_length_1 = 0;
        cap_length_2 = negated_length + 1;
        cap_length_3 = padded_length;
        cap_length_4 = 0;
        cap_length_5 = 0;
    }

    action comp_port_2_4()
    {
        cap_length_1 = 0;
        cap_length_2 = negated_length + 1;
        cap_length_3 = 0;
        cap_length_4 = padded_length;
        cap_length_5 = 0;
    }

    action comp_port_2_5()
    {
        cap_length_1 = 0;
        cap_length_2 = negated_length + 1;
        cap_length_3 = 0;
        cap_length_4 = 0;
        cap_length_5 = padded_length;
    }

    action comp_port_3_1()
    {
        cap_length_1 = padded_length;
        cap_length_2 = 0;
        cap_length_3 = negated_length + 1;
        cap_length_4 = 0;
        cap_length_5 = 0;
    }

    action comp_port_3_2()
    {
        cap_length_1 = 0;
        cap_length_2 = padded_length;
        cap_length_3 = negated_length + 1;
        cap_length_4 = 0;
        cap_length_5 = 0;
    }

    action comp_port_3_4()
    {
        cap_length_1 = 0;
        cap_length_2 = 0;
        cap_length_3 = negated_length + 1;
        cap_length_4 = padded_length;
        cap_length_5 = 0;
    }

    action comp_port_3_5()
    {
        cap_length_1 = 0;
        cap_length_2 = 0;
        cap_length_3 = negated_length + 1;
        cap_length_4 = 0;
        cap_length_5 = padded_length;
    }

    action comp_port_4_1()
    {
        cap_length_1 = padded_length;
        cap_length_2 = 0;
        cap_length_3 = 0;
        cap_length_4 = negated_length + 1;
        cap_length_5 = 0;
    }

    action comp_port_4_2()
    {
        cap_length_1 = 0;
        cap_length_2 = padded_length;
        cap_length_3 = 0;
        cap_length_4 = negated_length + 1;
        cap_length_5 = 0;
    }

    action comp_port_4_3()
    {
        cap_length_1 = 0;
        cap_length_2 = 0;
        cap_length_3 = padded_length;
        cap_length_4 = negated_length + 1;
        cap_length_5 = 0;
    }

    action comp_port_4_5()
    {
        cap_length_1 = 0;
        cap_length_2 = 0;
        cap_length_3 = 0;
        cap_length_4 = negated_length + 1;
        cap_length_5 = padded_length;
    }

    action comp_port_5_1()
    {
        cap_length_1 = padded_length;
        cap_length_2 = 0;
        cap_length_3 = 0;
        cap_length_4 = 0;
        cap_length_5 = negated_length + 1;
    }

    action comp_port_5_2()
    {
        cap_length_1 = 0;
        cap_length_2 = padded_length;
        cap_length_3 = 0;
        cap_length_4 = 0;
        cap_length_5 = negated_length + 1;
    }

    action comp_port_5_3()
    {
        cap_length_1 = 0;
        cap_length_2 = 0;
        cap_length_3 = padded_length;
        cap_length_4 = 0;
        cap_length_5 = negated_length + 1;
    }

    action comp_port_5_4()
    {
        cap_length_1 = 0;
        cap_length_2 = 0;
        cap_length_3 = 0;
        cap_length_4 = padded_length;
        cap_length_5 = negated_length + 1;
    }

    table LengthLookupTbl {
        key = {
            pkt_type     : exact;
            capture_port : ternary;
        }
        actions = {
            capture_port_1;
            capture_port_2;
            capture_port_3;
            capture_port_4;
            capture_port_5;
            comp_port_1_2();
            comp_port_1_3();
            comp_port_1_4();
            comp_port_1_5();
            comp_port_2_1();
            comp_port_2_3();
            comp_port_2_4();
            comp_port_2_5();
            comp_port_3_1();
            comp_port_3_2();
            comp_port_3_4();
            comp_port_3_5();
            comp_port_4_1();
            comp_port_4_2();
            comp_port_4_3();
            comp_port_4_5();
            comp_port_5_1();
            comp_port_5_2();
            comp_port_5_3();
            comp_port_5_4();
            NoAction;
        }
         const entries = {
            (PKT_TYPE_CAPTURE, 0 &&& 8w0x7): capture_port_1;
            (PKT_TYPE_CAPTURE, 1 &&& 8w0x7): capture_port_2;
            (PKT_TYPE_CAPTURE, 2 &&& 8w0x7): capture_port_3;
            (PKT_TYPE_CAPTURE, 3 &&& 8w0x7): capture_port_4;
            (PKT_TYPE_CAPTURE, 4 &&& 8w0x7): capture_port_5;
            (PKT_TYPE_CAPTURE_FINAL, 0x4): comp_port_1_5;
            (PKT_TYPE_CAPTURE_FINAL, 0x3): comp_port_1_4;
            (PKT_TYPE_CAPTURE_FINAL, 0x2): comp_port_1_3;
            (PKT_TYPE_CAPTURE_FINAL, 0x1): comp_port_1_2;
            (PKT_TYPE_CAPTURE_FINAL, 0x14): comp_port_2_5;
            (PKT_TYPE_CAPTURE_FINAL, 0x13): comp_port_2_4;
            (PKT_TYPE_CAPTURE_FINAL, 0x12): comp_port_2_3;
            (PKT_TYPE_CAPTURE_FINAL, 0x10): comp_port_2_1;
            (PKT_TYPE_CAPTURE_FINAL, 0x24): comp_port_3_5;
            (PKT_TYPE_CAPTURE_FINAL, 0x23): comp_port_3_4;
            (PKT_TYPE_CAPTURE_FINAL, 0x21): comp_port_3_2;
            (PKT_TYPE_CAPTURE_FINAL, 0x20): comp_port_3_1;
            (PKT_TYPE_CAPTURE_FINAL, 0x34): comp_port_4_5;
            (PKT_TYPE_CAPTURE_FINAL, 0x32): comp_port_4_3;
            (PKT_TYPE_CAPTURE_FINAL, 0x31): comp_port_4_2;
            (PKT_TYPE_CAPTURE_FINAL, 0x30): comp_port_4_1;
            (PKT_TYPE_CAPTURE_FINAL, 0x43): comp_port_5_4;
            (PKT_TYPE_CAPTURE_FINAL, 0x42): comp_port_5_3;
            (PKT_TYPE_CAPTURE_FINAL, 0x41): comp_port_5_2;
            (PKT_TYPE_CAPTURE_FINAL, 0x40): comp_port_5_1;
      }

        size = 32;
    }

    action map_last_2()
    {
        rich_register[7:4] = (bit<4>)(capture_port);
        rich_register[3:0] = (bit<4>)(reg2);
    }

    action map_last_4()
    {
        rich_register[7:4] = (bit<4>)(capture_port);
        rich_register[3:0] = (bit<4>)(4w4);
    }

    action partial_length()
    {
        portion = full_length>>2;
    }

    /*******************************************************/
    apply {
        partial_length();
        captureLookupTbl.apply();
        negate_pad();
        LengthLookupTbl.apply();
        //if ( pkt_type == PKT_TYPE_CAPTURE_FINAL)
        //{
            debt0 = increase_reg0.execute(0);
            debt1 = increase_reg1.execute(0);
            debt2 = increase_reg2.execute(0);
            debt3 = increase_reg3.execute(0);
            debt4 = increase_reg4.execute(0);
        //}
            if (debt1 == debt0)
            {
                reg0 = 8w0;
            }
            else
            {
                reg0 = 8w1;
            }

            if (debt2 == debt1)
            {
            	reg1 = reg0;
            }
            else
            {
                reg1 = 8w2;
            }

            if (debt3 == debt2 )
            {
                reg2 = reg1;
            }
            else
            {
                reg2 = 8w3;
            }

            //if (pkt_type == PKT_TYPE_CAPTURE)
            if (debt4 == debt3)
            {
                map_last_2();
                //new_rich = reg2;
                //rich_register = store_last_reg2.execute(0);
            }
            else
            {
                map_last_4();
                //new_rich = 8w4;
                //rich_register = store_last_reg4.execute(0);
            }

            //map_last();
    }
}


control Ingress(
    /* User */
    inout my_ingress_headers_t                       hdr,
    inout my_ingress_metadata_t                      meta,
    /* Intrinsic */
    in    ingress_intrinsic_metadata_t               ig_intr_md,
    in    ingress_intrinsic_metadata_from_parser_t   ig_prsr_md,
    inout ingress_intrinsic_metadata_for_deparser_t  ig_dprsr_md,
    inout ingress_intrinsic_metadata_for_tm_t        ig_tm_md)
{
    bit<8> capture_port;
    Hash<bit<32>>(HashAlgorithm_t.IDENTITY) identityHash32;
    bit<16> seq_no;

    action setEgPort(PortId_t egress_port)
    {
        ig_tm_md.ucast_egress_port = egress_port;
    }

    table setEgPortTbl{
        key = {
            ig_intr_md.ingress_port : exact;
        }
        actions = {
            setEgPort;
            NoAction;
        }
        default_action = NoAction;
        size = 8;
    }

    action set_mirror_session_capture(MirrorId_t mirror_session) {
        ig_dprsr_md.mirror_type = MIRROR_TYPE_I2E;
        ig_tm_md.mcast_grp_a = 0;
        meta.mirror_session = mirror_session;
        meta.pkt_type = PKT_TYPE_CAPTURE;
        meta.mac_timestamp = identityHash32.get(ig_intr_md.ingress_mac_tstamp);
    }

    table ingressMirrorTbl {
        key = {
          ig_intr_md.ingress_port : exact;
        }
        actions = {
          set_mirror_session_capture;
          NoAction;
        }
        default_action = NoAction;
        size = 1;
    }

    Register<bit<16>, bit<2>>(size=1, initial_value=0) sequence_no;
    RegisterAction<bit<16>, bit<2>, bit<16>>(sequence_no)
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
    action insert_seq_no( bit<24> calculated_ov)
    {
        hdr.capture.seq_no = calculated_ov;
    }

    table insertOverheadTbl {
    key = {
        seq_no : exact;
    }
    actions = {
        insert_seq_no;
    }
      size = 2048;
    }

    action setCaptureEgPort(PortId_t egress_port)
    {
        ig_tm_md.ucast_egress_port = egress_port;
    }

    table setCaptureTbl {
        key = {
            capture_port : ternary;
        }
        actions = {
            setCaptureEgPort;
            NoAction;
        }
        default_action = NoAction;
        size = 8;
    }

    action lookupCapturePort()
    {
         capture_port = hdr.capture.reserved;
    }


    /*********************  D E P A R S E R  ************************/

    apply {
         if (hdr.capture.isValid())
         {
             if (meta.pkt_type == PKT_TYPE_CAPTURE)
            {
                lookupCapturePort();
                seq_no = update_seq_no.execute(0);
                insertOverheadTbl.apply();
                setCaptureTbl.apply();
            }
            else
                ig_dprsr_md.drop_ctl = 1;
         }
        else
            setEgPortTbl.apply();
        ingressMirrorTbl.apply();
    }
}

    /*********************  D E P A R S E R  ************************/

control IngressDeparser(packet_out pkt,
    /* User */
    inout my_ingress_headers_t                       hdr,
    in    my_ingress_metadata_t                      meta,
    /* Intrinsic */
    in    ingress_intrinsic_metadata_for_deparser_t  ig_dprsr_md)
{
    Mirror() mirror;
    apply {
        if (ig_dprsr_md.mirror_type == MIRROR_TYPE_I2E) {
            mirror.emit<mirror_h>(meta.mirror_session, {meta.pkt_type, meta.mac_timestamp});
        }
        pkt.emit(hdr);
    }
}


/*************************************************************************
 ****************  E G R E S S   P R O C E S S I N G   *******************
 ***********/
parser EgressParser(packet_in        pkt,
    /* User */
    out my_egress_headers_t          hdr,
    out my_egress_metadata_t         meta,
    /* Intrinsic */
    out egress_intrinsic_metadata_t  eg_intr_md)
{
    /* This is a mandatory state, required by Tofino Architecture */
    state start {
        pkt.extract(eg_intr_md);
        mirror_h mirror_md = pkt.lookahead<mirror_h>();
        transition select(mirror_md.pkt_type) {
            PKT_TYPE_MIRROR : parse_mirror;
            PKT_TYPE_NORMAL : parse_bridge;
            PKT_TYPE_CAPTURE: parse_capture;
            PKT_TYPE_CAPTURE_FINAL : parse_capture_final;
        default : accept;
        }
    }

    state parse_capture {
        pkt.extract(meta.ing_port_mirror);
        hdr.capture.setValid();
        meta.pkt_type = PKT_TYPE_CAPTURE;
        transition accept;
    }

    state parse_capture_final {
        pkt.extract(meta.bridge);
        pkt.extract(hdr.capture);
        meta.pkt_type = PKT_TYPE_CAPTURE_FINAL;
        transition accept;
    }

    state parse_mirror {
        pkt.extract(meta.ing_port_mirror);
        pkt.extract(hdr.ethernet);
        meta.pkt_type = PKT_TYPE_NORMAL;
        transition select(hdr.ethernet.ether_type) {
            ETHERTYPE_TPID:  parse_vlan_tag;
            ETHERTYPE_IPV4:  parse_ipv4;
            default: accept;
        }
    }

    state parse_bridge {
        pkt.extract(meta.bridge);
        meta.pkt_type = PKT_TYPE_NORMAL;
        meta.ing_port_mirror.pkt_type = PKT_TYPE_NORMAL;
        meta.ing_port_mirror.mac_timestamp = 0;
        meta.pkt_type = PKT_TYPE_NORMAL;
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type) {
            ETHERTYPE_TPID:  parse_vlan_tag;
            ETHERTYPE_IPV4:  parse_ipv4;
            default: accept;
        }
    }

    state parse_vlan_tag {
        pkt.extract(hdr.vlan_tag);
        transition select(hdr.vlan_tag.ether_type) {
            ETHERTYPE_IPV4:  parse_ipv4;
            default: accept;
        }
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        transition select(hdr.ipv4.protocol) {
            IP_PROTOCOLS_TCP: parseTcp;
            IP_PROTOCOLS_UDP: parseUdp;
            default: parseL23;
      }
    }

    state parseTcp {
      pkt.extract(hdr.tcp);
      pkt.extract(hdr.first_payload);
      transition accept;
    }

    state parseUdp {
      pkt.extract(hdr.udp);
      pkt.extract(hdr.first_payload);
      transition accept;
    }

    state parseL23 {
      pkt.extract(hdr.first_payload);
      transition accept;
    }
}

    /***************** M A T C H - A C T I O N  *********************/

control Egress(
    /* User */
    inout my_egress_headers_t                          hdr,
    inout my_egress_metadata_t                         meta,
    /* Intrinsic */
    in    egress_intrinsic_metadata_t                  eg_intr_md,
    in    egress_intrinsic_metadata_from_parser_t      eg_prsr_md,
    inout egress_intrinsic_metadata_for_deparser_t     eg_dprsr_md,
    inout egress_intrinsic_metadata_for_output_port_t  eg_oport_md)
{
    bit<8> rich_register = 0;
    bit<8> capture_port;
    bit<16> padded_length = 0;
    Hash<bit<32>>(HashAlgorithm_t.IDENTITY) identityHash32;
    action set_mirror_session_capture(MirrorId_t mirror_session) {
        eg_dprsr_md.mirror_type = MIRROR_TYPE_E2E;
        meta.mirror_session = mirror_session;
        meta.pkt_type = PKT_TYPE_CAPTURE;
        meta.ing_port_mirror.mac_timestamp = eg_prsr_md.global_tstamp[31:0];
#if __TARGET_TOFINO__ != 1
        eg_dprsr_md.mirror_io_select = 1; // E2E mirroring for Tofino2 & future ASICs
#endif
    }

    table egressCaptureTbl {
    key = {
      eg_intr_md.egress_port : exact;
    }
    actions = {
      set_mirror_session_capture;
      NoAction;
    }
        default_action = NoAction;
        size = 64;
    }


    action insert_capture()
    {
        hdr.capture.reserved = rich_register;
        hdr.capture.timestamp = meta.ing_port_mirror.mac_timestamp;
    }

    /******************************************************************/
    apply
    {
        if (hdr.capture.isValid())
        {
            update_register.apply(eg_intr_md.pkt_length, hdr.capture.reserved,
                eg_intr_md.egress_port, meta.pkt_type, rich_register);
        }
        if (meta.ing_port_mirror.pkt_type == PKT_TYPE_CAPTURE)
            insert_capture();
        egressCaptureTbl.apply();
    }
}

    /*********************  D E P A R S E R  ************************/

control EgressDeparser(packet_out pkt,
    /* User */
    inout my_egress_headers_t                       hdr,
    in    my_egress_metadata_t                      meta,
    /* Intrinsic */
    in    egress_intrinsic_metadata_for_deparser_t  eg_dprsr_md)
{
    Mirror() mirror;
    apply {
        if (eg_dprsr_md.mirror_type == MIRROR_TYPE_E2E) {
            mirror.emit<mirror_h>(meta.mirror_session, {meta.pkt_type, meta.ing_port_mirror.mac_timestamp});
        }
        pkt.emit(hdr);
    }
}


/************ F I N A L   P A C K A G E ******************************/
Pipeline(
    IngressParser(),
    Ingress(),
    IngressDeparser(),
    EgressParser(),
    Egress(),
    EgressDeparser()
) pipe;

Switch(pipe) main;
