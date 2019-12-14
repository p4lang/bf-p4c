#include <core.p4>
#include <tna.p4>

header data_t {
        bit<32> f1;
            bit<32> f2;
                bit<16> h1;
                    bit<8>  b1;
                        bit<8>  b2;
}

struct metadata {
}

struct headers {
        data_t data;
}


parser ParserI(packet_in b,
                       out headers hdr,
                                      out metadata meta,
                                                     out ingress_intrinsic_metadata_t ig_intr_md) {
        state start {
                    b.extract(hdr.data);
                            transition accept;
                                }
}

control IngressP(inout headers hdr,
                         inout metadata meta,
                                          in ingress_intrinsic_metadata_t ig_intr_md,
                                                           in
                                                           ingress_intrinsic_metadata_from_parser_t
                                                           ig_intr_prsr_md,
                                                                            inout
                                                                            ingress_intrinsic_metadata_for_deparser_t
                                                                            ig_intr_dprs_md,
                                                                                             inout
                                                                                             ingress_intrinsic_metadata_for_tm_t
                                                                                             ig_intr_tm_md)
{
        action set_port_act(bit<9> port) {
                    ig_intr_tm_md.ucast_egress_port = port;
                        }

            action set1(bit<8> b1) {
                        hdr.data.f1[7:0] = hdr.data.f1[7:0] + b1;
                            }
                
                action set2(bit<32> w1) {
                            hdr.data.f1 = hdr.data.f1 + w1;
                                }


                    action noop() {

                            }

                        table t1 {
                                    key = { hdr.data.f1 : exact; }
                                            actions = { @tableonly set1;
                                                                    set2;
                                                                                        @defaultonly
                                                                                            noop; }
                                                    default_action = noop;
                                                        }
                            
                            table set_port {
                                        actions = { set_port_act;
                                                                noop; }
                                                key = { hdr.data.f1: exact; }
                                                        default_action = noop;
                                                            }
                                apply {
                                            t1.apply();
                                                    set_port.apply();
                                                        }

}

control DeparserI(packet_out b,
                          inout headers hdr,
                                            in metadata meta,
                                                              in
                                                              ingress_intrinsic_metadata_for_deparser_t
                                                              ig_intr_dprsr_md) {
        apply { b.emit(hdr.data); }
}

parser ParserE(packet_in b,
                       out headers hdr,
                                      out metadata meta,
                                                     out egress_intrinsic_metadata_t eg_intr_md) {
        state start {
                    b.extract(hdr.data);
                            transition accept;
                                }
}

control EgressP(inout headers hdr,
                        inout metadata meta,
                                        in egress_intrinsic_metadata_t eg_intr_md,
                                                        in egress_intrinsic_metadata_from_parser_t
                                                        eg_intr_md_from_prsr,
                                                                        inout
                                                                        egress_intrinsic_metadata_for_deparser_t
                                                                        ig_intr_dprs_md,
                                                                                        inout
                                                                                        egress_intrinsic_metadata_for_output_port_t
                                                                                        eg_intr_oport_md)
{
        apply { }
}

control DeparserE(packet_out b,
                          inout headers hdr,
                                            in metadata meta,
                                                              in
                                                              egress_intrinsic_metadata_for_deparser_t
                                                              ig_intr_dprs_md) {
        apply { b.emit(hdr.data); }
}

Pipeline(ParserI(), IngressP(), DeparserI(), ParserE(), EgressP(), DeparserE()) pipe0;
Switch(pipe0) main;

