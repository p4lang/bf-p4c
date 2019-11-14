/* -*- P4_16 -*- */

#include <core.p4>
#include <tna.p4>

/*************************************************************************
 ************* C O N S T A N T S    A N D   T Y P E S  *******************
*************************************************************************/
const bit<16> ETHERTYPE_TPID = 0x8100;
const bit<16> ETHERTYPE_IPV4 = 0x0800;
#define IP_PROTOCOLS_TCP       6

/*************************************************************************
 ***********************  H E A D E R S  *********************************
 *************************************************************************/
/*  Define all the headers the program will recognize             */
/*  The actual sets of headers processed by each gress can differ */

/* Standard ethernet header */
header ethernet_t {
    bit<48>  dst_addr;
    bit<48>  src_addr;
    bit<16>  ether_type;
}

header vlan_tag_t {
    bit<3>   pcp;
    bit<1>   cfi;
    bit<12>  vid;
    bit<16>  ether_type;
}

header ipv4_t {
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

header tcp_option_1_h {
     bit<8> data;
}

header tcp_option_2_h {
    bit<16> data;
}

header tcp_option_4_h {
    bit<32> value;
}

header tcp_option_mss_h {
    bit<8> kind;
    bit<8> length;
    bit<16> mss;
}

/*************************************************************************
 **************  I N G R E S S   P R O C E S S I N G   *******************
 *************************************************************************/
 
    /***********************  H E A D E R S  ************************/

struct my_ingress_headers_t {
    ethernet_t         ethernet;
    vlan_tag_t[2]      vlan_tag;
    ipv4_t             ipv4;
    tcp_h              tcp;
    tcp_option_4_h[10] tcp_options_4_before;
    tcp_option_2_h tcp_options_2_before;
    tcp_option_1_h tcp_options_1_before;
    tcp_option_mss_h tcp_options_mss;
}

    /******  G L O B A L   I N G R E S S   M E T A D A T A  *********/

struct my_ingress_metadata_t {
    bit<1>  ipv4_checksum_err;
    bit<16> ipv4_payload_len;
}

    /***********************  P A R S E R  **************************/

parser IngressParser(packet_in      pkt,
    /* User */
    out my_ingress_headers_t          hdr,
    out my_ingress_metadata_t         meta,
    /* Intrinsic */
    out ingress_intrinsic_metadata_t  ig_intr_md)
{
    ParserCounter() pctr;
    //ParserCounter<bit<32>>() pctr;
    Checksum() ipv4_checksum;
    //Checksum<bit<16>>() ipv4_checksum;
    
    /* This is a mandatory state, required by Tofino Architecture */
    state start {
        pkt.extract(ig_intr_md);
        pkt.advance(PORT_METADATA_SIZE);
        transition meta_init;
    }

    state meta_init {
        meta.ipv4_checksum_err = 0; /* Note, we can't set it to 1 here */
        transition parse_ethernet;
    }
    
    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type) {
            ETHERTYPE_TPID :  parse_vlan_tag;
            ETHERTYPE_IPV4 :  parse_ipv4;
            default        :  accept;
        }
    }

    state parse_vlan_tag {
        pkt.extract(hdr.vlan_tag.next);
        transition select(hdr.vlan_tag.last.ether_type) {
            ETHERTYPE_TPID :  parse_vlan_tag;
            ETHERTYPE_IPV4 :  parse_ipv4;
            default: accept;
        }
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        ipv4_checksum.add(hdr.ipv4);

        meta.ipv4_checksum_err = (bit<1>)ipv4_checksum.verify();
        transition select(hdr.ipv4.protocol) {
            IP_PROTOCOLS_TCP : parse_tcp;
            default : accept;
        }
    }
    state parse_tcp {
        pkt.extract(hdr.tcp);
        transition select(hdr.tcp.data_offset) {
            5 : accept;
            default : parse_tcp_option;
        }
    }

    state parse_tcp_option {
        transition select(hdr.tcp.flags[1:1]) {
            1 : parse_tcp_syn_option; // syn
            default : accept;
        }
    }

    state parse_tcp_syn_option {
        pctr.set(hdr.tcp.data_offset, 15 << 4, 2, 0x7, -20);  // (max, rot, mask, add)
        transition next_option_0b_align;
    }

    // Processing for data starting at byte 0 in 32b word
    @dont_unroll
    state next_option_0b_align {
        transition select(pctr.is_zero()) {
            true : accept;  // no TCP Option bytes left
            default : next_option_0b_align_part2;
        }
    }

    @dont_unroll
    state next_option_0b_align_part2 {
        // precondition: tcp_hdr_bytes_left >= 4
        transition select(pkt.lookahead<bit<32>>()) {
            0x020405b4 : parse_tcp_option_mss;
            0x02000000 &&& 0xff000000 : parse_tcp_option_mss;
            0x00000000 &&& 0xfefefefe : parse_tcp_option_4b_before;
            0x00000000 &&& 0xfefefe00 : next_option_3b_align;
            0x00000000 &&& 0xfefe0000 : next_option_2b_align;
            0x00000000 &&& 0xfe000000 : next_option_1b_align;
            0x00020000 &&& 0x00ff0000 : next_option_2b_align;
            0x00030000 &&& 0x00ff0000 : next_option_3b_align;
            0x00040000 &&& 0x00ff0000 : parse_tcp_option_4b_before;
            0x00060000 &&& 0x00ff0000 : parse_tcp_option_4b_before_2b;
            0x00080000 &&& 0x00ff0000 : parse_tcp_option_8b_before;
            0x000a0000 &&& 0x00ff0000 : parse_tcp_option_8b_before_2b;
            default : accept;
        }
    }

    // Processing for data starting at byte 1 in 32b word
    @dont_unroll
    state next_option_1b_align {
        transition select(pctr.is_zero()) {
            true : accept;  // no TCP Option bytes left
            default : next_option_1b_align_part2;
        }
    }

    @dont_unroll
    state next_option_1b_align_part2 {
        // precondition: tcp_hdr_bytes_left >= 3
        transition select(pkt.lookahead<bit<32>>()[23:0]) {
        // transition select(pkt.lookahead<bit<24>>()) {
            0x020000 &&& 0xff0000 : parse_tcp_option_1b_before_mss;
            0x000000 &&& 0xfefefe : parse_tcp_option_4b_before;
            0x000000 &&& 0xfefe00 : next_option_3b_align;
            0x000000 &&& 0xfe0000 : next_option_2b_align;
            0x000200 &&& 0x00ff00 : next_option_3b_align;
            0x000300 &&& 0x00ff00 : parse_tcp_option_4b_before;
            0x000400 &&& 0x00ff00 : parse_tcp_option_4b_before_1b;
            0x000600 &&& 0x00ff00 : parse_tcp_option_4b_before_3b;
            0x000800 &&& 0x00ff00 : parse_tcp_option_8b_before_1b;
            0x000a00 &&& 0x00ff00 : parse_tcp_option_8b_before_3b;
        }
    }

    // Processing for data starting at byte 2 in 32b word
    @dont_unroll
    state next_option_2b_align {
        transition select(pctr.is_zero()) {
            true : accept;  // no TCP Option bytes left
            default : next_option_2b_align_part2;
        }
    }

    state next_option_2b_align_part2 {
        // precondition: tcp_hdr_bytes_left >= 2
        transition select(pkt.lookahead<bit<32>>()[15:0]) {
        // transition select(pkt.lookahead<bit<16>>()) {
            0x0200 &&& 0xff00 : parse_tcp_option_2b_before_mss;
            0x0000 &&& 0xfefe : parse_tcp_option_4b_before;
            0x0000 &&& 0xfe00 : next_option_3b_align;
            0x0002 &&& 0x00ff : parse_tcp_option_4b_before;
            0x0003 &&& 0x00ff : parse_tcp_option_4b_before_1b;
            0x0004 &&& 0x00ff : parse_tcp_option_4b_before_2b;
            0x0006 &&& 0x00ff : parse_tcp_option_8b_before;
            0x0008 &&& 0x00ff : parse_tcp_option_8b_before_2b;
            0x000a &&& 0x00ff : parse_tcp_option_12b_before;
        }
    }

    // Processing for data starting at byte 3 in 32b word
    @dont_unroll
    state next_option_3b_align {
        transition select(pctr.is_zero()) {
            true : accept;  // no TCP Option bytes left
            default : next_option_3b_align_part2;
        }
    }

    @dont_unroll
    state next_option_3b_align_part2 {
        // precondition: tcp_hdr_bytes_left >= 2
        transition select(pkt.lookahead<bit<40>>()[15:0]) {
        // transition select(pkt.lookahead<bit<16>>()) {
            0x0200 &&& 0xff00 : parse_tcp_option_3b_before_mss;
            0x0000 &&& 0xfe00 : parse_tcp_option_4b_before;
            0x0002 &&& 0x00ff : parse_tcp_option_4b_before_1b;
            0x0003 &&& 0x00ff : parse_tcp_option_4b_before_2b;
            0x0004 &&& 0x00ff : parse_tcp_option_4b_before_3b;
            0x0006 &&& 0x00ff : parse_tcp_option_8b_before_1b;
            0x0008 &&& 0x00ff : parse_tcp_option_8b_before_3b;
            0x000a &&& 0x00ff : parse_tcp_option_12b_before_1b;
            default : parse_tcp_option_3b_before_mss;
        }
    }

    @dont_unroll
    state parse_tcp_option_mss {
        pkt.extract(hdr.tcp_options_mss);
        transition accept;
    }

    @dont_unroll
    state parse_tcp_option_1b_before_mss {
        pkt.extract(hdr.tcp_options_1_before);
        pctr.decrement(1);
        transition parse_tcp_option_mss;
    }

    @dont_unroll
    state parse_tcp_option_2b_before_mss {
        pkt.extract(hdr.tcp_options_2_before);
        pctr.decrement(2);
        transition parse_tcp_option_mss;
    }

    @dont_unroll
    state parse_tcp_option_3b_before_mss {
        pkt.extract(hdr.tcp_options_2_before);
        pkt.extract(hdr.tcp_options_1_before);
        pctr.decrement(3);
        transition parse_tcp_option_mss;
    }

    @dont_unroll
    state parse_tcp_option_4b_before {
        pkt.extract(hdr.tcp_options_4_before.next);
        pctr.decrement(4);
        transition next_option_0b_align;
    }

    @dont_unroll
    state parse_tcp_option_4b_before_1b {
        pkt.extract(hdr.tcp_options_4_before.next);
        pctr.decrement(4);
        transition next_option_1b_align;
    }

    @dont_unroll
    state parse_tcp_option_4b_before_2b {
        pkt.extract(hdr.tcp_options_4_before.next);
        pctr.decrement(4);
        transition next_option_2b_align;
    }

    @dont_unroll
    state parse_tcp_option_4b_before_3b {
        pkt.extract(hdr.tcp_options_4_before.next);
        pctr.decrement(4);
        transition next_option_3b_align;
    }

    @dont_unroll
    state parse_tcp_option_8b_before {
        pkt.extract(hdr.tcp_options_4_before.next);
        pkt.extract(hdr.tcp_options_4_before.next);
        pctr.decrement(8);
        transition next_option_0b_align;
    }

    @dont_unroll
    state parse_tcp_option_8b_before_1b {
        pkt.extract(hdr.tcp_options_4_before.next);
        pkt.extract(hdr.tcp_options_4_before.next);
        pctr.decrement(8);
        transition next_option_1b_align;
    }

    @dont_unroll
    state parse_tcp_option_8b_before_2b {
        pkt.extract(hdr.tcp_options_4_before.next);
        pkt.extract(hdr.tcp_options_4_before.next);
        pctr.decrement(8);
        transition next_option_2b_align;
    }

    @dont_unroll
    state parse_tcp_option_8b_before_3b {
        pkt.extract(hdr.tcp_options_4_before.next);
        pkt.extract(hdr.tcp_options_4_before.next);
        pctr.decrement(8);
        transition next_option_3b_align;
    }

    @dont_unroll
    state parse_tcp_option_12b_before {
        pkt.extract(hdr.tcp_options_4_before.next);
        pkt.extract(hdr.tcp_options_4_before.next);
        pkt.extract(hdr.tcp_options_4_before.next);
        pctr.decrement(12);
        transition next_option_0b_align;
    }

    @dont_unroll
    state parse_tcp_option_12b_before_1b {
        pkt.extract(hdr.tcp_options_4_before.next);
        pkt.extract(hdr.tcp_options_4_before.next);
        pkt.extract(hdr.tcp_options_4_before.next);
        pctr.decrement(12);
        transition next_option_1b_align;
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
    bit<16> mss_expect = 1430;
    bit<16> mss_check = 0;

    action do_mss_check(bit<16> mss, bit<16> expect) {
        mss_check = mss |-| expect;  //  saturated subtract
    }
    apply {
        ig_tm_md.ucast_egress_port = ig_intr_md.ingress_port;
            // mss clamping
        if (hdr.tcp_options_mss.isValid()) {
            do_mss_check(hdr.tcp_options_mss.mss, mss_expect);
            if (mss_check > 0) {
                hdr.tcp_options_mss.mss = mss_expect;
                meta.ipv4_payload_len = hdr.ipv4.total_len - 20;
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
    in    ingress_intrinsic_metadata_for_deparser_t  ig_intr_md_for_dprsr)
{
    Checksum() ipv4_checksum;
    //Checksum<bit<16>>(HashAlgorithm_t.CSUM16) ipv4_checksum;
    
    apply {
        hdr.ipv4.hdr_checksum = ipv4_checksum.update(
              { hdr.ipv4.version,
                hdr.ipv4.ihl,
                hdr.ipv4.diffserv,
                hdr.ipv4.total_len,
                hdr.ipv4.identification,
                hdr.ipv4.flags,
                hdr.ipv4.frag_offset,
                hdr.ipv4.ttl,
                hdr.ipv4.protocol,
                hdr.ipv4.src_addr,
                hdr.ipv4.dst_addr}
            );
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

parser EgressParser(packet_in      pkt,
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
