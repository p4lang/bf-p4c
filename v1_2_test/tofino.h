#include "stdlib.h"

struct standard_metadata {
    bit<9>      egress_spec;
}

parser parse<H>(packet_in packet, out H headers);
control pipe<H>(inout H headers, inout standard_metadata meta);
control deparse<H>(packet_out packet, in H headers);

package Switch<H>(parse<H> prsr, pipe<H> ingress, pipe<H> egress, deparse<H> deparser);
