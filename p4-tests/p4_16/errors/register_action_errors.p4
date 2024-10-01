#include <core.p4>
#include <tna.p4>

struct metadata { }

#include "trivial_parser.h"

control ingress(inout headers hdr, inout metadata meta,
                in ingress_intrinsic_metadata_t ig_intr_md,
                in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
                inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
                inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {

    // Register parameters attached to an indirect register

    Register<bit<32>, bit<10>>(1024) reg1;
    bool b1;
    bool b2;

    RegisterAction<bit<32>, bit<10>, bit<16>>(reg1) reg1action1 = {
        void apply(inout bit<32> value, out bit<16> read_value) {
#if TEST == 1
// Too many comparisons
            if (value == 0 || value == 1 || value == 2 || value == 3 || value == 4)
#if __TARGET_TOFINO__ == 1
            /* expect error@-5: "RegisterAction reg1action1.apply needs 5 comparisons but the device \
only has 2 comparison units. To make the action compile, reduce the number of comparisons." */
#else
            /* expect error@-8: "RegisterAction reg1action1.apply needs 5 comparisons but the device \
only has 4 comparison units. To make the action compile, reduce the number of comparisons." */
#endif // __TARGET_TOFINO__

                read_value = 1;

#elif TEST == 2
// Slice on top of an instruction
            bit<32> result = value + 1;
            read_value = result[15:0]; /* expect error: "Expression too complex \
for RegisterAction - result of an instruction cannot be sliced" */

#elif TEST == 3
// Invalid comparison
            value = 31w0 ++ (bit<1>)(value > 0); /* expect error: "In Stateful ALU, \
a comparison can only be used in a condition or in an assignment to an output parameter\." */

#elif TEST >= 4 && TEST <= 6
// Invalid logical operations
#if TEST == 4
#define OP !b1
#elif TEST == 5
#define OP b1 && b2
#elif TEST == 6
#define OP b1 || b2
#endif // OP

            value = 31w0 ++ (bit<1>)(OP); // expect error: "In Stateful ALU, .* can only be used in a condition\."

#else
// Complex instructions
#if TEST == 7
#define OP +
#elif TEST == 8
#define OP |+|
#elif TEST == 9
#define OP -
#elif TEST == 10
#define OP |-|
#elif TEST == 11
#define OP &
#elif TEST == 12
#define OP ^
#endif // OP

            bit<32> tmp = value |+| 32w0x42;
            value = tmp OP hdr.data.f1; /* expect error: "You can only have more than \
one binary operator in a statement if the outer one is \|" */
#endif // TEST
        }

    };

    apply {
        ig_intr_tm_md.ucast_egress_port = ig_intr_md.ingress_port;
        if (hdr.data.b1 == 0x00) {
            hdr.data.f1[15:0] = reg1action1.execute((bit<10>)ig_intr_md.ingress_port);
        }
    }
}

#include "common_tna_test.h"
