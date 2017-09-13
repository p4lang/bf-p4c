/*
Copyright 2013-present Barefoot Networks, Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

#include "tofino/test/gtest/tofino_gtest_utils.h"

#include "gtest/gtest.h"

#include "frontends/common/parseInput.h"
#include "frontends/p4/frontend.h"
#include "lib/error.h"
#include "ir/ir.h"
#include "test/gtest/helpers.h"
#include "tofino/common/extract_maupipe.h"
#include "tofino/common/header_stack.h"
#include "tofino/midend.h"
#include "tofino/phv/create_thread_local_instances.h"

namespace Test {

/* static */ boost::optional<FrontendTestCase>
FrontendTestCase::create(const std::string& source,
                         CompilerOptions::FrontendVersion langVersion
                            /* = CompilerOptions::FrontendVersion::P4_16 */) {
    auto* program =
      P4::parseP4String(source, langVersion);
    if (program == nullptr) {
        std::cerr << "Couldn't parse test case source" << std::endl;
        return boost::none;
    }
    if (::ErrorReporter::instance.getDiagnosticCount() > 0) {
        std::cerr << "Encountered " << ::ErrorReporter::instance.getDiagnosticCount()
                  << " errors while parsing test case" << std::endl;
        return boost::none;
    }

    Tofino_Options options;
    options.langVersion = langVersion;
    program = P4::FrontEnd().run(options, program, true);
    if (program == nullptr) {
        std::cerr << "Frontend failed" << std::endl;
        return boost::none;
    }
    if (::ErrorReporter::instance.getDiagnosticCount() > 0) {
        std::cerr << "Encountered " << ::ErrorReporter::instance.getDiagnosticCount()
                  << " errors while executing frontend" << std::endl;
        return boost::none;
    }

    return FrontendTestCase{program};
}

/* static */ boost::optional<MidendTestCase>
MidendTestCase::create(const std::string& source,
                       CompilerOptions::FrontendVersion langVersion
                          /* = CompilerOptions::FrontendVersion::P4_16 */) {
    auto frontendTestCase = FrontendTestCase::create(source, langVersion);
    if (!frontendTestCase) return boost::none;

    Tofino_Options options;
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

    Tofino_Options options;
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
