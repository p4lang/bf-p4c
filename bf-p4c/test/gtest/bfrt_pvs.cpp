/*
 * The test checks the contents of bfrt.json corresponding to parser value set (PVS)
 * specialized for different types (bit string, serializable enum, struct).
 */

#include <string>
#include <fstream>
#include <streambuf>
#include <iterator>
#include <regex>

#include "bf_gtest_helpers.h"
#include "gtest/gtest.h"

#include "bf-p4c/bf-p4c-options.h"
#include "bf-p4c/control-plane/runtime.h"
#include "bf-p4c/control-plane/bfruntime_arch_handler.h"
#include "control-plane/p4RuntimeArchStandard.h"

namespace Test {

void generate_bfrt(TestCode &test) {
    BFN::generateRuntime(test.get_program(), BackendOptions());
    // BFN's generateRuntime re-registers handler for psa architecture to a BFN handler
    // Re-register the original p4c one so that (plain) p4c tests are not affected
    auto p4RuntimeSerializer = P4::P4RuntimeSerializer::get();
    p4RuntimeSerializer->registerArch("psa",
        new P4::ControlPlaneAPI::Standard::PSAArchHandlerBuilder());
}

// Common for BfrtPvs.BitString and BfrtPvs.SerializableEnum
std::regex bfrt_regex_bitstring(
    ".*" "\\{\\n"
        ".*" "\"name\""        ".*:.*" "\"pipeline.ingress_parser.tpids\"" ",\\n"
        ".*" "\"id\""          ".*:.*" ",\\n"
        ".*" "\"table_type\""  ".*:.*" "\"ParserValueSet\"" ",\\n"
        ".*" "\"size\""        ".*:.*" "4" ",\\n"
        ".*" "\"annotations\"" ".*:.*" ",\\n"
        ".*" "\"depends_on\""  ".*:.*" ",\\n"
        ".*" "key"             ".*:.*" "\\[\\n"
        ".*" "\\{\\n"
            ".*" "\"id\""          ".*:.*" "1" ",\\n"
            ".*" "\"name\""        ".*:.*" "\"f1\"" ",\\n"
            ".*" "\"repeated\""    ".*:.*" ",\\n"
            ".*" "\"annotations\"" ".*:.*" ",\\n"
            ".*" "\"mandatory\""   ".*:.*" ",\\n"
            ".*" "\"match_type\""  ".*:.*" "\"Ternary\"" ",\\n"
            ".*" "\"type\""        ".*:.*" "\\{\\n"
                ".*" "\"type\""    ".*:.*" "\"bytes\"" ",\\n"
                ".*" "\"width\""   ".*:.*" "16" "\\n"
            ".*" "\\}\\n"
        ".*" "\\}\\n"
        ".*" "\\],\\n");

TEST(BfrtPvs, BitString) {
    auto defs = R"(
        header ethernet_h {
            bit<48>        dst_addr;
            bit<48>        src_addr;
            bit<16>        ether_type;
        }
        struct headers_t { ethernet_h ethernet; }
        struct local_metadata_t {})";

    auto parser = R"(
        value_set<bit<16>>(4) tpids;
        state start {
            packet.extract(hdr.ethernet);
            transition select(hdr.ethernet.ether_type) {
                            tpids:  parse_vlan_tag;
                           0x0800:  parse_ipv4;
                default: accept;
            }
        }
        state parse_vlan_tag {
            transition accept;
        }
        state parse_ipv4 {
            transition accept;
        })";

    std::string bfrt_json = "bfrt.json";

    auto blk = TestCode(TestCode::Hdr::TofinoMin, TestCode::tofino_shell(),
                        {defs, parser, TestCode::empty_appy(), TestCode::empty_appy()}, "",
                        {"--bf-rt-schema", bfrt_json});
    EXPECT_TRUE(blk.apply_pass(TestCode::Pass::FullFrontend));

    generate_bfrt(blk);

    std::ifstream bfrt_json_stream(bfrt_json);
    EXPECT_TRUE(bfrt_json_stream);

    std::string bfrt_json_string((std::istreambuf_iterator<char>(bfrt_json_stream)),
        std::istreambuf_iterator<char>());

    EXPECT_TRUE(std::regex_search(bfrt_json_string, bfrt_regex_bitstring));
}

TEST(BfrtPvs, SerializableEnum) {
    auto defs = R"(
        enum bit<16> ether_type_t {
            TPID       = 0x8100,
            IPV4       = 0x0800,
            IPV6       = 0x86DD,
            ARP        = 0x0806,
            MPLS       = 0x8847
        }
        header ethernet_h {
            bit<48>        dst_addr;
            bit<48>        src_addr;
            ether_type_t   ether_type;
        }
        struct headers_t { ethernet_h ethernet; }
        struct local_metadata_t {})";

    auto parser = R"(
        value_set<ether_type_t>(4) tpids;
        state start {
            packet.extract(hdr.ethernet);
            transition select(hdr.ethernet.ether_type) {
                            tpids:  parse_vlan_tag;
                ether_type_t.IPV4:  parse_ipv4;
                default: accept;
            }
        }
        state parse_vlan_tag {
            transition accept;
        }
        state parse_ipv4 {
            transition accept;
        })";

    std::string bfrt_json = "bfrt.json";

    auto blk = TestCode(TestCode::Hdr::TofinoMin, TestCode::tofino_shell(),
                        {defs, parser, TestCode::empty_appy(), TestCode::empty_appy()}, "",
                        {"--bf-rt-schema", bfrt_json});
    EXPECT_TRUE(blk.apply_pass(TestCode::Pass::FullFrontend));

    generate_bfrt(blk);

    std::ifstream bfrt_json_stream(bfrt_json);
    EXPECT_TRUE(bfrt_json_stream);

    std::string bfrt_json_string((std::istreambuf_iterator<char>(bfrt_json_stream)),
        std::istreambuf_iterator<char>());

    EXPECT_TRUE(std::regex_search(bfrt_json_string, bfrt_regex_bitstring));
}

// For BfrtPvs.Struct
std::regex bfrt_regex_struct(
    ".*" "\\{\\n"
        ".*" "\"name\""        ".*:.*" "\"pipeline.ingress_parser.tpids\"" ",\\n"
        ".*" "\"id\""          ".*:.*" ",\\n"
        ".*" "\"table_type\""  ".*:.*" "\"ParserValueSet\"" ",\\n"
        ".*" "\"size\""        ".*:.*" "4" ",\\n"
        ".*" "\"annotations\"" ".*:.*" ",\\n"
        ".*" "\"depends_on\""  ".*:.*" ",\\n"
        ".*" "key"             ".*:.*" "\\[\\n"
        ".*" "\\{\\n"
            ".*" "\"id\""          ".*:.*" "1" ",\\n"
            ".*" "\"name\""        ".*:.*" "\"ether_type\"" ",\\n"
            ".*" "\"repeated\""    ".*:.*" ",\\n"
            ".*" "\"annotations\"" ".*:.*" ",\\n"
            ".*" "\"mandatory\""   ".*:.*" ",\\n"
            ".*" "\"match_type\""  ".*:.*" "\"Ternary\"" ",\\n"
            ".*" "\"type\""        ".*:.*" "\\{\\n"
                ".*" "\"type\""    ".*:.*" "\"bytes\"" ",\\n"
                ".*" "\"width\""   ".*:.*" "16" "\\n"
            ".*" "\\}\\n"
        ".*" "\\},\\n"
        ".*" "\\{\\n"
            ".*" "\"id\""          ".*:.*" "2" ",\\n"
            ".*" "\"name\""        ".*:.*" "\"multicast\"" ",\\n"
            ".*" "\"repeated\""    ".*:.*" ",\\n"
            ".*" "\"annotations\"" ".*:.*" ",\\n"
            ".*" "\"mandatory\""   ".*:.*" ",\\n"
            ".*" "\"match_type\""  ".*:.*" "\"Ternary\"" ",\\n"
            ".*" "\"type\""        ".*:.*" "\\{\\n"
                ".*" "\"type\""    ".*:.*" "\"bytes\"" ",\\n"
                ".*" "\"width\""   ".*:.*" "1" "\\n"
            ".*" "\\}\\n"
        ".*" "\\}\\n"
        ".*" "\\],\\n");

TEST(BfrtPvs, Struct) {
    auto defs = R"(
        struct pvs_t {
            bit<16> ether_type;
            bit<1>  multicast;
        }
        header ethernet_h {
            bit<48>        dst_addr;
            bit<48>        src_addr;
            bit<16>        ether_type;
        }
        struct headers_t { ethernet_h ethernet; }
        struct local_metadata_t {})";

    auto parser = R"(
        value_set<pvs_t>(4) tpids;
        state start {
            packet.extract(hdr.ethernet);
            transition select(hdr.ethernet.ether_type, hdr.ethernet.dst_addr[40:40]) {
                            tpids:  parse_vlan_tag;
                      (0x0800, 0):  parse_ipv4;
                default: accept;
            }
        }
        state parse_vlan_tag {
            transition accept;
        }
        state parse_ipv4 {
            transition accept;
        })";

    std::string bfrt_json = "bfrt.json";

    auto blk = TestCode(TestCode::Hdr::TofinoMin, TestCode::tofino_shell(),
                        {defs, parser, TestCode::empty_appy(), TestCode::empty_appy()}, "",
                        {"--bf-rt-schema", bfrt_json});
    EXPECT_TRUE(blk.apply_pass(TestCode::Pass::FullFrontend));

    generate_bfrt(blk);

    std::ifstream bfrt_json_stream(bfrt_json);
    EXPECT_TRUE(bfrt_json_stream);

    std::string bfrt_json_string((std::istreambuf_iterator<char>(bfrt_json_stream)),
        std::istreambuf_iterator<char>());

    EXPECT_TRUE(std::regex_search(bfrt_json_string, bfrt_regex_struct));
}

}  // namespace Test
