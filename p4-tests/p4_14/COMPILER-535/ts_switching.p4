// Scheduled media switching based on RTP timestamp
// Author: Thomas Edwards (thomas.edwards@fox.com)
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

//#include <tofino/constants.p4>
#include <tofino/primitives.p4>
#include <tofino/intrinsic_metadata.p4>
#include <tofino/stateful_alu_blackbox.p4>
#include <tofino/pktgen_headers.p4>
//#include <tofino/pktgen_headers.p4>
//#include <tofino/wred_blackbox.p4>

#define MAC_LEARN_RECEIVER       0

header_type ethernet_t {
    fields {
        dstAddr : 48;
        srcAddr : 48;
        etherType : 16;
    }
}

header_type ipv4_t {
    fields {
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

header_type udp_t {
    fields {
        srcPort : 16;
        dstPort : 16;
        hdr_length : 16;
        checksum : 16;
    }
}

header_type rtp_t {
    fields {
        version : 2;
        padding : 1;
        extension : 1;
        CSRC_count : 4;
        marker : 1;
        payload_type : 7;
        sequence_number : 16;
        timestamp : 24;
        timestamp_2 : 8;
        SSRC : 32;
    }
}

header_type l3_metadata_t {
    fields {
        l3_dst_miss: 1;
    }
}
metadata l3_metadata_t l3_metadata;

header_type hct_metadata_t {
    fields {
        within_range: 4;
        timestamp_register_index:16;
        timestamp_offset:32;
        learn_meta_2:24;
        learn_meta_3:25;
        learn_meta_4:10;
    }
}

parser start {
    return parse_ethernet;
}

//@pragma pa_solitary ingress ethernet.dstAddr
//@pragma pa_solitary ingress ethernet.srcAddr
header ethernet_t ethernet;

#define ETHERTYPE_IPV4 0x0800

parser parse_ethernet {
    extract(ethernet);
    return select(latest.etherType) {
        ETHERTYPE_IPV4 : parse_ipv4;
        default: ingress;
   }
}

//@pragma pa_solitary ingress ipv4.dstAddr
//@pragma pa_solitary ingress ipv4.srcAddr
header ipv4_t ipv4;

#define PROTOCOL_UDP 0x11

parser parse_ipv4 {
    extract(ipv4);
    return select(ipv4.protocol) {
        PROTOCOL_UDP : parse_udp;
    default: ingress;
  }
}

header udp_t udp;

parser parse_udp {
    extract(udp);
    return parse_rtp;
}

//@pragma pa_solitary ingress rtp.timestamp
header rtp_t rtp;

parser parse_rtp {
    extract(rtp);
    return ingress;
}

action nop() {
}

action _drop() {
    drop();
}

action take_video(src_mac, dst_mac, src_ip, dst_ip, port_out) {
      modify_field(ethernet.srcAddr,src_mac);
      modify_field(ethernet.dstAddr,dst_mac);
      modify_field(ig_intr_md_for_tm.ucast_egress_port, port_out);
      modify_field(ipv4.srcAddr, src_ip);
      modify_field(ipv4.dstAddr, dst_ip);
}

table schedule_table {
    reads {
        ipv4.dstAddr: exact;
        rtp.timestamp mask 0x00FFFF: range;
    }
    actions {
        take_video;
        _drop;
    }
    size : 16384;
}

action l3_dst_miss() {
    modify_field( l3_metadata.l3_dst_miss, 1 );
    //drop();
}

table l3_check {
    reads {
        ipv4.dstAddr: exact;
    }
    actions {
        nop;
        l3_dst_miss;
    }
    size : 16384;
}

field_list stream_learn_digest {
    ethernet.srcAddr;
    ethernet.dstAddr;
    ipv4.srcAddr;
    ipv4.dstAddr;
    rtp.timestamp;
} // stream_learn_digest

action send_stream_learn_notification() {
    generate_digest( MAC_LEARN_RECEIVER, stream_learn_digest );
} // end send_stream_learn_notification

table stream_learn_notification {
    reads {
        l3_metadata.l3_dst_miss : exact;
    }
    actions {
       nop;
       send_stream_learn_notification;
    }
} // stream_learn_notification

control ingress {
    apply( l3_check );
    apply( stream_learn_notification );
    apply( schedule_table );
}

control egress {
}
