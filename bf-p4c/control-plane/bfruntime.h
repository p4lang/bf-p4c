#ifndef EXTENSIONS_BF_P4C_CONTROL_PLANE_BFRUNTIME_H_
#define EXTENSIONS_BF_P4C_CONTROL_PLANE_BFRUNTIME_H_

#include <iosfwd>

namespace P4 {
struct P4RuntimeAPI;
}  // namespace P4

namespace BFN {

namespace BFRT {

/// Generates BF-RT JSON schema from P4Info protobuf message and writes it to
/// the @destination stream.
void serializeBfRtSchema(std::ostream* destination, const P4::P4RuntimeAPI& p4Runtime);

}  // namespace BFRT

}  // namespace BFN

#endif /* EXTENSIONS_BF_P4C_CONTROL_PLANE_BFRUNTIME_H_ */
