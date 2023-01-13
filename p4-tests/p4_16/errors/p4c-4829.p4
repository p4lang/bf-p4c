// Bug report: cannot use const-metadata in RegisterAction

#include <core.p4>
#include <tna.p4>

struct header_t {}
struct ig_metadata_t {}
struct eg_metadata_t {}

parser SwitchIngressParser(
        packet_in pkt,
        out header_t hdr,
        out ig_metadata_t ig_md,
        out ingress_intrinsic_metadata_t ig_intr_md) {
    state start {
        pkt.extract(ig_intr_md);
        pkt.advance(64);
        transition accept;
    }
}

control SwitchIngressDeparser(
        packet_out pkt,
        inout header_t hdr,
        in ig_metadata_t ig_md,
        in ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md) {
    apply {
    }
}

parser SwitchEgressParser(
        packet_in pkt,
        out header_t hdr,
        out eg_metadata_t eg_md,
        out egress_intrinsic_metadata_t eg_intr_md) {
    state start {
        pkt.extract(eg_intr_md);
        transition accept;
    }
}

control SwitchEgressDeparser(
        packet_out pkt,
        inout header_t hdr,
        in eg_metadata_t eg_md,
        in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {
    apply {
    }
}

struct paired_8int {
    int<8> lo;
    int<8> hi;
}

control SwitchIngress(
        inout header_t hdr,
        inout ig_metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {

        action reflect(){
            ig_intr_tm_md.ucast_egress_port=ig_intr_md.ingress_port;
        }

        //==== begin bug report ====

        int<8> meta_int8_a;
        int<8> meta_int8_b;

        action set_meta(){
            meta_int8_a=23;
            meta_int8_a=45;
        }

#define CONST_1 81
#define CONST_2 82
#define CONST_3 83
#define CONST_4 84
#define CONST_5 85

#if TEST == 2 || TEST == 3
        RegisterParam<int<8>>(81) param1;
        RegisterParam<int<8>>(82) param2;
        RegisterParam<int<8>>(83) param3;

#define CONST_1 param1.read()
#define CONST_2 param2.read()
#define CONST_3 param3.read()
#endif
#if TEST == 3
        RegisterParam<int<8>>(84) param4;
        RegisterParam<int<8>>(85) param5;

#define CONST_4 param4.read()
#define CONST_5 param5.read()
#endif


        //==== int<8> register ====
        Register<paired_8int,_>(1024) my_reg;
#if TEST == 1
        /* expect error@-2: "Register actions associated with .* do not fit on the device\. \
Actions use 5 large constants but the device has only 4 register action parameter slots\. \
To make the actions fit, reduce the number of large constants\." */
#elif TEST == 2
        /* expect error@-6: "Register actions associated with .* do not fit on the device\. \
Actions use 2 large constants and 3 register parameters for a total of 5 register \
action parameter slots but the device has only 4 register action parameter slots\. \
To make the actions fit, reduce the number of large constants or register parameters\." */
#elif TEST == 3
        /* expect error@-11: "Register actions associated with .* do not fit on the device\. \
Actions use 5 register parameters but the device has only 4 register action parameter slots\. \
To make the actions fit, reduce the number of register parameters\." */
#endif

        RegisterAction<paired_8int, _, int<8>>(my_reg) my_regact_a= {
            void apply(inout paired_8int value, out int<8> rv) {
                rv = 0;
                paired_8int in_value;
                in_value = value;

                if(in_value.hi + meta_int8_a == CONST_1 ||
                    in_value.lo + meta_int8_b >= CONST_2){
                    value.lo=(meta_int8_b + CONST_3);
                    value.hi=(CONST_4 + 3);
                }else{
                    value.lo=(meta_int8_b + CONST_5);
                    value.hi=meta_int8_b;
                }

                rv=value.lo;
            }
        };

        action exec_a(){
            my_regact_a.execute(0);
        }

        apply {
            set_meta();

            if(ig_intr_md.ingress_port!=0){
                exec_a();
            }

            reflect();
        }
}

control SwitchEgress(
        inout header_t hdr,
        inout eg_metadata_t eg_md,
        in egress_intrinsic_metadata_t eg_intr_md,
        in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
        inout egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
        inout egress_intrinsic_metadata_for_output_port_t eg_intr_oport_md) {
    apply {
    }
}

Pipeline(SwitchIngressParser(),
         SwitchIngress(),
         SwitchIngressDeparser(),
         SwitchEgressParser(),
         SwitchEgress(),
         SwitchEgressDeparser()
         ) pipe;

Switch(pipe) main;
