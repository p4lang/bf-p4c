#ifndef BF_P4C_IR_GRESS_H_
#define BF_P4C_IR_GRESS_H_

#include <iosfwd>
#include <optional>
#include <lib/cstring.h>

/// An enumeration identifying a thread in the Tofino architecture.
enum gress_t {
  INGRESS = 0,
  EGRESS = 1,
  GHOST = 2,
  GRESS_T_COUNT  // number of different threads (max of all targets)
};

/// @return, given a thread @gress, the _other_ thread.  Ingress and Ghost are considered the
/// same, so they both return egress.
inline gress_t operator~(const gress_t& gress) { return gress_t((gress & 1) ^ 1); }

P4::cstring toString(gress_t gress);
P4::cstring toSymbol(gress_t gress);
P4::cstring createThreadName(gress_t gress, P4::cstring name);
P4::cstring stripThreadPrefix(P4::cstring name);

std::ostream& operator<<(std::ostream& out, gress_t gress);
std::ostream& operator<<(std::ostream& out, std::optional<gress_t> gress);
bool operator>>(P4::cstring s, gress_t& gressOut);

#endif /* BF_P4C_IR_GRESS_H_ */
