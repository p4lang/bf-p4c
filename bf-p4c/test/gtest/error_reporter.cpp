#include "bf_gtest_helpers.h"
#include "gtest/gtest.h"
#include "lib/error.h"
#include "frontends/parsers/parserDriver.h"
#include "bf-p4c/arch/arch.h"

namespace Test {
class ErrorReporterTest : public ::testing::Test {
 protected:
    std::stringstream customStream;
    std::string ROOT_DIR = std::string(__FILE__);

    void SetUp() {
        // ROOT_DIR currently looks like 'ROOT_DIR/bf-p4c/test/gtest/error_reporter.cpp' -> adjust
        const std::string SUFFIX("/p4c/extensions/bf-p4c/test/gtest/error_reporter.cpp");
        ROOT_DIR = ROOT_DIR.substr(0, ROOT_DIR.size() - std::string(SUFFIX).size());
    }

    void TearDown() {}
};

TEST_F(ErrorReporterTest, ErrorHelperPlainFormatsCorrectly) {
    boost::format fmt("Str: %1%, Dec: %2%");

    EXPECT_EQ(
        ::error_helper(fmt, "hello", 10).toString(),
        "Str: hello, Dec: 10\n");
}

TEST_F(ErrorReporterTest, WarningsConformToExpectedFormat) {
    // NOTE: Warnings are formatted exactly the same as errors

    const std::string EXPECTED_WARN_0 = R"(TestCode(44): [--Wwarn=unused] warning: 'val_undefined' is unused
    action do_global_action(in bool make_zero, out bool val_undefined) {
                                                        ^^^^^^^^^^^^^
)";

    const std::string EXPECTED_WARN_1 = R"(TestCode(46): [--Wwarn=uninitialized_use] warning: tmp may be uninitialized
        tmp = tmp * (make_zero ? 16w0 : 16w1);
              ^^^
)";

    const std::string EXPECTED_WARN_2 = R"(TestCode(44): [--Wwarn=uninitialized_out_param] warning: out parameter 'val_undefined' may be uninitialized when 'do_global_action' terminates
    action do_global_action(in bool make_zero, out bool val_undefined) {
                                                        ^^^^^^^^^^^^^
TestCode(44)
    action do_global_action(in bool make_zero, out bool val_undefined) {
           ^^^^^^^^^^^^^^^^
)";

    const std::string EXPECTED_WARN_3 = R"([--Wwarn=uninitialized_use] warning: val_undefined may be uninitialized
TestCode(44): [--Wwarn=uninitialized_use] warning: val_undefined may be uninitialized
    action do_global_action(in bool make_zero, out bool val_undefined) {
                                                        ^^^^^^^^^^^^^
)";

    const std::string EXPECTED_WARN_4 = R"(warning: No size defined for table 'TABLE_NAME', setting default size to 512
)";

    const std::string EXPECTED_WARNINGS = EXPECTED_WARN_0 + EXPECTED_WARN_1 + EXPECTED_WARN_2 +
                                          EXPECTED_WARN_3 + EXPECTED_WARN_4;

    // Running frontend on this code should emit EXPECTED_WARN_0, 1, 2, 3 and 4
    auto CODE = R"(
    header ethernet_t {
        bit<48> src_addr;
    }

    struct Headers {
        ethernet_t eth_hdr;
    }

    action do_global_action(in bool make_zero, out bool val_undefined) {
        bit<16> tmp;
        tmp = tmp * (make_zero ? 16w0 : 16w1);
    }
    control ingress(inout Headers h) {
        bool filler_bool = true;
        bool tmp_bool = false;
        action do_action() {
            do_global_action(tmp_bool, tmp_bool);
        }
        table simple_table {
            key = {
                h.eth_hdr.src_addr: exact;
            }
            actions = {
                do_action();
                do_global_action(true, filler_bool);
            }
        }
        apply {
            simple_table.apply();
        }
    }

    control c<H>(inout H h);
    package top<H>(c<H> _c);
    top(ingress()) main;
    )";


    // Compile program so our custom stream is populated with warnings
    // Instantiation of testCode reinstantiates errorReporter instance
    auto testCode = TestCode(TestCode::Hdr::CoreP4, CODE);

    // errorReporter is now stable, redirect to stringstream
    auto backupStream = BaseCompileContext::get().errorReporter().getOutputStream();
    BaseCompileContext::get().errorReporter().setOutputStream(&customStream);
    // Non-standard architecture, default to TNA
    BFN::Architecture::init("TNA");
    // Compile and emit warnings 1 and 2
    EXPECT_TRUE(testCode.apply_pass(TestCode::Pass::FullFrontend));

    // Should emit EXPECTED_WARN_3
    ::warning("No size defined for table '%s', setting default size to %d",
                        "TABLE_NAME", 512);

    EXPECT_EQ(EXPECTED_WARNINGS, customStream.str());

    // Restore error stream to original
    BaseCompileContext::get().errorReporter().setOutputStream(backupStream);
}

TEST_F(ErrorReporterTest, WarningWithSuffixConformToExpectedFormat) {
    const std::string EXPECTED_WARN_1 = R"(TestCode(44): [--Werror=type-error] error: return +
                return (ix + 1);
                ^^^^^^
  ---- Actual error:
  TestCode(43): Cannot cast implicitly type 'bit<16>' to type 'bool'
              bool f(in bit<16> ix) {
              ^^^^
  ---- Originating from:
  TestCode(44): Source expression '+' produces a result of type 'bit<16>' which cannot be assigned to a left-value with type 'bool'
                  return (ix + 1);
                          ^^^^^^
  TestCode(43)
              bool f(in bit<16> ix) {
              ^^^^
TestCode(42): [--Werror=type-error] error: cntr
        Virtual() cntr = {
                  ^^^^
  ---- Actual error:
  TestCode(43): Cannot unify type 'bool' with type 'bit<16>'
              bool f(in bit<16> ix) {
              ^^^^
  ---- Originating from:
  TestCode(43): Method 'f' does not have the expected type 'f'
              bool f(in bit<16> ix) {
                   ^
  TestCode(38)
      abstract bit<16> f(in bit<16> ix);
                       ^
)";

    auto CODE = R"(
    extern Virtual {
    Virtual();
    abstract bit<16> f(in bit<16> ix);
    }

    control c(inout bit<16> p) {
        Virtual() cntr = {
            bool f(in bit<16> ix) {
                return (ix + 1);
            }
        };

        apply {
            p = cntr.f(6);
        }
    }

    control ctr(inout bit<16> x);
    package top(ctr ctrl);
    top(c()) main;
    )";

    // Compile program so our custom stream is populated with warnings
    // Instantiation of testCode reinstantiates errorReporter instance
    auto testCode = TestCode(TestCode::Hdr::CoreP4, CODE);

    // errorReporter is now stable, redirect to stringstream
    auto backupStream = BaseCompileContext::get().errorReporter().getOutputStream();
    BaseCompileContext::get().errorReporter().setOutputStream(&customStream);

    EXPECT_FALSE(testCode.apply_pass(TestCode::Pass::FullFrontend));

    EXPECT_EQ(EXPECTED_WARN_1, customStream.str());

    // Restore error stream to original
    BaseCompileContext::get().errorReporter().setOutputStream(backupStream);
}

TEST_F(ErrorReporterTest, ParserErrorConformsToExpectedFormat) {
    const std::string EXPECTED_WARN = R"(file.cpp(0):syntax error, unexpected IDENTIFIER, expecting {
header hdr bug
           ^^^
)";

    // errorReporter is now stable, redirect to stringstream
    auto backupStream = BaseCompileContext::get().errorReporter().getOutputStream();
    BaseCompileContext::get().errorReporter().setOutputStream(&customStream);

    std::istringstream inputCode = std::istringstream("header hdr bug { bit<8> field; }");
    P4::P4ParserDriver::parse(inputCode, "file.cpp", 1);

    EXPECT_EQ(customStream.str(), EXPECTED_WARN);

    // Restore error stream to original
    BaseCompileContext::get().errorReporter().setOutputStream(backupStream);
}

}  // namespace Test
