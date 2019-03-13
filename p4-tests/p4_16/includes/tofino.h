#include "core.p4"

struct standard_metadata {
    bit<9>      ingress_port;           // 114-122
    bit<32>     packet_length;          // 82-113
    bit<9>      egress_spec;            // 73-81
    bit<9>      egress_port;            // 64-72
    bit<16>     egress_instance;        // 48-63 
    bit<32>     instance_type;          // 16-47
    bit<8>      parser_status;          // 8-15
    bit<8>      parser_error_location;  // 0-7
}

parser parse<H>(packet_in packet, out H headers, inout standard_metadata meta);
control pipe<H>(inout H headers, inout standard_metadata meta);
control deparse<H>(packet_out packet, in H headers, inout standard_metadata meta);

package Switch<H>(parse<H> p, pipe<H> ig, pipe<H> eg, deparse<H> dep);
