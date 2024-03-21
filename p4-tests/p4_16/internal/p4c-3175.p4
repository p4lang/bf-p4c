/* -*- P4_16 -*- */

#include <core.p4>
#include <t2na.p4>  /** TOFINO2_ONLY **/

/*************************************************************************
 ************* C O N S T A N T S    A N D   T Y P E S  *******************
**************************************************************************/
const bit<16> ETHERTYPE_TPID = 0x8100;
const bit<16> ETHERTYPE_IPV4 = 0x0800;

/* Table Sizes */
#define IPV4_HOST_SIZE 4800*1024
#define IPV4_LPM_SIZE 18*12*1024

const int IPV4_HOST_TABLE_SIZE = IPV4_HOST_SIZE;
const int IPV4_LPM_TABLE_SIZE  = IPV4_LPM_SIZE;

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

/*************************************************************************
 **************  I N G R E S S   P R O C E S S I N G   *******************
 *************************************************************************/

    /***********************  H E A D E R S  ************************/

struct my_ingress_headers_t {
    ethernet_h   ethernet;
    vlan_tag_h   vlan_tag;
    ipv4_h       ipv4;
}

    /******  G L O B A L   I N G R E S S   M E T A D A T A  *********/

struct my_ingress_metadata_t {
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
#ifdef CASE_FIX
@pa_solitary("ingress", "host_fwd_table_hit_0")
@pa_solitary("ingress", "host_fwd_ucast_egress_port_0")
@pa_solitary("ingress", "host_fwd_drop_ctl_0")
@pa_solitary("ingress", "lpm_fwd_ucast_egress_port_0")
@pa_solitary("ingress", "lpm_fwd_drop_ctl_0")
#endif

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
    /* Local variables to keep the results */
    bool     host_fwd_table_hit = false;
    PortId_t host_fwd_ucast_egress_port = 0;
    bit<3>   host_fwd_drop_ctl = 0;
    PortId_t lpm_fwd_ucast_egress_port = 0;
    bit<3>   lpm_fwd_drop_ctl = 0;
    
    action host_send(PortId_t port) {
        host_fwd_table_hit = true;
        host_fwd_ucast_egress_port = port;
        host_fwd_drop_ctl = 0;
    }
    
    action host_drop() {
        host_fwd_table_hit = true;
        host_fwd_drop_ctl = 1;
    }
    
    table ipv4_host {
        key = { hdr.ipv4.dst_addr : exact; }
        actions = {host_send; host_drop;
            @defaultonly NoAction;
        }
        const default_action = NoAction();
        size = IPV4_HOST_TABLE_SIZE;
    }

    action lpm_send(PortId_t port) {
        lpm_fwd_ucast_egress_port = port;
        lpm_fwd_drop_ctl = 0;
    }
    
    action lpm_drop() {
        lpm_fwd_drop_ctl = 1;
    }
    
    table ipv4_lpm {
        key     = { hdr.ipv4.dst_addr : lpm; }
        actions = { lpm_send; lpm_drop; }
        default_action = lpm_send(64);
        size           = IPV4_LPM_TABLE_SIZE;
    }

    /* Forwarding resolution action */
    action use_host() {
        ig_tm_md.ucast_egress_port = host_fwd_ucast_egress_port;
        ig_dprsr_md.drop_ctl = host_fwd_drop_ctl;
    }
    
    action use_lpm() {
        ig_tm_md.ucast_egress_port = lpm_fwd_ucast_egress_port;
        ig_dprsr_md.drop_ctl = lpm_fwd_drop_ctl;
    }

    action set_id(bit<16> new_id) {
        hdr.ipv4.identification = new_id;
    }

    table ipv4_rewrite_id {
        key = { hdr.ipv4.identification : exact; }
	actions = {set_id;
            @defaultonly NoAction;
        }
        const default_action = NoAction();
        size = 65536;
    }
    
    apply {
        if (hdr.ipv4.isValid()) {
            /* Prepare the metadata using both tables */
            ipv4_host.apply();
            ipv4_lpm.apply();
            
            if (host_fwd_table_hit) {
                use_host();
            } else {
                use_lpm();
            }
	    ipv4_rewrite_id.apply();
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
    apply {
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
