#include "widereg.h"
#include <map>
#include "log.h"
#include <sstream>

void widereg_base::log(const char *op, bitvec v) const {
    std::ostringstream tmp;
    LOG1(this << ' ' << op << ' ' << v <<
         (v != value ?  tmp << " (now " << value << ")", tmp : tmp).str()); }

