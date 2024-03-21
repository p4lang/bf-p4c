/*!
 * @file packet_parser_egress.p4
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

parser PacketParserEgress(packet_in pkt,
                    inout eg_header_t hdr, inout egress_metadata_t eg_md ) {
    state start {
        pkt.extract(hdr.ethernet);
        transition select(eg_md.bridge.l2_offset) {
            (1): parseHeaders1;
            (2): parseHeaders2;
            (3): parseHeaders3;
            (4): parseHeaders4;
            (5): parseHeaders5;
            (6): parseHeaders6;
            (7): parseHeaders7;
            (8): parseHeaders8;
            (9): parseHeaders9;
        default: parse_headers;
        }
    }

    state parseHeaders1 {
        pkt.extract(hdr.skip_l2_1);
        transition parse_headers;
    }

    state parseHeaders2 {
        pkt.extract(hdr.skip_l2_2);
        transition parse_headers;
    }

    state parseHeaders3 {
        pkt.extract(hdr.skip_l2_3);
        transition parse_headers;
    }

    state parseHeaders4 {
        pkt.extract(hdr.skip_l2_4);
        transition parse_headers;
    }

    state parseHeaders5 {
        pkt.extract(hdr.skip_l2_5);
        transition parse_headers;
    }

    state parseHeaders6 {
        pkt.extract(hdr.skip_l2_6);
        transition parse_headers;
    }

    state parseHeaders7 {
        pkt.extract(hdr.skip_l2_7);
        transition parse_headers;
    }

    state parseHeaders8 {
        pkt.extract(hdr.skip_l2_8);
        transition parse_headers;
    }

    state parseHeaders9 {
        pkt.extract(hdr.skip_l2_9);
        transition parse_headers;
    }

    state parse_headers {
        transition select(pkt.lookahead<ip46_h>().version) {
            (4): parseIpv4;
            (6): parseIpv6;
            default: parsel23payload;
        }
    }

    state parseIpv4Payload {
        transition select(eg_md.bridge.flags_l3_protocol) {
            1 : parseUdp;
            2 : parseTcp;
            3 : parseGre;
            4 : parseGtp;
            6 : parseInnerIpv6;
            7 : parseIcmp;
            default: parseL23;
        }
    }

    state parseIpv4 {
        pkt.extract(hdr.ip_version);
        pkt.extract(hdr.ipv4);
        pkt.extract(hdr.ipv4_options, (bit<32>)(hdr.ip_version.hdrlength - 5)*32 );
        transition parseIpv4Payload;
    }

    state parseIpv6 {
        pkt.extract(hdr.ip_version);
        pkt.extract(hdr.ipv6);
        transition select(eg_md.bridge.flags_l3_protocol) {
            (1): parseUdp;
            (4): parseGtp;
            (7): parseIcmp;
            (2): parseTcp;
            (3): parseGre;
            (5): parseInnerIpv4;
            default: parseL23;
        }
    }
   
    state parseGreNoChecksum {
      transition select(hdr.gre.protocol_type) {
         (ETHERTYPE_IPV4): parseInnerIpv4;
         (ETHERTYPE_IPV6): parseInnerIpv6;
         default: accept;
      }
    }

    state parseGreChecksum {
      pkt.extract(hdr.gre_checksum);
      transition select(hdr.gre.protocol_type) {
         (ETHERTYPE_IPV4): parseInnerIpv4;
         (ETHERTYPE_IPV6): parseInnerIpv6;
         default: accept;
      }
    }

    state parseGre {
      pkt.extract(hdr.gre);
      transition select(hdr.gre.checksum_flag) {
         (1w0x1): parseGreChecksum;
         default: parseGreNoChecksum;
      }
    }

    state parseL23 {
        transition select(eg_md.bridge.l23_txtstmp_insert) {
            1w1 : parseL23Timestamp;
            default: parseFirstPayload;
        }
    }

    state parseTcp{
        pkt.extract(hdr.tcp);
        transition select(eg_md.bridge.l47_timestamp_insert, eg_md.bridge.l23_txtstmp_insert)
        {
            (1w1, 1w0): parseL23;
            (1w0, 1w1): parseL23;
            default: accept;
        }
    }

     state parseIcmp {
        pkt.extract(hdr.icmp);
        pkt.extract(hdr.first_payload);
        transition accept;
    }

    state parseUdp {
        pkt.extract(hdr.udp);
        transition select(eg_md.bridge.l47_timestamp_insert, eg_md.bridge.l23_txtstmp_insert)
        {
            (1w1, 1w0): parseL47tstamp;
            (1w0, 1w1): parseL23Timestamp;
            default: accept;
        }
    }

    state parseL23Timestamp {
        pkt.extract(hdr.first_payload);
        pkt.extract(hdr.rx_timestamp);
        pkt.extract(hdr.l23_option);
        transition accept;
    }

    state parseFirstPayload {
        pkt.extract(hdr.first_payload);
        transition accept;
    }

    state parseL47tstamp {
        pkt.extract(hdr.l47_tstamp);
        transition accept;
    }

    state parseGtp {
        pkt.extract(hdr.udp);
        pkt.extract(hdr.gtp1);
        transition select(pkt.lookahead<ip46_h>().version) {
          4w0x4: parseInnerIpv4;
          4w0x6: parseInnerIpv6;
          default: accept;
      }
    }


    state parseInnerIpv4 {
      pkt.extract(hdr.inner_ip_version);
      pkt.extract(hdr.inner_ipv4);
      pkt.extract(hdr.inner_ipv4_options, (bit<32>)(hdr.inner_ip_version.hdrlength - 5)*32 );
      transition select(hdr.inner_ipv4.protocol,
        eg_md.bridge.l47_timestamp_insert,
        eg_md.bridge.l23_txtstmp_insert) {
        (IP_PROTOCOLS_TCP, 1w1, 1w0): parseInnerTcp;
        (IP_PROTOCOLS_TCP, 1w0, 1w1): parseInnerTcpL23Timestamp;
        (IP_PROTOCOLS_UDP, 1w0, 1w1): parseInnerUdpL23Timestamp;
        (IP_PROTOCOLS_UDP, 1w1, 1w0): parseInnerUdp;
        (_,                1w1, 1w0): parseFirstPayload;
        (_,                1w1, 1w1): parseL23Timestamp;
        default: accept;
      }
    }

    state parseInnerIpv6 {
      pkt.extract(hdr.inner_ip_version);
      pkt.extract(hdr.inner_ipv6);
      transition select(hdr.inner_ipv6.next_hdr,
        eg_md.bridge.l47_timestamp_insert,
        eg_md.bridge.l23_txtstmp_insert) {
        (IP_PROTOCOLS_TCP, 1w1, 1w0): parseInnerTcp;
        (IP_PROTOCOLS_TCP, 1w0, 1w1): parseInnerTcpL23Timestamp;
        (IP_PROTOCOLS_UDP, 1w0, 1w1): parseInnerUdpL23Timestamp;
        (IP_PROTOCOLS_UDP, 1w1, 1w0): parseInnerUdp;
        (_,                1w1, 1w0): parseFirstPayload;
        (_,                1w0, 1w1): parseL23Timestamp;
        default: accept;
      }
    }

    state parseInnerTcpL23Timestamp {
        pkt.extract(hdr.inner_tcp);
        transition parsel23payload;
    }

    state parseInnerUdpL23Timestamp{
        pkt.extract(hdr.inner_udp);
        transition parsel23payload;
    }

    state parseInnerTcp {
        pkt.extract(hdr.inner_tcp);
        pkt.extract(hdr.first_payload);
        transition accept;
    }

    state parsel23payload {
        pkt.extract(hdr.first_payload);
        pkt.extract(hdr.rx_timestamp);
        pkt.extract(hdr.l23_option);
        transition accept;
    }

    state parseInnerUdp{
        pkt.extract(hdr.inner_udp);
        pkt.extract(hdr.first_payload);
        transition accept;
    }
}


