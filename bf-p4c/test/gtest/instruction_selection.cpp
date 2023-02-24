#include <boost/algorithm/string/replace.hpp>
#include <boost/optional.hpp>
#include "gtest/gtest.h"

#include "ir/ir.h"
#include "lib/error.h"
#include "test/gtest/helpers.h"
#include "bf-p4c/test/gtest/tofino_gtest_utils.h"
#include "bf-p4c/common/check_uninitialized_read.h"
#include "bf_gtest_helpers.h"

namespace Test {

class InstructionSelectionTest : public TofinoBackendTest {};

// This test is to see if ssub operation is properly replaced. See p4c-1819.
TEST_F(InstructionSelectionTest, TestForSaturatingSubReplacement) {
    auto program = R"(
/* -*- P4_16 -*- */

/*************************************************************************
 ************* C O N S T A N T S    A N D   T Y P E S  *******************
**************************************************************************/
typedef bit<48>   mac_addr_t;
typedef bit<32>   ipv4_addr_t;
typedef bit<128>  ipv6_addr_t;

enum bit<16> ether_type_t {
    TPID = 0x8100,
    IPV4 = 0x0800,
    IPV6 = 0x86DD,
    MPLS = 0x8847
}

enum bit<8>  ip_proto_t {
    ICMP  = 1,
    IGMP  = 2,
    TCP   = 6,
    UDP   = 17
}

enum bit<8> header_type_t {
    UNKNOWN    = 0x0,
    RESUBMIT   = 0xA,   /* Again (i.e. parse again) */
    BRIDGE     = 0xB,   /* Bridge                   */
    ING_MIRROR = 0xC,   /* Clone                    */
    EGR_MIRROR = 0xD    /* D=C+1                    */
}

typedef bit<8> header_info_t;

/* The type of traffic an MPLS Circuit is carrying */
enum bit<8> mpls_circuit_t {
    INVALID  = 0,
    ETHERNET = 1,
    IPV4     = 2,
    IPV6     = 3
}

const int NEXTHOP_ID_WIDTH = 14;
typedef bit<(NEXTHOP_ID_WIDTH)> nexthop_id_t;

/* Table Sizing */
const int IPV4_HOST_TABLE_SIZE = 131072;
const int IPV4_LPM_TABLE_SIZE  = 12288;

const int IPV6_HOST_TABLE_SIZE = 65536;
const int IPV6_LPM_TABLE_SIZE  = 4096;

const int DMAC_TABLE_SIZE      = 32768;

const int NEXTHOP_TABLE_SIZE   = 1 << NEXTHOP_ID_WIDTH;

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

header mpls_h {
    bit<20>       label;
    bit<3>        exp;
    bit<1>        bos;
    bit<8>        ttl;
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

header ipv4_options_h {
    varbit<320> data;
}

header ipv6_h {
    bit<4>       version;
    bit<8>       traffic_class;
    bit<20>      flow_label;
    bit<16>      payload_len;
    ip_proto_t   next_hdr;
    bit<8>       hop_limit;
    ipv6_addr_t  src_addr;
    ipv6_addr_t  dst_addr;
}

/*** Internal Headers ***/

/*
 * This is a common "preamble" header that must be present in all internal
 * headers. The only time you do not need it is when you know that you are
 * not going to have more than one internal header type ever
 */


header inthdr_h {
    header_type_t header_type;
    header_info_t header_info;
}

/* Resubmit information */
const bit<3> MPLS_RESUBMIT = 0;

@pa_container_size("ingress", "meta.mpls_resubmit.header_type", 8)
@pa_container_size("ingress", "meta.mpls_resubmit.header_info", 8)
@pa_container_size("ingress", "meta.mpls_resubmit.mpls_circuit", 8)
header mpls_resubmit_h {
    header_type_t header_type;
    header_info_t header_info;
    mpls_circuit_t mpls_circuit;
}

/*************************************************************************
 **************  I N G R E S S   P R O C E S S I N G   *******************
 *************************************************************************/

    /***********************  H E A D E R S  ************************/

struct my_ingress_headers_t {
    ethernet_h         ethernet;
    vlan_tag_h         vlan_tag;
    mpls_h[3]          mpls;
    ethernet_h         inner_ethernet;
    ipv4_h             ipv4;
    ipv4_options_h     ipv4_options;
    ipv6_h             ipv6;
}

    /******  G L O B A L   I N G R E S S   M E T A D A T A  *********/

struct my_ingress_metadata_t {
    bit<1>          ipv4_csum_err;
    mpls_resubmit_h mpls_resubmit;
}

    /***********************  P A R S E R  **************************/
parser IngressParser(packet_in        pkt,
    /* User */
    out my_ingress_headers_t          hdr,
    out my_ingress_metadata_t         meta,
    /* Intrinsic */
    out ingress_intrinsic_metadata_t  ig_intr_md)
{
    inthdr_h    inthdr;
    Checksum() ipv4_checksum;
    bit<1> bos0;
    bit<1> bos1;
    bit<1> bos2;

    /* This is a mandatory state, required by Tofino Architecture */
    state start {
        meta.ipv4_csum_err = 0;

        pkt.extract(ig_intr_md);
        inthdr = pkt.lookahead<inthdr_h>();

        transition select(
            ig_intr_md.resubmit_flag,
            inthdr.header_type,
            inthdr.header_info)
        {
            (0, _, _) :  parse_port_metadata;
            (1, header_type_t.RESUBMIT, (header_info_t)MPLS_RESUBMIT):
                         parse_mpls_resubmit;
            default: accept;
            /* We will drop all other resubmitted packets */
        }
    }

    /* Normal (non-resubmitted) packet parsing */
    state parse_port_metadata {
        pkt.advance(PORT_METADATA_SIZE);

        transition parse_ethernet;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type) {
            ether_type_t.TPID:  parse_vlan_tag;
            ether_type_t.IPV4:  parse_ipv4;
            ether_type_t.IPV6:  parse_ipv6;
            ether_type_t.MPLS:  parse_mpls;
            default: accept;
        }
    }

    state parse_vlan_tag {
        pkt.extract(hdr.vlan_tag);
        transition select(hdr.vlan_tag.ether_type) {
            ether_type_t.IPV4:  parse_ipv4;
            ether_type_t.IPV6:  parse_ipv6;
            ether_type_t.MPLS:  parse_mpls;
           default: accept;
        }
    }

    state parse_mpls {
        pkt.extract(hdr.mpls.next);
        transition select(hdr.mpls.last.bos) {
            0: parse_mpls;
            1: parse_mpls_payload;
        }
    }

    state parse_mpls_payload {
        transition select(pkt.lookahead<bit<4>>()) {
            4: parse_ipv4;
            6: parse_ipv6;
            _: parse_inner_ethernet;
        }
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        ipv4_checksum.add(hdr.ipv4);

        transition select(hdr.ipv4.ihl) {
            0x5 : parse_ipv4_no_options;
            0x6 &&& 0xE : parse_ipv4_options;
            0x8 &&& 0x8 : parse_ipv4_options;
            default: reject;
        }
    }

    state parse_ipv4_options {
        pkt.extract(
            hdr.ipv4_options,
            (bit<32>)(hdr.ipv4.ihl - 5) * 32);

        ipv4_checksum.add(hdr.ipv4_options);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_no_options {
        meta.ipv4_csum_err = (bit<1>)ipv4_checksum.verify();
        transition accept;
    }

    state parse_ipv6 {
        pkt.extract(hdr.ipv6);
        transition accept;
    }

    state parse_inner_ethernet {
        pkt.extract(hdr.inner_ethernet);
        transition accept;
    }

    /* Resubmitted packet parsing */
    state parse_mpls_resubmit {
        /*
         * Resubmit header and PORT_METADATA occupy the same space (64 bits)
         * on Tofino. If resubmit header is smaller than PORT_METADATA_SIZE,
         * the remaining bits (bytes) must be consumed
         */

        meta.mpls_resubmit = pkt.lookahead<mpls_resubmit_h>();
        pkt.advance(PORT_METADATA_SIZE);
        transition parse_mpls_resubmit_ethernet;
    }
    state parse_mpls_resubmit_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type) {
            ether_type_t.TPID:  parse_mpls_resubmit_vlan_tag;
            ether_type_t.IPV4:  parse_ipv4;
            ether_type_t.IPV6:  parse_ipv6;
            ether_type_t.MPLS:  parse_mpls_resubmit_mpls;
            default: accept;
        }
    }

    state parse_mpls_resubmit_vlan_tag {
        pkt.extract(hdr.vlan_tag);
        transition select(hdr.vlan_tag.ether_type) {
            ether_type_t.IPV4:  parse_ipv4;
            ether_type_t.IPV6:  parse_ipv6;
            ether_type_t.MPLS:  parse_mpls_resubmit_mpls;
           default: accept;
        }
    }

    state parse_mpls_resubmit_mpls {
        pkt.extract(hdr.mpls.next);
        transition select(hdr.mpls.last.bos) {
            0: parse_mpls_resubmit_mpls;
            1: parse_mpls_resubmit_mpls_payload;
        }
    }

    state parse_mpls_resubmit_mpls_payload {
        transition select(meta.mpls_resubmit.mpls_circuit) {
            mpls_circuit_t.ETHERNET : parse_inner_ethernet;
            mpls_circuit_t.IPV4     : parse_ipv4;
            mpls_circuit_t.IPV6     : parse_ipv6;
            /* Drop the packet in all other cases */
        }
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
    nexthop_id_t    nexthop_id = 0;
    bit<8>          ttl_dec = 0;

    /************* MPLS DECAP **************/
    action remove_all_labels() {
        hdr.mpls[0].setInvalid();
        hdr.mpls[1].setInvalid();
        hdr.mpls[2].setInvalid();
    }

    action mpls_decap_ipv4() {
        remove_all_labels();
        hdr.ethernet.ether_type = ether_type_t.IPV4;
        meta.mpls_resubmit.mpls_circuit  = mpls_circuit_t.IPV4;
    }

    action mpls_decap_ipv6() {
        remove_all_labels();
        hdr.ethernet.ether_type = ether_type_t.IPV6;
        meta.mpls_resubmit.mpls_circuit  = mpls_circuit_t.IPV6;
    }

    action mpls_decap_inner_ethernet() {
        remove_all_labels();
        hdr.ethernet = hdr.inner_ethernet;
        meta.mpls_resubmit.mpls_circuit  = mpls_circuit_t.ETHERNET;
    }

    /* Transit VCs also carry a specific type of traffic. While this is
     * not the case in this program, users often want to parse transit packets
     * deeper, e.g. for ACLs or for traffic distribution */
    action mpls_transit(mpls_circuit_t circuit) {
        hdr.mpls.pop_front(1);
        hdr.mpls[0].ttl = hdr.mpls[0].ttl |-| 1;
        meta.mpls_resubmit.mpls_circuit = circuit;
    }

    table mpls_decap {
        key = {
            hdr.mpls[0].label : ternary;
            hdr.mpls[1].label : ternary;
            hdr.mpls[2].label : ternary;
        }
        actions = {
            mpls_decap_ipv4;
            mpls_decap_ipv6;
            mpls_decap_inner_ethernet;
            mpls_transit;
        }
        default_action = mpls_transit(mpls_circuit_t.IPV4);
        size = 512;
    }

    /************ MPLS RESUBMIT *********/
    action mpls_resubmit() {
        ig_dprsr_md.resubmit_type = MPLS_RESUBMIT;
        meta.mpls_resubmit.header_type = header_type_t.RESUBMIT;
        meta.mpls_resubmit.header_info = (header_info_t)MPLS_RESUBMIT;
        /* You can also add exit here */
    }

    /************ IPV4 LOOKUP ***********/
    action set_nexthop(nexthop_id_t nexthop) {
        nexthop_id = nexthop;
    }

    table ipv4_host {
        key = { hdr.ipv4.dst_addr : exact; }
        actions = {
            set_nexthop;
            @defaultonly NoAction;
        }
        const default_action = NoAction();
        size = IPV4_HOST_TABLE_SIZE;
    }

    table ipv4_lpm {
        key     = { hdr.ipv4.dst_addr : lpm; }
        actions = { set_nexthop; }

        default_action = set_nexthop(0);
        size           = IPV4_LPM_TABLE_SIZE;
    }

    /************ IPV6 LOOKUP ***********/
    table ipv6_host {
        key = { hdr.ipv6.dst_addr : exact; }
        actions = {
            set_nexthop;
            @defaultonly NoAction;
        }
        const default_action = NoAction();
        size = IPV6_HOST_TABLE_SIZE;
    }

    table ipv6_lpm {
        key     = { hdr.ipv6.dst_addr : lpm; }
        actions = { set_nexthop; }

        default_action = set_nexthop(0);
        size           = IPV6_LPM_TABLE_SIZE;
    }

    /************ L2 LOOKUP ***********/
    table dmac {
        key = { hdr.ethernet.dst_addr : exact; }
        actions = { set_nexthop; }
        default_action = set_nexthop(0);
        size           = DMAC_TABLE_SIZE;
    }


    /*********** NEXTHOP ************/
    action send(PortId_t port) {
        ig_tm_md.ucast_egress_port = port;
    }

    action drop() {
        ig_dprsr_md.drop_ctl = 1;
    }

    action l3_switch(PortId_t port, bit<48> new_mac_da, bit<48> new_mac_sa) {
        hdr.ethernet.dst_addr = new_mac_da;
        hdr.ethernet.src_addr = new_mac_sa;
        ttl_dec = 1;
        send(port);
    }

    table nexthop {
        key = { nexthop_id : exact; }
        actions = { send; drop; l3_switch; }
        size = NEXTHOP_TABLE_SIZE;
    }

    apply {
        if (hdr.mpls[0].isValid()) {
            switch(mpls_decap.apply().action_run) {
                mpls_decap_ipv4 : {
                    if (hdr.ipv4.isValid()) {
                        if (meta.ipv4_csum_err == 0 && hdr.ipv4.ttl > 1) {
                            if (!ipv4_host.apply().hit) {
                                ipv4_lpm.apply();
                            }
                        }
                    }
                }
                mpls_decap_ipv6: {
                    if (hdr.ipv6.isValid()) {
                        if (hdr.ipv6.hop_limit > 1) {
                            if (!ipv6_host.apply().hit) {
                                ipv6_lpm.apply();

                            }
                        }
                    }
                }
                mpls_decap_inner_ethernet: {
                    if (!hdr.inner_ethernet.isValid()) {
                        mpls_resubmit();
                    } else {
                        /* We copied it already */
                        hdr.inner_ethernet.setInvalid();
                        dmac.apply();
                    }
                }
                mpls_transit: {
                    if ((meta.mpls_resubmit.header_info == mpls_circuit_t.ETHERNET && !hdr.inner_ethernet.isValid()) ||
                        (meta.mpls_resubmit.header_info == mpls_circuit_t.IPV4 && !hdr.ipv4.isValid()) ||
                        (meta.mpls_resubmit.header_info == mpls_circuit_t.IPV6 && !hdr.ipv6.isValid())) {
                        mpls_resubmit();
                    } else {
                        dmac.apply();
                    }
                }
            }
        } else {
            /* For non-MPLS packets */
            dmac.apply();
        }

        nexthop.apply();

        if (hdr.ipv4.isValid()) {
            hdr.ipv4.ttl =  hdr.ipv4.ttl |-| ttl_dec;
        } else if (hdr.ipv6.isValid()) {
            hdr.ipv6.hop_limit = hdr.ipv6.hop_limit |-| ttl_dec;
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
    Checksum() ipv4_checksum;
    Resubmit() mpls_resubmit;

    apply {
        if (ig_dprsr_md.resubmit_type == MPLS_RESUBMIT) {
            mpls_resubmit.emit(meta.mpls_resubmit);
        }
        /* Update the IPv4 checksum first */
        if (hdr.ipv4.isValid()) {
            hdr.ipv4.hdr_checksum = ipv4_checksum.update({
                    hdr.ipv4.version,
                    hdr.ipv4.ihl,
                    hdr.ipv4.diffserv,
                    hdr.ipv4.total_len,
                    hdr.ipv4.identification,
                    hdr.ipv4.flags,
                    hdr.ipv4.frag_offset,
                    hdr.ipv4.ttl,
                    hdr.ipv4.protocol,
                    hdr.ipv4.src_addr,
                    hdr.ipv4.dst_addr,
                    hdr.ipv4_options.data
                });
        }

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
    in    egress_intrinsic_metadata_for_deparser_t  eg_dprsr_md,
    in    egress_intrinsic_metadata_t               eg_intr_md,
    in    egress_intrinsic_metadata_from_parser_t   eg_prsr_md)
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
)";
    auto blk = TestCode(TestCode::Hdr::Tofino2arch, program);
    ASSERT_TRUE(blk.apply_pass(TestCode::Pass::FullFrontend));
    ASSERT_TRUE(blk.apply_pass(TestCode::Pass::FullMidend));
    ASSERT_TRUE(blk.apply_pass(TestCode::Pass::ConverterToBackend));
    CheckUninitializedRead::unset_printed();
    testing::internal::CaptureStderr();
    EXPECT_TRUE(blk.apply_pass(TestCode::Pass::FullBackend));
    std::string output = testing::internal::GetCapturedStderr();

    // const_to_phv_8w1 should be initialized by a compiler-inserted table.
    auto res = output.find("warning: const_to_phv_8w1 is read in table Ingress.mpls_decap, but it"
        " is totally or partially uninitialized");
    ASSERT_TRUE(res == std::string::npos);
}

}  // namespace Test
