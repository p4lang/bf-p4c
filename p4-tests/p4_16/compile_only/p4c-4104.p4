#include <core.p4>
#include <tna.p4>

header header_t {
    bit<1> Bufalo;
    bit<1> Nenana;
    bit<6> pad1;
    bit<1> Ackley;
    bit<1> Eastwood;
    bit<6> pad2;
}

struct metadata_t {
}

@pa_container_size("ingress", "hdr.Bufalo", 8)
@pa_container_size("ingress", "hdr.Ackley", 8)

parser SwitchIngressParser(
    packet_in packet,
    out header_t hdr,
    out metadata_t meta,
    out ingress_intrinsic_metadata_t ig_meta)
{
    state start {
        packet.extract(ig_meta);
        packet.advance(PORT_METADATA_SIZE);
        packet.extract(hdr);
        transition accept;
    }
}

control SwitchIngressDeparser(
    packet_out packet,
    inout header_t hdr,
    in metadata_t meta,
    in ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md)
{
    apply {
        packet.emit(hdr);
    }
}

control SwitchIngress(
        inout header_t hdr,
        inout metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md)
{
    action Pillager(bit<1> Ackley) {
        // Ackley and Eastwood should be packed together
        // Ackley is written from action data -> the contant written to Eastwood should be converted
        // to action data
        hdr.Ackley = Ackley;
        hdr.Eastwood = 1;

        // Nenana has the same alignment as Eastwood -> the constant stored in action data
        // for Eastwood should be reused.
        hdr.Nenana = 1;

        // this source operand should be immediate data - but with conflicting alignment compared
        // to Nenana
        hdr.Bufalo = 1;
    }
    table Eaton {
        actions = {
            Pillager();
        }
        key = {
            hdr.Ackley: exact;
        }
    }
    apply {
        Eaton.apply();
    }
}

// Empty egress parser/control blocks
parser EgressParser(
        packet_in pkt,
        out header_t hdr,
        out metadata_t eg_md,
        out egress_intrinsic_metadata_t eg_intr_md) {
    state start {
        pkt.extract(eg_intr_md);
        pkt.extract(hdr);
        transition accept;
    }
}

control EgressDeparser(
        packet_out pkt,
        inout header_t hdr,
        in metadata_t eg_md,
        in egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md) {
    apply {
    }
}

control Egress(
        inout header_t hdr,
        inout metadata_t eg_md,
        in egress_intrinsic_metadata_t eg_intr_md,
        in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
        inout egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
        inout egress_intrinsic_metadata_for_output_port_t eg_intr_oport_md) {
    apply {}
}

Pipeline(SwitchIngressParser(),
         SwitchIngress(),
         SwitchIngressDeparser(),
         EgressParser(),
         Egress(),
         EgressDeparser()) pipe;

Switch(pipe) main;

