header ingress_intrinsic_metadata_t {
    bit<1> resubmit_flag;                // flag distinguising original packets
                                         // from resubmitted packets.
    bit<1> _pad1;

    bit<2> packet_version;               // packet version.

    bit<3> _pad2;

    PortId_t ingress_port;               // ingress physical port id.
                                         // this field is passed to the deparser

    bit<48> ingress_mac_tstamp;          // ingress IEEE 1588 timestamp (in nsec)
                                         // taken at the ingress MAC.
}

struct c0_ingress_parser_input_metadata_t {

}

struct c1_ingress_parser_input_metadata_t {

}

struct c2_ingress_parser_input_metadata_t {

}

struct c0_ingress_parser_output_metadata_t {

}

struct c1_ingress_parser_output_metadata_t {

}

struct c2_ingress_parser_output_metadata_t {

}

struct c0_ingress_input_metadata_t {

}

struct c1_ingress_input_metadata_t {

}

struct c2_ingress_input_metadata_t {

}

struct c0_ingress_output_metadata_t {
    // TM metadata
}

struct c1_ingress_output_metadata_t {

}

struct c2_ingress_output_metadata_t {
    // TM metadata
}

struct c3_egress_input_metadata_t {

}

struct c3_egress_output_metadata_t {

}

struct c3_egress_parser_input_metadata_t {

}

struct c3_egress_parser_output_metadata_t {

}

parser IngressParserC0<H, M>(
    packet_in buff,
    out H parsed_hdr,
    inout M meta,
    in c0_parser_input_metadata_t istd,
    out c0_parser_output_metadata_t ostd);

control IngressC0<H, M>(
    inout H hdr,
    inout M meta,
    in c0_ingress_input_metadata_t istd,
    out c0_ingress_output_metadata_t ostd);

control IngressDeparserC0<H, M>(
    packet_out buff,
    inout H hdr,
    in M meta,
    out clone_meta clone,
    out resubmit_meta resubmit,
    in c0_ingress_output_metadata_t istd);

parser IngressParserC1<H, M>(
    packet_in buff,
    out H parsed_hdr,
    inout M meta,
    in c1_ingress_parser_input_metadata_t istd,
    out c1_ingress_parser_output_metadata_t ostd);

control IngressC1<H, M>(
    inout H hdr,
    inout M meta,
    in c1_ingress_input_metadata_t istd,
    out c1_ingress_output_metadata_t ostd);

control IngressDeparserC1<H, M>(
    packet_out buff,
    inout H hdr,
    in M meta,
    in c1_ingress_output_metadata_t istd);

parser IngressParserC2<H, M>(
    packet_in buff,
    out H parsed_hdr,
    inout M meta,
    in c2_ingress_parser_input_metadata_t istd,
    out c2_ingress_parser_output_metadata_t ostd);

control IngressC2<H, M>(
    inout H hdr,
    inout M meta,
    in c2_ingress_input_metadata_t istd,
    out c2_ingress_output_metadata_t ostd);

control IngressDeparserC2<H, M>(
    packet_out buff,
    inout H hdr,
    in M meta,
    out recirc_meta recirc,
    out resubmit_meta resubmit,
    in c2_ingress_output_metadata_t istd);

parser EgressParser<H, M>(
    packet_in buff,
    out H parsed_hdr,
    inout M meta,
    in c3_egress_parser_input_metadata_t istd,
    out c3_egress_parser_output_metadata_t ostd);

control Egress<H, M>(
    inout H hdr,
    inout M meta,
    in c3_egress_input_metadata_t istd,
    out c3_egress_output_metadata_t ostd);

control EgressDeparser<H, M>(
    packet_out buff,
    inout H hdr,
    in M meta,
    out clone_meta clone,
    in c3_ingress_output_metadata_t istd);

// cloning
// digest
// resubmit
package Ingress0<H, M>(
    C32q_control_0_IngressParser<H, M> ip,
    C32q_control_0_Ingress<H, M> ig,
    C32q_control_0_IngressDeparser<H, M> id);

package Ingress1<H, M>(
    IngressParserC1<H, M> ip,
    IngressC1<H, M> ig,
    IngressDeparserC1<H, M> id);

// switching, UC, MC, CPU, recirc
// digest
// resubmit
package Ingress2<H, M>(
    IngressParserC2<H, M> ip,
    IngressC2<H, M> ig,
    IngressDeparserC2<H, M> id);

package IngressPipeline<H0, M0, H1, M1, H2, M2>(
    Ingress0<H0, M0> ig0,
    Ingress1<H1, M1> ig1,
    Ingress2<H2, M2> ig2);

// cloning
package EgressPipeline<H, M>(
    EgressParser<H, M> ep,
    Egress<H, M> eg,
    EgressDeparser<H, M> ed;
);

package Switch32Q<H0, M0, H1, M1, H2, M2, H3, M3>(
    IngressPipeline<H0, M0, H1, M1, H2, M2> ingress,
    EgressPipeline<H3, M3> egress,
);
