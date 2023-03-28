/* -*- P4_16 -*- */

#include <core.p4>
#include <tna.p4>

const bit<16> ETHERTYPE_IPV4 = 16w0x0800;

/* Standard ethernet header */
header ethernet_h {
    bit<48>   dst_addr;
    bit<48>   src_addr;
    bit<16>   ether_type;
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

struct reg_pair {
    bit<16>     x;
    bit<16>     y;
}


/*************************************************************************
 **************  I N G R E S S   P R O C E S S I N G   *******************
 *************************************************************************/
 
    /***********************  H E A D E R S  ************************/

struct my_ingress_headers_t {
    ethernet_h   ethernet;
    ipv4_h ipv4;
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
            ETHERTYPE_IPV4 : parse_ipv4;
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
    bit<16> curr = 0;
    bit<16> hold0 = 0;
    bit<16> hold1 = 0;

    Register<reg_pair, bit<1>>(1) reg0;
    RegisterAction<reg_pair, bit<1>, bit<16>> (reg0) reg0_update = {
        void apply(inout reg_pair val, out bit<16> rv) {
            if(curr != val.y) { // whenever the timestamp advances by 4.3s, then we reset val.x, then add 1
                val.x = 1;
            } else {
                val.x = val.x |+| 1;
            }
            val.y = curr;
            rv = val.x;
        }
    };

    Register<reg_pair, bit<1>>(1) reg1;
    RegisterAction<reg_pair, bit<1>, bit<16>> (reg1) reg1_update = {
        void apply(inout reg_pair val, out bit<16> rv) {
            if(curr != val.y) { // whenever the timestamp advances by 4.3s, then we reset val.x, then add 1
                val.x = 0;
            } 
            val.x = val.x |+| 1;
            val.y = curr;
            rv = val.x;
        }
    };

    action drop() {
        ig_dprsr_md.drop_ctl = 0x0;    // drop packet
        exit;
    }

    action forward(PortId_t port) {
        hdr.ipv4.ttl = hdr.ipv4.ttl - 1; 
        ig_tm_md.ucast_egress_port = port;
    }

    table ipv4_forward {
        key = {
            hdr.ipv4.dst_addr : exact;
        }
        actions = {
            forward;
            drop;
        }
        default_action = drop();
        size = 32;
    }

    apply {
        curr = (bit<16>) ig_intr_md.ingress_mac_tstamp[47:32];  // Advances every t. t = 2^32/(10**9) = ~4.3s

        if(hdr.ipv4.isValid()) {
            ipv4_forward.apply();

            // reg0 and reg1 are registers of similar specifications.
            // the register actions are supposed to perform the same action; though with slightly different implementation.
            hold0 = reg0_update.execute(0);
            hold1 = reg1_update.execute(0);
            hdr.ethernet.src_addr = (bit<48>) hold0;    // Placeholder
            hdr.ethernet.dst_addr = (bit<48>) hold1;    // Placeholder
        }

        ig_tm_md.bypass_egress = 1;
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
