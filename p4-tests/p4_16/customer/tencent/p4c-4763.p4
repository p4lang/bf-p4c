/* -*- P4_16 -*- */

/*

Please use p4c-9.1.0-pr.16 or higher pr.
It attempts to break down the options into a set of 4B chunks plus an optional 2B and 1B chunk before the MSS.
The difficulty is that because options can be any length, it has to merge or break them up into a series of 4B extracts.
There may also be the 2B and/or 1B extract immediately before the MSS. The downside of this approach is that it
consumes a lot of states in the parse table.

I don't believe you need to worry about options after MSS. If you don't parse them then they should be copied unmodified
into the output packet.

The 0xfe mask is to take all bits except the LSB. This is intended to take care of the two single-byte options
(kind = 0 and kind = 1). So 0x00000000 & 0xfefefefe is meant to match 4 single-byte options in a row,
0x00000000 & 0xfefefe00 matches 3 single-byte options in a row, etc.

tcp_option_3b, tcp_option_4b, tcp_option_end
(Total: 8B)
States:
- next_option_0b_align
- next_option_0b_align_part2 (matches on 3B option)
- next_option_3b_align
- next_option_3b_align_part2 (matches on 4B option)
If 4B option  MSS:
    - parse_tcp_option_3b_before_mss (extract 3B)
    - parse_tcp_option_mss (extract mss)
    - accept <Note: it does not parse the TCP options after MSS>
- If 4B option is not MSS:
    - parse_tcp_option_4b_before_3b (extracts 4B: 3B from tcp_option_3b and 1B from tcp_option_4b).
    - next_option_3b_align
    - next_option_3b_align_part2 (matches on 1B option)
    - parse_tcp_option_4b_before (extract 4B: 3B from tcp_option_4b and 1B from tcp_option_end)
    - next_option_0b_align (matches on ctr = 0)
    - accept

tcp_option_3b, tcp_option_2b, tcp_option_4b, tcp_option_nop, tcp_option_nop, tcp_option_end
(Total: 12B)
- next_option_0b_align
- next_option_0b_align_part2 (matches on 3B option)
- next_option_3b_align
- next_option_3b_align_part2 (matches on 2B option)
- parse_tcp_option_4b_before_1b (extracts 4B -- 3B from tcp_option_3b and 1B from tcp_option_2b)
- next_option_1b_align
- next_option_1b_align_part2 (matches on 4B option)
- If 4B option is MSS:
    - parse_tcp_option_1b_before_mss
    - parse_tcp_option_mss
    - accept <Note: it does not parse the TCP options after MSS>
- If 4B option is not MSS:
    - parse_tcp_option_4b_before_1b (extracts 4B -- 1B from tcp_option_2b and 3B from tcp_option_4b)
    - next_option_1b_align
    - next_option_1b_align_part2 (matches on 3 x 1B option)
    - parse_tcp_option_4b_before (extracts 4B -- 1B from tcp_option_4b and 3B from tcp_option_1b)
    - next_option_0b_align (matches on ctr = 0)
    - accept

tcp_option_3b, tcp_option_nop, tcp_option_2b, tcp_option_nop, tcp_option_nop, tcp_option_4b
(Total: 12B)
- next_option_0b_align
- next_option_0b_align_part2 (matches on 3B option)
- next_option_3b_align
- next_option_3b_align_part2 (matches on 1B option)
- parse_tcp_option_4b_before

- next_option_0b_align
- next_option_0b_align_part2 (matches on 2B option)

- next_option_2b_align
- next_option_2b_align_part2 (matches on 2 x 1B option)

- parse_tcp_option_4b_before


- next_option_0b_align
- next_option_0b_align_part2 (matches on 4B option)
If 4B option was MSS:
    - parse_tcp_option_mss
    - accept <Note: it does not parse the TCP options after MSS>
If 4B option was not MSS:
    - parse_tcp_option_4b_before
    - next_option_0b_align (matches on ctr = 0)
    - accept
*/

#include <core.p4>
#include <tna.p4>  /* TOFINO1_ONLY */

/*************************************************************************
 ************* C O N S T A N T S    A N D   T Y P E S  *******************
*************************************************************************/
const bit<16> ETHERTYPE_TPID = 0x8100;
const bit<16> ETHERTYPE_IPV4 = 0x0800;
#define IP_PROTOCOLS_TCP       6

@command_line("--disable-parse-min-depth-limit", "--disable-parse-max-depth-limit")

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

//     /***********************  H E A D E R S  ************************/

// struct my_ingress_headers_t {
//     ethernet_t         ethernet;
//     vlan_tag_t[2]      vlan_tag;
//     ipv4_t             ipv4;
//     tcp_h              tcp;
//     tcp_option_4_h[10] tcp_options_4b_before;
//     tcp_option_2_h tcp_options_2b_before;
//     tcp_option_1_h tcp_options_1b_before;
//     tcp_option_mss_h tcp_options_mss;
// }

//     /******  G L O B A L   I N G R E S S   M E T A D A T A  *********/

// struct my_ingress_metadata_t {
//     bit<1>  ipv4_checksum_err;
//     bool  tcp_checksum_odd;
//     bool  tcp_checksum_even;
//     bit<16> ipv4_payload_len;
//     bit<16> checksum_tcp_tmp;
//     bit<32> my_length;
// }

    /***********************  H E A D E R S  ************************/

struct my_ingress_headers_t {
}

    /********  G L O B A L   E G R E S S   M E T A D A T A  *********/

struct my_ingress_metadata_t {
}

    /***********************  P A R S E R  **************************/

parser IngressParser(packet_in      pkt,
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
    apply {
        ig_tm_md.ucast_egress_port = ig_intr_md.ingress_port;
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
    apply {
        pkt.emit(hdr);
    }
}


/*************************************************************************
 ****************  E G R E S S   P R O C E S S I N G   *******************
 *************************************************************************/

    /***********************  H E A D E R S  ************************/

struct my_egress_headers_t {
    ethernet_t         ethernet;
    vlan_tag_t[2]      vlan_tag;
    ipv4_t             ipv4;
    tcp_h              tcp;
    tcp_option_4_h[10] tcp_options_4b_before;
    tcp_option_2_h tcp_options_2b_before;
    tcp_option_1_h tcp_options_1b_before;
    tcp_option_mss_h tcp_options_mss;
}

    /******  G L O B A L   I N G R E S S   M E T A D A T A  *********/

struct my_egress_metadata_t {
    bit<1>  ipv4_checksum_err;
    bool  tcp_checksum_odd;
    bool  tcp_checksum_even;
    bit<16> ipv4_payload_len;
    bit<16> checksum_tcp_tmp;
    bit<32> my_length;
}

    /***********************  P A R S E R  **************************/

parser EgressParser(packet_in      pkt,
    /* User */
    out my_egress_headers_t          hdr,
    out my_egress_metadata_t         meta,
    /* Intrinsic */
    out egress_intrinsic_metadata_t  eg_intr_md)
{
    ParserCounter() pctr;
    Checksum() ipv4_checksum;
    Checksum() inner_ipv4_checksum;
    Checksum() tcp_checksum;

    /* This is a mandatory state, required by Tofino Architecture */
    state start {
        pkt.extract(eg_intr_md);
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

        // subtract other possibly changed fields
        //tcp_checksum.subtract({hdr.ipv4.src_addr});

        transition select(hdr.ipv4.protocol) {
            IP_PROTOCOLS_TCP : parse_tcp;
            default : accept;
        }
    }
    state parse_tcp {
        pkt.extract(hdr.tcp);

        // subtract other possibly changed fields
        //tcp_checksum.subtract({hdr.tcp.src_port});
        // tcp_checksum.subtract({hdr.tcp.checksum});
        // tcp_checksum.subtract_all_and_deposit(meta.checksum_tcp_tmp);
        tcp_checksum.subtract({hdr.tcp.checksum});
        meta.checksum_tcp_tmp = tcp_checksum.get();

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
        // Load the counter with a header field.
        // @param max : Maximum permitted value for counter (pre rotate/mask/add).
        // @param rotate : Right rotate (circular) the source field by this number of bits.
        // @param mask : Mask the rotated source field by 2 ^ (mask + 1) - 1.
        // @param add : Constant to add to the rotated and masked lookup field.
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
            0x00120000 &&& 0x00ff0000 : parse_tcp_option_12b_before_6b;
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
            0x001200 &&& 0x00ff00 : parse_tcp_option_12b_before_7b;
            default : accept;
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
            0x0200 &&& 0xff00 : parse_tcp_option_2b_before_mss;
            0x0000 &&& 0xfefe : parse_tcp_option_4b_before;
            0x0000 &&& 0xfe00 : next_option_3b_align;
            0x0002 &&& 0x00ff : parse_tcp_option_4b_before;
            0x0003 &&& 0x00ff : parse_tcp_option_4b_before_1b;
            0x0004 &&& 0x00ff : parse_tcp_option_4b_before_2b;
            0x0006 &&& 0x00ff : parse_tcp_option_8b_before;
            0x0008 &&& 0x00ff : parse_tcp_option_8b_before_2b;
            0x000a &&& 0x00ff : parse_tcp_option_12b_before;
            0x0012 &&& 0x00ff : parse_tcp_option_12b_before_8b;
            default : accept;
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
            0x0200 &&& 0xff00 : parse_tcp_option_3b_before_mss;
            0x0000 &&& 0xfe00 : parse_tcp_option_4b_before;
            0x0002 &&& 0x00ff : parse_tcp_option_4b_before_1b;
            0x0003 &&& 0x00ff : parse_tcp_option_4b_before_2b;
            0x0004 &&& 0x00ff : parse_tcp_option_4b_before_3b;
            0x0006 &&& 0x00ff : parse_tcp_option_8b_before_1b;
            0x0008 &&& 0x00ff : parse_tcp_option_8b_before_3b;
            0x000a &&& 0x00ff : parse_tcp_option_12b_before_1b;
            0x0012 &&& 0x00ff : parse_tcp_option_12b_before_9b;
            default : parse_tcp_option_3b_before_mss;
        }
    }

    @dont_unroll
    state parse_tcp_option_mss {
        pkt.extract(hdr.tcp_options_mss);
        tcp_checksum.subtract({hdr.tcp_options_mss});
        transition accept;
    }

    @dont_unroll
    state parse_tcp_option_1b_before_mss {
        pkt.extract(hdr.tcp_options_1b_before);
        pctr.decrement(1);
        transition accept;
    }

    @dont_unroll
    state parse_tcp_option_2b_before_mss {
        pkt.extract(hdr.tcp_options_2b_before);
        pctr.decrement(2);
        transition parse_tcp_option_mss;
    }

    @dont_unroll
    state parse_tcp_option_3b_before_mss {
        pkt.extract(hdr.tcp_options_2b_before);
        pkt.extract(hdr.tcp_options_1b_before);
        pctr.decrement(3);
        transition parse_tcp_option_mss;
    }

    @dont_unroll
    state parse_tcp_option_4b_before {
        pkt.extract(hdr.tcp_options_4b_before.next);
        pctr.decrement(4);
        transition next_option_0b_align;
    }

    @dont_unroll
    state parse_tcp_option_4b_before_1b {
        pkt.extract(hdr.tcp_options_4b_before.next);
        pctr.decrement(4);
        transition next_option_1b_align;
    }

    @dont_unroll
    state parse_tcp_option_4b_before_2b {
        pkt.extract(hdr.tcp_options_4b_before.next);
        pctr.decrement(4);
        transition next_option_2b_align;
    }

    @dont_unroll
    state parse_tcp_option_4b_before_3b {
        pkt.extract(hdr.tcp_options_4b_before.next);
        pctr.decrement(4);
        transition next_option_3b_align;
    }

    @dont_unroll
    state parse_tcp_option_8b_before {
        pkt.extract(hdr.tcp_options_4b_before.next);
        pkt.extract(hdr.tcp_options_4b_before.next);
        pctr.decrement(8);
        transition next_option_0b_align;
    }

    @dont_unroll
    state parse_tcp_option_8b_before_1b {
        pkt.extract(hdr.tcp_options_4b_before.next);
        pkt.extract(hdr.tcp_options_4b_before.next);
        pctr.decrement(8);
        transition next_option_1b_align;
    }

    @dont_unroll
    state parse_tcp_option_8b_before_2b {
        pkt.extract(hdr.tcp_options_4b_before.next);
        pkt.extract(hdr.tcp_options_4b_before.next);
        pctr.decrement(8);
        transition next_option_2b_align;
    }

    @dont_unroll
    state parse_tcp_option_8b_before_3b {
        pkt.extract(hdr.tcp_options_4b_before.next);
        pkt.extract(hdr.tcp_options_4b_before.next);
        pctr.decrement(8);
        transition next_option_3b_align;
    }

    @dont_unroll
    state parse_tcp_option_12b_before {
        pkt.extract(hdr.tcp_options_4b_before.next);
        pkt.extract(hdr.tcp_options_4b_before.next);
        pkt.extract(hdr.tcp_options_4b_before.next);
        pctr.decrement(12);
        transition next_option_0b_align;
    }

    @dont_unroll
    state parse_tcp_option_12b_before_1b {
        pkt.extract(hdr.tcp_options_4b_before.next);
        pkt.extract(hdr.tcp_options_4b_before.next);
        pkt.extract(hdr.tcp_options_4b_before.next);
        pctr.decrement(12);
        transition next_option_1b_align;
    }

    @dont_unroll
    state parse_tcp_option_12b_before_6b {
        pkt.extract(hdr.tcp_options_4b_before.next);
        pkt.extract(hdr.tcp_options_4b_before.next);
        pkt.extract(hdr.tcp_options_4b_before.next);
        pctr.decrement(12);
        transition parse_tcp_option_4b_before_2b;
    }

    @dont_unroll
    state parse_tcp_option_12b_before_7b {
        pkt.extract(hdr.tcp_options_4b_before.next);
        pkt.extract(hdr.tcp_options_4b_before.next);
        pkt.extract(hdr.tcp_options_4b_before.next);
        pctr.decrement(12);
        transition parse_tcp_option_4b_before_3b;
    }

    @dont_unroll
    state parse_tcp_option_12b_before_8b {
        pkt.extract(hdr.tcp_options_4b_before.next);
        pkt.extract(hdr.tcp_options_4b_before.next);
        pkt.extract(hdr.tcp_options_4b_before.next);
        pctr.decrement(12);
        transition parse_tcp_option_8b_before;
    }

    @dont_unroll
    state parse_tcp_option_12b_before_9b {
        pkt.extract(hdr.tcp_options_4b_before.next);
        pkt.extract(hdr.tcp_options_4b_before.next);
        pkt.extract(hdr.tcp_options_4b_before.next);
        pctr.decrement(12);
        transition parse_tcp_option_8b_before_1b;
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
    bit<16> mss_expect = 1428;
    bit<16> mss_check = 0;

    action do_mss_check(bit<16> mss, bit<16> expect) {
        mss_check = mss |-| expect;  //  saturated subtract
    }
    apply {
            // mss clamping
        if (hdr.tcp_options_mss.isValid()) {
            do_mss_check(hdr.tcp_options_mss.mss, mss_expect);
            if (mss_check > 0) {
                hdr.tcp_options_mss.mss = mss_expect;
            }
        }
        if (hdr.tcp_options_1b_before.isValid()) {
            meta.tcp_checksum_odd = true;
            meta.tcp_checksum_even = false;
        } else {
            meta.tcp_checksum_odd = false;
            meta.tcp_checksum_even = true;
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
    Checksum() ipv4_checksum;
    Checksum() tcp_checksum;

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
        if (meta.tcp_checksum_odd) {
            // tcp_checksum.subtract({});
            hdr.tcp.checksum = tcp_checksum.update({
                // update other possibly changed fields
                hdr.tcp_options_4b_before[0],
                hdr.tcp_options_4b_before[1],
                hdr.tcp_options_4b_before[2],
                hdr.tcp_options_4b_before[3],
                hdr.tcp_options_4b_before[4],
                hdr.tcp_options_4b_before[5],
                hdr.tcp_options_4b_before[6],
                hdr.tcp_options_4b_before[7],
                hdr.tcp_options_4b_before[8],
                hdr.tcp_options_4b_before[9],
                hdr.tcp_options_2b_before,
                hdr.tcp_options_1b_before,
                hdr.tcp_options_mss,
                8w0,
                meta.checksum_tcp_tmp
            });
        }

        if (meta.tcp_checksum_even) {
            hdr.tcp.checksum = tcp_checksum.update({
                // update other possibly changed fields
                hdr.tcp_options_4b_before[0],
                hdr.tcp_options_4b_before[1],
                hdr.tcp_options_4b_before[2],
                hdr.tcp_options_4b_before[3],
                hdr.tcp_options_4b_before[4],
                hdr.tcp_options_4b_before[5],
                hdr.tcp_options_4b_before[6],
                hdr.tcp_options_4b_before[7],
                hdr.tcp_options_4b_before[8],
                hdr.tcp_options_4b_before[9],
                hdr.tcp_options_2b_before,
                hdr.tcp_options_mss,
                meta.checksum_tcp_tmp
            });
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
