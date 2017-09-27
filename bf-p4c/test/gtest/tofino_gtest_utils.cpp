#include "bf-p4c/test/gtest/tofino_gtest_utils.h"

#include "gtest/gtest.h"

#include "frontends/common/parseInput.h"
#include "frontends/p4/frontend.h"
#include "lib/error.h"
#include "ir/ir.h"
#include "test/gtest/helpers.h"
#include "bf-p4c/common/extract_maupipe.h"
#include "bf-p4c/common/header_stack.h"
#include "bf-p4c/midend.h"
#include "bf-p4c/phv/create_thread_local_instances.h"

namespace Test {

/* static */ boost::optional<MidendTestCase>
MidendTestCase::create(const std::string& source,
                       CompilerOptions::FrontendVersion langVersion
                          /* = CompilerOptions::FrontendVersion::P4_16 */) {
    auto frontendTestCase = FrontendTestCase::create(source, langVersion);
    if (!frontendTestCase) return boost::none;

    BFN_Options options;
    options.langVersion = langVersion;
    BFN::MidEnd midend(options);
    auto* midendProgram = frontendTestCase->program->apply(midend);
    if (midendProgram == nullptr) {
        std::cerr << "Midend failed" << std::endl;
        return boost::none;
    }
    if (::ErrorReporter::instance.getDiagnosticCount() > 0) {
        std::cerr << "Encountered " << ::ErrorReporter::instance.getDiagnosticCount()
                  << " errors while executing midend" << std::endl;
        return boost::none;
    }

    return MidendTestCase{midendProgram, frontendTestCase->program};
}

/* static */ boost::optional<TofinoPipeTestCase>
TofinoPipeTestCase::create(const std::string& source,
                           CompilerOptions::FrontendVersion langVersion
                              /* = CompilerOptions::FrontendVersion::P4_16 */) {
    auto midendTestCase = MidendTestCase::create(source, langVersion);
    if (!midendTestCase) return boost::none;

    BFN_Options options;
    options.langVersion = langVersion;
    auto* pipe = extract_maupipe(midendTestCase->program, options);
    if (pipe == nullptr) {
        std::cerr << "extract_maupipe failed" << std::endl;
        return boost::none;
    }
    if (::ErrorReporter::instance.getDiagnosticCount() > 0) {
        std::cerr << "Encountered " << ::ErrorReporter::instance.getDiagnosticCount()
                  << " errors while executing extract_maupipe" << std::endl;
        return boost::none;
    }

    return TofinoPipeTestCase{pipe, midendTestCase->program};
}

/* static */ boost::optional<TofinoPipeTestCase>
TofinoPipeTestCase::createWithThreadLocalInstances(
        const std::string& source,
        CompilerOptions::FrontendVersion langVersion
          /* = CompilerOptions::FrontendVersion::P4_16 */) {
    auto pipeTestCase = TofinoPipeTestCase::create(source, langVersion);
    if (!pipeTestCase) return boost::none;

    pipeTestCase->pipe = pipeTestCase->pipe->apply(CreateThreadLocalInstances());
    if (pipeTestCase->pipe == nullptr) {
        std::cerr << "Inserting thread local instances failed" << std::endl;
        return boost::none;
    }
    if (::ErrorReporter::instance.getDiagnosticCount() > 0) {
        std::cerr << "Encountered " << ::ErrorReporter::instance.getDiagnosticCount()
                  << " errors while executing CreateThreadLocalInstances" << std::endl;
        return boost::none;
    }

    return pipeTestCase;
}

}  // namespace Test
