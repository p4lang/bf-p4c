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

        //==== int<8> register ====
        Register<paired_8int,_>(1024) my_reg;

        RegisterParam<int<8>>(81) param1;
        RegisterParam<int<8>>(82) param2;
        RegisterParam<int<8>>(83) param3;

        RegisterAction<paired_8int, _, int<8>>(my_reg) my_regact_a= {
            void apply(inout paired_8int value, out int<8> rv) {
                rv = 0;
                paired_8int in_value;
                in_value = value;

                if(in_value.hi + meta_int8_a == param1.read() || 
                    in_value.lo + meta_int8_b >= param2.read()){
                    value.lo=(meta_int8_b + param3.read());
                    value.hi=(84 + 85);
                }else{
                    value.lo=(meta_int8_b + 86);
                    value.hi=(meta_int8_b + 87);
                }

                rv=value.lo;
            }
        };


        RegisterAction<paired_8int, _, int<8>>(my_reg) my_regact_b= {
            void apply(inout paired_8int value, out int<8> rv) {
                rv = 0;
                paired_8int in_value;
                in_value = value;

                bool pred_0=(in_value.hi + meta_int8_a >= 91);
                bool pred_1=(0 + meta_int8_a != 92);

                if(pred_0){
                    value.lo=(meta_int8_a + 93);
                    value.hi=(meta_int8_a + in_value.hi);
                }else{
                    value.lo=(94 + in_value.hi);
                    value.hi=(meta_int8_a + in_value.hi);
                }

                rv=value.lo;
            }
        };

        action exec_a(){
            my_regact_a.execute(0);
        }
        action exec_b(){
            my_regact_b.execute(0);
        }


        apply {
            set_meta();

            if(ig_intr_md.ingress_port!=0){
                exec_a();
            }else{
                exec_b();
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
