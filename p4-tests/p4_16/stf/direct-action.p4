#include "tofino.h"
#include "trivial.h"

control c(inout packet_t hdrs, inout standard_metadata meta) {
    action a(bit<32> arg) {
        meta.egress_spec = (bit<9>)arg;
    }

    apply {
        a(3);
    }
}

Switch(TopParser(), c(), egress(), deparser()) main;
