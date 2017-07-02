#include <lib/cstring.h>
#include <lib/exceptions.h>
#include "gress.h"

static cstring toString(gress_t gress) {
  switch (gress) {
    case INGRESS: return "ingress";
    case EGRESS: return "egress"; }
  BUG("Unexpected *gress value");
}

std::ostream& operator<<(std::ostream& out, gress_t gress) {
    return out << toString(gress);
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
