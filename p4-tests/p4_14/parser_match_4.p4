header_type ipv4_t {
    fields {
        version        : 4;
        ihl            : 4;
        diffserv       : 8;
        totalLen       : 16;
        identification : 16;
        flags          : 3;
        fragOffset     : 13;
        ttl            : 8;
        protocol       : 8;
        hdrChecksum    : 16;
        srcAddr        : 32;
        dstAddr        : 32;
    }
}

header_type udp_t {
    fields {
        srcPort     : 16;
        dstPort     : 16;
        length_     : 16;  /* length is a reserved word */
        checksum    : 16;
    }
}

/*************************************************************************
 ***********************  P A R S E R  ***********************************
 *************************************************************************/
header ipv4_t     ipv4;
header udp_t      udp;


#define IPV4_OPTIONS(bits)                                 \
  header_type ipv4_options_##bits##b_t {                   \
      fields { options : bits; }                           \
  }                                                        \
                                                           \
  header ipv4_options_##bits##b_t ipv4_options_##bits##b;  \
                                                           \
  parser parse_ipv4_options_##bits##b {                    \
      extract(ipv4_options_##bits##b);                     \
      return parse_ipv4_no_options;                        \
  }

IPV4_OPTIONS( 32)  // ihl=0x6  4 Bytes
IPV4_OPTIONS( 64)  // ihl=0x7  8 Bytes
IPV4_OPTIONS( 96)  // ihl=0x8 12 Bytes
//IPV4_OPTIONS(128)  // ihl=0x9 16 Bytes
//IPV4_OPTIONS(160)  // ihl=0xA 20 Bytes
//IPV4_OPTIONS(192)  // ihl=0xB 24 Bytes
//IPV4_OPTIONS(224)  // ihl=0xC 28 Bytes
//IPV4_OPTIONS(256)  // ihl=0xD 32 Bytes
//IPV4_OPTIONS(288)  // ihl=0xE 36 Bytes
//IPV4_OPTIONS(320)  // ihl=0xF 40 Bytes

parser start {
    extract(ipv4);
    return select(ipv4.ihl) {
        0x5 : parse_ipv4_no_options;
        0x6 : parse_ipv4_options_32b;
        0x7 : parse_ipv4_options_64b;
        0x8 : parse_ipv4_options_96b;
//        0x9 : parse_ipv4_options_128b;
//        0xA : parse_ipv4_options_160b;
//        0xB : parse_ipv4_options_192b;
//        0xC : parse_ipv4_options_224b;
//        0xD : parse_ipv4_options_256b;
//        0xE : parse_ipv4_options_288b;
//        0xF : parse_ipv4_options_320b;
        default  : ingress; 
    }
}

parser parse_ipv4_no_options {
    return select(ipv4.fragOffset, ipv4.protocol) {
        0x000011 : parse_udp;
        default  : ingress;
    }
}

parser parse_udp {
    extract(udp);
    return ingress;
}

control ingress { }
control egress { }
