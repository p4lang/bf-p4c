/* -*- P4_16 -*- */

#include <core.p4>
#include <tna.p4>

/*************************************************************************
 ************* C O N S T A N T S    A N D   T Y P E S  *******************
*************************************************************************/
enum bit<16> ether_type_t {
    TPID = 0x8100,
    IPV4 = 0x0800,
    IPV6 = 0x86DD
}

enum bit<8>  ip_proto_t {
    ICMP  = 1,
    IGMP  = 2,
    TCP   = 6,
    UDP   = 17
}

typedef bit<48>   mac_addr_t;
typedef bit<32>   ipv4_addr_t;
typedef bit<128>  ipv6_addr_t;

typedef bit<16>   nexthop_id_t;

/*
 * This is common code that will be useful to the modules to decide
 * how much hash to calculate
 */
#if defined(RESILIENT_SELECTION)

  const SelectorMode_t SELECTION_MODE = SelectorMode_t.RESILIENT;

  #if MAX_GROUP_SIZE <= 120
    #define HASH_WIDTH 51
  #elif MAX_GROUP_SIZE <= 3840
    #ifdef P4C
      #define HASH_WIDTH 61
    #else
      #define HASH_WIDTH 66
    #endif
  #elif MAX_GROUP_SIZE <= 119040
    #define HASH_WIDTH 66
  #else
    #error "Maximum Group Size cannot exceed 119040 members on Tofino"
  #endif

#else /* ! RESILIENT_SLECTION */

  const SelectorMode_t SELECTION_MODE = SelectorMode_t.FAIR;

  #if MAX_GROUP_SIZE <= 120
    #define HASH_WIDTH 14
  #elif MAX_GROUP_SIZE <= 3840
    #ifdef P4C
      #define HASH_WIDTH 24
    #else
      #define HASH_WIDTH 29
    #endif
  #elif MAX_GROUP_SIZE <= 119040
    #define HASH_WIDTH 29
  #else
    #error "Maximum Group Size cannot exceed 119040 members on Tofino"
  #endif

#endif /* RESILIENT_SELECTION */

/******** TABLE SIZING **********/
const bit<32> LAG_ECMP_SIZE = 16384;

/*************************************************************************
 ***********************  H E A D E R S  *********************************
 *************************************************************************/
/*  Define all the headers the program will recognize             */
/*  The actual sets of headers processed by each gress can differ */

/* Standard ethernet header */
header ethernet_h {
    mac_addr_t    dst_addr;
    mac_addr_t    src_addr;
    ether_type_t  ether_type;
}

header vlan_tag_h {
    bit<3>        pcp;
    bit<1>        cfi;
    bit<12>       vid;
    ether_type_t  ether_type;
}

header ipv4_h {
    bit<4>       version;
    bit<4>       ihl;
    bit<8>       diffserv;
    bit<16>      total_len;
    bit<16>      identification;
    bit<3>       flags;
    bit<13>      frag_offset;
    bit<8>       ttl;
    ip_proto_t   protocol;
    bit<16>      hdr_checksum;
    ipv4_addr_t  src_addr;
    ipv4_addr_t  dst_addr;
}

header option_word_h { /* Works for both IPv4 and TCP options */
    bit<32> data;
}

header ipv6_h {
    bit<4>       version;
    bit<8>       traffic_class;
    bit<20>      flow_label;
    bit<16>      payload_len;
    ip_proto_t   next_hdr;
    bit<8>       hop_limit;
    ipv6_addr_t  src_addr;
    ipv6_addr_t  dst_addr;
}

header icmp_h {
    bit<16>  type_code;
    bit<16>  checksum;
}

header igmp_h {
    bit<16>  type_code;
    bit<16>  checksum;
}

header tcp_h {
    bit<16>  src_port;
    bit<16>  dst_port;
    bit<32>  seq_no;
    bit<32>  ack_no;
    bit<4>   data_offset;
    bit<4>   res;
    bit<8>   flags;
    bit<16>  window;
    bit<16>  checksum;
    bit<16>  urgent_ptr;
}

header udp_h {
    bit<16>  src_port;
    bit<16>  dst_port;
    bit<16>  len;
    bit<16>  checksum;
}

/*************************************************************************
 **************  I N G R E S S   P R O C E S S I N G   *******************
 *************************************************************************/

    /***********************  H E A D E R S  ************************/

struct my_ingress_headers_t {
    ethernet_h         ethernet;
    vlan_tag_h[2]      vlan_tag;
    ipv4_h             ipv4;
    ipv6_h             ipv6;
    option_word_h      option_word_1;
    option_word_h      option_word_2;
    option_word_h      option_word_3;
    option_word_h      option_word_4;
    option_word_h      option_word_5;
    option_word_h      option_word_6;
    option_word_h      option_word_7;
    option_word_h      option_word_8;
    option_word_h      option_word_9;
    option_word_h      option_word_10;
    icmp_h             icmp;
    igmp_h             igmp;
    tcp_h              tcp;
    udp_h              udp;
}

    /******  G L O B A L   I N G R E S S   M E T A D A T A  *********/

struct l4_lookup_t {
    bit<16>  word_1;
    bit<16>  word_2;
}

struct my_ingress_metadata_t {
    l4_lookup_t   l4_lookup;
    bit<1>        first_frag;
    bit<1>        ipv4_checksum_err;
}

    /***********************  P A R S E R  **************************/

parser IngressParser(packet_in        pkt,
    /* User */
    out my_ingress_headers_t          hdr,
    out my_ingress_metadata_t         meta,
    /* Intrinsic */
    out ingress_intrinsic_metadata_t  ig_intr_md)
{
    Checksum() ipv4_checksum;

    /* This is a mandatory state, required by Tofino Architecture */
    state start {
        pkt.extract(ig_intr_md);
        pkt.advance(PORT_METADATA_SIZE);
        transition meta_init;
    }

    /* User Metadata Initialization */
    state meta_init {
        meta.l4_lookup         = { 0, 0 };
        meta.first_frag        = 0;
        meta.ipv4_checksum_err = 0;

        transition parse_ethernet;
    }

    /* Packet parsing */
    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type) {
            ether_type_t.TPID :  parse_vlan_tag;
            ether_type_t.IPV4 :  parse_ipv4;
            ether_type_t.IPV6 :  parse_ipv6;
            default :  accept;
        }
    }

    state parse_vlan_tag {
        pkt.extract(hdr.vlan_tag.next);
        transition select(hdr.vlan_tag.last.ether_type) {
            ether_type_t.TPID :  parse_vlan_tag;
            ether_type_t.IPV4 :  parse_ipv4;
            default: accept;
        }
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        ipv4_checksum.add(hdr.ipv4);

        transition select(hdr.ipv4.ihl) {
             5 : parse_ipv4_no_options;
             6 : parse_ipv4_options_1;
             7 : parse_ipv4_options_2;
             8 : parse_ipv4_options_3;
             9 : parse_ipv4_options_4;
            10 : parse_ipv4_options_5;
            11 : parse_ipv4_options_6;
            12 : parse_ipv4_options_7;
            13 : parse_ipv4_options_8;
            14 : parse_ipv4_options_9;
            15 : parse_ipv4_options_10;
            default: reject;
        }
    }

    state parse_ipv4_options_1 {
        pkt.extract(hdr.option_word_1);

        /* Checksum Verification */
        ipv4_checksum.add(hdr.option_word_1);

        transition parse_ipv4_no_options;
    }

    state parse_ipv4_options_2 {
        pkt.extract(hdr.option_word_1);
        pkt.extract(hdr.option_word_2);

        /* Checksum Verification */
        ipv4_checksum.add(hdr.option_word_1);
        ipv4_checksum.add(hdr.option_word_2);

        transition parse_ipv4_no_options;
    }

    state parse_ipv4_options_3 {
        pkt.extract(hdr.option_word_1);
        pkt.extract(hdr.option_word_2);
        pkt.extract(hdr.option_word_3);

        /* Checksum Verification */
        ipv4_checksum.add(hdr.option_word_1);
        ipv4_checksum.add(hdr.option_word_2);
        ipv4_checksum.add(hdr.option_word_3);

        transition parse_ipv4_no_options;
    }

    state parse_ipv4_options_4 {
        pkt.extract(hdr.option_word_1);
        pkt.extract(hdr.option_word_2);
        pkt.extract(hdr.option_word_3);
        pkt.extract(hdr.option_word_4);

        /* Checksum Verification */
        ipv4_checksum.add(hdr.option_word_1);
        ipv4_checksum.add(hdr.option_word_2);
        ipv4_checksum.add(hdr.option_word_3);
        ipv4_checksum.add(hdr.option_word_4);

        transition parse_ipv4_no_options;
    }

    state parse_ipv4_options_5 {
        pkt.extract(hdr.option_word_1);
        pkt.extract(hdr.option_word_2);
        pkt.extract(hdr.option_word_3);
        pkt.extract(hdr.option_word_4);
        pkt.extract(hdr.option_word_5);

        /* Checksum Verification */
        ipv4_checksum.add(hdr.option_word_1);
        ipv4_checksum.add(hdr.option_word_2);
        ipv4_checksum.add(hdr.option_word_3);
        ipv4_checksum.add(hdr.option_word_4);
        ipv4_checksum.add(hdr.option_word_5);

        transition parse_ipv4_no_options;
    }

    state parse_ipv4_options_6 {
        pkt.extract(hdr.option_word_1);
        pkt.extract(hdr.option_word_2);
        pkt.extract(hdr.option_word_3);
        pkt.extract(hdr.option_word_4);
        pkt.extract(hdr.option_word_5);
        pkt.extract(hdr.option_word_6);

        /* Checksum Verification */
        ipv4_checksum.add(hdr.option_word_1);
        ipv4_checksum.add(hdr.option_word_2);
        ipv4_checksum.add(hdr.option_word_3);
        ipv4_checksum.add(hdr.option_word_4);
        ipv4_checksum.add(hdr.option_word_5);
        ipv4_checksum.add(hdr.option_word_6);

        transition parse_ipv4_no_options;
    }

    state parse_ipv4_options_7 {
        pkt.extract(hdr.option_word_1);
        pkt.extract(hdr.option_word_2);
        pkt.extract(hdr.option_word_3);
        pkt.extract(hdr.option_word_4);
        pkt.extract(hdr.option_word_5);
        pkt.extract(hdr.option_word_6);
        pkt.extract(hdr.option_word_7);

        /* Checksum Verification */
        ipv4_checksum.add(hdr.option_word_1);
        ipv4_checksum.add(hdr.option_word_2);
        ipv4_checksum.add(hdr.option_word_3);
        ipv4_checksum.add(hdr.option_word_4);
        ipv4_checksum.add(hdr.option_word_5);
        ipv4_checksum.add(hdr.option_word_6);
        ipv4_checksum.add(hdr.option_word_7);

        transition parse_ipv4_no_options;
    }

    state parse_ipv4_options_8 {
        pkt.extract(hdr.option_word_1);
        pkt.extract(hdr.option_word_2);
        pkt.extract(hdr.option_word_3);
        pkt.extract(hdr.option_word_4);
        pkt.extract(hdr.option_word_5);
        pkt.extract(hdr.option_word_6);
        pkt.extract(hdr.option_word_7);
        pkt.extract(hdr.option_word_8);

        /* Checksum Verification */
        ipv4_checksum.add(hdr.option_word_1);
        ipv4_checksum.add(hdr.option_word_2);
        ipv4_checksum.add(hdr.option_word_3);
        ipv4_checksum.add(hdr.option_word_4);
        ipv4_checksum.add(hdr.option_word_5);
        ipv4_checksum.add(hdr.option_word_6);
        ipv4_checksum.add(hdr.option_word_7);
        ipv4_checksum.add(hdr.option_word_8);

        transition parse_ipv4_no_options;
    }

    state parse_ipv4_options_9 {
        pkt.extract(hdr.option_word_1);
        pkt.extract(hdr.option_word_2);
        pkt.extract(hdr.option_word_3);
        pkt.extract(hdr.option_word_4);
        pkt.extract(hdr.option_word_5);
        pkt.extract(hdr.option_word_6);
        pkt.extract(hdr.option_word_7);
        pkt.extract(hdr.option_word_8);
        pkt.extract(hdr.option_word_9);

        /* Checksum Verification */
        ipv4_checksum.add(hdr.option_word_1);
        ipv4_checksum.add(hdr.option_word_2);
        ipv4_checksum.add(hdr.option_word_3);
        ipv4_checksum.add(hdr.option_word_4);
        ipv4_checksum.add(hdr.option_word_5);
        ipv4_checksum.add(hdr.option_word_6);
        ipv4_checksum.add(hdr.option_word_7);
        ipv4_checksum.add(hdr.option_word_8);
        ipv4_checksum.add(hdr.option_word_9);

        transition parse_ipv4_no_options;
    }

    state parse_ipv4_options_10 {
        pkt.extract(hdr.option_word_1);
        pkt.extract(hdr.option_word_2);
        pkt.extract(hdr.option_word_3);
        pkt.extract(hdr.option_word_4);
        pkt.extract(hdr.option_word_5);
        pkt.extract(hdr.option_word_6);
        pkt.extract(hdr.option_word_7);
        pkt.extract(hdr.option_word_8);
        pkt.extract(hdr.option_word_9);
        pkt.extract(hdr.option_word_10);

        /* Checksum Verification */
        ipv4_checksum.add(hdr.option_word_1);
        ipv4_checksum.add(hdr.option_word_2);
        ipv4_checksum.add(hdr.option_word_3);
        ipv4_checksum.add(hdr.option_word_4);
        ipv4_checksum.add(hdr.option_word_5);
        ipv4_checksum.add(hdr.option_word_6);
        ipv4_checksum.add(hdr.option_word_7);
        ipv4_checksum.add(hdr.option_word_8);
        ipv4_checksum.add(hdr.option_word_9);
        ipv4_checksum.add(hdr.option_word_10);

        transition parse_ipv4_no_options;
     }

    state parse_ipv4_no_options {
        /* Checksum Verification */
        meta.ipv4_checksum_err = (bit<1>)ipv4_checksum.verify();

        meta.l4_lookup = pkt.lookahead<l4_lookup_t>();

        transition select(hdr.ipv4.frag_offset, hdr.ipv4.protocol) {
            ( 0, ip_proto_t.ICMP ) : parse_icmp;
            ( 0, ip_proto_t.IGMP ) : parse_igmp;
            ( 0, ip_proto_t.TCP  ) : parse_tcp;
            ( 0, ip_proto_t.UDP  ) : parse_udp;
            ( 0, _               ) : parse_first_fragment;
            default : accept;
        }
    }

    state parse_ipv6 {
        pkt.extract(hdr.ipv6);
        meta.l4_lookup = pkt.lookahead<l4_lookup_t>();

        transition select(hdr.ipv6.next_hdr) {
            ip_proto_t.ICMP : parse_icmp;
            ip_proto_t.IGMP : parse_igmp;
            ip_proto_t.TCP  : parse_tcp;
            ip_proto_t.UDP  : parse_udp;
            default : parse_first_fragment;
        }
    }

    state parse_first_fragment {
        meta.first_frag = 1;
        transition accept;
    }

    state parse_icmp {
        pkt.extract(hdr.icmp);
        transition parse_first_fragment;
    }

    state parse_igmp {
        pkt.extract(hdr.igmp);
        meta.first_frag = 1;
        transition parse_first_fragment;
    }

    state parse_tcp {
        pkt.extract(hdr.tcp);
        transition parse_first_fragment;
    }

    state parse_udp {
        pkt.extract(hdr.udp);
        transition parse_first_fragment;
    }
}

    /***************** M A T C H - A C T I O N  *********************/

struct selector_hashes_t {
    bit<32> hash1;
#if HASH_WIDTH > 32
    bit<32> hash2;
#endif
#if HASH_WIDTH > 64
    bit<32> hash3;
#endif
}

#define IPV4_HASH_FIELDS { \
    hdr.ipv4.src_addr,     \
    hdr.ipv4.dst_addr,     \
    protocol,              \
    meta.l4_lookup.word_1, \
    meta.l4_lookup.word_2  \
}

control calc_ipv4_hash(
    in my_ingress_headers_t   hdr,
    in my_ingress_metadata_t  meta,
    out selector_hashes_t     hash)
{
    CRCPolynomial<bit<32>>(
        0x04C11DB7, true, false, false, 32w0xFFFFFFFF, 32w0xFFFFFFFF) crc32;
    Hash<bit<32>>(HashAlgorithm_t.CRC32, crc32) hash1;

#if HASH_WIDTH > 32
    CRCPolynomial<bit<32>>(
        0x1EDC6F41, true, false, false, 32w0xFFFFFFFF, 32w0xFFFFFFFF) crc32c;
    Hash<bit<32>>(HashAlgorithm_t.CRC32, crc32) hash2;
#endif

#if HASH_WIDTH > 64
    CRCPolynomial<bit<32>>(
        0xA833982B, true, false, false, 32w0xFFFFFFFF, 32w0xFFFFFFFF) crc32d;
    Hash<bit<32>>(HashAlgorithm_t.CRC32, crc32) hash3;
#endif

    bit<8> protocol = (bit<8>)hdr.ipv4.protocol;

    apply {
        hash.hash1 = hash1.get(IPV4_HASH_FIELDS);
#if HASH_WIDTH > 32
        hash.hash2 = hash2.get(IPV4_HASH_FIELDS);
#endif

#if HASH_WIDTH > 64
        hash.hash3 = hash3.get(IPV4_HASH_FIELDS);
#endif
    }
}

#define IPV6_HASH_FIELDS { \
    hdr.ipv6.src_addr,     \
    hdr.ipv6.dst_addr,     \
    protocol,              \
    meta.l4_lookup.word_1, \
    meta.l4_lookup.word_2  \
}

control calc_ipv6_hash(
    in my_ingress_headers_t   hdr,
    in my_ingress_metadata_t  meta,
    out selector_hashes_t     hash)
{
    CRCPolynomial<bit<32>>(
        0x04C11DB7, true, false, false, 32w0xFFFFFFFF, 32w0xFFFFFFFF) crc32;
    Hash<bit<32>>(HashAlgorithm_t.CRC32, crc32) hash1;

#if HASH_WIDTH > 32
    CRCPolynomial<bit<32>>(
        0x1EDC6F41, true, false, false, 32w0xFFFFFFFF, 32w0xFFFFFFFF) crc32c;
    Hash<bit<32>>(HashAlgorithm_t.CRC32, crc32) hash2;
#endif

#if HASH_WIDTH > 64
    CRCPolynomial<bit<32>>(
        0xA833982B, true, false, false, 32w0xFFFFFFFF, 32w0xFFFFFFFF) crc32d;
    Hash<bit<32>>(HashAlgorithm_t.CRC32, crc32) hash3;
#endif

    bit<8> protocol = (bit<8>)hdr.ipv6.next_hdr;

    apply {
        hash.hash1 = hash1.get(IPV6_HASH_FIELDS);
#if HASH_WIDTH > 32
        hash.hash2 = hash2.get(IPV6_HASH_FIELDS);
#endif

#if HASH_WIDTH > 64
        hash.hash3 = hash3.get(IPV6_HASH_FIELDS);
#endif
    }
}

control Ingress(
    /* User */
    inout my_ingress_headers_t                       hdr,
    inout my_ingress_metadata_t                      meta,
    /* Intrinsic */
    in    ingress_intrinsic_metadata_t               ig_intr_md,
    in    ingress_intrinsic_metadata_from_parser_t   ig_prsr_md,
    inout ingress_intrinsic_metadata_for_deparser_t  ig_dprsr_md,
    inout ingress_intrinsic_metadata_for_tm_t        ig_tm_md)
{
    nexthop_id_t       nexthop_id = 0;
    bit<8>             ttl_dec = 0;
    selector_hashes_t  hash = {
        #if HASH_WIDTH > 64
        0,
        #endif
        #if HASH_WIDTH > 32
        0,
        #endif
        0
        };

    action send(PortId_t port) {
        ig_tm_md.ucast_egress_port = port;
        ttl_dec = 0;
    }

    action drop() {
        ig_dprsr_md.drop_ctl = 1;
    }

    action l3_switch(PortId_t port, bit<48> new_mac_da, bit<48> new_mac_sa) {
        hdr.ethernet.dst_addr = new_mac_da;
        hdr.ethernet.src_addr = new_mac_sa;
        ttl_dec = 1;
        ig_tm_md.ucast_egress_port = port;

    }

    action set_nexthop(nexthop_id_t nexthop) {
        nexthop_id = nexthop;
    }

    table ipv4_host {
        key = { hdr.ipv4.dst_addr : exact; }
        actions = {
            set_nexthop;
            @defaultonly NoAction;
        }
        const default_action = NoAction();
        size = 65536;
    }

    table ipv4_lpm {
        key     = { hdr.ipv4.dst_addr : lpm; }
        actions = { set_nexthop; }

        default_action = set_nexthop(0);
        size           = 12288;
    }

    table ipv6_host {
        key = { hdr.ipv6.dst_addr : exact; }
        actions = {
            set_nexthop;
            @defaultonly NoAction;
        }
        const default_action = NoAction();
        size = 32768;
    }

    table ipv6_lpm {
        key     = { hdr.ipv6.dst_addr : lpm; }
        actions = { set_nexthop; }

        default_action = set_nexthop(0);
        size           = 4096;
    }

    Hash<bit<HASH_WIDTH>>(HashAlgorithm_t.IDENTITY) final_hash;
    ActionSelector(LAG_ECMP_SIZE, final_hash, SELECTION_MODE) lag_ecmp;
    @selector_max_group_size(120)
    table nexthop {
        key = {
            nexthop_id : exact;

            hash.hash1 : selector;
            #if HASH_WIDTH > 32
            hash.hash2 : selector;
            #endif
            #if HASH_WIDTH > 64
            hash.hash3 : selector;
            #endif
        }
        actions = { send; drop; l3_switch; }
        size = 16384;
        implementation = lag_ecmp;
    }

    action decrement(inout bit<8> what, in bit<8> dec_amount) {
        what = what - dec_amount;
    }

    /* The algorithm */
    apply {
        if (hdr.ipv4.isValid()) {
            calc_ipv4_hash.apply(hdr, meta, hash);
            if (meta.ipv4_checksum_err == 0 && hdr.ipv4.ttl > 1) {
                if (!ipv4_host.apply().hit) {
                    ipv4_lpm.apply();
                }
            }
        } else if (hdr.ipv6.isValid()) {
            calc_ipv6_hash.apply(hdr, meta, hash);
            if (hdr.ipv6.hop_limit > 1) {
                if (!ipv6_host.apply().hit) {
                    ipv6_lpm.apply();
                }
            }
        }
        nexthop.apply();

        /* TTL Modifications */
        if (hdr.ipv4.isValid()) {
            decrement(hdr.ipv4.ttl, ttl_dec);
        } else if (hdr.ipv6.isValid()) {
            decrement(hdr.ipv6.hop_limit, ttl_dec);
        }
    }
}

    /*********************  D E P A R S E R  ************************/

control IngressDeparser(packet_out pkt,
    /* User */
    inout my_ingress_headers_t                       hdr,
    in    my_ingress_metadata_t                      meta,
    /* Intrinsic */
    in    ingress_intrinsic_metadata_for_deparser_t  ig_dprsr_md)
{
    Checksum() ipv4_checksum;

    apply {
        hdr.ipv4.hdr_checksum = ipv4_checksum.update({
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
                hdr.ipv4.dst_addr,
                hdr.option_word_1,
                hdr.option_word_2,
                hdr.option_word_3,
                hdr.option_word_4,
                hdr.option_word_5,
                hdr.option_word_6,
                hdr.option_word_7,
                hdr.option_word_8,
                hdr.option_word_9,
                hdr.option_word_10
            });
        pkt.emit(hdr);
    }
}


/*************************************************************************
 ****************  E G R E S S   P R O C E S S I N G   *******************
 *************************************************************************/

    /***********************  H E A D E R S  ************************/

struct my_egress_headers_t {
}

    /********  G L O B A L   E G R E S S   M E T A D A T A  *********/

struct my_egress_metadata_t {
}

    /***********************  P A R S E R  **************************/

parser EgressParser(packet_in      pkt,
    /* User */
    out my_egress_headers_t          hdr,
    out my_egress_metadata_t         meta,
    /* Intrinsic */
    out egress_intrinsic_metadata_t  eg_intr_md)
{
    /* This is a mandatory state, required by Tofino Architecture */
    state start {
        pkt.extract(eg_intr_md);
        transition accept;
    }
}

    /***************** M A T C H - A C T I O N  *********************/

control Egress(
    /* User */
    inout my_egress_headers_t                          hdr,
    inout my_egress_metadata_t                         meta,
    /* Intrinsic */
    in    egress_intrinsic_metadata_t                  eg_intr_md,
    in    egress_intrinsic_metadata_from_parser_t      eg_prsr_md,
    inout egress_intrinsic_metadata_for_deparser_t     eg_dprsr_md,
    inout egress_intrinsic_metadata_for_output_port_t  eg_oport_md)
{
    apply {
    }
}

    /*********************  D E P A R S E R  ************************/

control EgressDeparser(packet_out pkt,
    /* User */
    inout my_egress_headers_t                       hdr,
    in    my_egress_metadata_t                      meta,
    /* Intrinsic */
    in    egress_intrinsic_metadata_for_deparser_t  eg_dprsr_md)
{
    apply {
        pkt.emit(hdr);
    }
}


/************ F I N A L   P A C K A G E ******************************/
Pipeline(
    IngressParser(),
    Ingress(),
    IngressDeparser(),
    EgressParser(),
    Egress(),
    EgressDeparser()
) pipe;

Switch(pipe) main;
