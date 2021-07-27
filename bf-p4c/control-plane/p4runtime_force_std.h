#ifndef EXTENSIONS_BF_P4C_CONTROL_PLANE_P4RUNTIME_FORCE_STD_H_
#define EXTENSIONS_BF_P4C_CONTROL_PLANE_P4RUNTIME_FORCE_STD_H_

#include "control-plane/p4RuntimeSerializer.h"

namespace BFN {

/// Takes a P4Info message generated for a TNA-specific architecture and
/// converts it to a "standard" P4Info message, which can be used with a
/// standard P4Runtime implementation (with no support for TNA-specific
/// extensions). Displays a warning to the user for each extern instance that
/// cannot be converted.
P4::P4RuntimeAPI convertToStdP4Runtime(const P4::P4RuntimeAPI& p4RuntimeInput);

}  // namespace BFN

#endif /* EXTENSIONS_BF_P4C_CONTROL_PLANE_P4RUNTIME_FORCE_STD_H_ */
