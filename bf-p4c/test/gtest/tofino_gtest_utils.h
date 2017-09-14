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

#ifndef TOFINO_TEST_GTEST_TOFINO_GTEST_UTILS_H_
#define TOFINO_TEST_GTEST_TOFINO_GTEST_UTILS_H_

#include <boost/optional.hpp>
#include <string>

#include "bf-p4c/tofinoOptions.h"

namespace IR {
namespace BFN {
class Pipe;
}  // namespace BFN
class P4Program;
}  // namespace IR

namespace Test {

struct FrontendTestCase {
    /// Create a test case that only requires the frontend to run.
    static boost::optional<FrontendTestCase>
    create(const std::string& source,
           CompilerOptions::FrontendVersion langVersion
              = CompilerOptions::FrontendVersion::P4_16);

    /// The output of the frontend.
    const IR::P4Program* program;
};

struct MidendTestCase {
    /// Create a test case that requires the frontend and the midend to run.
    static boost::optional<MidendTestCase>
    create(const std::string& source,
           CompilerOptions::FrontendVersion langVersion
              = CompilerOptions::FrontendVersion::P4_16);

    /// The output of the midend.
    const IR::P4Program* program;

    /// The output of the frontend.
    const IR::P4Program* frontendProgram;
};

struct TofinoPipeTestCase {
    /// Create a test case that requires extract_maupipe() to run.
    static boost::optional<TofinoPipeTestCase>
    create(const std::string& source,
           CompilerOptions::FrontendVersion langVersion
              = CompilerOptions::FrontendVersion::P4_16);

    /// Create a test case that requires extract_maupipe() to run, and apply
    /// CreateThreadLocalInstances.
    static boost::optional<TofinoPipeTestCase>
    createWithThreadLocalInstances(const std::string& source,
                                   CompilerOptions::FrontendVersion langVersion
                                     = CompilerOptions::FrontendVersion::P4_16);

    /// The output of extract_maupipe().
    const IR::BFN::Pipe* pipe;

    /// The output of the frontend.
    const IR::P4Program* frontendProgram;
};

}  // namespace Test

#endif /* TOFINO_TEST_GTEST_TOFINO_GTEST_UTILS_H_ */
