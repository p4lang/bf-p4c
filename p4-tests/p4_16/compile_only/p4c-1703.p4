/* -*- P4_16 -*- */

#include <core.p4>
#if __TARGET_TOFINO__ == 3
#include <t3na.p4>
#elif __TARGET_TOFINO__ == 2
#include <t2na.p4>
#elif __TARGET_TOFINO__ == 1
#include <tna.p4>
#else
#error Unsupported target
#endif

/*************************************************************************
 ************* C O N S T A N T S    A N D   T Y P E S  *******************
**************************************************************************/
const bit<16> ETHERTYPE_TPID   = 0x8100;
const bit<16> ETHERTYPE_IPV4   = 0x0800;
const bit<16> ETHERTYPE_TO_CPU = 0xBF01;

const int IPV4_HOST_SIZE = 65536;
const int IPV4_LPM_SIZE  = 12288;

/*************************************************************************
 ***********************  H E A D E R S  *********************************
 *************************************************************************/

/*  Define all the headers the program will recognize             */
/*  The actual sets of headers processed by each gress can differ */

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

/* Custom to-cpu header */
header to_cpu_h {
    bit<8>   mirror_type;
    bit<16>  mirror_session;
    bit<16>  ingress_port;
    bit<48>  ingress_mac_tstamp;
    bit<48>  ingress_global_tstamp;
    bit<48>  egress_global_tstamp;
    bit<16>  pkt_length;
}

/*** Internal Headers ***/
enum bit<8> internal_header_t {
    TYPE_MASK           = 0b00000001,
    TYPE_BRIDGE         = 0b00000000,
    TYPE_MIRROR         = 0b00000001,

    MIRROR_TYPE_MASK    = 0b00000110,
    MIRROR_TYPE_INGRESS = 0b00000000,
    MIRROR_TYPE_EGRESS  = 0b00000010,

    MIRROR_INGRESS      = 0b00000001, /* TYPE_MIRROR | INGRESS */
    MIRROR_EGRESS       = 0b00000011  /* MIRROR | EGRESS  */

}

/* Bridged metadata */
@flexible
struct bridge_t {
    PortId_t  ingress_port;  /* We need something here */
}

header bridge_h {
    internal_header_t   header_type;
    bridge_t            data;
}
/* !!!! Adjust every time you change bridge_t or bridge_h */
const bit<16> BRIDGE_HEADER_LEN=3;

/* Ingress mirroring information */
@flexible
struct ingress_mirror_t {
    PortId_t      ingress_port;
    MirrorId_t    mirror_session;
    bit<48>       ingress_mac_tstamp;
    bit<48>       ingress_global_tstamp;
}

header ingress_mirror_h {
    internal_header_t   header_type;
    ingress_mirror_t    data;
}
/* !!!! Adjust every time you change ingress_mirror_t or _h */
const bit<16> MIRROR_HEADER_LEN=17;


/*************************************************************************
 **************  I N G R E S S   P R O C E S S I N G   *******************
 *************************************************************************/

    /***********************  H E A D E R S  ************************/

struct my_ingress_headers_t {
    bridge_h     bridge;
    ethernet_h   ethernet;
    vlan_tag_h   vlan_tag;
    ipv4_h       ipv4;
}

    /******  G L O B A L   I N G R E S S   M E T A D A T A  *********/

struct my_ingress_metadata_t {
    bit<1>           do_mirror;
    ingress_mirror_h ing_mirror;
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
        transition init_meta;
    }

    state init_meta {
        meta.do_mirror = 0;
        meta.ing_mirror.setInvalid();

        hdr.bridge.setValid();
        hdr.bridge.header_type = internal_header_t.TYPE_BRIDGE;

        transition parse_ethernet;
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

    table ipv4_host {
        key = { hdr.ipv4.dst_addr : exact; }
        actions = {
            send; drop;
            @defaultonly NoAction;
        }
        const default_action = NoAction();
        size = IPV4_HOST_SIZE;
    }

    table ipv4_lpm {
        key     = { hdr.ipv4.dst_addr : lpm; }
        actions = { send; drop; }

        default_action = send(64);
        size           = IPV4_LPM_SIZE;
    }

    action acl_mirror(MirrorId_t mirror_session) {
        meta.do_mirror      = 1;

        meta.ing_mirror.setValid();
        meta.ing_mirror.header_type = internal_header_t.MIRROR_INGRESS;

        meta.ing_mirror.data.ingress_port   = ig_intr_md.ingress_port;
        meta.ing_mirror.data.mirror_session = mirror_session;

        meta.ing_mirror.data.ingress_mac_tstamp    = ig_intr_md.
                                                          ingress_mac_tstamp;
        meta.ing_mirror.data.ingress_global_tstamp = ig_prsr_md.
                                                          global_tstamp;
    }

    action acl_drop_and_mirror(MirrorId_t mirror_session) {
        acl_mirror(mirror_session);
        drop();
    }

    table port_acl {
        key = {
            ig_intr_md.ingress_port : ternary;
        }
        actions = {
            acl_mirror; acl_drop_and_mirror; drop; NoAction;
        }
        size = 512;
        default_action = NoAction();
    }

    apply {
        if (ig_prsr_md.parser_err == 0) {
            if (hdr.ipv4.isValid()) {
                if (!ipv4_host.apply().hit) {
                    ipv4_lpm.apply();
                }
            }
        }
        port_acl.apply();
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
    Mirror() ing_port_mirror;

    apply {
        /*
         * If there is a mirror request, create a clone.
         * Note: Mirror() externs emits the provided header, but also
         * appends the ORIGINAL ingress packet after those
         */
        if (meta.do_mirror == 1) {
            ing_port_mirror.emit(
                meta.ing_mirror.data.mirror_session,
                meta.ing_mirror);
        }

        /* Deparse the regular packet with bridge metadata header prepended */
        pkt.emit(hdr);
    }
}


/*************************************************************************
 ****************  E G R E S S   P R O C E S S I N G   *******************
 *************************************************************************/

    /***********************  H E A D E R S  ************************/

struct my_egress_headers_t {
    ethernet_h   cpu_ethernet;
    to_cpu_h     to_cpu;
    ethernet_h   ethernet;
    vlan_tag_h   vlan_tag;
    ipv4_h       ipv4;
}

    /********  G L O B A L   E G R E S S   M E T A D A T A  *********/

struct my_egress_metadata_t {
    internal_header_t packet_type;
    bridge_h          bridge;
    ingress_mirror_h  ing_mirror;
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
        meta.packet_type = pkt.lookahead<internal_header_t>();
        transition select(meta.packet_type) {
            internal_header_t.TYPE_BRIDGE    : parse_bridge;
            internal_header_t.MIRROR_INGRESS : parse_ingress_mirror;
            default : reject;
        }
    }

    state parse_bridge {
        pkt.extract(meta.bridge);
        transition parse_ethernet;
    }

    state parse_ingress_mirror {
        pkt.extract(meta.ing_mirror);
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
    action just_send() {}

    action send_to_cpu() {
        hdr.cpu_ethernet.setValid();
        hdr.cpu_ethernet.dst_addr   = 0xFFFFFFFFFFFF;
        hdr.cpu_ethernet.src_addr   = 0xAAAAAAAAAAAA;
        hdr.cpu_ethernet.ether_type = ETHERTYPE_TO_CPU;

        hdr.to_cpu.setValid();
        hdr.to_cpu.mirror_type     = (bit<8>)meta.packet_type;
        hdr.to_cpu.mirror_session  = (bit<16>)meta.ing_mirror.data.mirror_session;
        hdr.to_cpu.ingress_port    = (bit<16>)meta.ing_mirror.data.ingress_port;
        /* Needs adjustment */
        hdr.to_cpu.pkt_length      = eg_intr_md.pkt_length -
                                     (bit<16>)sizeInBytes(meta.ing_mirror);
        /* Timestamps */
        hdr.to_cpu.ingress_mac_tstamp    = meta.ing_mirror.data.
                                                    ingress_mac_tstamp;
        hdr.to_cpu.ingress_global_tstamp = meta.ing_mirror.data.
                                                    ingress_global_tstamp;
        hdr.to_cpu.egress_global_tstamp  = eg_prsr_md.global_tstamp;
    }

    table mirror_dest {
        key = {
            meta.ing_mirror.data.mirror_session : exact;
        }

        actions = {
            just_send;
            send_to_cpu;
        }
        default_action = just_send();
    }

    apply {
        if ((bit<8>)meta.packet_type & (bit<8>)internal_header_t.TYPE_MIRROR != 0) {
            mirror_dest.apply();
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
