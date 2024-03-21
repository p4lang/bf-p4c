#ifndef _NPB_PARSERS_COMMON_
#define _NPB_PARSERS_COMMON_

//-----------------------------------------------------------------------------
// Underlay - Layer 2
//-----------------------------------------------------------------------------

parser ParserUnderlayL2(
    packet_in pkt,
    inout switch_header_t hdr,
    out bit<16> ether_type) {

    state start {
        pkt.extract(hdr.ethernet);
        ether_type = hdr.ethernet.ether_type;
        transition select(hdr.ethernet.ether_type) {
            ETHERTYPE_BR : parse_br;
            ETHERTYPE_VN : parse_vn;
            ETHERTYPE_VLAN : parse_vlan;
            ETHERTYPE_QINQ : parse_vlan;
            default : accept;
        }
    }

    state parse_br {
	    pkt.extract(hdr.e_tag);
        ether_type = hdr.e_tag.ether_type;
        transition select(hdr.e_tag.ether_type) {
            ETHERTYPE_VLAN : parse_vlan;
            ETHERTYPE_QINQ : parse_vlan;
            default : accept;
        }
    }

    state parse_vn {
	    pkt.extract(hdr.vn_tag);
        ether_type = hdr.vn_tag.ether_type;
        transition select(hdr.vn_tag.ether_type) {
            ETHERTYPE_VLAN : parse_vlan;
            ETHERTYPE_QINQ : parse_vlan;
            default : accept;
        }
    }

    state parse_vlan {
	    pkt.extract(hdr.vlan_tag.next);
        ether_type = hdr.vlan_tag.last.ether_type;
        transition select(hdr.vlan_tag.last.ether_type) {
            ETHERTYPE_VLAN : parse_vlan;
            ETHERTYPE_QINQ : parse_vlan;
            default : accept;
        }
    }
}


// //-----------------------------------------------------------------------------
// // Underlay - Network Service Headers (NSH)
// //-----------------------------------------------------------------------------
// // For now, we'll just assume a fixed 20Bytes of opaque Extreme metadata and
// // parse the whole thing as one big (fixed sized) header. We're also assuming
// // the next header will always be ethernet.
// 
// parser ParserUnderlayNsh(
//     packet_in pkt,
//     inout switch_header_t hdr) {
// 
//     state start {
// 	    pkt.extract(hdr.nsh_extr);
//         // verify base header md-type = 2
//         // verify base header length matches expected
//         // verify base header next_proto = ethernet
//         // verify md2 context header type = "extreme"
//         // verify md2 context header md_len matches expected
//         transition accept;
//     }
// }


// //-----------------------------------------------------------------------------
// // Layer3 - IPv4
// //-----------------------------------------------------------------------------
// 
// parser ParserIPv4(
//     packet_in pkt,
//     inout switch_ingress_metadata_t ig_md,
//     inout switch_header_t hdr) {
// 
//     Checksum<bit<16>>(HashAlgorithm_t.CRC16) ipv4_checksum;
// 
//     state start {
//         pkt.extract(hdr.ipv4);
//          // todo: Flag packet (to be sent to host) if it's a frag or has options.
//         ipv4_checksum.add(hdr.ipv4);
//         transition select(hdr.ipv4.ihl, hdr.ipv4.flags, hdr.ipv4.frag_offset) {
//             (5, 0, 0) : parse_ipv4_no_options_frags;
//             (5, 2, 0) : parse_ipv4_no_options_frags;
//             default : accept;
//         }
//     }
// 
//     state parse_ipv4_no_options_frags {
//         ig_md.flags.ipv4_checksum_err = ipv4_checksum.verify();
//         // bit slicing like this not supported in v8.6.0
//         //ig_md.parser_scratch[15:8] = 0x4;
//         //ig_md.parser_scratch[7:0] = hdr.ipv4.protocol;
//         //ig_md.parser_scratch_b = 0x0004;
//         //ig_md.parser_scratch_proto = hdr.ipv4.protocol;
//         ig_md.parser_protocol = 0xFF;
//         transition accept;
//     }
// 
// 
// //     state start {
// //          // todo: Flag packet (to be sent to host) if it's a frag or has options.
// //         ig_md.parser_scratch = 0xFFFF; // can we flag it like this?
// //         //ig_md.parser_scratch = -1; // can we flag it like this?
// //         ipv4_h snoop = pkt.lookahead<ipv4_h>();
// //         transition select(snoop.ihl, snoop.flags, snoop.frag_offset) {
// //             (5, 0, 0) : parse_ipv4_no_options_frags;
// //             (5, 2, 0) : parse_ipv4_no_options_frags;
// //             default : accept;
// //         }
// //     }
// // 
// //     state parse_ipv4_no_options_frags {
// //         pkt.extract(hdr.ipv4);
// //         ipv4_checksum.add(hdr.ipv4);
// //         ig_md.flags.ipv4_checksum_err = ipv4_checksum.verify();
// //         // bit slicing like this not supported in v8.6.0
// //         //ig_md.parser_scratch[15:8] = 0x4;
// //         //ig_md.parser_scratch[7:0] = hdr.ipv4.protocol;
// //         //ig_md.parser_scratch_b = 4;
// //         //ig_md.parser_scratch_b = hdr.ipv4.version;
// //         ig_md.parser_scratch = (bit<16>)hdr.ipv4.protocol;
// //         transition accept;
// //     }
// 
// 
// }
// 
// 
// 
// //-----------------------------------------------------------------------------
// // Layer3 - IPv6
// //-----------------------------------------------------------------------------
// 
// parser ParserIPv6(
//     packet_in pkt,
//     inout switch_ingress_metadata_t ig_md,
//     inout switch_header_t hdr) {
// 
//     state start {
//         pkt.extract(hdr.ipv6);
//         // bit slicing like this not supported in v8.6.0
//         //ig_md.parser_scratch[15:8] = 0x6;
//         //ig_md.parser_scratch[7:0] = hdr.ipv6.next_hdr;
//         //ig_md.parser_scratch_b = 0x0006;
//         //ig_md.parser_scratch = (bit<16>)hdr.ipv6.next_hdr;
//         transition accept;
//     }
// }




// //-------------------------------------------------------------------------
// // GPRS (General Packet Radio Service) Tunneling Protocol (GTP)
// //-------------------------------------------------------------------------
// // Based on pseudo code from Glenn (see email from 02/11/2019):
// // Does not support parsing GTP optional word
// // Does not support parsing (TLV) extension headers
// 
// parser ParserGtp(
//     packet_in pkt,
//     //inout switch_ingress_metadata_t ig_md,
//     inout bit<2> md_tunnel_type,
//     inout switch_header_t hdr) {
// 
//     state start {
// 
//         // todo: Flag frame (to be trapped) if version > 2
// #ifdef GTP_ENABLE
//         transition select(pkt.lookahead<bit<4>>()) { //version,PT
//             3: parse_gtp_u;
//             5: parse_gtp_c; // does PT matter w/ gtp-c?
//             //1,4: parse_gtp_prime;
//             default: accept;
//         }
// #else
//         transition reject;
// #endif  /* GTP_ENABLE */
//     }
// 
// #ifdef GTP_ENABLE
//     state parse_gtp_u {
//         pkt.extract(hdr.gtp_v1_base);
//     	transition select(
//             hdr.gtp_v1_base.E,
//             hdr.gtp_v1_base.S,
//             hdr.gtp_v1_base.PN) {
//             (0,0,0): parse_gtp_u_end;
//             default: accept;
//         }
//     }
// 
//     state parse_gtp_c {
//         pkt.extract(hdr.gtp_v1_base);
//         //ig_md.tunnel.type = SWITCH_TUNNEL_TYPE_GTP_C;
//         md_tunnel_type = SWITCH_TUNNEL_TYPE_GTP_C;
//     	transition accept;
//     }
// 
//     state parse_gtp_u_end {
//         //ig_md.tunnel.type = SWITCH_TUNNEL_TYPE_GTP_U;
//         md_tunnel_type = SWITCH_TUNNEL_TYPE_GTP_U;
//     	transition accept;
//     }
// #endif  /* GTP_ENABLE */
// 
// }




#endif /* _NPB_PARSERS_COMMON_ */

