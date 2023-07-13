/*!
 * @file packet_parser_ingress.p4
 * @brief  main functions for Eagle switch.
 * @author
 * @date
 */

#if __TARGET_TOFINO__ == 2
#include <t2na.p4>
#else
#include <tna.p4>
#endif

#include "headers.p4"

parser PacketParserIngress(packet_in pkt,
                    out header_t hdr,
                    out ingress_metadata_t meta,
                    out ingress_intrinsic_metadata_t ig_intr_md) {
    state start {
        pkt.extract(ig_intr_md);
        meta.port_properties =
        port_metadata_unpack<port_metadata_t>(pkt);
       // meta.l47_ib_ethertype = 0;
        meta.ipv6_src_127_96 = 0;
        meta.ipv6_src_95_64 = 0;
        meta.ipv6_src_63_32 = 0;
        meta.ip_src_31_0 = 0;
        meta.ipv6_dst_127_96 = 0;
        meta.ipv6_dst_95_64 = 0;
        meta.ipv6_dst_63_32 = 0;
        meta.ip_dst_31_0 = 0;
        meta.src_port = 0;
        meta.dst_port = 0;
        meta.v4options_count = 0;
        meta.innerv4options_count = 0;
        // initialize bridge header
        hdr.bridge.setValid();
        hdr.bridge.l47_timestamp_insert = 0;
        hdr.bridge.l23_txtstmp_insert = 0;
        hdr.bridge.l23_rxtstmp_insert = 0;
        hdr.bridge.l2_offset = 0;
        transition parseEthernet;
    }

    state parseEthernet {
        pkt.extract(hdr.ethernet);
        hdr.bridge.pkt_type = PKT_TYPE_NORMAL;
        transition select(hdr.ethernet.ether_type) {
            0 &&& 0xf800: parseSnapHeader; /* < 1536 */
            ETHERTYPE_VLAN: parseVlan;
            ETHERTYPE_SVLAN: parseVlan;
            ETHERTYPE_MPLS_UNICAST: parseMpls;
            ETHERTYPE_MPLS_MULTICAST: parseMpls;
            ETHERTYPE_IPV4: parseIp;
            ETHERTYPE_IPV6: parseIpv6;
            ETHERTYPE_ARP:  parseAccept;
            ETHERTYPE_LLDP: parseCPU;
            default: parseL23;
        }
    }
    
    state parseCPU {
        meta.cpu_lldp = 1;
        transition accept;
    }

    state parseSnapHeader {
        pkt.extract(hdr.snap);
        transition select(hdr.snap.ether_type) {
            ETHERTYPE_MPLS_UNICAST: parseMpls;
            ETHERTYPE_MPLS_MULTICAST: parseMpls;
            ETHERTYPE_IPV4: parseIp;
            ETHERTYPE_IPV6: parseIpv6;
            ETHERTYPE_ARP:  parseAccept;
            default: parseL23;
        }
    }

    state parseVlan {
        pkt.extract(hdr.vlan_tag_0);
        transition select(hdr.vlan_tag_0.ether_type) {
            0 &&& 0xf800: parseSnapHeader; /* < 1536 */
            ETHERTYPE_VLAN_INNER: parseVlan1;
            ETHERTYPE_VLAN: parseVlan1;
            ETHERTYPE_SVLAN: parseVlan1;
            ETHERTYPE_MPLS_UNICAST: parseMpls;
            ETHERTYPE_MPLS_MULTICAST: parseMpls;
            ETHERTYPE_IPV4: parseIp;
            ETHERTYPE_IPV6: parseIpv6;
            ETHERTYPE_ARP:  parseAccept;
            default: parseL23;
        }
    }

    state parseVlan1 {
        pkt.extract(hdr.vlan_tag_1);
        transition select(hdr.vlan_tag_1.ether_type) {
            0 &&& 0xf800: parseSnapHeader; /* < 1536 */
            ETHERTYPE_VLAN_INNER: parseVlan2;
            ETHERTYPE_VLAN: parseVlan2;
            ETHERTYPE_SVLAN: parseVlan2;
            ETHERTYPE_MPLS_UNICAST: parseMpls;
            ETHERTYPE_MPLS_MULTICAST: parseMpls;
            ETHERTYPE_IPV4: parseIp;
            ETHERTYPE_IPV6: parseIpv6;
            ETHERTYPE_ARP:  parseAccept;
            default: parseL23;
        }
    }
    //last vlan, accept anything that is not decoded
    state parseVlan2 {
        pkt.extract(hdr.vlan_tag_2);
        transition select(hdr.vlan_tag_2.ether_type) {
            0 &&& 0xf800: parseSnapHeader; /* < 1536 */
            ETHERTYPE_MPLS_UNICAST: parseMpls;
            ETHERTYPE_MPLS_MULTICAST: parseMpls;
            ETHERTYPE_IPV4: parseIp;
            ETHERTYPE_IPV6: parseIpv6;
            ETHERTYPE_ARP:  parseAccept;
            default: parseL23;
        }
    }

    state parseMpls {
        bit<1> bos0 = pkt.lookahead<mpls5_h>().bos0;
        bit<1> bos1 = pkt.lookahead<mpls5_h>().bos1;
        bit<1> bos2 = pkt.lookahead<mpls5_h>().bos2;
        bit<1> bos3 = pkt.lookahead<mpls5_h>().bos3;
        pkt.extract(hdr.mpls_0);
        transition select(bos0, bos1, bos2, bos3) {
            (1, _, _, _) : parseIp;
            (0, 1, _, _) : parseMpls1;
            (0, 0, 1, _) : parseMpls2;
            (0, 0, 0, 1) : parseMpls3;
            default: parseMpls4Check;
        }
    }
    // have to split to 2, it error with one more bit above
    state parseMpls4Check {
        bit<1> bos3 = pkt.lookahead<mpls5_h>().bos3;
        transition select(bos3) {
            (1) : parseMpls4;
            default: parseIp;
        }
    }

    state parseMpls1 {
        pkt.extract(hdr.mpls_1);
        transition parseIp;
    }

    state parseMpls2 {
        pkt.extract(hdr.mpls_1);
        pkt.extract(hdr.mpls_2);
        transition parseIp;
    }

    state parseMpls3 {
        pkt.extract(hdr.mpls_1);
        pkt.extract(hdr.mpls_2);
        pkt.extract(hdr.mpls_3);
        transition parseIp;
    }

    state parseMpls4 {
        pkt.extract(hdr.mpls_1);
        pkt.extract(hdr.mpls_2);
        pkt.extract(hdr.mpls_3);
        pkt.extract(hdr.mpls_4);
        transition parseIp;
    }

     state parseIp {
        bit<4> version = pkt.lookahead<ip46_h>().version;
        transition select(version) {
          (4w0x4): parseMplsIpv4;
          (4w0x6): parseIpv6;
          default: parseL23;
        }
    }

    state parseMplsIpv4 {
        pkt.extract(hdr.ip_version_0);
        pkt.extract(hdr.ipv4);
        pkt.extract(hdr.ipv4_options, (bit<32>)(hdr.ip_version_0.hdrlength - 5)*32 );
        transition select(hdr.ipv4.protocol, hdr.ipv4.total_len) {
            (IP_PROTOCOLS_GRE,  _): parseGre;
            (IP_PROTOCOLS_IPV6, _): parseInnerIpv6;
            (IP_PROTOCOLS_TCP,  _): parseTcpv4;
            (IP_PROTOCOLS_UDP,  _ ): parseUdp;
            (IP_PROTOCOLS_ICMP, _): parseIcmp;
            (_, 16w0x10 &&& 16w0xfff0): parseAccept;
            (_, 16w0x2a &&& 16w0xfffa): parseL23;
            (_, 16w0x28 &&& 16w0xfffc): parseAccept;
            (_, 16w0x20 &&& 16w0xfffc): parseAccept;
            default: parseL23;
        }
    }

    state parseIpv6 {
        pkt.extract(hdr.ip_version_0);
        pkt.extract(hdr.ipv6);
        transition select(hdr.ipv6.next_hdr, hdr.ipv6.payload_len) {
            (IP_PROTOCOLS_GRE, _): parseGre;
            (IP_PROTOCOLS_IPV4, _): parseInnerIpv4;
            (IP_PROTOCOLS_ICMPv6, _): parseIcmp;
            (IP_PROTOCOLS_UDP, _): parseUdp;
            (IP_PROTOCOLS_TCP, 16w0x10 &&& 16w0xfff8) : parseTcpAccept;
            (IP_PROTOCOLS_TCP, 16w0x18 &&& 16w0xfff8) : parseTcpv4;
            (IP_PROTOCOLS_TCP, 16w0x20 &&& 16w0x20): parseTcpv4;
            (IP_PROTOCOLS_TCP, 16w0x40 &&& 16w0x40): parseTcpv4;
            (IP_PROTOCOLS_TCP, 16w0x80 &&& 16w0x80): parseTcpv4;
            (IP_PROTOCOLS_TCP, 16w0x100 &&& 16w0x100): parseTcpv4;
            (IP_PROTOCOLS_TCP, 16w0x200 &&& 16w0x200): parseTcpv4;
            (IP_PROTOCOLS_TCP, 16w0x400 &&& 16w0x400): parseTcpv4;
            (IP_PROTOCOLS_TCP, 16w0x800 &&& 16w0x800): parseTcpv4;
            (IP_PROTOCOLS_TCP, 16w0x1000 &&& 16w0x1000): parseTcpv4;
            (IP_PROTOCOLS_TCP, 16w0x2000 &&& 16w0x2000): parseTcpv4;
            (IP_PROTOCOLS_TCP, 16w0x4000 &&& 16w0x4000): parseTcpv4;
            (IP_PROTOCOLS_TCP, 16w0x8000 &&& 16w0x8000): parseTcpv4;
            (_, 16w0x18 &&& 16w0xfff8) : parseL23;
            (_, 16w0x10 &&& 16w0xfff8) : parseAccept;
            default: parseL23;
        }
    }

    state parseTcpv4 {
        pkt.extract(hdr.tcp);
        bit<32> signature = pkt.lookahead<l23signature_h>().signature_top;
        transition select(signature) {
            (L47_SIGNATURE_TOP): parseL47;
            (L23_SIGNATURE_TOP): parseL23;
            default : accept;
        }
    }


    state parseTcpAccept {
        pkt.extract(hdr.tcp);
        transition accept;
    }

    state parseIcmp {
        pkt.extract(hdr.icmp);
        pkt.extract(hdr.first_payload);
        meta.engine_id = hdr.first_payload.signature_bot[23:16];
        transition accept;
    }

    state parseUdp {
        pkt.extract(hdr.udp);
        transition select(hdr.udp.dst_port, hdr.udp.udp_length) {
            (PORT_GTP, _): parseGtpv1;
            (_, 0x10 &&& 0xfff8): parseUdpOpt;
            (_, 0x18 &&& 0xfffe): parseUdpOpt;
           // (_, 0x1a &&& 0xfffa): parseL23;
            (_, 0x00 &&& 0xfff0): parseAccept;
            default: parseL23;
        }
    }

    state parseUdpOpt {
        pkt.extract(hdr.l47_tstamp);
        transition accept;
    }

    state parseGtpv1{
        pkt.extract(hdr.gtp1);
        transition select(pkt.lookahead<ip46_h>().version) {
            4w0x4: parseInnerIpv4;
            4w0x6: parseInnerIpv6;
            default: accept;
        }
    }

    state parseGre {
        pkt.extract(hdr.gre);
        transition select(hdr.gre.checksum_flag, hdr.gre.protocol_type) {
            (1w0x1, ETHERTYPE_IPV4): parseGrechecksumIpv4;
            (1w0x1, ETHERTYPE_IPV6): parseGrechecksumIpv6;
            (1w0x0, ETHERTYPE_IPV4): parseInnerIpv4;
            (1w0x0, ETHERTYPE_IPV6): parseInnerIpv6;
            default: accept;
        }
    }

    state parseGrechecksumIpv6 {
        pkt.extract(hdr.gre_checksum);
        transition parseInnerIpv6;
    }

    state parseGrechecksumIpv4 {
        pkt.extract(hdr.gre_checksum);
        transition parseInnerIpv4;
    }

    state parseInnerUdpOpt {
        pkt.extract(hdr.inner_udp);
        pkt.extract(hdr.l47_tstamp);
        transition accept;
    }

    state parseInnerIpv6 {
        pkt.extract(hdr.inner_ip_version);
        pkt.extract(hdr.inner_ipv6);
        transition select(hdr.inner_ipv6.next_hdr, hdr.inner_ipv6.payload_len) {
            // for particular inner decode
            (IP_PROTOCOLS_TCP, 16w0x10 &&& 16w0xfff ) : parseInnerTcpAccept;
            (IP_PROTOCOLS_TCP, 16w0x18 &&& 16w0xfff8) : parseInnerTcpv4;
            (IP_PROTOCOLS_TCP, 16w0x20 &&& 16w0x20): parseInnerTcpv4;
            (IP_PROTOCOLS_TCP, 16w0x40 &&& 16w0x40): parseInnerTcpv4;
            (IP_PROTOCOLS_TCP, 16w0x80 &&& 16w0x80): parseInnerTcpv4;
            (IP_PROTOCOLS_TCP, 16w0x100 &&& 16w0x100): parseInnerTcpv4;
            (IP_PROTOCOLS_TCP, 16w0x200 &&& 16w0x200): parseInnerTcpv4;
            (IP_PROTOCOLS_TCP, 16w0x400 &&& 16w0x400): parseInnerTcpv4;
            (IP_PROTOCOLS_TCP, 16w0x800 &&& 16w0x800): parseInnerTcpv4;
            (IP_PROTOCOLS_TCP, 16w0x1000 &&& 16w0x1000): parseInnerTcpv4;
            (IP_PROTOCOLS_TCP, 16w0x2000 &&& 16w0x2000): parseInnerTcpv4;
            (IP_PROTOCOLS_TCP, 16w0x4000 &&& 16w0x4000): parseInnerTcpv4;
            (IP_PROTOCOLS_TCP, 16w0x8000 &&& 16w0x8000): parseInnerTcpv4;
            (IP_PROTOCOLS_UDP, _): parseInnerUdp;
            (_, 16w0x18 &&& 16w0xfff8) : parseL23;
            (_, 16w0x10 &&& 16w0xfff8) : parseAccept;
            default: parseL23;
        }
    }

    state parseInnerIpv4 {
        pkt.extract(hdr.inner_ip_version);
        pkt.extract(hdr.inner_ipv4);
        pkt.extract(hdr.inner_ipv4_options, (bit<32>)(hdr.inner_ip_version.hdrlength - 5)*32 );
        transition select(hdr.inner_ipv4.protocol, hdr.inner_ipv4.total_len) {
            (IP_PROTOCOLS_TCP,  _): parseInnerTcpv4; 
            (IP_PROTOCOLS_UDP, _): parseInnerUdp;
            (_, 16w0x10 &&& 16w0xfff0) : parseAccept;  
            (_, 16w0x2c &&& 16w0xfffc) : parseL23;
            (_, 16w0x28 &&& 16w0xfffc) : parseAccept;
            (_, 16w0x20 &&& 16w0xfffc) : parseAccept;  
            default: parseL23;
        }
    }

    state parseInnerTcpv4 {
        pkt.extract(hdr.inner_tcp);
        bit<32> signature = pkt.lookahead<l23signature_h>().signature_top;
        transition select(signature) {
            (L47_SIGNATURE_TOP): parseL47;
            (L23_SIGNATURE_TOP): parseL23;
            default : accept;
        }
    }

    state parseInnerTcpAccept {
        pkt.extract(hdr.inner_tcp);
        transition accept;
    }
 
    state parseInnerUdp {
        pkt.extract(hdr.inner_udp);
        transition select(hdr.inner_udp.udp_length) {
            (0x10 &&& 0xfff8):  parseUdpOpt;
            (0x18 &&& 0xfffe): parseUdpOpt;
            (0x08 &&& 0xfff0): parseAccept;
            default: parseL23;
        }
    }

    state parseL23 {
        pkt.extract(hdr.first_payload);
        pkt.extract(hdr.rx_timestamp);
        meta.engine_id = hdr.first_payload.signature_bot[23:16];
        transition accept;
    }

    state parseL47 {
        pkt.extract(hdr.first_payload);
        transition accept;
    }

    state parseAccept {
        transition accept;
    }
}
