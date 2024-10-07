#if HAVE_FLATROCK
#include <boost/algorithm/string/replace.hpp>

#include "gtest/gtest.h"
#include "bf_gtest_helpers.h"

#include "ir/ir.h"
#include "bf-p4c/test/gtest/tofino_gtest_utils.h"
#include "test/gtest/helpers.h"

namespace P4::Test {

using namespace Match;  // To remove noise & reduce line lengths.

/**
 * Verify that initial pointer is set accordingly when ingress intrinsic metadata are extracted.
 */
TEST(FlatrockParser, IngressIntrinsicMetadata) {
    std::string test_prog = R"(
    header data_h {
        bit<32>     f1;
        bit<32>     f2;
        bit<16>     h1;
        bit<8>      b1;
        bit<8>      b2;
    }
    struct headers {
        data_h       data;
    }
    struct metadata {
    }
    parser ingressParser(packet_in packet, out headers hdrs,
                        out metadata meta, out ingress_intrinsic_metadata_t ig_intr_md) {
        state start {
            packet.extract(ig_intr_md);
            packet.advance(PORT_METADATA_SIZE);
            packet.extract(hdrs.data);
            transition accept;
        }
    }
    control ingress(in headers hdrs, inout metadata meta,
                    in ingress_intrinsic_metadata_t ig_intr_md,
                    inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
        apply {
            ig_intr_tm_md.ucast_egress_pipe = ig_intr_md.ingress_pipe;
            ig_intr_tm_md.ucast_egress_port = ig_intr_md.ingress_port;
        }
    }
    control egress(inout headers hdrs, inout metadata meta,
                in egress_intrinsic_metadata_t eg_intr_md,
                inout egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
                inout egress_intrinsic_metadata_for_output_port_t eg_intr_oport_md)
    {
        apply { }
    }
    control egressDeparser(packet_out packet, inout headers hdrs, in metadata meta,
                        in egress_intrinsic_metadata_t eg_intr_md,
                        in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprs) {
        apply {
            packet.emit(hdrs);
        }
    }
    Pipeline(ingressParser(), ingress(), egress(), egressDeparser()) pipe;
    Switch(pipe) main;
    )";

    auto blk = TestCode(TestCode::Hdr::Tofino5arch, test_prog);
    blk.flags(TrimWhiteSpace | TrimAnnotations);

    EXPECT_TRUE(blk.CreateBackend());
    EXPECT_TRUE(blk.apply_pass(TestCode::Pass::FullBackend));

    auto res =
        blk.match(TestCode::CodeBlock::ParserIAsm,
                  CheckList{"parser ingress:",
                            "`.*`",
                            "initial_ptr:` *`0"});
    EXPECT_TRUE(res.success) << " pos=" << res.pos << " count=" << res.count << "\n'"
                             << blk.extract_code(TestCode::CodeBlock::ParserIAsm) << "'\n";
}

/**
 * Verify that initial pointer is set accordingly when ingress intrinsic metadata are not extracted
 * (or not used and the extraction is optimized out).
 */
TEST(FlatrockParser, NoIngressIntrinsicMetadata) {
    std::string test_prog = R"(
    header data_h {
        bit<32>     f1;
        bit<32>     f2;
        bit<16>     h1;
        bit<8>      b1;
        bit<8>      b2;
    }
    struct headers {
        data_h       data;
    }
    struct metadata {
    }
    parser ingressParser(packet_in packet, out headers hdrs,
                        out metadata meta, out ingress_intrinsic_metadata_t ig_intr_md) {
        state start {
            packet.extract(ig_intr_md);
            packet.advance(PORT_METADATA_SIZE);
            packet.extract(hdrs.data);
            transition accept;
        }
    }
    control ingress(in headers hdrs, inout metadata meta,
                    in ingress_intrinsic_metadata_t ig_intr_md,
                    inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
        apply {
            ig_intr_tm_md.ucast_egress_pipe = 0;
            ig_intr_tm_md.ucast_egress_port = 4;
        }
    }
    control egress(inout headers hdrs, inout metadata meta,
                in egress_intrinsic_metadata_t eg_intr_md,
                inout egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
                inout egress_intrinsic_metadata_for_output_port_t eg_intr_oport_md)
    {
        apply { }
    }
    control egressDeparser(packet_out packet, inout headers hdrs, in metadata meta,
                        in egress_intrinsic_metadata_t eg_intr_md,
                        in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprs) {
        apply {
            packet.emit(hdrs);
        }
    }
    Pipeline(ingressParser(), ingress(), egress(), egressDeparser()) pipe;
    Switch(pipe) main;
    )";

    auto blk = TestCode(TestCode::Hdr::Tofino5arch, test_prog);
    blk.flags(TrimWhiteSpace | TrimAnnotations);

    EXPECT_TRUE(blk.CreateBackend());
    EXPECT_TRUE(blk.apply_pass(TestCode::Pass::FullBackend));

    auto res =
        blk.match(TestCode::CodeBlock::ParserIAsm,
                  CheckList{"parser ingress:",
                            "`.*`",
                            "initial_ptr:` *`0"});
    EXPECT_TRUE(res.success) << " pos=" << res.pos << " count=" << res.count << "\n'"
                             << blk.extract_code(TestCode::CodeBlock::ParserIAsm) << "'\n";
}

/**
 * Verify that there is an egress parser section present if there are any extracted fields
 * used in egress control block.
 */
TEST(FlatrockParser, PseudoParserExtraction) {
    std::string test_prog = R"(
    header data_h {
        bit<32>     f1;
        bit<32>     f2;
        bit<16>     h1;
        bit<8>      b1;
        bit<8>      b2;
    }
    struct headers {
        data_h       data;
    }
    struct metadata {
    }
    parser ingressParser(packet_in packet, out headers hdrs,
                        out metadata meta, out ingress_intrinsic_metadata_t ig_intr_md) {
        state start {
            packet.extract(ig_intr_md);
            packet.advance(PORT_METADATA_SIZE);
            packet.extract(hdrs.data);
            transition accept;
        }
    }
    control ingress(in headers hdrs, inout metadata meta,
                    in ingress_intrinsic_metadata_t ig_intr_md,
                    inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
        apply { }
    }
    control egress(inout headers hdrs, inout metadata meta,
                in egress_intrinsic_metadata_t eg_intr_md,
                inout egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
                inout egress_intrinsic_metadata_for_output_port_t eg_intr_oport_md)
    {
        apply {
            hdrs.data.f1 = hdrs.data.f2;
        }
    }
    control egressDeparser(packet_out packet, inout headers hdrs, in metadata meta,
                        in egress_intrinsic_metadata_t eg_intr_md,
                        in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprs) {
        apply {
            packet.emit(hdrs);
        }
    }
    Pipeline(ingressParser(), ingress(), egress(), egressDeparser()) pipe;
    Switch(pipe) main;
    )";

    auto blk = TestCode(TestCode::Hdr::Tofino5arch, test_prog);
    blk.flags(TrimWhiteSpace | TrimAnnotations);

    EXPECT_TRUE(blk.CreateBackend());
    EXPECT_TRUE(blk.apply_pass(TestCode::Pass::FullBackend));

    auto res =
        blk.match(TestCode::CodeBlock::ParserEAsm,
                  CheckList{"parser egress:",
                            "`.*`",
                            "packet32 hdrs.data `(W\\d+)` msb_offset `\\d+`",
                            "`.*`",
                            "#`.*``\\1` bit[`\\d+`..`\\d+`]: hdrs.data.f2"});
    EXPECT_TRUE(res.success) << " pos=" << res.pos << " count=" << res.count << "\n'"
                             << blk.extract_code(TestCode::CodeBlock::ParserEAsm) << "'\n";
}

std::string constant_test_input(const char *assignment){
    return R"(
    header data_h {
        bit<64>     d1;
        bit<32>     f1;
        bit<32>     f2;
        bit<16>     h1;
        bit<8>      b1;
        bit<8>      b2;
    }
    struct headers {
        data_h       data;
    }
    struct metadata {
    }
    parser ingressParser(packet_in packet, out headers hdrs,
                        out metadata meta, out ingress_intrinsic_metadata_t ig_intr_md) {
        state start {
            packet.extract(ig_intr_md);
            packet.advance(PORT_METADATA_SIZE);
            packet.extract(hdrs.data);
    )" + std::string(assignment) +
           R"(     
            transition accept;
        }
    }
    control ingress(in headers hdrs, inout metadata meta,
                    in ingress_intrinsic_metadata_t ig_intr_md,
                    inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
        apply {
            ig_intr_tm_md.ucast_egress_pipe = 0;
            ig_intr_tm_md.ucast_egress_port = 4;
        }
    }
    control egress(inout headers hdrs, inout metadata meta,
                in egress_intrinsic_metadata_t eg_intr_md,
                inout egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
                inout egress_intrinsic_metadata_for_output_port_t eg_intr_oport_md)
    {
        apply { }
    }
    control egressDeparser(packet_out packet, inout headers hdrs, in metadata meta,
                        in egress_intrinsic_metadata_t eg_intr_md,
                        in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprs) {
        apply {
            packet.emit(hdrs);
        }
    }
    Pipeline(ingressParser(), ingress(), egress(), egressDeparser()) pipe;
    Switch(pipe) main;
    )";
}

TEST(FlatrockParser, OneByteConstant) {
    const auto input = constant_test_input("hdrs.data.b1 = 8w42;\n");
    auto blk = TestCode(TestCode::Hdr::Tofino5arch, input);
    blk.flags(TrimWhiteSpace | TrimAnnotations);

    EXPECT_TRUE(blk.CreateBackend());
    EXPECT_TRUE(blk.apply_pass(TestCode::Pass::FullBackend));

    auto res =
        blk.match(TestCode::CodeBlock::ParserEAsm,
                  CheckList{"parser egress:", "`.*`", "phv_builder_group `\\d{1,2}`:", "`.*`",
                            "extract `\\d{1,2}`:", "`.*`", "- {`.*`B`\\d{1,2}`: constant 42`.*`}"});
    EXPECT_TRUE(res.success) << " pos=" << res.pos << " count=" << res.count << "\n'"
                             << blk.extract_code(TestCode::CodeBlock::ParserIAsm) << "'\n";
}

TEST(FlatrockParser, FourByteConstant) {
    const auto input = constant_test_input("hdrs.data.f1 = 8w1 ++ 8w2 ++ 8w3 ++ 8w4;\n");
    auto blk = TestCode(TestCode::Hdr::Tofino5arch, input);
    blk.flags(TrimWhiteSpace | TrimAnnotations);

    EXPECT_TRUE(blk.CreateBackend());
    EXPECT_TRUE(blk.apply_pass(TestCode::Pass::FullBackend));

    auto res =
        blk.match(TestCode::CodeBlock::ParserEAsm,
                  CheckList{"parser egress:", "`.*`", "phv_builder_group `\\d{1,2}`:", "`.*`",
                            "extract `\\d{1,2}`:", "`.*`",
                            "- {`.*`W`(\\d{1,2})`(0..7): constant 4`.*`"
                            "W`\\1`(8..15): constant 3`.*`"
                            "W`\\1`(16..23): constant 2`.*`"
                            "W`\\1`(24..31): constant 1`.*`}"});
    EXPECT_TRUE(res.success) << " pos=" << res.pos << " count=" << res.count << "\n'"
                             << blk.extract_code(TestCode::CodeBlock::ParserEAsm) << "'\n";
}

TEST(FlatrockParser, EightByteConstant) {
    const auto input = constant_test_input("hdrs.data.d1 = 16w1 ++ 16w2 ++ 16w3 ++ 16w4;\n");
    auto blk = TestCode(TestCode::Hdr::Tofino5arch, input);
    blk.flags(TrimWhiteSpace | TrimAnnotations);

    EXPECT_TRUE(blk.CreateBackend());
    EXPECT_TRUE(blk.apply_pass(TestCode::Pass::FullBackend));

    auto res =
        blk.match(TestCode::CodeBlock::ParserEAsm,
                  CheckList{"parser egress:", "`.*`", "phv_builder_group `\\d{1,2}`:", "`.*`",
                            "extract `\\d{1,2}`:", "`.*`",
                            "- {`.*`W`(\\d{1,2})`(0..7): constant 4`.*`"
                            "W`\\1`(8..15): constant 0`.*`"
                            "W`\\1`(16..23): constant 3`.*`"
                            "W`\\1`(24..31): constant 0`.*`}",
                            "`.*`",
                            "- {`.*`W`(\\d{1,2})`(0..7): constant 2`.*`"
                            "W`\\2`(8..15): constant 0`.*`"
                            "W`\\2`(16..23): constant 1`.*`"
                            "W`\\2`(24..31): constant 0`.*`}"});
    EXPECT_TRUE(res.success) << " pos=" << res.pos << " count=" << res.count << "\n'"
                             << blk.extract_code(TestCode::CodeBlock::ParserEAsm) << "'\n";
}

/**
 * Verify that sections for analyzer stages and rules contain correct data in a simple
 * scenario with a select expression and multiple transitions.
 */
TEST(FlatrockParser, AnalyzerMultipleTransitions) {
    std::string test_prog = R"(
    header hdr_1_h {
        bit<32>     f1;
        bit<32>     f2;
        bit<16>     h1;
        bit<8>      b1;
        bit<8>      b2;
    }
    header hdr_2_h {
        bit<8>      b1;
        bit<8>      b2;
    }
    header hdr_3_h {
        bit<16>     h1;
        bit<16>     h2;
    }
    struct headers {
        hdr_1_h     h1;
        hdr_2_h     h2;
        hdr_3_h     h3;
    }
    struct metadata {
    }
    parser ingressParser(packet_in packet, out headers hdrs,
                         out metadata meta, out ingress_intrinsic_metadata_t ig_intr_md) {
        state start {
            packet.extract(ig_intr_md);
            packet.advance(PORT_METADATA_SIZE);
            packet.extract(hdrs.h1);
            transition select(hdrs.h1.h1) {
                16w0x0001 : parse_h2;
                16w0x0002 : parse_h3;
                default :  accept;
            }
        }
        state parse_h2 {
            packet.extract(hdrs.h2);
            transition parse_h3;
        }
        state parse_h3 {
            packet.extract(hdrs.h3);
            transition accept;
        }
    }
    control ingress(in headers hdrs, inout metadata meta,
                    in ingress_intrinsic_metadata_t ig_intr_md,
                    inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
        apply {
            ig_intr_tm_md.ucast_egress_pipe = ig_intr_md.ingress_pipe;
            ig_intr_tm_md.ucast_egress_port = ig_intr_md.ingress_port;
        }
    }
    control egress(inout headers hdrs, inout metadata meta,
                   in egress_intrinsic_metadata_t eg_intr_md,
                   inout egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
                   inout egress_intrinsic_metadata_for_output_port_t eg_intr_oport_md) {
        apply { }
    }
    control egressDeparser(packet_out packet, inout headers hdrs, in metadata meta,
                           in egress_intrinsic_metadata_t eg_intr_md,
                           in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprs) {
        apply {
            packet.emit(hdrs);
        }
    }
    Pipeline(ingressParser(), ingress(), egress(), egressDeparser()) pipe;
    Switch(pipe) main;
    )";

    auto blk = TestCode(TestCode::Hdr::Tofino5arch, test_prog);
    blk.flags(TrimWhiteSpace | TrimAnnotations);

    EXPECT_TRUE(blk.CreateBackend());
    EXPECT_TRUE(blk.apply_pass(TestCode::Pass::FullBackend));

    auto res = blk.match(TestCode::CodeBlock::HdrAsm, CheckList{
        "hdr:",
        "map:",
        "hdrs.h1: 1",
        "hdrs.h2: 2",
        "hdrs.h3: 3",
        "ig_intr_md: 0",
        "payload: 254",
        "seq:",
        "0: [ig_intr_md, hdrs.h1, hdrs.h2, hdrs.h3, payload]",
        "1: [ig_intr_md, hdrs.h1, payload]",
        "len:",
        "ig_intr_md: { base_len: 8, num_comp_bits: 0, scale: 0 }",
        "hdrs.h1: { base_len: 12, num_comp_bits: 0, scale: 0 }",
        "hdrs.h2: { base_len: 2, num_comp_bits: 0, scale: 0 }",
        "hdrs.h3: { base_len: 4, num_comp_bits: 0, scale: 0 }",
        "payload: { base_len: 0, num_comp_bits: 0, scale: 0 }"
    });
    EXPECT_TRUE(res.success) << " pos=" << res.pos << " count=" << res.count << "\n'"
                             << blk.extract_code(TestCode::CodeBlock::HdrAsm) << "'\n";

    res = blk.match(TestCode::CodeBlock::ParserIAsm, CheckList{
        "parser ingress:",
        "states:",
        "$entry_point: 0x**************00",
        "$final: 0x**************06",
        "parse_h2: 0x**************04",
        "parse_h3: 0x**************05",
        "start: 0x**************01",
        "start.$oob_stall_0: 0x**************02",
        "start.$split_0: 0x**************03",
        "profile 0:",
        "match_port: 0o**",
        "match_inband_metadata: 0x****************",
        "initial_pktlen: 0",
        "initial_seglen: 0",
        "initial_state: $entry_point",
        "initial_ptr: ` *`0",
        "metadata_select: [ port_metadata 15, port_metadata 14, inband_metadata 2, ",
        "inband_metadata 3, inband_metadata 4, inband_metadata 5, inband_metadata 6, ",
        "inband_metadata 7 ]",
        "analyzer_stage 0 $entry_point:",
        "rule 0:",
        "match_w0: 0x****",
        "match_w1: 0x****",
        "next_state: start",
        "next_alu0_instruction: { opcode: 0, add: 0 } ` *`# ptr += 0",
        "next_alu1_instruction: { opcode: noop } ` *`# noop",
        "analyzer_stage 1 start:",
        "rule 0:",
        "match_w0: 0x****",
        "match_w1: 0x****",
        "next_state: start.$oob_stall_0",
        "next_alu0_instruction: { opcode: 0, add: 32 } ` *`# ptr += 32",
        "next_alu1_instruction: { opcode: noop } ` *`# noop",
        "modify_flag0: { set: 11 }",
        "push_hdr_id: { hdr: 0, offset: 224 }",
        "analyzer_stage 2 start.$oob_stall_0:",
        "rule 0:",
        "match_w0: 0x****",
        "match_w1: 0x****",
        "next_state: start.$split_0",
        "next_w0_offset: 8",
        "next_alu0_instruction: { opcode: 0, add: 0 } ` *`# ptr += 0",
        "next_alu1_instruction: { opcode: noop } ` *`# noop",
        "analyzer_stage 3 start.$split_0:",
        "rule 0:",
        "match_w0: 0x****",
        "match_w1: 0x****",
        "next_state: $final",
        "next_alu0_instruction: { opcode: 0, add: 12 } ` *`# ptr += 12",
        "next_alu1_instruction: { opcode: noop } ` *`# noop",
        "modify_flag0: { set: 8 }",
        "push_hdr_id: { hdr: 1, offset: 244 }",
        "rule 1:",
        "match_w0: 0x0002",
        "match_w1: 0x****",
        "next_state: parse_h3",
        "next_alu0_instruction: { opcode: 0, add: 12 } ` *`# ptr += 12",
        "next_alu1_instruction: { opcode: noop } ` *`# noop",
        "modify_flag0: { set: 8 }",
        "push_hdr_id: { hdr: 1, offset: 244 }",
        "rule 2:",
        "match_w0: 0x0001",
        "match_w1: 0x****",
        "next_state: parse_h2",
        "next_alu0_instruction: { opcode: 0, add: 12 } ` *`# ptr += 12",
        "next_alu1_instruction: { opcode: noop } ` *`# noop",
        "modify_flag0: { set: 8 }",
        "push_hdr_id: { hdr: 1, offset: 244 }",
        "analyzer_stage 4 parse_h2:",
        "rule 0:",
        "match_w0: 0x****",
        "match_w1: 0x****",
        "next_state: parse_h3",
        "next_alu0_instruction: { opcode: 0, add: 2 } ` *`# ptr += 2",
        "next_alu1_instruction: { opcode: noop } ` *`# noop",
        "modify_flag0: { set: 9 }",
        "push_hdr_id: { hdr: 2, offset: 254 }",
        "analyzer_stage 5 parse_h3:",
        "rule 0:",
        "match_w0: 0x****",
        "match_w1: 0x****",
        "next_state: $final",
        "next_alu0_instruction: { opcode: 0, add: 4 } ` *`# ptr += 4",
        "next_alu1_instruction: { opcode: noop } ` *`# noop",
        "modify_flag0: { set: 10 }",
        "push_hdr_id: { hdr: 3, offset: 252 }",
        "analyzer_stage 6 $final:",
        "rule 0:",
        "match_w0: 0x****",
        "match_w1: 0x****",
        "next_alu0_instruction: { opcode: noop } ` *`# noop",
        "next_alu1_instruction: { opcode: noop } ` *`# noop",
        "push_hdr_id: { hdr: 254, offset: 0 }"
    });
    EXPECT_TRUE(res.success) << " pos=" << res.pos << " count=" << res.count << "\n'"
                             << blk.extract_code(TestCode::CodeBlock::ParserIAsm) << "'\n";
}

/**
 * Verify that sections for analyzer stages and rules contain correct data when multiple
 * select fields and fields wider than 16b are used
 */
TEST(FlatrockParser, AnalyzerWiderSelects) {
    std::string test_prog = R"(
    // This test multiple different uses of wide/multi-field select:
    // Discontinued 24b+4b separated by 3 bits (= second one not aligned)
    header hdr_1_h {
        bit<8>      pad1;
        bit<24>     f1;
        bit<3>      sep1;
        bit<4>      f2;
        bit<1>      pad2;
    }
    // Discontinued 2b+18b+6b separated by 1+2 bits (= second split + 2x merge + unaligned)
    header hdr_2_h {
        bit<2>      sep1;
        bit<2>      f1;
        bit<1>      sep2;
        bit<18>     f2;
        bit<2>      sep3;
        bit<6>      f3;
        bit<1>      pad1;
    }
    header final_hdr_h {
        bit<32>     pad1;
    }
    struct headers {
        hdr_1_h     h1;
        hdr_2_h     h2;
        final_hdr_h final_h;
    }
    struct metadata {
    }

    parser ingressParser(packet_in packet, out headers hdrs,
                        out metadata meta, out ingress_intrinsic_metadata_t ig_intr_md) {
        state start {
            packet.extract(ig_intr_md);
            packet.advance(PORT_METADATA_SIZE);
            packet.extract(hdrs.h1);
            // Discontinued 24b+4b separated by 3 bits (= second one not aligned)
            // Additionally swapped fields compared to packet order
            transition select(hdrs.h1.f2, hdrs.h1.f1) {
                (0x5, 0x777766) : parse_h2;  // W0=0x7777, W1=0b01100110***0101*
                default :  accept;
            }
        }

        state parse_h2 {
            packet.extract(hdrs.h2);
            // Discontinued 2b+18b+6b separated by 1+2 bits (= second split + 2x merge + unaligned)
            // Additionally swapped fields compared to packet order
            transition select(hdrs.h2.f3, hdrs.h2.f1, hdrs.h2.f2) {
                (0x07, 0x2, 0x3abcd) : parse_final_h;   // W0=0b**10*11101010111, W1=0b1001101**000111*
                default :  accept;
            }
        }

        state parse_final_h {
            packet.extract(hdrs.final_h);
            transition accept;
        }

    }
    control ingress(in headers hdrs, inout metadata meta,
                    in ingress_intrinsic_metadata_t ig_intr_md,
                    inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
        apply {
            ig_intr_tm_md.ucast_egress_pipe = ig_intr_md.ingress_pipe;
            ig_intr_tm_md.ucast_egress_port = ig_intr_md.ingress_port;
        }
    }
    control egress(inout headers hdrs, inout metadata meta,
                in egress_intrinsic_metadata_t eg_intr_md,
                inout egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
                inout egress_intrinsic_metadata_for_output_port_t eg_intr_oport_md) {
        apply {
        }
    }
    control egressDeparser(packet_out packet, inout headers hdrs, in metadata meta,
                        in egress_intrinsic_metadata_t eg_intr_md,
                        in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprs) {
        apply {
            packet.emit(hdrs);
        }
    }

    Pipeline(ingressParser(), ingress(), egress(), egressDeparser()) pipe;
    Switch(pipe) main;
    )";

    auto blk = TestCode(TestCode::Hdr::Tofino5arch, test_prog);
    blk.flags(TrimWhiteSpace | TrimAnnotations);

    EXPECT_TRUE(blk.CreateBackend());
    EXPECT_TRUE(blk.apply_pass(TestCode::Pass::FullBackend));

    auto res = blk.match(TestCode::CodeBlock::ParserIAsm, CheckList{
        "parser ingress:",
        "states:",
        "$entry_point: 0x**************00",
        "$final: 0x**************06",
        "parse_final_h: 0x**************05",
        "parse_h2: 0x**************04",
        "start: 0x**************01",
        "start.$oob_stall_0: 0x**************02",
        "start.$split_0: 0x**************03",
        "profile 0:",
        "match_port: 0o**",
        "match_inband_metadata: 0x****************",
        "initial_pktlen: 0",
        "initial_seglen: 0",
        "initial_state: $entry_point",
        "initial_ptr: 0",
        "metadata_select: [",
        "port_metadata 15,",
        "port_metadata 14,",
        "inband_metadata 2,",
        "inband_metadata 3,",
        "inband_metadata 4,",
        "inband_metadata 5,",
        "inband_metadata 6,",
        "inband_metadata 7 ]",
        "analyzer_stage 0",
        "$entry_point:",
        "rule 0:",
        "match_w0: 0x****",
        "match_w1: 0x****",
        "next_state: start",
        "next_alu0_instruction: { opcode: 0, add: 0 } # ptr += 0",
        "next_alu1_instruction: { opcode: noop } # noop",
        "analyzer_stage 1",
        "start: rule 0:",
        "match_w0: 0x****",
        "match_w1: 0x****",
        "next_state: start.$oob_stall_0",
        "next_alu0_instruction: { opcode: 0, add: 32 } # ptr += 32",
        "next_alu1_instruction: { opcode: noop } # noop",
        "modify_flag0: { set: 11 }",
        "push_hdr_id: { hdr: 0, offset: 224 }",
        "analyzer_stage 2",
        "start.$oob_stall_0:",
        "rule 0:",
        "match_w0: 0x****",
        "match_w1: 0x****",
        "next_state: start.$split_0",
        "next_w0_offset: 1",
        "next_w1_offset: 3",
        "next_alu0_instruction: { opcode: 0, add: 0 } # ptr += 0",
        "next_alu1_instruction: { opcode: noop } # noop",
        "analyzer_stage 3",
        "start.$split_0:",
        "rule 0:",
        "match_w0: 0x****",
        "match_w1: 0x****",
        "next_state: $final",
        "next_alu0_instruction: { opcode: 0, add: 5 } # ptr += 5",
        "next_alu1_instruction: { opcode: noop } # noop",
        "modify_flag0: { set: 8 }",
        "push_hdr_id: { hdr: 1, offset: 251 }",
        "rule 1:",
        "match_w0: 0x7777",
        "match_w1: 0b01100110***0101*",
        "next_state: parse_h2",
        "next_w0_offset: 5",
        "next_w1_offset: 7",
        "next_alu0_instruction: { opcode: 0, add: 5 } # ptr += 5",
        "next_alu1_instruction: { opcode: noop } # noop",
        "modify_flag0: { set: 8 }",
        "push_hdr_id: { hdr: 1, offset: 251 }",
        "analyzer_stage 4",
        "parse_h2:",
        "rule 0:",
        "match_w0: 0x****",
        "match_w1: 0x****",
        "next_state: $final",
        "next_alu0_instruction: { opcode: 0, add: 4 } # ptr += 4",
        "next_alu1_instruction: { opcode: noop } # noop",
        "modify_flag0: { set: 9 }",
        "push_hdr_id: { hdr: 2, offset: 252 }",
        "rule 1:",
        "match_w0: 0b**10*11101010111",
        "match_w1: 0b1001101**000111*"
    });
    EXPECT_TRUE(res.success) << " pos=" << res.pos << " count=" << res.count << "\n'"
                             << blk.extract_code(TestCode::CodeBlock::ParserIAsm) << "'\n";
}

/**
 * Verify that sections for phv builder group extracts and deparser ingress (Metadata Packer)
 * contain correct values for extractions of POV flags.
 */
TEST(FlatrockParser, PovFlagsExtraction) {
    std::string test_prog = R"(
    header hdr_1_h {
        bit<32>     f1;
        bit<32>     f2;
        bit<16>     h1;
        bit<8>      b1;
        bit<8>      b2;
    }
    header hdr_2_h {
        bit<8>      b1;
        bit<8>      b2;
    }
    header hdr_3_h {
        bit<16>     h1;
    }
    struct headers {
        hdr_1_h     h1;
        hdr_2_h     h2;
        hdr_3_h     h3;
        hdr_3_h     h4;
        hdr_3_h     h5;
        hdr_3_h     h6;
        hdr_3_h     h7;
        hdr_3_h     h8;
        hdr_3_h     h9;
        hdr_3_h     h10;
        hdr_3_h     h11;
        hdr_3_h     h12;
        hdr_3_h     h13;
        hdr_3_h     h14;
        hdr_3_h     h15;
    }
    struct metadata {
    }

    parser ingressParser(packet_in packet, out headers hdrs,
                         out metadata meta, out ingress_intrinsic_metadata_t ig_intr_md) {
        state start {
            packet.extract(ig_intr_md);
            packet.advance(PORT_METADATA_SIZE);
            packet.extract(hdrs.h1);
            transition select(hdrs.h1.h1) {
                0x0001 : parse_h2;
                0x0002 : parse_all;
                default :  accept;
            }
        }
        state parse_h2 {
            packet.extract(hdrs.h2);
            transition accept;
        }
        state parse_all {
            hdrs.h1.setInvalid();
            packet.extract(hdrs.h2);
            packet.extract(hdrs.h3);
            packet.extract(hdrs.h4);
            packet.extract(hdrs.h5);
            packet.extract(hdrs.h6);
            packet.extract(hdrs.h7);
            packet.extract(hdrs.h8);
            packet.extract(hdrs.h9);
            packet.extract(hdrs.h10);
            packet.extract(hdrs.h11);
            packet.extract(hdrs.h12);
            packet.extract(hdrs.h13);
            packet.extract(hdrs.h14);
            packet.extract(hdrs.h15);
            transition accept;
        }
    }
    control ingress(in headers hdrs, inout metadata meta,
                    in ingress_intrinsic_metadata_t ig_intr_md,
                    inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
        apply {
            ig_intr_tm_md.ucast_egress_pipe = (PipeId_t)hdrs.h2.b1;
            ig_intr_tm_md.ucast_egress_port = (PortId_t)hdrs.h2.b2;
        }
    }
    control egress(inout headers hdrs, inout metadata meta,
                   in egress_intrinsic_metadata_t eg_intr_md,
                   inout egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
                   inout egress_intrinsic_metadata_for_output_port_t eg_intr_oport_md) {
        apply {
        }
    }
    control egressDeparser(packet_out packet, inout headers hdrs, in metadata meta,
                           in egress_intrinsic_metadata_t eg_intr_md,
                           in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprs) {
        apply {
            packet.emit(hdrs);
        }
    }

    Pipeline(ingressParser(), ingress(), egress(), egressDeparser()) pipe;
    Switch(pipe) main;
    )";

    auto blk = TestCode(TestCode::Hdr::Tofino5arch, test_prog);
    blk.flags(TrimWhiteSpace | TrimAnnotations);

    EXPECT_TRUE(blk.CreateBackend());
    EXPECT_TRUE(blk.apply_pass(TestCode::Pass::FullBackend));

    auto res = blk.match(TestCode::CodeBlock::ParserIAsm, CheckList{
        "parser ingress:",
        "`.*`",
        "phv_builder_group 0:",
        "pov_select: [ ]",
        "extract 0:",
        "match: 0x********",
        "source:",
        "- { B1: pov_flags 1 }",
        "# POV flags bit[8] -> B1 bit[0]: hdrs.h1.$valid",
        "- { }",
        "phv_builder_group 16:",
        "pov_select: [ flags 2 ]",
        "extract 0:",
        "match: 0x********",
        "source:",
        "- { H0(0..7): pov_flags 2, H0(8..15): pov_flags 3 }",
        "# POV flags bit[16] -> H0 bit[0]: hdrs.h2.$valid",
        "# POV flags bit[17] -> H0 bit[1]: hdrs.h3.$valid",
        "# POV flags bit[18] -> H0 bit[2]: hdrs.h4.$valid",
        "# POV flags bit[19] -> H0 bit[3]: hdrs.h5.$valid",
        "# POV flags bit[20] -> H0 bit[4]: hdrs.h6.$valid",
        "# POV flags bit[21] -> H0 bit[5]: hdrs.h7.$valid",
        "# POV flags bit[22] -> H0 bit[6]: hdrs.h8.$valid",
        "# POV flags bit[23] -> H0 bit[7]: hdrs.h9.$valid",
        "# POV flags bit[24] -> H0 bit[8]: hdrs.h10.$valid",
        "# POV flags bit[25] -> H0 bit[9]: hdrs.h11.$valid",
        "# POV flags bit[26] -> H0 bit[10]: hdrs.h12.$valid",
        "# POV flags bit[27] -> H0 bit[11]: hdrs.h13.$valid",
        "# POV flags bit[28] -> H0 bit[12]: hdrs.h14.$valid",
        "# POV flags bit[29] -> H0 bit[13]: hdrs.h15.$valid",
        "- { }",
        "extract 1:",
        "match: 0b*******************************1",
        "source:",
        "- { H0(0..7): pov_flags 2, H0(8..15): pov_flags 3 }",
        "# POV flags bit[16] -> H0 bit[0]: hdrs.h2.$valid",
        "# POV flags bit[17] -> H0 bit[1]: hdrs.h3.$valid",
        "# POV flags bit[18] -> H0 bit[2]: hdrs.h4.$valid",
        "# POV flags bit[19] -> H0 bit[3]: hdrs.h5.$valid",
        "# POV flags bit[20] -> H0 bit[4]: hdrs.h6.$valid",
        "# POV flags bit[21] -> H0 bit[5]: hdrs.h7.$valid",
        "# POV flags bit[22] -> H0 bit[6]: hdrs.h8.$valid",
        "# POV flags bit[23] -> H0 bit[7]: hdrs.h9.$valid",
        "# POV flags bit[24] -> H0 bit[8]: hdrs.h10.$valid",
        "# POV flags bit[25] -> H0 bit[9]: hdrs.h11.$valid",
        "# POV flags bit[26] -> H0 bit[10]: hdrs.h12.$valid",
        "# POV flags bit[27] -> H0 bit[11]: hdrs.h13.$valid",
        "# POV flags bit[28] -> H0 bit[12]: hdrs.h14.$valid",
        "# POV flags bit[29] -> H0 bit[13]: hdrs.h15.$valid",
        "- packet16 hdrs.h2 [ H2 msb_offset 0 ]",
        "# bit[0..7] -> H2 bit[15..8]: hdrs.h2.b1",
        "# bit[8..15] -> H2 bit[7..0]: hdrs.h2.b2"
    });
    EXPECT_TRUE(res.success) << " pos=" << res.pos << " count=" << res.count << "\n'"
                             << blk.extract_code(TestCode::CodeBlock::ParserIAsm) << "'\n";

    res = blk.match(TestCode::CodeBlock::DeparserIAsm, CheckList{
        "deparser ingress:",
        "`.*`",
        "pov: [B3, B1, H0(0..7), H0(8..15)]",
        "# B3: # ig_intr_md_for_tm.$zero",
        "# B1: # bit[0]: hdrs.h1.$valid",
        "# H0(0..7):",
        "# - bit[0]: hdrs.h2.$valid",
        "# - bit[1]: hdrs.h3.$valid",
        "# - bit[2]: hdrs.h4.$valid",
        "# - bit[3]: hdrs.h5.$valid",
        "# - bit[4]: hdrs.h6.$valid",
        "# - bit[5]: hdrs.h7.$valid",
        "# - bit[6]: hdrs.h8.$valid",
        "# - bit[7]: hdrs.h9.$valid",
        "# H0(8..15):",
        "# - bit[8]: hdrs.h10.$valid",
        "# - bit[9]: hdrs.h11.$valid",
        "# - bit[10]: hdrs.h12.$valid",
        "# - bit[11]: hdrs.h13.$valid",
        "# - bit[12]: hdrs.h14.$valid",
        "# - bit[13]: hdrs.h15.$valid"
    });
    EXPECT_TRUE(res.success) << " pos=" << res.pos << " count=" << res.count << "\n'"
                             << blk.extract_code(TestCode::CodeBlock::DeparserIAsm) << "'\n";

    res = blk.match(TestCode::CodeBlock::ParserEAsm, CheckList{
        "parser egress:",
        "`.*`",
        "phv_builder_group 0:",
        "pov_select: [ ]",
        "extract 0:",
        "match: 0x********",
        "source:",
        "- { B1: pov_flags 1 }",
        "# POV flags bit[8] -> B1 bit[0]: hdrs.h1.$valid",
        "- { }",
        "phv_builder_group 16:",
        "pov_select: [ flags 2 ]",
        "extract 0:",
        "match: 0x********",
        "source:",
        "- { H0(0..7): pov_flags 2, H0(8..15): pov_flags 3 }",
        "# POV flags bit[16] -> H0 bit[0]: hdrs.h2.$valid",
        "# POV flags bit[17] -> H0 bit[1]: hdrs.h3.$valid",
        "# POV flags bit[18] -> H0 bit[2]: hdrs.h4.$valid",
        "# POV flags bit[19] -> H0 bit[3]: hdrs.h5.$valid",
        "# POV flags bit[20] -> H0 bit[4]: hdrs.h6.$valid",
        "# POV flags bit[21] -> H0 bit[5]: hdrs.h7.$valid",
        "# POV flags bit[22] -> H0 bit[6]: hdrs.h8.$valid",
        "# POV flags bit[23] -> H0 bit[7]: hdrs.h9.$valid",
        "# POV flags bit[24] -> H0 bit[8]: hdrs.h10.$valid",
        "# POV flags bit[25] -> H0 bit[9]: hdrs.h11.$valid",
        "# POV flags bit[26] -> H0 bit[10]: hdrs.h12.$valid",
        "# POV flags bit[27] -> H0 bit[11]: hdrs.h13.$valid",
        "# POV flags bit[28] -> H0 bit[12]: hdrs.h14.$valid",
        "# POV flags bit[29] -> H0 bit[13]: hdrs.h15.$valid",
        "- { }",
        "extract 1:",
        "match: 0b*******************************1",
        "source:",
        "- { H0(0..7): pov_flags 2, H0(8..15): pov_flags 3 }",
        "# POV flags bit[16] -> H0 bit[0]: hdrs.h2.$valid",
        "# POV flags bit[17] -> H0 bit[1]: hdrs.h3.$valid",
        "# POV flags bit[18] -> H0 bit[2]: hdrs.h4.$valid",
        "# POV flags bit[19] -> H0 bit[3]: hdrs.h5.$valid",
        "# POV flags bit[20] -> H0 bit[4]: hdrs.h6.$valid",
        "# POV flags bit[21] -> H0 bit[5]: hdrs.h7.$valid",
        "# POV flags bit[22] -> H0 bit[6]: hdrs.h8.$valid",
        "# POV flags bit[23] -> H0 bit[7]: hdrs.h9.$valid",
        "# POV flags bit[24] -> H0 bit[8]: hdrs.h10.$valid",
        "# POV flags bit[25] -> H0 bit[9]: hdrs.h11.$valid",
        "# POV flags bit[26] -> H0 bit[10]: hdrs.h12.$valid",
        "# POV flags bit[27] -> H0 bit[11]: hdrs.h13.$valid",
        "# POV flags bit[28] -> H0 bit[12]: hdrs.h14.$valid",
        "# POV flags bit[29] -> H0 bit[13]: hdrs.h15.$valid"
    });
    EXPECT_TRUE(res.success) << " pos=" << res.pos << " count=" << res.count << "\n'"
                             << blk.extract_code(TestCode::CodeBlock::ParserEAsm) << "'\n";
}

}  // namespace P4::Test
#endif  // HAVE_FLATROCK
