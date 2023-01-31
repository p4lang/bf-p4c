#include <core.p4>
#include <tna.p4>

@pa_parser_bandwidth_opt

enum bit<16> EtherType_t {
  IPV4 = 0x0800,
  ARISTA=0xD28B,
  AGGREGATION_PROTOCOL = 0x7260,
  VLAN = 0x8100,
  IPV6 = 0x86DD,
  MPLS = 0x8847,
  MPLSm= 0x8848,
  PPPoE= 0x8864,
  VLANAD=0x88A8,
  MACSEC=0x88E5,
  PBB = 0x88E7, // 802.1AH / PBB / Mac-in-Mac
  VLANADX=0x9100,
  VLAN2= 0x9200,
  VLAN3= 0x9300,
  VLANQA=0xA100
}

header TwoBytes_h {
  bit<16> bits;
}

header FourBytes_h {
  bit<32> bits;
}

header EightBytes_h {
  bit<64> bits;
}

struct Unknown_t {


# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        FourBytes_h word0;


        FourBytes_h word1;


        FourBytes_h word2;


        FourBytes_h word3;


        FourBytes_h word4;


        FourBytes_h word5;


        FourBytes_h word6;


        FourBytes_h word7;


        FourBytes_h word8;


        FourBytes_h word9;


        FourBytes_h word10;


        FourBytes_h word11;


        FourBytes_h word12;


        FourBytes_h word13;


        FourBytes_h word14;


        FourBytes_h word15;
# 45 "./jira/p4c-4825/common.p4" 2
}

header Ethernet_h {
  bit<48> dstAddr;
  bit<48> srcAddr;
  EtherType_t etherType;
}

header Aggregation_h {
  bit<4> version;
  bit<5> optionalFlags;
  bit<7> len;
  bit<16> payloadType;
  bit<3> verMod;
  bit<5> sigFlags;
  bit<8> pad;
  bit<32> flowID;
}

header VlanFlow_h {
  bit<3> pcp;
  bit<1> cfi;
  bit<12> vid;
}

header Vlan_h {
  bit<3> pcp;
  bit<1> cfi;
  bit<12> vid;
  EtherType_t etherType;
}

header Mpls_h {
  bit<20> label;
  bit<3> tc;
  bit<1> bos;
  bit<8> ttl;
}

header PPP_h {
  bit<8> flag;
  bit<8> address;
  bit<8> ctrl;
  bit<16> nextProto;
}

header PPPoE_h {
  bit<4> version;
  bit<4> type;
  bit<8> code;
  bit<16> sess_id;
  bit<16> len;
  //ppp header unwrapped
  bit<8> flag;
  bit<8> address;
  bit<8> ctrl;
  bit<16> nextProto;
}
# 5 "./jira/p4c-4825/Main.p4" 2

struct PortMetadata {
  bit<32> flowID;
  bit<8> inputType;
}

@flexible struct initial_meta_t
{
  bool found_ipv6;
  bool found_ipv4;
  bool ipv4_checksum_bad;
  bool mplsIP;
  bool macsec;
  PortMetadata portCfg;
  bit<8> expected_next;
}




struct full_layer2_headers_t
{
  Ethernet_h baseEth;
  Aggregation_h agg;
  EightBytes_h aggTimestamp;
  VlanFlow_h vlanFlow;

  TwoBytes_h etherType;



# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        Vlan_h baseTag0 ;


        Vlan_h baseTag1 ;


        Vlan_h baseTag2 ;
# 37 "./jira/p4c-4825/Main.p4" 2

  PPPoE_h basePPPoE;



# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        Mpls_h baseLabel_0_0 ; Mpls_h baseLabel_1_0 ; Mpls_h baseLabel_2_0 ;


        Mpls_h baseLabel_0_1 ; Mpls_h baseLabel_1_1 ; Mpls_h baseLabel_2_1 ;
# 43 "./jira/p4c-4825/Main.p4" 2

  FourBytes_h stuff;
  Ethernet_h extEth;



# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        Vlan_h extTag0 ;


        Vlan_h extTag1 ;


        Vlan_h extTag2 ;
# 50 "./jira/p4c-4825/Main.p4" 2

  PPPoE_h extPPPoE;



# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        Mpls_h extLabel_0_0 ; Mpls_h extLabel_1_0 ; Mpls_h extLabel_2_0 ;


        Mpls_h extLabel_0_1 ; Mpls_h extLabel_1_1 ; Mpls_h extLabel_2_1 ;
# 56 "./jira/p4c-4825/Main.p4" 2

  FourBytes_h stuffExt;

  Unknown_t unknown;
}

/* Programmable blocks */
parser InitialIngressParser(packet_in pkt,
                            out full_layer2_headers_t hdr,
                            out initial_meta_t meta,
                            out ingress_intrinsic_metadata_t ig_intr_md)
{
  Checksum() ipv4chk;

  state start {
    //**REQUIRED** [intrinsic]
    pkt.extract(ig_intr_md);

    //**REQUIRED** [port meta]
    meta.portCfg = port_metadata_unpack<PortMetadata>(pkt);
    meta.found_ipv6 = false;
    meta.found_ipv4 = false;
    meta.ipv4_checksum_bad = false;
    meta.mplsIP = false;
    meta.macsec = false;
    meta.expected_next = 0;

    transition select (meta.portCfg.inputType, pkt.lookahead<bit<112>>()[15:0]) {
      (1,(bit<16>)EtherType_t.AGGREGATION_PROTOCOL) : aggregation_hdr;
      (2,(bit<16>)EtherType_t.VLAN ) : parse_vlan_flow;
      (4,(bit<16>)EtherType_t.ARISTA ) : parse_arista;
      (2,(bit<16>)EtherType_t.ARISTA ) : parse_arista_vlan_flow;
      (_,(bit<16>)EtherType_t.IPV4 ) : parse_ethernet_ip;
      (_,(bit<16>)EtherType_t.IPV6 ) : parse_ethernet_ip;

      (_,0x8100 &&& 0xEFFF): parse_ethernet_vlan; // 8100 and 9100
      (_,0x9200 &&& 0xFEFF): parse_ethernet_vlan; // 9200 and 9300
      (_,(bit<16>)EtherType_t.VLANAD): parse_ethernet_vlan;
      (_,(bit<16>)EtherType_t.VLANQA): parse_ethernet_vlan;

      (_,(bit<16>)EtherType_t.MPLS): parse_ethernet_mpls;
      (_,(bit<16>)EtherType_t.MPLSm): parse_ethernet_mpls;

      (_,(bit<16>)EtherType_t.PPPoE): parse_ethernet_pppoe;
      (_,(bit<16>)EtherType_t.PBB): parse_ethernet_pbb;
      (_,(bit<16>)EtherType_t.MACSEC): parse_ethernet_macsec;

      default: parse_ethernet_unknown;
    }
  }

  state parse_ethernet_ip {
    pkt.extract(hdr.baseEth);
    transition expect_ip;
  }
  state parse_ethernet_vlan {
    pkt.extract(hdr.baseEth);
    transition parse_vlan_base;
  }
  state parse_ethernet_mpls {
    pkt.extract(hdr.baseEth);
    transition parse_mpls_base;
  }
  state parse_ethernet_pppoe {
    pkt.extract(hdr.baseEth);
    transition parse_pppoe_base;
  }
  state parse_ethernet_pbb {
    pkt.extract(hdr.baseEth);
    transition parse_pbb_base;
  }
  state parse_ethernet_macsec {
    pkt.extract(hdr.baseEth);
    transition parse_macsec;
  }
  state parse_ethernet_unknown {
    pkt.extract(hdr.baseEth);
    transition parse_unknown;
  }

  state parse_ethernet {
    pkt.extract(hdr.baseEth);
    transition select ((bit<16>)hdr.baseEth.etherType){
      (bit<16>)EtherType_t.IPV4: expect_ip;
      (bit<16>)EtherType_t.IPV6: expect_ip;

      0x8100 &&& 0xEFFF: parse_vlan_base; // 8100 and 9100
      0x9200 &&& 0xFEFF: parse_vlan_base; // 9200 and 9300
      (bit<16>)EtherType_t.VLANAD: parse_vlan_base;
      (bit<16>)EtherType_t.VLANQA: parse_vlan_base;

      (bit<16>)EtherType_t.MPLS: parse_mpls_base;
      (bit<16>)EtherType_t.MPLSm: parse_mpls_base;

      (bit<16>)EtherType_t.PPPoE: parse_pppoe_base;
      (bit<16>)EtherType_t.PBB: parse_pbb_base;
      (bit<16>)EtherType_t.MACSEC: parse_macsec;

      default: parse_unknown;
    }
  }

  state aggregation_hdr {
    pkt.advance(112);//No need to keep aggregation ethernet header around
    pkt.extract(hdr.agg);//Only need this for flow information - maybe better solution?
    transition select (hdr.agg.optionalFlags) {
      0b000: parse_ethernet;
      0b001: agg_timestamp;
      0b010: agg_frags;
      0b100: agg_priority;
      0b110: agg_frags_priority;
      0b011: agg_timestamp_frags;
      0b101: agg_timestamp_priority;
      0b111: agg_timestamp_frags_priority;
    }
  }

  state agg_timestamp {
    pkt.extract(hdr.aggTimestamp);
    transition parse_ethernet;
  }

  state agg_frags {
    pkt.advance(24); // discard
    transition parse_ethernet;
  }

  state agg_priority {
    pkt.advance(8); // discard
    transition parse_ethernet;
  }

  state agg_frags_priority {
    pkt.advance(32); // discard
    transition parse_ethernet;
  }

  state agg_timestamp_frags {
    pkt.extract(hdr.aggTimestamp);
    pkt.advance(24); // discard
    transition parse_ethernet;
  }

  state agg_timestamp_priority {
    pkt.extract(hdr.aggTimestamp);
    pkt.advance(8); // discard
    transition parse_ethernet;
  }

  state agg_timestamp_frags_priority {
    pkt.extract(hdr.aggTimestamp);
    pkt.advance(24); // discard
    pkt.advance(8); // discard
    transition parse_ethernet;
  }

  state parse_arista {
    pkt.extract(hdr.baseEth);
    pkt.advance(32);//No need to keep arista types
    pkt.extract(hdr.aggTimestamp);
    transition parse_etherType;
  }

  state parse_arista_vlan_flow {
    pkt.extract(hdr.baseEth);
    pkt.advance(32);//No need to keep arista types
    pkt.extract(hdr.aggTimestamp);
    pkt.advance(16);
    transition parse_vlan_flow;
  }

  state parse_vlan_flow {
    pkt.extract(hdr.vlanFlow);
    transition parse_etherType;
  }

  state parse_etherType {
    pkt.extract(hdr.etherType);
    transition select ((bit<16>)hdr.etherType.bits) {
      (bit<16>)EtherType_t.IPV4: expect_ip;
      (bit<16>)EtherType_t.IPV6: expect_ip;

      0x8100 &&& 0xEFFF: parse_vlan_base; // 8100 and 9100
      0x9200 &&& 0xFEFF: parse_vlan_base; // 9200 and 9300
      (bit<16>)EtherType_t.VLANAD: parse_vlan_base;
      (bit<16>)EtherType_t.VLANQA: parse_vlan_base;

      (bit<16>)EtherType_t.MPLS: parse_mpls_base;
      (bit<16>)EtherType_t.MPLSm: parse_mpls_base;

      (bit<16>)EtherType_t.PPPoE: parse_pppoe_base;
      (bit<16>)EtherType_t.PBB: parse_pbb_base;
      (bit<16>)EtherType_t.MACSEC:parse_macsec;

      default: parse_unknown;
    }
  }


  state parse_pppoe_base {
    pkt.extract(hdr.basePPPoE);
    transition select (hdr.basePPPoE.nextProto){
      0x0021: expect_ip;
      0x0057: expect_ip;
      0x0281 &&& 0xFFFD: parse_mpls_base;
      default: parse_unknown;
    }
  }






# 1 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 1
# 17 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp"
# 1 "/usr/local/include/boost/preprocessor/iteration/detail/bounds/lower1.hpp" 1
# 12 "/usr/local/include/boost/preprocessor/iteration/detail/bounds/lower1.hpp"
# 1 "/usr/local/include/boost/preprocessor/slot/detail/shared.hpp" 1
# 13 "/usr/local/include/boost/preprocessor/iteration/detail/bounds/lower1.hpp" 2
# 18 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2

# 1 "/usr/local/include/boost/preprocessor/iteration/detail/bounds/upper1.hpp" 1
# 12 "/usr/local/include/boost/preprocessor/iteration/detail/bounds/upper1.hpp"
# 1 "/usr/local/include/boost/preprocessor/slot/detail/shared.hpp" 1
# 13 "/usr/local/include/boost/preprocessor/iteration/detail/bounds/upper1.hpp" 2
# 20 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2
# 48 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp"
# 1 "./jira/p4c-4825/parse_vlan.p4" 1




  state parse_vlan_base



  {
    pkt.extract(hdr.baseTag0);
    transition select ((bit<16>)hdr.baseTag0.etherType) {
      (bit<16>)EtherType_t.IPV4 : expect_ip;
      (bit<16>)EtherType_t.IPV6 : expect_ip;
      (bit<16>)EtherType_t.MACSEC:parse_macsec;


      0x8100 &&& 0xEFFF: parse_vlan_base1; // 8100 and 9100
      0x9200 &&& 0xFEFF: parse_vlan_base1; // 9200 and 9300
      (bit<16>)EtherType_t.VLANAD: parse_vlan_base1;
      (bit<16>)EtherType_t.VLANQA: parse_vlan_base1;







      (bit<16>)EtherType_t.MPLS: parse_mpls_base;
      (bit<16>)EtherType_t.MPLSm: parse_mpls_base;

      (bit<16>)EtherType_t.PPPoE: parse_pppoe_base;
      (bit<16>)EtherType_t.PBB: parse_pbb_base;
      default: parse_unknown;
    }
  }
# 48 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2





# 1 "./jira/p4c-4825/parse_vlan.p4" 1






  state parse_vlan_base1

  {
    pkt.extract(hdr.baseTag1);
    transition select ((bit<16>)hdr.baseTag1.etherType) {
      (bit<16>)EtherType_t.IPV4 : expect_ip;
      (bit<16>)EtherType_t.IPV6 : expect_ip;
      (bit<16>)EtherType_t.MACSEC:parse_macsec;


      0x8100 &&& 0xEFFF: parse_vlan_base2; // 8100 and 9100
      0x9200 &&& 0xFEFF: parse_vlan_base2; // 9200 and 9300
      (bit<16>)EtherType_t.VLANAD: parse_vlan_base2;
      (bit<16>)EtherType_t.VLANQA: parse_vlan_base2;







      (bit<16>)EtherType_t.MPLS: parse_mpls_base;
      (bit<16>)EtherType_t.MPLSm: parse_mpls_base;

      (bit<16>)EtherType_t.PPPoE: parse_pppoe_base;
      (bit<16>)EtherType_t.PBB: parse_pbb_base;
      default: parse_unknown;
    }
  }
# 53 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2





# 1 "./jira/p4c-4825/parse_vlan.p4" 1






  state parse_vlan_base2

  {
    pkt.extract(hdr.baseTag2);
    transition select ((bit<16>)hdr.baseTag2.etherType) {
      (bit<16>)EtherType_t.IPV4 : expect_ip;
      (bit<16>)EtherType_t.IPV6 : expect_ip;
      (bit<16>)EtherType_t.MACSEC:parse_macsec;







      0x8100 &&& 0xEFFF: parse_vlan_ext;
      0x9200 &&& 0xFEFF: parse_vlan_ext;
      (bit<16>)EtherType_t.VLANAD: parse_vlan_ext;
      (bit<16>)EtherType_t.VLANQA: parse_vlan_ext;


      (bit<16>)EtherType_t.MPLS: parse_mpls_base;
      (bit<16>)EtherType_t.MPLSm: parse_mpls_base;

      (bit<16>)EtherType_t.PPPoE: parse_pppoe_base;
      (bit<16>)EtherType_t.PBB: parse_pbb_base;
      default: parse_unknown;
    }
  }
# 58 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2
# 271 "./jira/p4c-4825/Main.p4" 2



# 1 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 1
# 17 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp"
# 1 "/usr/local/include/boost/preprocessor/iteration/detail/bounds/lower1.hpp" 1
# 12 "/usr/local/include/boost/preprocessor/iteration/detail/bounds/lower1.hpp"
# 1 "/usr/local/include/boost/preprocessor/slot/detail/shared.hpp" 1
# 13 "/usr/local/include/boost/preprocessor/iteration/detail/bounds/lower1.hpp" 2
# 18 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2

# 1 "/usr/local/include/boost/preprocessor/iteration/detail/bounds/upper1.hpp" 1
# 12 "/usr/local/include/boost/preprocessor/iteration/detail/bounds/upper1.hpp"
# 1 "/usr/local/include/boost/preprocessor/slot/detail/shared.hpp" 1
# 13 "/usr/local/include/boost/preprocessor/iteration/detail/bounds/upper1.hpp" 2
# 20 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2
# 48 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp"
# 1 "./jira/p4c-4825/parse_mpls.p4" 1




  state parse_mpls_base {
    transition select (pkt.lookahead<bit<96>>()[72:72], pkt.lookahead<bit<96>>()[40:40], pkt.lookahead<bit<96>>()[8:8]) {
      (1,_,_): parse_mpls_base_single_0;
      (0,1,_): parse_mpls_base_1_0;
      (0,0,1): parse_mpls_base_2_0;
      (0,0,0): parse_mpls_base_3plus_0;
    }
  }

  state parse_mpls_base_single_0 {
    pkt.extract(hdr. baseLabel_0_0);
    transition bottom_of_stack_base;
  }


  state parse_mpls_base_1_0 {

    pkt.extract(hdr. baseLabel_0_0);

    pkt.extract(hdr. baseLabel_1_0);
    transition bottom_of_stack_base;
  }

  state parse_mpls_base_2_0 {

    pkt.extract(hdr. baseLabel_0_0);

    pkt.extract(hdr. baseLabel_1_0);
    pkt.extract(hdr. baseLabel_2_0);
    transition bottom_of_stack_base;
  }

  state parse_mpls_base_3plus_0 {

    pkt.extract(hdr. baseLabel_0_0);

    pkt.extract(hdr. baseLabel_1_0);
    pkt.extract(hdr. baseLabel_2_0);

    pkt.extract(hdr. baseLabel_0_1);
    transition select (hdr.baseLabel_0_1.bos, pkt.lookahead<bit<64>>()[40:40], pkt.lookahead<bit<64>>()[8:8]) {
      (1,_,_): bottom_of_stack_base;
      (0,1,_): parse_mpls_base_1_1;
      (0,0,1): parse_mpls_base_2_1;
      (0,0,0): parse_mpls_base_3plus_1;
    }





  }
# 48 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2





# 1 "./jira/p4c-4825/parse_mpls.p4" 1
# 20 "./jira/p4c-4825/parse_mpls.p4"
  state parse_mpls_base_1_1 {



    pkt.extract(hdr. baseLabel_1_1);
    transition bottom_of_stack_base;
  }

  state parse_mpls_base_2_1 {



    pkt.extract(hdr. baseLabel_1_1);
    pkt.extract(hdr. baseLabel_2_1);
    transition bottom_of_stack_base;
  }

  state parse_mpls_base_3plus_1 {



    pkt.extract(hdr. baseLabel_1_1);
    pkt.extract(hdr. baseLabel_2_1);
# 52 "./jira/p4c-4825/parse_mpls.p4"
    transition parse_mpls_ext;



  }
# 53 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2
# 275 "./jira/p4c-4825/Main.p4" 2




  state bottom_of_stack_base {
    transition select (pkt.lookahead<bit<32>>()) {
      0: parse_pseudowire_ext;
      0x40000000 &&& 0xF0003FF0: maybe_ethernet_ext; // bad total length, not in range [15, 16383]
      0x45000000 &&& 0xFF00E000: parse_unknown;
      0x46000000 &&& 0xF600E000: parse_unknown;
      0x48000000 &&& 0xF800E000: parse_unknown;
      0x60000000 &&& 0xF0000000: parse_unknown;
      default: maybe_ethernet_ext;
    }
  }

  state maybe_ethernet_ext {
    transition select (pkt.lookahead<bit<144>>()[47:32]) {
      (bit<16>)EtherType_t.IPV4: parse_ethernet_ext_ip;
      (bit<16>)EtherType_t.IPV6: parse_ethernet_ext_ip;

      (bit<16>)EtherType_t.MPLS: parse_ethernet_ext_mpls;
      (bit<16>)EtherType_t.MPLSm: parse_ethernet_ext_mpls;

      0x8100 &&& 0xEFFF: parse_ethernet_ext_vlan; // 8100 and 9100
      0x9200 &&& 0xFEFF: parse_ethernet_ext_vlan; // 9200 and 9300
      (bit<16>)EtherType_t.VLANAD: parse_ethernet_ext_vlan;
      (bit<16>)EtherType_t.VLANQA: parse_ethernet_ext_vlan;
      (bit<16>)EtherType_t.MACSEC: parse_ethernet_ext_macsec;
      (bit<16>)EtherType_t.PPPoE: parse_ethernet_ext_pppoe;

      default: parse_unknown;
    }
  }

  state parse_pbb_base {
    pkt.extract(hdr.stuff);
    transition maybe_ethernet_ext;
  } //NOTE: There is a loss here - unknown case does not skip the expected ethernet header now

  state parse_pseudowire_ext {
    pkt.extract(hdr.stuff);
    transition maybe_ethernet_ext;
  }

  state parse_ethernet_ext_ip {
    pkt.extract(hdr.extEth);
    transition expect_ip;
  }

  state parse_ethernet_ext_vlan {
    pkt.extract(hdr.extEth);
    transition parse_vlan_ext;
  }

  state parse_ethernet_ext_mpls {
    pkt.extract(hdr.extEth);
    transition parse_mpls_ext;
  }

  state parse_ethernet_ext_pppoe {
    pkt.extract(hdr.extEth);
    transition parse_pppoe_ext;
  }

  state parse_ethernet_ext_macsec {
    pkt.extract(hdr.extEth);
    transition parse_macsec;
  }

  state parse_pppoe_ext {
    pkt.extract(hdr.extPPPoE);
    transition select (hdr.extPPPoE.nextProto) {
      0x0021: expect_ip;
      0x0057: expect_ip;
      0x0281 &&& 0xFFFD: parse_mpls_ext;
      default: parse_unknown;
    }
  }







# 1 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 1
# 17 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp"
# 1 "/usr/local/include/boost/preprocessor/iteration/detail/bounds/lower1.hpp" 1
# 12 "/usr/local/include/boost/preprocessor/iteration/detail/bounds/lower1.hpp"
# 1 "/usr/local/include/boost/preprocessor/slot/detail/shared.hpp" 1
# 13 "/usr/local/include/boost/preprocessor/iteration/detail/bounds/lower1.hpp" 2
# 18 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2

# 1 "/usr/local/include/boost/preprocessor/iteration/detail/bounds/upper1.hpp" 1
# 12 "/usr/local/include/boost/preprocessor/iteration/detail/bounds/upper1.hpp"
# 1 "/usr/local/include/boost/preprocessor/slot/detail/shared.hpp" 1
# 13 "/usr/local/include/boost/preprocessor/iteration/detail/bounds/upper1.hpp" 2
# 20 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2
# 48 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp"
# 1 "./jira/p4c-4825/parse_vlan.p4" 1




  state parse_vlan_ext



  {
    pkt.extract(hdr.extTag0);
    transition select ((bit<16>)hdr.extTag0.etherType) {
      (bit<16>)EtherType_t.IPV4 : expect_ip;
      (bit<16>)EtherType_t.IPV6 : expect_ip;
      (bit<16>)EtherType_t.MACSEC:parse_macsec;


      0x8100 &&& 0xEFFF: parse_vlan_ext1; // 8100 and 9100
      0x9200 &&& 0xFEFF: parse_vlan_ext1; // 9200 and 9300
      (bit<16>)EtherType_t.VLANAD: parse_vlan_ext1;
      (bit<16>)EtherType_t.VLANQA: parse_vlan_ext1;







      (bit<16>)EtherType_t.MPLS: parse_mpls_ext;
      (bit<16>)EtherType_t.MPLSm: parse_mpls_ext;

      (bit<16>)EtherType_t.PPPoE: parse_pppoe_ext;
      (bit<16>)EtherType_t.PBB: parse_pbb_ext;
      default: parse_unknown;
    }
  }
# 48 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2





# 1 "./jira/p4c-4825/parse_vlan.p4" 1






  state parse_vlan_ext1

  {
    pkt.extract(hdr.extTag1);
    transition select ((bit<16>)hdr.extTag1.etherType) {
      (bit<16>)EtherType_t.IPV4 : expect_ip;
      (bit<16>)EtherType_t.IPV6 : expect_ip;
      (bit<16>)EtherType_t.MACSEC:parse_macsec;


      0x8100 &&& 0xEFFF: parse_vlan_ext2; // 8100 and 9100
      0x9200 &&& 0xFEFF: parse_vlan_ext2; // 9200 and 9300
      (bit<16>)EtherType_t.VLANAD: parse_vlan_ext2;
      (bit<16>)EtherType_t.VLANQA: parse_vlan_ext2;







      (bit<16>)EtherType_t.MPLS: parse_mpls_ext;
      (bit<16>)EtherType_t.MPLSm: parse_mpls_ext;

      (bit<16>)EtherType_t.PPPoE: parse_pppoe_ext;
      (bit<16>)EtherType_t.PBB: parse_pbb_ext;
      default: parse_unknown;
    }
  }
# 53 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2





# 1 "./jira/p4c-4825/parse_vlan.p4" 1






  state parse_vlan_ext2

  {
    pkt.extract(hdr.extTag2);
    transition select ((bit<16>)hdr.extTag2.etherType) {
      (bit<16>)EtherType_t.IPV4 : expect_ip;
      (bit<16>)EtherType_t.IPV6 : expect_ip;
      (bit<16>)EtherType_t.MACSEC:parse_macsec;







      0x8100 &&& 0xEFFF: parse_vlan_too_many;
      0x9200 &&& 0xFEFF: parse_vlan_too_many;
      (bit<16>)EtherType_t.VLANAD: parse_vlan_too_many;
      (bit<16>)EtherType_t.VLANQA: parse_vlan_too_many;


      (bit<16>)EtherType_t.MPLS: parse_mpls_ext;
      (bit<16>)EtherType_t.MPLSm: parse_mpls_ext;

      (bit<16>)EtherType_t.PPPoE: parse_pppoe_ext;
      (bit<16>)EtherType_t.PBB: parse_pbb_ext;
      default: parse_unknown;
    }
  }
# 58 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2
# 362 "./jira/p4c-4825/Main.p4" 2







# 1 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 1
# 17 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp"
# 1 "/usr/local/include/boost/preprocessor/iteration/detail/bounds/lower1.hpp" 1
# 12 "/usr/local/include/boost/preprocessor/iteration/detail/bounds/lower1.hpp"
# 1 "/usr/local/include/boost/preprocessor/slot/detail/shared.hpp" 1
# 13 "/usr/local/include/boost/preprocessor/iteration/detail/bounds/lower1.hpp" 2
# 18 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2

# 1 "/usr/local/include/boost/preprocessor/iteration/detail/bounds/upper1.hpp" 1
# 12 "/usr/local/include/boost/preprocessor/iteration/detail/bounds/upper1.hpp"
# 1 "/usr/local/include/boost/preprocessor/slot/detail/shared.hpp" 1
# 13 "/usr/local/include/boost/preprocessor/iteration/detail/bounds/upper1.hpp" 2
# 20 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2
# 48 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp"
# 1 "./jira/p4c-4825/parse_mpls.p4" 1




  state parse_mpls_ext {
    transition select (pkt.lookahead<bit<96>>()[72:72], pkt.lookahead<bit<96>>()[40:40], pkt.lookahead<bit<96>>()[8:8]) {
      (1,_,_): parse_mpls_ext_single_0;
      (0,1,_): parse_mpls_ext_1_0;
      (0,0,1): parse_mpls_ext_2_0;
      (0,0,0): parse_mpls_ext_3plus_0;
    }
  }

  state parse_mpls_ext_single_0 {
    pkt.extract(hdr. extLabel_0_0);
    transition bottom_of_stack_ext;
  }


  state parse_mpls_ext_1_0 {

    pkt.extract(hdr. extLabel_0_0);

    pkt.extract(hdr. extLabel_1_0);
    transition bottom_of_stack_ext;
  }

  state parse_mpls_ext_2_0 {

    pkt.extract(hdr. extLabel_0_0);

    pkt.extract(hdr. extLabel_1_0);
    pkt.extract(hdr. extLabel_2_0);
    transition bottom_of_stack_ext;
  }

  state parse_mpls_ext_3plus_0 {

    pkt.extract(hdr. extLabel_0_0);

    pkt.extract(hdr. extLabel_1_0);
    pkt.extract(hdr. extLabel_2_0);

    pkt.extract(hdr. extLabel_0_1);
    transition select (hdr.extLabel_0_1.bos, pkt.lookahead<bit<64>>()[40:40], pkt.lookahead<bit<64>>()[8:8]) {
      (1,_,_): bottom_of_stack_ext;
      (0,1,_): parse_mpls_ext_1_1;
      (0,0,1): parse_mpls_ext_2_1;
      (0,0,0): parse_mpls_ext_3plus_1;
    }





  }
# 48 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2





# 1 "./jira/p4c-4825/parse_mpls.p4" 1
# 20 "./jira/p4c-4825/parse_mpls.p4"
  state parse_mpls_ext_1_1 {



    pkt.extract(hdr. extLabel_1_1);
    transition bottom_of_stack_ext;
  }

  state parse_mpls_ext_2_1 {



    pkt.extract(hdr. extLabel_1_1);
    pkt.extract(hdr. extLabel_2_1);
    transition bottom_of_stack_ext;
  }

  state parse_mpls_ext_3plus_1 {



    pkt.extract(hdr. extLabel_1_1);
    pkt.extract(hdr. extLabel_2_1);
# 54 "./jira/p4c-4825/parse_mpls.p4"
    transition too_many_mpls;

  }
# 53 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2
# 370 "./jira/p4c-4825/Main.p4" 2





  state bottom_of_stack_ext { //We'll depend on parse unknown/ip find finding IP if present
    transition select(pkt.lookahead<bit<32>>()) {
      0 : parse_pbb_ext;//Really control-word ethernet assumed
      default : expect_ethernet;
    }
  }

  state too_many_mpls {
    meta.expected_next = 67;
    transition parse_unknown;
  }

  state parse_vlan_too_many {
    meta.expected_next = 66;
    transition parse_unknown;
  }

  state parse_pbb_ext {
    pkt.extract(hdr.stuffExt);
    meta.expected_next = 65;
    transition parse_unknown;
  }

  state expect_ethernet {
    meta.expected_next = 65;
    transition parse_unknown;
  }

  state parse_macsec {
    meta.macsec = true;


# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        pkt.extract(hdr.unknown.word0);


        pkt.extract(hdr.unknown.word1);


        pkt.extract(hdr.unknown.word2);


        pkt.extract(hdr.unknown.word3);
# 408 "./jira/p4c-4825/Main.p4" 2
    transition unknown_4;
  }

  state expect_ip {


# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        pkt.extract(hdr.unknown.word0);


        pkt.extract(hdr.unknown.word1);


        pkt.extract(hdr.unknown.word2);


        pkt.extract(hdr.unknown.word3);
# 415 "./jira/p4c-4825/Main.p4" 2
    ipv4chk.add({
      hdr.unknown.word0.bits


# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 37 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        ,hdr.unknown.word1.bits


        ,hdr.unknown.word2.bits


        ,hdr.unknown.word3.bits
# 420 "./jira/p4c-4825/Main.p4" 2
    });

    transition select(hdr.unknown.word0.bits[31:28], hdr.unknown.word0.bits[27:24]) {
      (4,5): checksum_ipv4_5;
      (4,6): checksum_ipv4_6;
      (4,7): checksum_ipv4_7;
      (4,8 &&& 8): checksum_ipv4_8plus;

      (6, _): got_ipv6;

      default: unknown_4;
    }
  }

  state got_ipv6 {
    meta.found_ipv6 = true;


# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 46 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        pkt.extract(hdr.unknown.word4);


        pkt.extract(hdr.unknown.word5);


        pkt.extract(hdr.unknown.word6);


        pkt.extract(hdr.unknown.word7);
# 439 "./jira/p4c-4825/Main.p4" 2
    transition unknown_8;
  }

  state checksum_ipv4_5 {


# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 46 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        pkt.extract(hdr.unknown.word4);


        pkt.extract(hdr.unknown.word5);


        pkt.extract(hdr.unknown.word6);


        pkt.extract(hdr.unknown.word7);
# 446 "./jira/p4c-4825/Main.p4" 2

    meta.found_ipv4 = true;
    ipv4chk.add({
      hdr.unknown.word4.bits
    });
    meta.ipv4_checksum_bad = ipv4chk.verify();

    transition unknown_8;
  }

  state checksum_ipv4_6 {


# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 46 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        pkt.extract(hdr.unknown.word4);


        pkt.extract(hdr.unknown.word5);


        pkt.extract(hdr.unknown.word6);


        pkt.extract(hdr.unknown.word7);
# 460 "./jira/p4c-4825/Main.p4" 2

    meta.found_ipv4 = true;
    ipv4chk.add({
      hdr.unknown.word4.bits,
      hdr.unknown.word5.bits
    });
    meta.ipv4_checksum_bad = ipv4chk.verify();

    transition unknown_8;
  }

  state checksum_ipv4_7 {


# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 46 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        pkt.extract(hdr.unknown.word4);


        pkt.extract(hdr.unknown.word5);


        pkt.extract(hdr.unknown.word6);


        pkt.extract(hdr.unknown.word7);
# 475 "./jira/p4c-4825/Main.p4" 2

    meta.found_ipv4 = true;
    ipv4chk.add({
      hdr.unknown.word4.bits,
      hdr.unknown.word5.bits,
      hdr.unknown.word6.bits
    });
    meta.ipv4_checksum_bad = ipv4chk.verify();

    transition unknown_8;
  }

  state checksum_ipv4_8plus {


# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 46 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        pkt.extract(hdr.unknown.word4);


        pkt.extract(hdr.unknown.word5);


        pkt.extract(hdr.unknown.word6);


        pkt.extract(hdr.unknown.word7);
# 491 "./jira/p4c-4825/Main.p4" 2

    ipv4chk.add({
      hdr.unknown.word4.bits,
      hdr.unknown.word5.bits,
      hdr.unknown.word6.bits,
      hdr.unknown.word7.bits
    });

    transition select (hdr.unknown.word0.bits[27:24]) {
      8: checksum_ipv4_8;
      9: checksum_ipv4_9;
      10: checksum_ipv4_10;
      11: checksum_ipv4_11;
      default: checksum_ipv4_12plus;
    }
  }

  state checksum_ipv4_8 {


# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 58 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        pkt.extract(hdr.unknown.word8);


        pkt.extract(hdr.unknown.word9);
# 512 "./jira/p4c-4825/Main.p4" 2

    meta.found_ipv4 = true;
    meta.ipv4_checksum_bad = ipv4chk.verify();

    transition unknown_10;
  }

  state checksum_ipv4_9 {


# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 58 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        pkt.extract(hdr.unknown.word8);


        pkt.extract(hdr.unknown.word9);
# 523 "./jira/p4c-4825/Main.p4" 2

    meta.found_ipv4 = true;
    ipv4chk.add({
      hdr.unknown.word8.bits
    });
    meta.ipv4_checksum_bad = ipv4chk.verify();

    transition unknown_10;
  }

  state checksum_ipv4_10 {


# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 58 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        pkt.extract(hdr.unknown.word8);


        pkt.extract(hdr.unknown.word9);
# 537 "./jira/p4c-4825/Main.p4" 2

    meta.found_ipv4 = true;
    ipv4chk.add({
      hdr.unknown.word8.bits,
      hdr.unknown.word9.bits
    });
    meta.ipv4_checksum_bad = ipv4chk.verify();

    transition unknown_10;
  }

  state checksum_ipv4_11 {


# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 58 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        pkt.extract(hdr.unknown.word8);


        pkt.extract(hdr.unknown.word9);


        pkt.extract(hdr.unknown.word10);


        pkt.extract(hdr.unknown.word11);
# 552 "./jira/p4c-4825/Main.p4" 2

    meta.found_ipv4 = true;
    ipv4chk.add({
      hdr.unknown.word8.bits,
      hdr.unknown.word9.bits,
      hdr.unknown.word10.bits
    });
    meta.ipv4_checksum_bad = ipv4chk.verify();

    transition unknown_12;
  }

  state checksum_ipv4_12plus {


# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 58 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        pkt.extract(hdr.unknown.word8);


        pkt.extract(hdr.unknown.word9);


        pkt.extract(hdr.unknown.word10);


        pkt.extract(hdr.unknown.word11);
# 568 "./jira/p4c-4825/Main.p4" 2

    ipv4chk.add({
      hdr.unknown.word8.bits,
      hdr.unknown.word9.bits,
      hdr.unknown.word10.bits,
      hdr.unknown.word11.bits
    });

    transition select (hdr.unknown.word0.bits[27:24]) {
      12: checksum_ipv4_12;
      13: checksum_ipv4_13;
      14: checksum_ipv4_14;
      15: checksum_ipv4_15;
    }
  }

  state checksum_ipv4_12 {


# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 70 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        pkt.extract(hdr.unknown.word12);


        pkt.extract(hdr.unknown.word13);
# 588 "./jira/p4c-4825/Main.p4" 2

    meta.found_ipv4 = true;
    meta.ipv4_checksum_bad = ipv4chk.verify();

    transition unknown_14;
  }

  state checksum_ipv4_13 {


# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 70 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        pkt.extract(hdr.unknown.word12);


        pkt.extract(hdr.unknown.word13);
# 599 "./jira/p4c-4825/Main.p4" 2

    meta.found_ipv4 = true;
    ipv4chk.add({
      hdr.unknown.word12.bits
    });
    meta.ipv4_checksum_bad = ipv4chk.verify();

    transition unknown_14;
  }

  state checksum_ipv4_14 {


# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 70 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        pkt.extract(hdr.unknown.word12);


        pkt.extract(hdr.unknown.word13);


        pkt.extract(hdr.unknown.word14);


        pkt.extract(hdr.unknown.word15);
# 613 "./jira/p4c-4825/Main.p4" 2

    meta.found_ipv4 = true;
    ipv4chk.add({
      hdr.unknown.word12.bits,
      hdr.unknown.word13.bits
    });
    meta.ipv4_checksum_bad = ipv4chk.verify();

    transition accept;
  }

  state checksum_ipv4_15 {


# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 70 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        pkt.extract(hdr.unknown.word12);


        pkt.extract(hdr.unknown.word13);


        pkt.extract(hdr.unknown.word14);


        pkt.extract(hdr.unknown.word15);
# 628 "./jira/p4c-4825/Main.p4" 2

    meta.found_ipv4 = true;
    ipv4chk.add({
      hdr.unknown.word12.bits,
      hdr.unknown.word13.bits,
      hdr.unknown.word14.bits
    });
    meta.ipv4_checksum_bad = ipv4chk.verify();

    transition accept;
  }

  state parse_unknown {


# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        pkt.extract(hdr.unknown.word0);


        pkt.extract(hdr.unknown.word1);


        pkt.extract(hdr.unknown.word2);


        pkt.extract(hdr.unknown.word3);
# 644 "./jira/p4c-4825/Main.p4" 2
    ipv4chk.add({
      hdr.unknown.word0.bits


# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 37 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        ,hdr.unknown.word1.bits


        ,hdr.unknown.word2.bits


        ,hdr.unknown.word3.bits
# 649 "./jira/p4c-4825/Main.p4" 2
    });

    transition select(hdr.unknown.word0.bits[31:28], hdr.unknown.word0.bits[27:24]) {
      (4,5): checksum_ipv4_5;
      (4,6): checksum_ipv4_6;
      (4,7): checksum_ipv4_7;
      (4,8 &&& 8): checksum_ipv4_8plus;

      // DO NOT check for ipv6 here

      default: unknown_4;
    }
  }

  state unknown_4 {


# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 46 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        pkt.extract(hdr.unknown.word4);


        pkt.extract(hdr.unknown.word5);


        pkt.extract(hdr.unknown.word6);


        pkt.extract(hdr.unknown.word7);
# 667 "./jira/p4c-4825/Main.p4" 2
    transition unknown_8;
  }

  state unknown_8 {
    pkt.extract(hdr.unknown.word8);
    pkt.extract(hdr.unknown.word9);
    transition unknown_10;
  }

  state unknown_10 {
    pkt.extract(hdr.unknown.word10);
    pkt.extract(hdr.unknown.word11);
    transition unknown_12;
  }

  state unknown_12 {
    pkt.extract(hdr.unknown.word12);
    pkt.extract(hdr.unknown.word13);
    transition unknown_14;
  }

  state unknown_14 {
    pkt.extract(hdr.unknown.word14);
    pkt.extract(hdr.unknown.word15);
    transition accept;
  }
}

struct pair_32_t { bit<32> a; bit<32> b; };

control InitialIngress(inout full_layer2_headers_t hdr,
                       inout initial_meta_t meta,
                       in ingress_intrinsic_metadata_t ig_intr_md,
                       in ingress_intrinsic_metadata_from_parser_t ig_intr_md_from_prsr,
                       inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
                       inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm)
{
  Random<bit<4>>() rand16;
  Meter<bit<9>>(512, MeterType_t.BYTES) InternalPortMeter;
  Counter<bit<32>, bit<9>>(512, CounterType_t.BYTES) InternalPortTraffic;
  Counter<bit<32>, bit<9>>(512, CounterType_t.BYTES) InternalPortOverQuota;
  Counter<bit<32>, bit<9>>(512, CounterType_t.PACKETS_AND_BYTES) InputPortTraffic;
  Counter<bit<32>, bit<1>>(1, CounterType_t.PACKETS_AND_BYTES) IngressTraffic;
  Counter<bit<32>, bit<9>>(512, CounterType_t.PACKETS_AND_BYTES) Easy_IPv4;
  Counter<bit<32>, bit<9>>(512, CounterType_t.PACKETS_AND_BYTES) Easy_IPv6;

  @hidden Hash<bit<4>>(HashAlgorithm_t.CRC32) unkhash;

  action doDisableLoopingParse() {meta.expected_next = 0;}
  table disableLoopingParse {
    actions = {@defaultonly NoAction; @defaultonly doDisableLoopingParse;}
    default_action = NoAction();
  }

  action alternate() {
    ig_intr_md_for_tm.ucast_egress_port = ig_intr_md.ingress_port ^ 9w0x080; // 0->1, 1->0, 2->3, 3->2
  }
  action lower() {
    ig_intr_md_for_tm.ucast_egress_port = ig_intr_md.ingress_port & 9w0x0FF; // zero upper bit
  }
  action upper() {
    ig_intr_md_for_tm.ucast_egress_port = ig_intr_md.ingress_port | 9w0x100; // set upper bit
  }
  table assignInternalPipe
  {
    actions = { @defaultonly alternate; @defaultonly lower; @defaultonly upper; }
    default_action = alternate();
  }
  bit<32> flowID;

  apply {
    disableLoopingParse.apply();
    InputPortTraffic.count(ig_intr_md.ingress_port);
    IngressTraffic.count(0);
    if (meta.found_ipv4 && !meta.ipv4_checksum_bad)
      Easy_IPv4.count(ig_intr_md.ingress_port);
    else if (meta.found_ipv6)
      Easy_IPv6.count(ig_intr_md.ingress_port);

    if (hdr.agg.isValid())
      flowID = hdr.agg.flowID;
    else if (hdr.vlanFlow.isValid())
      flowID = (bit<32>)hdr.vlanFlow.vid;
    else
      flowID = meta.portCfg.flowID;

    if (hdr.etherType.isValid())
      hdr.baseEth.etherType = (EtherType_t)hdr.etherType.bits;

    assignInternalPipe.apply();
    ig_intr_md_for_tm.ucast_egress_port[5:2] = unkhash.get({flowID, hdr.baseEth.srcAddr, hdr.baseEth.dstAddr, hdr.baseEth.etherType});
    ig_intr_md_for_tm.ucast_egress_port[1:0] = 0; // use the 100G interface

    // Round-robin if the port is highly loaded so that our internal header bloat doesn't force packet drops
    // But don't do this in normal cases because it probably results in tons of reordering
    ig_intr_md_for_dprsr.drop_ctl = 0;
    bit<8> color = InternalPortMeter.execute(ig_intr_md_for_tm.ucast_egress_port);
    if (color == (bit<8>)MeterColor_t.RED) {
      InternalPortOverQuota.count(ig_intr_md_for_tm.ucast_egress_port);
      ig_intr_md_for_tm.ucast_egress_port[5:2] = rand16.get();
    }
    InternalPortTraffic.count(ig_intr_md_for_tm.ucast_egress_port);

    hdr.etherType.setInvalid();
    hdr.agg.setInvalid();
    hdr.aggTimestamp.setInvalid();
    hdr.vlanFlow.setInvalid();
  }
}

control InitialIngressDeparser(packet_out pkt,
                               inout full_layer2_headers_t hdr,
                               in initial_meta_t meta,
                               in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr)
{
  apply { pkt.emit(hdr); }
}

struct final_headers_t {}
struct final_meta_t {}

parser FinalEgressParser(packet_in pkt,
                         out final_headers_t hdr,
                         out final_meta_t meta,
                         out egress_intrinsic_metadata_t eg_intr_md)
{
  state start {
    pkt.extract(eg_intr_md); // required intrinsic
    transition accept;
  }
}

control FinalEgress(inout final_headers_t hdr,
                    inout final_meta_t meta,
                    in egress_intrinsic_metadata_t eg_intr_md,
                    in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
                    inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
                    inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport)
{
  apply {
  }
}

control FinalEgressDeparser(packet_out pkt,
                            inout final_headers_t hdr,
                            in final_meta_t metadata,
                            in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr)
{
  apply {
    pkt.emit(hdr);
  }
}

Pipeline(
    InitialIngressParser(),
    InitialIngress(),
    InitialIngressDeparser(),
    FinalEgressParser(),
    FinalEgress(),
    FinalEgressDeparser())
pipe;


Switch(pipe) main;
