#include "tofino.h"
#include "trivial.h"

control c(inout packet_t hdrs, inout standard_metadata meta) {
    apply {
        meta.egress_spec = 3;
    }
}

Switch(Parser(), c(), egress(), deparser()) main;