#include "core.p4"

struct standard_metadata {
    bit<16>     ingress_port;
    bit<16>     packet_length;
    bit<9>      egress_spec;
    bit<16>     egress_port;
    bit<16>     egress_instance;
    bit<8>      instance_type;
    bit<8>      parser_status;
    bit<8>      parser_error_location;
}

parser parse<H>(packet_in packet, out H headers, inout standard_metadata meta);
control pipe<H>(inout H headers, inout standard_metadata meta);
control deparse<H>(packet_out packet, in H headers, inout standard_metadata meta);

package Switch<H>(parse<H> p, pipe<H> ig, pipe<H> eg, deparse<H> dep);
