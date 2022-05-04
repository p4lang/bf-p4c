#include <tofino/intrinsic_metadata.p4>

//=====================
//      DEFINES
//=====================

// Ethertypes
#define ETHERTYPE_IPV4 0x0800
#define ETHERTYPE_VLAN 0x8100

#define IP_PROTO_UDP   17
#define UDP_PORT_VXLAN 4789

// === Standard Headers ===

header_type ethernet_t
{
    fields
    {
        dstAddr0 : 8;
        dstAddr1 : 8;
        dstAddr2 : 8;
        dstAddr3 : 8;
        dstAddr4 : 8;
        dstAddr5 : 8;
        srcAddr0 : 8;
        srcAddr1 : 8;
        srcAddr2 : 8;
        srcAddr3 : 8;
        srcAddr4 : 8;
        srcAddr5 : 8;
        etherType : 16;
    }
}

header_type vlan_tag_t {
    fields {
        pcp : 3;
        cfi : 1;
        vid : 12;
        etherType : 16;
    }
}

header_type ipv4_t
{
    fields
    {
        version : 4;
        ihl : 4;
        diffserv : 8;
        totalLen : 16;
        identification : 16;
        flags : 3;
        fragOffset : 13;
        ttl : 8;
        protocol : 8;
        hdrChecksum : 16;
        srcAddr : 32;
        dstAddr : 32;
    }
}

header_type udp_t
{
    fields
    {
        srcPort : 16;
        dstPort : 16;
        length_ : 16;
        checksum : 16;
    }
}

header_type vxlan_t
{
    fields
    {
        flags     : 8;
        reserved  : 24;
        vni       : 24;
        reserved2 : 8;
    }
}

//========== metadata types and instances =============

header_type metadata_t
{
    fields
    {
    }
}
metadata metadata_t meta;


//========== packet header instances =============

#define VLAN_DEPTH 2
header ethernet_t   outer_eth;
header ipv4_t       outer_ipv4;
header udp_t        outer_udp;
header vxlan_t      vxlan_hdr;
header ethernet_t   inner_eth;
header vlan_tag_t   vlan_inner_tag[VLAN_DEPTH];
header ipv4_t       inner_ipv4;

//========= IPv4 CHECKSUM ================
field_list ipv4_field_list
{
    outer_ipv4.version;
    outer_ipv4.ihl;
    outer_ipv4.diffserv;
    outer_ipv4.totalLen;
    outer_ipv4.identification;
    outer_ipv4.flags;
    outer_ipv4.fragOffset;
    outer_ipv4.ttl;
    outer_ipv4.protocol;
    outer_ipv4.srcAddr;
    outer_ipv4.dstAddr;
}

field_list_calculation ipv4_chksum_calc
{
    input
    {
        ipv4_field_list;
    }
    algorithm : csum16;
    output_width: 16;
}

// This declaration means: update ipv4.hdrChecksum automatically upon egress
// using the field list specified
calculated_field outer_ipv4.hdrChecksum
{
    verify ipv4_chksum_calc;
    update ipv4_chksum_calc;
}

//========= UDP CHECKSUM ================
field_list ipv4_udp_checksum_list
{
    outer_ipv4.srcAddr;
    outer_ipv4.dstAddr;
    8'0;
    outer_ipv4.protocol;
    outer_udp.length_;
    outer_udp.srcPort;
    outer_udp.dstPort;
    outer_udp.length_;
    payload;
}

field_list_calculation ipv4_udp_checksum
{
    input
    {
        ipv4_udp_checksum_list;
    }
    algorithm : csum16;
    output_width : 16;
}

calculated_field outer_udp.checksum
{
    update ipv4_udp_checksum;
}

// ================= PARSER ================

parser start
{
    extract(outer_eth);
    return select(outer_eth.etherType)
    {
        ETHERTYPE_IPV4: parse_outer_ipv4;
        default: ingress;
    }
}

parser parse_outer_ipv4
{
    extract(outer_ipv4);
    return select(outer_ipv4.protocol)
    {
        IP_PROTO_UDP: parse_outer_udp;
        default: ingress;
    }
}

parser parse_outer_udp
{
    extract(outer_udp);
    return select(outer_udp.dstPort)
    {
        UDP_PORT_VXLAN: parse_vxlan;
        default: ingress;
    }
}

parser parse_vxlan
{
    extract(vxlan_hdr);
    return parse_inner_eth;
}


parser parse_inner_eth
{
    extract(inner_eth);
    return select(inner_eth.etherType)
    {
        ETHERTYPE_IPV4: parse_inner_ipv4;
        ETHERTYPE_VLAN: parse_inner_vlan;
        default: ingress;
    }
}

parser parse_inner_vlan
{
    extract(vlan_inner_tag[0]);
    return select(latest.etherType)
    {
        ETHERTYPE_IPV4: parse_inner_ipv4;
        ETHERTYPE_VLAN: parse_qinq_inner_vlan;
        default: ingress;
    }
}

parser parse_qinq_inner_vlan
{
    extract(vlan_inner_tag[1]);
    return select(latest.etherType)
    {
        ETHERTYPE_IPV4: parse_inner_ipv4;
        default: ingress;
    }
}

parser parse_inner_ipv4
{
    extract(inner_ipv4);
    return ingress;
}

//============= INGRESS PIPELINE ===================

action send_back()
{
    modify_field(ig_intr_md_for_tm.ucast_egress_port, ig_intr_md.ingress_port);
}

table forward
{
    actions
    {
        send_back;
    }
    default_action: send_back;
    size: 0;
}

action set_inner_vlan_1_vid()
{
    modify_field(vlan_inner_tag[1].vid, 3214);
}

table modify_vlan
{
    actions
    {
        set_inner_vlan_1_vid;
    }
    default_action: set_inner_vlan_1_vid;
    size: 0;
}

//==============================================
// ============== Ingress control ==============
//==============================================
control ingress
{
    apply(forward);
    if (vlan_inner_tag[1].valid == 1) {
        apply(modify_vlan);
    }
}
