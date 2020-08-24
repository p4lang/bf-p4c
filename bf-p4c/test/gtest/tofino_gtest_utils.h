#ifndef EXTENSIONS_BF_P4C_TEST_GTEST_TOFINO_GTEST_UTILS_H_
#define EXTENSIONS_BF_P4C_TEST_GTEST_TOFINO_GTEST_UTILS_H_

#include <boost/optional.hpp>
#include <string>

#include "bf-p4c/bf-p4c-options.h"
#include "bf-p4c/device.h"
#include "gtest/gtest.h"
#include "lib/compile_context.h"

namespace IR {
namespace BFN {
class Pipe;
}  // namespace BFN
class P4Program;
}  // namespace IR

namespace Test {

struct MidendTestCase {
    /// Create a test case that requires the frontend and the midend to run.
    static boost::optional<MidendTestCase>
    create(const std::string& source);

    /// The output of the midend.
    const IR::P4Program* program;

    /// The output of the frontend.
    const IR::P4Program* frontendProgram;
};

struct TofinoPipeTestCase {
    /// Create a test case that requires extract_maupipe() to run.
    static boost::optional<TofinoPipeTestCase>
    create(const std::string& source);

    /// Create a test case that requires extract_maupipe() to run, and apply
    /// CreateThreadLocalInstances.
    static boost::optional<TofinoPipeTestCase>
    createWithThreadLocalInstances(const std::string& source);

    /// The output of extract_maupipe().
    const IR::BFN::Pipe* pipe;

    /// The output of the frontend.
    const IR::P4Program* frontendProgram;
};

/// A GTest fixture base class for backend targets.
class BackendTest : public ::testing::Test {
 protected:
    BackendTest() : autoBFNContext(new BFNContext()) { }

    AutoCompileContext autoBFNContext;
};

/// A GTest fixture for Tofino tests.
class TofinoBackendTest : public BackendTest {
 public:
    TofinoBackendTest() { Device::init("Tofino"); }
};

/// A GTest fixture for JBay tests.
class JBayBackendTest : public BackendTest {
 public:
    JBayBackendTest() { Device::init("Tofino2"); }
};

}  // namespace Test

#endif /* EXTENSIONS_BF_P4C_TEST_GTEST_TOFINO_GTEST_UTILS_H_ */
