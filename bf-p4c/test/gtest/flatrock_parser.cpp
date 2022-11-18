#include <boost/algorithm/string/replace.hpp>

#include "gtest/gtest.h"
#include "bf_gtest_helpers.h"

#include "ir/ir.h"
#include "bf-p4c/test/gtest/tofino_gtest_utils.h"
#include "test/gtest/helpers.h"

namespace Test {

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
                            "- {`.*`W`(\\d{1,2})`(24..31): constant 1`.*`"
                            "W`\\1`(16..23): constant 2`.*`"
                            "W`\\1`(8..15): constant 3`.*`"
                            "W`\\1`(0..7): constant 4`.*`}"});
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
                            "- {`.*`W`(\\d{1,2})`(24..31): constant 0`.*`"
                            "W`\\1`(16..23): constant 3`.*`"
                            "W`\\1`(8..15): constant 0`.*`"
                            "W`\\1`(0..7): constant 4`.*`}",
                            "`.*`",
                            "- {`.*`W`(\\d{1,2})`(24..31): constant 0`.*`"
                            "W`\\2`(16..23): constant 1`.*`"
                            "W`\\2`(8..15): constant 0`.*`"
                            "W`\\2`(0..7): constant 2`.*`}"});
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
        "` *`map:",
        "` *`hdrs.h1: 1",
        "` *`hdrs.h2: 2",
        "` *`hdrs.h3: 3",
        "` *`ig_intr_md: 0",
        "` *`payload: 254",
        "` *`seq:",
        "` *`0: [ig_intr_md, hdrs.h1, hdrs.h2, hdrs.h3, payload]",
        "` *`1: [ig_intr_md, hdrs.h1, payload]",
        "` *`len:",
        "` *`ig_intr_md: { base_len: 8, num_comp_bits: 0, scale: 0 }",
        "` *`hdrs.h1: { base_len: 12, num_comp_bits: 0, scale: 0 }",
        "` *`hdrs.h2: { base_len: 2, num_comp_bits: 0, scale: 0 }",
        "` *`hdrs.h3: { base_len: 4, num_comp_bits: 0, scale: 0 }",
        "` *`payload: { base_len: 0, num_comp_bits: 0, scale: 0 }"
    });
    EXPECT_TRUE(res.success) << " pos=" << res.pos << " count=" << res.count << "\n'"
                             << blk.extract_code(TestCode::CodeBlock::HdrAsm) << "'\n";

    res = blk.match(TestCode::CodeBlock::ParserIAsm, CheckList{
        "` *`parser ingress:",
        "` *`states:",
        "` *`$entry_point: 0x**************00",
        "` *`$final: 0x**************06",
        "` *`parse_h2: 0x**************04",
        "` *`parse_h3: 0x**************05",
        "` *`start: 0x**************01",
        "` *`start.$oob_stall_0: 0x**************02",
        "` *`start.$split_0: 0x**************03",
        "` *`profile 0:",
        "` *`match_port: 0o**",
        "` *`match_inband_metadata: 0x****************",
        "` *`initial_pktlen: 0",
        "` *`initial_seglen: 0",
        "` *`initial_state: $entry_point",
        "` *`initial_ptr: ` *`0",
        "` *`metadata_select: [ logical_port_number, port_metadata 0, inband_metadata 2, ",
        "inband_metadata 3, inband_metadata 4, inband_metadata 5, inband_metadata 6, ",
        "inband_metadata 7 ]",
        "` *`analyzer_stage 0 $entry_point:",
        "` *`rule 0:",
        "` *`match_w0: 0x****",
        "` *`match_w1: 0x****",
        "` *`next_state: start",
        "` *`next_alu0_instruction: { opcode: 0, add: 0 } ` *`# ptr += 0",
        "` *`next_alu1_instruction: { opcode: noop } ` *`# noop",
        "` *`analyzer_stage 1 start:",
        "` *`rule 0:",
        "` *`match_w0: 0x****",
        "` *`match_w1: 0x****",
        "` *`next_state: start.$oob_stall_0",
        "` *`next_alu0_instruction: { opcode: 0, add: 32 } ` *`# ptr += 32",
        "` *`next_alu1_instruction: { opcode: noop } ` *`# noop",
        "` *`modify_flag0: { set: 3 }",
        "` *`push_hdr_id: { hdr: 0, offset: 0 }",
        "` *`analyzer_stage 2 start.$oob_stall_0:",
        "` *`rule 0:",
        "` *`match_w0: 0x****",
        "` *`match_w1: 0x****",
        "` *`next_state: start.$split_0",
        "` *`next_w0_offset: 8",
        "` *`next_alu0_instruction: { opcode: 0, add: 0 } ` *`# ptr += 0",
        "` *`next_alu1_instruction: { opcode: noop } ` *`# noop",
        "` *`analyzer_stage 3 start.$split_0:",
        "` *`rule 0:",
        "` *`match_w0: 0x****",
        "` *`match_w1: 0x****",
        "` *`next_state: $final",
        "` *`next_alu0_instruction: { opcode: 0, add: 12 } ` *`# ptr += 12",
        "` *`next_alu1_instruction: { opcode: noop } ` *`# noop",
        "` *`modify_flag0: { set: 0 }",
        "` *`push_hdr_id: { hdr: 1, offset: 0 }",
        "` *`rule 1:",
        "` *`match_w0: 0x0002",
        "` *`match_w1: 0x****",
        "` *`next_state: parse_h3",
        "` *`next_alu0_instruction: { opcode: 0, add: 12 } ` *`# ptr += 12",
        "` *`next_alu1_instruction: { opcode: noop } ` *`# noop",
        "` *`modify_flag0: { set: 0 }",
        "` *`push_hdr_id: { hdr: 1, offset: 0 }",
        "` *`rule 2:",
        "` *`match_w0: 0x0001",
        "` *`match_w1: 0x****",
        "` *`next_state: parse_h2",
        "` *`next_alu0_instruction: { opcode: 0, add: 12 } ` *`# ptr += 12",
        "` *`next_alu1_instruction: { opcode: noop } ` *`# noop",
        "` *`modify_flag0: { set: 0 }",
        "` *`push_hdr_id: { hdr: 1, offset: 0 }",
        "` *`analyzer_stage 4 parse_h2:",
        "` *`rule 0:",
        "` *`match_w0: 0x****",
        "` *`match_w1: 0x****",
        "` *`next_state: parse_h3",
        "` *`next_alu0_instruction: { opcode: 0, add: 2 } ` *`# ptr += 2",
        "` *`next_alu1_instruction: { opcode: noop } ` *`# noop",
        "` *`modify_flag0: { set: 1 }",
        "` *`push_hdr_id: { hdr: 2, offset: 0 }",
        "` *`analyzer_stage 5 parse_h3:",
        "` *`rule 0:",
        "` *`match_w0: 0x****",
        "` *`match_w1: 0x****",
        "` *`next_state: $final",
        "` *`next_alu0_instruction: { opcode: 0, add: 4 } ` *`# ptr += 4",
        "` *`next_alu1_instruction: { opcode: noop } ` *`# noop",
        "` *`modify_flag0: { set: 2 }",
        "` *`push_hdr_id: { hdr: 3, offset: 0 }",
        "` *`analyzer_stage 6 $final:",
        "` *`rule 0:",
        "` *`match_w0: 0x****",
        "` *`match_w1: 0x****",
        "` *`next_alu0_instruction: { opcode: noop } ` *`# noop",
        "` *`next_alu1_instruction: { opcode: noop } ` *`# noop",
        "` *`push_hdr_id: { hdr: 254, offset: 0 }"
    });
    EXPECT_TRUE(res.success) << " pos=" << res.pos << " count=" << res.count << "\n'"
                             << blk.extract_code(TestCode::CodeBlock::ParserIAsm) << "'\n";
}

}  // namespace Test
