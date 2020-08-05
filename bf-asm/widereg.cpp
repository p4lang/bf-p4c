#include "widereg.h"

#include <map>
#include <sstream>

#include "log.h"

void widereg_base::log(const char *op, bitvec v) const {
    std::ostringstream tmp;
    LOG1(this << ' ' << op << ' ' << v <<
         (v != value ?  tmp << " (now " << value << ")", tmp : tmp).str()); }

