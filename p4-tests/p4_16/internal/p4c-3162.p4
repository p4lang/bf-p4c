/* -*- P4_16 -*- */

#include <core.p4>
#include <tna.p4>

/*************************************************************************
 ************* C O N S T A N T S    A N D   T Y P E S  *******************
**************************************************************************/
const bit<16> ETHERTYPE_8100 = 0x8100;
const bit<16> ETHERTYPE_88A8 = 0x88a8;
const bit<16> ETHERTYPE_9100 = 0x9100;
const bit<16> ETHERTYPE_9200 = 0x9200;

const bit<16> STRIP_OUTER_VLAN  = 0x0001;
const bit<16> STRIP_DOUBLE_VLAN = 0x0002;
const bit<16> ADD_OUTER_VLAN    = 0x0004;
const bit<16> ADD_DOUBLE_VLAN   = 0x0008;
const bit<16> TRANS_OUTER_VLAN  = 0x0001;
const bit<16> TRANS_DOUBLE_VLAN = 0x0002;
const bit<16> MATCH_OUTER_VLAN  = 0x0001;
const bit<16> MATCH_DOUBLE_VLAN = 0x0002;
const bit<16> MATCH_ANY_VLAN    = 0x0003;
const bit<16> MATCHED_VLAN      = 0x0004;
const bit<16> VLAN_MASK         = 0xFFF;

const int CPU_PORT = 64;

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

header port_config_h {
    bit<1> single_strip;
    bit<1> double_strip;
    bit<1> single_add;
    bit<1> double_add;
    bit<12> new_inner_vid;
    bit<1>  outer_translate;
    bit<1>  inner_translate;
    bit<1>  l2gre_stripping;
    bit<1>  vxlan_stripping;
    bit<12> new_outer_vid;
    bit<4>  reserved;
    bit<12> match_outer_vlan;
    bit<4>  reserved1;
    bit<12> match_inner_vlan;
}

/*************************************************************************
 **************  I N G R E S S   P R O C E S S I N G   *******************
 *************************************************************************/
 
    /***********************  H E A D E R S  ************************/

struct my_ingress_headers_t {
    ethernet_h   ethernet;
    vlan_tag_h[2]   vlan_tag;
}

    /******  G L O B A L   I N G R E S S   M E T A D A T A  *********/

struct my_ingress_metadata_t {
    /*
     * bit 1 - strip single VLAN
     * bit 2 - strip double VLAN
     * bit 3 - Add single VLAN
     * bit 4 - Add double VLAN
     * bits 5 - 16 - New Outer VLAN */
    bit<16> mod_vlan;
    
    /*
     * bit 1 - translate single VLAN
     * bit 2 - translate double VLAN
     * bit 3 - Reserved
     * bit 4 - Reserved
     * bits 5 - 16 - New Inner VLAN */
    bit<16> trans_vlan;
    
    /*
     * bit 1 - match single VLAN
     * bit 2 - match double VLAN
     * bit 3 - VLAN Match bit
     * bit 4 - Add double VLAN
     * bits 5 - 16 - Match Outer VLAN */
    bit<16> match_vlan;
    /*
     * bit 1 - 4 Reserved
     * bits 5 - 16 - Match Inner VLAN */
    bit<16> match_vlan1;

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
        /* These are OK  */
        meta.mod_vlan = 0;
        meta.trans_vlan = 0;
        meta.match_vlan = 0;
        meta.match_vlan1 = 0;

        pkt.extract(ig_intr_md);
        pkt.advance(PORT_METADATA_SIZE);
        transition parse_ethernet;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type) {
            ETHERTYPE_8100: parse_vlan_tag;
            ETHERTYPE_88A8: parse_vlan_tag;
            ETHERTYPE_9100: parse_vlan_tag;
            ETHERTYPE_9200: parse_vlan_tag;
            default:accept;
        }
    }

    state parse_vlan_tag {
        pkt.extract(hdr.vlan_tag.next);
        transition select(hdr.vlan_tag.last.ether_type) {
            ETHERTYPE_8100: parse_vlan_tag;
            ETHERTYPE_88A8: parse_vlan_tag;
            ETHERTYPE_9100: parse_vlan_tag;
            ETHERTYPE_9200: parse_vlan_tag;
            default:accept;
        }
    }

    /* These are no OK */
 //   meta.mod_vlan = 0;
 //   meta.trans_vlan = 0;
 //   meta.match_vlan = 0;
 //   meta.match_vlan1 = 0;
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
    
    action read_config(PortId_t port, bit<16> mod_vlan, bit<16> trans_vlan, bit<16> match_vlan, bit<16> match_vlan1) {
        meta.mod_vlan = mod_vlan;
        meta.trans_vlan = trans_vlan;
        meta.match_vlan = match_vlan;
        meta.match_vlan1 = match_vlan1;
        send(port);
    }


    table port_config {
        key = { ig_intr_md.ingress_port : exact; }

        actions = {
           send;drop;read_config;
        }

        default_action = send(CPU_PORT);
        size           = 256;
    }
    
            apply {
        if (port_config.apply().hit) {
                    /* These are OK ?? Yep */
        if ((meta.match_vlan & MATCH_OUTER_VLAN) != 0 && hdr.vlan_tag[0].isValid()) {
            bit<12> tmp = meta.match_vlan[15:4];
            if (tmp == hdr.vlan_tag[0].vid) {
                meta.match_vlan =  meta.match_vlan | MATCHED_VLAN;
            }
        }
        
        if ((meta.match_vlan & MATCH_DOUBLE_VLAN) != 0 && hdr.vlan_tag[1].isValid() && hdr.vlan_tag[0].isValid()) {
            bit<12> tmp = meta.match_vlan[15:4];
            bit<12> inner = meta.match_vlan1[15:4];
            if (tmp == hdr.vlan_tag[0].vid && inner == hdr.vlan_tag[1].vid) {
                meta.match_vlan =  meta.match_vlan | MATCHED_VLAN;
            }
        }

        if ((meta.match_vlan & MATCH_ANY_VLAN) == 0){
            meta.match_vlan =  meta.match_vlan | MATCHED_VLAN;
        }

                    if ((meta.match_vlan & MATCHED_VLAN) != 0) {
                        if ((meta.trans_vlan & TRANS_OUTER_VLAN) != 0 && hdr.vlan_tag[0].isValid()) {
                            hdr.vlan_tag[0].vid = meta.mod_vlan[15:4];
                        }

                        if ((meta.trans_vlan & TRANS_DOUBLE_VLAN) != 0 && hdr.vlan_tag[1].isValid() && hdr.vlan_tag[0].isValid()) {
                                hdr.vlan_tag[0].vid = meta.mod_vlan[15:4];
                                hdr.vlan_tag[1].vid = meta.trans_vlan[15:4];
                            }

                            if ((meta.mod_vlan & STRIP_OUTER_VLAN) != 0) {
                                if (hdr.vlan_tag[0].isValid()) {
                                    hdr.ethernet.ether_type = hdr.vlan_tag[0].ether_type;
                                    hdr.vlan_tag[0].setInvalid();
                                }
                            }
                            if ((meta.mod_vlan & STRIP_DOUBLE_VLAN) != 0) {
                                if (hdr.vlan_tag[1].isValid()) {
                                    hdr.ethernet.ether_type = hdr.vlan_tag[1].ether_type;
                                } else if (hdr.vlan_tag[0].isValid()) {
                                    hdr.ethernet.ether_type = hdr.vlan_tag[0].ether_type;
                                }
                                hdr.vlan_tag[0].setInvalid();
                                hdr.vlan_tag[1].setInvalid();
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
