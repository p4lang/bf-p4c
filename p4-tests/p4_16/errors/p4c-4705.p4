/* -*- P4_16 -*- */
#include <core.p4>
#include <tna.p4>

const int CPU_PORT = 64;

#define N_SN_BITS 8
#define IPV4_OPT_LEN 4
#define IHL 6
#define N_VCONN_ID_BITS 8
#define MAX_VCONNS 256

const bit<16> ETHERTYPE_IPV4 = 0x800;
const bit<5>  IPV4_OPT_VCONN = 31;


typedef bit<48> macAddr_t;
header ethernet_h {
    macAddr_t   dst_addr;
    macAddr_t   src_addr;
    bit<16>     ether_type;
}

typedef bit<32> ip4Addr_t;
header ipv4_h {
    bit<4>      version;
    bit<4>      ihl;
    bit<8>      diffserv;
    bit<16>     total_len;
    bit<16>     identification;
    bit<3>      flags;
    bit<13>     frag_offset;
    bit<8>      ttl;
    bit<8>      protocol;
    bit<16>     hdr_checksum;
    ip4Addr_t   src_addr;
    ip4Addr_t   dst_addr;
}

header ipv4_option_h {
    bit<1> copy;
    bit<2> optClass;
    bit<5> option;
    bit<8> optLen;
}

typedef bit<N_VCONN_ID_BITS> vconn_id_t;
typedef bit<N_SN_BITS> vconn_sn_t;
header vconn_h {
    vconn_id_t id;
    vconn_sn_t sn;
}


/*
 * ====================================================
 *
 *                      Ingress
 *
 * ====================================================
*/
struct my_ingress_headers_t {
    ethernet_h      ethernet;
    ipv4_h          ipv4;
    ipv4_option_h   ipv4_option;
    vconn_h         vconn;
}

struct my_ingress_metadata_t {
    vconn_sn_t  max_sn;
    vconn_sn_t  big_sn;
}

parser IngressParser(
        packet_in                       pkt,
    out my_ingress_headers_t            hdr,
    out my_ingress_metadata_t           meta,
    out ingress_intrinsic_metadata_t    intr_meta
) {
    /* This is a mandatory state, required by Tofino Architecture */
    state start {
        meta = { 0, 0 };
        pkt.extract(intr_meta);
        pkt.advance(PORT_METADATA_SIZE);
        transition parse_ethernet;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type) {
            ETHERTYPE_IPV4:  parse_ipv4;
            default: accept;
        }
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        transition select(hdr.ipv4.ihl) {
            5: accept;
            default: parse_ipv4_option;
        }
    }

    state parse_ipv4_option {
        pkt.extract(hdr.ipv4_option);
        transition select(hdr.ipv4_option.option) {
            IPV4_OPT_VCONN: parse_vconn;
            default: accept;
        }
    }

    state parse_vconn {
        pkt.extract(hdr.vconn);
        transition accept;
    }
}

control Ingress(
    inout my_ingress_headers_t                       hdr,
    inout my_ingress_metadata_t                      meta,
    in    ingress_intrinsic_metadata_t               intr_meta,
    in    ingress_intrinsic_metadata_from_parser_t   prsr_md,
    inout ingress_intrinsic_metadata_for_deparser_t  dprsr_md,
    inout ingress_intrinsic_metadata_for_tm_t        tm_md)
{

    /*
     * Reads registered max_sn and incoming sn.
     * If sn > max_sn (circular numbers), update max_sn
     * Always return the previously stored max_sn
    */
    Register<vconn_sn_t, vconn_id_t>(MAX_VCONNS, 0) reg_max_sn;
    RegisterAction<vconn_sn_t, vconn_id_t, vconn_sn_t>(reg_max_sn) regact_max_sn = {
		void apply(inout vconn_sn_t max_sn, out vconn_sn_t rv) {
			rv = max_sn;

			bit<8> delta = (hdr.vconn.sn - max_sn) | 0xE0;
			if(delta < 0xfc) {
				max_sn = hdr.vconn.sn;
			}
		}
    };

    action read_max_sn() {
        meta.max_sn = regact_max_sn.execute(hdr.vconn.id);
    }
    table read_max_sn_tbl {
        key = { }
        actions = { read_max_sn; }
        default_action = read_max_sn;
        size = 1;
    }


    Register<vconn_sn_t, vconn_id_t>(MAX_VCONNS, 0) reg_next_sn;
    RegisterAction<vconn_sn_t, vconn_id_t, vconn_sn_t>(reg_next_sn) regact_next_sn = {
        void apply(inout vconn_sn_t value, out vconn_sn_t rv) {
            rv = value;
            if(value == 31) {
                value = 0;
            } else {
                value = value + 1;
            }
        }
    };

    action forward(macAddr_t dst_addr, PortId_t port, vconn_id_t next_vconn_id) {
        hdr.ipv4.ihl = IHL;

        hdr.ipv4_option.setValid();
        hdr.ipv4_option.copy = 0;
        hdr.ipv4_option.optClass = 0;
        hdr.ipv4_option.option = IPV4_OPT_VCONN;
        hdr.ipv4_option.optLen = IPV4_OPT_LEN;

        hdr.vconn.setValid();
        hdr.vconn.id = next_vconn_id;
        hdr.vconn.sn = regact_next_sn.execute(next_vconn_id);

        tm_md.ucast_egress_port = port;
        hdr.ethernet.src_addr = hdr.ethernet.dst_addr;
        hdr.ethernet.dst_addr = dst_addr;
        hdr.ipv4.ttl = hdr.ipv4.ttl - 1;
    }

    table ipv4_forward_tbl {
        key = {
            hdr.ipv4.dst_addr: lpm;
        }
        actions = {
            forward;
            NoAction;
        }
        size = 1024;
        default_action = NoAction();
    }

    apply {
        if (hdr.vconn.isValid()) {
            read_max_sn_tbl.apply();
        }

        ipv4_forward_tbl.apply();
    }
}


control IngressDeparser(
            packet_out                                  pkt,
    inout   my_ingress_headers_t                        hdr,
    in      my_ingress_metadata_t                       meta,
    in      ingress_intrinsic_metadata_for_deparser_t   dprsr_md
) {
    apply { }
}



/*
 * ====================================================
 *
 *                      Egress
 *
 * ====================================================
*/
struct my_egress_headers_t {
}

struct my_egress_metadata_t {
}

parser EgressParser(
        packet_in                   pkt,
    out my_egress_headers_t         hdr,
    out my_egress_metadata_t        meta,
    out egress_intrinsic_metadata_t eg_intr_md)
{
    /* This is a mandatory state, required by Tofino Architecture */
    state start {
        pkt.extract(eg_intr_md);
        transition accept;
    }
}

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

control EgressDeparser(
            packet_out                                  pkt,
    inout   my_egress_headers_t                         hdr,
    in      my_egress_metadata_t                        meta,
    in      egress_intrinsic_metadata_for_deparser_t    eg_dprsr_md
) {
    apply {
        pkt.emit(hdr);
    }
}

Pipeline(
    IngressParser(),
    Ingress(),
    IngressDeparser(),
    EgressParser(),
    Egress(),
    EgressDeparser()
) pipe;

Switch(pipe) main;


