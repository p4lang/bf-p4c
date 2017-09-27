#ifndef EXTENSIONS_BF_P4C_COMMON_MACHINE_DESCRIPTION_H_
#define EXTENSIONS_BF_P4C_COMMON_MACHINE_DESCRIPTION_H_

#include <array>

namespace BFN {
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
}  // namespace BFN

#endif /* EXTENSIONS_BF_P4C_COMMON_MACHINE_DESCRIPTION_H_ */
