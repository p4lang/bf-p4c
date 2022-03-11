/*
 * Tests related to the merging of parser states.
 */

#include <boost/algorithm/string/replace.hpp>

#include "gtest/gtest.h"
#include "bf_gtest_helpers.h"

#include "ir/ir.h"
#include "bf-p4c/test/gtest/tofino_gtest_utils.h"
#include "test/gtest/helpers.h"

namespace Test {

/*
 * Verify that compiler-generated stall parser states are not merged during
 * the MergeLoweredParserStates pass.
 *
 * These are the states that contain the following in their name:
 *
 *          $stall_
 *          $ctr_stall_
 *          $oob_stall_
 *          $hdr_len_stop_stall_
 */
TEST(ParserStateMergeTest, DoNotMergeStallStates) {
// P4 program
const char * p4_prog = R"(
header ethernet_t {
    bit<48> dst_addr;
    bit<48> src_addr;
    bit<16> ethertype;
}

header hdr32b_t {
    bit<32> f1;
    bit<32> f2;
    bit<32> f3;
    bit<32> f4;
    bit<32> f5;
    bit<32> f6;
    bit<32> f7;
    bit<32> f8;
};

header hdr_variable_t{
    bit<8>  opt_len;
    bit<8>  pad0;
    bit<16> pad1;
};

header hdr40b_t {
    bit<32> f1;
    bit<32> f2;
    bit<32> f3;
    bit<32> f4;
    bit<32> f5;
    bit<32> f6;
    bit<32> f7;
    bit<32> f8;
    bit<32> f9;
    bit<32> reject;
};

struct headers_t {
    ethernet_t eth;
    hdr32b_t h1;
    hdr_variable_t h2;
    hdr40b_t h3;
}

struct metadata_t {
}

parser IngressParser(
    packet_in pkt,
    out headers_t hdr,
    out metadata_t meta,
    out ingress_intrinsic_metadata_t ig_intr_md) {

    state start {
        pkt.extract(ig_intr_md);
        pkt.advance(PORT_METADATA_SIZE);
        transition accept;
    }
}

parser EgressParser(
    packet_in pkt,
    out headers_t hdr,
    out metadata_t meta,
    out egress_intrinsic_metadata_t eg_intr_md) {

    ParserCounter<>() pctr;

    state start {
        transition parse_ethernet;
    }

    state parse_ethernet {
        pkt.extract(hdr.eth);
        transition select(hdr.eth.ethertype) {
            0xcdef : parse_h1;
            0x1111 : parse_h2;
            0x2222 : parse_h3;
            default : accept;
        }
    }

    state parse_h1 {
        // create $stall
        pkt.advance(320);
        transition accept;
    }

    state parse_h2 {
        pkt.extract(hdr.h2);
        // create $ctr_stall
        pctr.set(hdr.h2.opt_len);
        transition select(pctr.is_zero()) {
            true : accept;
            false : next_option;
        }
    }

    @dont_unroll
    state next_option {
        pctr.decrement(1);
        transition select(pctr.is_zero()) {
            true : accept;
            false : next_option;
        }
    }

    state parse_h3 {
        // create $oob_stall.
        pkt.extract (hdr.h3);
        transition select(hdr.h3.reject) {
            0x1 : accept;
            0x2 : accept;
            default : reject;
        }
    }
}

control Ingress(
    inout headers_t hdr,
    inout metadata_t ig_md,
    in ingress_intrinsic_metadata_t ig_intr_md,
    in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
    inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md,
    inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
    apply {
        ig_intr_tm_md.ucast_egress_port = ig_intr_md.ingress_port;
    }
}

control Egress(
    inout headers_t hdr,
    inout metadata_t meta,
    in egress_intrinsic_metadata_t eg_intr_md,
    in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
    inout egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
    inout egress_intrinsic_metadata_for_output_port_t eg_intr_oport_md) {
    apply {
    }
}

control IngressDeparser(
    packet_out pkt,
    inout headers_t hdr,
    in metadata_t ig_md,
    in ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md) {
    apply {
        pkt.emit(hdr);
    }
}

control EgressDeparser(
    packet_out pkt,
    inout headers_t hdr,
    in metadata_t eg_md,
    in egress_intrinsic_metadata_for_deparser_t eg_intr_dprsr_md) {
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
    EgressDeparser()) pipe;

Switch(pipe) main;)";

    auto blk = TestCode(TestCode::Hdr::Tofino1arch, p4_prog);
    blk.flags(Match::TrimWhiteSpace | Match::TrimAnnotations);

    // TestCode disables min depth limits by default. Re-enable.
    BackendOptions().disable_parse_min_depth_limit = false;

    EXPECT_TRUE(blk.CreateBackend());
    EXPECT_TRUE(blk.apply_pass(TestCode::Pass::FullBackend));

    // Check that stall states are present in the output file.
    auto res =
        blk.match(TestCode::CodeBlock::ParserEAsm,
            Match::CheckList{"parser egress: start", "`.*`", "parse_h1.$stall_0:"});
    EXPECT_TRUE(res.success) << " pos=" << res.pos << " count=" << res.count << "\n'"
                             << blk.extract_code(TestCode::CodeBlock::ParserEAsm) << "'\n";

    res = blk.match(TestCode::CodeBlock::ParserEAsm,
            Match::CheckList{"parser egress: start", "`.*`", "parse_h2.$split_0.$ctr_stall0:"});
    EXPECT_TRUE(res.success) << " pos=" << res.pos << " count=" << res.count << "\n'"
                             << blk.extract_code(TestCode::CodeBlock::ParserEAsm) << "'\n";

    res = blk.match(TestCode::CodeBlock::ParserEAsm,
            Match::CheckList{"parser egress: start", "`.*`", "parse_h3.$oob_stall_0:"});
    EXPECT_TRUE(res.success) << " pos=" << res.pos << " count=" << res.count << "\n'"
                             << blk.extract_code(TestCode::CodeBlock::ParserEAsm) << "'\n";
}

/*
 * P4C-4281: state parse_seg_list could mistakenly be merged because
 *           the loop created along with state parse_segment was
 *           overlooked in the code.  This test makes sure this
 *           is not the case.
 */
TEST(ParserStateMergeTest, ConsiderLoopInMergeDecision) {
const char *p4_prog = R"(
header segment_t {
    bit<128> sid;
}

struct metadata {
}

struct headers {
    segment_t[10]  seg_list;
}

parser ParserI(packet_in packet,
                         out headers hdr,
                         out metadata meta,
                         out ingress_intrinsic_metadata_t ig_intr_md) {
    ParserCounter() pctr;

    state start {
        packet.extract(ig_intr_md);
        packet.advance(PORT_METADATA_SIZE);
        pctr.set(8w4);
        transition parse_segments;
    }

    state parse_seg_list {
        transition select(pctr.is_zero()) {
            true: accept;
            false: parse_segments;
        }
    }

    @dont_unroll
    state parse_segments {
        packet.extract(hdr.seg_list.next);
        pctr.decrement(1);
        transition parse_seg_list;
    }
}

parser ParserE(packet_in packet,
                        out headers hdr,
                        out metadata meta,
                        out egress_intrinsic_metadata_t eg_intr_md) {
    state start {
        packet.extract(eg_intr_md);
        transition accept;
    }
}

control IngressP(
        inout headers hdr,
        inout metadata meta,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
    apply {
            ig_intr_tm_md.ucast_egress_port = 2;
    }
}

control DeparserI(packet_out packet,
                  inout headers hdr,
                  in metadata meta,
                  in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) {
    apply {
        packet.emit(hdr.seg_list);
    }
}

control EgressP(
        inout headers hdr,
        inout metadata meta,
        in egress_intrinsic_metadata_t eg_intr_md,
        in egress_intrinsic_metadata_from_parser_t eg_intr_prsr_md,
        inout egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
        inout egress_intrinsic_metadata_for_output_port_t eg_intr_oport_md) {
    apply { }
}

control DeparserE(packet_out packet,
                           inout headers hdr,
                           in metadata meta,
                           in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {
    apply { }
}

Pipeline(ParserI(),
         IngressP(),
         DeparserI(),
         ParserE(),
         EgressP(),
         DeparserE()) pipe;

Switch(pipe) main;

)";

    auto blk = TestCode(TestCode::Hdr::Tofino1arch, p4_prog);
    blk.flags(Match::TrimWhiteSpace | Match::TrimAnnotations);

    // TestCode disables min depth limits by default. Re-enable.
    BackendOptions().disable_parse_min_depth_limit = false;

    EXPECT_TRUE(blk.CreateBackend());
    EXPECT_TRUE(blk.apply_pass(TestCode::Pass::FullBackend));

    // Check that state parse_seg_list is still present in the output file.
    auto res =
        blk.match(TestCode::CodeBlock::ParserIAsm,
            Match::CheckList{"parser ingress: start", "`.*`", "parse_seg_list:"});
    EXPECT_TRUE(res.success) << " pos=" << res.pos << " count=" << res.count << "\n'"
                             << blk.extract_code(TestCode::CodeBlock::ParserEAsm) << "'\n";
}

}  // namespace Test
