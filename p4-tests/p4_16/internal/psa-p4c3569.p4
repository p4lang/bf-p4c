#include <psa.p4>


// psa defs
error {
    UnhandledIPv4Options,
    BadIPv4HeaderChecksum
}
# 2 "middleblock.p4" 2
# 1 "../../fixed/headers.p4" 1



# 1 "../../fixed/resource_limits.p4" 1



// -- Bitwidth definitions -----------------------------------------------------
# 39 "../../fixed/resource_limits.p4"
// -- Table sizes --------------------------------------------------------------
# 51 "../../fixed/resource_limits.p4"
// The maximum number of wcmp groups.


// The maximum sum of weights across all wcmp groups.


// The maximum sum of weights for each wcmp group.


// The selector chooses a group's member, so its bitwidth has to be at least
// log2 of WCMP_GROUP_SELECTOR_MAX_SUM_OF_WEIGHTS_PER_GROUP.
# 5 "../../fixed/headers.p4" 2
# 23 "../../fixed/headers.p4"
typedef bit<48> ethernet_addr_t;
typedef bit<32> ipv4_addr_t;
typedef bit<128> ipv6_addr_t;


type PortId_t port_id_t;







// -- Protocol headers ---------------------------------------------------------



header ethernet_t {
  ethernet_addr_t dst_addr;
  ethernet_addr_t src_addr;
  bit<16> ether_type;
}



header ipv4_t {
  bit<4> version;
  bit<4> ihl;
  bit<6> dscp; // The 6 most significant bits of the diff_serv field.
  bit<2> ecn; // The 2 least significant bits of the diff_serv field.
  bit<16> total_len;
  bit<16> identification;
  bit<1> reserved;
  bit<1> do_not_fragment;
  bit<1> more_fragments;
  bit<13> frag_offset;
  bit<8> ttl;
  bit<8> protocol;
  bit<16> header_checksum;
  ipv4_addr_t src_addr;
  ipv4_addr_t dst_addr;
}



header ipv6_t {
  bit<4> version;
  bit<6> dscp; // The 6 most significant bits of the traffic_class field.
  bit<2> ecn; // The 2 least significant bits of the traffic_class field.
  bit<20> flow_label;
  bit<16> payload_length;
  bit<8> next_header;
  bit<8> hop_limit;
  ipv6_addr_t src_addr;
  ipv6_addr_t dst_addr;
}

header udp_t {
  bit<16> src_port;
  bit<16> dst_port;
  bit<16> hdr_length;
  bit<16> checksum;
}

header tcp_t {
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

header icmp_t {
  bit<8> type;
  bit<8> code;
  bit<16> checksum;
}

header arp_t {
  bit<16> hw_type;
  bit<16> proto_type;
  bit<8> hw_addr_len;
  bit<8> proto_addr_len;
  bit<16> opcode;
  bit<48> sender_hw_addr;
  bit<32> sender_proto_addr;
  bit<48> target_hw_addr;
  bit<32> target_proto_addr;
}



header gre_t {
  bit<1> checksum_present;
  bit<1> routing_present;
  bit<1> key_present;
  bit<1> sequence_present;
  bit<1> strict_source_route;
  bit<3> recursion_control;
  bit<1> acknowledgement_present;
  bit<4> flags;
  bit<3> version;
  bit<16> protocol;
}


header cpu_header_t {
  bit<6> _pad;
  // The port the packet ingressed on.
  port_id_t ingress_port;
  // The initial intended egress port decided for the packet by the pipeline.
  port_id_t target_egress_port;

  // original ether_type
  bit<16> ether_type;
}
struct empty_metadata_t {
}
# 3 "middleblock.p4" 2
# 1 "../../fixed/metadata.p4" 1



##include "arch-deps.p4"
# 1 "../../fixed/ids.h" 1



// All declarations (tables, actions, action profiles, meters, counters) have a
// stable ID. This list will evolve as new declarations are added. IDs cannot be
// reused. If a declaration is removed, its ID macro is kept and marked reserved
// to avoid the ID being reused.
//
// The IDs are classified using the 8 most significant bits to be compatible
// with "6.3. ID Allocation for P4Info Objects" in the P4Runtime specification.

// --- Tables ------------------------------------------------------------------

// IDs of fixed SAI tables (8 most significant bits = 0x02).
# 25 "../../fixed/ids.h"
// --- Actions -----------------------------------------------------------------

// IDs of fixed SAI actions (8 most significant bits = 0x01).
# 38 "../../fixed/ids.h"
// --- Copy to CPU session -----------------------------------------------------

// The COPY_TO_CPU_SESSION_ID must be programmed in the target using P4Runtime:
//
// type: INSERT
// entity {
//   packet_replication_engine_entry {
//     clone_session_entry {
//       session_id: COPY_TO_CPU_SESSION_ID
//       replicas { egress_port: 0xfffffffd } # to CPU
//     }
//   }
// }
//


// --- Packet-IO ---------------------------------------------------------------

// Packet-in ingress port field. Indicates which port the packet arrived at.
// Uses @p4runtime_translation(.., string).


// Packet-in target egress port field. Indicates the port a packet would have
// taken if it had not gotten trapped. Uses @p4runtime_translation(.., string).


// Packet-out egress port field. Indicates the egress port for the packet-out to
// be taken. Mutually exclusive with "submit_to_ingress". Uses
// @p4runtime_translation(.., string).


// Packet-out submit_to_ingress field. Indicates that the packet should go
// through the ingress pipeline to determine which port to take (if any).
// Mutually exclusive with "egress_port".


//--- Packet Replication Engine Instances --------------------------------------

// Egress instance type definitions.
// The egress instance is a 32-bit standard metadata set by the packet
// replication engine (PRE) in the V1Model architecture. However, the values are
// not defined by the P4 specification. Here we define our own values; these may
// be changed when we adopt another architecture.
# 6 "../../fixed/metadata.p4" 2
# 1 "../../fixed/headers.p4" 1
# 7 "../../fixed/metadata.p4" 2


// -- Translated Types ---------------------------------------------------------

// BMv2 does not support @p4runtime_translation.


@p4runtime_translation("", string)

type bit<10> nexthop_id_t;


@p4runtime_translation("", string)

type bit<12> wcmp_group_id_t;


@p4runtime_translation("", string)

type bit<10> vrf_id_t;


@p4runtime_translation("", string)

type bit<10> router_interface_id_t;


@p4runtime_translation("", string)

type bit<10> neighbor_id_t;


@p4runtime_translation("", string)

type bit<10> mirror_session_id_t;


@p4runtime_translation("", string)

type bit<8> qos_queue_t;

// -- Meters -------------------------------------------------------------------

enum MeterColor_t { GREEN, YELLOW, RED };

// -- Packet IO headers --------------------------------------------------------

// TODO: extend the P4 program to actually define the semantics of these.

@controller_header("packet_in")
header packet_in_header_t {
  bit<6> _pad;
  // The port the packet ingressed on.
  @id(1)
  port_id_t ingress_port;
  // The initial intended egress port decided for the packet by the pipeline.
  @id(2)
  port_id_t target_egress_port;
}

@controller_header("packet_out")
header packet_out_header_t {
  bit<7> _pad;
  // The port this packet should egress out of when `submit_to_ingress == 0`.
  // Meaningless when `submit_to_ingress == 1`.
  @id(1)
  port_id_t egress_port;
  // Should the packet be submitted to the ingress pipeline instead of being
  // sent directly?
  @id(2)
  bit<1> submit_to_ingress;
  // BMV2 backend requires headers to be multiple of 8-bits.
  @id(3)
  bit<7> unused_pad;

  // original packet ether type
  bit<16> ether_type;

}

// -- Per Packet State ---------------------------------------------------------

struct headers_t {
  // ERSPAN headers, not extracted during parsing.
  ethernet_t erspan_ethernet;
  ipv4_t erspan_ipv4;
  gre_t erspan_gre;

  ethernet_t ethernet;

  cpu_header_t cpu_header;
  packet_in_header_t packet_in;
  packet_out_header_t packet_out;

  ipv4_t ipv4;
  ipv6_t ipv6;
  icmp_t icmp;
  tcp_t tcp;
  udp_t udp;
  arp_t arp;
}

// Header fields rewritten by the ingress pipeline. Rewrites are computed and
// stored in this struct, but actual rewriting is dealyed until the egress
// pipeline so that the original values aren't overridden and get be matched on.
struct packet_rewrites_t {
  ethernet_addr_t src_mac;
  ethernet_addr_t dst_mac;
}

// Local metadata for each packet being processed.
struct local_metadata_t {
  bool admit_to_l3;
  vrf_id_t vrf_id;
  packet_rewrites_t packet_rewrites;
  bit<16> l4_src_port;
  bit<16> l4_dst_port;
  // mirroring data, we can not group the into a struct, because BMv2 does not
  // support passing structs in clone3.
  bool mirror_session_id_valid;
  mirror_session_id_t mirror_session_id_value;
  ipv4_addr_t mirroring_src_ip;
  ipv4_addr_t mirroring_dst_ip;
  ethernet_addr_t mirroring_src_mac;
  ethernet_addr_t mirroring_dst_mac;
  bit<8> mirroring_ttl;
  bit<8> mirroring_tos;

  PSA_MeterColor_t color;




}
# 4 "middleblock.p4" 2
# 1 "../../fixed/parser.p4" 1



# 1 "../../fixed/arch-deps.p4" 1
# 5 "../../fixed/parser.p4" 2

# 1 "../../fixed/metadata.p4" 1
# 7 "../../fixed/parser.p4" 2

parser packet_parser(packet_in packet, out headers_t headers,
                     inout local_metadata_t local_metadata,
                     in psa_ingress_parser_input_metadata_t istd, in empty_metadata_t resub_meta, in empty_metadata_t recirc_meta) {

    InternetChecksum() csum;

  state start {

    // move below to pipeline - not needed in parser?

    // Initialize local metadata fields.
    // TODO: Currently, all packets are admitted to L3 pipeline.
    local_metadata.admit_to_l3 = true;
    // local_metadata.admit_to_l3 = false;
    local_metadata.vrf_id = 0;
    local_metadata.packet_rewrites.src_mac = 0;
    local_metadata.packet_rewrites.dst_mac = 0;
    local_metadata.l4_src_port = 0;
    local_metadata.l4_dst_port = 0;
    local_metadata.mirror_session_id_valid = false;

    local_metadata.color = PSA_MeterColor_t.GREEN;




    transition parse_ethernet;
  }

  state parse_ethernet {
    packet.extract(headers.ethernet);
    transition select(headers.ethernet.ether_type) {
      0x0800: parse_ipv4;
      0x86dd: parse_ipv6;
      0x0806: parse_arp;

      0x9000: parse_packet_out;

      _: accept;
    }
  }


  state parse_packet_out {
    packet.extract(headers.packet_out);
// workaround
//#ifdef TOFINO_1
//   local_metadata.cpu_packet = true;
//#else
   headers.ethernet.ether_type = headers.packet_out.ether_type;
//#endif
//    local_metadata.oport = headers.packet_out.egress_port;
//    istd.egress_port = headers.packet_out.egress_port;
    transition select(headers.packet_out.ether_type) {
      0x0800: parse_ipv4;
      0x86dd: parse_ipv6;
      0x0806: parse_arp;
      _: accept;
    }
  }


  state parse_ipv4 {
    packet.extract(headers.ipv4);

    verify(headers.ipv4.ihl == 5,
             error.UnhandledIPv4Options);

    csum.add({
            /* 16-bit word  0   */ headers.ipv4.version, headers.ipv4.ihl, headers.ipv4.dscp, headers.ipv4.ecn,
            /* 16-bit word  1   */ headers.ipv4.total_len,
            /* 16-bit word  2   */ headers.ipv4.identification,
            /* 16-bit word  3   */ headers.ipv4.reserved, headers.ipv4.do_not_fragment,headers.ipv4.more_fragments, headers.ipv4.frag_offset,
            /* 16-bit word  4   */ headers.ipv4.ttl, headers.ipv4.protocol,
            /* 16-bit word  5 skip headers.ipv4.header_checksum, */
            /* 16-bit words 6-7 */ headers.ipv4.src_addr,
            /* 16-bit words 8-9 */ headers.ipv4.dst_addr
            });
        // The verify statement below will cause the parser to enter
        // the reject state, and thus terminate parsing immediately,
        // if the IPv4 header checksum is wrong.  It will also record
        // the error parser_error.BadIPv4HeaderChecksum, which will be
        // available in a metadata field in the ingress control block.
        verify(csum.get() == headers.ipv4.header_checksum,
               error.BadIPv4HeaderChecksum);

    transition select(headers.ipv4.protocol) {
      0x01: parse_icmp;
      0x06: parse_tcp;
      0x11: parse_udp;
      _: accept;
    }
  }

  state parse_ipv6 {
    packet.extract(headers.ipv6);
    transition select(headers.ipv6.next_header) {
      0x3a: parse_icmp;
      0x06: parse_tcp;
      0x11: parse_udp;
      _: accept;
    }
  }

  state parse_tcp {
    packet.extract(headers.tcp);
    // Normalize TCP port metadata to common port metadata.
    local_metadata.l4_src_port = headers.tcp.src_port;
    local_metadata.l4_dst_port = headers.tcp.dst_port;
    transition accept;
  }

  state parse_udp {
    packet.extract(headers.udp);
    // Normalize UDP port metadata to common port metadata.
    local_metadata.l4_src_port = headers.udp.src_port;
    local_metadata.l4_dst_port = headers.udp.dst_port;
    transition accept;
  }

  state parse_icmp {
    packet.extract(headers.icmp);
    transition accept;
  }

  state parse_arp {
    packet.extract(headers.arp);
    transition accept;
  }
} // parser packet_parser

control packet_deparser(packet_out packet, out empty_metadata_t clone_i2e_meta, out empty_metadata_t resubmit_meta, out empty_metadata_t normal_meta, inout headers_t headers, in local_metadata_t local_metadata, in psa_ingress_output_metadata_t istd) {

    InternetChecksum() csum;

 apply {

    csum.add({
            /* 16-bit word  0   */ headers.ipv4.version, headers.ipv4.ihl, headers.ipv4.dscp, headers.ipv4.ecn,
            /* 16-bit word  1   */ headers.ipv4.total_len,
            /* 16-bit word  2   */ headers.ipv4.identification,
            /* 16-bit word  3   */ headers.ipv4.reserved, headers.ipv4.do_not_fragment,headers.ipv4.more_fragments, headers.ipv4.frag_offset,
            /* 16-bit word  4   */ headers.ipv4.ttl, headers.ipv4.protocol,
            /* 16-bit word  5 skip headers.ipv4.header_checksum, */
            /* 16-bit words 6-7 */ headers.ipv4.src_addr,
            /* 16-bit words 8-9 */ headers.ipv4.dst_addr
            });

    packet.emit(headers.erspan_ethernet);
    packet.emit(headers.erspan_ipv4);
    packet.emit(headers.erspan_gre);
    packet.emit(headers.ethernet);

    packet.emit(headers.packet_in);

    packet.emit(headers.ipv4);
    packet.emit(headers.ipv6);
    packet.emit(headers.arp);
    packet.emit(headers.icmp);
    packet.emit(headers.tcp);
    packet.emit(headers.udp);
  }
} // control packet_deparser
# 5 "middleblock.p4" 2
# 1 "../../fixed/routing.p4" 1
# 10 "../../fixed/routing.p4"
// This control block models the L3 routing pipeline.
//
// +-------+   +-------+ wcmp  +---------+       +-----------+
// |  lpm  |-->| group |------>| nexthop |----+->| router    |--> egress_port
// |       |   |       |------>|         |-+  |  | interface |--> src_mac
// +-------+   +-------+       +---------+ |  |  +-----------+
//   |   |                         ^       |  |  +-----------+
//   |   |                         |       |  +->| neighbor  |
//   V   +-------------------------+       +---->|           |--> dst_mac
//  drop                                         +-----------+
//
// The pipeline first performs a longest prefix match on the packet's
// destination IP address. The action associated with the match then either
// drops the packet, points to a nexthop, or points to a wcmp group which uses a
// hash of the packet to choose from a set of nexthops. The nexthop points to a
// router interface, which determines the packet's src_mac and the egress_port
// to forward the packet to. The nexthop also points to a neighbor which,
// together with the router_interface, determines the packet's dst_mac.
//
// Note that this block does not rewrite any header fields directly, but only
// records rewrites in `local_metadata.packet_rewrites`, from where they will be
// read and applied in the egress stage.
control routing(in headers_t headers,
                inout local_metadata_t local_metadata,
                in psa_ingress_input_metadata_t istd, inout psa_ingress_output_metadata_t ostd) {
  // Wcmp group id, only valid if `wcmp_group_id_valid` is true.
  bool wcmp_group_id_valid = false;
  wcmp_group_id_t wcmp_group_id_value;

  // Nexthop id, only valid if `nexthop_id_valid` is true.
  bool nexthop_id_valid = false;
  nexthop_id_t nexthop_id_value;

  // Router interface id, only valid if `router_interface_id_valid` is true.
  bool router_interface_id_valid = false;
  router_interface_id_t router_interface_id_value;

  // Neighbor id, only valid if `neighbor_id_valid` is true.
  bool neighbor_id_valid = false;
  neighbor_id_t neighbor_id_value;

  const bit<1> HASH_BASE_CRC16 = 1w0;
  const bit<14> HASH_MAX_CRC16 = 14w1024;


  Hash<bit<16>>(PSA_HashAlgorithm_t.CRC16) hash_v4;
  Hash<bit<16>>(PSA_HashAlgorithm_t.CRC16) hash_v6;

  bit<10> wcmp_selector_input = 0;
  // Sets SAI_NEIGHBOR_ENTRY_ATTR_DST_MAC_ADDRESS.
  @id(0x01000001)
  action set_dst_mac(@id(1) @format(MAC_ADDRESS) ethernet_addr_t dst_mac) {
    local_metadata.packet_rewrites.dst_mac = dst_mac;
  }

  @proto_package("sai")
  @id(0x02000040)
  table neighbor_table {
    key = {
      // Sets rif_id in sai_neighbor_entry_t. Can only refer to values that are
      // already programmed in the `router_interface_table`.
      router_interface_id_value : exact @id(1) @name("router_interface_id")
          @refers_to(router_interface_table, router_interface_id);
      // Sets ip_address in sai_neighbor_entry_t.
      neighbor_id_value : exact @id(2) @name("neighbor_id");
    }
    actions = {
      @proto_id(1) set_dst_mac;
      @defaultonly NoAction;
    }
    const default_action = NoAction;
    size = 1024;
  }

  // Sets SAI_ROUTER_INTERFACE_ATTR_TYPE to SAI_ROUTER_INTERFACE_TYPE_PORT, and
  // SAI_ROUTER_INTERFACE_ATTR_PORT_ID, and
  // SAI_ROUTER_INTERFACE_ATTR_SRC_MAC_ADDRESS.
  @id(0x01000002)
  action set_port_and_src_mac(@id(1) port_id_t port,
                              @id(2) @format(MAC_ADDRESS)
                              ethernet_addr_t src_mac) {
    // Cast is necessary, because v1model does not define port using `type`.

    ostd.egress_port = (PortId_t)port;



    local_metadata.packet_rewrites.src_mac = src_mac;
  }

  @proto_package("sai")
  @id(0x02000041)
  table router_interface_table {
    key = {
      router_interface_id_value : exact @id(1)
                                        @name("router_interface_id");
    }
    actions = {
      @proto_id(1) set_port_and_src_mac;
      @defaultonly NoAction;
    }
    const default_action = NoAction;
    size = 1024;
  }

  // Sets SAI_NEXT_HOP_ATTR_TYPE to SAI_NEXT_HOP_TYPE_IP, and
  // SAI_NEXT_HOP_ATTR_ROUTER_INTERFACE_ID, and SAI_NEXT_HOP_ATTR_IP.
  //
  // This action can only refer to `router_interface_id`s and `neighbor_id`s,
  // if `router_interface_id` is a key in the `router_interface_table`, and
  // the `(router_interface_id, neighbor_id)` pair is a key in the
  // `neighbor_table`.
  //
  // Note that the @refers_to annotation could be more precise if it allowed
  // specifying that the pair (router_interface_id, neighbor_id) refers to the
  // two match fields in neighbor_table. This is still correct, but less
  // precise.
  @id(0x01000003)
  action set_nexthop(@id(1)
                     @refers_to(router_interface_table, router_interface_id)
                     @refers_to(neighbor_table, router_interface_id)
                     router_interface_id_t router_interface_id,
                     @id(2) @refers_to(neighbor_table, neighbor_id)
                     neighbor_id_t neighbor_id) {
    router_interface_id_valid = true;
    router_interface_id_value = router_interface_id;
    neighbor_id_valid = true;
    neighbor_id_value = neighbor_id;
  }

  @proto_package("sai")
  @id(0x02000042)
  table nexthop_table {
    key = {
      nexthop_id_value : exact @id(1) @name("nexthop_id");
    }
    actions = {
      @proto_id(1) set_nexthop;
      @defaultonly NoAction;
    }
    const default_action = NoAction;
    size = 1024;
  }

  // When called from a route, sets SAI_ROUTE_ENTRY_ATTR_PACKET_ACTION to
  // SAI_PACKET_ACTION_FORWARD, and SAI_ROUTE_ENTRY_ATTR_NEXT_HOP_ID to a
  // SAI_OBJECT_TYPE_NEXT_HOP.
  //
  // When called from a group, sets SAI_NEXT_HOP_GROUP_MEMBER_ATTR_NEXT_HOP_ID.
  // When called from a group, sets SAI_NEXT_HOP_GROUP_MEMBER_ATTR_WEIGHT.
  //
  // This action can only refer to `nexthop_id`s that are programmed in the
  // `nexthop_table`.
  @id(0x01000005)
  action set_nexthop_id(@id(1) @refers_to(nexthop_table, nexthop_id)
                        nexthop_id_t nexthop_id) {
    nexthop_id_valid = true;
    nexthop_id_value = nexthop_id;
  }


  ActionSelector(PSA_HashAlgorithm_t.IDENTITY,
                  65536,
                  10)
      wcmp_group_selector;
# 186 "../../fixed/routing.p4"
  @proto_package("sai")
  @id(0x02000043)
  @oneshot()
  table wcmp_group_table {
    key = {
      wcmp_group_id_value : exact @id(1) @name("wcmp_group_id");
      wcmp_selector_input : selector;
    }
    actions = {
      @proto_id(1) set_nexthop_id;
      @defaultonly NoAction;
    }
    const default_action = NoAction;

    psa_implementation = wcmp_group_selector;



    size = 4096;
  }

  // Sets SAI_ROUTE_ENTRY_ATTR_PACKET_ACTION to SAI_PACKET_ACTION_DROP.
  @id(0x01000006)
  action drop() {
    ingress_drop(ostd);
  }

  // Sets SAI_ROUTE_ENTRY_ATTR_PACKET_ACTION to SAI_PACKET_ACTION_FORWARD, and
  // SAI_ROUTE_ENTRY_ATTR_NEXT_HOP_ID to a SAI_OBJECT_TYPE_NEXT_HOP_GROUP.
  //
  // This action can only refer to `wcmp_group_id`s that are programmed in the
  // `wcmp_group_table`.
  @id(0x01000004)
  action set_wcmp_group_id(@id(1) @refers_to(wcmp_group_table, wcmp_group_id)
                           wcmp_group_id_t wcmp_group_id) {
    wcmp_group_id_valid = true;
    wcmp_group_id_value = wcmp_group_id;
  }

  @proto_package("sai")
  @id(0x02000044)
  table ipv4_table {
    key = {
      // Sets vr_id in sai_route_entry_t.
      local_metadata.vrf_id : exact @id(1) @name("vrf_id");
      // Sets destination in sai_route_entry_t to an IPv4 prefix.
      headers.ipv4.dst_addr : lpm @format(IPV4_ADDRESS) @id(2)
                                  @name("ipv4_dst");
    }
    actions = {
      @proto_id(1) drop;
      @proto_id(2) set_nexthop_id;
      @proto_id(3) set_wcmp_group_id;
    }
    const default_action = drop;
  }

  @proto_package("sai")
  @id(0x02000045)
  table ipv6_table {
    key = {
      // Sets vr_id in sai_route_entry_t.
      local_metadata.vrf_id : exact @id(1) @name("vrf_id");
      // Sets destination in sai_route_entry_t to an IPv6 prefix.
      headers.ipv6.dst_addr : lpm @format(IPV6_ADDRESS) @id(2)
                                  @name("ipv6_dst");
    }
    actions = {
      @proto_id(1) drop;
      @proto_id(2) set_nexthop_id;
      @proto_id(3) set_wcmp_group_id;
    }
    const default_action = drop;
  }

  apply {
    if (local_metadata.admit_to_l3) {
      if (headers.ipv4.isValid()) {

        wcmp_selector_input = (bit<10>)hash_v4.get_hash({
             headers.ipv4.dst_addr, headers.ipv4.src_addr,
             local_metadata.l4_src_port, local_metadata.l4_dst_port});






        ipv4_table.apply();
      } else if (headers.ipv6.isValid()) {

        wcmp_selector_input = (bit<10>)hash_v6.get_hash({
             headers.ipv6.dst_addr, headers.ipv6.src_addr,
             headers.ipv6.flow_label[15:0], local_metadata.l4_src_port,
             local_metadata.l4_dst_port});






        ipv6_table.apply();
      }

      // The lpm tables may not set a valid `wcmp_group_id`, e.g. they may drop.
      if (wcmp_group_id_valid) {
        wcmp_group_table.apply();
      }

      // The lpm tables may not set a valid `nexthop_id`, e.g. they may drop.
      // The `wcmp_group_table` should always set a valid `nexthop_id`.
      if (nexthop_id_valid) {
        nexthop_table.apply();

        // The `nexthop_table` should always set a valid
        // `router_interface_id` and `neighbor_id`.
        if (router_interface_id_valid && neighbor_id_valid) {
          router_interface_table.apply();
          neighbor_table.apply();
        }
      }
    }
  }
} // control routing
# 6 "middleblock.p4" 2



# 1 "../../fixed/mirroring_encap.p4" 1
# 10 "../../fixed/mirroring_encap.p4"
control mirroring_encap(inout headers_t headers,
                        inout local_metadata_t local_metadata,
                        in psa_egress_input_metadata_t istd, inout psa_egress_output_metadata_t ostd) {
  apply {

    if (istd.packet_path == PSA_PacketPath_t.CLONE_I2E)



    {
      // Reference for ERSPAN Type II header construction
      // https://tools.ietf.org/html/draft-foschiano-erspan-00
      headers.erspan_ethernet.setValid();
      headers.erspan_ethernet.src_addr = local_metadata.mirroring_src_mac;
      headers.erspan_ethernet.dst_addr = local_metadata.mirroring_dst_mac;
      headers.erspan_ethernet.ether_type = 0x0800;

      headers.erspan_ipv4.setValid();
      headers.erspan_ipv4.src_addr = local_metadata.mirroring_src_ip;
      headers.erspan_ipv4.dst_addr = local_metadata.mirroring_dst_ip;
      headers.erspan_ipv4.version = 4w4;
      headers.erspan_ipv4.ihl = 4w5;
      headers.erspan_ipv4.protocol = 0x2f;
      headers.erspan_ipv4.ttl = local_metadata.mirroring_ttl;
      headers.erspan_ipv4.dscp = local_metadata.mirroring_tos[7:2];
      headers.erspan_ipv4.ecn = local_metadata.mirroring_tos[1:0];

      headers.erspan_ipv4.total_len = 20 + 4;




      headers.erspan_ipv4.identification = 0;
      headers.erspan_ipv4.reserved = 0;
      headers.erspan_ipv4.do_not_fragment = 1;
      headers.erspan_ipv4.more_fragments = 0;
      headers.erspan_ipv4.frag_offset = 0;
      headers.erspan_ipv4.header_checksum = 0;

      headers.erspan_gre.setValid();
      headers.erspan_gre.checksum_present = 0;
      headers.erspan_gre.routing_present = 0;
      headers.erspan_gre.key_present = 0;
      headers.erspan_gre.sequence_present = 0;
      headers.erspan_gre.strict_source_route = 0;
      headers.erspan_gre.recursion_control = 0;
      headers.erspan_gre.acknowledgement_present = 0;
      headers.erspan_gre.flags = 0;
      headers.erspan_gre.version = 0;
      headers.erspan_gre.protocol = 0x88be;
    }
  }
} // control mirroring_encap
# 10 "middleblock.p4" 2
# 1 "../../fixed/mirroring_clone.p4" 1
# 10 "../../fixed/mirroring_clone.p4"
control mirroring_clone(inout headers_t headers,
                        inout local_metadata_t local_metadata) {
  port_id_t mirror_port;
  bit<32> pre_session;

  @sai_attr_action_key_value(SAI_MIRROR_SESSION_ATTR_TYPE ENHANCED_REMOTE)
  @sai_attr_action_key_value(SAI_MIRROR_SESSION_ATTR_ERSPAN_ENCAPSULATION_TYPE L3_GRE_TUNNEL)
  @sai_attr_action_key_value(SAI_MIRROR_SESSION_ATTR_IPHDR_VERSION 4)
  @sai_attr_action_key_value(SAI_MIRROR_SESSION_ATTR_GRE_PROTOCOL_TYPE 0x88BE)
  @proto_package("sai")
  @id(0x01000007)
  action mirror_as_ipv4_erspan(
      @id(1) @sai_attr_key(SAI_MIRROR_SESSION_ATTR_MONITOR_PORT) port_id_t port,
      @id(2) @format(IPV4_ADDRESS) @sai_attr_key(SAI_MIRROR_SESSION_ATTR_SRC_IP_ADDRESS) ipv4_addr_t src_ip,
      @id(3) @format(IPV4_ADDRESS) @sai_attr_key(SAI_MIRROR_SESSION_ATTR_DST_IP_ADDRESS) ipv4_addr_t dst_ip,
      @id(4) @format(MAC_ADDRESS) @sai_attr_key(SAI_MIRROR_SESSION_ATTR_SRC_MAC_ADDRESS) ethernet_addr_t src_mac,
      @id(5) @format(MAC_ADDRESS) @sai_attr_key(SAI_MIRROR_SESSION_ATTR_DST_MAC_ADDRESS) ethernet_addr_t dst_mac,
      @id(6) @sai_attr_key(SAI_MIRROR_SESSION_ATTR_TTL) bit<8> ttl,
      @id(7) @sai_attr_key(SAI_MIRROR_SESSION_ATTR_TOS) bit<8> tos) {
    mirror_port = port;
    local_metadata.mirroring_src_ip = src_ip;
    local_metadata.mirroring_dst_ip = dst_ip;
    local_metadata.mirroring_src_mac = src_mac;
    local_metadata.mirroring_dst_mac = dst_mac;
    local_metadata.mirroring_ttl = ttl;
    local_metadata.mirroring_tos = tos;
  }

  @proto_package("sai")
  @id(0x02000046)
  table mirror_session_table {
    key = {
      local_metadata.mirror_session_id_value : exact @id(1)
                                                     @name("mirror_session_id");
    }
    actions = {
      @proto_id(1) mirror_as_ipv4_erspan;
      @defaultonly NoAction;
    }
    const default_action = NoAction;
    size = 1024;
  }

  @proto_package("sai")
  @id(0x01000009)
  action set_pre_session(bit<32> id) {
    pre_session = id;
  }

  @proto_package("sai")
  @id(0x02000048)
  table mirror_port_to_pre_session_table {
    key = {
      mirror_port : exact @id(1);
    }
    actions = {
      @proto_id(1) set_pre_session;
      @defaultonly NoAction;
    }
    const default_action = NoAction;
  }

  apply {
    if (local_metadata.mirror_session_id_valid) {
      // Map mirror session id to mirroring data.
      if (mirror_session_table.apply().hit) {
        // Map mirror port to Packet Replication Engine session.
        if (mirror_port_to_pre_session_table.apply().hit) {
# 88 "../../fixed/mirroring_clone.p4"
        }
      }
    }
  }
} // control mirroring_clone
# 11 "middleblock.p4" 2
# 1 "../../fixed/l3_admit.p4" 1
# 11 "../../fixed/l3_admit.p4"
control l3_admit(in headers_t headers,
                 inout local_metadata_t local_metadata,
                 in psa_ingress_input_metadata_t istd, inout psa_ingress_output_metadata_t ostd) {
  @id(0x01000008)
  action admit_to_l3() {
    local_metadata.admit_to_l3 = true;
  }

  @proto_package("sai")
  @id(0x02000047)
  table l3_admit_table {
    key = {
      headers.ethernet.dst_addr : ternary @name("dst_mac") @id(1)
                                          @format(MAC_ADDRESS);

      istd.ingress_port : ternary @optional @name("in_port") @id(2);



    }
    actions = {
      @proto_id(1) admit_to_l3;
      @defaultonly NoAction;
    }
    const default_action = NoAction;
    size = 512;
  }

  apply {
    l3_admit_table.apply();
  }
} // control l3_admit
# 12 "middleblock.p4" 2
# 1 "../../fixed/ttl.p4" 1







control ttl(inout headers_t headers,
                  inout local_metadata_t local_metadata,
                  in psa_ingress_input_metadata_t istd, inout psa_ingress_output_metadata_t ostd) {
  apply {
    if (local_metadata.admit_to_l3) {
      if (headers.ipv4.isValid()) {
        if (headers.ipv4.ttl <= 1) {
          ingress_drop(ostd);
        } else {
          headers.ipv4.ttl = headers.ipv4.ttl - 1;
        }
      }

      if (headers.ipv6.isValid()) {
        if (headers.ipv6.hop_limit <= 1) {
          ingress_drop(ostd);
        } else {
          headers.ipv6.hop_limit = headers.ipv6.hop_limit - 1;
        }
      }
    }
  }
} // control ttl
# 13 "middleblock.p4" 2
# 1 "../../fixed/packet_rewrites.p4" 1
# 9 "../../fixed/packet_rewrites.p4"
// This control block applies the rewrites computed during the the ingress
// stage to the actual packet.
control packet_rewrites(inout headers_t headers,
                        in local_metadata_t local_metadata) {
  apply {
    if (local_metadata.admit_to_l3) {
      headers.ethernet.src_addr = local_metadata.packet_rewrites.src_mac;
      headers.ethernet.dst_addr = local_metadata.packet_rewrites.dst_mac;
    }
  }
} // control packet_rewrites
# 14 "middleblock.p4" 2
# 1 "acl_ingress.p4" 1






# 1 "ids.h" 1



# 1 "../../fixed/ids.h" 1
# 5 "ids.h" 2

// All declarations (tables, actions, action profiles, meters, counters) have a
// stable ID. This list will evolve as new declarations are added. IDs cannot be
// reused. If a declaration is removed, its ID macro is kept and marked reserved
// to avoid the ID being reused.
//
// The IDs are classified using the 8 most significant bits to be compatible
// with "6.3. ID Allocation for P4Info Objects" in the P4Runtime specification.

// --- Tables ------------------------------------------------------------------

// IDs of ACL tables (8 most significant bits = 0x02).
// Since these IDs are user defined, they need to be separate from the fixed SAI
// table ID space. We achieve this by starting the IDs at 0x100.




// --- Actions -----------------------------------------------------------------

// IDs of ACL actions (8 most significant bits = 0x01).
// Since these IDs are user defined, they need to be separate from the fixed SAI
// actions ID space. We achieve this by starting the IDs at 0x100.
# 36 "ids.h"
// --- Meters ------------------------------------------------------------------


// --- Counters ----------------------------------------------------------------
# 8 "acl_ingress.p4" 2
# 1 "resource_limits.p4" 1



// -- Table sizes --------------------------------------------------------------




// Maximum channelization for current use-cases is 96 ports, and each port may
// have up to 2 linkqual flows associated with it.
# 9 "acl_ingress.p4" 2

control acl_ingress(in headers_t headers,
                    inout local_metadata_t local_metadata,
                    in psa_ingress_input_metadata_t istd, inout psa_ingress_output_metadata_t ostd) {
  // IPv4 TTL or IPv6 hoplimit bits (or 0, for non-IP packets)
  bit<8> packet_ttl = 0;
  // First 6 bits of IPv4 TOS or IPv6 traffic class (or 0, for non-IP packets)
  bit<6> dscp = 0;
  // Last 2 bits of IPv4 TOS or IPv6 traffic class (or 0, for non-IP packets)
  bit<2> ecn = 0;
  // IPv4 IP protocol or IPv6 next_header (or 0, for non-IP packets)
  bit<8> ip_protocol = 0;

  @id(0x15000100)

  DirectMeter(PSA_MeterType_t.BYTES) acl_ingress_meter;




  @id(0x13000102)

  DirectCounter<bit<32>>(PSA_CounterType_t.PACKETS_AND_BYTES) acl_ingress_counter;




  // Copy the packet to the CPU, and forward the original packet.
  @id(0x01000101)
  @sai_action(SAI_PACKET_ACTION_COPY)
  action copy(@sai_action_param(QOS_QUEUE) @id(1) qos_queue_t qos_queue) {
    ostd.clone_session_id = (CloneSessionId_t)1024; ostd.clone = true;
    acl_ingress_counter.count();
    local_metadata.color = acl_ingress_meter.execute();
  }

  // Copy the packet to the CPU. The original packet is dropped.
  @id(0x01000102)
  @sai_action(SAI_PACKET_ACTION_TRAP)
  action trap(@sai_action_param(QOS_QUEUE) @id(1) qos_queue_t qos_queue) {
    copy(qos_queue);
    ingress_drop(ostd);
    // acl_ingress_counter.count();
  }

  // Forward the packet normally (i.e., perform no action). This is useful as
  // the default action, and to specify a meter but not otherwise perform any
  // action.
  @id(0x01000103)
  @sai_action(SAI_PACKET_ACTION_FORWARD)
  action forward() {

    local_metadata.color = acl_ingress_meter.execute();



    acl_ingress_counter.count();
  }

  @id(0x01000104)
  @sai_action(SAI_PACKET_ACTION_FORWARD)
  action mirror(@sai_action_param(SAI_ACL_ENTRY_ATTR_ACTION_MIRROR_INGRESS)
                @id(1) @refers_to(mirror_session_table, mirror_session_id)
                mirror_session_id_t mirror_session_id) {
    local_metadata.mirror_session_id_valid = true;
    local_metadata.mirror_session_id_value = mirror_session_id;
    acl_ingress_counter.count();
    local_metadata.color = acl_ingress_meter.execute();
  }

  @proto_package("sai")
  @id(0x02000100)
  @sai_acl(INGRESS)
  @entry_restriction("
    // Only allow IP field matches for IP packets.
    dst_ip::mask != 0 -> is_ipv4 == 1;
    dst_ipv6::mask != 0 -> is_ipv6 == 1;
    packet_ttl::mask != 0 -> (is_ip == 1 || is_ipv4 == 1 || is_ipv6 == 1);
    dscp::mask != 0 -> (is_ip == 1 || is_ipv4 == 1 || is_ipv6 == 1);
    ecn::mask != 0 -> (is_ip == 1 || is_ipv4 == 1 || is_ipv6 == 1);
    ip_protocol::mask != 0 -> (is_ip == 1 || is_ipv4 == 1 || is_ipv6 == 1);
    // Forbit using ether_type for IP packets (by convention, use is_ip* instead).
    ether_type != 0x0800 && ether_type != 0x86dd;
    // Only allow arp_tpa for ARP packets
    arp_tpa::mask != 0 -> ether_type == 0x0806;
    // Only allow icmp_type for ICMP packets
    icmp_type::mask != 0 -> ((is_ip == 1 || is_ipv4 == 1 || is_ipv6 == 1) && ip_protocol == 58);
    // Forbid illegal combinations of IP_TYPE fields.
    is_ip::mask != 0 -> (is_ipv4::mask == 0 && is_ipv6::mask == 0);
    is_ipv4::mask != 0 -> (is_ip::mask == 0 && is_ipv6::mask == 0);
    is_ipv6::mask != 0 -> (is_ip::mask == 0 && is_ipv4::mask == 0);
    // Forbid unsupported combinations of IP_TYPE fields.
    is_ipv4::mask != 0 -> (is_ipv4 == 1);
    is_ipv6::mask != 0 -> (is_ipv6 == 1);
  ")
  table acl_ingress_table {
    key = {

      // headers.ipv4.isValid() || headers.ipv6.isValid() : ternary @optional @name("is_ip") @id(1)
      //    @sai_field(SAI_ACL_TABLE_ATTR_FIELD_ACL_IP_TYPE/IP);
      headers.ipv4.isValid() : ternary @optional @name("is_ipv4") @id(2)
          @sai_field(SAI_ACL_TABLE_ATTR_FIELD_ACL_IP_TYPE/IPV4ANY);
      headers.ipv6.isValid() : ternary @optional @name("is_ipv6") @id(3)
          @sai_field(SAI_ACL_TABLE_ATTR_FIELD_ACL_IP_TYPE/IPV6ANY);
# 119 "acl_ingress.p4"
      headers.ethernet.ether_type : ternary @name("ether_type") @id(4)
          @sai_field(SAI_ACL_TABLE_ATTR_FIELD_ETHER_TYPE);
      headers.ethernet.dst_addr : ternary @name("dst_mac") @id(5)
          @sai_field(SAI_ACL_TABLE_ATTR_FIELD_DST_MAC) @format(MAC_ADDRESS);
      headers.ipv4.src_addr : ternary @name("src_ip") @id(6)
          @sai_field(SAI_ACL_TABLE_ATTR_FIELD_SRC_IP) @format(IPV4_ADDRESS);
      headers.ipv4.dst_addr : ternary @name("dst_ip") @id(7)
          @sai_field(SAI_ACL_TABLE_ATTR_FIELD_DST_IP) @format(IPV4_ADDRESS);
      headers.ipv6.src_addr : ternary @name("src_ipv6") @id(8)
          @sai_field(SAI_ACL_TABLE_ATTR_FIELD_SRC_IPV6) @format(IPV6_ADDRESS);
      headers.ipv6.dst_addr : ternary @name("dst_ipv6") @id(9)
          @sai_field(SAI_ACL_TABLE_ATTR_FIELD_DST_IPV6) @format(IPV6_ADDRESS);
      // Field for v4 TTL and v6 hop_limit
      packet_ttl : ternary @name("ttl") @id(10)
          @sai_field(SAI_ACL_TABLE_ATTR_FIELD_TTL);
      // Field for v4 and v6 DSCP bits.
      dscp : ternary @name("dscp") @id(11)
          @sai_field(SAI_ACL_TABLE_ATTR_FIELD_DSCP);
      // Field for v4 and v6 ECN bits.
      ecn : ternary @name("ecn") @id(12)
          @sai_field(SAI_ACL_TABLE_ATTR_FIELD_ECN);
      // Field for v4 IP protocol and v6 next header.
      ip_protocol : ternary @name("ip_protocol") @id(13)
          @sai_field(SAI_ACL_TABLE_ATTR_FIELD_IP_PROTOCOL);
      headers.icmp.type : ternary @name("icmpv6_type") @id(14)
          @sai_field(SAI_ACL_TABLE_ATTR_FIELD_ICMPV6_TYPE);
      local_metadata.l4_dst_port : ternary @name("l4_dst_port") @id(15)
          @sai_field(SAI_ACL_TABLE_ATTR_FIELD_L4_DST_PORT);
      headers.arp.target_proto_addr : ternary @name("arp_tpa") @id(16)
          @composite_field(
              @sai_udf(base=SAI_UDF_BASE_L3, offset=24, length=2),
              @sai_udf(base=SAI_UDF_BASE_L3, offset=26, length=2)
          ) @format(IPV4_ADDRESS);
    }
    actions = {
      // TODO: add action to set color to yellow
      @proto_id(1) copy();
      @proto_id(2) trap();
      @proto_id(3) forward();
      @proto_id(4) mirror();
      @defaultonly NoAction;
    }
    const default_action = NoAction;

    psa_direct_meter = acl_ingress_meter;
    psa_direct_counter = acl_ingress_counter;




    size = 128;
  }

  apply {
    if (headers.ipv4.isValid()) {
      packet_ttl = headers.ipv4.ttl;
      dscp = headers.ipv4.dscp;
      ecn = headers.ipv4.ecn;
      ip_protocol = headers.ipv4.protocol;
    } else if (headers.ipv6.isValid()) {
      packet_ttl = headers.ipv6.hop_limit;
      dscp = headers.ipv6.dscp;
      ecn = headers.ipv6.ecn;
      ip_protocol = headers.ipv6.next_header;
    }

    acl_ingress_table.apply();
  }
} // control ACL_INGRESS
# 15 "middleblock.p4" 2
# 1 "acl_lookup.p4" 1
# 10 "acl_lookup.p4"
control acl_lookup(in headers_t headers,
                   inout local_metadata_t local_metadata,
                    in psa_ingress_input_metadata_t istd, inout psa_ingress_output_metadata_t ostd) {
  // First 6 bits of IPv4 TOS or IPv6 traffic class (or 0, for non-IP packets)
  bit<6> dscp = 0;

  @id(0x13000101)

  DirectCounter<bit<32>>(PSA_CounterType_t.PACKETS_AND_BYTES) acl_lookup_counter;




  @id(0x01000100)
  @sai_action(SAI_PACKET_ACTION_FORWARD)
  action set_vrf(@sai_action_param(SAI_ACL_ENTRY_ATTR_EXTENSIONS_ACTION_SET_VRF)
                 @id(1) vrf_id_t vrf_id) {
    local_metadata.vrf_id = vrf_id;
    acl_lookup_counter.count();
  }

  @proto_package("sai")
  @id(0x02000101)
  @sai_acl(LOOKUP)
  @entry_restriction("
    // Only allow IP field matches for IP packets.
    dscp::mask != 0 -> (is_ip == 1 || is_ipv4 == 1 || is_ipv6 == 1);
    dst_ip::mask != 0 -> is_ipv4 == 1;
    dst_ipv6::mask != 0 -> is_ipv6 == 1;
    // Forbid illegal combinations of IP_TYPE fields.
    is_ip::mask != 0 -> (is_ipv4::mask == 0 && is_ipv6::mask == 0);
    is_ipv4::mask != 0 -> (is_ip::mask == 0 && is_ipv6::mask == 0);
    is_ipv6::mask != 0 -> (is_ip::mask == 0 && is_ipv4::mask == 0);
    // Forbid unsupported combinations of IP_TYPE fields.
    is_ipv4::mask != 0 -> (is_ipv4 == 1);
    is_ipv6::mask != 0 -> (is_ipv6 == 1);
  ")
  table acl_lookup_table {
    key = {

      // headers.ipv4.isValid() || headers.ipv6.isValid() : ternary @optional @name("is_ip") @id(1)
      //     @sai_field(SAI_ACL_TABLE_ATTR_FIELD_ACL_IP_TYPE/IP);
      headers.ipv4.isValid() : ternary @optional @name("is_ipv4") @id(2)
          @sai_field(SAI_ACL_TABLE_ATTR_FIELD_ACL_IP_TYPE/IPV4ANY);
      headers.ipv6.isValid() : ternary @optional @name("is_ipv6") @id(3)
          @sai_field(SAI_ACL_TABLE_ATTR_FIELD_ACL_IP_TYPE/IPV6ANY);
# 64 "acl_lookup.p4"
      headers.ethernet.src_addr : ternary @name("src_mac") @id(4)
          @sai_field(SAI_ACL_TABLE_ATTR_FIELD_SRC_MAC) @format(MAC_ADDRESS);
      headers.ipv4.dst_addr : ternary @name("dst_ip") @id(5)
          @sai_field(SAI_ACL_TABLE_ATTR_FIELD_DST_IP) @format(IPV4_ADDRESS);
      headers.ipv6.dst_addr : ternary @name("dst_ipv6") @id(6)
          @sai_field(SAI_ACL_TABLE_ATTR_FIELD_DST_IPV6) @format(IPV6_ADDRESS);
      dscp : ternary @name("dscp") @id(7)
          @sai_field(SAI_ACL_TABLE_ATTR_FIELD_DSCP);

      istd.ingress_port : ternary @optional @name("in_port") @id(8)
          @sai_field(SAI_ACL_TABLE_ATTR_FIELD_IN_PORT);




    }
    actions = {
      @proto_id(1) set_vrf;
      @defaultonly NoAction;
    }
    const default_action = NoAction;

    psa_direct_counter = acl_lookup_counter;



    size = 256;
  }

  apply {
    if (headers.ipv4.isValid()) {
      dscp = headers.ipv4.dscp;
    } else if (headers.ipv6.isValid()) {
      dscp = headers.ipv6.dscp;
    }

    acl_lookup_table.apply();
  }
} // control acl_lookup
# 16 "middleblock.p4" 2
# 1 "acl_linkqual.p4" 1
# 10 "acl_linkqual.p4"
control acl_linkqual(in headers_t headers,
                     inout local_metadata_t local_metadata,
                     in psa_ingress_input_metadata_t istd, inout psa_ingress_output_metadata_t ostd) {

  @id(0x13000100)

  DirectCounter<bit<32>>(PSA_CounterType_t.PACKETS_AND_BYTES) linkqual_counter;




  @id(0x01000105)
  @sai_action(SAI_PACKET_ACTION_DROP)
  action linkqual_drop() {
    ingress_drop(ostd);
    linkqual_counter.count();
  }

  @id(0x01000106)
  @sai_action(SAI_PACKET_ACTION_FORWARD)
  action linkqual_set_port(@sai_action_param(SAI_ACL_ENTRY_ATTR_ACTION_REDIRECT)
                           @id(1) port_id_t port) {

    ostd.egress_port = (PortId_t)port;




    linkqual_counter.count();
  }

  @proto_package("sai")
  @id(0x02000102)
  @sai_acl(INGRESS)
  table acl_linkqual_table {
    key = {
      headers.ethernet.ether_type : ternary @name("ether_type") @id(1)
          @sai_field(SAI_ACL_TABLE_ATTR_FIELD_ETHER_TYPE);
      headers.ethernet.dst_addr : ternary @name("dst_mac") @id(2)
          @sai_field(SAI_ACL_TABLE_ATTR_FIELD_DST_MAC) @format(MAC_ADDRESS);

      istd.ingress_port : ternary @optional @name("in_port") @id(3)
          @sai_field(SAI_ACL_TABLE_ATTR_FIELD_IN_PORT);




    }
    actions = {
      @proto_id(1) linkqual_drop();
      @proto_id(2) linkqual_set_port();
      @defaultonly NoAction;
    }

    psa_direct_counter = linkqual_counter;



    const default_action = NoAction;
    size = 192;
  }

  apply {
    acl_linkqual_table.apply();
  }
} // control acl_linkqual
# 17 "middleblock.p4" 2

control ingress(inout headers_t headers,
                inout local_metadata_t local_metadata,
                in psa_ingress_input_metadata_t istd, inout psa_ingress_output_metadata_t ostd) {
  apply {
    acl_lookup.apply(headers, local_metadata, istd, ostd);
    l3_admit.apply(headers, local_metadata, istd, ostd);
    routing.apply(headers, local_metadata, istd, ostd);
    acl_linkqual.apply(headers, local_metadata, istd, ostd);
    acl_ingress.apply(headers, local_metadata, istd, ostd);
    ttl.apply(headers, local_metadata, istd, ostd);
    mirroring_clone.apply(headers, local_metadata);
  }
} // control ingress

control egress(inout headers_t headers,
               inout local_metadata_t local_metadata,
               in psa_egress_input_metadata_t istd, inout psa_egress_output_metadata_t ostd) {
  apply {
    packet_rewrites.apply(headers, local_metadata);
    mirroring_encap.apply(headers, local_metadata, istd, ostd);
  }
} // control egress

# 1 "../../fixed/instance.p4" 1






# 1 "../../fixed/egress_parde.p4" 1
/*
egress_parde.p4
*/

parser egress_parser(packet_in buffer,
                        out headers_t headers,
                        inout local_metadata_t local_metadata,
                        in psa_egress_parser_input_metadata_t istd,
                        in empty_metadata_t normal_meta,
                        in empty_metadata_t clone_i2e_meta,
                        in empty_metadata_t clone_e2e_meta)
{
    state start {
        transition accept;
    }
}

control egress_deparser(packet_out packet,
                        out empty_metadata_t clone_e2e_meta,
                        out empty_metadata_t recirculate_meta,
                        inout headers_t headers,
                        in local_metadata_t local_metadata,
                        in psa_egress_output_metadata_t istd,
                        in psa_egress_deparser_input_metadata_t edstd) {
    apply {
        packet.emit(headers);
    }
}
# 8 "../../fixed/instance.p4" 2
IngressPipeline(packet_parser(),
                ingress(),
                packet_deparser()) ip;

EgressPipeline(egress_parser(),
               egress(),
               egress_deparser()) ep;

PSA_Switch(ip, PacketReplicationEngine(), ep, BufferingQueueingEngine()) main;
# 41 "middleblock.p4" 2
