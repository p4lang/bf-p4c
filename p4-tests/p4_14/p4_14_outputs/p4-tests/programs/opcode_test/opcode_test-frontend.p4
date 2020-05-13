#include <core.p4>
#include <v1model.p4>

struct meta_t {
    bit<32> calc1;
    bit<32> calc2;
    bit<32> calc3;
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

header ethernet_t {
    bit<48> dstAddr;
    bit<48> srcAddr;
    bit<16> etherType;
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

header tcp_t {
    bit<16> srcPort;
    bit<16> dstPort;
    bit<32> seqNo;
    bit<32> ackNo;
    bit<4>  dataOffset;
    bit<4>  res;
    bit<8>  flags;
    bit<16> window;
    bit<16> checksum;
    bit<16> urgentPtr;
}

header udp_t {
    bit<16> srcPort;
    bit<16> dstPort;
    bit<16> length_;
    bit<16> checksum;
}

struct metadata {
    @name(".meta") 
    meta_t meta;
}

struct headers {
    @dont_trim @not_deparsed("ingress") @not_deparsed("egress") @pa_intrinsic_header("egress", "eg_intr_md") @pa_atomic("egress", "eg_intr_md.egress_port") @pa_fragment("egress", "eg_intr_md._pad1") @pa_fragment("egress", "eg_intr_md._pad7") @pa_fragment("egress", "eg_intr_md._pad8") @pa_mandatory_intrinsic_field("egress", "eg_intr_md.egress_port") @pa_mandatory_intrinsic_field("egress", "eg_intr_md.egress_cos") @name(".eg_intr_md") 
    egress_intrinsic_metadata_t                    eg_intr_md;
    @dont_trim @pa_intrinsic_header("egress", "eg_intr_md_for_mb") @pa_atomic("egress", "eg_intr_md_for_mb.egress_mirror_id") @pa_fragment("egress", "eg_intr_md_for_mb.coalesce_flush") @pa_mandatory_intrinsic_field("egress", "eg_intr_md_for_mb.egress_mirror_id") @pa_mandatory_intrinsic_field("egress", "eg_intr_md_for_mb.coalesce_flush") @pa_mandatory_intrinsic_field("egress", "eg_intr_md_for_mb.coalesce_length") @not_deparsed("ingress") @not_deparsed("egress") @name(".eg_intr_md_for_mb") 
    egress_intrinsic_metadata_for_mirror_buffer_t  eg_intr_md_for_mb;
    @dont_trim @pa_mandatory_intrinsic_field("egress", "eg_intr_md_for_oport.drop_ctl") @not_deparsed("ingress") @not_deparsed("egress") @pa_intrinsic_header("egress", "eg_intr_md_for_oport") @name(".eg_intr_md_for_oport") 
    egress_intrinsic_metadata_for_output_port_t    eg_intr_md_for_oport;
    @pa_fragment("egress", "eg_intr_md_from_parser_aux.coalesce_sample_count") @pa_fragment("egress", "eg_intr_md_from_parser_aux.clone_src") @pa_fragment("egress", "eg_intr_md_from_parser_aux.egress_parser_err") @pa_atomic("egress", "eg_intr_md_from_parser_aux.egress_parser_err") @not_deparsed("ingress") @not_deparsed("egress") @pa_intrinsic_header("egress", "eg_intr_md_from_parser_aux") @name(".eg_intr_md_from_parser_aux") 
    egress_intrinsic_metadata_from_parser_aux_t    eg_intr_md_from_parser_aux;
    @name(".ethernet") 
    ethernet_t                                     ethernet;
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
    @pa_container_size("ingress", "ipv4.diffserv", 8) @pa_container_size("ingress", "ipv4.identification", 16) @pa_container_size("ingress", "ipv4.dstAddr", 32) @name(".ipv4") 
    ipv4_t                                         ipv4;
    @name(".tcp") 
    tcp_t                                          tcp;
    @name(".udp") 
    udp_t                                          udp;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".parse_ethernet") state parse_ethernet {
        packet.extract<ethernet_t>(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            16w0x800: parse_ipv4;
            default: accept;
        }
    }
    @name(".parse_ipv4") state parse_ipv4 {
        packet.extract<ipv4_t>(hdr.ipv4);
        transition select(hdr.ipv4.fragOffset, hdr.ipv4.protocol) {
            (13w0, 8w6): parse_tcp;
            (13w0, 8w17): parse_udp;
            default: accept;
        }
    }
    @name(".parse_tcp") state parse_tcp {
        packet.extract<tcp_t>(hdr.tcp);
        transition accept;
    }
    @name(".parse_udp") state parse_udp {
        packet.extract<udp_t>(hdr.udp);
        transition accept;
    }
    @name(".start") state start {
        transition parse_ethernet;
    }
}
#include <tofino/p4_14_prim.p4>

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    bit<16> tmp_5;
    bit<16> tmp_6;
    bit<32> tmp_7;
    bit<32> tmp_8;
    bit<8> tmp_9;
    bit<8> tmp_10;
    @name(".invalidate_port") action invalidate_port_0() {
        invalidate<bit<9>>(hdr.ig_intr_md_for_tm.ucast_egress_port);
    }
    @name(".do_nothing") action do_nothing_0() {
    }
    @name(".do_nothing") action do_nothing_4() {
    }
    @name(".do_nothing") action do_nothing_5() {
    }
    @name(".do_nothing") action do_nothing_6() {
    }
    @name(".set_p") action set_p_0(bit<9> p) {
        hdr.ig_intr_md_for_tm.ucast_egress_port = p;
    }
    @name(".a16bit_add") action a16bit_add_0(bit<16> value) {
        hdr.ipv4.identification = hdr.ipv4.identification + value;
    }
    @name(".a16bit_bit_and") action a16bit_bit_and_0(bit<16> value) {
        hdr.ipv4.identification = hdr.ipv4.identification & value;
    }
    @name(".a16bit_bit_andca") action a16bit_bit_andca_0(bit<16> value) {
        hdr.ipv4.identification = ~hdr.ipv4.identification & value;
    }
    @name(".a16bit_bit_andcb") action a16bit_bit_andcb_0(bit<16> value) {
        hdr.ipv4.identification = hdr.ipv4.identification & ~value;
    }
    @name(".a16bit_bit_nand") action a16bit_bit_nand_0(bit<16> value) {
        hdr.ipv4.identification = ~(hdr.ipv4.identification & value);
    }
    @name(".a16bit_bit_nor") action a16bit_bit_nor_0(bit<16> value) {
        hdr.ipv4.identification = ~(hdr.ipv4.identification | value);
    }
    @name(".a16bit_bit_not") action a16bit_bit_not_0() {
        hdr.ipv4.identification = ~hdr.ipv4.identification;
    }
    @name(".a16bit_bit_or") action a16bit_bit_or_0(bit<16> value) {
        hdr.ipv4.identification = hdr.ipv4.identification | value;
    }
    @name(".a16bit_bit_orca") action a16bit_bit_orca_0(bit<16> value) {
        hdr.ipv4.identification = ~hdr.ipv4.identification | value;
    }
    @name(".a16bit_bit_orcb") action a16bit_bit_orcb_0(bit<16> value) {
        hdr.ipv4.identification = hdr.ipv4.identification | ~value;
    }
    @name(".a16bit_bit_xnor") action a16bit_bit_xnor_0(bit<16> value) {
        hdr.ipv4.identification = ~(hdr.ipv4.identification ^ value);
    }
    @name(".a16bit_bit_xor") action a16bit_bit_xor_0(bit<16> value) {
        hdr.ipv4.identification = hdr.ipv4.identification ^ value;
    }
    @name(".a16bit_max") action a16bit_max_0(bit<16> value) {
        if (hdr.ipv4.identification >= value) 
            tmp_5 = hdr.ipv4.identification;
        else 
            tmp_5 = value;
        hdr.ipv4.identification = tmp_5;
    }
    @name(".a16bit_min") action a16bit_min_0(bit<16> value) {
        if (hdr.ipv4.identification <= value) 
            tmp_6 = hdr.ipv4.identification;
        else 
            tmp_6 = value;
        hdr.ipv4.identification = tmp_6;
    }
    @name(".a16bit_modify_field") action a16bit_modify_field_0(bit<16> value) {
        hdr.ipv4.identification = value;
    }
    @name(".a16bit_modify_field_bit_mask") action a16bit_modify_field_bit_mask_0(bit<16> value) {
        hdr.ipv4.identification = hdr.ipv4.identification & 16w0x5555 | value & 16w0xaaaa;
    }
    @name(".a16bit_modify_field_deposit_field") action a16bit_modify_field_deposit_field_0(bit<16> value) {
        hdr.ipv4.identification[15:8] = value[15:8];
    }
    @name(".a16bit_shift_left_2") action a16bit_shift_left() {
        hdr.ipv4.identification = hdr.ipv4.identification << 2;
    }
    @name(".a16bit_shift_right_5") action a16bit_shift_right() {
        hdr.ipv4.identification = hdr.ipv4.identification >> 5;
    }
    @name(".a16bit_subtract") action a16bit_subtract_0() {
        hdr.ipv4.identification = hdr.ipv4.identification + 16w65535;
    }
    @name(".a16bit_subtract_reverse") action a16bit_subtract_reverse_0(bit<16> value) {
        hdr.ipv4.identification = value - hdr.ipv4.identification;
    }
    @name(".a16bit_modify_field_load_const") action a16bit_modify_field_load_const_0() {
        hdr.ipv4.identification = 16w0x7735;
    }
    @name(".a16bit_funnel_shift") action a16bit_funnel_shift_0() {
        hdr.ipv4.identification = (bit<16>)(hdr.ethernet.etherType ++ hdr.ipv4.identification >> 13);
    }
    @name(".a32bit_add") action a32bit_add_0(bit<32> value) {
        hdr.ipv4.dstAddr = hdr.ipv4.dstAddr + value;
    }
    @name(".a32bit_bit_and") action a32bit_bit_and_0(bit<32> value) {
        hdr.ipv4.dstAddr = hdr.ipv4.dstAddr & value;
    }
    @name(".a32bit_bit_andca") action a32bit_bit_andca_0(bit<32> value) {
        hdr.ipv4.dstAddr = ~hdr.ipv4.dstAddr & value;
    }
    @name(".a32bit_bit_andcb") action a32bit_bit_andcb_0(bit<32> value) {
        hdr.ipv4.dstAddr = hdr.ipv4.dstAddr & ~value;
    }
    @name(".a32bit_bit_nand") action a32bit_bit_nand_0(bit<32> value) {
        hdr.ipv4.dstAddr = ~(hdr.ipv4.dstAddr & value);
    }
    @name(".a32bit_bit_nor") action a32bit_bit_nor_0(bit<32> value) {
        hdr.ipv4.dstAddr = ~(hdr.ipv4.dstAddr | value);
    }
    @name(".a32bit_bit_not") action a32bit_bit_not_0() {
        hdr.ipv4.dstAddr = ~hdr.ipv4.dstAddr;
    }
    @name(".a32bit_bit_or") action a32bit_bit_or_0(bit<32> value) {
        hdr.ipv4.dstAddr = hdr.ipv4.dstAddr | value;
    }
    @name(".a32bit_bit_orca") action a32bit_bit_orca_0(bit<32> value) {
        hdr.ipv4.dstAddr = ~hdr.ipv4.dstAddr | value;
    }
    @name(".a32bit_bit_orcb") action a32bit_bit_orcb_0(bit<32> value) {
        hdr.ipv4.dstAddr = hdr.ipv4.dstAddr | ~value;
    }
    @name(".a32bit_bit_xnor") action a32bit_bit_xnor_0(bit<32> value) {
        hdr.ipv4.dstAddr = ~(hdr.ipv4.dstAddr ^ value);
    }
    @name(".a32bit_bit_xor") action a32bit_bit_xor_0(bit<32> value) {
        hdr.ipv4.dstAddr = hdr.ipv4.dstAddr ^ value;
    }
    @name(".a32bit_max") action a32bit_max_0(bit<32> value) {
        if (hdr.ipv4.dstAddr >= value) 
            tmp_7 = hdr.ipv4.dstAddr;
        else 
            tmp_7 = value;
        hdr.ipv4.dstAddr = tmp_7;
    }
    @name(".a32bit_min") action a32bit_min_0(bit<32> value) {
        if (hdr.ipv4.dstAddr <= value) 
            tmp_8 = hdr.ipv4.dstAddr;
        else 
            tmp_8 = value;
        hdr.ipv4.dstAddr = tmp_8;
    }
    @name(".a32bit_modify_field") action a32bit_modify_field_0(bit<32> value) {
        hdr.ipv4.dstAddr = value;
    }
    @name(".a32bit_modify_field_bit_mask") action a32bit_modify_field_bit_mask_0(bit<32> value) {
        hdr.ipv4.dstAddr = hdr.ipv4.dstAddr & 32w0x55555555 | value & 32w0xaaaaaaaa;
    }
    @name(".a32bit_modify_field_deposit_field") action a32bit_modify_field_deposit_field_0(bit<32> value) {
        hdr.ipv4.dstAddr[31:16] = value[31:16];
    }
    @name(".a32bit_shift_left_2") action a32bit_shift_left() {
        hdr.ipv4.dstAddr = hdr.ipv4.dstAddr << 2;
    }
    @name(".a32bit_shift_right_5") action a32bit_shift_right() {
        hdr.ipv4.dstAddr = hdr.ipv4.dstAddr >> 5;
    }
    @name(".a32bit_subtract") action a32bit_subtract_0() {
        hdr.ipv4.dstAddr = hdr.ipv4.dstAddr + 32w4294967295;
    }
    @name(".a32bit_subtract_reverse") action a32bit_subtract_reverse_0(bit<32> value) {
        hdr.ipv4.dstAddr = value - hdr.ipv4.dstAddr;
    }
    @name(".a32bit_modify_field_load_const") action a32bit_modify_field_load_const_0() {
        hdr.ipv4.dstAddr = 32w4096;
    }
    @name(".a32bit_funnel_shift") action a32bit_funnel_shift_0() {
        hdr.ipv4.dstAddr = (bit<32>)(hdr.ipv4.srcAddr ++ hdr.ipv4.dstAddr >> 8);
    }
    @name(".a8bit_add") action a8bit_add_0(bit<8> value) {
        hdr.ipv4.diffserv = hdr.ipv4.diffserv + value;
    }
    @name(".a8bit_bit_and") action a8bit_bit_and_0(bit<8> value) {
        hdr.ipv4.diffserv = hdr.ipv4.diffserv & value;
    }
    @name(".a8bit_bit_andca") action a8bit_bit_andca_0(bit<8> value) {
        hdr.ipv4.diffserv = ~hdr.ipv4.diffserv & value;
    }
    @name(".a8bit_bit_andcb") action a8bit_bit_andcb_0(bit<8> value) {
        hdr.ipv4.diffserv = hdr.ipv4.diffserv & ~value;
    }
    @name(".a8bit_bit_nand") action a8bit_bit_nand_0(bit<8> value) {
        hdr.ipv4.diffserv = ~(hdr.ipv4.diffserv & value);
    }
    @name(".a8bit_bit_nor") action a8bit_bit_nor_0(bit<8> value) {
        hdr.ipv4.diffserv = ~(hdr.ipv4.diffserv | value);
    }
    @name(".a8bit_bit_not") action a8bit_bit_not_0() {
        hdr.ipv4.diffserv = ~hdr.ipv4.diffserv;
    }
    @name(".a8bit_bit_or") action a8bit_bit_or_0(bit<8> value) {
        hdr.ipv4.diffserv = hdr.ipv4.diffserv | value;
    }
    @name(".a8bit_bit_orca") action a8bit_bit_orca_0(bit<8> value) {
        hdr.ipv4.diffserv = ~hdr.ipv4.diffserv | value;
    }
    @name(".a8bit_bit_orcb") action a8bit_bit_orcb_0(bit<8> value) {
        hdr.ipv4.diffserv = hdr.ipv4.diffserv | ~value;
    }
    @name(".a8bit_bit_xnor") action a8bit_bit_xnor_0(bit<8> value) {
        hdr.ipv4.diffserv = ~(hdr.ipv4.diffserv ^ value);
    }
    @name(".a8bit_bit_xor") action a8bit_bit_xor_0(bit<8> value) {
        hdr.ipv4.diffserv = hdr.ipv4.diffserv ^ value;
    }
    @name(".a8bit_max") action a8bit_max_0(bit<8> value) {
        if (hdr.ipv4.diffserv >= value) 
            tmp_9 = hdr.ipv4.diffserv;
        else 
            tmp_9 = value;
        hdr.ipv4.diffserv = tmp_9;
    }
    @name(".a8bit_min") action a8bit_min_0(bit<8> value) {
        if (hdr.ipv4.diffserv <= value) 
            tmp_10 = hdr.ipv4.diffserv;
        else 
            tmp_10 = value;
        hdr.ipv4.diffserv = tmp_10;
    }
    @name(".a8bit_modify_field") action a8bit_modify_field_0(bit<8> value) {
        hdr.ipv4.diffserv = value;
    }
    @name(".a8bit_modify_field_bit_mask") action a8bit_modify_field_bit_mask_0(bit<8> value) {
        hdr.ipv4.diffserv = hdr.ipv4.diffserv & 8w0x55 | value & 8w0xaa;
    }
    @name(".a8bit_modify_field_deposit_field") action a8bit_modify_field_deposit_field_0(bit<8> value) {
        hdr.ipv4.diffserv[7:4] = value[7:4];
    }
    @name(".a8bit_shift_left_2") action a8bit_shift_left() {
        hdr.ipv4.diffserv = hdr.ipv4.diffserv << 2;
    }
    @name(".a8bit_shift_right_5") action a8bit_shift_right() {
        hdr.ipv4.diffserv = hdr.ipv4.diffserv >> 5;
    }
    @name(".a8bit_subtract") action a8bit_subtract_0() {
        hdr.ipv4.diffserv = hdr.ipv4.diffserv + 8w255;
    }
    @name(".a8bit_subtract_reverse") action a8bit_subtract_reverse_0(bit<8> value) {
        hdr.ipv4.diffserv = value - hdr.ipv4.diffserv;
    }
    @name(".a8bit_modify_field_load_const") action a8bit_modify_field_load_const_0() {
        hdr.ipv4.diffserv = 8w0x22;
    }
    @name(".a8bit_funnel_shift") action a8bit_funnel_shift_0() {
        hdr.ipv4.diffserv = (bit<8>)(hdr.ipv4.protocol ++ hdr.ipv4.diffserv >> 6);
    }
    @name(".invalidate_port_table") table invalidate_port_table {
        actions = {
            invalidate_port_0();
            do_nothing_0();
        }
        key = {
            hdr.tcp.srcPort: exact @name("tcp.srcPort") ;
        }
        default_action = do_nothing_0();
    }
    @name(".port_table") table port_table {
        actions = {
            set_p_0();
        }
        default_action = set_p_0(9w0);
    }
    @name(".t16bit") table t16bit {
        actions = {
            a16bit_add_0();
            a16bit_bit_and_0();
            a16bit_bit_andca_0();
            a16bit_bit_andcb_0();
            a16bit_bit_nand_0();
            a16bit_bit_nor_0();
            a16bit_bit_not_0();
            a16bit_bit_or_0();
            a16bit_bit_orca_0();
            a16bit_bit_orcb_0();
            a16bit_bit_xnor_0();
            a16bit_bit_xor_0();
            a16bit_max_0();
            a16bit_min_0();
            a16bit_modify_field_0();
            a16bit_modify_field_bit_mask_0();
            a16bit_modify_field_deposit_field_0();
            a16bit_shift_left();
            a16bit_shift_right();
            a16bit_subtract_0();
            a16bit_subtract_reverse_0();
            a16bit_modify_field_load_const_0();
            a16bit_funnel_shift_0();
            do_nothing_4();
        }
        key = {
            hdr.tcp.srcPort: exact @name("tcp.srcPort") ;
        }
        default_action = do_nothing_4();
    }
    @name(".t32bit") table t32bit {
        actions = {
            a32bit_add_0();
            a32bit_bit_and_0();
            a32bit_bit_andca_0();
            a32bit_bit_andcb_0();
            a32bit_bit_nand_0();
            a32bit_bit_nor_0();
            a32bit_bit_not_0();
            a32bit_bit_or_0();
            a32bit_bit_orca_0();
            a32bit_bit_orcb_0();
            a32bit_bit_xnor_0();
            a32bit_bit_xor_0();
            a32bit_max_0();
            a32bit_min_0();
            a32bit_modify_field_0();
            a32bit_modify_field_bit_mask_0();
            a32bit_modify_field_deposit_field_0();
            a32bit_shift_left();
            a32bit_shift_right();
            a32bit_subtract_0();
            a32bit_subtract_reverse_0();
            a32bit_modify_field_load_const_0();
            a32bit_funnel_shift_0();
            do_nothing_5();
        }
        key = {
            hdr.tcp.srcPort: exact @name("tcp.srcPort") ;
        }
        default_action = do_nothing_5();
    }
    @name(".t8bit") table t8bit {
        actions = {
            a8bit_add_0();
            a8bit_bit_and_0();
            a8bit_bit_andca_0();
            a8bit_bit_andcb_0();
            a8bit_bit_nand_0();
            a8bit_bit_nor_0();
            a8bit_bit_not_0();
            a8bit_bit_or_0();
            a8bit_bit_orca_0();
            a8bit_bit_orcb_0();
            a8bit_bit_xnor_0();
            a8bit_bit_xor_0();
            a8bit_max_0();
            a8bit_min_0();
            a8bit_modify_field_0();
            a8bit_modify_field_bit_mask_0();
            a8bit_modify_field_deposit_field_0();
            a8bit_shift_left();
            a8bit_shift_right();
            a8bit_subtract_0();
            a8bit_subtract_reverse_0();
            a8bit_modify_field_load_const_0();
            a8bit_funnel_shift_0();
            do_nothing_6();
        }
        key = {
            hdr.tcp.srcPort: exact @name("tcp.srcPort") ;
        }
        default_action = do_nothing_6();
    }
    apply {
        if (hdr.tcp.isValid()) {
            t8bit.apply();
            t16bit.apply();
            t32bit.apply();
        }
        port_table.apply();
        invalidate_port_table.apply();
    }
}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit<ethernet_t>(hdr.ethernet);
        packet.emit<ipv4_t>(hdr.ipv4);
        packet.emit<udp_t>(hdr.udp);
        packet.emit<tcp_t>(hdr.tcp);
    }
}

control verifyChecksum(inout headers hdr, inout metadata meta) {
    apply {
        verify_checksum<tuple<bit<4>, bit<4>, bit<8>, bit<16>, bit<16>, bit<3>, bit<13>, bit<8>, bit<8>, bit<32>, bit<32>>, bit<16>>(true, { hdr.ipv4.version, hdr.ipv4.ihl, hdr.ipv4.diffserv, hdr.ipv4.totalLen, hdr.ipv4.identification, hdr.ipv4.flags, hdr.ipv4.fragOffset, hdr.ipv4.ttl, hdr.ipv4.protocol, hdr.ipv4.srcAddr, hdr.ipv4.dstAddr }, hdr.ipv4.hdrChecksum, HashAlgorithm.csum16);
    }
}

control computeChecksum(inout headers hdr, inout metadata meta) {
    apply {
        update_checksum<tuple<bit<4>, bit<4>, bit<8>, bit<16>, bit<16>, bit<3>, bit<13>, bit<8>, bit<8>, bit<32>, bit<32>>, bit<16>>(true, { hdr.ipv4.version, hdr.ipv4.ihl, hdr.ipv4.diffserv, hdr.ipv4.totalLen, hdr.ipv4.identification, hdr.ipv4.flags, hdr.ipv4.fragOffset, hdr.ipv4.ttl, hdr.ipv4.protocol, hdr.ipv4.srcAddr, hdr.ipv4.dstAddr }, hdr.ipv4.hdrChecksum, HashAlgorithm.csum16);
        update_checksum_with_payload<tuple<bit<32>, bit<32>, bit<8>, bit<8>, bit<16>, bit<16>, bit<32>, bit<32>, bit<4>, bit<4>, bit<8>, bit<16>, bit<16>>, bit<16>>(true, { hdr.ipv4.srcAddr, hdr.ipv4.dstAddr, 8w0, hdr.ipv4.protocol, hdr.tcp.srcPort, hdr.tcp.dstPort, hdr.tcp.seqNo, hdr.tcp.ackNo, hdr.tcp.dataOffset, hdr.tcp.res, hdr.tcp.flags, hdr.tcp.window, hdr.tcp.urgentPtr }, hdr.tcp.checksum, HashAlgorithm.csum16);
    }
}

V1Switch<headers, metadata>(ParserImpl(), verifyChecksum(), ingress(), egress(), computeChecksum(), DeparserImpl()) main;
