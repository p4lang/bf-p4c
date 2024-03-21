/* -*- P4_16 -*- */

#include <core.p4>
#include <t2na.p4>

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
typedef bit<8>  pkt_type_t;
const pkt_type_t PKT_TYPE_NORMAL  = 1;
const pkt_type_t PKT_TYPE_MIRROR  = 2;
const pkt_type_t PKT_TYPE_CAPTURE = 3;

typedef bit<4> port_type_t;
const port_type_t L23_PORT = 2;
const port_type_t L47_PORT = 3;
const port_type_t CAPTURE_PORT = 4;
const port_type_t RESUBMIT_PORT = 5;
const port_type_t FRONTPANEL_PORT = 1;
#if __TARGET_TOFINO__ == 1
typedef bit<3> mirror_type_t;
#else
typedef bit<4> mirror_type_t;
#endif
const mirror_type_t MIRROR_TYPE_I2E = 1;
const mirror_type_t MIRROR_TYPE_E2E = 2;
typedef bit<5> capture_index_t;
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
    bit<16> pkt_length;
    bit<16> seq_no;
    bit<32> timestamp;
}

//@flexible 
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
    bit<8> ingress_port;
}

struct my_ingress_headers_t {
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
    MirrorId_t  mirror_session;
    bit<32>  mac_timestamp;
    pkt_type_t pkt_type;
}

struct my_egress_headers_t {
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
        transition select(meta.port_properties.port_type)
        {
            CAPTURE_PORT : accept; // no parsing for capture ports 
            RESUBMIT_PORT: parse_capture;
            default: parse_ethernet;
        }
    }

    state parse_capture {
        pkt.extract(hdr.capture);
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
    Hash<bit<32>>(HashAlgorithm_t.IDENTITY) identityHash32;
    bit<2> capture_group;
    bit<8> capture_port;
    bit<8> rich_register;
    bit<32> deb_register;
    bit<1> update;
    bit<16> seq_no;
    bit<32> capture_pkt_length;

    action map_pkt_length()
    {
        capture_pkt_length[15:0] = hdr.capture.pkt_length;
    }
    
    Register<bit<16>, bit<2>>(size=4, initial_value=0) sequence_no;
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

    Register<bit<32>, capture_index_t>(size=32, initial_value=0) store_debt_reg;
    RegisterAction<bit<32>, capture_index_t, bit<32>>(store_debt_reg)
    increment_debt_reg = {
        void apply(inout bit<32> register_data)
        {
            register_data = register_data + capture_pkt_length;
        }
    };

    RegisterAction<bit<32>, capture_index_t, bit<32>>(store_debt_reg)
    decrement_debt_reg = {
        void apply(inout bit<32> register_data, out bit<32> result)
        {
            // fixed 84 bytes per packet
            if (register_data < 84)
                register_data = 0;
            else
                register_data = register_data - 84;
            result = register_data;
        }
    };

    Register<bit<32>, bit<2>>(size=4, initial_value=0xffff) store_min_reg;
    RegisterAction<bit<32>, bit<2>, bit<1>>(store_min_reg)
    compare_min_reg = {
        void apply(inout bit<32> register_data, out bit<1> update)
        {
            if (register_data > deb_register)
            {
                register_data = deb_register;
                update = 1;
            }   
            else
            {
                update = 0;
            }
        }
    };
   
    //final link that is the riches for this group
    Register<bit<8>, bit<8>>(size=4, initial_value=0) store_rich_reg;
    RegisterAction<bit<8>, bit<2>, bit<8>>(store_rich_reg)
    read_rich_reg = {
      void apply(inout bit<8> register_data, out bit<8> result)
      {
         result = register_data;
      }
    }; 

   RegisterAction<bit<8>, bit<2>, bit<8>>(store_rich_reg)
    write_rich_reg = {
       void apply(inout bit<8> register_data) {
          register_data = rich_register;
       }
   };

    action set_mirror_session_l47(MirrorId_t mirror_session, bit<3> l47_port) {
        ig_dprsr_md.mirror_type = MIRROR_TYPE_I2E;
        ig_tm_md.mcast_grp_a = 0;
        meta.mirror_session = mirror_session;
        meta.pkt_type = PKT_TYPE_MIRROR;
        meta.mac_timestamp[3:1] = l47_port;
        meta.mac_timestamp[0:0] = 0;
        //drop parser error packet
        ig_dprsr_md.drop_ctl = 1;
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
      ig_prsr_md.parser_err :ternary;
    }
    actions = {
      set_mirror_session_l47;
      set_mirror_session_capture;
      NoAction;
    }
        default_action = NoAction;
        size = 64;
    }
    
    action lookupGroupIndex(bit<2> group_no, bit<5> stat_index)
    {   
        capture_port[4:0] = stat_index;
        capture_group = group_no;
    }

    table captureLookupTbl {
    key = {
      ig_intr_md.ingress_port : exact;
    }
    actions = {
      lookupGroupIndex; 
      NoAction;
    }
        default_action = NoAction;
        size = 64;
    }
    action setCaptureEgPort(PortId_t egress_port)
    {
        ig_tm_md.ucast_egress_port = egress_port;
    }

    table setCaptureTbl {
    key = {
      rich_register : exact;
      capture_group : exact;
    }
    actions = {
      setCaptureEgPort; 
      NoAction;
    }
        default_action = NoAction;
        size = 64;
    }

    action set_rich_reg()
    {
        rich_register = capture_port;
    }

    action insert_seq_no( bit<16> seq_no)
    {
        hdr.capture.pkt_length = seq_no;
        hdr.capture.seq_no = seq_no;
    }

    table insert_overheadTbl {
    key = {
      seq_no : exact;
    }
    actions = {
      insert_seq_no; 
    }
        size = 2048;
    }

    apply {
        map_pkt_length();
        ingressMirrorTbl.apply();
        if (hdr.capture.isValid())
        {
            captureLookupTbl.apply();
            if ( meta.port_properties.port_type == RESUBMIT_PORT)
            {
                seq_no = update_seq_no.execute(capture_group);
                rich_register = read_rich_reg.execute(capture_group);
                setCaptureTbl.apply();
                increment_debt_reg.execute(capture_port[4:0]);
                insert_overheadTbl.apply();
            }
            else
            {
                deb_register = decrement_debt_reg.execute(capture_port[4:0]);
                update = compare_min_reg.execute(capture_group);
                if (update == 1)
                {
                    set_rich_reg();
                    write_rich_reg.execute(capture_group);
                }
            }
        }
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
        default : accept;
        }
    }
    
    state parse_capture {
        pkt.extract(meta.ing_port_mirror);
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
        //pkt.extract(meta.bridge);
        pkt.extract(hdr.ethernet);
        meta.pkt_type = PKT_TYPE_NORMAL;
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
    action insert_capture()
    {
        hdr.capture.setValid();
        hdr.capture.pkt_length = eg_intr_md.pkt_length;
        hdr.capture.timestamp = meta.ing_port_mirror.mac_timestamp;
    }

    action set_mirror_session_capture(MirrorId_t mirror_session) {
        eg_dprsr_md.mirror_type = MIRROR_TYPE_E2E;
        meta.mirror_session = mirror_session;
        meta.pkt_type = PKT_TYPE_CAPTURE;
        meta.ing_port_mirror.mac_timestamp = eg_prsr_md.global_tstamp[31:0];
    }

    table captureTbl {
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

    apply
    {
        if (meta.ing_port_mirror.pkt_type == PKT_TYPE_CAPTURE)
        {
            insert_capture();
        }
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
