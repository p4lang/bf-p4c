/* -*- P4_16 -*- */

#include <core.p4>
#include <tna.p4>

/*************************************************************************
 ************* C O N S T A N T S    A N D   T Y P E S  *******************
*************************************************************************/
enum bit<16> ether_type_t {
    TPID       = 0x8100,
    IPV4       = 0x0800
}

enum bit<8>  ip_proto_t {
    ICMP  = 1,
    IGMP  = 2,
    TCP   = 6,
    UDP   = 17
}

type bit<48> mac_addr_t;
type bit<32> ipv4_addr_t;

/*************************************************************************
 ***********************  H E A D E R S  *********************************
 *************************************************************************/
/*  Define all the headers the program will recognize             */
/*  The actual sets of headers processed by each gress can differ */

/* Standard ethernet header */
header ethernet_h {
    mac_addr_t    dst_addr;
    mac_addr_t    src_addr;
    ether_type_t  ether_type;
}

header vlan_tag_h {
    bit<3>        pcp;
    bit<1>        cfi;
    bit<12>       vid;
    ether_type_t  ether_type;
}

header ipv4_h {
    bit<4>       version;
    bit<4>       ihl;
    bit<8>       diffserv;
    bit<16>      total_len;
    bit<16>      identification;
    bit<3>       flags;
    bit<13>      frag_offset;
    bit<8>       ttl;
    ip_proto_t   protocol;
    bit<16>      hdr_checksum;
    ipv4_addr_t  src_addr;
    ipv4_addr_t  dst_addr;
}

header icmp_h {
    bit<16>  type_code;
    bit<16>  checksum;
}

header igmp_h {
    bit<16>  type_code;
    bit<16>  checksum;
}

header tcp_h {
    bit<16>  src_port;
    bit<16>  dst_port;
    bit<32>  seq_no;
    bit<32>  ack_no;
    bit<4>   data_offset;
    bit<4>   res;
    bit<8>   flags;
    bit<16>  window;
    bit<16>  checksum;
    bit<16>  urgent_ptr;
}

header udp_h {
    bit<16>  src_port;
    bit<16>  dst_port;
    bit<16>  len;
    bit<16>  checksum;
}

/*************************************************************************
 **************  I N G R E S S   P R O C E S S I N G   *******************
 *************************************************************************/

    /***********************  H E A D E R S  ************************/

struct my_ingress_headers_t {
    ethernet_h         ethernet;
    vlan_tag_h[2]      vlan_tag;
    ipv4_h             ipv4;
    icmp_h             icmp;
    igmp_h             igmp;
    tcp_h              tcp;
    udp_h              udp;
}

    /******  G L O B A L   I N G R E S S   M E T A D A T A  *********/

struct l4_lookup_t {
    bit<16>  word_1;
    bit<16>  word_2;
}

@not_parsed("pipe", "ingress", "meta.session_id")
struct my_ingress_metadata_t {
    l4_lookup_t   l4_lookup;
    bit<1>        first_frag;
    MirrorId_t    session_id;
    bit<6>        tmp_0;
    PortId_t      egress_port;
    bit<8>        type;
}

header switch_port_mirror_metadata_h {
    bit<16> session_id;
}

header switch_mirror_type_h {
    bit<8> type;
}

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
        pkt.advance(PORT_METADATA_SIZE);
        transition meta_init;
    }

    state meta_init {
        meta.l4_lookup     = { 0, 0 };
        meta.first_frag    = 0;

        transition parse_ethernet;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        /*
         * The explicit cast allows us to use ternary matching on
         * serializable enum
         */
        transition select((bit<16>)hdr.ethernet.ether_type) {
            (bit<16>)ether_type_t.TPID &&& 0xEFFF :  parse_vlan_tag;
            (bit<16>)ether_type_t.IPV4            :  parse_ipv4;
            default :  accept;
        }
    }

    state parse_vlan_tag {
        pkt.extract(hdr.vlan_tag.next);
        transition select(hdr.vlan_tag.last.ether_type) {
            ether_type_t.TPID :  parse_vlan_tag;
            ether_type_t.IPV4 :  parse_ipv4;
            default: accept;
        }
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);

        transition accept;
    }

    state parse_icmp {
        meta.l4_lookup = pkt.lookahead<l4_lookup_t>();
        pkt.extract(hdr.icmp);
        meta.first_frag = 1;
        transition accept;
    }

    state parse_igmp {
        meta.l4_lookup = pkt.lookahead<l4_lookup_t>();
        pkt.extract(hdr.igmp);
        meta.first_frag = 1;
        transition accept;
    }

    state parse_tcp {
        meta.l4_lookup = pkt.lookahead<l4_lookup_t>();
        pkt.extract(hdr.tcp);
        meta.first_frag = 1;
        transition accept;
    }

    state parse_udp {
        meta.l4_lookup = pkt.lookahead<l4_lookup_t>();
        pkt.extract(hdr.udp);
        meta.first_frag = 1;
        transition accept;
    }

    state parse_first_fragment {
        meta.l4_lookup = pkt.lookahead<l4_lookup_t>();
        meta.first_frag = 1;
        transition accept;
    }

    state parse_other_fragments {
        meta.l4_lookup = pkt.lookahead<l4_lookup_t>();
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
    action send(PortId_t port) {
        ig_tm_md.ucast_egress_port = port;
    }

    action drop() {
        ig_dprsr_md.drop_ctl = 1;
    }

    action real_drop() {
        drop();
        exit;
    }

    table ipv4_host {
        key = { hdr.ipv4.dst_addr : exact; }
        actions = {
            send; drop;
            @defaultonly NoAction;
        }
        const default_action = NoAction();
        size = 65536;
    }

    table ipv4_lpm {
        key     = { hdr.ipv4.dst_addr : lpm; }
        actions = { send; drop; }

        default_action = send(64);
        size           = 12288;
    }

    table ipv4_acl {
        key = {
            hdr.ipv4.src_addr     : ternary;
            hdr.ipv4.dst_addr     : ternary;
            hdr.ipv4.protocol     : ternary;
        }
        actions = { NoAction; drop; }
        size    = 2048;
    }

    /* The algorithm */
    apply {
        meta.egress_port = ig_tm_md.ucast_egress_port;
    }
}

header Sagerton {
    bit<8> Exell;
    bit<16> Toccopola;
}

header Cornell {
    bit<8> Foo;
    bit<8> Bar;
}

    /*********************  D E P A R S E R  ************************/

control IngressDeparser(packet_out pkt,
    /* User */
    inout my_ingress_headers_t                       hdr,
    in    my_ingress_metadata_t                      meta,
    /* Intrinsic */
    in    ingress_intrinsic_metadata_for_deparser_t  ig_dprsr_md)
{
    Mirror(0) mirror_0;
    Mirror(1) mirror_1;
    apply {
        mirror_0.emit<Sagerton>(meta.session_id, { (bit<8>)ig_dprsr_md.mirror_type, (bit<16>)meta.egress_port } );
        mirror_1.emit<Cornell>(meta.session_id, { 8w0, 8w0 });
        pkt.emit(hdr);
    }
}


/*************************************************************************
 ****************  E G R E S S   P R O C E S S I N G   *******************
 *************************************************************************/

    /***********************  H E A D E R S  ************************/

struct my_egress_headers_t {
}

    /********  G L O B A L   E G R E S S   M E T A D A T A  *********/

struct my_egress_metadata_t {
}

    /***********************  P A R S E R  **************************/

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
    apply {
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
    apply {
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