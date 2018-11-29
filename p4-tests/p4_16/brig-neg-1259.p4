
#include <core.p4>
#include <tna.p4>

// Headers and defines.

#define ETH_TYPE_IPV4 0x800
#define ETH_TYPE_VLAN 0x8100

#define CPU_PORT 64

header ethernet_t {
    bit<48> dst_addr;
    bit<48> src_addr;
    bit<16> ether_type;
}

header ipv4_t {
    bit<4>  version;
    bit<4>  ihl;
    bit<6>  dscp;
    bit<2>  ecn;
    bit<16> len;
    bit<16> identification;
    bit<3>  flags;
    bit<13> frag_offset;
    bit<8>  ttl;
    bit<8>  protocol;
    bit<16> hdr_checksum;
    bit<32> src_addr;
    bit<32> dst_addr;
}

header vlan_tag_t {
    bit<3>  pcp;
    bit<1>  cfi;
    bit<12> vid;
    bit<16> ether_type;
}

header metadata_hdr_t{
    bit<20>     pad0;
    bit<12>     vid;
}

struct headers_t {
    metadata_hdr_t bridged_meta;
	ethernet_t	ethernet;
	ipv4_t		ipv4;
    vlan_tag_t  vlan;
}

// Program-specific metadata

header mirror_metadata_t {
    MirrorId_t id;
    bit<22> pad0;
}

struct local_metadata_t {
    bit<1>      unknown_pkt_err;
    bit<31>     pad0;
    mirror_metadata_t mirr_md;
}

@pa_container_size("egress", "mirr_id", 16)
control clone_e2e_control(  inout headers_t hdr,
                            in local_metadata_t md)
{
    Mirror() mirror;

    action clone( bit<48> dst_addr, MirrorId_t mirr_id ){
//        hdr.ethernet.dst_addr = dst_addr;
        //mirror.emit(mirr_id, md.mirr_md);
        mirror.emit(mirr_id);
    }

    action do_not_clone(){

    }

    table clone_e2e{
        key = {
            hdr.ethernet.dst_addr: exact;
        }

        actions = {
            clone;
            do_not_clone;
        }

        default_action = do_not_clone;
    }

    apply{
        clone_e2e.apply();
    }
}


// Ingress parser

parser ingress_parser(  packet_in packet,
                        out headers_t hdr,
                        out local_metadata_t ig_md,
                        out ingress_intrinsic_metadata_t ig_intr_md) 
{
    state start {

        ig_md.unknown_pkt_err = 0;
        hdr.bridged_meta.pad0 = 0x12345;
        hdr.bridged_meta.setValid();

        // Remove ingress intrinsic metadata
        packet.extract(ig_intr_md);

        // Remove the next 64-bit that seems unused at the moment.
        packet.advance(64);

        // Parse ethernet and following headers.
        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type){
            ETH_TYPE_IPV4: parse_ipv4;
            ETH_TYPE_VLAN: parse_vlan;
            default: unknown_packet_err;
        }
    }

    state parse_vlan {
        packet.extract(hdr.vlan);
        transition select( hdr.vlan.ether_type ){
            ETH_TYPE_IPV4: parse_ipv4;
            default: unknown_packet_err;
        }
    }

    state parse_ipv4 {
        packet.extract(hdr.ipv4);
        transition accept;
    }

    state unknown_packet_err{
        ig_md.unknown_pkt_err = 1;
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
    action set_egress_port( PortId_t port, bit<12> vid ){
        ig_tm_md.ucast_egress_port = port;
        hdr.bridged_meta.vid = vid;
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
            drop;
        }

        const default_action = drop;
    }

    apply {
        if (ig_md.unknown_pkt_err != 0){
            set_egress_port(CPU_PORT,0);
        }
        else{
            set_output.apply();            
        }
    }
}

// Ingress deparser

control ingress_deparser(   packet_out packet,
                            inout headers_t hdr,
                            in local_metadata_t ig_md,
                            in ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md)
{

    apply {
//        packet.emit(hdr.ethernet);
//        packet.emit(hdr.vlan);
//        packet.emit(hdr.ipv4);
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
        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type){
            ETH_TYPE_IPV4: parse_ipv4;
            ETH_TYPE_VLAN: parse_vlan;
            default: accept;
        }
    }

    state parse_vlan {
        packet.extract(hdr.vlan);
        transition select( hdr.vlan.ether_type ){
            ETH_TYPE_IPV4: parse_ipv4;
            default: accept;
        }
    }

    state parse_ipv4 {
        packet.extract(hdr.ipv4);
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

//    clone_e2e_control() clone_e2e_ctrl;
//    Mirror() mirror;

    action push_vlan_hdr(){
        hdr.vlan.setValid();
        hdr.ethernet.ether_type = ETH_TYPE_VLAN;
        hdr.vlan.vid = hdr.bridged_meta.vid;
        hdr.vlan.ether_type = ETH_TYPE_IPV4;
    }

    table push_vlan{
        actions = {
            push_vlan_hdr;
        }

        const default_action = push_vlan_hdr;
    }

    apply{ 
        if (hdr.bridged_meta.vid != 0){
            push_vlan.apply();            
        }
//        clone_e2e_ctrl.apply( hdr, eg_md, eg_intr_md );
//        mirror.emit( eg_md.mirr_md.id );
    }
}

control egress_deparser(    packet_out packet,
                            inout headers_t hdr,
                            in local_metadata_t eg_md,
                            in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr)
{
    clone_e2e_control() _clone_e2e;

    apply {
       packet.emit(hdr.ethernet);
       packet.emit(hdr.vlan);
       packet.emit(hdr.ipv4);

       _clone_e2e.apply(hdr, eg_md);
    }
}

/* PIPELINE AND SWITCH INSTANTIATIONS
 */

Pipeline(ingress_parser(),
         ingress_control(),
         ingress_deparser(),
         egress_parser(),
         egress_control(),
         egress_deparser()) pipeline;

Switch(pipeline) main;
