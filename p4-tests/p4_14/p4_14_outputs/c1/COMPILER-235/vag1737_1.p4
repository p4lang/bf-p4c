#include <core.p4>
#include <v1model.p4>

struct AbPvhk {
    bit<16> SXktkN;
}

struct WeFXyH {
    bit<8> VLGXXG;
    bit<1> OTmmdU;
    bit<1> vxRZLD;
    bit<1> lhgqZR;
    bit<1> PqcjFS;
    bit<1> TNJQUK;
}

struct RjEUbC {
    bit<1> ZtjVUq;
    bit<1> tgfjtx;
}

struct egress_l2_metadata_t {
    bit<24> dstOUI;
    bit<24> dstSTA;
    bit<24> srcOUI;
    bit<24> srcSTA;
    bit<16> outer_bd;
    bit<16> inner_bd;
    bit<16> VqbwXd;
    bit<12> vid;
    bit<9>  egress_port;
    bit<1>  MXEAcT;
    bit<1>  GbMjEH;
    bit<1>  DxjBnx;
    bit<1>  fqhobT;
    bit<1>  vRiVoY;
    bit<1>  xALOuI;
}

struct ipv4_metadata_t {
    bit<32> srcAddr;
    bit<32> dstAddr;
    bit<16> vrf;
}

struct ipv6_metadata_t {
    bit<128> srcAddr;
    bit<128> dstAddr;
}

struct l2_metadata_t {
    bit<24> dstOUI;
    bit<24> dstSTA;
    bit<24> srcOUI;
    bit<24> srcSTA;
    bit<16> outer_bd;
    bit<16> inner_bd;
    bit<16> pQXqBl;
    bit<12> dndsBa;
    bit<2>  eDTSaM;
    bit<1>  dhmjSj;
    bit<1>  AlAsan;
    bit<1>  FZIXaP;
    bit<1>  JFtqsz;
    bit<1>  OjymPH;
    bit<1>  mUhTtj;
    bit<3>  prio;
}

struct pKpXdV {
    bit<8> zVITkG;
}

struct port_metadata_t {
    bit<14> ouVJSA;
    bit<1>  cCOHKE;
    bit<1>  huEsCO;
    bit<12> vid;
}

header arp_t {
    bit<16> hwType;
    bit<16> protoType;
    bit<8>  hwAddrLen;
    bit<8>  protoAddrLen;
    bit<16> opcode;
}

header egress_intrinsic_metadata_t {
    bit<7>  _pad0;
    bit<9>  egress_port;
    bit<5>  _pad1;
    bit<19> enq_qdepth;
    bit<6>  _pad2;
    bit<2>  enq_congest_stat;
    bit<32> enq_tstamp;
    bit<5>  _pad3;
    bit<19> deq_qdepth;
    bit<6>  _pad4;
    bit<2>  deq_congest_stat;
    bit<8>  app_pool_congest_stat;
    bit<32> deq_timedelta;
    bit<16> egress_rid;
    bit<7>  _pad5;
    bit<1>  egress_rid_first;
    bit<3>  _pad6;
    bit<5>  egress_qid;
    bit<5>  _pad7;
    bit<3>  egress_cos;
    bit<7>  _pad8;
    bit<1>  deflection_flag;
    bit<16> pkt_length;
}

header egress_intrinsic_metadata_for_mirror_buffer_t {
    bit<6>  _pad1;
    bit<10> egress_mirror_id;
    bit<1>  coalesce_flush;
    bit<7>  coalesce_length;
}

header egress_intrinsic_metadata_for_output_port_t {
    bit<2> _pad1;
    bit<1> capture_tstamp_on_tx;
    bit<1> update_delay_on_tx;
    bit<1> force_tx_error;
    bit<3> drop_ctl;
}

header egress_intrinsic_metadata_from_parser_aux_t {
    bit<48> egress_global_tstamp;
    bit<32> egress_global_ver;
    bit<16> egress_parser_err;
    bit<4>  clone_digest_id;
    bit<4>  clone_src;
    bit<8>  coalesce_sample_count;
}

header ingress_intrinsic_metadata_t {
    bit<1>  resubmit_flag;
    bit<1>  _pad1;
    bit<2>  _pad2;
    bit<3>  _pad3;
    bit<9>  ingress_port;
    bit<48> ingress_mac_tstamp;
}

header ingress_intrinsic_metadata_for_mirror_buffer_t {
    bit<6>  _pad1;
    bit<10> ingress_mirror_id;
}

header ingress_intrinsic_metadata_for_tm_t {
    bit<7>  _pad1;
    bit<9>  ucast_egress_port;
    bit<3>  drop_ctl;
    bit<1>  bypass_egress;
    bit<1>  deflect_on_drop;
    bit<3>  ingress_cos;
    bit<5>  qid;
    bit<3>  icos_for_copy_to_cpu;
    bit<3>  _pad2;
    bit<1>  copy_to_cpu;
    bit<2>  packet_color;
    bit<1>  disable_ucast_cutthru;
    bit<1>  enable_mcast_cutthru;
    bit<16> mcast_grp_a;
    bit<16> mcast_grp_b;
    bit<3>  _pad3;
    bit<13> level1_mcast_hash;
    bit<3>  _pad4;
    bit<13> level2_mcast_hash;
    bit<16> level1_exclusion_id;
    bit<7>  _pad5;
    bit<9>  level2_exclusion_id;
    bit<16> rid;
}

header ingress_intrinsic_metadata_from_parser_aux_t {
    bit<48> ingress_global_tstamp;
    bit<32> ingress_global_ver;
    bit<16> ingress_parser_err;
}

@name("generator_metadata_t") header generator_metadata_t_0 {
    bit<16> app_id;
    bit<16> batch_id;
    bit<16> instance_id;
}

header ingress_parser_control_signals {
    bit<3> priority;
    bit<5> _pad1;
    bit<8> parser_counter;
}

header ethernet_t {
    bit<24> dstOUI;
    bit<24> dstSTA;
    bit<24> srcOUI;
    bit<24> srcSTA;
    bit<16> ethertype;
}

header ipv4_t {
    bit<4>  version;
    bit<4>  ihl;
    bit<8>  diffserv;
    bit<16> totalLen;
    bit<16> identification;
    bit<3>  flags;
    bit<13> fragOffset;
    bit<8>  ttl;
    bit<8>  protocol;
    bit<16> hdrChecksum;
    bit<32> srcAddr;
    bit<32> dstAddr;
}

header ipv6_t {
    bit<4>   version;
    bit<8>   trafficClass;
    bit<20>  flowLabel;
    bit<16>  payloadLen;
    bit<8>   nextHdr;
    bit<8>   hopLimit;
    bit<128> srcAddr;
    bit<128> dstAddr;
}

header vlan_tag_t {
    bit<3>  prio;
    bit<1>  cfi;
    bit<12> vid;
    bit<16> ethertype;
}

header udp_t {
    bit<16> srcPort;
    bit<16> dstPort;
    bit<16> length_;
    bit<16> checksum;
}

header vxlan_t {
    bit<8>  flags;
    bit<24> reserved_1;
    bit<24> vni;
    bit<8>  reserved_2;
}

struct metadata {
    @name(".Eqzejr") 
    AbPvhk               Eqzejr;
    @name(".PdKkSx") 
    WeFXyH               PdKkSx;
    @name(".YKjpKX") 
    RjEUbC               YKjpKX;
    @name(".egress_l2_metadata") 
    egress_l2_metadata_t egress_l2_metadata;
    @name(".ipv4_metadata") 
    ipv4_metadata_t      ipv4_metadata;
    @name(".ipv6_metadata") 
    ipv6_metadata_t      ipv6_metadata;
    @name(".l2_metadata") 
    l2_metadata_t        l2_metadata;
    @name(".ozKgHM") 
    pKpXdV               ozKgHM;
    @name(".port_metadata") 
    port_metadata_t      port_metadata;
}

struct headers {
    @name(".arp") 
    arp_t                                          arp;
    @dont_trim @not_deparsed("ingress") @not_deparsed("egress") @pa_intrinsic_header("egress", "eg_intr_md") @pa_atomic("egress", "eg_intr_md.egress_port") @pa_fragment("egress", "eg_intr_md._pad1") @pa_fragment("egress", "eg_intr_md._pad7") @pa_fragment("egress", "eg_intr_md._pad8") @pa_mandatory_intrinsic_field("egress", "eg_intr_md.egress_port") @pa_mandatory_intrinsic_field("egress", "eg_intr_md.egress_cos") @name(".eg_intr_md") 
    egress_intrinsic_metadata_t                    eg_intr_md;
    @dont_trim @pa_intrinsic_header("egress", "eg_intr_md_for_mb") @pa_atomic("egress", "eg_intr_md_for_mb.egress_mirror_id") @pa_fragment("egress", "eg_intr_md_for_mb.coalesce_flush") @pa_mandatory_intrinsic_field("egress", "eg_intr_md_for_mb.egress_mirror_id") @pa_mandatory_intrinsic_field("egress", "eg_intr_md_for_mb.coalesce_flush") @pa_mandatory_intrinsic_field("egress", "eg_intr_md_for_mb.coalesce_length") @not_deparsed("ingress") @not_deparsed("egress") @name(".eg_intr_md_for_mb") 
    egress_intrinsic_metadata_for_mirror_buffer_t  eg_intr_md_for_mb;
    @dont_trim @pa_mandatory_intrinsic_field("egress", "eg_intr_md_for_oport.drop_ctl") @not_deparsed("ingress") @not_deparsed("egress") @pa_intrinsic_header("egress", "eg_intr_md_for_oport") @name(".eg_intr_md_for_oport") 
    egress_intrinsic_metadata_for_output_port_t    eg_intr_md_for_oport;
    @pa_fragment("egress", "eg_intr_md_from_parser_aux.coalesce_sample_count") @pa_fragment("egress", "eg_intr_md_from_parser_aux.clone_src") @pa_fragment("egress", "eg_intr_md_from_parser_aux.egress_parser_err") @pa_atomic("egress", "eg_intr_md_from_parser_aux.egress_parser_err") @not_deparsed("ingress") @not_deparsed("egress") @pa_intrinsic_header("egress", "eg_intr_md_from_parser_aux") @name(".eg_intr_md_from_parser_aux") 
    egress_intrinsic_metadata_from_parser_aux_t    eg_intr_md_from_parser_aux;
    @dont_trim @not_deparsed("ingress") @not_deparsed("egress") @pa_intrinsic_header("ingress", "ig_intr_md") @pa_mandatory_intrinsic_field("ingress", "ig_intr_md.ingress_port") @name(".ig_intr_md") 
    ingress_intrinsic_metadata_t                   ig_intr_md;
    @dont_trim @pa_intrinsic_header("ingress", "ig_intr_md_for_mb") @pa_atomic("ingress", "ig_intr_md_for_mb.ingress_mirror_id") @pa_mandatory_intrinsic_field("ingress", "ig_intr_md_for_mb.ingress_mirror_id") @not_deparsed("ingress") @not_deparsed("egress") @name(".ig_intr_md_for_mb") 
    ingress_intrinsic_metadata_for_mirror_buffer_t ig_intr_md_for_mb;
    @pa_atomic("ingress", "ig_intr_md_for_tm.ucast_egress_port") @pa_fragment("ingress", "ig_intr_md_for_tm.drop_ctl") @pa_fragment("ingress", "ig_intr_md_for_tm.qid") @pa_fragment("ingress", "ig_intr_md_for_tm._pad2") @pa_atomic("ingress", "ig_intr_md_for_tm.mcast_grp_a") @pa_fragment("ingress", "ig_intr_md_for_tm.mcast_grp_a") @pa_mandatory_intrinsic_field("ingress", "ig_intr_md_for_tm.mcast_grp_a") @pa_atomic("ingress", "ig_intr_md_for_tm.mcast_grp_b") @pa_fragment("ingress", "ig_intr_md_for_tm.mcast_grp_b") @pa_mandatory_intrinsic_field("ingress", "ig_intr_md_for_tm.mcast_grp_b") @pa_atomic("ingress", "ig_intr_md_for_tm.level1_mcast_hash") @pa_fragment("ingress", "ig_intr_md_for_tm._pad3") @pa_atomic("ingress", "ig_intr_md_for_tm.level2_mcast_hash") @pa_fragment("ingress", "ig_intr_md_for_tm._pad4") @pa_atomic("ingress", "ig_intr_md_for_tm.level1_exclusion_id") @pa_fragment("ingress", "ig_intr_md_for_tm.level1_exclusion_id") @pa_atomic("ingress", "ig_intr_md_for_tm.level2_exclusion_id") @pa_fragment("ingress", "ig_intr_md_for_tm._pad5") @pa_atomic("ingress", "ig_intr_md_for_tm.rid") @pa_fragment("ingress", "ig_intr_md_for_tm.rid") @not_deparsed("ingress") @not_deparsed("egress") @pa_intrinsic_header("ingress", "ig_intr_md_for_tm") @dont_trim @pa_mandatory_intrinsic_field("ingress", "ig_intr_md_for_tm.drop_ctl") @name(".ig_intr_md_for_tm") 
    ingress_intrinsic_metadata_for_tm_t            ig_intr_md_for_tm;
    @pa_fragment("ingress", "ig_intr_md_from_parser_aux.ingress_parser_err") @pa_atomic("ingress", "ig_intr_md_from_parser_aux.ingress_parser_err") @not_deparsed("ingress") @not_deparsed("egress") @pa_intrinsic_header("ingress", "ig_intr_md_from_parser_aux") @name(".ig_intr_md_from_parser_aux") 
    ingress_intrinsic_metadata_from_parser_aux_t   ig_intr_md_from_parser_aux;
    @not_deparsed("ingress") @not_deparsed("egress") @name(".ig_pg_md") 
    generator_metadata_t_0                         ig_pg_md;
    @not_deparsed("ingress") @not_deparsed("egress") @pa_intrinsic_header("ingress", "ig_prsr_ctrl") @name(".ig_prsr_ctrl") 
    ingress_parser_control_signals                 ig_prsr_ctrl;
    @name(".inner_ethernet") 
    ethernet_t                                     inner_ethernet;
    @name(".inner_ipv4") 
    ipv4_t                                         inner_ipv4;
    @name(".inner_ipv6") 
    ipv6_t                                         inner_ipv6;
    @name(".inner_vlan_tag") 
    vlan_tag_t                                     inner_vlan_tag;
    @name(".outer_ethernet") 
    ethernet_t                                     outer_ethernet;
    @name(".outer_ipv4") 
    ipv4_t                                         outer_ipv4;
    @name(".outer_ipv6") 
    ipv6_t                                         outer_ipv6;
    @name(".outer_vlan_tag") 
    vlan_tag_t                                     outer_vlan_tag;
    @name(".udp") 
    udp_t                                          udp;
    @name(".vxlan") 
    vxlan_t                                        vxlan;
}
#include <tofino/stateful_alu.p4>

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".parse_arp") state parse_arp {
        packet.extract(hdr.arp);
        transition accept;
    }
    @name(".parse_ethernet") state parse_ethernet {
        packet.extract(hdr.outer_ethernet);
        meta.l2_metadata.dstOUI = hdr.outer_ethernet.dstOUI;
        meta.l2_metadata.dstSTA = hdr.outer_ethernet.dstSTA;
        meta.l2_metadata.srcOUI = hdr.outer_ethernet.srcOUI;
        meta.l2_metadata.srcSTA = hdr.outer_ethernet.srcSTA;
        transition select(hdr.outer_ethernet.ethertype) {
            16w0x8100: parse_outer_vlan_tag;
            16w0x800: parse_outer_ipv4;
            16w0x86dd: parse_outer_ipv6;
            16w0x806: parse_arp;
            default: accept;
        }
    }
    @name(".parse_inner_ethernet") state parse_inner_ethernet {
        packet.extract(hdr.inner_ethernet);
        transition select(hdr.inner_ethernet.ethertype) {
            16w0x800: parse_inner_ipv4;
            16w0x86dd: parse_inner_ipv6;
            default: accept;
        }
    }
    @name(".parse_inner_ipv4") state parse_inner_ipv4 {
        packet.extract(hdr.inner_ipv4);
        transition accept;
    }
    @name(".parse_inner_ipv6") state parse_inner_ipv6 {
        packet.extract(hdr.inner_ipv6);
        transition accept;
    }
    @name(".parse_outer_ipv4") state parse_outer_ipv4 {
        packet.extract(hdr.outer_ipv4);
        transition select(hdr.outer_ipv4.fragOffset, hdr.outer_ipv4.ihl, hdr.outer_ipv4.protocol) {
            (13w0x0, 4w0x5, 8w0x11): parse_udp;
            default: accept;
        }
    }
    @name(".parse_outer_ipv6") state parse_outer_ipv6 {
        packet.extract(hdr.outer_ipv6);
        transition accept;
    }
    @name(".parse_outer_vlan_tag") state parse_outer_vlan_tag {
        packet.extract(hdr.outer_vlan_tag);
        transition select(hdr.outer_vlan_tag.ethertype) {
            16w0x800: parse_outer_ipv4;
            16w0x86dd: parse_outer_ipv6;
            16w0x806: parse_arp;
            default: accept;
        }
    }
    @name(".parse_udp") state parse_udp {
        packet.extract(hdr.udp);
        transition select(hdr.udp.dstPort) {
            16w0x12b5: parse_vxlan;
            default: accept;
        }
    }
    @name(".parse_vxlan") state parse_vxlan {
        packet.extract(hdr.vxlan);
        meta.l2_metadata.eDTSaM = 2w0x1;
        transition parse_inner_ethernet;
    }
    @name(".start") state start {
        transition parse_ethernet;
    }
}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".nop") action nop() {
        ;
    }
    @name(".add_vlan_tag") action add_vlan_tag() {
        hdr.outer_vlan_tag.setValid();
        hdr.outer_vlan_tag.vid = meta.egress_l2_metadata.vid;
        hdr.outer_vlan_tag.ethertype = hdr.outer_ethernet.ethertype;
        hdr.outer_ethernet.ethertype = 16w0x8100;
    }
    @name(".bd2vid") action bd2vid(bit<12> ObALmB) {
        meta.egress_l2_metadata.vid = ObALmB;
        hdr.outer_vlan_tag.setInvalid();
    }
    @name(".add_vlan_tag") table add_vlan_tag_0 {
        actions = {
            nop;
            add_vlan_tag;
        }
        key = {
            meta.egress_l2_metadata.vid        : exact;
            meta.egress_l2_metadata.egress_port: exact;
        }
        size = 64;
    }
    @name(".assign_vid") table assign_vid {
        actions = {
            bd2vid;
        }
        key = {
            meta.egress_l2_metadata.outer_bd: exact;
        }
        size = 4096;
    }
    apply {
        assign_vid.apply();
        add_vlan_tag_0.apply();
    }
}

@name("jeqIuB") struct jeqIuB {
    bit<8>  zVITkG;
    bit<16> outer_bd;
    bit<24> srcOUI;
    bit<24> srcSTA;
    bit<32> srcAddr;
}

@name("RgamWT") struct RgamWT {
    bit<8>  zVITkG;
    bit<24> srcOUI;
    bit<24> srcSTA;
    bit<16> outer_bd;
    bit<16> inner_bd;
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".uZpeEH") action uZpeEH() {
        meta.egress_l2_metadata.DxjBnx = 1w0x1;
        meta.egress_l2_metadata.xALOuI = 1w0x1;
        meta.egress_l2_metadata.VqbwXd = meta.egress_l2_metadata.outer_bd + 16w0x1000;
    }
    @name(".QXYBjG") action QXYBjG() {
        digest<jeqIuB>((bit<32>)0x0, { meta.ozKgHM.zVITkG, meta.l2_metadata.outer_bd, hdr.inner_ethernet.srcOUI, hdr.inner_ethernet.srcSTA, hdr.outer_ipv4.srcAddr });
    }
    @name(".XVktOe") action XVktOe(bit<16> rJWdDI) {
        meta.ipv4_metadata.vrf = rJWdDI;
    }
    @name(".wpFyFj") action wpFyFj(bit<8> NldXIO, bit<1> zbyrRT, bit<1> iCFOSL, bit<1> gJQdqX, bit<1> EsFJTP) {
        meta.l2_metadata.mUhTtj = 1w0x1;
        meta.PdKkSx.VLGXXG = NldXIO;
        meta.PdKkSx.OTmmdU = zbyrRT;
        meta.PdKkSx.lhgqZR = iCFOSL;
        meta.PdKkSx.vxRZLD = gJQdqX;
        meta.PdKkSx.PqcjFS = EsFJTP;
    }
    @name(".FjFvSI") action FjFvSI() {
        digest<RgamWT>((bit<32>)0x0, { meta.ozKgHM.zVITkG, meta.l2_metadata.srcOUI, meta.l2_metadata.srcSTA, meta.l2_metadata.outer_bd, meta.l2_metadata.inner_bd });
    }
    @name(".jwLDdv") action jwLDdv() {
    }
    @name(".Ayapvg") action Ayapvg(bit<16> ZPSBzg) {
        meta.l2_metadata.outer_bd = ZPSBzg;
    }
    @name(".jYRXTf") action jYRXTf() {
    }
    @name(".QYBPRQ") action QYBPRQ(bit<16> ObALmB, bit<8> NldXIO, bit<1> zbyrRT, bit<1> iCFOSL, bit<1> gJQdqX, bit<1> EsFJTP, bit<1> LqZpLg) {
        meta.l2_metadata.outer_bd = ObALmB;
        meta.l2_metadata.mUhTtj = LqZpLg;
        meta.PdKkSx.VLGXXG = NldXIO;
        meta.PdKkSx.OTmmdU = zbyrRT;
        meta.PdKkSx.lhgqZR = iCFOSL;
        meta.PdKkSx.vxRZLD = gJQdqX;
        meta.PdKkSx.PqcjFS = EsFJTP;
    }
    @name(".YpQxby") action YpQxby() {
        meta.l2_metadata.JFtqsz = 1w0x1;
        meta.l2_metadata.OjymPH = 1w0x1;
    }
    @name(".JZMMTw") action JZMMTw() {
        meta.PdKkSx.TNJQUK = 1w0x1;
    }
    @name(".ZByrIe") action ZByrIe() {
        hdr.outer_ethernet.ethertype = hdr.outer_vlan_tag.ethertype;
        meta.l2_metadata.prio = hdr.outer_vlan_tag.prio;
        hdr.outer_vlan_tag.setInvalid();
    }
    @name(".JnIDid") action JnIDid() {
        meta.egress_l2_metadata.GbMjEH = 1w0x1;
        meta.egress_l2_metadata.MXEAcT = 1w0x1;
        meta.egress_l2_metadata.VqbwXd = meta.egress_l2_metadata.outer_bd;
    }
    @name(".uYBjrZ") action uYBjrZ() {
    }
    @name(".yTtrnk") action yTtrnk(bit<8> JuQPYe) {
    }
    @name(".xfABlB") action xfABlB() {
        meta.l2_metadata.AlAsan = 1w0x1;
        meta.ozKgHM.zVITkG = 8w0x0;
    }
    @name(".xsDQie") action xsDQie(bit<16> yppSOY) {
        meta.egress_l2_metadata.fqhobT = 1w0x1;
        meta.egress_l2_metadata.inner_bd = yppSOY;
        hdr.ig_intr_md_for_tm.ucast_egress_port = (bit<9>)yppSOY;
        meta.egress_l2_metadata.egress_port = (bit<9>)yppSOY;
    }
    @name(".tsXBkz") action tsXBkz(bit<16> hkkrmJ) {
        meta.egress_l2_metadata.DxjBnx = 1w0x1;
        meta.egress_l2_metadata.VqbwXd = hkkrmJ;
    }
    @name(".ruSbdS") action ruSbdS() {
    }
    @name(".sRuUvS") action sRuUvS(bit<16> ZPSBzg, bit<8> NldXIO, bit<1> zbyrRT, bit<1> iCFOSL, bit<1> gJQdqX, bit<1> EsFJTP) {
        meta.l2_metadata.pQXqBl = ZPSBzg;
        meta.l2_metadata.mUhTtj = 1w0x1;
        meta.PdKkSx.VLGXXG = NldXIO;
        meta.PdKkSx.OTmmdU = zbyrRT;
        meta.PdKkSx.lhgqZR = iCFOSL;
        meta.PdKkSx.vxRZLD = gJQdqX;
        meta.PdKkSx.PqcjFS = EsFJTP;
    }
    @name(".sgfrDS") action sgfrDS() {
        ;
    }
    @name(".ukhAli") action ukhAli() {
        meta.egress_l2_metadata.vRiVoY = 1w0x1;
        meta.egress_l2_metadata.VqbwXd = meta.egress_l2_metadata.outer_bd;
    }
    @name(".TwIQHU") action TwIQHU(bit<16> ZJeNes) {
        meta.Eqzejr.SXktkN = ZJeNes;
    }
    @name(".uNBXVV") action uNBXVV() {
        meta.ipv4_metadata.srcAddr = hdr.inner_ipv4.srcAddr;
        meta.ipv4_metadata.dstAddr = hdr.inner_ipv4.dstAddr;
        meta.ipv6_metadata.srcAddr = hdr.outer_ipv6.srcAddr;
        meta.ipv6_metadata.dstAddr = hdr.outer_ipv6.dstAddr;
        meta.l2_metadata.dstOUI = hdr.inner_ethernet.dstOUI;
        meta.l2_metadata.dstSTA = hdr.inner_ethernet.dstSTA;
        meta.l2_metadata.srcOUI = hdr.inner_ethernet.srcOUI;
        meta.l2_metadata.srcSTA = hdr.inner_ethernet.srcSTA;
    }
    @name(".zEaBcj") action zEaBcj() {
        meta.l2_metadata.eDTSaM = 2w0x0;
        meta.l2_metadata.inner_bd = (bit<16>)meta.port_metadata.ouVJSA;
        meta.ipv4_metadata.srcAddr = hdr.outer_ipv4.srcAddr;
        meta.ipv4_metadata.dstAddr = hdr.outer_ipv4.dstAddr;
        meta.ipv6_metadata.srcAddr = hdr.inner_ipv6.srcAddr;
        meta.ipv6_metadata.dstAddr = hdr.inner_ipv6.dstAddr;
        meta.l2_metadata.dstOUI = hdr.outer_ethernet.dstOUI;
        meta.l2_metadata.dstSTA = hdr.outer_ethernet.dstSTA;
        meta.l2_metadata.srcOUI = hdr.outer_ethernet.srcOUI;
        meta.l2_metadata.srcSTA = hdr.outer_ethernet.srcSTA;
    }
    @name(".SBqFEe") action SBqFEe(bit<16> UWsnEK) {
        meta.l2_metadata.inner_bd = UWsnEK;
    }
    @name(".KQcrRq") action KQcrRq() {
        meta.l2_metadata.FZIXaP = 1w0x1;
        meta.ozKgHM.zVITkG = 8w0x1;
    }
    @name(".set_ingress_port_properties") action set_ingress_port_properties(bit<14> DSyDIW, bit<1> wPlBaD, bit<12> jsYLqr, bit<1> tTfUVS) {
        meta.port_metadata.ouVJSA = DSyDIW;
        meta.port_metadata.cCOHKE = wPlBaD;
        meta.port_metadata.vid = jsYLqr;
        meta.port_metadata.huEsCO = tTfUVS;
    }
    @name(".GXegax") action GXegax(bit<8> NldXIO, bit<1> zbyrRT, bit<1> iCFOSL, bit<1> gJQdqX, bit<1> EsFJTP) {
        meta.l2_metadata.pQXqBl[11:0] = ((bit<16>)meta.port_metadata.vid)[11:0];
        meta.l2_metadata.mUhTtj = 1w0x1;
        meta.PdKkSx.VLGXXG = NldXIO;
        meta.PdKkSx.OTmmdU = zbyrRT;
        meta.PdKkSx.lhgqZR = iCFOSL;
        meta.PdKkSx.vxRZLD = gJQdqX;
        meta.PdKkSx.PqcjFS = EsFJTP;
    }
    @name(".GrmhMU") action GrmhMU() {
        meta.l2_metadata.dhmjSj = 1w0x1;
    }
    @name(".MbuqfL") action MbuqfL() {
        meta.egress_l2_metadata.dstOUI = meta.l2_metadata.dstOUI;
        meta.egress_l2_metadata.dstSTA = meta.l2_metadata.dstSTA;
        meta.egress_l2_metadata.srcOUI = meta.l2_metadata.srcOUI;
        meta.egress_l2_metadata.srcSTA = meta.l2_metadata.srcSTA;
        meta.egress_l2_metadata.outer_bd = meta.l2_metadata.outer_bd;
    }
    @name(".AosIFt") table AosIFt {
        actions = {
            uZpeEH;
        }
        size = 1;
    }
    @name(".FObudl") table FObudl {
        actions = {
            QXYBjG;
        }
        size = 1;
    }
    @name(".FsxDka") table FsxDka {
        actions = {
            XVktOe;
        }
        key = {
            meta.PdKkSx.VLGXXG        : exact;
            meta.ipv4_metadata.dstAddr: lpm;
        }
        size = 16384;
    }
    @name(".FyMYiX") table FyMYiX {
        actions = {
            wpFyFj;
        }
        key = {
            hdr.outer_vlan_tag.vid: exact;
        }
        size = 4096;
    }
    @name(".GKgaxO") table GKgaxO {
        actions = {
            FjFvSI;
        }
        size = 1;
    }
    @name(".GiINoN") table GiINoN {
        actions = {
            jwLDdv;
            Ayapvg;
            jYRXTf;
        }
        key = {
            meta.port_metadata.ouVJSA   : ternary;
            hdr.outer_vlan_tag.isValid(): exact;
            hdr.outer_vlan_tag.vid      : ternary;
        }
        size = 4096;
    }
    @name(".KPlvUi") table KPlvUi {
        actions = {
            QYBPRQ;
            YpQxby;
        }
        key = {
            hdr.vxlan.vni: exact;
        }
        size = 4096;
    }
    @name(".KhzFiy") table KhzFiy {
        actions = {
            JZMMTw;
        }
        key = {
            meta.l2_metadata.pQXqBl: ternary;
            meta.l2_metadata.dstOUI: exact;
            meta.l2_metadata.dstSTA: exact;
        }
        size = 512;
    }
    @name(".LbcSdm") table LbcSdm {
        actions = {
            ZByrIe;
        }
        size = 1;
    }
    @name(".OgtsFH") table OgtsFH {
        actions = {
            JnIDid;
            uYBjrZ;
        }
        key = {
            meta.egress_l2_metadata.dstOUI: exact;
            meta.egress_l2_metadata.dstSTA: exact;
        }
        size = 1;
    }
    @name(".OsNzCx") table OsNzCx {
        actions = {
            yTtrnk;
            xfABlB;
        }
        key = {
            meta.l2_metadata.srcOUI  : exact;
            meta.l2_metadata.srcSTA  : exact;
            meta.l2_metadata.outer_bd: exact;
            meta.l2_metadata.inner_bd: exact;
        }
        size = 65536;
    }
    @name(".PHSvkl") table PHSvkl {
        actions = {
            xsDQie;
            tsXBkz;
            ruSbdS;
        }
        key = {
            meta.egress_l2_metadata.dstOUI  : exact;
            meta.egress_l2_metadata.dstSTA  : exact;
            meta.egress_l2_metadata.outer_bd: exact;
        }
        size = 65536;
    }
    @name(".RmXtve") table RmXtve {
        actions = {
            sRuUvS;
            sgfrDS;
        }
        key = {
            meta.port_metadata.ouVJSA: exact;
            hdr.outer_vlan_tag.vid   : exact;
        }
        size = 1024;
    }
    @name(".UHdtQj") table UHdtQj {
        actions = {
            ukhAli;
        }
        size = 1;
    }
    @atcam_partition_index("ipv4_metadata.vrf") @atcam_number_partitions(16384) @name(".XWEKAE") table XWEKAE {
        actions = {
            TwIQHU;
        }
        key = {
            meta.ipv4_metadata.vrf    : exact;
            meta.ipv4_metadata.dstAddr: lpm;
        }
        size = 147456;
    }
    @name(".ceGwFc") table ceGwFc {
        actions = {
            uNBXVV;
            zEaBcj;
        }
        key = {
            hdr.outer_ethernet.dstOUI: exact;
            hdr.outer_ethernet.dstSTA: exact;
            hdr.outer_ipv4.dstAddr   : exact;
            meta.l2_metadata.eDTSaM  : exact;
        }
        size = 1024;
    }
    @name(".chPApZ") table chPApZ {
        actions = {
            SBqFEe;
            KQcrRq;
        }
        key = {
            hdr.outer_ipv4.srcAddr: exact;
        }
        size = 4096;
    }
    @name(".fDUvPP") table fDUvPP {
        actions = {
            TwIQHU;
            sgfrDS;
        }
        key = {
            meta.PdKkSx.VLGXXG        : exact;
            meta.ipv4_metadata.dstAddr: exact;
        }
        size = 65536;
    }
    @name(".ingress_port_properties") table ingress_port_properties {
        actions = {
            set_ingress_port_properties;
        }
        key = {
            hdr.ig_intr_md.ingress_port: exact;
        }
        size = 288;
    }
    @name(".jubrcZ") table jubrcZ {
        actions = {
            GXegax;
        }
        key = {
            meta.port_metadata.vid: exact;
        }
        size = 4096;
    }
    @name(".rmac") table rmac {
        actions = {
            GrmhMU;
        }
        key = {
            hdr.outer_ethernet.dstOUI: exact;
            hdr.outer_ethernet.dstSTA: exact;
        }
        size = 64;
    }
    @name(".sFQXXt") table sFQXXt {
        actions = {
            MbuqfL;
        }
        size = 1;
    }
    apply {
        if (hdr.ig_intr_md.resubmit_flag == 1w0x0) {
            ingress_port_properties.apply();
        }
        rmac.apply();
        switch (ceGwFc.apply().action_run) {
            zEaBcj: {
                if (meta.port_metadata.huEsCO == 1w0x1) {
                    GiINoN.apply();
                }
                if (hdr.outer_vlan_tag.isValid()) {
                    switch (RmXtve.apply().action_run) {
                        sgfrDS: {
                            FyMYiX.apply();
                        }
                    }

                }
                jubrcZ.apply();
            }
            uNBXVV: {
                chPApZ.apply();
                KPlvUi.apply();
            }
        }

        if (meta.port_metadata.cCOHKE == 1w0x0 && meta.l2_metadata.FZIXaP == 1w0x0) {
            OsNzCx.apply();
        }
        if (meta.l2_metadata.JFtqsz == 1w0x0 && meta.l2_metadata.OjymPH == 1w0x0) {
            KhzFiy.apply();
        }
        if (meta.l2_metadata.outer_bd != 16w0x0) {
            sFQXXt.apply();
        }
        if (meta.YKjpKX.ZtjVUq == 1w0x0 && meta.YKjpKX.tgfjtx == 1w0x0 && meta.l2_metadata.JFtqsz == 1w0x0 && meta.PdKkSx.TNJQUK == 1w0x1) {
            if (meta.PdKkSx.OTmmdU == 1w0x1 && (meta.l2_metadata.eDTSaM == 2w0x0 && hdr.outer_ipv4.isValid() || meta.l2_metadata.eDTSaM != 2w0x0 && hdr.inner_ipv4.isValid())) {
                switch (fDUvPP.apply().action_run) {
                    sgfrDS: {
                        FsxDka.apply();
                        if (meta.ipv4_metadata.vrf != 16w0x0) {
                            XWEKAE.apply();
                        }
                    }
                }

            }
        }
        if (meta.l2_metadata.JFtqsz == 1w0x0) {
            switch (PHSvkl.apply().action_run) {
                ruSbdS: {
                    switch (OgtsFH.apply().action_run) {
                        uYBjrZ: {
                            if (meta.egress_l2_metadata.dstOUI & 24w0x10000 == 24w0x10000) {
                                AosIFt.apply();
                            }
                            UHdtQj.apply();
                        }
                    }

                }
            }

        }
        if (meta.l2_metadata.FZIXaP == 1w0x1) {
            FObudl.apply();
        }
        if (meta.l2_metadata.AlAsan == 1w0x1) {
            GKgaxO.apply();
        }
        if (hdr.outer_vlan_tag.isValid()) {
            LbcSdm.apply();
        }
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit(hdr.outer_ethernet);
        packet.emit(hdr.outer_vlan_tag);
        packet.emit(hdr.arp);
        packet.emit(hdr.outer_ipv6);
        packet.emit(hdr.outer_ipv4);
        packet.emit(hdr.udp);
        packet.emit(hdr.vxlan);
        packet.emit(hdr.inner_ethernet);
        packet.emit(hdr.inner_ipv6);
        packet.emit(hdr.inner_ipv4);
    }
}

control verifyChecksum(inout headers hdr, inout metadata meta) {
    apply {
    }
}

control computeChecksum(inout headers hdr, inout metadata meta) {
    apply {
    }
}

V1Switch(ParserImpl(), verifyChecksum(), ingress(), egress(), computeChecksum(), DeparserImpl()) main;

