#include <boost/algorithm/string/replace.hpp>

#include "gtest/gtest.h"
#include "bf_gtest_helpers.h"

#include "ir/ir.h"
#include "bf-p4c/test/gtest/tofino_gtest_utils.h"
#include "test/gtest/helpers.h"

namespace Test {

using namespace Match;  // To remove noise & reduce line lengths.

/**
 * Verify that initial pointer is set accordingly when ingress intrinsic metadata are not extracted
 * (or not used and the extraction is optimized out).
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
                            "initial_ptr:` *`32"});  // MD32
    EXPECT_TRUE(res.success) << " pos=" << res.pos << " count=" << res.count << "\n'"
                             << blk.extract_code(TestCode::CodeBlock::ParserIAsm) << "'\n";
}

}  // namespace Test
