#ifndef BF_P4C_IR_GRESS_H_
#define BF_P4C_IR_GRESS_H_

#include <boost/optional.hpp>
#include <iosfwd>

class cstring;

/// An enumeration identifying a thread in the Tofino architecture.
enum gress_t {
  INGRESS = 0,
  EGRESS = 1,
  GHOST = 2,
};

/// @return, given a thread @gress, the _other_ thread.  Ingress and Ghost are considered the
/// same, so they both return egress.
inline gress_t operator~(const gress_t& gress) { return gress_t((gress & 1) ^ 1); }

cstring toString(gress_t gress);
cstring createThreadName(gress_t gress, cstring name);

std::ostream& operator<<(std::ostream& out, gress_t gress);
std::ostream& operator<<(std::ostream& out, boost::optional<gress_t> gress);
bool operator>>(cstring s, gress_t& gressOut);

#endif /* BF_P4C_IR_GRESS_H_ */
