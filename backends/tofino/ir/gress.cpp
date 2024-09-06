#include "gress.h"
#include <lib/cstring.h>
#include <lib/exceptions.h>
#include <boost/optional/optional_io.hpp>

cstring toString(gress_t gress) {
  switch (gress) {
    case INGRESS: return "ingress";
    case EGRESS: return "egress";
    case GHOST: return "ghost";
    default: BUG("Unexpected *gress value"); }
}

cstring toSymbol(gress_t gress) {
  switch (gress) {
    case INGRESS: return "I";
    case EGRESS: return "E";
    case GHOST: return "G";
    default: BUG("Unexpected *gress value"); }
}

cstring createThreadName(gress_t gress, cstring name) {
    return toString(gress) + "::" + name;
}

cstring stripThreadPrefix(cstring name) {
    if (auto *pos = name.find("::")) {
        return cstring(pos + 2);
    }
    return name;
}

std::ostream& operator<<(std::ostream& out, gress_t gress) {
    return out << toString(gress);
}

std::ostream& operator<<(std::ostream& out, std::optional<gress_t> gress) {
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
    else if (s == "ghost")
        gressOut = GHOST;
    else
        return false;
    return true;
}
