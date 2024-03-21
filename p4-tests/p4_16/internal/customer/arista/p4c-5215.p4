#include <core.p4>
#include <t2na.p4>
// Different Profiles in Diag
//  1. Basic Diags
//  2. Diag Single stage                 DIAG_SINGLE_STAGE
//  3. Diag Power                        DIAG_POWER_ENABLE
//  4. MAU bus stress                    DIAG_MAU_BUS_STRESS_ENABLE
//  5. PHV, Parde Stress                 DIAG_PHV_PARDE_STRESS_ENABLE
//  6. PHV, Parde, Hold Stress           DIAG_PHV_PARDE_HOLD_STRESS_ENABLE
//  7. Queue Stress                      DIAG_QUEUE_STRESS_ENABLE
//  8. Parde Strain                      DIAG_PARDE_STRAIN
//  9. PHV Action Flop Tests for TF1     DIAG_PHV_FLOP_TEST={1|2}
// 10. PHV Match Flop Tests  for TF1     DIAG_PHV_FLOP_MATCH={1|2}
// 11. PHV Flop Tests for Ruije TF2      DIAG_PHV_FLOP_TEST=3
// 12. PHV Datapath for TF2 action dep   DIAG_PHV_FLOP_TEST=4
// 13. PHV Datapath for TF2 match dep    DIAG_PHV_FLOP_TEST=5
// 14. PHV Dark/Mocha TF2 action dep     DIAG_PHV_MOCHA_DARK
// 15. PHV Dark/Mocha TF2 match dep      DIAG_PHV_MOCHA_DARK_MATCH_DEPENDENT

// Different products supported in Diag
// 1. Tofino1  - 12 stages - TOFINO1
// 2. Tofino2  - 20 stages - TOFINO2
// 3. Tofino2u - 20 stages - TOFINO2U
// 4. Tofino2m - 12 stages - TOFINO2M
// 5. Tofino2h -  8 stages - TOFINO2H
// 6. Emulator - 10 stages - DEVICE_IS_EMULATOR
// 7. Tofino3  - 20 stages - TOFINO3

// Temporarily override the format checker so we can indent
// the nested preprocessor directives.
// clang-format off
/* Special Ports */
/* Resubmit types */


/* Mirror types */
// Reenable format checking.
// clang-format on



typedef bit<48> mac_addr_t;
typedef bit<32> ipv4_addr_t;
typedef bit<128> ipv6_addr_t;
typedef bit<12> vlan_id_t;
typedef bit<192> mau_stress_hdr_exm_key_len_t;
typedef bit<192> mau_stress_hdr_tcam_key_len_t;

typedef bit<16> ether_type_t;
const ether_type_t ETHERTYPE_IPV4 = 16w0x0800;
const ether_type_t ETHERTYPE_IPV6 = 16w0x86dd;
const ether_type_t ETHERTYPE_VLAN = 16w0x8100;
const ether_type_t ETHERTYPE_QINQ = 16w0x9100;
const ether_type_t ETHERTYPE_MPLS = 16w0x8847;
const ether_type_t ETHERTYPE_LLDP = 16w0x88cc;
const ether_type_t ETHERTYPE_LACP = 16w0x8809;
const ether_type_t ETHERTYPE_NSH = 16w0x894f;
const ether_type_t ETHERTYPE_ROCE = 16w0x8915;
const ether_type_t ETHERTYPE_FCOE = 16w0x8906;
const ether_type_t ETHERTYPE_ETHERNET = 16w0x6658;
const ether_type_t ETHERTYPE_ARP = 16w0x0806;
const ether_type_t ETHERTYPE_VNTAG = 16w0x8926;
const ether_type_t ETHERTYPE_TRILL = 16w0x22f3;

typedef bit<8> ip_protocol_t;
const ip_protocol_t IP_PROTOCOLS_ICMP = 1;
const ip_protocol_t IP_PROTOCOLS_IPV4 = 4;
const ip_protocol_t IP_PROTOCOLS_TCP = 6;
const ip_protocol_t IP_PROTOCOLS_UDP = 17;
const ip_protocol_t IP_PROTOCOLS_IPV6 = 41;
const ip_protocol_t IP_PROTOCOLS_GRE = 47;
const ip_protocol_t IP_PROTOCOLS_ICMPV6 = 58;
const ip_protocol_t IP_PROTOCOLS_EIGRP = 88;
const ip_protocol_t IP_PROTOCOLS_OSPF = 89;
const ip_protocol_t IP_PROTOCOLS_PIM = 103;
const ip_protocol_t IP_PROTOCOLS_VRRP = 112;
const ip_protocol_t IP_PROTOCOLS_MPLS = 137;

typedef bit<32> ingress_tunnel_type_t;
const ingress_tunnel_type_t INGRESS_TUNNEL_TYPE_GRE = 2;
const ingress_tunnel_type_t INGRESS_TUNNEL_TYPE_IP_IN_IP = 2;
const ingress_tunnel_type_t INGRESS_TUNNEL_TYPE_NVGRE = 5;
const ingress_tunnel_type_t INGRESS_TUNNEL_TYPE_MPLS = 6;

typedef bit<3> ctrl_prio_t;
const ctrl_prio_t CONTROL_TRAFFIC_PRIO_3 = 3;
const ctrl_prio_t CONTROL_TRAFFIC_PRIO_5 = 5;
const ctrl_prio_t CONTROL_TRAFFIC_PRIO_7 = 7;
// !DIAG_POWER_ENABLE



// TF2 PHV Datapath
// Coverage Details: 100% normal PHV and 100% Mocha PHV
// B0-47, H0-72, W0-47, MB0-15, MH0-23, MW0-15


// Main header
header main_h {
    bit<32> w0;
    bit<32> w1;
    bit<32> w2;
    bit<32> w3;
    bit<8> b0;
    bit<8> b1;
    bit<8> b2;
    bit<8> b3;
    bit<16> h0;
    bit<16> h1;
    bit<16> h2;
    bit<16> h3;
    bit<16> h4;
}

// Ingress tail header
header i_tail_h {
    bit<16> h0;
    bit<16> h1;
    bit<16> h2;
    bit<16> h3;
    bit<16> h4;
    bit<16> h5;
}

// Egress tail header
header e_tail_h {
    bit<16> h0;
    bit<16> h1;
    bit<16> h2;
    bit<16> h3;
}

//Ingress main_h
@pa_container_size("ingress", "hdr.main0.w0", 32) @pa_container_type("ingress", "hdr.main0.w0", "normal")
@pa_container_size("ingress", "hdr.main0.w1", 32) @pa_container_type("ingress", "hdr.main0.w1", "normal")
@pa_container_size("ingress", "hdr.main0.w2", 32) @pa_container_type("ingress", "hdr.main0.w2", "normal")
@pa_container_size("ingress", "hdr.main0.w3", 32) @pa_container_type("ingress", "hdr.main0.w3", "normal")
@pa_container_size("ingress", "hdr.main0.b0", 8) @pa_container_type("ingress", "hdr.main0.b0", "normal")
@pa_container_size("ingress", "hdr.main0.b1", 8) @pa_container_type("ingress", "hdr.main0.b1", "normal")
@pa_container_size("ingress", "hdr.main0.b2", 8) @pa_container_type("ingress", "hdr.main0.b2", "normal")
@pa_container_size("ingress", "hdr.main0.b3", 8) @pa_container_type("ingress", "hdr.main0.b3", "normal")
@pa_container_size("ingress", "hdr.main0.h0", 16) @pa_container_type("ingress", "hdr.main0.h0", "normal")
@pa_container_size("ingress", "hdr.main0.h1", 16) @pa_container_type("ingress", "hdr.main0.h1", "normal")
@pa_container_size("ingress", "hdr.main0.h2", 16) @pa_container_type("ingress", "hdr.main0.h2", "normal")
@pa_container_size("ingress", "hdr.main0.h3", 16) @pa_container_type("ingress", "hdr.main0.h3", "normal")
@pa_container_size("ingress", "hdr.main0.h4", 16) @pa_container_type("ingress", "hdr.main0.h4", "normal")

@pa_container_size("ingress", "hdr.main1.w0", 32) @pa_container_type("ingress", "hdr.main1.w0", "normal")
@pa_container_size("ingress", "hdr.main1.w1", 32) @pa_container_type("ingress", "hdr.main1.w1", "normal")
@pa_container_size("ingress", "hdr.main1.w2", 32) @pa_container_type("ingress", "hdr.main1.w2", "normal")
@pa_container_size("ingress", "hdr.main1.w3", 32) @pa_container_type("ingress", "hdr.main1.w3", "normal")
@pa_container_size("ingress", "hdr.main1.b0", 8) @pa_container_type("ingress", "hdr.main1.b0", "normal")
@pa_container_size("ingress", "hdr.main1.b1", 8) @pa_container_type("ingress", "hdr.main1.b1", "normal")
@pa_container_size("ingress", "hdr.main1.b2", 8) @pa_container_type("ingress", "hdr.main1.b2", "normal")
@pa_container_size("ingress", "hdr.main1.b3", 8) @pa_container_type("ingress", "hdr.main1.b3", "normal")
@pa_container_size("ingress", "hdr.main1.h0", 16) @pa_container_type("ingress", "hdr.main1.h0", "normal")
@pa_container_size("ingress", "hdr.main1.h1", 16) @pa_container_type("ingress", "hdr.main1.h1", "normal")
@pa_container_size("ingress", "hdr.main1.h2", 16) @pa_container_type("ingress", "hdr.main1.h2", "normal")
@pa_container_size("ingress", "hdr.main1.h3", 16) @pa_container_type("ingress", "hdr.main1.h3", "normal")
@pa_container_size("ingress", "hdr.main1.h4", 16) @pa_container_type("ingress", "hdr.main1.h4", "normal")

@pa_container_size("ingress", "hdr.main2.w0", 32) @pa_container_type("ingress", "hdr.main2.w0", "normal")
@pa_container_size("ingress", "hdr.main2.w1", 32) @pa_container_type("ingress", "hdr.main2.w1", "normal")
@pa_container_size("ingress", "hdr.main2.w2", 32) @pa_container_type("ingress", "hdr.main2.w2", "normal")
@pa_container_size("ingress", "hdr.main2.w3", 32) @pa_container_type("ingress", "hdr.main2.w3", "normal")
@pa_container_size("ingress", "hdr.main2.b0", 8) @pa_container_type("ingress", "hdr.main2.b0", "normal")
@pa_container_size("ingress", "hdr.main2.b1", 8) @pa_container_type("ingress", "hdr.main2.b1", "normal")
@pa_container_size("ingress", "hdr.main2.b2", 8) @pa_container_type("ingress", "hdr.main2.b2", "normal")
@pa_container_size("ingress", "hdr.main2.b3", 8) @pa_container_type("ingress", "hdr.main2.b3", "normal")
@pa_container_size("ingress", "hdr.main2.h0", 16) @pa_container_type("ingress", "hdr.main2.h0", "normal")
@pa_container_size("ingress", "hdr.main2.h1", 16) @pa_container_type("ingress", "hdr.main2.h1", "normal")
@pa_container_size("ingress", "hdr.main2.h2", 16) @pa_container_type("ingress", "hdr.main2.h2", "normal")
@pa_container_size("ingress", "hdr.main2.h3", 16) @pa_container_type("ingress", "hdr.main2.h3", "normal")
@pa_container_size("ingress", "hdr.main2.h4", 16) @pa_container_type("ingress", "hdr.main2.h4", "normal")

@pa_container_size("ingress", "hdr.main3.w0", 32) @pa_container_type("ingress", "hdr.main3.w0", "normal")
@pa_container_size("ingress", "hdr.main3.w1", 32) @pa_container_type("ingress", "hdr.main3.w1", "normal")
@pa_container_size("ingress", "hdr.main3.w2", 32) @pa_container_type("ingress", "hdr.main3.w2", "normal")
@pa_container_size("ingress", "hdr.main3.w3", 32) @pa_container_type("ingress", "hdr.main3.w3", "normal")
@pa_container_size("ingress", "hdr.main3.b0", 8) @pa_container_type("ingress", "hdr.main3.b0", "normal")
@pa_container_size("ingress", "hdr.main3.b1", 8) @pa_container_type("ingress", "hdr.main3.b1", "normal")
@pa_container_size("ingress", "hdr.main3.b2", 8) @pa_container_type("ingress", "hdr.main3.b2", "normal")
@pa_container_size("ingress", "hdr.main3.b3", 8) @pa_container_type("ingress", "hdr.main3.b3", "normal")
@pa_container_size("ingress", "hdr.main3.h0", 16) @pa_container_type("ingress", "hdr.main3.h0", "normal")
@pa_container_size("ingress", "hdr.main3.h1", 16) @pa_container_type("ingress", "hdr.main3.h1", "normal")
@pa_container_size("ingress", "hdr.main3.h2", 16) @pa_container_type("ingress", "hdr.main3.h2", "normal")
@pa_container_size("ingress", "hdr.main3.h3", 16) @pa_container_type("ingress", "hdr.main3.h3", "normal")
@pa_container_size("ingress", "hdr.main3.h4", 16) @pa_container_type("ingress", "hdr.main3.h4", "normal")

@pa_container_size("ingress", "hdr.main4.w0", 32) @pa_container_type("ingress", "hdr.main4.w0", "normal")
@pa_container_size("ingress", "hdr.main4.w1", 32) @pa_container_type("ingress", "hdr.main4.w1", "normal")
@pa_container_size("ingress", "hdr.main4.w2", 32) @pa_container_type("ingress", "hdr.main4.w2", "normal")
@pa_container_size("ingress", "hdr.main4.w3", 32) @pa_container_type("ingress", "hdr.main4.w3", "normal")
@pa_container_size("ingress", "hdr.main4.b0", 8) @pa_container_type("ingress", "hdr.main4.b0", "normal")
@pa_container_size("ingress", "hdr.main4.b1", 8) @pa_container_type("ingress", "hdr.main4.b1", "normal")
@pa_container_size("ingress", "hdr.main4.b2", 8) @pa_container_type("ingress", "hdr.main4.b2", "normal")
@pa_container_size("ingress", "hdr.main4.b3", 8) @pa_container_type("ingress", "hdr.main4.b3", "normal")
@pa_container_size("ingress", "hdr.main4.h0", 16) @pa_container_type("ingress", "hdr.main4.h0", "normal")
@pa_container_size("ingress", "hdr.main4.h1", 16) @pa_container_type("ingress", "hdr.main4.h1", "normal")
@pa_container_size("ingress", "hdr.main4.h2", 16) @pa_container_type("ingress", "hdr.main4.h2", "normal")
@pa_container_size("ingress", "hdr.main4.h3", 16) @pa_container_type("ingress", "hdr.main4.h3", "normal")
@pa_container_size("ingress", "hdr.main4.h4", 16) @pa_container_type("ingress", "hdr.main4.h4", "normal")

@pa_container_size("ingress", "hdr.main5.w0", 32) @pa_container_type("ingress", "hdr.main5.w0", "normal")
@pa_container_size("ingress", "hdr.main5.w1", 32) @pa_container_type("ingress", "hdr.main5.w1", "normal")
@pa_container_size("ingress", "hdr.main5.w2", 32) @pa_container_type("ingress", "hdr.main5.w2", "normal")
@pa_container_size("ingress", "hdr.main5.w3", 32) @pa_container_type("ingress", "hdr.main5.w3", "normal")
@pa_container_size("ingress", "hdr.main5.b0", 8) @pa_container_type("ingress", "hdr.main5.b0", "normal")
@pa_container_size("ingress", "hdr.main5.b1", 8) @pa_container_type("ingress", "hdr.main5.b1", "normal")
@pa_container_size("ingress", "hdr.main5.b2", 8) @pa_container_type("ingress", "hdr.main5.b2", "normal")
@pa_container_size("ingress", "hdr.main5.b3", 8) @pa_container_type("ingress", "hdr.main5.b3", "normal")
@pa_container_size("ingress", "hdr.main5.h0", 16) @pa_container_type("ingress", "hdr.main5.h0", "normal")
@pa_container_size("ingress", "hdr.main5.h1", 16) @pa_container_type("ingress", "hdr.main5.h1", "normal")
@pa_container_size("ingress", "hdr.main5.h2", 16) @pa_container_type("ingress", "hdr.main5.h2", "normal")
@pa_container_size("ingress", "hdr.main5.h3", 16) @pa_container_type("ingress", "hdr.main5.h3", "normal")
@pa_container_size("ingress", "hdr.main5.h4", 16) @pa_container_type("ingress", "hdr.main5.h4", "normal")

@pa_container_size("ingress", "hdr.main6.w0", 32) @pa_container_type("ingress", "hdr.main6.w0", "normal")
@pa_container_size("ingress", "hdr.main6.w1", 32) @pa_container_type("ingress", "hdr.main6.w1", "normal")
@pa_container_size("ingress", "hdr.main6.w2", 32) @pa_container_type("ingress", "hdr.main6.w2", "normal")
@pa_container_size("ingress", "hdr.main6.w3", 32) @pa_container_type("ingress", "hdr.main6.w3", "normal")
@pa_container_size("ingress", "hdr.main6.b0", 8) @pa_container_type("ingress", "hdr.main6.b0", "normal")
@pa_container_size("ingress", "hdr.main6.b1", 8) @pa_container_type("ingress", "hdr.main6.b1", "normal")
@pa_container_size("ingress", "hdr.main6.b2", 8) @pa_container_type("ingress", "hdr.main6.b2", "normal")
@pa_container_size("ingress", "hdr.main6.b3", 8) @pa_container_type("ingress", "hdr.main6.b3", "normal")
@pa_container_size("ingress", "hdr.main6.h0", 16) @pa_container_type("ingress", "hdr.main6.h0", "normal")
@pa_container_size("ingress", "hdr.main6.h1", 16) @pa_container_type("ingress", "hdr.main6.h1", "normal")
@pa_container_size("ingress", "hdr.main6.h2", 16) @pa_container_type("ingress", "hdr.main6.h2", "normal")
@pa_container_size("ingress", "hdr.main6.h3", 16) @pa_container_type("ingress", "hdr.main6.h3", "normal")
@pa_container_size("ingress", "hdr.main6.h4", 16) @pa_container_type("ingress", "hdr.main6.h4", "normal")

@pa_container_size("ingress", "hdr.main7.w0", 32) @pa_container_type("ingress", "hdr.main7.w0", "normal")
@pa_container_size("ingress", "hdr.main7.w1", 32) @pa_container_type("ingress", "hdr.main7.w1", "normal")
@pa_container_size("ingress", "hdr.main7.w2", 32) @pa_container_type("ingress", "hdr.main7.w2", "normal")
@pa_container_size("ingress", "hdr.main7.w3", 32) @pa_container_type("ingress", "hdr.main7.w3", "normal")
@pa_container_size("ingress", "hdr.main7.b0", 8) @pa_container_type("ingress", "hdr.main7.b0", "normal")
@pa_container_size("ingress", "hdr.main7.b1", 8) @pa_container_type("ingress", "hdr.main7.b1", "normal")
@pa_container_size("ingress", "hdr.main7.b2", 8) @pa_container_type("ingress", "hdr.main7.b2", "normal")
@pa_container_size("ingress", "hdr.main7.b3", 8) @pa_container_type("ingress", "hdr.main7.b3", "normal")
@pa_container_size("ingress", "hdr.main7.h0", 16) @pa_container_type("ingress", "hdr.main7.h0", "normal")
@pa_container_size("ingress", "hdr.main7.h1", 16) @pa_container_type("ingress", "hdr.main7.h1", "normal")
@pa_container_size("ingress", "hdr.main7.h2", 16) @pa_container_type("ingress", "hdr.main7.h2", "normal")
@pa_container_size("ingress", "hdr.main7.h3", 16) @pa_container_type("ingress", "hdr.main7.h3", "normal")
@pa_container_size("ingress", "hdr.main7.h4", 16) @pa_container_type("ingress", "hdr.main7.h4", "normal")

@pa_container_size("ingress", "hdr.main8.w0", 32) @pa_container_type("ingress", "hdr.main8.w0", "normal")
@pa_container_size("ingress", "hdr.main8.w1", 32) @pa_container_type("ingress", "hdr.main8.w1", "normal")
@pa_container_size("ingress", "hdr.main8.w2", 32) @pa_container_type("ingress", "hdr.main8.w2", "normal")
@pa_container_size("ingress", "hdr.main8.w3", 32) @pa_container_type("ingress", "hdr.main8.w3", "normal")
@pa_container_size("ingress", "hdr.main8.b0", 8) @pa_container_type("ingress", "hdr.main8.b0", "normal")
@pa_container_size("ingress", "hdr.main8.b1", 8) @pa_container_type("ingress", "hdr.main8.b1", "normal")
@pa_container_size("ingress", "hdr.main8.b2", 8) @pa_container_type("ingress", "hdr.main8.b2", "normal")
@pa_container_size("ingress", "hdr.main8.b3", 8) @pa_container_type("ingress", "hdr.main8.b3", "normal")
@pa_container_size("ingress", "hdr.main8.h0", 16) @pa_container_type("ingress", "hdr.main8.h0", "normal")
@pa_container_size("ingress", "hdr.main8.h1", 16) @pa_container_type("ingress", "hdr.main8.h1", "normal")
@pa_container_size("ingress", "hdr.main8.h2", 16) @pa_container_type("ingress", "hdr.main8.h2", "normal")
@pa_container_size("ingress", "hdr.main8.h3", 16) @pa_container_type("ingress", "hdr.main8.h3", "normal")
@pa_container_size("ingress", "hdr.main8.h4", 16) @pa_container_type("ingress", "hdr.main8.h4", "normal")

// Ingress i_tail_h
@pa_container_size("ingress", "hdr.tail.h0", 16) @pa_container_type("ingress", "hdr.tail.h0", "normal")
@pa_container_size("ingress", "hdr.tail.h1", 16) @pa_container_type("ingress", "hdr.tail.h1", "normal")
@pa_container_size("ingress", "hdr.tail.h2", 16) @pa_container_type("ingress", "hdr.tail.h2", "normal")
@pa_container_size("ingress", "hdr.tail.h3", 16) @pa_container_type("ingress", "hdr.tail.h3", "normal")
@pa_container_size("ingress", "hdr.tail.h4", 16) @pa_container_type("ingress", "hdr.tail.h4", "normal")
@pa_container_size("ingress", "hdr.tail.h5", 16) @pa_container_type("ingress", "hdr.tail.h5", "normal")


//Egress main_h
@pa_container_size("egress", "hdr.main0.w0", 32) @pa_container_type("egress", "hdr.main0.w0", "normal")
@pa_container_size("egress", "hdr.main0.w1", 32) @pa_container_type("egress", "hdr.main0.w1", "normal")
@pa_container_size("egress", "hdr.main0.w2", 32) @pa_container_type("egress", "hdr.main0.w2", "normal")
@pa_container_size("egress", "hdr.main0.w3", 32) @pa_container_type("egress", "hdr.main0.w3", "normal")
@pa_container_size("egress", "hdr.main0.b0", 8) @pa_container_type("egress", "hdr.main0.b0", "normal")
@pa_container_size("egress", "hdr.main0.b1", 8) @pa_container_type("egress", "hdr.main0.b1", "normal")
@pa_container_size("egress", "hdr.main0.b2", 8) @pa_container_type("egress", "hdr.main0.b2", "normal")
@pa_container_size("egress", "hdr.main0.b3", 8) @pa_container_type("egress", "hdr.main0.b3", "normal")
@pa_container_size("egress", "hdr.main0.h0", 16) @pa_container_type("egress", "hdr.main0.h0", "normal")
@pa_container_size("egress", "hdr.main0.h1", 16) @pa_container_type("egress", "hdr.main0.h1", "normal")
@pa_container_size("egress", "hdr.main0.h2", 16) @pa_container_type("egress", "hdr.main0.h2", "normal")
@pa_container_size("egress", "hdr.main0.h3", 16) @pa_container_type("egress", "hdr.main0.h3", "normal")
@pa_container_size("egress", "hdr.main0.h4", 16) @pa_container_type("egress", "hdr.main0.h4", "normal")

@pa_container_size("egress", "hdr.main1.w0", 32) @pa_container_type("egress", "hdr.main1.w0", "normal")
@pa_container_size("egress", "hdr.main1.w1", 32) @pa_container_type("egress", "hdr.main1.w1", "normal")
@pa_container_size("egress", "hdr.main1.w2", 32) @pa_container_type("egress", "hdr.main1.w2", "normal")
@pa_container_size("egress", "hdr.main1.w3", 32) @pa_container_type("egress", "hdr.main1.w3", "normal")
@pa_container_size("egress", "hdr.main1.b0", 8) @pa_container_type("egress", "hdr.main1.b0", "normal")
@pa_container_size("egress", "hdr.main1.b1", 8) @pa_container_type("egress", "hdr.main1.b1", "normal")
@pa_container_size("egress", "hdr.main1.b2", 8) @pa_container_type("egress", "hdr.main1.b2", "normal")
@pa_container_size("egress", "hdr.main1.b3", 8) @pa_container_type("egress", "hdr.main1.b3", "normal")
@pa_container_size("egress", "hdr.main1.h0", 16) @pa_container_type("egress", "hdr.main1.h0", "normal")
@pa_container_size("egress", "hdr.main1.h1", 16) @pa_container_type("egress", "hdr.main1.h1", "normal")
@pa_container_size("egress", "hdr.main1.h2", 16) @pa_container_type("egress", "hdr.main1.h2", "normal")
@pa_container_size("egress", "hdr.main1.h3", 16) @pa_container_type("egress", "hdr.main1.h3", "normal")
@pa_container_size("egress", "hdr.main1.h4", 16) @pa_container_type("egress", "hdr.main1.h4", "normal")

@pa_container_size("egress", "hdr.main2.w0", 32) @pa_container_type("egress", "hdr.main2.w0", "normal")
@pa_container_size("egress", "hdr.main2.w1", 32) @pa_container_type("egress", "hdr.main2.w1", "normal")
@pa_container_size("egress", "hdr.main2.w2", 32) @pa_container_type("egress", "hdr.main2.w2", "normal")
@pa_container_size("egress", "hdr.main2.w3", 32) @pa_container_type("egress", "hdr.main2.w3", "normal")
@pa_container_size("egress", "hdr.main2.b0", 8) @pa_container_type("egress", "hdr.main2.b0", "normal")
@pa_container_size("egress", "hdr.main2.b1", 8) @pa_container_type("egress", "hdr.main2.b1", "normal")
@pa_container_size("egress", "hdr.main2.b2", 8) @pa_container_type("egress", "hdr.main2.b2", "normal")
@pa_container_size("egress", "hdr.main2.b3", 8) @pa_container_type("egress", "hdr.main2.b3", "normal")
@pa_container_size("egress", "hdr.main2.h0", 16) @pa_container_type("egress", "hdr.main2.h0", "normal")
@pa_container_size("egress", "hdr.main2.h1", 16) @pa_container_type("egress", "hdr.main2.h1", "normal")
@pa_container_size("egress", "hdr.main2.h2", 16) @pa_container_type("egress", "hdr.main2.h2", "normal")
@pa_container_size("egress", "hdr.main2.h3", 16) @pa_container_type("egress", "hdr.main2.h3", "normal")
@pa_container_size("egress", "hdr.main2.h4", 16) @pa_container_type("egress", "hdr.main2.h4", "normal")


// Egress e_tail_h
@pa_container_size("egress", "hdr.tail.h0", 16) @pa_container_type("egress", "hdr.tail.h0", "normal")
@pa_container_size("egress", "hdr.tail.h1", 16) @pa_container_type("egress", "hdr.tail.h1", "normal")
@pa_container_size("egress", "hdr.tail.h2", 16) @pa_container_type("egress", "hdr.tail.h2", "normal")
@pa_container_size("egress", "hdr.tail.h3", 16) @pa_container_type("egress", "hdr.tail.h3", "normal")


/* For compability with the control plane we define a specifically named header
 * with a 16-bit field.  This will be used in a match table to control the
 * packet's forwarding destination.  It will also have a 14B padding field
 * representing the Ethernet header added by the control plane. */
header test_data_t {
  bit<(14*8)> ethernet;
  bit<16> pkt_ctrl;
}

// Ingress header
struct i_header_t {
    test_data_t testdata;
    main_h main0;
    main_h main1;
    main_h main2;
    main_h main3;
    main_h main4;
    main_h main5;
    main_h main6;
    main_h main7;
    main_h main8;
    i_tail_h tail;
}

// Egress header
struct e_header_t {
    test_data_t testdata;
    main_h main0;
    main_h main1;
    main_h main2;
    e_tail_h tail;
}

struct metadata {
    bit<9> ingress_port;
}

struct portmeta {
    bit<9> eg_port;
}

// Header AND operations
// Ingress Parser
parser IgParser(
        packet_in pkt,
        out i_header_t hdr,
        out metadata md,
        out ingress_intrinsic_metadata_t ig_intr_md,
        out ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm,
        out ingress_intrinsic_metadata_from_parser_t ig_intr_md_from_prsr) {

    //@dontmerge("ingress")
    state start {
        pkt.extract(ig_intr_md);
        // portmeta port_md = port_metadata_unpack<portmeta>(pkt);
        // ig_intr_md_for_tm.ucast_egress_port = port_md.eg_port;
        pkt.advance(PORT_METADATA_SIZE);
        md.ingress_port = ig_intr_md.ingress_port;
        pkt.extract(hdr.testdata);
        transition after_testdata;
   }
   //@dontmerge("ingress")
   state after_testdata {
        pkt.extract(hdr.main0);
        pkt.extract(hdr.main1);
        pkt.extract(hdr.main2);
        pkt.extract(hdr.main3);
        pkt.extract(hdr.main4);
        pkt.extract(hdr.main5);
        pkt.extract(hdr.main6);
        pkt.extract(hdr.main7);
        pkt.extract(hdr.main8);
        pkt.extract(hdr.tail);
        transition accept;
    }
}


// Ingress pipeline
@disable_reserved_i2e_drop_implementation
control Ig(
        inout i_header_t hdr,
        inout metadata md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_intr_md_from_prsr,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm) {

    action hdr_copy_action_0_0() { hdr.main0.w0 = 0; hdr.main0.w1 = 0; hdr.main0.w2 = 0; hdr.main0.w3 = 0; hdr.main0.b0 = 0; hdr.main0.b1 = 0; hdr.main0.b2 = 0; hdr.main0.b3 = 0; hdr.main0.h0 = 0; hdr.main0.h1 = 0; hdr.main0.h2 = 0; hdr.main0.h3 = 0; hdr.main0.h4 = 0; } @stage( 0) table hdr_copy_0_0 { actions = {NoAction; hdr_copy_action_0_0;} default_action = NoAction; size = 256; }
    action hdr_copy_action_1_1() { hdr.main1.w0 = 0; hdr.main1.w1 = 0; hdr.main1.w2 = 0; hdr.main1.w3 = 0; hdr.main1.b0 = 0; hdr.main1.b1 = 0; hdr.main1.b2 = 0; hdr.main1.b3 = 0; hdr.main1.h0 = 0; hdr.main1.h1 = 0; hdr.main1.h2 = 0; hdr.main1.h3 = 0; hdr.main1.h4 = 0; } @stage( 1) table hdr_copy_1_1 { actions = {NoAction; hdr_copy_action_1_1;} default_action = NoAction; size = 256; }
    action hdr_copy_action_2_2() { hdr.main2.w0 = 0; hdr.main2.w1 = 0; hdr.main2.w2 = 0; hdr.main2.w3 = 0; hdr.main2.b0 = 0; hdr.main2.b1 = 0; hdr.main2.b2 = 0; hdr.main2.b3 = 0; hdr.main2.h0 = 0; hdr.main2.h1 = 0; hdr.main2.h2 = 0; hdr.main2.h3 = 0; hdr.main2.h4 = 0; } @stage( 2) table hdr_copy_2_2 { actions = {NoAction; hdr_copy_action_2_2;} default_action = NoAction; size = 256; }
    action hdr_copy_action_3_3() { hdr.main3.w0 = 0; hdr.main3.w1 = 0; hdr.main3.w2 = 0; hdr.main3.w3 = 0; hdr.main3.b0 = 0; hdr.main3.b1 = 0; hdr.main3.b2 = 0; hdr.main3.b3 = 0; hdr.main3.h0 = 0; hdr.main3.h1 = 0; hdr.main3.h2 = 0; hdr.main3.h3 = 0; hdr.main3.h4 = 0; } @stage( 3) table hdr_copy_3_3 { actions = {NoAction; hdr_copy_action_3_3;} default_action = NoAction; size = 256; }
    action hdr_copy_action_4_4() { hdr.main4.w0 = 0; hdr.main4.w1 = 0; hdr.main4.w2 = 0; hdr.main4.w3 = 0; hdr.main4.b0 = 0; hdr.main4.b1 = 0; hdr.main4.b2 = 0; hdr.main4.b3 = 0; hdr.main4.h0 = 0; hdr.main4.h1 = 0; hdr.main4.h2 = 0; hdr.main4.h3 = 0; hdr.main4.h4 = 0; } @stage( 4) table hdr_copy_4_4 { actions = {NoAction; hdr_copy_action_4_4;} default_action = NoAction; size = 256; }
    action hdr_copy_action_5_5() { hdr.main5.w0 = 0; hdr.main5.w1 = 0; hdr.main5.w2 = 0; hdr.main5.w3 = 0; hdr.main5.b0 = 0; hdr.main5.b1 = 0; hdr.main5.b2 = 0; hdr.main5.b3 = 0; hdr.main5.h0 = 0; hdr.main5.h1 = 0; hdr.main5.h2 = 0; hdr.main5.h3 = 0; hdr.main5.h4 = 0; } @stage( 5) table hdr_copy_5_5 { actions = {NoAction; hdr_copy_action_5_5;} default_action = NoAction; size = 256; }
    action hdr_copy_action_6_6() { hdr.main6.w0 = 0; hdr.main6.w1 = 0; hdr.main6.w2 = 0; hdr.main6.w3 = 0; hdr.main6.b0 = 0; hdr.main6.b1 = 0; hdr.main6.b2 = 0; hdr.main6.b3 = 0; hdr.main6.h0 = 0; hdr.main6.h1 = 0; hdr.main6.h2 = 0; hdr.main6.h3 = 0; hdr.main6.h4 = 0; } @stage( 6) table hdr_copy_6_6 { actions = {NoAction; hdr_copy_action_6_6;} default_action = NoAction; size = 256; }
    action hdr_copy_action_7_7() { hdr.main7.w0 = 0; hdr.main7.w1 = 0; hdr.main7.w2 = 0; hdr.main7.w3 = 0; hdr.main7.b0 = 0; hdr.main7.b1 = 0; hdr.main7.b2 = 0; hdr.main7.b3 = 0; hdr.main7.h0 = 0; hdr.main7.h1 = 0; hdr.main7.h2 = 0; hdr.main7.h3 = 0; hdr.main7.h4 = 0; } @stage( 7) table hdr_copy_7_7 { actions = {NoAction; hdr_copy_action_7_7;} default_action = NoAction; size = 256; }
    action hdr_copy_action_8_8() { hdr.main8.w0 = 0; hdr.main8.w1 = 0; hdr.main8.w2 = 0; hdr.main8.w3 = 0; hdr.main8.b0 = 0; hdr.main8.b1 = 0; hdr.main8.b2 = 0; hdr.main8.b3 = 0; hdr.main8.h0 = 0; hdr.main8.h1 = 0; hdr.main8.h2 = 0; hdr.main8.h3 = 0; hdr.main8.h4 = 0; } @stage( 8) table hdr_copy_8_8 { actions = {NoAction; hdr_copy_action_8_8;} default_action = NoAction; size = 256; }
    action hdr_copy_action_0_9() { hdr.main0.w0 = 0; hdr.main0.w1 = 0; hdr.main0.w2 = 0; hdr.main0.w3 = 0; hdr.main0.b0 = 0; hdr.main0.b1 = 0; hdr.main0.b2 = 0; hdr.main0.b3 = 0; hdr.main0.h0 = 0; hdr.main0.h1 = 0; hdr.main0.h2 = 0; hdr.main0.h3 = 0; hdr.main0.h4 = 0; } @stage( 9) table hdr_copy_0_9 { actions = {NoAction; hdr_copy_action_0_9;} default_action = NoAction; size = 256; }
    action hdr_copy_action_1_10() { hdr.main1.w0 = 0; hdr.main1.w1 = 0; hdr.main1.w2 = 0; hdr.main1.w3 = 0; hdr.main1.b0 = 0; hdr.main1.b1 = 0; hdr.main1.b2 = 0; hdr.main1.b3 = 0; hdr.main1.h0 = 0; hdr.main1.h1 = 0; hdr.main1.h2 = 0; hdr.main1.h3 = 0; hdr.main1.h4 = 0; } @stage( 10) table hdr_copy_1_10 { actions = {NoAction; hdr_copy_action_1_10;} default_action = NoAction; size = 256; }
    action hdr_copy_action_2_11() { hdr.main2.w0 = 0; hdr.main2.w1 = 0; hdr.main2.w2 = 0; hdr.main2.w3 = 0; hdr.main2.b0 = 0; hdr.main2.b1 = 0; hdr.main2.b2 = 0; hdr.main2.b3 = 0; hdr.main2.h0 = 0; hdr.main2.h1 = 0; hdr.main2.h2 = 0; hdr.main2.h3 = 0; hdr.main2.h4 = 0; } @stage( 11) table hdr_copy_2_11 { actions = {NoAction; hdr_copy_action_2_11;} default_action = NoAction; size = 256; }
    action hdr_copy_action_3_12() { hdr.main3.w0 = 0; hdr.main3.w1 = 0; hdr.main3.w2 = 0; hdr.main3.w3 = 0; hdr.main3.b0 = 0; hdr.main3.b1 = 0; hdr.main3.b2 = 0; hdr.main3.b3 = 0; hdr.main3.h0 = 0; hdr.main3.h1 = 0; hdr.main3.h2 = 0; hdr.main3.h3 = 0; hdr.main3.h4 = 0; } @stage( 12) table hdr_copy_3_12 { actions = {NoAction; hdr_copy_action_3_12;} default_action = NoAction; size = 256; }
    action hdr_copy_action_4_13() { hdr.main4.w0 = 0; hdr.main4.w1 = 0; hdr.main4.w2 = 0; hdr.main4.w3 = 0; hdr.main4.b0 = 0; hdr.main4.b1 = 0; hdr.main4.b2 = 0; hdr.main4.b3 = 0; hdr.main4.h0 = 0; hdr.main4.h1 = 0; hdr.main4.h2 = 0; hdr.main4.h3 = 0; hdr.main4.h4 = 0; } @stage( 13) table hdr_copy_4_13 { actions = {NoAction; hdr_copy_action_4_13;} default_action = NoAction; size = 256; }
    action hdr_copy_action_5_14() { hdr.main5.w0 = 0; hdr.main5.w1 = 0; hdr.main5.w2 = 0; hdr.main5.w3 = 0; hdr.main5.b0 = 0; hdr.main5.b1 = 0; hdr.main5.b2 = 0; hdr.main5.b3 = 0; hdr.main5.h0 = 0; hdr.main5.h1 = 0; hdr.main5.h2 = 0; hdr.main5.h3 = 0; hdr.main5.h4 = 0; } @stage( 14) table hdr_copy_5_14 { actions = {NoAction; hdr_copy_action_5_14;} default_action = NoAction; size = 256; }
    action hdr_copy_action_6_15() { hdr.main6.w0 = 0; hdr.main6.w1 = 0; hdr.main6.w2 = 0; hdr.main6.w3 = 0; hdr.main6.b0 = 0; hdr.main6.b1 = 0; hdr.main6.b2 = 0; hdr.main6.b3 = 0; hdr.main6.h0 = 0; hdr.main6.h1 = 0; hdr.main6.h2 = 0; hdr.main6.h3 = 0; hdr.main6.h4 = 0; } @stage( 15) table hdr_copy_6_15 { actions = {NoAction; hdr_copy_action_6_15;} default_action = NoAction; size = 256; }
    action hdr_copy_action_7_16() { hdr.main7.w0 = 0; hdr.main7.w1 = 0; hdr.main7.w2 = 0; hdr.main7.w3 = 0; hdr.main7.b0 = 0; hdr.main7.b1 = 0; hdr.main7.b2 = 0; hdr.main7.b3 = 0; hdr.main7.h0 = 0; hdr.main7.h1 = 0; hdr.main7.h2 = 0; hdr.main7.h3 = 0; hdr.main7.h4 = 0; } @stage( 16) table hdr_copy_7_16 { actions = {NoAction; hdr_copy_action_7_16;} default_action = NoAction; size = 256; }
    action hdr_copy_action_8_17() { hdr.main8.w0 = 0; hdr.main8.w1 = 0; hdr.main8.w2 = 0; hdr.main8.w3 = 0; hdr.main8.b0 = 0; hdr.main8.b1 = 0; hdr.main8.b2 = 0; hdr.main8.b3 = 0; hdr.main8.h0 = 0; hdr.main8.h1 = 0; hdr.main8.h2 = 0; hdr.main8.h3 = 0; hdr.main8.h4 = 0; } @stage( 17) table hdr_copy_8_17 { actions = {NoAction; hdr_copy_action_8_17;} default_action = NoAction; size = 256; }
    action hdr_copy_action_0_18() { hdr.main0.w0 = 0; hdr.main0.w1 = 0; hdr.main0.w2 = 0; hdr.main0.w3 = 0; hdr.main0.b0 = 0; hdr.main0.b1 = 0; hdr.main0.b2 = 0; hdr.main0.b3 = 0; hdr.main0.h0 = 0; hdr.main0.h1 = 0; hdr.main0.h2 = 0; hdr.main0.h3 = 0; hdr.main0.h4 = 0; } @stage( 18) table hdr_copy_0_18 { actions = {NoAction; hdr_copy_action_0_18;} default_action = NoAction; size = 256; }
    action hdr_copy_action_1_19() { hdr.main1.w0 = 0; hdr.main1.w1 = 0; hdr.main1.w2 = 0; hdr.main1.w3 = 0; hdr.main1.b0 = 0; hdr.main1.b1 = 0; hdr.main1.b2 = 0; hdr.main1.b3 = 0; hdr.main1.h0 = 0; hdr.main1.h1 = 0; hdr.main1.h2 = 0; hdr.main1.h3 = 0; hdr.main1.h4 = 0; } @stage( 19) table hdr_copy_1_19 { actions = {NoAction; hdr_copy_action_1_19;} default_action = NoAction; size = 256; }

    action copy_tail_action() {
        hdr.tail.h0 = 0;
        hdr.tail.h1 = 0;
        hdr.tail.h2 = 0;
        hdr.tail.h3 = 0;
        hdr.tail.h4 = 0;
        hdr.tail.h5 = 0;
    }

    @stage(19) table hdr_copy_tail {
        key = {
            hdr.main0.h2 : ternary;
        }
        actions = { NoAction; copy_tail_action; }
        default_action = NoAction;
        size = 256;
    }

    @name(".cntPkt") DirectCounter<bit<32>>(CounterType_t.PACKETS) cntPkt;
    @name(".override_eg_port") action override_eg_port(PortId_t port) {
       ig_intr_md_for_tm.ucast_egress_port = port;
       cntPkt.count();
    }

    // this test forces everything into normal, we will use mocha for mgmt stuff
    @pa_container_type("ingress", "md.ingress_port", "mocha")
    @pa_container_type("ingress", "ig_intr_md_for_tm.ucast_egress_port", "mocha")
    @stage(0) @name(".dst_override") table dst_override {
       actions = {
          override_eg_port;
       }
       key = {
          md.ingress_port: exact @name("ig_intr_md.ingress_port");
       }
       size = 2048;
       counters = cntPkt;
       const entries = {
          ( 3 ) : override_eg_port( 128 );
          ( 128 ) : override_eg_port( 256 );
          ( 256 ) : override_eg_port( 384 );
          ( 384 ) : override_eg_port( 3 );
       }
    }

    apply {
        dst_override.apply();
        hdr_copy_0_0.apply();
        hdr_copy_1_1.apply();
        hdr_copy_2_2.apply();
        hdr_copy_3_3.apply();
        hdr_copy_4_4.apply();
        hdr_copy_5_5.apply();
        hdr_copy_6_6.apply();
        hdr_copy_7_7.apply();
        hdr_copy_8_8.apply();
        hdr_copy_0_9.apply();
        hdr_copy_1_10.apply();
        hdr_copy_2_11.apply();
        hdr_copy_3_12.apply();
        hdr_copy_4_13.apply();
        hdr_copy_5_14.apply();
        hdr_copy_6_15.apply();
        hdr_copy_7_16.apply();
        hdr_copy_8_17.apply();
        hdr_copy_0_18.apply();
        hdr_copy_1_19.apply();
        hdr_copy_tail.apply();
    }
}

// Ingress Deparser
control IgDeparser(
        packet_out pkt,
        inout i_header_t hdr,
        in metadata md,
        in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
        in ingress_intrinsic_metadata_t ig_intr_md) {
    apply {
        pkt.emit(hdr);
    }
}


// Egress Parser
parser EgParser(
        packet_in pkt,
        out e_header_t hdr,
        out metadata md,
        out egress_intrinsic_metadata_t eg_intr_md
        ) {

    //@dontmerge("egress")
    state start {
        pkt.extract(eg_intr_md);
        pkt.extract(hdr.testdata);
        transition after_testdata;
    }
    //@dontmerge("egress")
    state after_testdata {
        pkt.extract(hdr.main0);
        pkt.extract(hdr.main1);
        pkt.extract(hdr.main2);
        pkt.extract(hdr.tail);
        transition accept;
    }
}

// Egress pipeline
control Eg(
        inout e_header_t hdr,
        inout metadata md,
        in egress_intrinsic_metadata_t eg_intr_md,
        in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
        inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
        inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {

    action hdr_copy_action_0_0() { hdr.main0.w0 = 0; hdr.main0.w1 = 0; hdr.main0.w2 = 0; hdr.main0.w3 = 0; hdr.main0.b0 = 0; hdr.main0.b1 = 0; hdr.main0.b2 = 0; hdr.main0.b3 = 0; hdr.main0.h0 = 0; hdr.main0.h1 = 0; hdr.main0.h2 = 0; hdr.main0.h3 = 0; hdr.main0.h4 = 0; } @stage( 0) table hdr_copy_0_0 { actions = {NoAction; hdr_copy_action_0_0;} default_action = NoAction; size = 256; }
    action hdr_copy_action_1_1() { hdr.main1.w0 = 0; hdr.main1.w1 = 0; hdr.main1.w2 = 0; hdr.main1.w3 = 0; hdr.main1.b0 = 0; hdr.main1.b1 = 0; hdr.main1.b2 = 0; hdr.main1.b3 = 0; hdr.main1.h0 = 0; hdr.main1.h1 = 0; hdr.main1.h2 = 0; hdr.main1.h3 = 0; hdr.main1.h4 = 0; } @stage( 1) table hdr_copy_1_1 { actions = {NoAction; hdr_copy_action_1_1;} default_action = NoAction; size = 256; }
    action hdr_copy_action_2_2() { hdr.main2.w0 = 0; hdr.main2.w1 = 0; hdr.main2.w2 = 0; hdr.main2.w3 = 0; hdr.main2.b0 = 0; hdr.main2.b1 = 0; hdr.main2.b2 = 0; hdr.main2.b3 = 0; hdr.main2.h0 = 0; hdr.main2.h1 = 0; hdr.main2.h2 = 0; hdr.main2.h3 = 0; hdr.main2.h4 = 0; } @stage( 2) table hdr_copy_2_2 { actions = {NoAction; hdr_copy_action_2_2;} default_action = NoAction; size = 256; }
    action hdr_copy_action_0_3() { hdr.main0.w0 = 0; hdr.main0.w1 = 0; hdr.main0.w2 = 0; hdr.main0.w3 = 0; hdr.main0.b0 = 0; hdr.main0.b1 = 0; hdr.main0.b2 = 0; hdr.main0.b3 = 0; hdr.main0.h0 = 0; hdr.main0.h1 = 0; hdr.main0.h2 = 0; hdr.main0.h3 = 0; hdr.main0.h4 = 0; } @stage( 3) table hdr_copy_0_3 { actions = {NoAction; hdr_copy_action_0_3;} default_action = NoAction; size = 256; }
    action hdr_copy_action_1_4() { hdr.main1.w0 = 0; hdr.main1.w1 = 0; hdr.main1.w2 = 0; hdr.main1.w3 = 0; hdr.main1.b0 = 0; hdr.main1.b1 = 0; hdr.main1.b2 = 0; hdr.main1.b3 = 0; hdr.main1.h0 = 0; hdr.main1.h1 = 0; hdr.main1.h2 = 0; hdr.main1.h3 = 0; hdr.main1.h4 = 0; } @stage( 4) table hdr_copy_1_4 { actions = {NoAction; hdr_copy_action_1_4;} default_action = NoAction; size = 256; }
    action hdr_copy_action_2_5() { hdr.main2.w0 = 0; hdr.main2.w1 = 0; hdr.main2.w2 = 0; hdr.main2.w3 = 0; hdr.main2.b0 = 0; hdr.main2.b1 = 0; hdr.main2.b2 = 0; hdr.main2.b3 = 0; hdr.main2.h0 = 0; hdr.main2.h1 = 0; hdr.main2.h2 = 0; hdr.main2.h3 = 0; hdr.main2.h4 = 0; } @stage( 5) table hdr_copy_2_5 { actions = {NoAction; hdr_copy_action_2_5;} default_action = NoAction; size = 256; }
    action hdr_copy_action_0_6() { hdr.main0.w0 = 0; hdr.main0.w1 = 0; hdr.main0.w2 = 0; hdr.main0.w3 = 0; hdr.main0.b0 = 0; hdr.main0.b1 = 0; hdr.main0.b2 = 0; hdr.main0.b3 = 0; hdr.main0.h0 = 0; hdr.main0.h1 = 0; hdr.main0.h2 = 0; hdr.main0.h3 = 0; hdr.main0.h4 = 0; } @stage( 6) table hdr_copy_0_6 { actions = {NoAction; hdr_copy_action_0_6;} default_action = NoAction; size = 256; }
    action hdr_copy_action_1_7() { hdr.main1.w0 = 0; hdr.main1.w1 = 0; hdr.main1.w2 = 0; hdr.main1.w3 = 0; hdr.main1.b0 = 0; hdr.main1.b1 = 0; hdr.main1.b2 = 0; hdr.main1.b3 = 0; hdr.main1.h0 = 0; hdr.main1.h1 = 0; hdr.main1.h2 = 0; hdr.main1.h3 = 0; hdr.main1.h4 = 0; } @stage( 7) table hdr_copy_1_7 { actions = {NoAction; hdr_copy_action_1_7;} default_action = NoAction; size = 256; }
    action hdr_copy_action_2_8() { hdr.main2.w0 = 0; hdr.main2.w1 = 0; hdr.main2.w2 = 0; hdr.main2.w3 = 0; hdr.main2.b0 = 0; hdr.main2.b1 = 0; hdr.main2.b2 = 0; hdr.main2.b3 = 0; hdr.main2.h0 = 0; hdr.main2.h1 = 0; hdr.main2.h2 = 0; hdr.main2.h3 = 0; hdr.main2.h4 = 0; } @stage( 8) table hdr_copy_2_8 { actions = {NoAction; hdr_copy_action_2_8;} default_action = NoAction; size = 256; }
    action hdr_copy_action_0_9() { hdr.main0.w0 = 0; hdr.main0.w1 = 0; hdr.main0.w2 = 0; hdr.main0.w3 = 0; hdr.main0.b0 = 0; hdr.main0.b1 = 0; hdr.main0.b2 = 0; hdr.main0.b3 = 0; hdr.main0.h0 = 0; hdr.main0.h1 = 0; hdr.main0.h2 = 0; hdr.main0.h3 = 0; hdr.main0.h4 = 0; } @stage( 9) table hdr_copy_0_9 { actions = {NoAction; hdr_copy_action_0_9;} default_action = NoAction; size = 256; }
    action hdr_copy_action_1_10() { hdr.main1.w0 = 0; hdr.main1.w1 = 0; hdr.main1.w2 = 0; hdr.main1.w3 = 0; hdr.main1.b0 = 0; hdr.main1.b1 = 0; hdr.main1.b2 = 0; hdr.main1.b3 = 0; hdr.main1.h0 = 0; hdr.main1.h1 = 0; hdr.main1.h2 = 0; hdr.main1.h3 = 0; hdr.main1.h4 = 0; } @stage( 10) table hdr_copy_1_10 { actions = {NoAction; hdr_copy_action_1_10;} default_action = NoAction; size = 256; }
    action hdr_copy_action_2_11() { hdr.main2.w0 = 0; hdr.main2.w1 = 0; hdr.main2.w2 = 0; hdr.main2.w3 = 0; hdr.main2.b0 = 0; hdr.main2.b1 = 0; hdr.main2.b2 = 0; hdr.main2.b3 = 0; hdr.main2.h0 = 0; hdr.main2.h1 = 0; hdr.main2.h2 = 0; hdr.main2.h3 = 0; hdr.main2.h4 = 0; } @stage( 11) table hdr_copy_2_11 { actions = {NoAction; hdr_copy_action_2_11;} default_action = NoAction; size = 256; }
    action hdr_copy_action_0_12() { hdr.main0.w0 = 0; hdr.main0.w1 = 0; hdr.main0.w2 = 0; hdr.main0.w3 = 0; hdr.main0.b0 = 0; hdr.main0.b1 = 0; hdr.main0.b2 = 0; hdr.main0.b3 = 0; hdr.main0.h0 = 0; hdr.main0.h1 = 0; hdr.main0.h2 = 0; hdr.main0.h3 = 0; hdr.main0.h4 = 0; } @stage( 12) table hdr_copy_0_12 { actions = {NoAction; hdr_copy_action_0_12;} default_action = NoAction; size = 256; }
    action hdr_copy_action_1_13() { hdr.main1.w0 = 0; hdr.main1.w1 = 0; hdr.main1.w2 = 0; hdr.main1.w3 = 0; hdr.main1.b0 = 0; hdr.main1.b1 = 0; hdr.main1.b2 = 0; hdr.main1.b3 = 0; hdr.main1.h0 = 0; hdr.main1.h1 = 0; hdr.main1.h2 = 0; hdr.main1.h3 = 0; hdr.main1.h4 = 0; } @stage( 13) table hdr_copy_1_13 { actions = {NoAction; hdr_copy_action_1_13;} default_action = NoAction; size = 256; }
    action hdr_copy_action_2_14() { hdr.main2.w0 = 0; hdr.main2.w1 = 0; hdr.main2.w2 = 0; hdr.main2.w3 = 0; hdr.main2.b0 = 0; hdr.main2.b1 = 0; hdr.main2.b2 = 0; hdr.main2.b3 = 0; hdr.main2.h0 = 0; hdr.main2.h1 = 0; hdr.main2.h2 = 0; hdr.main2.h3 = 0; hdr.main2.h4 = 0; } @stage( 14) table hdr_copy_2_14 { actions = {NoAction; hdr_copy_action_2_14;} default_action = NoAction; size = 256; }
    action hdr_copy_action_0_15() { hdr.main0.w0 = 0; hdr.main0.w1 = 0; hdr.main0.w2 = 0; hdr.main0.w3 = 0; hdr.main0.b0 = 0; hdr.main0.b1 = 0; hdr.main0.b2 = 0; hdr.main0.b3 = 0; hdr.main0.h0 = 0; hdr.main0.h1 = 0; hdr.main0.h2 = 0; hdr.main0.h3 = 0; hdr.main0.h4 = 0; } @stage( 15) table hdr_copy_0_15 { actions = {NoAction; hdr_copy_action_0_15;} default_action = NoAction; size = 256; }
    action hdr_copy_action_1_16() { hdr.main1.w0 = 0; hdr.main1.w1 = 0; hdr.main1.w2 = 0; hdr.main1.w3 = 0; hdr.main1.b0 = 0; hdr.main1.b1 = 0; hdr.main1.b2 = 0; hdr.main1.b3 = 0; hdr.main1.h0 = 0; hdr.main1.h1 = 0; hdr.main1.h2 = 0; hdr.main1.h3 = 0; hdr.main1.h4 = 0; } @stage( 16) table hdr_copy_1_16 { actions = {NoAction; hdr_copy_action_1_16;} default_action = NoAction; size = 256; }
    action hdr_copy_action_2_17() { hdr.main2.w0 = 0; hdr.main2.w1 = 0; hdr.main2.w2 = 0; hdr.main2.w3 = 0; hdr.main2.b0 = 0; hdr.main2.b1 = 0; hdr.main2.b2 = 0; hdr.main2.b3 = 0; hdr.main2.h0 = 0; hdr.main2.h1 = 0; hdr.main2.h2 = 0; hdr.main2.h3 = 0; hdr.main2.h4 = 0; } @stage( 17) table hdr_copy_2_17 { actions = {NoAction; hdr_copy_action_2_17;} default_action = NoAction; size = 256; }
    action hdr_copy_action_0_18() { hdr.main0.w0 = 0; hdr.main0.w1 = 0; hdr.main0.w2 = 0; hdr.main0.w3 = 0; hdr.main0.b0 = 0; hdr.main0.b1 = 0; hdr.main0.b2 = 0; hdr.main0.b3 = 0; hdr.main0.h0 = 0; hdr.main0.h1 = 0; hdr.main0.h2 = 0; hdr.main0.h3 = 0; hdr.main0.h4 = 0; } @stage( 18) table hdr_copy_0_18 { actions = {NoAction; hdr_copy_action_0_18;} default_action = NoAction; size = 256; }
    action hdr_copy_action_1_19() { hdr.main1.w0 = 0; hdr.main1.w1 = 0; hdr.main1.w2 = 0; hdr.main1.w3 = 0; hdr.main1.b0 = 0; hdr.main1.b1 = 0; hdr.main1.b2 = 0; hdr.main1.b3 = 0; hdr.main1.h0 = 0; hdr.main1.h1 = 0; hdr.main1.h2 = 0; hdr.main1.h3 = 0; hdr.main1.h4 = 0; } @stage( 19) table hdr_copy_1_19 { actions = {NoAction; hdr_copy_action_1_19;} default_action = NoAction; size = 256; }

    action copy_tail_action() {
        hdr.tail.h0 = 0;
        hdr.tail.h1 = 0;
        hdr.tail.h2 = 0;
        hdr.tail.h3 = 0;
    }

    @stage(19) table hdr_copy_tail {
        key = {
            hdr.main0.h2 : ternary;
        }
        actions = { NoAction; copy_tail_action; }
        default_action = NoAction;
        size = 256;
    }

    apply {
        // Copy & AND Header fields
        hdr_copy_0_0.apply();
        hdr_copy_1_1.apply();
        hdr_copy_2_2.apply();
        hdr_copy_0_3.apply();
        hdr_copy_1_4.apply();
        hdr_copy_2_5.apply();
        hdr_copy_0_6.apply();
        hdr_copy_1_7.apply();
        hdr_copy_2_8.apply();
        hdr_copy_0_9.apply();
        hdr_copy_1_10.apply();
        hdr_copy_2_11.apply();
        hdr_copy_0_12.apply();
        hdr_copy_1_13.apply();
        hdr_copy_2_14.apply();
        hdr_copy_0_15.apply();
        hdr_copy_1_16.apply();
        hdr_copy_2_17.apply();
        hdr_copy_0_18.apply();
        hdr_copy_1_19.apply();
        hdr_copy_tail.apply();
    }
}

// Egress Deparser
control EgDeparser(
        packet_out pkt,
        inout e_header_t hdr,
        in metadata md,
        in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
        in egress_intrinsic_metadata_t eg_intr_md,
        in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr) {
    apply{
        pkt.emit(hdr);
    }
}

Pipeline(IgParser(),Ig(),IgDeparser(),EgParser(),Eg(),EgDeparser()) pipeline_profile;
Switch(pipeline_profile) main;
