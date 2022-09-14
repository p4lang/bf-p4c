/*
 * Verify assembler generation for hdr section.
 */

#include <boost/algorithm/string/replace.hpp>

#include "gtest/gtest.h"
#include "bf_gtest_helpers.h"

#include "ir/ir.h"
#include "bf-p4c/test/gtest/tofino_gtest_utils.h"
#include "test/gtest/helpers.h"

namespace Test {

using namespace Match;  // To remove noise & reduce line lengths.

/** Verify that the hdr assembler section is emitted correctly.
 */
TEST(AsmHdrSectionTest, Simple) {
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
        
    control egress(inout headers hdrs, inout metadata meta,
                in egress_intrinsic_metadata_t eg_intr_md,
                inout egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
                inout egress_intrinsic_metadata_for_output_port_t eg_intr_oport_md)
    {
        apply {
            bit<8> tmp;
            tmp = hdrs.data.b1;
            hdrs.data.b1 = hdrs.data.b2;
            hdrs.data.b2 = tmp;
        }
    }

    parser ingressParser(packet_in packet, out headers hdrs,
                        out metadata meta, out ingress_intrinsic_metadata_t ig_intr_md)
    {
        state start {
            // FIXME: update this for Tofino5
            //packet.extract(ig_intr_md);
            //packet.advance(PORT_METADATA_SIZE);
            packet.extract(hdrs.data);
            transition accept;
        }
    }
        
    control ingress(in headers hdrs, inout metadata meta,
                    in ingress_intrinsic_metadata_t ig_intr_md,
                    inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
        apply {
            ig_intr_tm_md.ucast_egress_port = ig_intr_md.ingress_port;
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

    // Check that the min_parse_depth_access states are present in the output file.
    auto res =
        blk.match(TestCode::CodeBlock::HdrAsm,
                  CheckList{"hdr:",
                            "map:",
                            "hdrs.data: 0",
                            "payload: 254",
                            "seq:",
                            "0: [hdrs.data, payload]",
                            "len:",
                            "hdrs.data: { base_len: 12, num_comp_bits: 0, scale: 0 }",
                            "payload: { base_len: 0, num_comp_bits: 0, scale: 0 }"});
    EXPECT_TRUE(res.success) << " pos=" << res.pos << " count=" << res.count << "\n'"
                             << blk.extract_code(TestCode::CodeBlock::HdrAsm) << "'\n";
}

TEST(AsmHdrSectionTest, HeaderStack) {
    std::string test_prog = R"(
    header stack_t {
        bit<80> a;
    }

    struct headers {
        stack_t[3] stack;
    }

    struct metadata {      
    }                      
        
    control egress(inout headers hdrs, inout metadata meta,
                in egress_intrinsic_metadata_t eg_intr_md,
                inout egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
                inout egress_intrinsic_metadata_for_output_port_t eg_intr_oport_md)
    {
        apply {}
    }

    parser ingressParser(packet_in packet, out headers hdrs,
                        out metadata meta, out ingress_intrinsic_metadata_t ig_intr_md)
    {
        state start {
            // FIXME: update this for Tofino5
            //packet.extract(ig_intr_md);
            //packet.advance(PORT_METADATA_SIZE);
            packet.extract(hdrs.stack.next);
            packet.extract(hdrs.stack.next);
            packet.extract(hdrs.stack.next);
            transition accept;
        }
    }
        
    control ingress(in headers hdrs, inout metadata meta,
                    in ingress_intrinsic_metadata_t ig_intr_md,
                    inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
        apply {
            ig_intr_tm_md.ucast_egress_port = ig_intr_md.ingress_port;
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

    // Check that the min_parse_depth_access states are present in the output file.
    // clang-format off
    auto res =
        blk.match(TestCode::CodeBlock::HdrAsm,
                  CheckList{"hdr:",
                            "map:",
                            "hdrs.stack[0]: 0",
                            "hdrs.stack[1]: 1",
                            "hdrs.stack[2]: 2",
                            "payload: 254",
                            "seq:",
                            "0: [hdrs.stack[0], hdrs.stack[1], hdrs.stack[2], payload]",
                            "len:",
                            "hdrs.stack[0]: { base_len: 10, num_comp_bits: 0, scale: 0 }",
                            "hdrs.stack[1]: { base_len: 10, num_comp_bits: 0, scale: 0 }",
                            "hdrs.stack[2]: { base_len: 10, num_comp_bits: 0, scale: 0 }",
                            "payload: { base_len: 0, num_comp_bits: 0, scale: 0 }"});
    // clang-format on
    EXPECT_TRUE(res.success) << " pos=" << res.pos << " count=" << res.count << "\n'"
                             << blk.extract_code(TestCode::CodeBlock::HdrAsm) << "'\n";
}

}  // namespace Test
