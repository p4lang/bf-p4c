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

#ifndef _EXTENSIONS_TOFINO_COMMON_MACHINE_DESCRIPTION_H_
#define _EXTENSIONS_TOFINO_COMMON_MACHINE_DESCRIPTION_H_

#include <array>

namespace Tofino {
namespace Description {

/// The name of this machine, in a form suitable for display to end users.
static constexpr const char* ModelName = "Tofino";

/// The available kinds of extractors, specified as sizes in bits.
static constexpr std::array<unsigned, 3> ExtractorKinds = {{ 8, 16, 32 }};

/// The number of extractors of each kind available in each hardware parser
/// state.
static constexpr unsigned ExtractorCount = 4;

/// The size of the input buffer, in bits.
static constexpr int BitInputBufferSize = 256;

/// The size of the input buffer, in bytes.
static constexpr int ByteInputBufferSize = BitInputBufferSize / 8;

}  // namespace Description
}  // namespace Tofino

#endif /* _EXTENSIONS_TOFINO_COMMON_MACHINE_DESCRIPTION_H_ */
