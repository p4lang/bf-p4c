
#include <core.p4>
#include <tna.p4>


// Headers and defines.

typedef bit<8> inthdr_type_t;
const inthdr_type_t INTHDR_TYPE_BRIDGE = 0xfc;
const inthdr_type_t INTHDR_TYPE_CLONE_INGRESS = 0xfd;
const inthdr_type_t INTHDR_TYPE_CLONE_EGRESS = 0xfe;

header ethernet_t {
    bit<48> dst_addr;
    bit<48> src_addr;
    bit<16> ether_type;
}

header bridged_meta_hdr_t{
    inthdr_type_t hdr_type;
    bit<3>      pad1;
    bit<1>      do_clone;
    bit<12>     pad0;
    bit<6>      pad2;
    MirrorId_t  mirror_id;
}

struct headers_t {
    bridged_meta_hdr_t bridged_meta;
	ethernet_t	ethernet;
}

// Program-specific metadata

struct local_metadata_t {
    bit<1>      do_clone;
    bit<7>      pad0;
}

// Ingress parser

parser ingress_parser(  packet_in packet,
                        out headers_t hdr,
                        out local_metadata_t ig_md,
                        out ingress_intrinsic_metadata_t ig_intr_md) 
{
    state start {
        hdr.bridged_meta.hdr_type = INTHDR_TYPE_BRIDGE;
        hdr.bridged_meta.pad0 = 0;
        hdr.bridged_meta.setValid();

        // Remove ingress intrinsic metadata
        packet.extract(ig_intr_md);

        // Remove the next 64-bit that seems unused at the moment.
        packet.advance(64);

        // Parse ethernet header.
        packet.extract(hdr.ethernet);
        transition accept;
    }

}

// Ingress control

control ingress_control(    inout headers_t hdr,
                            inout local_metadata_t ig_md,
                            in ingress_intrinsic_metadata_t ig_intr_md,
                            in ingress_intrinsic_metadata_from_parser_t ig_prsr_md,
                            inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,
                            inout ingress_intrinsic_metadata_for_tm_t ig_tm_md) 
{

    Hash<bit<16>>(HashAlgorithm_t.CRC16) hash;

    action set_egress_port( PortId_t port, bit<12> vid ){
        ig_tm_md.ucast_egress_port = port;
    }

    action md_set_lag_hash(){
        ig_tm_md.level2_mcast_hash = (bit<13>)hash.get({ig_prsr_md.global_tstamp});
        ig_tm_md.level1_mcast_hash = (bit<13>)hash.get({ig_prsr_md.global_tstamp});
    }

    table set_lag_hash{
        actions = {
            md_set_lag_hash;
        }

        const default_action = md_set_lag_hash;
    }

    action set_multicast( MulticastGroupId_t mcast_grp ){
        ig_tm_md.mcast_grp_a = mcast_grp;
    }

    action drop() {
        ig_dprsr_md.drop_ctl = 0x1; // Drop packet.
    }

    table set_output{

        key = {
            ig_intr_md.ingress_port: exact;
        }

        actions = {
            set_egress_port;
            set_multicast;
            drop;
        }

        const default_action = set_multicast(2);
    }

    apply {
//        set_lag_hash.apply();
        set_output.apply();
        set_lag_hash.apply();
    }
}

// Ingress deparser

control ingress_deparser(   packet_out packet,
                            inout headers_t hdr,
                            in local_metadata_t ig_md,
                            in ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md)
{

    apply {
        packet.emit(hdr);
    }
}

// Egress parser

parser eg_parser(   packet_in packet,
                    out headers_t hdr,
                    out local_metadata_t eg_md,
                    out egress_intrinsic_metadata_t eg_intr_md) 
{

    state start {
        packet.extract(eg_intr_md);
        packet.extract(hdr.bridged_meta);
        transition accept;
    }

}

parser egress_parser(   packet_in packet,
                        out headers_t hdr,
                        out local_metadata_t eg_md,
                        out egress_intrinsic_metadata_t eg_intr_md)
{

    eg_parser() _eg_parser;

    state start {
        _eg_parser.apply(packet, hdr, eg_md, eg_intr_md);
        transition accept;
    }
}

control egress_control( inout headers_t hdr,
                        inout local_metadata_t eg_md,
                        in egress_intrinsic_metadata_t eg_intr_md,
                        in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
                        inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
                        inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport)
{
    apply{}
}

control egress_deparser(    packet_out packet,
                            inout headers_t hdr,
                            in local_metadata_t eg_md,
                            in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr)
{
    apply {
        packet.emit(hdr.ethernet);
    }
}

// Pipeline definition.

Pipeline(ingress_parser(),
         ingress_control(),
         ingress_deparser(),
         egress_parser(),
         egress_control(),
         egress_deparser()) pipeline;

Switch(pipeline) main;
