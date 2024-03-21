#include <core.p4>
#include <t2na.p4>

typedef bit<48> mac_addr_t;
typedef bit<32> ipv4_addr_t;
typedef bit<128> ipv6_addr_t;

typedef bit<16> ether_type_t;
const ether_type_t ETHERTYPE_ARP = 16w0x0806;
const ether_type_t ETHERTYPE_IPV4 = 16w0x0800;
const ether_type_t ETHERTYPE_IPV6 = 16w0x86dd;

typedef bit<8> ip_protocol_t;
const ip_protocol_t IP_PROTOCOLS_ICMP = 1;
const ip_protocol_t IP_PROTOCOLS_TCP = 6;
const ip_protocol_t IP_PROTOCOLS_UDP = 17;

typedef bit<16> l4_port_t;
const l4_port_t DEFAULT_UDP_PORT_VXLAN = 4789;

//const ipv4_addr_t KTM_LOOPBACK_IP = 32w0x0A0A0A0A; // 10.10.10.10
//const ipv4_addr_t EC_VTEP_IP = 32w0x0B0B0B0B; // 11.11.11.11

header ethernet_h {
    mac_addr_t dst_addr;
    mac_addr_t src_addr;
    bit<16> ether_type;
}

header ipv4_h {
    bit<4> version;
    bit<4> ihl;
    bit<8> diffserv;
    bit<16> total_len;
    bit<16> identification;
    bit<3> flags;
    bit<13> frag_offset;
    bit<8> ttl;
    bit<8> protocol;
    bit<16> hdr_checksum;
    ipv4_addr_t src_addr;
    ipv4_addr_t dst_addr;
}

header ipv6_h {
    bit<4> version;
    bit<8> traffic_class;
    bit<20> flow_label;
    bit<16> payload_len;
    bit<8> next_hdr;
    bit<8> hop_limit;
    ipv6_addr_t src_addr;
    ipv6_addr_t dst_addr;
}

header tcp_h {
    bit<16> src_port;
    bit<16> dst_port;
    bit<32> seq_no;
    bit<32> ack_no;
    bit<4> data_offset;
    bit<4> res;
    bit<8> flags;
    bit<16> window;
    bit<16> checksum;
    bit<16> urgent_ptr;
}

@pa_no_overlay("egress", "hdr.udp.src_port")
@pa_no_overlay("egress", "hdr.udp.dst_port")
@pa_no_overlay("egress", "hdr.udp.length")
@pa_no_overlay("egress", "hdr.udp.checksum")
header udp_h {
    bit<16> src_port;
    bit<16> dst_port;
    bit<16> length;
    bit<16> checksum;
}

header vxlan_h {
    bit<8> flags;
    bit<24> reserved;
    bit<24> vni;
    bit<8> reserved2;
}

@flexible
struct ktm_metadata_extension_t {
    bool ktm_vx_pkt;
    bool me2client; // dip:EC_VTEP_IP sip:KTM_LOOPBACK_IP vxlan inner_dip:CLIENT_IP inner_sip
    bool me2server; // 
    ipv4_addr_t eip;
    ipv6_addr_t eip6;
    ipv4_addr_t server_ip;
    ipv6_addr_t server_ip6;
    ipv4_addr_t server_vtep_ip;
    mac_addr_t server_vtep_mac;
    ipv4_addr_t KTM_LOOPBACK_IP;
    ipv4_addr_t EC_VTEP_IP;
    mac_addr_t ktm_vtep_mac;
    mac_addr_t ec_vtep_mac;
    bit<24> customize_vni;
    bit<16> customize_vxlan_dst_port;
    bit<32> vxlan_src_port_hash_base32;
}

header switch_bridged_metadata_h {
    ktm_metadata_extension_t ktm_meta;
    @flexible bit<8> padding;
}

struct switch_header_t {
    switch_bridged_metadata_h bridged_md;
    ethernet_h ethernet;
    ipv4_h ipv4;
    ipv6_h ipv6;
    udp_h udp;
    tcp_h tcp;
    vxlan_h vxlan;
    ethernet_h inner_ethernet;
    ipv4_h inner_ipv4;
    ipv6_h inner_ipv6;
    udp_h inner_udp;
    tcp_h inner_tcp;
}

typedef bit<2> switch_pkt_type_t;
typedef bit<2> switch_ip_type_t;
typedef bit<2> switch_ip_frag_t;
typedef bit<8> switch_hostif_trap_t;

struct switch_lookup_fields_t {
    switch_pkt_type_t pkt_type;

    mac_addr_t mac_src_addr;
    mac_addr_t mac_dst_addr;
    bit<16> mac_type;
    bit<3> pcp;

    // 1 for ARP request, 2 for ARP reply.
    bit<16> arp_opcode;

    switch_ip_type_t ip_type;
    bit<8> ip_proto;
    bit<8> ip_ttl;
    bit<8> ip_tos;
    switch_ip_frag_t ip_frag;
    bit<128> ip_src_addr;
    bit<128> ip_dst_addr;
    bit<20> ipv6_flow_label;

    bit<8> tcp_flags;
    bit<16> l4_src_port;
    bit<16> l4_dst_port;
    bit<16> hash_l4_src_port;
    bit<16> hash_l4_dst_port;

    bool mpls_pkt;
    bit<1> mpls_router_alert_label;
    bit<20> mpls_lookup_label;

    switch_hostif_trap_t hostif_trap_id;
}

typedef bit<2> switch_myip_type_t;

struct switch_ingress_flags_t {
    bool ipv4_checksum_err;
    bool inner_ipv4_checksum_err;
    bool inner2_ipv4_checksum_err;
    bool link_local;
    bool routed;
    bool acl_deny;
    bool racl_deny;
    bool port_vlan_miss;
    bool rmac_hit;
    bool dmac_miss;
    switch_myip_type_t myip;
    bool glean;
    bool storm_control_drop;
    bool acl_meter_drop;
    bool port_meter_drop;
    bool flood_to_multicast_routers;
    bool peer_link;
    bool capture_ts;
    bool mac_pkt_class;
    bool pfc_wd_drop;
    bool bypass_egress;
    bool mpls_trap;
    bool srv6_trap;
    // Add more flags here.
}

struct switch_egress_flags_t {
    bool routed;
    bool bypass_egress;
    bool acl_deny;
    bool mlag_member;
    bool peer_link;
    bool capture_ts;
    bool wred_drop;
    bool port_meter_drop;
    bool acl_meter_drop;
    bool pfc_wd_drop;
    bool isolation_packet_drop;

    // Add more flags here.
}



struct switch_ingress_metadata_t {
    bit<16> tcp_udp_checksum;
    bit<16> inner_tcp_udp_checksum;
    switch_lookup_fields_t lkp;
    switch_ingress_flags_t flags;
    ktm_metadata_extension_t ktm_meta;
}

struct switch_egress_metadata_t {
    bit<16> tcp_udp_checksum;
    bit<16> inner_tcp_udp_checksum;
    switch_lookup_fields_t lkp;
    switch_egress_flags_t flags;
    ktm_metadata_extension_t ktm_meta;
}

parser SwitchIngressParser(
        packet_in pkt,
        out switch_header_t hdr,
        out switch_ingress_metadata_t ig_md,
        out ingress_intrinsic_metadata_t ig_intr_md) {

    Checksum() ipv4_checksum;
    Checksum() tcp_checksum;
    Checksum() udp_checksum;
    Checksum() inner_ipv4_checksum;
    Checksum() inner_tcp_checksum;
    Checksum() inner_udp_checksum;

    state start {
        pkt.extract(ig_intr_md);
        pkt.advance(PORT_METADATA_SIZE);
        transition parse_packet;
    }

    state parse_packet {
        transition parse_ethernet;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type) {
            ETHERTYPE_IPV4 : parse_ipv4;
            ETHERTYPE_IPV6 : parse_ipv6;
            default : accept;
        }
    }

    state parse_ipv6 {
        pkt.extract(hdr.ipv6);
        transition select (hdr.ipv6.next_hdr) {
            IP_PROTOCOLS_TCP : parse_tcp;
            IP_PROTOCOLS_UDP : parse_udp;
            default : accept;
        }
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        ipv4_checksum.add(hdr.ipv4);
        tcp_checksum.subtract({hdr.ipv4.src_addr,hdr.ipv4.dst_addr});
        udp_checksum.subtract({hdr.ipv4.src_addr,hdr.ipv4.dst_addr});
        transition select(hdr.ipv4.ihl) {
            5 : parse_ipv4_no_options;
            default : accept;
        }
    }

    state parse_ipv4_no_options {
        transition select(hdr.ipv4.protocol, hdr.ipv4.frag_offset) {
            (IP_PROTOCOLS_TCP, 0) : parse_tcp;
            (IP_PROTOCOLS_UDP, 0) : parse_udp;
            // Do NOT parse the next header if IP packet is fragmented.
            default : accept;
        }
    }

    state parse_udp {
        pkt.extract(hdr.udp);
        udp_checksum.subtract_all_and_deposit(ig_md.tcp_udp_checksum);
        udp_checksum.subtract({hdr.udp.checksum});
        udp_checksum.subtract({hdr.udp.src_port, hdr.udp.dst_port});
        transition select(hdr.udp.dst_port) {
            DEFAULT_UDP_PORT_VXLAN : parse_vxlan;
            default : accept;
        }
    }

    state parse_tcp {
        pkt.extract(hdr.tcp);
        tcp_checksum.subtract_all_and_deposit(ig_md.tcp_udp_checksum);
        tcp_checksum.subtract({hdr.tcp.checksum});
        tcp_checksum.subtract({hdr.tcp.src_port, hdr.tcp.dst_port});
        transition accept;
    }

    state parse_vxlan {
        pkt.extract(hdr.vxlan);
        transition parse_inner_ethernet;
    }

    state parse_inner_ethernet {
        pkt.extract(hdr.inner_ethernet);
        transition select(hdr.inner_ethernet.ether_type) {
            ETHERTYPE_IPV4 : parse_inner_ipv4;
            ETHERTYPE_IPV6 : parse_inner_ipv6;
            default : accept;
        }
    }

    state parse_inner_ipv6 {
        pkt.extract(hdr.inner_ipv6);
        transition select(hdr.inner_ipv6.next_hdr) {
            IP_PROTOCOLS_TCP : parse_inner_tcp;
            IP_PROTOCOLS_UDP : parse_inner_udp;
        }
    }

    state parse_inner_ipv4 {
        pkt.extract(hdr.inner_ipv4);

        //inner_ipv4_checksum.add(hdr.inner_ipv4);
        //inner_tcp_checksum.subtract({hdr.inner_ipv4.src_addr, hdr.inner_ipv4.dst_addr});
        //inner_udp_checksum.subtract({hdr.inner_ipv4.src_addr, hdr.inner_ipv4.dst_addr});
        transition select(hdr.inner_ipv4.protocol) {
            IP_PROTOCOLS_TCP : parse_inner_tcp;
            IP_PROTOCOLS_UDP : parse_inner_udp;
            default : accept;
        }
    }

    state parse_inner_udp {
        pkt.extract(hdr.inner_udp);

        //inner_udp_checksum.subtract_all_and_deposit(ig_md.inner_tcp_udp_checksum);
        //inner_udp_checksum.subtract({hdr.inner_udp.checksum});
        //inner_udp_checksum.subtract({hdr.inner_udp.src_port, hdr.inner_udp.dst_port});
        transition accept;
    }

    state parse_inner_tcp {
        pkt.extract(hdr.inner_tcp);
        //inner_tcp_checksum.subtract_all_and_deposit(ig_md.inner_tcp_udp_checksum);
        //inner_tcp_checksum.subtract({hdr.inner_tcp.checksum});
        //inner_tcp_checksum.subtract({hdr.inner_tcp.src_port, hdr.inner_tcp.dst_port});
        transition accept;
    }

}

struct ktm_drop_ip_sample_t {
    ipv4_addr_t src_addr;
    ipv4_addr_t dst_addr;
}

struct ktm_drop_protocol_sample_t {
    ip_protocol_t protocol;
}

struct ktm_drop_port_sample_t{
    bit<16> src_port;
    bit<16> dst_port;
}

control SwitchIngress(
        inout switch_header_t hdr,
        inout switch_ingress_metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_intr_from_prsr,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm) {

    Hash<bit<16>>(HashAlgorithm_t.CRC16) ktm_ingress_drop_pkt_sample_hash;
    bit<2> drop_idx;

    Register<ktm_drop_ip_sample_t,_>(4) ktm_ingress_drop_ip_sample_reg;
    RegisterAction<_, bit<2>, void>(ktm_ingress_drop_ip_sample_reg) do_ktm_ingress_drop_ip_sample = {
        void apply(inout ktm_drop_ip_sample_t sample) {
            sample.src_addr = hdr.ipv4.src_addr;
            sample.dst_addr = hdr.ipv4.dst_addr;
        }
    };

    Register<ktm_drop_protocol_sample_t,_>(4) ktm_ingress_drop_protocol_sample_reg;
    RegisterAction<_, bit<2>, void>(ktm_ingress_drop_protocol_sample_reg) do_ktm_ingress_drop_protocol_sample = {
        void apply(inout ktm_drop_protocol_sample_t sample) {
            sample.protocol = hdr.ipv4.protocol;
        }
    };

    
    bit<16> drop_src_port = 0;
    bit<16> drop_dst_port = 0;
    Register<ktm_drop_port_sample_t,_>(4) ktm_ingress_drop_port_sample_reg;
    RegisterAction<_, bit<2>, void>(ktm_ingress_drop_port_sample_reg) do_ktm_ingress_drop_port_sample = {
        void apply(inout ktm_drop_port_sample_t sample) {
            sample.src_port = drop_src_port;
            sample.dst_port = drop_dst_port;
        }
    };

    
    DirectCounter<bit<64>>(CounterType_t.PACKETS_AND_BYTES) ktm_dnat_stats;

    action ktm_dnat_hit(ipv4_addr_t server_vtep_ip, ipv4_addr_t server_ip, mac_addr_t server_vtep_mac, bit<16> customize_vxlan_dst_port, bit<24> customize_vni) {
        ig_md.lkp.ip_dst_addr[95:64] = server_vtep_ip;
        ig_md.ktm_meta.server_vtep_ip = server_vtep_ip;
        ig_md.ktm_meta.server_ip = server_ip;
        ig_md.ktm_meta.server_vtep_mac = server_vtep_mac;
        ig_md.ktm_meta.customize_vxlan_dst_port = customize_vxlan_dst_port;
        ig_md.ktm_meta.customize_vni = customize_vni;
        ig_md.ktm_meta.me2server = true;
        ig_md.ktm_meta.ktm_vx_pkt = true;
        ktm_dnat_stats.count();
    }

    table ktm_dnat_table {
        key = {
            hdr.ipv4.dst_addr : exact;
        }

        actions = {
            ktm_dnat_hit;
            //NoAction;
        }

        //const default_action = NoAction;
        counters = ktm_dnat_stats;
    }

    DirectCounter<bit<64>>(CounterType_t.PACKETS_AND_BYTES) ktm_dnat6_stats;

    action ktm_dnat6_hit(ipv4_addr_t server_vtep_ip, ipv6_addr_t server_ip6, mac_addr_t server_vtep_mac, bit<16> customize_vxlan_dst_port, bit<24> customize_vni) {
        ig_md.ktm_meta.server_ip6 = server_ip6;
        ig_md.lkp.ip_dst_addr[95:64] = server_vtep_ip;
        ig_md.ktm_meta.server_vtep_ip = server_vtep_ip;
        ig_md.ktm_meta.server_vtep_mac = server_vtep_mac;
        ig_md.ktm_meta.customize_vxlan_dst_port = customize_vxlan_dst_port;
        ig_md.ktm_meta.customize_vni = customize_vni;
        ig_md.ktm_meta.me2server = true;
        ig_md.ktm_meta.ktm_vx_pkt = true;
        ktm_dnat6_stats.count();
    }

    table ktm_dnat6_table {
        key = {
            hdr.ipv6.dst_addr : exact;
        }

        actions = {
            ktm_dnat6_hit;
        }

        counters = ktm_dnat6_stats;
    }

    DirectCounter<bit<64>>(CounterType_t.PACKETS_AND_BYTES) ktm_snat_stats;

    action ktm_snat_hit(ipv4_addr_t eip) {
        ig_md.ktm_meta.eip = eip;
        ig_md.ktm_meta.me2client = true;
        ktm_snat_stats.count();
    }

    action ktm_snat_miss() {
        ig_intr_md_for_dprsr.drop_ctl = 0x1;
        ktm_snat_stats.count();
    }

    table ktm_snat_table {
        key = {
            hdr.inner_ipv4.src_addr : exact;
        }

        actions = {
            ktm_snat_hit;
            ktm_snat_miss;
            //NoAction;
        }

        const default_action = ktm_snat_miss;
        counters = ktm_snat_stats;
    }

    DirectCounter<bit<64>>(CounterType_t.PACKETS_AND_BYTES) ktm_snat6_stats;

    action ktm_snat6_hit(ipv6_addr_t eip6) {
        ig_md.ktm_meta.eip6 = eip6;
        ig_md.ktm_meta.me2client = true;
        ktm_snat6_stats.count();
    }

    action ktm_snat6_miss() {
        ig_intr_md_for_dprsr.drop_ctl = 0x1;
        ktm_snat6_stats.count();
    }

    table ktm_snat6_table {

        key = {
            hdr.inner_ipv6.src_addr : exact;
        }

        actions = {
            ktm_snat6_hit;
            ktm_snat6_miss;
        }

        const default_action = ktm_snat6_miss;
        counters = ktm_snat6_stats;
    }

    action fib_miss(inout switch_ingress_metadata_t ig_md) {
            ig_md.flags.routed = false;
            ig_intr_md_for_dprsr.drop_ctl = 0x1;
    }

    action fib_hit(inout switch_ingress_metadata_t ig_md, PortId_t port) {
        ig_md.flags.routed = true;
        ig_intr_md_for_tm.ucast_egress_port = port;
    }

    table fib {

        key = {
            ig_md.lkp.ip_dst_addr[95:64] : lpm;
        }

        actions = {
            fib_miss(ig_md);
            fib_hit(ig_md);
        }

        const default_action = fib_miss(ig_md);
    }

    table fib6 {
        key = {
            ig_md.lkp.ip_dst_addr : lpm;
        }

        actions = {
            fib_miss(ig_md);
            fib_hit(ig_md);
        }

        const default_action = fib_miss(ig_md);

    }

    action add_bridged_md(inout switch_bridged_metadata_h bridged_md, in switch_ingress_metadata_t ig_md) {

        bridged_md.setValid();
        //bridged_md.ktm_meta.me2client = ig_md.ktm_meta.me2client;
        //bridged_md.ktm_meta.me2server = ig_md.ktm_meta.me2server;
        bridged_md.ktm_meta = ig_md.ktm_meta;
    }

    Register<ipv4_addr_t,_>(1) ktm_loop_ip_register; 
    RegisterAction<_, bit<1>, ipv4_addr_t>(ktm_loop_ip_register) get_ktm_loopback_ip = {
        void apply(inout ipv4_addr_t reg_ip, out ipv4_addr_t ip) {
            ip = reg_ip;
        }
    };
    Register<ipv4_addr_t,_>(1) ec_vtep_ip_register;
    RegisterAction<_, bit<1>, ipv4_addr_t>(ec_vtep_ip_register) get_ec_vtep_ip = {
        void apply(inout ipv4_addr_t reg_ip, out ipv4_addr_t ip) {
            ip = reg_ip;
        }
    };


    apply {

        if (hdr.ipv4.isValid()) {
            ig_md.lkp.ip_dst_addr[95:64] = hdr.ipv4.dst_addr;
        } else if (hdr.ipv6.isValid()) {
            ig_md.lkp.ip_dst_addr = hdr.ipv6.dst_addr;
        }

        if (hdr.vxlan.isValid()) {
            //ig_md.ktm_meta.KTM_LOOPBACK_IP = get_ktm_loopback_ip.execute(0);
            //ig_md.ktm_meta.EC_VTEP_IP = get_ec_vtep_ip.execute(0);
            ig_md.ktm_meta.KTM_LOOPBACK_IP = 32w0x0a0a0a0a;
            ig_md.ktm_meta.EC_VTEP_IP = 32w0x0b0b0b0b;

            if (hdr.ipv4.dst_addr == ig_md.ktm_meta.KTM_LOOPBACK_IP) {

                ig_md.lkp.ip_dst_addr[95:64] = ig_md.ktm_meta.EC_VTEP_IP;
                ig_md.ktm_meta.me2client = true;
                ig_md.ktm_meta.ktm_vx_pkt = true;
                
                if (hdr.inner_ipv4.isValid()) {
                    ktm_snat_table.apply();
                } else if (hdr.inner_ipv6.isValid()) {
                    ktm_snat6_table.apply();
                }
                
            } else {
                if (hdr.ipv4.isValid()) {
                    ktm_dnat_table.apply();
                } else if (hdr.ipv6.isValid()) {

                }
                
            }

        }
        
        if (hdr.ipv4.isValid()) {
            //ig_md.lkp.ip_dst_addr[95:64] = hdr.ipv4.dst_addr;

            fib.apply();

        } else if (hdr.ipv6.isValid()) {
            //ig_md.lkp.ip_dst_addr = hdr.ipv6.dst_addr;

            fib6.apply();
        }
        
        /*
        if (ig_md.flags.routed && ig_md.ktm_meta.me2client) {
            ktm_snat_table.apply();
            //hdr.ipv4.dst_addr = EC_VTEP_IP;
            //hdr.ipv4.src_addr = KTM_LOOPBACK_IP;
            //hdr.udp.checksum = 0;
        } else if (ig_md.flags.routed && ig_md.ktm_meta.me2server) {

            if (hdr.udp.isValid()) {
                hdr.inner_udp.setValid();
                hdr.inner_udp = hdr.udp;
                ig_md.inner_tcp_udp_checksum = ig_md.tcp_udp_checksum;
            } else if (hdr.tcp.isValid()) {
                hdr.inner_tcp.setValid();
                hdr.inner_tcp = hdr.tcp;
                hdr.tcp.setInvalid();
                ig_md.inner_tcp_udp_checksum = ig_md.tcp_udp_checksum;
            }

            hdr.inner_ipv4.setValid();
            hdr.inner_ipv4 = hdr.ipv4;
            hdr.inner_ipv4.dst_addr = ig_md.ktm_meta.server_ip;

            hdr.inner_ethernet.setValid();
            hdr.inner_ethernet = hdr.ethernet;
            hdr.inner_ethernet.dst_addr = ig_md.ktm_meta.server_vtep_mac;

            hdr.vxlan.setValid();

            hdr.udp.setValid();
            hdr.udp.src_port = DEFAULT_UDP_PORT_VXLAN;
            hdr.udp.dst_port = DEFAULT_UDP_PORT_VXLAN;
            hdr.udp.length = hdr.inner_ipv4.total_len + 30;
            hdr.udp.checksum = 0;
            
            hdr.ipv4.dst_addr = ig_md.ktm_meta.server_vtep_ip;
            hdr.ipv4.src_addr = KTM_LOOPBACK_IP;
            hdr.ipv4.total_len = hdr.inner_ipv4.total_len + 50;
        }
        */

        add_bridged_md(hdr.bridged_md, ig_md);
        //ig_intr_md_for_tm.bypass_egress = 1w1;
        if ((ig_intr_md_for_dprsr.drop_ctl == 0x1) && hdr.ipv4.isValid()) {
            drop_idx = ktm_ingress_drop_pkt_sample_hash.get({hdr.ipv4.src_addr, hdr.ipv4.dst_addr, hdr.ipv4.protocol})[1:0];
            if (hdr.udp.isValid()) {
                drop_src_port = hdr.udp.src_port;
                drop_dst_port = hdr.udp.dst_port;
            } else if (hdr.tcp.isValid()) {
                drop_src_port = hdr.tcp.src_port;
                drop_dst_port = hdr.tcp.dst_port;
            }

            do_ktm_ingress_drop_ip_sample.execute(drop_idx);
            do_ktm_ingress_drop_protocol_sample.execute(drop_idx);
            do_ktm_ingress_drop_port_sample.execute(drop_idx);
        }
    }

}

control SwitchIngressDeparser(
    packet_out pkt,
    inout switch_header_t hdr,
    in switch_ingress_metadata_t ig_md,
    in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) {

    Checksum() ipv4_checksum;
    Checksum() udp_checksum;
    Checksum() inner_ipv4_checksum;
    Checksum() inner_udp_checksum;
    Checksum() inner_tcp_checksum;

    apply {
        /*
        hdr.ipv4.hdr_checksum = ipv4_checksum.update(
            {
                hdr.ipv4.version,
                hdr.ipv4.ihl,
                hdr.ipv4.diffserv,
                hdr.ipv4.total_len,
                hdr.ipv4.identification,
                hdr.ipv4.flags,
                hdr.ipv4.frag_offset,
                hdr.ipv4.ttl,
                hdr.ipv4.protocol,
                hdr.ipv4.src_addr,
                hdr.ipv4.dst_addr 
            }
        );
        hdr.inner_ipv4.hdr_checksum = inner_ipv4_checksum.update(
            {
                hdr.inner_ipv4.version,
                hdr.inner_ipv4.ihl,
                hdr.inner_ipv4.diffserv,
                hdr.inner_ipv4.total_len,
                hdr.inner_ipv4.identification,
                hdr.inner_ipv4.flags,
                hdr.inner_ipv4.frag_offset,
                hdr.inner_ipv4.ttl,
                hdr.inner_ipv4.protocol,
                hdr.inner_ipv4.src_addr,
                hdr.inner_ipv4.dst_addr 
            }
        );
        */
        /*
        if (hdr.inner_udp.isValid()) {
            hdr.inner_udp.checksum = inner_udp_checksum.update({
            hdr.inner_ipv4.src_addr,
            hdr.inner_ipv4.dst_addr,
            hdr.inner_udp.src_port,
            hdr.inner_udp.dst_port,
            ig_md.inner_tcp_udp_checksum});
        } else if (hdr.inner_tcp.isValid()) {
            hdr.tcp.checksum = inner_tcp_checksum.update({
                hdr.inner_ipv4.src_addr,
                hdr.inner_ipv4.dst_addr,
                hdr.inner_tcp.src_port,
                hdr.inner_tcp.dst_port,
                ig_md.inner_tcp_udp_checksum});
        }
        */
        
        pkt.emit(hdr.bridged_md);

        pkt.emit(hdr.ethernet);
        pkt.emit(hdr.ipv4);
        pkt.emit(hdr.ipv6);
        pkt.emit(hdr.udp);
        pkt.emit(hdr.tcp); // Ingress only.
        pkt.emit(hdr.vxlan);
        pkt.emit(hdr.inner_ethernet);
        pkt.emit(hdr.inner_ipv4);
        pkt.emit(hdr.inner_ipv6);
        pkt.emit(hdr.inner_udp);
        pkt.emit(hdr.inner_tcp);
    }
}

parser KTMEgressParser(
        packet_in pkt,
        out switch_header_t hdr,
        out switch_egress_metadata_t eg_md,
        out egress_intrinsic_metadata_t eg_intr_md) {

    Checksum() ipv4_checksum;
    Checksum() tcp_checksum;
    Checksum() udp_checksum;
    Checksum() inner_ipv4_checksum;
    Checksum() inner_tcp_checksum;
    Checksum() inner_udp_checksum;

    state start {
        eg_md.flags.bypass_egress = false;
        transition parse_ktm_pkt;
    }

    state parse_ktm_pkt {
        transition select((bit<1>)eg_md.ktm_meta.me2client, (bit<1>)eg_md.ktm_meta.me2server) {
            (1,0)   :   parse_m2c;
            (0,1)   :   parse_m2s;
            default :   reject;
        }
    }

    state parse_m2c {
        transition parse_ethernet;
    }

    state parse_m2s {

        hdr.ethernet.setValid();
        hdr.ipv4.setValid();
        hdr.udp.setValid();
        hdr.vxlan.setValid();
        transition parse_inner_ethernet;
        //transition parse_ethernet;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type) {
            ETHERTYPE_IPV4  :   parse_ipv4;
            ETHERTYPE_IPV6  :   parse_ipv6;
            default         :   accept;
        }
    }

    state parse_ipv6 {
        pkt.extract(hdr.ipv6);
        transition select (hdr.ipv6.next_hdr) {
            IP_PROTOCOLS_TCP : parse_tcp;
            IP_PROTOCOLS_UDP : parse_udp;
            default : accept;
        }
    }

    state parse_ipv4 {
        ipv4_checksum.add(hdr.ipv4);
        pkt.extract(hdr.ipv4);
        eg_md.ktm_meta.vxlan_src_port_hash_base32 = pkt.lookahead<bit<32>>();
        tcp_checksum.subtract({hdr.ipv4.src_addr,hdr.ipv4.dst_addr});
        udp_checksum.subtract({hdr.ipv4.src_addr,hdr.ipv4.dst_addr});
        transition select(hdr.ipv4.protocol, hdr.ipv4.ihl, hdr.ipv4.frag_offset) {
            (IP_PROTOCOLS_UDP,  5, 0)   : parse_udp;
            (IP_PROTOCOLS_TCP, 5, 0)    : parse_tcp;
            default : accept;
        }
    }

    state parse_udp {
        pkt.extract(hdr.udp);
        udp_checksum.subtract_all_and_deposit(eg_md.tcp_udp_checksum);
        udp_checksum.subtract({hdr.udp.checksum});
        udp_checksum.subtract({hdr.udp.src_port, hdr.udp.dst_port});
        transition select(hdr.udp.dst_port) {
            DEFAULT_UDP_PORT_VXLAN : parse_vxlan;
            default : accept;
        }
    }

    state parse_tcp {
        pkt.extract(hdr.tcp);
        tcp_checksum.subtract_all_and_deposit(eg_md.tcp_udp_checksum);
        tcp_checksum.subtract({hdr.tcp.checksum});
        tcp_checksum.subtract({hdr.tcp.src_port, hdr.tcp.dst_port});
        transition accept;
    }

    state parse_vxlan {
        pkt.extract(hdr.vxlan);
        transition parse_inner_ethernet;
    }

    state parse_inner_ethernet {
        pkt.extract(hdr.inner_ethernet);
        transition select(hdr.inner_ethernet.ether_type) {
            ETHERTYPE_IPV4 : parse_inner_ipv4;
            ETHERTYPE_IPV6 : parse_inner_ipv6;
            default : accept;
        }
    }

    state parse_inner_ipv6 {
        pkt.extract(hdr.inner_ipv6);
        inner_tcp_checksum.subtract({hdr.inner_ipv6.src_addr, hdr.inner_ipv6.dst_addr});
        inner_udp_checksum.subtract({hdr.inner_ipv6.src_addr, hdr.inner_ipv6.dst_addr});
        transition select(hdr.inner_ipv6.next_hdr) {
            IP_PROTOCOLS_TCP : parse_inner_tcp;
            IP_PROTOCOLS_UDP : parse_inner_udp;
        }
    }

    state parse_inner_ipv4 {
         pkt.extract(hdr.inner_ipv4);

        inner_ipv4_checksum.add(hdr.inner_ipv4);
        inner_tcp_checksum.subtract({hdr.inner_ipv4.src_addr, hdr.inner_ipv4.dst_addr});
        inner_udp_checksum.subtract({hdr.inner_ipv4.src_addr, hdr.inner_ipv4.dst_addr});

        transition select(hdr.inner_ipv4.protocol) {
            IP_PROTOCOLS_UDP : parse_inner_udp;
            IP_PROTOCOLS_TCP : parse_inner_tcp;
            default : accept;
        }
    }

    state parse_inner_udp {
        pkt.extract(hdr.inner_udp);

        inner_udp_checksum.subtract_all_and_deposit(eg_md.inner_tcp_udp_checksum);
        inner_udp_checksum.subtract({hdr.inner_udp.checksum});
        inner_udp_checksum.subtract({hdr.inner_udp.src_port, hdr.inner_udp.dst_port});
        transition accept;
    }

    state parse_inner_tcp {
        pkt.extract(hdr.inner_tcp);

        inner_tcp_checksum.subtract_all_and_deposit(eg_md.inner_tcp_udp_checksum);
        inner_tcp_checksum.subtract({hdr.inner_tcp.checksum});
        inner_tcp_checksum.subtract({hdr.inner_tcp.src_port, hdr.inner_tcp.dst_port});
        transition accept;
    }

}

//----------------------------------------------------------------------------
// Egress parser
//----------------------------------------------------------------------------
parser SwitchEgressParser(
        packet_in pkt,
        out switch_header_t hdr,
        out switch_egress_metadata_t eg_md,
        out egress_intrinsic_metadata_t eg_intr_md) {

    KTMEgressParser() ktm_egress_parser;

    @critical
    state start {
        pkt.extract(eg_intr_md);


        transition parse_bridged_pkt;
    }

    state parse_bridged_pkt {
        pkt.extract(hdr.bridged_md);
        eg_md.ktm_meta = hdr.bridged_md.ktm_meta;
        
        transition select((bit<1>)hdr.bridged_md.ktm_meta.ktm_vx_pkt) {
            0   :   parse_ethernet;
            1   :   parse_ktm_vx_pkt;
        }

    }

    state parse_ktm_vx_pkt {
        ktm_egress_parser.apply(pkt, hdr, eg_md, eg_intr_md);
        transition accept;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type, eg_intr_md.egress_port) {
            (ETHERTYPE_IPV4, _) : parse_ipv4;
            (ETHERTYPE_IPV6, _) : parse_ipv6;
            default : accept;
        }
    }

    state parse_ipv6 {
        pkt.extract(hdr.ipv6);
        transition select (hdr.ipv6.next_hdr) {
            IP_PROTOCOLS_TCP : parse_tcp;
            IP_PROTOCOLS_UDP : parse_udp;
            default : accept;
        }
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        transition select(hdr.ipv4.protocol, hdr.ipv4.ihl, hdr.ipv4.frag_offset) {
            (IP_PROTOCOLS_UDP,  5, 0) : parse_udp;

            default : accept;
        }
    }

    state parse_udp {
        pkt.extract(hdr.udp);
        transition select(hdr.udp.dst_port) {
            DEFAULT_UDP_PORT_VXLAN : parse_vxlan;
            default : accept;
        }
    }

    state parse_tcp {
        pkt.extract(hdr.tcp);
        transition accept;
    }

    state parse_vxlan {
        pkt.extract(hdr.vxlan);
        transition parse_inner_ethernet;
    }

    state parse_inner_ethernet {
        pkt.extract(hdr.inner_ethernet);
        transition select(hdr.inner_ethernet.ether_type) {
            ETHERTYPE_IPV4 : parse_inner_ipv4;
            ETHERTYPE_IPV6 : parse_inner_ipv6;
            default : accept;
        }
    }

    state parse_inner_ipv6 {
        pkt.extract(hdr.inner_ipv6);
        transition select(hdr.inner_ipv6.next_hdr) {
            IP_PROTOCOLS_TCP : parse_inner_tcp;
            IP_PROTOCOLS_UDP : parse_inner_udp;
        }
    }

    state parse_inner_ipv4 {
        pkt.extract(hdr.inner_ipv4);
        transition select(hdr.inner_ipv4.protocol) {
            IP_PROTOCOLS_UDP : parse_inner_udp;
            default : accept;
        }
    }

    state parse_inner_udp {
        pkt.extract(hdr.inner_udp);
        transition accept;
    }

    state parse_inner_tcp {
        pkt.extract(hdr.inner_tcp);
        transition accept;
    }
}

struct padding_mac {
    bit<32> first;
    bit<32> second;
}

control SwitchEgress(
        inout switch_header_t hdr,
        inout switch_egress_metadata_t eg_md,
        in egress_intrinsic_metadata_t eg_intr_md,
        in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
        inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
        inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {

    

    Register<bit<64>,_>(1) ktm_vtep_mac_register; 
    RegisterAction<_, _, bit<64>>(ktm_vtep_mac_register) get_ktm_vtep_mac = {
        void apply(inout bit<64> reg_mac, out bit<64> mac) {
            mac = reg_mac;
            //mac = reg_mac[63:16];
            //mac = reg_mac.first[15:0] ++ reg_mac.second;
        }
    };
    Register<bit<64>,_>(1) ec_vtep_mac_register;
    RegisterAction<_, _, bit<64>>(ec_vtep_mac_register) get_ec_vtep_mac = {
        void apply(inout bit<64> reg_mac, out bit<64> mac) {
            mac = reg_mac;
            //mac = reg_mac[63:16];
            //mac = reg_mac.first[15:0] ++ reg_mac.second;
        }
    };

    action vtep_mac_get(mac_addr_t ktm_vtep_mac, mac_addr_t ec_vtep_mac) {
        eg_md.ktm_meta.ktm_vtep_mac = ktm_vtep_mac;
        eg_md.ktm_meta.ec_vtep_mac = ec_vtep_mac;
    }

    table vtep_mac_table {
        key = {
            eg_md.ktm_meta.KTM_LOOPBACK_IP:exact;
        }
        actions = {
            vtep_mac_get;
        }
    }
    Hash<bit<16>>(HashAlgorithm_t.CRC16) vxlan_src_port_hash;
    bit<16> hash_vxlan_src_port;


    apply{

        vtep_mac_table.apply();
        hash_vxlan_src_port = vxlan_src_port_hash.get({
                hdr.inner_ipv4.src_addr,
                hdr.inner_ipv4.dst_addr,
                hdr.inner_ipv4.protocol,
                eg_md.ktm_meta.vxlan_src_port_hash_base32
            });
        if (eg_md.ktm_meta.me2client) {
            if (hdr.inner_ipv4.isValid()) {
                hdr.inner_ipv4.src_addr = eg_md.ktm_meta.eip;
            } else if (hdr.inner_ipv6.isValid()) {
                hdr.inner_ipv6.src_addr = eg_md.ktm_meta.eip6;
            }
            //eg_intr_md_for_dprsr.drop_ctl = 0x1;
            hdr.inner_ethernet.src_addr = eg_md.ktm_meta.ktm_vtep_mac;
            hdr.inner_ethernet.dst_addr = eg_md.ktm_meta.ec_vtep_mac;
            //hdr.inner_ethernet.src_addr = get_ktm_vtep_mac.execute(0)[47:0];
            //hdr.inner_ethernet.dst_addr = get_ec_vtep_mac.execute(0)[47:0];
            hdr.ipv4.dst_addr = eg_md.ktm_meta.EC_VTEP_IP;
            hdr.ipv4.src_addr = eg_md.ktm_meta.KTM_LOOPBACK_IP;
            hdr.udp.checksum = 0;
        } else if (eg_md.ktm_meta.me2server){

            if (hdr.inner_ipv4.isValid()) {
                hdr.inner_ipv4.dst_addr = eg_md.ktm_meta.server_ip;
            } else if (hdr.inner_ipv6.isValid()) {
                hdr.inner_ipv6.dst_addr = eg_md.ktm_meta.server_ip6;
            }


            hdr.ethernet = hdr.inner_ethernet;
            hdr.inner_ethernet.src_addr = eg_md.ktm_meta.ktm_vtep_mac;
            //hdr.inner_ethernet.src_addr = get_ktm_vtep_mac.execute(0)[47:0];
            hdr.inner_ethernet.dst_addr = eg_md.ktm_meta.server_vtep_mac;

            hdr.vxlan.vni = eg_md.ktm_meta.customize_vni;

            hdr.udp.src_port = hash_vxlan_src_port;
            hdr.udp.dst_port = eg_md.ktm_meta.customize_vxlan_dst_port;
            hdr.udp.length = hdr.inner_ipv4.total_len + 30;
            hdr.udp.checksum = 0;

            hdr.ipv4 = hdr.inner_ipv4;
            hdr.ipv4.dst_addr = eg_md.ktm_meta.server_vtep_ip;
            hdr.ipv4.src_addr = eg_md.ktm_meta.KTM_LOOPBACK_IP;
            hdr.ipv4.total_len = hdr.inner_ipv4.total_len + 50;
            hdr.ipv4.protocol = IP_PROTOCOLS_UDP;

            hdr.ethernet.ether_type = ETHERTYPE_IPV4;
        }
    }

}

//-----------------------------------------------------------------------------
// Egress Deparser
//-----------------------------------------------------------------------------
control SwitchEgressDeparser(
        packet_out pkt,
        inout switch_header_t hdr,
        in switch_egress_metadata_t eg_md,
        in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {

    Checksum() ipv4_checksum;
    //Checksum() udp_checksum;
    Checksum() inner_ipv4_checksum;
    Checksum() inner_udp_checksum;
    Checksum() inner_tcp_checksum;

    apply {
        
        hdr.ipv4.hdr_checksum = ipv4_checksum.update(
            {
                hdr.ipv4.version,
                hdr.ipv4.ihl,
                hdr.ipv4.diffserv,
                hdr.ipv4.total_len,
                hdr.ipv4.identification,
                hdr.ipv4.flags,
                hdr.ipv4.frag_offset,
                hdr.ipv4.ttl,
                hdr.ipv4.protocol,
                hdr.ipv4.src_addr,
                hdr.ipv4.dst_addr 
            }
        );
        if (hdr.inner_ipv4.isValid()) {
            hdr.inner_ipv4.hdr_checksum = inner_ipv4_checksum.update(
                {
                    hdr.inner_ipv4.version,
                    hdr.inner_ipv4.ihl,
                    hdr.inner_ipv4.diffserv,
                    hdr.inner_ipv4.total_len,
                    hdr.inner_ipv4.identification,
                    hdr.inner_ipv4.flags,
                    hdr.inner_ipv4.frag_offset,
                    hdr.inner_ipv4.ttl,
                    hdr.inner_ipv4.protocol,
                    hdr.inner_ipv4.src_addr,
                    hdr.inner_ipv4.dst_addr 
                }
            );
            
            if (hdr.inner_udp.isValid()) {
                hdr.inner_udp.checksum = inner_udp_checksum.update({
                hdr.inner_ipv4.src_addr,
                hdr.inner_ipv4.dst_addr,
                hdr.inner_udp.src_port,
                hdr.inner_udp.dst_port,
                eg_md.inner_tcp_udp_checksum});
            } else if (hdr.inner_tcp.isValid()) {
                hdr.inner_tcp.checksum = inner_tcp_checksum.update({
                hdr.inner_ipv4.src_addr,
                hdr.inner_ipv4.dst_addr,
                hdr.inner_tcp.src_port,
                hdr.inner_tcp.dst_port,
                eg_md.inner_tcp_udp_checksum});
            }
        } else if (hdr.inner_ipv6.isValid()) {
            if (hdr.inner_udp.isValid()) {
                hdr.inner_udp.checksum = inner_udp_checksum.update({
                hdr.inner_ipv6.src_addr,
                hdr.inner_ipv6.dst_addr,
                hdr.inner_udp.src_port,
                hdr.inner_udp.dst_port,
                eg_md.inner_tcp_udp_checksum});
            } else if (hdr.inner_tcp.isValid()) {
                hdr.inner_tcp.checksum = inner_tcp_checksum.update({
                hdr.inner_ipv6.src_addr,
                hdr.inner_ipv6.dst_addr,
                hdr.inner_tcp.src_port,
                hdr.inner_tcp.dst_port,
                eg_md.inner_tcp_udp_checksum});
            }
        }
        
        
        /*
        // this way compiler will report error with updates exceed checksum engines
        if (hdr.inner_udp.isValid()) {
            if (hdr.inner_ipv4.isValid()) {
                hdr.inner_udp.checksum = inner_udp_checksum.update({
                hdr.inner_ipv4.src_addr,
                hdr.inner_ipv4.dst_addr,
                hdr.inner_udp.src_port,
                hdr.inner_udp.dst_port,
                eg_md.inner_tcp_udp_checksum});
            } else if (hdr.inner_ipv6.isValid()) {
                hdr.inner_udp.checksum = inner_udp_checksum.update({
                hdr.inner_ipv6.src_addr,
                hdr.inner_ipv6.dst_addr,
                hdr.inner_udp.src_port,
                hdr.inner_udp.dst_port,
                eg_md.inner_tcp_udp_checksum});
            }
            
        } else if (hdr.inner_tcp.isValid()) {
            if (hdr.inner_ipv4.isValid()) {
                hdr.inner_tcp.checksum = inner_tcp_checksum.update({
                hdr.inner_ipv4.src_addr,
                hdr.inner_ipv4.dst_addr,
                hdr.inner_tcp.src_port,
                hdr.inner_tcp.dst_port,
                eg_md.inner_tcp_udp_checksum});
            } else if (hdr.inner_ipv6.isValid()) {
                hdr.inner_tcp.checksum = inner_tcp_checksum.update({
                hdr.inner_ipv6.src_addr,
                hdr.inner_ipv6.dst_addr,
                hdr.inner_tcp.src_port,
                hdr.inner_tcp.dst_port,
                eg_md.inner_tcp_udp_checksum});
            }
            
        }
        */
        

        
        pkt.emit(hdr.ethernet);
        pkt.emit(hdr.ipv4);
        pkt.emit(hdr.ipv6);
        pkt.emit(hdr.udp);

        pkt.emit(hdr.vxlan);

        pkt.emit(hdr.inner_ethernet);
        pkt.emit(hdr.inner_ipv4);
        pkt.emit(hdr.inner_ipv6);
        pkt.emit(hdr.inner_udp);
        pkt.emit(hdr.inner_tcp);
    }
}



struct empty_header_t {}

struct empty_metadata_t {}

parser EmptyEgressParser(
        packet_in pkt,
        out empty_header_t hdr,
        out empty_metadata_t eg_md,
        out egress_intrinsic_metadata_t eg_intr_md) {
    state start {
        transition accept;
    }
}

control EmptyEgress(
        inout empty_header_t hdr,
        inout empty_metadata_t eg_md,
        in egress_intrinsic_metadata_t eg_intr_md,
        in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
        inout egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
        inout egress_intrinsic_metadata_for_output_port_t eg_intr_oport_md) {
    apply {}
}

control EmptyEgressDeparser(
        packet_out pkt,
        inout empty_header_t hdr,
        in empty_metadata_t eg_md,
        in egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md) {
    apply {}
}



Pipeline(SwitchIngressParser(),
         SwitchIngress(),
         SwitchIngressDeparser(),
         SwitchEgressParser(),
         SwitchEgress(),
         SwitchEgressDeparser()) pipe;

Switch(pipe) main;
