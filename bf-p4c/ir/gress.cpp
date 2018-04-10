#include "gress.h"
#include <lib/cstring.h>
#include <lib/exceptions.h>
#include <boost/optional/optional_io.hpp>

cstring toString(gress_t gress) {
  switch (gress) {
    case INGRESS: return "ingress";
    case EGRESS: return "egress"; }
  BUG("Unexpected *gress value");
}

cstring createThreadName(gress_t gress, cstring name) {
    return toString(gress) + "::" + name;
}

std::ostream& operator<<(std::ostream& out, gress_t gress) {
    return out << toString(gress);
}

std::ostream& operator<<(std::ostream& out, boost::optional<gress_t> gress) {
    if (gress)
        out << *gress;
    else
        out << "none";
    return out;
}

bool operator>>(cstring s, gress_t& gressOut) {
    if (s == "ingress")
        gressOut = INGRESS;
    else if (s == "egress")
        gressOut = EGRESS;
    else
        return false;
    return true;
}
