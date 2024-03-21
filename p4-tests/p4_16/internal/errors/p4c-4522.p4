#include <core.p4>
#include <tna.p4>

header hdr_t {
    bit<8> x;
    bit<8> y;
    bit<8> z;
}

struct myHeaders {
  hdr_t hdr;
}

struct metadata {
}

parser IngressParser(packet_in        pkt,
    out myHeaders         hdr,
    out metadata         meta,
    out ingress_intrinsic_metadata_t  ig_intr_md)
{
    state start {
        pkt.extract(ig_intr_md);
        pkt.advance(PORT_METADATA_SIZE);
        pkt.extract(hdr.hdr);
        transition accept;
    }
}

control Ingress(
    inout myHeaders                       hdr,
    inout metadata                     meta,
    in    ingress_intrinsic_metadata_t               ig_intr_md,
    in    ingress_intrinsic_metadata_from_parser_t   ig_prsr_md,
    inout ingress_intrinsic_metadata_for_deparser_t  ig_dprsr_md,
    inout ingress_intrinsic_metadata_for_tm_t        ig_tm_md)
{
    Register<bit<1>, bit<8>>(1<<8, 0) reg1;
    RegisterAction<bit<1>, bit<8>, bit<1>>(reg1) ract1 = {
      void apply(inout bit<1> reg, out bit<1> val) {
        reg = 0;    // ok (clr_bit)
      }
    };
    RegisterAction<bit<1>, bit<8>, bit<1>>(reg1) ract2 = {
      void apply(inout bit<1> reg, out bit<1> val) {
        val = ~reg; // ok (read_bitc)
      }
    };
    RegisterAction<bit<1>, bit<8>, bit<1>>(reg1) ract3 = {
      void apply(inout bit<1> reg, out bit<1> val) {
        reg = reg ^ 1;    // expect error: "Only simple assignments are supported for one-bit registers\."
      }
    };

    apply {
      bit<1> val1b = ract1.execute(hdr.hdr.x);
      bit<1> val1b2 = ract2.execute(hdr.hdr.x);
      bit<1> val1b3 = ract3.execute(hdr.hdr.x);

      ig_tm_md.ucast_egress_port = 2;
      ig_tm_md.bypass_egress = 1;
    }
}

control IngressDeparser(
    packet_out pkt,
    inout myHeaders hdr,
    in metadata meta,
    in ingress_intrinsic_metadata_for_deparser_t ingressDeparserMetadata
) {
    apply {
        pkt.emit(hdr);
    }
}
parser EgressParser(packet_in        pkt,
    /* User */
    out myHeaders          hdr,
    out metadata           meta,
    out egress_intrinsic_metadata_t  eg_intr_md)
{
    state start {}
}

control Egress(
    /* User */
    inout myHeaders hdr,
    inout metadata  meta,
    in    egress_intrinsic_metadata_t                  eg_intr_md,
    in    egress_intrinsic_metadata_from_parser_t      eg_prsr_md,
    inout egress_intrinsic_metadata_for_deparser_t     eg_dprsr_md,
    inout egress_intrinsic_metadata_for_output_port_t  eg_oport_md)
{
    apply {}
}

control EgressDeparser(packet_out pkt,
    /* User */
    inout myHeaders                       hdr,
    in    metadata                      meta,
    /* Intrinsic */
    in    egress_intrinsic_metadata_for_deparser_t  eg_dprsr_md)
{
    apply {}
}


/************ F I N A L   P A C K A G E ******************************/
Pipeline(
    IngressParser(),
    Ingress(),
    IngressDeparser(),
    EgressParser(),
    Egress(),
    EgressDeparser()
) pipe;

Switch(pipe) main;

