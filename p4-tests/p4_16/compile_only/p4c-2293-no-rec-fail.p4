/* -*- P4_16 -*- */
#include <core.p4>
#include <tna.p4>

typedef bit<48> mac_addr_t;
typedef bit<16> ethertype_t;
typedef bit<32> ipv4_addr_t;

header ethernet_t {
    mac_addr_t dst_mac_addr;
    mac_addr_t src_mac_addr;
    ethertype_t ethertype;
}

enum bit<8> ip_proto_t {
    TCP = 6,
    UDP = 17,
    FOO = 0x12,
    NONE = 0xAA
}

header ipv4_t {
    bit<4> version;
    bit<4> ihl;
    bit<8> diffserv;
    bit<16> total_len;
    bit<16> identification;
    bit<3> flags;
    bit<13> frag_offset;
    bit<8> ttl;
    ip_proto_t protocol;
    bit<16> hdr_checksum;
    ipv4_addr_t src_addr;
    ipv4_addr_t dst_addr;
}

#ifdef CASE_FIX_2
header foo_t {
    bit<16> f;
}
#endif

struct headers {
    ethernet_t ethernet;
    ipv4_t ipv4;
#ifdef CASE_FIX_2
    foo_t  foo;
#endif
}

struct ingress_metadata_t {
    ip_proto_t protocol;
}

struct egress_metadata_t {
}

struct egress_headers_t {
}

parser ig_prs(packet_in pkt,
    out headers hdr, out ingress_metadata_t ig_md,
    out ingress_intrinsic_metadata_t ig_intr_md)
{
    state start {
        pkt.extract(ig_intr_md);
        pkt.advance(PORT_METADATA_SIZE);
        
        transition meta_init;
    }
    
    state meta_init {
        ig_md.protocol = ip_proto_t.NONE;
        
        transition prs_ethernet;
    }
    
    state prs_ethernet {
        pkt.extract(hdr.ethernet);
        
        transition select(hdr.ethernet.ethertype) {
            0x0800: prs_ipv4;
#ifdef CASE_FIX_2
            0x0F00: prs_foo;
#endif
            
#ifdef CASE_FIX_1           
            default: accept;
#else            
            default: reject;
#endif            
        }
    }
    
    state prs_ipv4 {
        pkt.extract(hdr.ipv4);
        ig_md.protocol = hdr.ipv4.protocol;
        
        transition accept;
    }
#ifdef CASE_FIX_2
    state prs_foo {
        pkt.extract(hdr.foo);
        transition accept; 
    }
#endif
}

control ig_ctl(inout headers hdr, inout ingress_metadata_t ig_md,
    in ingress_intrinsic_metadata_t ig_intr_md,
    in ingress_intrinsic_metadata_from_parser_t ig_prsr_md,
    inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,
    inout ingress_intrinsic_metadata_for_tm_t ig_tm_md)
{
    action act_send(PortId_t port) {
        ig_tm_md.ucast_egress_port = port;
    }
    
    table tbl_forward {
        key = {
            ig_intr_md.ingress_port : exact;
        }
        actions = {
            act_send;
        }
        const entries = {
              0:  act_send(2);
            132 : act_send(134);
        }
    }
    
    apply {
        if (hdr.ipv4.isValid()) {
            hdr.ipv4.protocol = ig_md.protocol;
        }
        tbl_forward.apply();
    }
    
}

control ig_ctl_dprs(packet_out pkt, inout headers hdr,
    in ingress_metadata_t ig_md,
    in ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md)
{
    apply {
        pkt.emit(hdr);
    }
}

parser eg_prs(packet_in pkt,
    /* User */
    out egress_headers_t eg_hdr, out egress_metadata_t eg_md,
    /* Intrinsic */
    out egress_intrinsic_metadata_t eg_intr_md)
{
    
    state start {
        pkt.extract(eg_intr_md);
        transition accept;
    }
}

control eg_ctl(
    /* User */
    inout egress_headers_t eg_hdr, inout egress_metadata_t eg_md,
    /* Intrinsic */
    in egress_intrinsic_metadata_t eg_intr_md,
    in egress_intrinsic_metadata_from_parser_t eg_prsr_md,
    inout egress_intrinsic_metadata_for_deparser_t eg_dprsr_md,
    inout egress_intrinsic_metadata_for_output_port_t eg_oport_md)
{
    apply {
    }
}


control eg_ctl_dprs(packet_out pkt,
    /* User */
    inout egress_headers_t eg_hdr, in egress_metadata_t eg_md,
    /* Intrinsic */
    in egress_intrinsic_metadata_for_deparser_t eg_dprsr_md)
{
    apply {
        pkt.emit(eg_hdr);
    }
}

Pipeline(
    ig_prs(), ig_ctl(), ig_ctl_dprs(),
    eg_prs(), eg_ctl(), eg_ctl_dprs()) pipe;

Switch(pipe) main;
