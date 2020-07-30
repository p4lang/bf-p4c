/* -*- P4_16 -*- */

#include <core.p4>
#include <t2na.p4>  /* TOFINO2_ONLY */

# 1 "./Constants.p4h" 1
# 10 "./Constants.p4h"
const bit<8> BPT_UNKNOWN = 0;
const bit<8> BPT_MPLS = 1;
const bit<8> BPT_VLAN = 2;
const bit<8> BPT_ETHERNET = 3;
const bit<8> BPT_IP4 = 4; //Bridged IP - should only see on returns from external processing
const bit<8> BPT_IP6 = 5;
const bit<8> BPT_GTPV0 = 6;
const bit<8> BPT_GTPV1 = 7;
const bit<8> BPT_AYIYA = 8;
const bit<8> BPT_GRE = 9;
const bit<8> BPT_L2TP = 10;
const bit<8> BPT_TEREDO = 11;
const bit<8> BPT_BRIDGED = 12;
const bit<8> BPT_MACSEC = 13;

const bit<8> IPT_UNKNOWN = 0;
const bit<8> IPT_BRIDGED = 1;
const bit<8> IPT_IP = 2;
const bit<8> IPT_ETHERNET = 3;
const bit<8> IPT_DROP = 5;

const bit<8> IpNp_IP4 = 4;
const bit<8> IpNp_TCP = 6;
const bit<8> IpNp_UDP = 17;
const bit<8> IpNp_IP6 = 41;
const bit<8> IpNp_GRE = 47;
const bit<8> IpNp_L2TP = 115;
const bit<8> IpNp_MPLS = 137;

const bit<8> ST_OFFLOAD = 0;
const bit<8> ST_UNFINISHED = 1;
const bit<8> ST_DONE_LOCAL = 2;
const bit<8> ST_DONE = 3;
const bit<8> ST_OFFLOAD_DIRECT = 4;
const bit<8> ST_NON_IP = 5;

const bit<8> RT_UNSET = 0;
const bit<8> RT_DONE = 1;
const bit<8> RT_CONTINUE = 2;
const bit<8> RT_TO_CPU = 3;
const bit<8> RT_DROP = 4;
const bit<8> RT_UNKNOWN_PROTO = 5;
const bit<8> RT_IP_DEFRAG = 6;
# 5 "./ParsingStructures.p4h" 2

struct port_metadata_t {
    bit<8> protocol_key;
    bit<32> flowId;
}

header Byte128_h {
    bit<1024> d;
};

header Byte64_h {
    bit<512> d;
};

header Byte32_h {
    bit<256> d;
};

header Byte20_h {
    bit<160> d;
};

header Byte16_h {
    bit<128> d;
};

header Byte12_h {
    bit<96> d;
};

header Byte8_h {
    bit<64> d;
};

header Byte4_h {
    bit<32> d;
};

header Byte2_h {
    bit<16> d;
};

header Byte1_h {
    bit<8> d;
};

header VarByte64_h {
    varbit<512> d;
}

header VarByte40_h {
    varbit<320> d;
}

header VarByte20_h {
    varbit<160> d;
}

header KeyBytes_h {
    bit<16> hw1;
    bit<16> hw2;
    bit<32> hdw;
    bit<16> dw1;
    bit<16> dw2;
    bit<16> dw3;
    bit<16> dw4;
    bit<16> dw5;
    bit<16> dw6;
};

header IdSequence_h {
    bit<4> ipVersion;
    bit<4> ip4hdrlen;
    bit<8> zero1;
    bit<4> ip4lenbits;
    bit<4> zero2;
    bit<4> PAD1;
    bit<4> zero3;
    bit<4> ip6lenbits;
    bit<4> PAD2;
}

header FullIpIdSequence_h {
    bit<4> ipVersion;
    bit<4> ip4hdrlen;
    bit<8> zero1;
    bit<4> ip4lenbits;
    bit<8> zero2;
    bit<4> PAD1;
    bit<4> ip6lenbits;
    bit<28> PAD2;
    bit<16> ip6A1;
};

header Mpls_h {
    bit<16> labelU;
    bit<4> labelL;
    bit<3> qos;
    bit<1> bos;
    bit<8> ttl;
}

header MplsStack_h {
    bit<8> pad1;
    bit<15> zcheck;
    bit<1> bos1;
    bit<31> pad2;
    bit<1> bos2;
}

header Vlan_h {
    bit<3> pcp;
    bit<1> cfi;
    bit<12> vid;
    bit<16> type;
}

header Ethernet_h {
    bit<48> src;
    bit<48> dst;
    bit<16> type;
}

header EthernetTestHeader_h {
    bit<96> pad1;
    bit<16> ethType;
    bit<16> pad2;
    bit<16> ethType2;
}
# 144 "./ParsingStructures.p4h"
header Ipv4_h {
    bit<4> version;
    bit<4> hdrlen;
    bit<8> tos;
    bit<16> totalLength;
    bit<16> id;
    bit<1> reserved;
    bit<1> dontFrag;
    bit<1> moreFrags;
    bit<13> fragmentOffset;
    bit<8> ttl;
    bit<8> protocol;
    bit<16> checksum;
}

header Ipv4Addresses_h {
    bit<32> src;
    bit<32> dst;
}







header Ipv6_h {
    bit<4> version;
    bit<8> trafficClass;
    bit<20> flowLabel;
    bit<16> payloadLength;
    bit<8> nextHeader;
    bit<8> hopLimit;
}

header Ipv6Addresses_h {
    bit<128> src;
    bit<128> dst;
};

header Ipv6Ext_h {
    bit<8> protocol;
    bit<8> length;
    bit<48> pad;
};

header Bridging_h {
    bit<8> protocol;
    bit<8> offset;
    bit<8> state;
    bit<8> routingType;
    bit<32> sourceId;
    bit<48> timestamp;
}

header TransportFilterInformation_h { //Egress to ingress only
    bit<8> ipNextProtocol;
    bit<16> srcPort;
    bit<16> dstPort;
}

header OutputRoutingInformation_h {
    bit<32> routingHashA;
    bit<32> routingHashB;
}

header PPPoE_h {
    bit<4> version;
    bit<4> type;
    bit<8> code;
    bit<16> sess_id;
    bit<16> len;
    bit<8> flag;
    bit<8> address;
    bit<8> ctrl;
    bit<16> nextProto;
}

struct IpHeaderStack_s {
    Ipv4_h ipv4;
    Ipv4Addresses_h ipv4Addresses;
    Ipv6_h ipv6;
    Ipv6Addresses_h ipv6Addresses;
    Ipv6Ext_h ipv6Ext;
    Byte20_h ipOptions5Bl;
    Byte8_h ipOptions2Bl1;
    Byte8_h ipOptions2Bl2;
    Byte4_h ipOptions1Bl;
    KeyBytes_h keybytes;
}

struct ParsingHeaderStack {
    Bridging_h bridging;
    OutputRoutingInformation_h outputRouting;
    Byte64_h skipExtra;
    Byte64_h s64ISKIP; Byte32_h s32ISKIP; Byte16_h s16ISKIP; Byte8_h s8ISKIP; Byte4_h s4ISKIP; Byte2_h s2ISKIP; Byte1_h s1ISKIP;
    Ethernet_h ethernet;



    Vlan_h vlan0;
    Vlan_h vlan1;
    Vlan_h vlan2;
    Vlan_h vlan3;

    PPPoE_h pppOe;



    Mpls_h mpls0;
    Mpls_h mpls1;
    Mpls_h mpls2;
    Mpls_h mpls3;
    Mpls_h mpls4;
    Mpls_h mpls5;

    Byte4_h mplsZeroBlob;
    IpHeaderStack_s ip;
    Byte1_h dummyBlob;
}






struct HeadersInfo_s {
    bit<8> routeState;
    bit<8> nextProtocol;
    bit<8> ipNextProtocol;
    bit<16> srcPort;
    bit<16> dstPort;
}

struct FlowInfo_s {
    bit<32> src;
    bit<32> dst;
};

struct RouteHashes_s {
    bit<32> hash1;
    bit<32> hash2;
    bit<32> hash3;
};

struct EgressHeadersInfo_s {
    bit<8> routeState;
    bit<8> nextProtocol;
}

struct StandardEgressParsingMetadata {
    EgressHeadersInfo_s headersInfo;
}

struct StandardIngressParsingMetadata {
    port_metadata_t portProperties;
    HeadersInfo_s headersInfo;
    MirrorId_t mirrorSession;
}

header PacketSummary_h {
    bit<48> timestamp;
    bit<32> sourceId;
}
# 8 "./ParserDesign.p4h" 2
# 43 "./ParserDesign.p4h"
parser IngressParser( packet_in pkt,
  out ParsingHeaderStack headers,
  out StandardIngressParsingMetadata meta,
  out ingress_intrinsic_metadata_t intrinsic)
{
    state start {
        meta.headersInfo = {RT_UNSET, BPT_UNKNOWN, 0, 0, 0};
        meta.mirrorSession = 0;
        pkt.extract(intrinsic);
        meta.portProperties = port_metadata_unpack<port_metadata_t>(pkt);
        headers.bridging.offset = 0;
        Bridging_h blook = pkt.lookahead<Bridging_h>();
        transition select(meta.portProperties.protocol_key, blook.state, blook.protocol) {
            (IPT_ETHERNET, _, _) : parseEthernet;
            (IPT_IP, _, 0x40 &&& 0xF0) : parseIpv4;
            (IPT_IP, _, 0x60 &&& 0xF0) : parseIpv6;
            (IPT_BRIDGED, ST_UNFINISHED, _) : bridged;
            (IPT_BRIDGED, _, BPT_IP4) : bridged4;
            (IPT_BRIDGED, _, BPT_IP6) : bridged6;
            (IPT_BRIDGED, _, _) : bridgedOther;
            (IPT_DROP, _, _) : setDrop;
            default : reject;
        }
    }

    state setDrop {
        meta.headersInfo.nextProtocol = BPT_UNKNOWN; meta.headersInfo.routeState = RT_DROP; transition accept;
    }

    state bridged {
        pkt.extract(headers.bridging);
        transition select(headers.bridging.offset, headers.bridging.protocol) {
            (_, BPT_UNKNOWN) : cpuRoutedData;//No sense wasting time parsing to an unknown, so shortcut it here

            (0xC0 &&& 0xC0, _) : cpuRoutedData;
            (0x80 &&& 0x80, _) : parseExtra;



            (0x40 &&& 0x40, _) : parse64ISKIP;
            (0x20 &&& 0x20, _) : parse32ISKIP;
            (0x18 &&& 0x18, _) : parse24ISKIP;
            (0x10 &&& 0x18, _) : parse16ISKIP;
            (0x08 &&& 0x18, _) : parse8ISKIP;
            (0, _) : skipFinishedISKIP;
            default : parseSinglesISKIP;
        }
    }

    state parseExtra {
        pkt.extract(headers.skipExtra);
        transition parse64ISKIP;
    }


    state parse64ISKIP { pkt.extract(headers.s64ISKIP); transition select(headers.bridging.offset) { 0x20 &&& 0x20 : parse32ISKIP; 0x18 &&& 0x18 : parse24ISKIP; 0x10 &&& 0x18 : parse16ISKIP; 0x08 &&& 0x18 : parse8ISKIP; default : parseSinglesISKIP; } } state parse32ISKIP { pkt.extract(headers.s32ISKIP); transition select(headers.bridging.offset) { 0x18 &&& 0x18 : parse24ISKIP; 0x10 &&& 0x18 : parse16ISKIP; 0x08 &&& 0x18 : parse8ISKIP; 0x00 &&& 0x07 : skipFinishedISKIP; default : parseSinglesISKIP; } } state parse24ISKIP { pkt.extract(headers.s16ISKIP); pkt.extract(headers.s8ISKIP); transition select(headers.bridging.offset) { 0x00 &&& 0x07 : skipFinishedISKIP; default : parseSinglesISKIP; } } state parse16ISKIP { pkt.extract(headers.s16ISKIP); transition select(headers.bridging.offset) { 0x00 &&& 0x07 : skipFinishedISKIP; default : parseSinglesISKIP; } } state parse8ISKIP { pkt.extract(headers.s8ISKIP); transition select(headers.bridging.offset) { 0x00 &&& 0x07 : skipFinishedISKIP; default : parseSinglesISKIP; } } state parseSinglesISKIP { transition select(headers.bridging.offset) { 0x07 &&& 0x07 : parse7ISKIP; 0x06 &&& 0x07 : parse6ISKIP; 0x05 &&& 0x07 : parse5ISKIP; 0x04 &&& 0x07 : parse4ISKIP; 0x03 &&& 0x07 : parse3ISKIP; 0x02 &&& 0x07 : parse2ISKIP; 0x01 &&& 0x07 : parse1ISKIP; 0x00 &&& 0x07 : skipFinishedISKIP; } } state parse7ISKIP { pkt.extract(headers.s4ISKIP); pkt.extract(headers.s2ISKIP); pkt.extract(headers.s1ISKIP); transition skipFinishedISKIP; } state parse6ISKIP { pkt.extract(headers.s4ISKIP); pkt.extract(headers.s2ISKIP); transition skipFinishedISKIP; } state parse5ISKIP { pkt.extract(headers.s4ISKIP); pkt.extract(headers.s1ISKIP); transition skipFinishedISKIP; } state parse4ISKIP { pkt.extract(headers.s4ISKIP); transition skipFinishedISKIP; } state parse3ISKIP { pkt.extract(headers.s2ISKIP); pkt.extract(headers.s1ISKIP); transition skipFinishedISKIP; } state parse2ISKIP { pkt.extract(headers.s2ISKIP); transition skipFinishedISKIP; } state parse1ISKIP { pkt.extract(headers.s1ISKIP); transition skipFinishedISKIP; }

    state skipFinishedISKIP { transition select(headers.bridging.protocol) { BPT_VLAN : parseVlan; BPT_MPLS : parseMpls; BPT_ETHERNET : parseEthernet; BPT_IP4 : parseIpv4; BPT_IP6 : parseIpv6; default : accept; } } state parseEthernet { pkt.extract(headers.ethernet); transition select(headers.ethernet.type) { 0x0800 : parseIpv4; 0x86DD : parseIpv6; 0x8847 : parseMpls; 0x8848 : parseMpls; 0x8100 &&& 0xEFFF : parseVlan; 0x9200 &&& 0xFEFF : parseVlan; 0x88A8 : parseVlan; 0x8864 : parsePPPoE; default : cpuRoutedData; } } state parseVlan { pkt.extract(headers.vlan0); transition select(headers.vlan0.type) { 0x0800 : parseIpv4; 0x86DD : parseIpv6; 0x8847 : parseMpls; 0x8848 : parseMpls; 0x8100 &&& 0xEFFF : parseVlan2; 0x9200 &&& 0xFEFF : parseVlan2; 0x88A8 : parseVlan2; 0x8864 : parsePPPoE; default : cpuRoutedData; } } state parseVlan2 { pkt.extract(headers.vlan1); transition select(headers.vlan1.type) { 0x0800 : parseIpv4; 0x86DD : parseIpv6; 0x8847 : parseMpls; 0x8848 : parseMpls; 0x8100 &&& 0xEFFF : parseVlan3; 0x9200 &&& 0xFEFF : parseVlan3; 0x88A8 : parseVlan3; 0x8864 : parsePPPoE; default : cpuRoutedData; } } state parseVlan3 { pkt.extract(headers.vlan2); transition select(headers.vlan2.type) { 0x0800 : parseIpv4; 0x86DD : parseIpv6; 0x8847 : parseMpls; 0x8848 : parseMpls; 0x8100 &&& 0xEFFF : parseVlan4; 0x9200 &&& 0xFEFF : parseVlan4; 0x88A8 : parseVlan4; 0x8864 : parsePPPoE; default : cpuRoutedData; } } state parseVlan4 { pkt.extract(headers.vlan3); transition select(headers.vlan3.type) { 0x0800 : parseIpv4; 0x86DD : parseIpv6; 0x8847 : parseMpls; 0x8848 : parseMpls; 0x8100 &&& 0xEFFF : parseManyVlan; 0x9200 &&& 0xFEFF : parseManyVlan; 0x88A8 : parseManyVlan; 0x8864 : parsePPPoE; default : cpuRoutedData; } } state parseManyVlan { meta.headersInfo.nextProtocol = BPT_VLAN; meta.headersInfo.routeState = RT_CONTINUE; transition accept; } state parseMpls { pkt.extract(headers.mpls0); MplsStack_h mplsStack = pkt.lookahead<MplsStack_h>(); transition select(headers.mpls0.bos,mplsStack.zcheck,mplsStack.bos1,mplsStack.bos2) { (1,_,_,_) : mplsDone; (0,_,1,_) : mplsSingleA; (0,_,0,1) : mplsDoubleA; default : mplsTriplePlus; } } state mplsSingleA { pkt.extract(headers.mpls1); IdSequence_h idSequence = pkt.lookahead<IdSequence_h>(); transition select(idSequence.ipVersion,idSequence.ip4hdrlen,idSequence.ip4lenbits,idSequence.ip6lenbits) { (4,5,0x0 &&& 0xE,_) : parseIpv4; (4, 0x6 &&& 0xE,0x0 &&& 0xE,_) : parseIpv4; (4, 0x8 &&& 0x8,0x0 &&& 0xE,_) : parseIpv4; (6, _, _, 0x0 &&& 0xE) : parseIpv6; default : testForEthernet; } } state mplsDoubleA { pkt.extract(headers.mpls1); pkt.extract(headers.mpls2); IdSequence_h idSequence = pkt.lookahead<IdSequence_h>(); transition select(idSequence.ipVersion,idSequence.ip4hdrlen,idSequence.ip4lenbits,idSequence.ip6lenbits) { (4,5,0x0 &&& 0xE,_) : parseIpv4; (4, 0x6 &&& 0xE,0x0 &&& 0xE,_) : parseIpv4; (4, 0x8 &&& 0x8,0x0 &&& 0xE,_) : parseIpv4; (6, _, _, 0x0 &&& 0xE) : parseIpv6; default : testForEthernet; } } state mplsTriplePlus { pkt.extract(headers.mpls1); pkt.extract(headers.mpls2); pkt.extract(headers.mpls3); MplsStack_h mplsStack = pkt.lookahead<MplsStack_h>(); transition select(headers.mpls3.bos,mplsStack.zcheck,mplsStack.bos1,mplsStack.bos2) { (1,_,_,_) : mplsDone; (0,_,1,_) : mplsSingleB; (0,_,0,1) : mplsDoubleB; default : mplsTooMany; } } state mplsSingleB { pkt.extract(headers.mpls4); IdSequence_h idSequence = pkt.lookahead<IdSequence_h>(); transition select(idSequence.ipVersion,idSequence.ip4hdrlen,idSequence.ip4lenbits,idSequence.ip6lenbits) { (4,5,0x0 &&& 0xE,_) : parseIpv4; (4, 0x6 &&& 0xE,0x0 &&& 0xE,_) : parseIpv4; (4, 0x8 &&& 0x8,0x0 &&& 0xE,_) : parseIpv4; (6, _, _, 0x0 &&& 0xE) : parseIpv6; default : testForEthernet; } } state mplsDoubleB { pkt.extract(headers.mpls4); pkt.extract(headers.mpls5); IdSequence_h idSequence = pkt.lookahead<IdSequence_h>(); transition select(idSequence.ipVersion,idSequence.ip4hdrlen,idSequence.ip4lenbits,idSequence.ip6lenbits) { (4,5,0x0 &&& 0xE,_) : parseIpv4; (4, 0x6 &&& 0xE,0x0 &&& 0xE,_) : parseIpv4; (4, 0x8 &&& 0x8,0x0 &&& 0xE,_) : parseIpv4; (6, _, _, 0x0 &&& 0xE) : parseIpv6; default : testForEthernet; } } state mplsDone { IdSequence_h idSequence = pkt.lookahead<IdSequence_h>(); transition select(idSequence.ipVersion,idSequence.ip4hdrlen,idSequence.ip4lenbits,idSequence.ip6lenbits) { (4,5,0x0 &&& 0xE,_) : parseIpv4; (4, 0x6 &&& 0xE,0x0 &&& 0xE,_) : parseIpv4; (4, 0x8 &&& 0x8,0x0 &&& 0xE,_) : parseIpv4; (6, _, _, 0x0 &&& 0xE) : parseIpv6; default : testForEthernet; } } state testForEthernet { EthernetTestHeader_h test = pkt.lookahead<EthernetTestHeader_h>(); transition select(test.ethType,test.ethType2) { (0x0800, _) : possibleEthernet; (0x86DD, _) : possibleEthernet; (0x8847, _) : possibleEthernet; (0x8848, _) : possibleEthernet; (0x8100 &&& 0xEFFF, _) : possibleEthernet; (0x9200 &&& 0xFEFF, _) : possibleEthernet; (0x88A8, _) : possibleEthernet; (0x88E7, _) : possibleEthernet; (0x8864, _) : possibleEthernet; (0x88E5, _) : possibleEthernet; (_, 0x0800) : extCwEth; (_, 0x86DD) : extCwEth; (_, 0x8847) : extCwEth; (_, 0x8848) : extCwEth; (_, 0x8100 &&& 0xEFFF) : extCwEth; (_, 0x9200 &&& 0xFEFF) : extCwEth; (_, 0x88A8) : extCwEth; (_, 0x88E7) : extCwEth; (_, 0x8864) : extCwEth; (_, 0x88E5) : extCwEth; default : cpuRoutedData; } } state extCwEth { pkt.extract(headers.mplsZeroBlob); transition possibleEthernet; } state mplsTooMany { pkt.extract(headers.mpls4); pkt.extract(headers.mpls5); meta.headersInfo.nextProtocol = BPT_MPLS; meta.headersInfo.routeState = RT_CONTINUE; transition accept; } state possibleEthernet { meta.headersInfo.nextProtocol = BPT_ETHERNET; meta.headersInfo.routeState = RT_CONTINUE; transition accept; } state parseIpv6 { pkt.extract(headers.ip.ipv6); pkt.extract(headers.ip.ipv6Addresses); transition select(headers.ip.ipv6.nextHeader) { 0 : parseIpv6Extension; 43 : parseIpv6Extension; 44 : cpuRoutedData; 60 : parseIpv6Extension; 135 : parseIpv6Extension; default : parseKey; } } state cpuRoutedData { meta.headersInfo.nextProtocol = BPT_UNKNOWN; meta.headersInfo.routeState = RT_TO_CPU; transition accept; } state ipFragment { meta.headersInfo.nextProtocol = BPT_UNKNOWN; meta.headersInfo.routeState = RT_IP_DEFRAG; transition accept; } state parseKey { pkt.extract(headers.ip.keybytes); transition accept; } state parseIpv4 { pkt.extract(headers.ip.ipv4); pkt.extract(headers.ip.ipv4Addresses); transition select(headers.ip.ipv4.moreFrags, headers.ip.ipv4.fragmentOffset, headers.ip.ipv4.hdrlen, headers.ip.ipv4.protocol) { (0,0,6,_) : parseOneOption; (0,0,7,_) : parseTwoOptions; (0,0,8,_) : parseThreeOptions; (0,0,9,_) : parseFourOptions; (0,0,10,_) : parseFiveOptions; (0,0,0x8 &&& 0x8, _) : parseFivePlusOptions; (0,0,5,_) : parseKey; default : ipFragment; } } state parseOneOption { pkt.extract(headers.ip.ipOptions1Bl); transition parseKey; } state parseTwoOptions { pkt.extract(headers.ip.ipOptions2Bl1); transition parseKey; } state parseThreeOptions { pkt.extract(headers.ip.ipOptions2Bl1); pkt.extract(headers.ip.ipOptions1Bl); transition parseKey; } state parseFourOptions { pkt.extract(headers.ip.ipOptions2Bl1); pkt.extract(headers.ip.ipOptions2Bl2); transition parseKey; } state parseFiveOptions { pkt.extract(headers.ip.ipOptions2Bl1); pkt.extract(headers.ip.ipOptions2Bl2); pkt.extract(headers.ip.ipOptions1Bl); transition parseKey; } state parseFivePlusOptions { pkt.extract(headers.ip.ipOptions5Bl); transition select(headers.ip.ipv4.hdrlen) { 11 : parseOneOption; 12 : parseTwoOptions; 13 : parseThreeOptions; 14 : parseFourOptions; 15 : parseFiveOptions; default : reject; } } state parseIpv6Extension { pkt.extract(headers.ip.ipv6Ext); transition select(headers.ip.ipv6Ext.length, headers.ip.ipv6Ext.protocol) { (_, 0) : cpuRoutedData; (_, 43) : cpuRoutedData; (_, 44) : ipFragment; (_, 60) : cpuRoutedData; (_, 135) : cpuRoutedData; (0, _) : parseKey; (1, _) : parseOneExtDW; (2, _) : parseTwoExtDW; (3, _) : parseThreeExtDW; (4, _) : parseFourExtDW; (5, _) : parseFiveExtDW; default : cpuRoutedData; } } state parseOneExtDW { pkt.extract(headers.ip.ipOptions2Bl1); transition parseKey; } state parseTwoExtDW { pkt.extract(headers.ip.ipOptions2Bl1); pkt.extract(headers.ip.ipOptions2Bl2); transition parseKey; } state parseThreeExtDW { pkt.extract(headers.ip.ipOptions5Bl); pkt.extract(headers.ip.ipOptions1Bl); transition parseKey; } state parseFourExtDW { pkt.extract(headers.ip.ipOptions5Bl); pkt.extract(headers.ip.ipOptions2Bl1); pkt.extract(headers.ip.ipOptions1Bl); transition parseKey; } state parseFiveExtDW { pkt.extract(headers.ip.ipOptions5Bl); pkt.extract(headers.ip.ipOptions2Bl1); pkt.extract(headers.ip.ipOptions2Bl2); pkt.extract(headers.ip.ipOptions1Bl); transition parseKey; } state parsePPPoE { pkt.extract(headers.pppOe); transition select(headers.pppOe.nextProto) { 0x0021 : parseIpv4; 0x0057 : parseIpv6; 0x0281 &&& 0xFFFD : parseMpls; default : cpuRoutedData; } }

    state bridged4 { //Externally processed, filter information provided
        pkt.extract(headers.bridging);
        pkt.extract(headers.ip.ipv4Addresses);
        TransportFilterInformation_h tfi = pkt.lookahead<TransportFilterInformation_h>();
        meta.headersInfo.ipNextProtocol = tfi.ipNextProtocol;
        meta.headersInfo.srcPort = tfi.srcPort;
        meta.headersInfo.dstPort = tfi.dstPort;
        pkt.advance(40);
        transition accept;
    }

    state bridged6 { //Externally processed, filter information provided
        pkt.extract(headers.bridging);
        pkt.extract(headers.ip.ipv6Addresses);
        TransportFilterInformation_h tfi = pkt.lookahead<TransportFilterInformation_h>();
        meta.headersInfo.ipNextProtocol = tfi.ipNextProtocol;
        meta.headersInfo.srcPort = tfi.srcPort;
        meta.headersInfo.dstPort = tfi.dstPort;
        pkt.advance(40);
        transition accept;
    }

    state bridgedOther {
        pkt.extract(headers.bridging);
        transition accept;
    }
}

parser EgressParser( packet_in pkt,
  out ParsingHeaderStack headers,
  out StandardEgressParsingMetadata meta,
  out egress_intrinsic_metadata_t intrinsic)
{
    state start {
        meta.headersInfo = {RT_UNSET,BPT_UNKNOWN};
        pkt.extract(intrinsic);
        Bridging_h bridge = pkt.lookahead<Bridging_h>();
        transition select(bridge.offset,bridge.protocol,bridge.state,bridge.routingType) {
            (0,0,0,_) : accept; //No processing to do for mirrored packets, so we're done now
            (0x00 &&& 0x80, _, ST_UNFINISHED, _) : bridgedData;
            (_, _, _, RT_DONE) : getRoutingInfo;
            default : accept; //No processing to be done here
        }
    }

    state bridgedData { //We should never see offset 0 here, so assume non-zero
        pkt.extract(headers.bridging);
        transition select(headers.bridging.offset,headers.bridging.protocol,headers.bridging.state) {
            (0x40 &&& 0xC0, _, ST_UNFINISHED) : parse64ISKIP;
            (0x20 &&& 0xE0, _, ST_UNFINISHED) : parse32ISKIP;
            (0x18 &&& 0xF8, _, ST_UNFINISHED) : parse24ISKIP;
            (0x10 &&& 0xF8, _, ST_UNFINISHED) : parse16ISKIP;
            (0x08 &&& 0xF8, _, ST_UNFINISHED) : parse8ISKIP;
            default : parseSinglesISKIP;
        }
    }
    state getRoutingInfo {
        pkt.extract(headers.bridging);
        pkt.extract(headers.outputRouting);
        transition accept;
    }

    state parse64ISKIP { pkt.extract(headers.s64ISKIP); transition select(headers.bridging.offset) { 0x20 &&& 0x20 : parse32ISKIP; 0x18 &&& 0x18 : parse24ISKIP; 0x10 &&& 0x18 : parse16ISKIP; 0x08 &&& 0x18 : parse8ISKIP; default : parseSinglesISKIP; } } state parse32ISKIP { pkt.extract(headers.s32ISKIP); transition select(headers.bridging.offset) { 0x18 &&& 0x18 : parse24ISKIP; 0x10 &&& 0x18 : parse16ISKIP; 0x08 &&& 0x18 : parse8ISKIP; 0x00 &&& 0x07 : skipFinishedISKIP; default : parseSinglesISKIP; } } state parse24ISKIP { pkt.extract(headers.s16ISKIP); pkt.extract(headers.s8ISKIP); transition select(headers.bridging.offset) { 0x00 &&& 0x07 : skipFinishedISKIP; default : parseSinglesISKIP; } } state parse16ISKIP { pkt.extract(headers.s16ISKIP); transition select(headers.bridging.offset) { 0x00 &&& 0x07 : skipFinishedISKIP; default : parseSinglesISKIP; } } state parse8ISKIP { pkt.extract(headers.s8ISKIP); transition select(headers.bridging.offset) { 0x00 &&& 0x07 : skipFinishedISKIP; default : parseSinglesISKIP; } } state parseSinglesISKIP { transition select(headers.bridging.offset) { 0x07 &&& 0x07 : parse7ISKIP; 0x06 &&& 0x07 : parse6ISKIP; 0x05 &&& 0x07 : parse5ISKIP; 0x04 &&& 0x07 : parse4ISKIP; 0x03 &&& 0x07 : parse3ISKIP; 0x02 &&& 0x07 : parse2ISKIP; 0x01 &&& 0x07 : parse1ISKIP; 0x00 &&& 0x07 : skipFinishedISKIP; } } state parse7ISKIP { pkt.extract(headers.s4ISKIP); pkt.extract(headers.s2ISKIP); pkt.extract(headers.s1ISKIP); transition skipFinishedISKIP; } state parse6ISKIP { pkt.extract(headers.s4ISKIP); pkt.extract(headers.s2ISKIP); transition skipFinishedISKIP; } state parse5ISKIP { pkt.extract(headers.s4ISKIP); pkt.extract(headers.s1ISKIP); transition skipFinishedISKIP; } state parse4ISKIP { pkt.extract(headers.s4ISKIP); transition skipFinishedISKIP; } state parse3ISKIP { pkt.extract(headers.s2ISKIP); pkt.extract(headers.s1ISKIP); transition skipFinishedISKIP; } state parse2ISKIP { pkt.extract(headers.s2ISKIP); transition skipFinishedISKIP; } state parse1ISKIP { pkt.extract(headers.s1ISKIP); transition skipFinishedISKIP; }

    state skipFinishedISKIP {
        transition select(headers.bridging.protocol) {
            BPT_VLAN : parseVlan;
            BPT_MPLS : parseMpls;
            BPT_ETHERNET : parseEthernet;
            default : accept;
        }
    }
    state parseEthernet {
        pkt.extract(headers.ethernet);
        transition select(headers.ethernet.type) {
            0x0800 : parseIpv4; 0x86DD : parseIpv6; 0x8847 : parseMpls; 0x8848 : parseMpls; 0x8100 &&& 0xEFFF : parseVlan; 0x9200 &&& 0xFEFF : parseVlan; 0x88A8 : parseVlan; 0x8864 : parsePPPoE;
            default : cpuRoutedData;
        }
    }
    state parseVlan { pkt.extract(headers.vlan0); transition select(headers.vlan0.type) { 0x0800 : parseIpv4; 0x86DD : parseIpv6; 0x8847 : parseMpls; 0x8848 : parseMpls; 0x8100 &&& 0xEFFF : parseVlan2; 0x9200 &&& 0xFEFF : parseVlan2; 0x88A8 : parseVlan2; 0x8864 : parsePPPoE; default : cpuRoutedData; } } state parseVlan2 { pkt.extract(headers.vlan1); transition select(headers.vlan1.type) { 0x0800 : parseIpv4; 0x86DD : parseIpv6; 0x8847 : parseMpls; 0x8848 : parseMpls; 0x8100 &&& 0xEFFF : parseVlan3; 0x9200 &&& 0xFEFF : parseVlan3; 0x88A8 : parseVlan3; 0x8864 : parsePPPoE; default : cpuRoutedData; } } state parseVlan3 { pkt.extract(headers.vlan2); transition select(headers.vlan2.type) { 0x0800 : parseIpv4; 0x86DD : parseIpv6; 0x8847 : parseMpls; 0x8848 : parseMpls; 0x8100 &&& 0xEFFF : parseVlan4; 0x9200 &&& 0xFEFF : parseVlan4; 0x88A8 : parseVlan4; 0x8864 : parsePPPoE; default : cpuRoutedData; } } state parseVlan4 { pkt.extract(headers.vlan3); transition select(headers.vlan3.type) { 0x0800 : parseIpv4; 0x86DD : parseIpv6; 0x8847 : parseMpls; 0x8848 : parseMpls; 0x8100 &&& 0xEFFF : parseManyVlan; 0x9200 &&& 0xFEFF : parseManyVlan; 0x88A8 : parseManyVlan; 0x8864 : parsePPPoE; default : cpuRoutedData; } }
    state parseManyVlan {
        meta.headersInfo.nextProtocol = BPT_VLAN; meta.headersInfo.routeState = RT_CONTINUE; transition accept;
    }
    state parseMpls { pkt.extract(headers.mpls0); MplsStack_h mplsStack = pkt.lookahead<MplsStack_h>(); transition select(headers.mpls0.bos,mplsStack.zcheck,mplsStack.bos1,mplsStack.bos2) { (1,_,_,_) : mplsDone; (0,_,1,_) : mplsSingleA; (0,_,0,1) : mplsDoubleA; default : mplsTriplePlus; } } state mplsSingleA { pkt.extract(headers.mpls1); IdSequence_h idSequence = pkt.lookahead<IdSequence_h>(); transition select(idSequence.ipVersion,idSequence.ip4hdrlen,idSequence.ip4lenbits,idSequence.ip6lenbits) { (4,5,0x0 &&& 0xE,_) : parseIpv4; (4, 0x6 &&& 0xE,0x0 &&& 0xE,_) : parseIpv4; (4, 0x8 &&& 0x8,0x0 &&& 0xE,_) : parseIpv4; (6, _, _, 0x0 &&& 0xE) : parseIpv6; default : testForEthernet; } } state mplsDoubleA { pkt.extract(headers.mpls1); pkt.extract(headers.mpls2); IdSequence_h idSequence = pkt.lookahead<IdSequence_h>(); transition select(idSequence.ipVersion,idSequence.ip4hdrlen,idSequence.ip4lenbits,idSequence.ip6lenbits) { (4,5,0x0 &&& 0xE,_) : parseIpv4; (4, 0x6 &&& 0xE,0x0 &&& 0xE,_) : parseIpv4; (4, 0x8 &&& 0x8,0x0 &&& 0xE,_) : parseIpv4; (6, _, _, 0x0 &&& 0xE) : parseIpv6; default : testForEthernet; } } state mplsTriplePlus { pkt.extract(headers.mpls1); pkt.extract(headers.mpls2); pkt.extract(headers.mpls3); MplsStack_h mplsStack = pkt.lookahead<MplsStack_h>(); transition select(headers.mpls3.bos,mplsStack.zcheck,mplsStack.bos1,mplsStack.bos2) { (1,_,_,_) : mplsDone; (0,_,1,_) : mplsSingleB; (0,_,0,1) : mplsDoubleB; default : mplsTooMany; } } state mplsSingleB { pkt.extract(headers.mpls4); IdSequence_h idSequence = pkt.lookahead<IdSequence_h>(); transition select(idSequence.ipVersion,idSequence.ip4hdrlen,idSequence.ip4lenbits,idSequence.ip6lenbits) { (4,5,0x0 &&& 0xE,_) : parseIpv4; (4, 0x6 &&& 0xE,0x0 &&& 0xE,_) : parseIpv4; (4, 0x8 &&& 0x8,0x0 &&& 0xE,_) : parseIpv4; (6, _, _, 0x0 &&& 0xE) : parseIpv6; default : testForEthernet; } } state mplsDoubleB { pkt.extract(headers.mpls4); pkt.extract(headers.mpls5); IdSequence_h idSequence = pkt.lookahead<IdSequence_h>(); transition select(idSequence.ipVersion,idSequence.ip4hdrlen,idSequence.ip4lenbits,idSequence.ip6lenbits) { (4,5,0x0 &&& 0xE,_) : parseIpv4; (4, 0x6 &&& 0xE,0x0 &&& 0xE,_) : parseIpv4; (4, 0x8 &&& 0x8,0x0 &&& 0xE,_) : parseIpv4; (6, _, _, 0x0 &&& 0xE) : parseIpv6; default : testForEthernet; } } state mplsDone { IdSequence_h idSequence = pkt.lookahead<IdSequence_h>(); transition select(idSequence.ipVersion,idSequence.ip4hdrlen,idSequence.ip4lenbits,idSequence.ip6lenbits) { (4,5,0x0 &&& 0xE,_) : parseIpv4; (4, 0x6 &&& 0xE,0x0 &&& 0xE,_) : parseIpv4; (4, 0x8 &&& 0x8,0x0 &&& 0xE,_) : parseIpv4; (6, _, _, 0x0 &&& 0xE) : parseIpv6; default : testForEthernet; } } state testForEthernet { EthernetTestHeader_h test = pkt.lookahead<EthernetTestHeader_h>(); transition select(test.ethType,test.ethType2) { (0x0800, _) : possibleEthernet; (0x86DD, _) : possibleEthernet; (0x8847, _) : possibleEthernet; (0x8848, _) : possibleEthernet; (0x8100 &&& 0xEFFF, _) : possibleEthernet; (0x9200 &&& 0xFEFF, _) : possibleEthernet; (0x88A8, _) : possibleEthernet; (0x88E7, _) : possibleEthernet; (0x8864, _) : possibleEthernet; (0x88E5, _) : possibleEthernet; (_, 0x0800) : extCwEth; (_, 0x86DD) : extCwEth; (_, 0x8847) : extCwEth; (_, 0x8848) : extCwEth; (_, 0x8100 &&& 0xEFFF) : extCwEth; (_, 0x9200 &&& 0xFEFF) : extCwEth; (_, 0x88A8) : extCwEth; (_, 0x88E7) : extCwEth; (_, 0x8864) : extCwEth; (_, 0x88E5) : extCwEth; default : cpuRoutedData; } } state extCwEth { pkt.extract(headers.mplsZeroBlob); transition possibleEthernet; }
    state mplsTooMany {
        pkt.extract(headers.mpls4);
        pkt.extract(headers.mpls5);
        meta.headersInfo.nextProtocol = BPT_MPLS; meta.headersInfo.routeState = RT_CONTINUE; transition accept;
    }
    state possibleEthernet {
        meta.headersInfo.nextProtocol = BPT_ETHERNET; meta.headersInfo.routeState = RT_CONTINUE; transition accept;
    }
    state parseIpv4 {
        meta.headersInfo.nextProtocol = BPT_IP4; meta.headersInfo.routeState = RT_CONTINUE; transition accept;
    }
    state parseIpv6 {
        meta.headersInfo.nextProtocol = BPT_IP4; meta.headersInfo.routeState = RT_CONTINUE; transition accept;
    }
    state cpuRoutedData {
        meta.headersInfo.nextProtocol = BPT_UNKNOWN; meta.headersInfo.routeState = RT_TO_CPU; transition accept;
    }
    state parsePPPoE { pkt.extract(headers.pppOe); transition select(headers.pppOe.nextProto) { 0x0021 : parseIpv4; 0x0057 : parseIpv6; 0x0281 &&& 0xFFFD : parseMpls; default : cpuRoutedData; } }

}
# 10 "SimpleProc.p4" 2
# 1 "./MauAndDeparser.p4h" 1



# 1 "./FilterImplementation.p4h" 1





struct RulePriorityData_s {
    bit<8> p0;
    bit<8> p1;
    bit<8> p2;
    bit<8> p3;
    bit<8> p4;
}

# 1 "./DropResolution.p4h" 1



control DropResolution(inout ingress_intrinsic_metadata_for_deparser_t dp,
    in RulePriorityData_s priorities) {
    action drop() {dp.drop_ctl = 1;}
    table resolver {
        key = {
            priorities.p0 : ternary;
            priorities.p1 : ternary;
            priorities.p2 : ternary;
            priorities.p3 : ternary;
        }
        actions = {NoAction; drop;}
        default_action = NoAction();
        size = 1024;
        const entries = {
            (255,_,_,_) : drop();
            (_,255,_,_) : drop();
            (_,_,255,_) : drop();
            (_,_,_,255) : drop();
            (254,_,_,_) : NoAction();
            (_,254,_,_) : NoAction();
            (_,_,254,_) : NoAction();
            (_,_,_,254) : NoAction();
            (253,_,_,_) : drop();
            (_,253,_,_) : drop();
            (_,_,253,_) : drop();
            (_,_,_,253) : drop();
            (252,_,_,_) : NoAction();
            (_,252,_,_) : NoAction();
            (_,_,252,_) : NoAction();
            (_,_,_,252) : NoAction();
            (251,_,_,_) : drop();
            (_,251,_,_) : drop();
            (_,_,251,_) : drop();
            (_,_,_,251) : drop();
            (250,_,_,_) : NoAction();
            (_,250,_,_) : NoAction();
            (_,_,250,_) : NoAction();
            (_,_,_,250) : NoAction();
            (249,_,_,_) : drop();
            (_,249,_,_) : drop();
            (_,_,249,_) : drop();
            (_,_,_,249) : drop();
            (248,_,_,_) : NoAction();
            (_,248,_,_) : NoAction();
            (_,_,248,_) : NoAction();
            (_,_,_,248) : NoAction();
            (247,_,_,_) : drop();
            (_,247,_,_) : drop();
            (_,_,247,_) : drop();
            (_,_,_,247) : drop();
            (246,_,_,_) : NoAction();
            (_,246,_,_) : NoAction();
            (_,_,246,_) : NoAction();
            (_,_,_,246) : NoAction();
            (245,_,_,_) : drop();
            (_,245,_,_) : drop();
            (_,_,245,_) : drop();
            (_,_,_,245) : drop();
            (244,_,_,_) : NoAction();
            (_,244,_,_) : NoAction();
            (_,_,244,_) : NoAction();
            (_,_,_,244) : NoAction();
            (243,_,_,_) : drop();
            (_,243,_,_) : drop();
            (_,_,243,_) : drop();
            (_,_,_,243) : drop();
            (242,_,_,_) : NoAction();
            (_,242,_,_) : NoAction();
            (_,_,242,_) : NoAction();
            (_,_,_,242) : NoAction();
            (241,_,_,_) : drop();
            (_,241,_,_) : drop();
            (_,_,241,_) : drop();
            (_,_,_,241) : drop();
            (240,_,_,_) : NoAction();
            (_,240,_,_) : NoAction();
            (_,_,240,_) : NoAction();
            (_,_,_,240) : NoAction();
            (239,_,_,_) : drop();
            (_,239,_,_) : drop();
            (_,_,239,_) : drop();
            (_,_,_,239) : drop();
            (238,_,_,_) : NoAction();
            (_,238,_,_) : NoAction();
            (_,_,238,_) : NoAction();
            (_,_,_,238) : NoAction();
            (237,_,_,_) : drop();
            (_,237,_,_) : drop();
            (_,_,237,_) : drop();
            (_,_,_,237) : drop();
            (236,_,_,_) : NoAction();
            (_,236,_,_) : NoAction();
            (_,_,236,_) : NoAction();
            (_,_,_,236) : NoAction();
            (235,_,_,_) : drop();
            (_,235,_,_) : drop();
            (_,_,235,_) : drop();
            (_,_,_,235) : drop();
            (234,_,_,_) : NoAction();
            (_,234,_,_) : NoAction();
            (_,_,234,_) : NoAction();
            (_,_,_,234) : NoAction();
            (233,_,_,_) : drop();
            (_,233,_,_) : drop();
            (_,_,233,_) : drop();
            (_,_,_,233) : drop();
            (232,_,_,_) : NoAction();
            (_,232,_,_) : NoAction();
            (_,_,232,_) : NoAction();
            (_,_,_,232) : NoAction();
            (231,_,_,_) : drop();
            (_,231,_,_) : drop();
            (_,_,231,_) : drop();
            (_,_,_,231) : drop();
            (230,_,_,_) : NoAction();
            (_,230,_,_) : NoAction();
            (_,_,230,_) : NoAction();
            (_,_,_,230) : NoAction();
            (229,_,_,_) : drop();
            (_,229,_,_) : drop();
            (_,_,229,_) : drop();
            (_,_,_,229) : drop();
            (228,_,_,_) : NoAction();
            (_,228,_,_) : NoAction();
            (_,_,228,_) : NoAction();
            (_,_,_,228) : NoAction();
            (227,_,_,_) : drop();
            (_,227,_,_) : drop();
            (_,_,227,_) : drop();
            (_,_,_,227) : drop();
            (226,_,_,_) : NoAction();
            (_,226,_,_) : NoAction();
            (_,_,226,_) : NoAction();
            (_,_,_,226) : NoAction();
            (225,_,_,_) : drop();
            (_,225,_,_) : drop();
            (_,_,225,_) : drop();
            (_,_,_,225) : drop();
            (224,_,_,_) : NoAction();
            (_,224,_,_) : NoAction();
            (_,_,224,_) : NoAction();
            (_,_,_,224) : NoAction();
            (223,_,_,_) : drop();
            (_,223,_,_) : drop();
            (_,_,223,_) : drop();
            (_,_,_,223) : drop();
            (222,_,_,_) : NoAction();
            (_,222,_,_) : NoAction();
            (_,_,222,_) : NoAction();
            (_,_,_,222) : NoAction();
            (221,_,_,_) : drop();
            (_,221,_,_) : drop();
            (_,_,221,_) : drop();
            (_,_,_,221) : drop();
            (220,_,_,_) : NoAction();
            (_,220,_,_) : NoAction();
            (_,_,220,_) : NoAction();
            (_,_,_,220) : NoAction();
            (219,_,_,_) : drop();
            (_,219,_,_) : drop();
            (_,_,219,_) : drop();
            (_,_,_,219) : drop();
            (218,_,_,_) : NoAction();
            (_,218,_,_) : NoAction();
            (_,_,218,_) : NoAction();
            (_,_,_,218) : NoAction();
            (217,_,_,_) : drop();
            (_,217,_,_) : drop();
            (_,_,217,_) : drop();
            (_,_,_,217) : drop();
            (216,_,_,_) : NoAction();
            (_,216,_,_) : NoAction();
            (_,_,216,_) : NoAction();
            (_,_,_,216) : NoAction();
            (215,_,_,_) : drop();
            (_,215,_,_) : drop();
            (_,_,215,_) : drop();
            (_,_,_,215) : drop();
            (214,_,_,_) : NoAction();
            (_,214,_,_) : NoAction();
            (_,_,214,_) : NoAction();
            (_,_,_,214) : NoAction();
            (213,_,_,_) : drop();
            (_,213,_,_) : drop();
            (_,_,213,_) : drop();
            (_,_,_,213) : drop();
            (212,_,_,_) : NoAction();
            (_,212,_,_) : NoAction();
            (_,_,212,_) : NoAction();
            (_,_,_,212) : NoAction();
            (211,_,_,_) : drop();
            (_,211,_,_) : drop();
            (_,_,211,_) : drop();
            (_,_,_,211) : drop();
            (210,_,_,_) : NoAction();
            (_,210,_,_) : NoAction();
            (_,_,210,_) : NoAction();
            (_,_,_,210) : NoAction();
            (209,_,_,_) : drop();
            (_,209,_,_) : drop();
            (_,_,209,_) : drop();
            (_,_,_,209) : drop();
            (208,_,_,_) : NoAction();
            (_,208,_,_) : NoAction();
            (_,_,208,_) : NoAction();
            (_,_,_,208) : NoAction();
            (207,_,_,_) : drop();
            (_,207,_,_) : drop();
            (_,_,207,_) : drop();
            (_,_,_,207) : drop();
            (206,_,_,_) : NoAction();
            (_,206,_,_) : NoAction();
            (_,_,206,_) : NoAction();
            (_,_,_,206) : NoAction();
            (205,_,_,_) : drop();
            (_,205,_,_) : drop();
            (_,_,205,_) : drop();
            (_,_,_,205) : drop();
            (204,_,_,_) : NoAction();
            (_,204,_,_) : NoAction();
            (_,_,204,_) : NoAction();
            (_,_,_,204) : NoAction();
            (203,_,_,_) : drop();
            (_,203,_,_) : drop();
            (_,_,203,_) : drop();
            (_,_,_,203) : drop();
            (202,_,_,_) : NoAction();
            (_,202,_,_) : NoAction();
            (_,_,202,_) : NoAction();
            (_,_,_,202) : NoAction();
            (201,_,_,_) : drop();
            (_,201,_,_) : drop();
            (_,_,201,_) : drop();
            (_,_,_,201) : drop();
            (200,_,_,_) : NoAction();
            (_,200,_,_) : NoAction();
            (_,_,200,_) : NoAction();
            (_,_,_,200) : NoAction();
            (199,_,_,_) : drop();
            (_,199,_,_) : drop();
            (_,_,199,_) : drop();
            (_,_,_,199) : drop();
            (198,_,_,_) : NoAction();
            (_,198,_,_) : NoAction();
            (_,_,198,_) : NoAction();
            (_,_,_,198) : NoAction();
            (197,_,_,_) : drop();
            (_,197,_,_) : drop();
            (_,_,197,_) : drop();
            (_,_,_,197) : drop();
            (196,_,_,_) : NoAction();
            (_,196,_,_) : NoAction();
            (_,_,196,_) : NoAction();
            (_,_,_,196) : NoAction();
            (195,_,_,_) : drop();
            (_,195,_,_) : drop();
            (_,_,195,_) : drop();
            (_,_,_,195) : drop();
            (194,_,_,_) : NoAction();
            (_,194,_,_) : NoAction();
            (_,_,194,_) : NoAction();
            (_,_,_,194) : NoAction();
            (193,_,_,_) : drop();
            (_,193,_,_) : drop();
            (_,_,193,_) : drop();
            (_,_,_,193) : drop();
            (192,_,_,_) : NoAction();
            (_,192,_,_) : NoAction();
            (_,_,192,_) : NoAction();
            (_,_,_,192) : NoAction();
            (191,_,_,_) : drop();
            (_,191,_,_) : drop();
            (_,_,191,_) : drop();
            (_,_,_,191) : drop();
            (190,_,_,_) : NoAction();
            (_,190,_,_) : NoAction();
            (_,_,190,_) : NoAction();
            (_,_,_,190) : NoAction();
            (189,_,_,_) : drop();
            (_,189,_,_) : drop();
            (_,_,189,_) : drop();
            (_,_,_,189) : drop();
            (188,_,_,_) : NoAction();
            (_,188,_,_) : NoAction();
            (_,_,188,_) : NoAction();
            (_,_,_,188) : NoAction();
            (187,_,_,_) : drop();
            (_,187,_,_) : drop();
            (_,_,187,_) : drop();
            (_,_,_,187) : drop();
            (186,_,_,_) : NoAction();
            (_,186,_,_) : NoAction();
            (_,_,186,_) : NoAction();
            (_,_,_,186) : NoAction();
            (185,_,_,_) : drop();
            (_,185,_,_) : drop();
            (_,_,185,_) : drop();
            (_,_,_,185) : drop();
            (184,_,_,_) : NoAction();
            (_,184,_,_) : NoAction();
            (_,_,184,_) : NoAction();
            (_,_,_,184) : NoAction();
            (183,_,_,_) : drop();
            (_,183,_,_) : drop();
            (_,_,183,_) : drop();
            (_,_,_,183) : drop();
            (182,_,_,_) : NoAction();
            (_,182,_,_) : NoAction();
            (_,_,182,_) : NoAction();
            (_,_,_,182) : NoAction();
            (181,_,_,_) : drop();
            (_,181,_,_) : drop();
            (_,_,181,_) : drop();
            (_,_,_,181) : drop();
            (180,_,_,_) : NoAction();
            (_,180,_,_) : NoAction();
            (_,_,180,_) : NoAction();
            (_,_,_,180) : NoAction();
            (179,_,_,_) : drop();
            (_,179,_,_) : drop();
            (_,_,179,_) : drop();
            (_,_,_,179) : drop();
            (178,_,_,_) : NoAction();
            (_,178,_,_) : NoAction();
            (_,_,178,_) : NoAction();
            (_,_,_,178) : NoAction();
            (177,_,_,_) : drop();
            (_,177,_,_) : drop();
            (_,_,177,_) : drop();
            (_,_,_,177) : drop();
            (176,_,_,_) : NoAction();
            (_,176,_,_) : NoAction();
            (_,_,176,_) : NoAction();
            (_,_,_,176) : NoAction();
            (175,_,_,_) : drop();
            (_,175,_,_) : drop();
            (_,_,175,_) : drop();
            (_,_,_,175) : drop();
            (174,_,_,_) : NoAction();
            (_,174,_,_) : NoAction();
            (_,_,174,_) : NoAction();
            (_,_,_,174) : NoAction();
            (173,_,_,_) : drop();
            (_,173,_,_) : drop();
            (_,_,173,_) : drop();
            (_,_,_,173) : drop();
            (172,_,_,_) : NoAction();
            (_,172,_,_) : NoAction();
            (_,_,172,_) : NoAction();
            (_,_,_,172) : NoAction();
            (171,_,_,_) : drop();
            (_,171,_,_) : drop();
            (_,_,171,_) : drop();
            (_,_,_,171) : drop();
            (170,_,_,_) : NoAction();
            (_,170,_,_) : NoAction();
            (_,_,170,_) : NoAction();
            (_,_,_,170) : NoAction();
            (169,_,_,_) : drop();
            (_,169,_,_) : drop();
            (_,_,169,_) : drop();
            (_,_,_,169) : drop();
            (168,_,_,_) : NoAction();
            (_,168,_,_) : NoAction();
            (_,_,168,_) : NoAction();
            (_,_,_,168) : NoAction();
            (167,_,_,_) : drop();
            (_,167,_,_) : drop();
            (_,_,167,_) : drop();
            (_,_,_,167) : drop();
            (166,_,_,_) : NoAction();
            (_,166,_,_) : NoAction();
            (_,_,166,_) : NoAction();
            (_,_,_,166) : NoAction();
            (165,_,_,_) : drop();
            (_,165,_,_) : drop();
            (_,_,165,_) : drop();
            (_,_,_,165) : drop();
            (164,_,_,_) : NoAction();
            (_,164,_,_) : NoAction();
            (_,_,164,_) : NoAction();
            (_,_,_,164) : NoAction();
            (163,_,_,_) : drop();
            (_,163,_,_) : drop();
            (_,_,163,_) : drop();
            (_,_,_,163) : drop();
            (162,_,_,_) : NoAction();
            (_,162,_,_) : NoAction();
            (_,_,162,_) : NoAction();
            (_,_,_,162) : NoAction();
            (161,_,_,_) : drop();
            (_,161,_,_) : drop();
            (_,_,161,_) : drop();
            (_,_,_,161) : drop();
            (160,_,_,_) : NoAction();
            (_,160,_,_) : NoAction();
            (_,_,160,_) : NoAction();
            (_,_,_,160) : NoAction();
            (159,_,_,_) : drop();
            (_,159,_,_) : drop();
            (_,_,159,_) : drop();
            (_,_,_,159) : drop();
            (158,_,_,_) : NoAction();
            (_,158,_,_) : NoAction();
            (_,_,158,_) : NoAction();
            (_,_,_,158) : NoAction();
            (157,_,_,_) : drop();
            (_,157,_,_) : drop();
            (_,_,157,_) : drop();
            (_,_,_,157) : drop();
            (156,_,_,_) : NoAction();
            (_,156,_,_) : NoAction();
            (_,_,156,_) : NoAction();
            (_,_,_,156) : NoAction();
            (155,_,_,_) : drop();
            (_,155,_,_) : drop();
            (_,_,155,_) : drop();
            (_,_,_,155) : drop();
            (154,_,_,_) : NoAction();
            (_,154,_,_) : NoAction();
            (_,_,154,_) : NoAction();
            (_,_,_,154) : NoAction();
            (153,_,_,_) : drop();
            (_,153,_,_) : drop();
            (_,_,153,_) : drop();
            (_,_,_,153) : drop();
            (152,_,_,_) : NoAction();
            (_,152,_,_) : NoAction();
            (_,_,152,_) : NoAction();
            (_,_,_,152) : NoAction();
            (151,_,_,_) : drop();
            (_,151,_,_) : drop();
            (_,_,151,_) : drop();
            (_,_,_,151) : drop();
            (150,_,_,_) : NoAction();
            (_,150,_,_) : NoAction();
            (_,_,150,_) : NoAction();
            (_,_,_,150) : NoAction();
            (149,_,_,_) : drop();
            (_,149,_,_) : drop();
            (_,_,149,_) : drop();
            (_,_,_,149) : drop();
            (148,_,_,_) : NoAction();
            (_,148,_,_) : NoAction();
            (_,_,148,_) : NoAction();
            (_,_,_,148) : NoAction();
            (147,_,_,_) : drop();
            (_,147,_,_) : drop();
            (_,_,147,_) : drop();
            (_,_,_,147) : drop();
            (146,_,_,_) : NoAction();
            (_,146,_,_) : NoAction();
            (_,_,146,_) : NoAction();
            (_,_,_,146) : NoAction();
            (145,_,_,_) : drop();
            (_,145,_,_) : drop();
            (_,_,145,_) : drop();
            (_,_,_,145) : drop();
            (144,_,_,_) : NoAction();
            (_,144,_,_) : NoAction();
            (_,_,144,_) : NoAction();
            (_,_,_,144) : NoAction();
            (143,_,_,_) : drop();
            (_,143,_,_) : drop();
            (_,_,143,_) : drop();
            (_,_,_,143) : drop();
            (142,_,_,_) : NoAction();
            (_,142,_,_) : NoAction();
            (_,_,142,_) : NoAction();
            (_,_,_,142) : NoAction();
            (141,_,_,_) : drop();
            (_,141,_,_) : drop();
            (_,_,141,_) : drop();
            (_,_,_,141) : drop();
            (140,_,_,_) : NoAction();
            (_,140,_,_) : NoAction();
            (_,_,140,_) : NoAction();
            (_,_,_,140) : NoAction();
            (139,_,_,_) : drop();
            (_,139,_,_) : drop();
            (_,_,139,_) : drop();
            (_,_,_,139) : drop();
            (138,_,_,_) : NoAction();
            (_,138,_,_) : NoAction();
            (_,_,138,_) : NoAction();
            (_,_,_,138) : NoAction();
            (137,_,_,_) : drop();
            (_,137,_,_) : drop();
            (_,_,137,_) : drop();
            (_,_,_,137) : drop();
            (136,_,_,_) : NoAction();
            (_,136,_,_) : NoAction();
            (_,_,136,_) : NoAction();
            (_,_,_,136) : NoAction();
            (135,_,_,_) : drop();
            (_,135,_,_) : drop();
            (_,_,135,_) : drop();
            (_,_,_,135) : drop();
            (134,_,_,_) : NoAction();
            (_,134,_,_) : NoAction();
            (_,_,134,_) : NoAction();
            (_,_,_,134) : NoAction();
            (133,_,_,_) : drop();
            (_,133,_,_) : drop();
            (_,_,133,_) : drop();
            (_,_,_,133) : drop();
            (132,_,_,_) : NoAction();
            (_,132,_,_) : NoAction();
            (_,_,132,_) : NoAction();
            (_,_,_,132) : NoAction();
            (131,_,_,_) : drop();
            (_,131,_,_) : drop();
            (_,_,131,_) : drop();
            (_,_,_,131) : drop();
            (130,_,_,_) : NoAction();
            (_,130,_,_) : NoAction();
            (_,_,130,_) : NoAction();
            (_,_,_,130) : NoAction();
            (129,_,_,_) : drop();
            (_,129,_,_) : drop();
            (_,_,129,_) : drop();
            (_,_,_,129) : drop();
            (128,_,_,_) : NoAction();
            (_,128,_,_) : NoAction();
            (_,_,128,_) : NoAction();
            (_,_,_,128) : NoAction();
            (127,_,_,_) : drop();
            (_,127,_,_) : drop();
            (_,_,127,_) : drop();
            (_,_,_,127) : drop();
            (126,_,_,_) : NoAction();
            (_,126,_,_) : NoAction();
            (_,_,126,_) : NoAction();
            (_,_,_,126) : NoAction();
            (125,_,_,_) : drop();
            (_,125,_,_) : drop();
            (_,_,125,_) : drop();
            (_,_,_,125) : drop();
            (124,_,_,_) : NoAction();
            (_,124,_,_) : NoAction();
            (_,_,124,_) : NoAction();
            (_,_,_,124) : NoAction();
            (123,_,_,_) : drop();
            (_,123,_,_) : drop();
            (_,_,123,_) : drop();
            (_,_,_,123) : drop();
            (122,_,_,_) : NoAction();
            (_,122,_,_) : NoAction();
            (_,_,122,_) : NoAction();
            (_,_,_,122) : NoAction();
            (121,_,_,_) : drop();
            (_,121,_,_) : drop();
            (_,_,121,_) : drop();
            (_,_,_,121) : drop();
            (120,_,_,_) : NoAction();
            (_,120,_,_) : NoAction();
            (_,_,120,_) : NoAction();
            (_,_,_,120) : NoAction();
            (119,_,_,_) : drop();
            (_,119,_,_) : drop();
            (_,_,119,_) : drop();
            (_,_,_,119) : drop();
            (118,_,_,_) : NoAction();
            (_,118,_,_) : NoAction();
            (_,_,118,_) : NoAction();
            (_,_,_,118) : NoAction();
            (117,_,_,_) : drop();
            (_,117,_,_) : drop();
            (_,_,117,_) : drop();
            (_,_,_,117) : drop();
            (116,_,_,_) : NoAction();
            (_,116,_,_) : NoAction();
            (_,_,116,_) : NoAction();
            (_,_,_,116) : NoAction();
            (115,_,_,_) : drop();
            (_,115,_,_) : drop();
            (_,_,115,_) : drop();
            (_,_,_,115) : drop();
            (114,_,_,_) : NoAction();
            (_,114,_,_) : NoAction();
            (_,_,114,_) : NoAction();
            (_,_,_,114) : NoAction();
            (113,_,_,_) : drop();
            (_,113,_,_) : drop();
            (_,_,113,_) : drop();
            (_,_,_,113) : drop();
            (112,_,_,_) : NoAction();
            (_,112,_,_) : NoAction();
            (_,_,112,_) : NoAction();
            (_,_,_,112) : NoAction();
            (111,_,_,_) : drop();
            (_,111,_,_) : drop();
            (_,_,111,_) : drop();
            (_,_,_,111) : drop();
            (110,_,_,_) : NoAction();
            (_,110,_,_) : NoAction();
            (_,_,110,_) : NoAction();
            (_,_,_,110) : NoAction();
            (109,_,_,_) : drop();
            (_,109,_,_) : drop();
            (_,_,109,_) : drop();
            (_,_,_,109) : drop();
            (108,_,_,_) : NoAction();
            (_,108,_,_) : NoAction();
            (_,_,108,_) : NoAction();
            (_,_,_,108) : NoAction();
            (107,_,_,_) : drop();
            (_,107,_,_) : drop();
            (_,_,107,_) : drop();
            (_,_,_,107) : drop();
            (106,_,_,_) : NoAction();
            (_,106,_,_) : NoAction();
            (_,_,106,_) : NoAction();
            (_,_,_,106) : NoAction();
            (105,_,_,_) : drop();
            (_,105,_,_) : drop();
            (_,_,105,_) : drop();
            (_,_,_,105) : drop();
            (104,_,_,_) : NoAction();
            (_,104,_,_) : NoAction();
            (_,_,104,_) : NoAction();
            (_,_,_,104) : NoAction();
            (103,_,_,_) : drop();
            (_,103,_,_) : drop();
            (_,_,103,_) : drop();
            (_,_,_,103) : drop();
            (102,_,_,_) : NoAction();
            (_,102,_,_) : NoAction();
            (_,_,102,_) : NoAction();
            (_,_,_,102) : NoAction();
            (101,_,_,_) : drop();
            (_,101,_,_) : drop();
            (_,_,101,_) : drop();
            (_,_,_,101) : drop();
            (100,_,_,_) : NoAction();
            (_,100,_,_) : NoAction();
            (_,_,100,_) : NoAction();
            (_,_,_,100) : NoAction();
            (99,_,_,_) : drop();
            (_,99,_,_) : drop();
            (_,_,99,_) : drop();
            (_,_,_,99) : drop();
            (98,_,_,_) : NoAction();
            (_,98,_,_) : NoAction();
            (_,_,98,_) : NoAction();
            (_,_,_,98) : NoAction();
            (97,_,_,_) : drop();
            (_,97,_,_) : drop();
            (_,_,97,_) : drop();
            (_,_,_,97) : drop();
            (96,_,_,_) : NoAction();
            (_,96,_,_) : NoAction();
            (_,_,96,_) : NoAction();
            (_,_,_,96) : NoAction();
            (95,_,_,_) : drop();
            (_,95,_,_) : drop();
            (_,_,95,_) : drop();
            (_,_,_,95) : drop();
            (94,_,_,_) : NoAction();
            (_,94,_,_) : NoAction();
            (_,_,94,_) : NoAction();
            (_,_,_,94) : NoAction();
            (93,_,_,_) : drop();
            (_,93,_,_) : drop();
            (_,_,93,_) : drop();
            (_,_,_,93) : drop();
            (92,_,_,_) : NoAction();
            (_,92,_,_) : NoAction();
            (_,_,92,_) : NoAction();
            (_,_,_,92) : NoAction();
            (91,_,_,_) : drop();
            (_,91,_,_) : drop();
            (_,_,91,_) : drop();
            (_,_,_,91) : drop();
            (90,_,_,_) : NoAction();
            (_,90,_,_) : NoAction();
            (_,_,90,_) : NoAction();
            (_,_,_,90) : NoAction();
            (89,_,_,_) : drop();
            (_,89,_,_) : drop();
            (_,_,89,_) : drop();
            (_,_,_,89) : drop();
            (88,_,_,_) : NoAction();
            (_,88,_,_) : NoAction();
            (_,_,88,_) : NoAction();
            (_,_,_,88) : NoAction();
            (87,_,_,_) : drop();
            (_,87,_,_) : drop();
            (_,_,87,_) : drop();
            (_,_,_,87) : drop();
            (86,_,_,_) : NoAction();
            (_,86,_,_) : NoAction();
            (_,_,86,_) : NoAction();
            (_,_,_,86) : NoAction();
            (85,_,_,_) : drop();
            (_,85,_,_) : drop();
            (_,_,85,_) : drop();
            (_,_,_,85) : drop();
            (84,_,_,_) : NoAction();
            (_,84,_,_) : NoAction();
            (_,_,84,_) : NoAction();
            (_,_,_,84) : NoAction();
            (83,_,_,_) : drop();
            (_,83,_,_) : drop();
            (_,_,83,_) : drop();
            (_,_,_,83) : drop();
            (82,_,_,_) : NoAction();
            (_,82,_,_) : NoAction();
            (_,_,82,_) : NoAction();
            (_,_,_,82) : NoAction();
            (81,_,_,_) : drop();
            (_,81,_,_) : drop();
            (_,_,81,_) : drop();
            (_,_,_,81) : drop();
            (80,_,_,_) : NoAction();
            (_,80,_,_) : NoAction();
            (_,_,80,_) : NoAction();
            (_,_,_,80) : NoAction();
            (79,_,_,_) : drop();
            (_,79,_,_) : drop();
            (_,_,79,_) : drop();
            (_,_,_,79) : drop();
            (78,_,_,_) : NoAction();
            (_,78,_,_) : NoAction();
            (_,_,78,_) : NoAction();
            (_,_,_,78) : NoAction();
            (77,_,_,_) : drop();
            (_,77,_,_) : drop();
            (_,_,77,_) : drop();
            (_,_,_,77) : drop();
            (76,_,_,_) : NoAction();
            (_,76,_,_) : NoAction();
            (_,_,76,_) : NoAction();
            (_,_,_,76) : NoAction();
            (75,_,_,_) : drop();
            (_,75,_,_) : drop();
            (_,_,75,_) : drop();
            (_,_,_,75) : drop();
            (74,_,_,_) : NoAction();
            (_,74,_,_) : NoAction();
            (_,_,74,_) : NoAction();
            (_,_,_,74) : NoAction();
            (73,_,_,_) : drop();
            (_,73,_,_) : drop();
            (_,_,73,_) : drop();
            (_,_,_,73) : drop();
            (72,_,_,_) : NoAction();
            (_,72,_,_) : NoAction();
            (_,_,72,_) : NoAction();
            (_,_,_,72) : NoAction();
            (71,_,_,_) : drop();
            (_,71,_,_) : drop();
            (_,_,71,_) : drop();
            (_,_,_,71) : drop();
            (70,_,_,_) : NoAction();
            (_,70,_,_) : NoAction();
            (_,_,70,_) : NoAction();
            (_,_,_,70) : NoAction();
            (69,_,_,_) : drop();
            (_,69,_,_) : drop();
            (_,_,69,_) : drop();
            (_,_,_,69) : drop();
            (68,_,_,_) : NoAction();
            (_,68,_,_) : NoAction();
            (_,_,68,_) : NoAction();
            (_,_,_,68) : NoAction();
            (67,_,_,_) : drop();
            (_,67,_,_) : drop();
            (_,_,67,_) : drop();
            (_,_,_,67) : drop();
            (66,_,_,_) : NoAction();
            (_,66,_,_) : NoAction();
            (_,_,66,_) : NoAction();
            (_,_,_,66) : NoAction();
            (65,_,_,_) : drop();
            (_,65,_,_) : drop();
            (_,_,65,_) : drop();
            (_,_,_,65) : drop();
            (64,_,_,_) : NoAction();
            (_,64,_,_) : NoAction();
            (_,_,64,_) : NoAction();
            (_,_,_,64) : NoAction();
            (63,_,_,_) : drop();
            (_,63,_,_) : drop();
            (_,_,63,_) : drop();
            (_,_,_,63) : drop();
            (62,_,_,_) : NoAction();
            (_,62,_,_) : NoAction();
            (_,_,62,_) : NoAction();
            (_,_,_,62) : NoAction();
            (61,_,_,_) : drop();
            (_,61,_,_) : drop();
            (_,_,61,_) : drop();
            (_,_,_,61) : drop();
            (60,_,_,_) : NoAction();
            (_,60,_,_) : NoAction();
            (_,_,60,_) : NoAction();
            (_,_,_,60) : NoAction();
            (59,_,_,_) : drop();
            (_,59,_,_) : drop();
            (_,_,59,_) : drop();
            (_,_,_,59) : drop();
            (58,_,_,_) : NoAction();
            (_,58,_,_) : NoAction();
            (_,_,58,_) : NoAction();
            (_,_,_,58) : NoAction();
            (57,_,_,_) : drop();
            (_,57,_,_) : drop();
            (_,_,57,_) : drop();
            (_,_,_,57) : drop();
            (56,_,_,_) : NoAction();
            (_,56,_,_) : NoAction();
            (_,_,56,_) : NoAction();
            (_,_,_,56) : NoAction();
            (55,_,_,_) : drop();
            (_,55,_,_) : drop();
            (_,_,55,_) : drop();
            (_,_,_,55) : drop();
            (54,_,_,_) : NoAction();
            (_,54,_,_) : NoAction();
            (_,_,54,_) : NoAction();
            (_,_,_,54) : NoAction();
            (53,_,_,_) : drop();
            (_,53,_,_) : drop();
            (_,_,53,_) : drop();
            (_,_,_,53) : drop();
            (52,_,_,_) : NoAction();
            (_,52,_,_) : NoAction();
            (_,_,52,_) : NoAction();
            (_,_,_,52) : NoAction();
            (51,_,_,_) : drop();
            (_,51,_,_) : drop();
            (_,_,51,_) : drop();
            (_,_,_,51) : drop();
            (50,_,_,_) : NoAction();
            (_,50,_,_) : NoAction();
            (_,_,50,_) : NoAction();
            (_,_,_,50) : NoAction();
            (49,_,_,_) : drop();
            (_,49,_,_) : drop();
            (_,_,49,_) : drop();
            (_,_,_,49) : drop();
            (48,_,_,_) : NoAction();
            (_,48,_,_) : NoAction();
            (_,_,48,_) : NoAction();
            (_,_,_,48) : NoAction();
            (47,_,_,_) : drop();
            (_,47,_,_) : drop();
            (_,_,47,_) : drop();
            (_,_,_,47) : drop();
            (46,_,_,_) : NoAction();
            (_,46,_,_) : NoAction();
            (_,_,46,_) : NoAction();
            (_,_,_,46) : NoAction();
            (45,_,_,_) : drop();
            (_,45,_,_) : drop();
            (_,_,45,_) : drop();
            (_,_,_,45) : drop();
            (44,_,_,_) : NoAction();
            (_,44,_,_) : NoAction();
            (_,_,44,_) : NoAction();
            (_,_,_,44) : NoAction();
            (43,_,_,_) : drop();
            (_,43,_,_) : drop();
            (_,_,43,_) : drop();
            (_,_,_,43) : drop();
            (42,_,_,_) : NoAction();
            (_,42,_,_) : NoAction();
            (_,_,42,_) : NoAction();
            (_,_,_,42) : NoAction();
            (41,_,_,_) : drop();
            (_,41,_,_) : drop();
            (_,_,41,_) : drop();
            (_,_,_,41) : drop();
            (40,_,_,_) : NoAction();
            (_,40,_,_) : NoAction();
            (_,_,40,_) : NoAction();
            (_,_,_,40) : NoAction();
            (39,_,_,_) : drop();
            (_,39,_,_) : drop();
            (_,_,39,_) : drop();
            (_,_,_,39) : drop();
            (38,_,_,_) : NoAction();
            (_,38,_,_) : NoAction();
            (_,_,38,_) : NoAction();
            (_,_,_,38) : NoAction();
            (37,_,_,_) : drop();
            (_,37,_,_) : drop();
            (_,_,37,_) : drop();
            (_,_,_,37) : drop();
            (36,_,_,_) : NoAction();
            (_,36,_,_) : NoAction();
            (_,_,36,_) : NoAction();
            (_,_,_,36) : NoAction();
            (35,_,_,_) : drop();
            (_,35,_,_) : drop();
            (_,_,35,_) : drop();
            (_,_,_,35) : drop();
            (34,_,_,_) : NoAction();
            (_,34,_,_) : NoAction();
            (_,_,34,_) : NoAction();
            (_,_,_,34) : NoAction();
            (33,_,_,_) : drop();
            (_,33,_,_) : drop();
            (_,_,33,_) : drop();
            (_,_,_,33) : drop();
            (32,_,_,_) : NoAction();
            (_,32,_,_) : NoAction();
            (_,_,32,_) : NoAction();
            (_,_,_,32) : NoAction();
            (31,_,_,_) : drop();
            (_,31,_,_) : drop();
            (_,_,31,_) : drop();
            (_,_,_,31) : drop();
            (30,_,_,_) : NoAction();
            (_,30,_,_) : NoAction();
            (_,_,30,_) : NoAction();
            (_,_,_,30) : NoAction();
            (29,_,_,_) : drop();
            (_,29,_,_) : drop();
            (_,_,29,_) : drop();
            (_,_,_,29) : drop();
            (28,_,_,_) : NoAction();
            (_,28,_,_) : NoAction();
            (_,_,28,_) : NoAction();
            (_,_,_,28) : NoAction();
            (27,_,_,_) : drop();
            (_,27,_,_) : drop();
            (_,_,27,_) : drop();
            (_,_,_,27) : drop();
            (26,_,_,_) : NoAction();
            (_,26,_,_) : NoAction();
            (_,_,26,_) : NoAction();
            (_,_,_,26) : NoAction();
            (25,_,_,_) : drop();
            (_,25,_,_) : drop();
            (_,_,25,_) : drop();
            (_,_,_,25) : drop();
            (24,_,_,_) : NoAction();
            (_,24,_,_) : NoAction();
            (_,_,24,_) : NoAction();
            (_,_,_,24) : NoAction();
            (23,_,_,_) : drop();
            (_,23,_,_) : drop();
            (_,_,23,_) : drop();
            (_,_,_,23) : drop();
            (22,_,_,_) : NoAction();
            (_,22,_,_) : NoAction();
            (_,_,22,_) : NoAction();
            (_,_,_,22) : NoAction();
            (21,_,_,_) : drop();
            (_,21,_,_) : drop();
            (_,_,21,_) : drop();
            (_,_,_,21) : drop();
            (20,_,_,_) : NoAction();
            (_,20,_,_) : NoAction();
            (_,_,20,_) : NoAction();
            (_,_,_,20) : NoAction();
            (19,_,_,_) : drop();
            (_,19,_,_) : drop();
            (_,_,19,_) : drop();
            (_,_,_,19) : drop();
            (18,_,_,_) : NoAction();
            (_,18,_,_) : NoAction();
            (_,_,18,_) : NoAction();
            (_,_,_,18) : NoAction();
            (17,_,_,_) : drop();
            (_,17,_,_) : drop();
            (_,_,17,_) : drop();
            (_,_,_,17) : drop();
            (16,_,_,_) : NoAction();
            (_,16,_,_) : NoAction();
            (_,_,16,_) : NoAction();
            (_,_,_,16) : NoAction();
            (15,_,_,_) : drop();
            (_,15,_,_) : drop();
            (_,_,15,_) : drop();
            (_,_,_,15) : drop();
            (14,_,_,_) : NoAction();
            (_,14,_,_) : NoAction();
            (_,_,14,_) : NoAction();
            (_,_,_,14) : NoAction();
            (13,_,_,_) : drop();
            (_,13,_,_) : drop();
            (_,_,13,_) : drop();
            (_,_,_,13) : drop();
            (12,_,_,_) : NoAction();
            (_,12,_,_) : NoAction();
            (_,_,12,_) : NoAction();
            (_,_,_,12) : NoAction();
            (11,_,_,_) : drop();
            (_,11,_,_) : drop();
            (_,_,11,_) : drop();
            (_,_,_,11) : drop();
            (10,_,_,_) : NoAction();
            (_,10,_,_) : NoAction();
            (_,_,10,_) : NoAction();
            (_,_,_,10) : NoAction();
            (9,_,_,_) : drop();
            (_,9,_,_) : drop();
            (_,_,9,_) : drop();
            (_,_,_,9) : drop();
            (8,_,_,_) : NoAction();
            (_,8,_,_) : NoAction();
            (_,_,8,_) : NoAction();
            (_,_,_,8) : NoAction();
            (7,_,_,_) : drop();
            (_,7,_,_) : drop();
            (_,_,7,_) : drop();
            (_,_,_,7) : drop();
            (6,_,_,_) : NoAction();
            (_,6,_,_) : NoAction();
            (_,_,6,_) : NoAction();
            (_,_,_,6) : NoAction();
            (5,_,_,_) : drop();
            (_,5,_,_) : drop();
            (_,_,5,_) : drop();
            (_,_,_,5) : drop();
            (4,_,_,_) : NoAction();
            (_,4,_,_) : NoAction();
            (_,_,4,_) : NoAction();
            (_,_,_,4) : NoAction();
            (3,_,_,_) : drop();
            (_,3,_,_) : drop();
            (_,_,3,_) : drop();
            (_,_,_,3) : drop();
            (2,_,_,_) : NoAction();
            (_,2,_,_) : NoAction();
            (_,_,2,_) : NoAction();
            (_,_,_,2) : NoAction();
            (1,_,_,_) : drop();
            (_,1,_,_) : drop();
            (_,_,1,_) : drop();
            (_,_,_,1) : drop();
        }
    }
    apply {
        resolver.apply();
    }
}
# 15 "./FilterImplementation.p4h" 2

/*
control SimpleRuleTable<T>(in T field, out bit<8> prio)
 (int sz, int pprio) {
    action prioritization(bit<8> p) {prio = p;}
    @pragma placement_priority pprio
    table rules {
        key = {port : exact;}
        actions = {prioritization;}
        default_action = prioritization(0);
        size = sz;
    }
    apply {
        rules.apply();
    }
}

control LpmRuleTable<T>(in T field, out bit<8> prio)
 (int sz, int pprio, int isAlpm = 0, int part = 4096, int subtrees = 2) {
    action prioritization(bit<8> p) {prio = p;}
    @pragma placement_priority
    @pragma alpm 1
    @pragma alpm_partitions 4096
    @pragma alpm_subtrees_per_partition 2
    table rules {
        key = {field : lpm;}
        actions = {prioritization;}
        default_action = prioritization(0);
        size = sz;
    }
    apply {
        rules.apply();
    }
}
*/

control PortRuleTable(in bit<16> port, out bit<8> prio) {
    action prioritization(bit<8> p) {prio = p;}
    @pragma placement_priority 1
    table rules {
        key = { port : exact; }
        actions = { prioritization; }
        default_action = prioritization(0);
        size = 65536;
    }
    apply {
        rules.apply();
    }
}

control RoutingTypeTable(in bit<8> routing, out bit<8> prio) {
    action prioritization(bit<8> p) {prio = p;}
    @pragma placement_priority 1
    table rules {
        key = { routing : exact; }
        actions = { prioritization; }
        default_action = prioritization(0);
        size = 256;
    }
    apply {
        rules.apply();
    }
}

control Ip4RuleTable(in bit<32> ip, out bit<8> prio) {
    action prioritization(bit<8> p) {prio = p;}
# 112 "./FilterImplementation.p4h"
    @pragma alpm 1
    @pragma alpm_partitions 4096
    @pragma alpm_subtrees_per_partition 2
    table rules {
        key = {ip : lpm;}
        actions = {prioritization;}
        default_action = prioritization(0);

        size = 524288;



    }
    apply {
        rules.apply();
    }

}

control Ip6RuleTable(in bit<128> ip, out bit<8> prio) {
    action prioritization(bit<8> p) {prio = p;}
    //@pragma alpm 1
    table rules {
        key = {ip : lpm;}
        actions = {prioritization;}
        default_action = prioritization(0);

        size = 26624;



    }
    apply {
        rules.apply();
    }
}

control FilterImplementation(
    in ParsingHeaderStack headers,
    in HeadersInfo_s headersInfo,
    inout ingress_intrinsic_metadata_for_deparser_t depIntrinsic
) {
    RulePriorityData_s priorities = {0,0,0,0,0};
    Ip4RuleTable() sipRules;
    Ip4RuleTable() dipRules;
    Ip6RuleTable() sip6Rules;
    Ip6RuleTable() dip6Rules;
    PortRuleTable() spRules;
    PortRuleTable() dpRules;
    RoutingTypeTable() routing;
    DropResolution() resolver;

    table statesAllowingFiltering {
        actions = {NoAction;}
        key = {headers.bridging.state : exact;}
        const entries = {
            ST_DONE : NoAction();
            ST_DONE_LOCAL : NoAction();
        }
    }

    apply {
        if(headers.ip.ipv6Addresses.isValid()) {
            sip6Rules.apply(headers.ip.ipv6Addresses.src,priorities.p0);
            dip6Rules.apply(headers.ip.ipv6Addresses.dst,priorities.p1);
        }
        else {
            sipRules.apply(headers.ip.ipv4Addresses.src,priorities.p0);
            dipRules.apply(headers.ip.ipv4Addresses.dst,priorities.p1);
            if(!headers.ip.ipv4Addresses.isValid()) { //Simplify gateway logic - zero out results after processing
                priorities.p0 = 0;
                priorities.p1 = 1;
            }
        }
        routing.apply(headers.bridging.routingType,priorities.p4);
        spRules.apply(headersInfo.srcPort,priorities.p2);
        dpRules.apply(headersInfo.dstPort,priorities.p3);
        if(statesAllowingFiltering.apply().hit) {
            resolver.apply(depIntrinsic,priorities);
        }
    }
}
# 5 "./MauAndDeparser.p4h" 2

# 1 "./OffsetCalculation.p4h" 1



control OffsetCalculation(inout ParsingHeaderStack headers) {
    action setLength(bit<8> len) {
        headers.bridging.offset = headers.bridging.offset + len;
    }
    table lengthCalculations {
        key = {
            headers.ethernet.isValid() : exact;
            headers.vlan0.isValid() : exact;
            headers.vlan1.isValid() : exact;
            headers.vlan2.isValid() : exact;
            headers.vlan3.isValid() : exact;
            headers.mpls0.isValid() : exact;
            headers.mpls1.isValid() : exact;
            headers.mpls2.isValid() : exact;
            headers.mpls3.isValid() : exact;
            headers.mpls4.isValid() : exact;
            headers.mpls5.isValid() : exact;
            headers.mplsZeroBlob.isValid() : exact;
            headers.pppOe.isValid() : exact;
        }
        actions = {setLength; NoAction;}
        const default_action = NoAction();
        const entries = {
            (false, false, false, false, false, false, false, false, false, false, false, false, false) : setLength(0);
            (false, false, false, false, false, false, false, false, false, false, false, false, true) : setLength(11);
            (false, false, false, false, false, false, false, false, false, false, false, true, false) : setLength(4);
            (false, false, false, false, false, false, false, false, false, false, false, true, true) : setLength(15);
            (false, false, false, false, false, true, false, false, false, false, false, false, false) : setLength(4);
            (false, false, false, false, false, true, false, false, false, false, false, false, true) : setLength(15);
            (false, false, false, false, false, true, false, false, false, false, false, true, false) : setLength(8);
            (false, false, false, false, false, true, false, false, false, false, false, true, true) : setLength(19);
            (false, false, false, false, false, true, true, false, false, false, false, false, false) : setLength(8);
            (false, false, false, false, false, true, true, false, false, false, false, false, true) : setLength(19);
            (false, false, false, false, false, true, true, false, false, false, false, true, false) : setLength(12);
            (false, false, false, false, false, true, true, false, false, false, false, true, true) : setLength(23);
            (false, false, false, false, false, true, true, true, false, false, false, false, false) : setLength(12);
            (false, false, false, false, false, true, true, true, false, false, false, false, true) : setLength(23);
            (false, false, false, false, false, true, true, true, false, false, false, true, false) : setLength(16);
            (false, false, false, false, false, true, true, true, false, false, false, true, true) : setLength(27);
            (false, false, false, false, false, true, true, true, true, false, false, false, false) : setLength(16);
            (false, false, false, false, false, true, true, true, true, false, false, false, true) : setLength(27);
            (false, false, false, false, false, true, true, true, true, false, false, true, false) : setLength(20);
            (false, false, false, false, false, true, true, true, true, false, false, true, true) : setLength(31);
            (false, false, false, false, false, true, true, true, true, true, false, false, false) : setLength(20);
            (false, false, false, false, false, true, true, true, true, true, false, false, true) : setLength(31);
            (false, false, false, false, false, true, true, true, true, true, false, true, false) : setLength(24);
            (false, false, false, false, false, true, true, true, true, true, false, true, true) : setLength(35);
            (false, false, false, false, false, true, true, true, true, true, true, false, false) : setLength(24);
            (false, false, false, false, false, true, true, true, true, true, true, false, true) : setLength(35);
            (false, false, false, false, false, true, true, true, true, true, true, true, false) : setLength(28);
            (false, false, false, false, false, true, true, true, true, true, true, true, true) : setLength(39);
            (false, true, false, false, false, false, false, false, false, false, false, false, false) : setLength(4);
            (false, true, false, false, false, false, false, false, false, false, false, false, true) : setLength(15);
            (false, true, false, false, false, false, false, false, false, false, false, true, false) : setLength(8);
            (false, true, false, false, false, false, false, false, false, false, false, true, true) : setLength(19);
            (false, true, false, false, false, true, false, false, false, false, false, false, false) : setLength(8);
            (false, true, false, false, false, true, false, false, false, false, false, false, true) : setLength(19);
            (false, true, false, false, false, true, false, false, false, false, false, true, false) : setLength(12);
            (false, true, false, false, false, true, false, false, false, false, false, true, true) : setLength(23);
            (false, true, false, false, false, true, true, false, false, false, false, false, false) : setLength(12);
            (false, true, false, false, false, true, true, false, false, false, false, false, true) : setLength(23);
            (false, true, false, false, false, true, true, false, false, false, false, true, false) : setLength(16);
            (false, true, false, false, false, true, true, false, false, false, false, true, true) : setLength(27);
            (false, true, false, false, false, true, true, true, false, false, false, false, false) : setLength(16);
            (false, true, false, false, false, true, true, true, false, false, false, false, true) : setLength(27);
            (false, true, false, false, false, true, true, true, false, false, false, true, false) : setLength(20);
            (false, true, false, false, false, true, true, true, false, false, false, true, true) : setLength(31);
            (false, true, false, false, false, true, true, true, true, false, false, false, false) : setLength(20);
            (false, true, false, false, false, true, true, true, true, false, false, false, true) : setLength(31);
            (false, true, false, false, false, true, true, true, true, false, false, true, false) : setLength(24);
            (false, true, false, false, false, true, true, true, true, false, false, true, true) : setLength(35);
            (false, true, false, false, false, true, true, true, true, true, false, false, false) : setLength(24);
            (false, true, false, false, false, true, true, true, true, true, false, false, true) : setLength(35);
            (false, true, false, false, false, true, true, true, true, true, false, true, false) : setLength(28);
            (false, true, false, false, false, true, true, true, true, true, false, true, true) : setLength(39);
            (false, true, false, false, false, true, true, true, true, true, true, false, false) : setLength(28);
            (false, true, false, false, false, true, true, true, true, true, true, false, true) : setLength(39);
            (false, true, false, false, false, true, true, true, true, true, true, true, false) : setLength(32);
            (false, true, false, false, false, true, true, true, true, true, true, true, true) : setLength(43);
            (false, true, true, false, false, false, false, false, false, false, false, false, false) : setLength(8);
            (false, true, true, false, false, false, false, false, false, false, false, false, true) : setLength(19);
            (false, true, true, false, false, false, false, false, false, false, false, true, false) : setLength(12);
            (false, true, true, false, false, false, false, false, false, false, false, true, true) : setLength(23);
            (false, true, true, false, false, true, false, false, false, false, false, false, false) : setLength(12);
            (false, true, true, false, false, true, false, false, false, false, false, false, true) : setLength(23);
            (false, true, true, false, false, true, false, false, false, false, false, true, false) : setLength(16);
            (false, true, true, false, false, true, false, false, false, false, false, true, true) : setLength(27);
            (false, true, true, false, false, true, true, false, false, false, false, false, false) : setLength(16);
            (false, true, true, false, false, true, true, false, false, false, false, false, true) : setLength(27);
            (false, true, true, false, false, true, true, false, false, false, false, true, false) : setLength(20);
            (false, true, true, false, false, true, true, false, false, false, false, true, true) : setLength(31);
            (false, true, true, false, false, true, true, true, false, false, false, false, false) : setLength(20);
            (false, true, true, false, false, true, true, true, false, false, false, false, true) : setLength(31);
            (false, true, true, false, false, true, true, true, false, false, false, true, false) : setLength(24);
            (false, true, true, false, false, true, true, true, false, false, false, true, true) : setLength(35);
            (false, true, true, false, false, true, true, true, true, false, false, false, false) : setLength(24);
            (false, true, true, false, false, true, true, true, true, false, false, false, true) : setLength(35);
            (false, true, true, false, false, true, true, true, true, false, false, true, false) : setLength(28);
            (false, true, true, false, false, true, true, true, true, false, false, true, true) : setLength(39);
            (false, true, true, false, false, true, true, true, true, true, false, false, false) : setLength(28);
            (false, true, true, false, false, true, true, true, true, true, false, false, true) : setLength(39);
            (false, true, true, false, false, true, true, true, true, true, false, true, false) : setLength(32);
            (false, true, true, false, false, true, true, true, true, true, false, true, true) : setLength(43);
            (false, true, true, false, false, true, true, true, true, true, true, false, false) : setLength(32);
            (false, true, true, false, false, true, true, true, true, true, true, false, true) : setLength(43);
            (false, true, true, false, false, true, true, true, true, true, true, true, false) : setLength(36);
            (false, true, true, false, false, true, true, true, true, true, true, true, true) : setLength(47);
            (false, true, true, true, false, false, false, false, false, false, false, false, false) : setLength(12);
            (false, true, true, true, false, false, false, false, false, false, false, false, true) : setLength(23);
            (false, true, true, true, false, false, false, false, false, false, false, true, false) : setLength(16);
            (false, true, true, true, false, false, false, false, false, false, false, true, true) : setLength(27);
            (false, true, true, true, false, true, false, false, false, false, false, false, false) : setLength(16);
            (false, true, true, true, false, true, false, false, false, false, false, false, true) : setLength(27);
            (false, true, true, true, false, true, false, false, false, false, false, true, false) : setLength(20);
            (false, true, true, true, false, true, false, false, false, false, false, true, true) : setLength(31);
            (false, true, true, true, false, true, true, false, false, false, false, false, false) : setLength(20);
            (false, true, true, true, false, true, true, false, false, false, false, false, true) : setLength(31);
            (false, true, true, true, false, true, true, false, false, false, false, true, false) : setLength(24);
            (false, true, true, true, false, true, true, false, false, false, false, true, true) : setLength(35);
            (false, true, true, true, false, true, true, true, false, false, false, false, false) : setLength(24);
            (false, true, true, true, false, true, true, true, false, false, false, false, true) : setLength(35);
            (false, true, true, true, false, true, true, true, false, false, false, true, false) : setLength(28);
            (false, true, true, true, false, true, true, true, false, false, false, true, true) : setLength(39);
            (false, true, true, true, false, true, true, true, true, false, false, false, false) : setLength(28);
            (false, true, true, true, false, true, true, true, true, false, false, false, true) : setLength(39);
            (false, true, true, true, false, true, true, true, true, false, false, true, false) : setLength(32);
            (false, true, true, true, false, true, true, true, true, false, false, true, true) : setLength(43);
            (false, true, true, true, false, true, true, true, true, true, false, false, false) : setLength(32);
            (false, true, true, true, false, true, true, true, true, true, false, false, true) : setLength(43);
            (false, true, true, true, false, true, true, true, true, true, false, true, false) : setLength(36);
            (false, true, true, true, false, true, true, true, true, true, false, true, true) : setLength(47);
            (false, true, true, true, false, true, true, true, true, true, true, false, false) : setLength(36);
            (false, true, true, true, false, true, true, true, true, true, true, false, true) : setLength(47);
            (false, true, true, true, false, true, true, true, true, true, true, true, false) : setLength(40);
            (false, true, true, true, false, true, true, true, true, true, true, true, true) : setLength(51);
            (false, true, true, true, true, false, false, false, false, false, false, false, false) : setLength(16);
            (false, true, true, true, true, false, false, false, false, false, false, false, true) : setLength(27);
            (false, true, true, true, true, false, false, false, false, false, false, true, false) : setLength(20);
            (false, true, true, true, true, false, false, false, false, false, false, true, true) : setLength(31);
            (false, true, true, true, true, true, false, false, false, false, false, false, false) : setLength(20);
            (false, true, true, true, true, true, false, false, false, false, false, false, true) : setLength(31);
            (false, true, true, true, true, true, false, false, false, false, false, true, false) : setLength(24);
            (false, true, true, true, true, true, false, false, false, false, false, true, true) : setLength(35);
            (false, true, true, true, true, true, true, false, false, false, false, false, false) : setLength(24);
            (false, true, true, true, true, true, true, false, false, false, false, false, true) : setLength(35);
            (false, true, true, true, true, true, true, false, false, false, false, true, false) : setLength(28);
            (false, true, true, true, true, true, true, false, false, false, false, true, true) : setLength(39);
            (false, true, true, true, true, true, true, true, false, false, false, false, false) : setLength(28);
            (false, true, true, true, true, true, true, true, false, false, false, false, true) : setLength(39);
            (false, true, true, true, true, true, true, true, false, false, false, true, false) : setLength(32);
            (false, true, true, true, true, true, true, true, false, false, false, true, true) : setLength(43);
            (false, true, true, true, true, true, true, true, true, false, false, false, false) : setLength(32);
            (false, true, true, true, true, true, true, true, true, false, false, false, true) : setLength(43);
            (false, true, true, true, true, true, true, true, true, false, false, true, false) : setLength(36);
            (false, true, true, true, true, true, true, true, true, false, false, true, true) : setLength(47);
            (false, true, true, true, true, true, true, true, true, true, false, false, false) : setLength(36);
            (false, true, true, true, true, true, true, true, true, true, false, false, true) : setLength(47);
            (false, true, true, true, true, true, true, true, true, true, false, true, false) : setLength(40);
            (false, true, true, true, true, true, true, true, true, true, false, true, true) : setLength(51);
            (false, true, true, true, true, true, true, true, true, true, true, false, false) : setLength(40);
            (false, true, true, true, true, true, true, true, true, true, true, false, true) : setLength(51);
            (false, true, true, true, true, true, true, true, true, true, true, true, false) : setLength(44);
            (false, true, true, true, true, true, true, true, true, true, true, true, true) : setLength(55);
            (true, false, false, false, false, false, false, false, false, false, false, false, false) : setLength(14);
            (true, false, false, false, false, false, false, false, false, false, false, false, true) : setLength(25);
            (true, false, false, false, false, false, false, false, false, false, false, true, false) : setLength(18);
            (true, false, false, false, false, false, false, false, false, false, false, true, true) : setLength(29);
            (true, false, false, false, false, true, false, false, false, false, false, false, false) : setLength(18);
            (true, false, false, false, false, true, false, false, false, false, false, false, true) : setLength(29);
            (true, false, false, false, false, true, false, false, false, false, false, true, false) : setLength(22);
            (true, false, false, false, false, true, false, false, false, false, false, true, true) : setLength(33);
            (true, false, false, false, false, true, true, false, false, false, false, false, false) : setLength(22);
            (true, false, false, false, false, true, true, false, false, false, false, false, true) : setLength(33);
            (true, false, false, false, false, true, true, false, false, false, false, true, false) : setLength(26);
            (true, false, false, false, false, true, true, false, false, false, false, true, true) : setLength(37);
            (true, false, false, false, false, true, true, true, false, false, false, false, false) : setLength(26);
            (true, false, false, false, false, true, true, true, false, false, false, false, true) : setLength(37);
            (true, false, false, false, false, true, true, true, false, false, false, true, false) : setLength(30);
            (true, false, false, false, false, true, true, true, false, false, false, true, true) : setLength(41);
            (true, false, false, false, false, true, true, true, true, false, false, false, false) : setLength(30);
            (true, false, false, false, false, true, true, true, true, false, false, false, true) : setLength(41);
            (true, false, false, false, false, true, true, true, true, false, false, true, false) : setLength(34);
            (true, false, false, false, false, true, true, true, true, false, false, true, true) : setLength(45);
            (true, false, false, false, false, true, true, true, true, true, false, false, false) : setLength(34);
            (true, false, false, false, false, true, true, true, true, true, false, false, true) : setLength(45);
            (true, false, false, false, false, true, true, true, true, true, false, true, false) : setLength(38);
            (true, false, false, false, false, true, true, true, true, true, false, true, true) : setLength(49);
            (true, false, false, false, false, true, true, true, true, true, true, false, false) : setLength(38);
            (true, false, false, false, false, true, true, true, true, true, true, false, true) : setLength(49);
            (true, false, false, false, false, true, true, true, true, true, true, true, false) : setLength(42);
            (true, false, false, false, false, true, true, true, true, true, true, true, true) : setLength(53);
            (true, true, false, false, false, false, false, false, false, false, false, false, false) : setLength(18);
            (true, true, false, false, false, false, false, false, false, false, false, false, true) : setLength(29);
            (true, true, false, false, false, false, false, false, false, false, false, true, false) : setLength(22);
            (true, true, false, false, false, false, false, false, false, false, false, true, true) : setLength(33);
            (true, true, false, false, false, true, false, false, false, false, false, false, false) : setLength(22);
            (true, true, false, false, false, true, false, false, false, false, false, false, true) : setLength(33);
            (true, true, false, false, false, true, false, false, false, false, false, true, false) : setLength(26);
            (true, true, false, false, false, true, false, false, false, false, false, true, true) : setLength(37);
            (true, true, false, false, false, true, true, false, false, false, false, false, false) : setLength(26);
            (true, true, false, false, false, true, true, false, false, false, false, false, true) : setLength(37);
            (true, true, false, false, false, true, true, false, false, false, false, true, false) : setLength(30);
            (true, true, false, false, false, true, true, false, false, false, false, true, true) : setLength(41);
            (true, true, false, false, false, true, true, true, false, false, false, false, false) : setLength(30);
            (true, true, false, false, false, true, true, true, false, false, false, false, true) : setLength(41);
            (true, true, false, false, false, true, true, true, false, false, false, true, false) : setLength(34);
            (true, true, false, false, false, true, true, true, false, false, false, true, true) : setLength(45);
            (true, true, false, false, false, true, true, true, true, false, false, false, false) : setLength(34);
            (true, true, false, false, false, true, true, true, true, false, false, false, true) : setLength(45);
            (true, true, false, false, false, true, true, true, true, false, false, true, false) : setLength(38);
            (true, true, false, false, false, true, true, true, true, false, false, true, true) : setLength(49);
            (true, true, false, false, false, true, true, true, true, true, false, false, false) : setLength(38);
            (true, true, false, false, false, true, true, true, true, true, false, false, true) : setLength(49);
            (true, true, false, false, false, true, true, true, true, true, false, true, false) : setLength(42);
            (true, true, false, false, false, true, true, true, true, true, false, true, true) : setLength(53);
            (true, true, false, false, false, true, true, true, true, true, true, false, false) : setLength(42);
            (true, true, false, false, false, true, true, true, true, true, true, false, true) : setLength(53);
            (true, true, false, false, false, true, true, true, true, true, true, true, false) : setLength(46);
            (true, true, false, false, false, true, true, true, true, true, true, true, true) : setLength(57);
            (true, true, true, false, false, false, false, false, false, false, false, false, false) : setLength(22);
            (true, true, true, false, false, false, false, false, false, false, false, false, true) : setLength(33);
            (true, true, true, false, false, false, false, false, false, false, false, true, false) : setLength(26);
            (true, true, true, false, false, false, false, false, false, false, false, true, true) : setLength(37);
            (true, true, true, false, false, true, false, false, false, false, false, false, false) : setLength(26);
            (true, true, true, false, false, true, false, false, false, false, false, false, true) : setLength(37);
            (true, true, true, false, false, true, false, false, false, false, false, true, false) : setLength(30);
            (true, true, true, false, false, true, false, false, false, false, false, true, true) : setLength(41);
            (true, true, true, false, false, true, true, false, false, false, false, false, false) : setLength(30);
            (true, true, true, false, false, true, true, false, false, false, false, false, true) : setLength(41);
            (true, true, true, false, false, true, true, false, false, false, false, true, false) : setLength(34);
            (true, true, true, false, false, true, true, false, false, false, false, true, true) : setLength(45);
            (true, true, true, false, false, true, true, true, false, false, false, false, false) : setLength(34);
            (true, true, true, false, false, true, true, true, false, false, false, false, true) : setLength(45);
            (true, true, true, false, false, true, true, true, false, false, false, true, false) : setLength(38);
            (true, true, true, false, false, true, true, true, false, false, false, true, true) : setLength(49);
            (true, true, true, false, false, true, true, true, true, false, false, false, false) : setLength(38);
            (true, true, true, false, false, true, true, true, true, false, false, false, true) : setLength(49);
            (true, true, true, false, false, true, true, true, true, false, false, true, false) : setLength(42);
            (true, true, true, false, false, true, true, true, true, false, false, true, true) : setLength(53);
            (true, true, true, false, false, true, true, true, true, true, false, false, false) : setLength(42);
            (true, true, true, false, false, true, true, true, true, true, false, false, true) : setLength(53);
            (true, true, true, false, false, true, true, true, true, true, false, true, false) : setLength(46);
            (true, true, true, false, false, true, true, true, true, true, false, true, true) : setLength(57);
            (true, true, true, false, false, true, true, true, true, true, true, false, false) : setLength(46);
            (true, true, true, false, false, true, true, true, true, true, true, false, true) : setLength(57);
            (true, true, true, false, false, true, true, true, true, true, true, true, false) : setLength(50);
            (true, true, true, false, false, true, true, true, true, true, true, true, true) : setLength(61);
            (true, true, true, true, false, false, false, false, false, false, false, false, false) : setLength(26);
            (true, true, true, true, false, false, false, false, false, false, false, false, true) : setLength(37);
            (true, true, true, true, false, false, false, false, false, false, false, true, false) : setLength(30);
            (true, true, true, true, false, false, false, false, false, false, false, true, true) : setLength(41);
            (true, true, true, true, false, true, false, false, false, false, false, false, false) : setLength(30);
            (true, true, true, true, false, true, false, false, false, false, false, false, true) : setLength(41);
            (true, true, true, true, false, true, false, false, false, false, false, true, false) : setLength(34);
            (true, true, true, true, false, true, false, false, false, false, false, true, true) : setLength(45);
            (true, true, true, true, false, true, true, false, false, false, false, false, false) : setLength(34);
            (true, true, true, true, false, true, true, false, false, false, false, false, true) : setLength(45);
            (true, true, true, true, false, true, true, false, false, false, false, true, false) : setLength(38);
            (true, true, true, true, false, true, true, false, false, false, false, true, true) : setLength(49);
            (true, true, true, true, false, true, true, true, false, false, false, false, false) : setLength(38);
            (true, true, true, true, false, true, true, true, false, false, false, false, true) : setLength(49);
            (true, true, true, true, false, true, true, true, false, false, false, true, false) : setLength(42);
            (true, true, true, true, false, true, true, true, false, false, false, true, true) : setLength(53);
            (true, true, true, true, false, true, true, true, true, false, false, false, false) : setLength(42);
            (true, true, true, true, false, true, true, true, true, false, false, false, true) : setLength(53);
            (true, true, true, true, false, true, true, true, true, false, false, true, false) : setLength(46);
            (true, true, true, true, false, true, true, true, true, false, false, true, true) : setLength(57);
            (true, true, true, true, false, true, true, true, true, true, false, false, false) : setLength(46);
            (true, true, true, true, false, true, true, true, true, true, false, false, true) : setLength(57);
            (true, true, true, true, false, true, true, true, true, true, false, true, false) : setLength(50);
            (true, true, true, true, false, true, true, true, true, true, false, true, true) : setLength(61);
            (true, true, true, true, false, true, true, true, true, true, true, false, false) : setLength(50);
            (true, true, true, true, false, true, true, true, true, true, true, false, true) : setLength(61);
            (true, true, true, true, false, true, true, true, true, true, true, true, false) : setLength(54);
            (true, true, true, true, false, true, true, true, true, true, true, true, true) : setLength(65);
            (true, true, true, true, true, false, false, false, false, false, false, false, false) : setLength(30);
            (true, true, true, true, true, false, false, false, false, false, false, false, true) : setLength(41);
            (true, true, true, true, true, false, false, false, false, false, false, true, false) : setLength(34);
            (true, true, true, true, true, false, false, false, false, false, false, true, true) : setLength(45);
            (true, true, true, true, true, true, false, false, false, false, false, false, false) : setLength(34);
            (true, true, true, true, true, true, false, false, false, false, false, false, true) : setLength(45);
            (true, true, true, true, true, true, false, false, false, false, false, true, false) : setLength(38);
            (true, true, true, true, true, true, false, false, false, false, false, true, true) : setLength(49);
            (true, true, true, true, true, true, true, false, false, false, false, false, false) : setLength(38);
            (true, true, true, true, true, true, true, false, false, false, false, false, true) : setLength(49);
            (true, true, true, true, true, true, true, false, false, false, false, true, false) : setLength(42);
            (true, true, true, true, true, true, true, false, false, false, false, true, true) : setLength(53);
            (true, true, true, true, true, true, true, true, false, false, false, false, false) : setLength(42);
            (true, true, true, true, true, true, true, true, false, false, false, false, true) : setLength(53);
            (true, true, true, true, true, true, true, true, false, false, false, true, false) : setLength(46);
            (true, true, true, true, true, true, true, true, false, false, false, true, true) : setLength(57);
            (true, true, true, true, true, true, true, true, true, false, false, false, false) : setLength(46);
            (true, true, true, true, true, true, true, true, true, false, false, false, true) : setLength(57);
            (true, true, true, true, true, true, true, true, true, false, false, true, false) : setLength(50);
            (true, true, true, true, true, true, true, true, true, false, false, true, true) : setLength(61);
            (true, true, true, true, true, true, true, true, true, true, false, false, false) : setLength(50);
            (true, true, true, true, true, true, true, true, true, true, false, false, true) : setLength(61);
            (true, true, true, true, true, true, true, true, true, true, false, true, false) : setLength(54);
            (true, true, true, true, true, true, true, true, true, true, false, true, true) : setLength(65);
            (true, true, true, true, true, true, true, true, true, true, true, false, false) : setLength(54);
            (true, true, true, true, true, true, true, true, true, true, true, false, true) : setLength(65);
            (true, true, true, true, true, true, true, true, true, true, true, true, false) : setLength(58);
            (true, true, true, true, true, true, true, true, true, true, true, true, true) : setLength(69);
        }
    }
    apply {
        lengthCalculations.apply();
    }
}
# 7 "./MauAndDeparser.p4h" 2

control Ingress(
    inout ParsingHeaderStack headers,
    inout StandardIngressParsingMetadata meta,
    in ingress_intrinsic_metadata_t intrinsic,
    in ingress_intrinsic_metadata_from_parser_t parserIntrinsic,
    inout ingress_intrinsic_metadata_for_deparser_t depIntrinsic,
    inout ingress_intrinsic_metadata_for_tm_t tmIntrinsic
) {
    FilterImplementation() filter;
    OffsetCalculation() offsetCalculation;

    apply {
        if(!headers.bridging.isValid()) { //We always need a bridging header if we don't have one
            headers.bridging.setValid();
            headers.bridging.state = ST_UNFINISHED;
            headers.bridging.timestamp = intrinsic.ingress_mac_tstamp;
        }
        depIntrinsic.drop_ctl = 0;//Force to 0 by default
        if(meta.portProperties.flowId != 0) {
            headers.bridging.sourceId = (bit<32>)meta.portProperties.flowId;
        }
        offsetCalculation.apply(headers);

        filter.apply(headers,meta.headersInfo,depIntrinsic);

        if(!headers.ip.ipv4.isValid()) { //Any addresses extracted were inserted artifically if the rest of the header is missing, so remove them now
            headers.ip.ipv4Addresses.setInvalid();
        }
        if(!headers.ip.ipv6.isValid()) {
            headers.ip.ipv6Addresses.setInvalid();
        }
    }
}

control IngressDeparser(
    packet_out pkt,
    inout ParsingHeaderStack headers,
    in StandardIngressParsingMetadata meta,
    in ingress_intrinsic_metadata_for_deparser_t ingressDeparserMetadata
) {
    apply {
        pkt.emit(headers);
    }
}

control Egress(
    inout ParsingHeaderStack headers,
    inout StandardEgressParsingMetadata meta,
    in egress_intrinsic_metadata_t intrinsic,
    in egress_intrinsic_metadata_from_parser_t parserIntrinsic,
    inout egress_intrinsic_metadata_for_deparser_t depIntrinsic,
    inout egress_intrinsic_metadata_for_output_port_t tmIntrinsic
) {
    OffsetCalculation() offsetCalculation;

    apply {
        if(headers.bridging.isValid() && !headers.outputRouting.isValid()) {
            //May as well apply any time headers.bridging is valid - if unneeded, does nothing
            offsetCalculation.apply(headers);
            if(meta.headersInfo.routeState != RT_UNSET) {
                headers.bridging.protocol = meta.headersInfo.nextProtocol;
            }
        }
    }
}

control EgressDeparser(
    packet_out pkt,
    inout ParsingHeaderStack headers,
    in StandardEgressParsingMetadata meta,
    in egress_intrinsic_metadata_for_deparser_t dep)
{
    apply {
        pkt.emit(headers);
    }
}
# 11 "SimpleProc.p4" 2

Pipeline(IngressParser(),Ingress(),IngressDeparser(),EgressParser(),Egress(),EgressDeparser()) pipe;
Switch(pipe) main;
