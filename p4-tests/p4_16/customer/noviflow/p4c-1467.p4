
#include <core.p4>
#include <tna.p4>

action nop() {}

header bridged_meta_hdr_t{
    bit<8> pad;
}

struct ingress_metadata_t {
    bit<16> mcast_group;
}

struct egress_metadata_t
{
    bit<7> pad0;
}


header ethernet_t {
    bit<48> dstAddr;
    bit<48> srcAddr;
    bit<16> etherType;
}


struct packet_headers_t {
    ethernet_t ethernet;
};

struct headers_t {
    packet_headers_t pkt;
};






parser ingress_parser( packet_in packet,
                        out headers_t hdr,
                        out ingress_metadata_t ig_md,
                        out ingress_intrinsic_metadata_t ig_intr_md)
{
    state start {

        packet.extract(ig_intr_md);
        packet.advance(64);
        transition accept;
    }
}






parser egress_parser( packet_in packet,
                        out headers_t hdr,
                        out egress_metadata_t eg_md,
                        out egress_intrinsic_metadata_t eg_intr_md)
{
    state start {


        packet.extract(eg_intr_md);
        packet.extract(hdr.pkt.ethernet);
        transition accept;
    }

}





control ingress_control( inout headers_t hdr,
                            inout ingress_metadata_t ig_md,
                            in ingress_intrinsic_metadata_t ig_intr_md,
                            in ingress_intrinsic_metadata_from_parser_t ig_prsr_md,
                            inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,
                            inout ingress_intrinsic_metadata_for_tm_t ig_tm_md)
{

    apply{
    }
}




control ingress_deparser( packet_out packet,
                            inout headers_t hdr,
                            in ingress_metadata_t ig_md,
                            in ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md)
{

    apply {

        packet.emit(hdr);
    }
}



control egress_control( inout headers_t hdr,
                        inout egress_metadata_t eg_md,
                        in egress_intrinsic_metadata_t eg_intr_md,
                        in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
                        inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
                        inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport)
{
 
    Hash<bit<16>>(HashAlgorithm_t.CRC64) sel_hash;

    action get_hash( )
    {
        hdr.pkt.ethernet.etherType = sel_hash.get({
                    hdr.pkt.ethernet.dstAddr,
                    hdr.pkt.ethernet.srcAddr
                });
    }

    table tb_hash {
        actions = {
            get_hash;
        }
        const default_action = get_hash;
    }

    apply {
        tb_hash.apply();
    }
}


control egress_deparser( packet_out packet,
                            inout headers_t hdr,
                            in egress_metadata_t eg_md,
                            in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr)
{
    apply {
        packet.emit(hdr.pkt);
    }
}




Pipeline(ingress_parser(),
         ingress_control(),
         ingress_deparser(),
         egress_parser(),
         egress_control(),
         egress_deparser()) pipeline;

Switch(pipeline) main;
