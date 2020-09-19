#include <t2na.p4>

#define ETHERTYPE_IPV4 0x0800

typedef bit<8>  pkt_type_t;
const pkt_type_t PKT_TYPE_NORMAL = 1;
const pkt_type_t PKT_TYPE_CAPTURE = 2;


#if __TARGET_TOFINO__ == 1
typedef bit<3> mirror_type_t;
#else
typedef bit<4> mirror_type_t;
#endif
const mirror_type_t MIRROR_TYPE_I2E = 1;
const mirror_type_t MIRROR_TYPE_E2E = 2;


header ethernet_h {
    bit<48> dst;
    bit<48> src;
    bit<16> etype;
}

header ipv4_h {
    bit<4> version;
    bit<4> ihl;
    bit<8> diffserv;
    bit<16> total_len;
    bit<16> identification;
    bit<3> flags;
    bit<13> frag_offset;
    bit<8> ttl;
    bit<8> protocol;
    bit<16> hdr_checksum;
    bit<32> src_addr;
    bit<32> dst_addr;
}

header mirror_h {
   pkt_type_t pkt_type;
   bit<32> capture_seq_no;
   bit<32> mac_timestamp;
}

header example_bridge_h {
    pkt_type_t pkt_type;
    bit<3>     capture_group;
    bit<5>     reserved;
    bit<8>     rich_register;   
}

header capture_h {
    bit<32> seq_no;
    bit<32> timestamp;
}

struct headers {
    example_bridge_h bridge;
    capture_h        capture;
    ethernet_h       ethernet;
    ipv4_h ipv4;
}

struct metadata {
    mirror_h mirror;
    MirrorId_t  mirror_session;
}

struct egress_metadata_t {
    example_bridge_h  bridge;
    mirror_h  ing_port_mirror;
    mirror_h  mirror;
    MirrorId_t mirror_session;
}

parser iPrsr(packet_in packet, out headers hdr, out metadata meta,
             out ingress_intrinsic_metadata_t ig_intr_md) {
    state start {
        packet.extract(ig_intr_md);
        packet.advance(128);
        packet.advance(64);
        hdr.bridge.setValid();
        transition parse_ethernet;
    }

    state parse_ethernet {
        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.etype) {
            ETHERTYPE_IPV4 : parse_ipv4;
            default : reject;
        }
    }

    state parse_ipv4 {
        packet.extract(hdr.ipv4);
        transition accept;
    }
}

#define QUEUE_REG_STAGE1 1
#define QUEUE_REG_STAGE2 2
#define QUEUE_REG_STAGE3 3
#define QUEUE_REG_STAGE4 4
#define QUEUE_REG_STAGE5 5

@stage(QUEUE_REG_STAGE1)
Register<bit<32>, bit<3>>(8) ping_reg;
@stage(QUEUE_REG_STAGE1)
Register<bit<32>, bit<3>>(8) pong_reg;
@stage(QUEUE_REG_STAGE2)
Register<bit<32>, bit<3>>(8) ping_reg2;
@stage(QUEUE_REG_STAGE2)
Register<bit<32>, bit<3>>(8) pong_reg2;
@stage(QUEUE_REG_STAGE3)
Register<bit<32>, bit<3>>(8) ping_reg3;
@stage(QUEUE_REG_STAGE2)
Register<bit<32>, bit<3>>(8) pong_reg3;
@stage(QUEUE_REG_STAGE4)
Register<bit<32>, bit<3>>(8) ping_reg4;
@stage(QUEUE_REG_STAGE4)
Register<bit<32>, bit<3>>(8) pong_reg4;
@stage(QUEUE_REG_STAGE5)
Register<bit<32>, bit<3>>(8) ping_reg5;
@stage(QUEUE_REG_STAGE5)
Register<bit<32>, bit<3>>(8) pong_reg5;


control ingress(
        inout headers hdr,
        inout metadata meta,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md,
        in ghost_intrinsic_metadata_t g_intr_md) {

    bit<32> debt0; 
    bit<32> debt1;
    bit<32> debt2; 
    bit<32> debt3;
    bit<32> debt4;
    bit<3>  idx;
    bit<8>  reg0=0;
    bit<8>  reg1=1;
    bit<8>  reg2=2;
    bit<8>  rich_register;
    bit<16> seq_no = 0;

    Register<bit<16>, bit<3>>(size=1, initial_value=0) sequence_no;
    RegisterAction<bit<16>, bit<3>, bit<16>>(sequence_no)
    update_seq_no = {
        void apply(inout bit<16> register_data, out bit<16> result)
        {
            result = register_data;
            if (register_data == 16w0x7ff)
                register_data = 0;
            else
                register_data = register_data + 1;
        }
    };

    action insert_seq_no( bit<16> calculated_ov)
    {
        meta.mirror.capture_seq_no[15:0] = calculated_ov;
        meta.mirror.capture_seq_no[31:16] = calculated_ov;
    }

    table insertOverheadTbl {
    key = {
        seq_no : exact;
    }
    actions = {
        insert_seq_no;
    }
      size = 2048;
    }

    action do_set_dest(PortId_t port, bit<3> group) {
        ig_intr_tm_md.ucast_egress_port = port;
        idx = group;
    }

    table set_dest {
        key = {
            ig_intr_md.ingress_port : exact;
        }
        actions = { do_set_dest; }
        size = 512;
    }

    RegisterAction<bit<32>, bit<3>, bit<32>>(ping_reg) ping_get = {
        void apply(inout bit<32> value, out bit<32> rv) { rv = value; }
    };
    RegisterAction<bit<32>, bit<3>, bit<32>>(pong_reg) pong_get = {
        void apply(inout bit<32> value, out bit<32> rv) { rv = value; }
    };

    RegisterAction<bit<32>, bit<3>, bit<32>>(ping_reg2) ping2_get = {
        void apply(inout bit<32> value, out bit<32> rv) { 
            rv = min(debt0, value);
        }
    };
    RegisterAction<bit<32>, bit<3>, bit<32>>(pong_reg2) pong2_get = {
        void apply(inout bit<32> value, out bit<32> rv) { 
            rv = min(debt0, value); }
    };

    RegisterAction<bit<32>, bit<3>, bit<32>>(ping_reg3) ping3_get = {
        void apply(inout bit<32> value, out bit<32> rv) { 
            rv = min(debt1, value);
        }
    };
    RegisterAction<bit<32>, bit<3>, bit<32>>(pong_reg3) pong3_get = {
        void apply(inout bit<32> value, out bit<32> rv) { 
            rv = min(debt1, value); }
    };

    RegisterAction<bit<32>, bit<3>, bit<32>>(ping_reg4) ping4_get = {
        void apply(inout bit<32> value, out bit<32> rv) { 
            rv = min(debt2, value);
        }
    };
    RegisterAction<bit<32>, bit<3>, bit<32>>(pong_reg4) pong4_get = {
        void apply(inout bit<32> value, out bit<32> rv) { 
            rv = min(debt2, value); }
    };

    RegisterAction<bit<32>, bit<3>, bit<32>>(ping_reg5) ping5_get = {
        void apply(inout bit<32> value, out bit<32> rv) { 
            rv = min(debt3, value);
        }
    };
    RegisterAction<bit<32>, bit<3>, bit<32>>(pong_reg5) pong5_get = {
        void apply(inout bit<32> value, out bit<32> rv) { 
            rv = min(debt3, value); }
    };

    @stage(QUEUE_REG_STAGE1)
    action ping_get_depth() {
        debt0 = ping_get.execute(idx);
    }
    @stage(QUEUE_REG_STAGE1)
    action pong_get_depth() {
        debt0 = pong_get.execute(idx);
    }

    @stage(QUEUE_REG_STAGE2)
    action ping2_get_depth() {
        debt1 = ping2_get.execute(idx);
    }
    @stage(QUEUE_REG_STAGE2)
    action pong2_get_depth() {
        debt1 = pong2_get.execute(idx);
    }

    @stage(QUEUE_REG_STAGE3)
    action ping3_get_depth() {
        debt2 = ping3_get.execute(idx);
    }
    @stage(QUEUE_REG_STAGE3)
    action pong3_get_depth() {
        debt2 = pong3_get.execute(idx);
    }

    @stage(QUEUE_REG_STAGE4)
    action ping4_get_depth() {
        debt3 = ping4_get.execute(idx);
    }
    @stage(QUEUE_REG_STAGE4)
    action pong4_get_depth() {
        debt3 = pong4_get.execute(idx);
    }

    @stage(QUEUE_REG_STAGE5)
    action ping5_get_depth() {
        debt4 = ping5_get.execute(idx);
    }
    @stage(QUEUE_REG_STAGE5)
    action pong5_get_depth() {
        debt4 = pong5_get.execute(idx);
    }
    //***********************************
    action set_capture_mirror_session(MirrorId_t mirror_session) {
        ig_intr_dprsr_md.mirror_type = MIRROR_TYPE_I2E;
        ig_intr_tm_md.mcast_grp_a = 0;
        meta.mirror_session = mirror_session;
        meta.mirror.pkt_type = PKT_TYPE_CAPTURE;
        meta.mirror.mac_timestamp = (bit<32>)(ig_intr_md.ingress_mac_tstamp);
        seq_no = update_seq_no.execute(idx);
    }

    action map_bridge()
    {
        hdr.bridge.pkt_type = PKT_TYPE_NORMAL;
        hdr.bridge.capture_group = idx;
        hdr.bridge.rich_register = rich_register;
    }

    table ingressCaptureTbl {
        key = {
            ig_intr_md.ingress_port : exact;
            idx                     : exact;
            rich_register           : exact;
        }
        actions = {
            set_capture_mirror_session;
            map_bridge;
        }
        default_action = map_bridge;
        size = 32;
    }
    //***********************************
    apply {
        set_dest.apply();
        if (g_intr_md.ping_pong == 0) {
            ping_get_depth();
            ping2_get_depth();
            ping3_get_depth();
            ping4_get_depth();
            ping5_get_depth();
        } else {
            pong_get_depth();
            pong2_get_depth();
            pong3_get_depth();
            pong4_get_depth();
            pong5_get_depth();
        }
        if (debt1 == debt0)
        {
            reg0 = 8w1;
        }
        else
        {
            reg0 = 8w2;
        }
        
        if (debt2 == debt1)
        {
            reg1 = reg0;
        }
        else
        {
            reg1 = 8w3;
        }
        
        if (debt3 == debt2 )
        {
            reg2 = reg1;
        }
        else
        {
            reg2 = 8w4;
        }
       
        if (debt4 == debt3)
        {
            rich_register = reg2;
        }
        else
        {
            rich_register = 8w5;                
        }
        ingressCaptureTbl.apply();
        insertOverheadTbl.apply();
    }
}

control ghost(in ghost_intrinsic_metadata_t g_intr_md) {
    RegisterAction<bit<32>, bit<3>, bit<32>>(ping_reg) ping_update = {
        void apply(inout bit<32> value) { value = (bit<32>)g_intr_md.qlength; } };
    RegisterAction<bit<32>, bit<3>, bit<32>>(pong_reg) pong_update = {
        void apply(inout bit<32> value) { value = (bit<32>)g_intr_md.qlength; } };

    RegisterAction<bit<32>, bit<3>, bit<32>>(ping_reg2) ping2_update = {
        void apply(inout bit<32> value) { value = (bit<32>)g_intr_md.qlength; } };
    RegisterAction<bit<32>, bit<3>, bit<32>>(pong_reg2) pong2_update = {
        void apply(inout bit<32> value) { value = (bit<32>)g_intr_md.qlength; } };

    RegisterAction<bit<32>, bit<3>, bit<32>>(ping_reg3) ping3_update = {
        void apply(inout bit<32> value) { value = (bit<32>)g_intr_md.qlength; } };
    RegisterAction<bit<32>, bit<3>, bit<32>>(pong_reg3) pong3_update = {
        void apply(inout bit<32> value) { value = (bit<32>)g_intr_md.qlength; } };

    RegisterAction<bit<32>, bit<3>, bit<32>>(ping_reg4) ping4_update = {
        void apply(inout bit<32> value) { value = (bit<32>)g_intr_md.qlength; } };
    RegisterAction<bit<32>, bit<3>, bit<32>>(pong_reg4) pong4_update = {
        void apply(inout bit<32> value) { value = (bit<32>)g_intr_md.qlength; } };

    RegisterAction<bit<32>, bit<3>, bit<32>>(ping_reg5) ping5_update = {
        void apply(inout bit<32> value) { value = (bit<32>)g_intr_md.qlength; } };
    RegisterAction<bit<32>, bit<3>, bit<32>>(pong_reg5) pong5_update = {
        void apply(inout bit<32> value) { value = (bit<32>)g_intr_md.qlength; } };

    //**************************
    action ping_do_update(bit<3> idx) {
        ping_update.execute(idx);
    }
    action pong_do_update(bit<3> idx) {
        pong_update.execute(idx);
    }

    @stage(QUEUE_REG_STAGE1)
    table ping_update_tbl {
        key = {
            g_intr_md.pipe_id : exact;
            g_intr_md.qid : exact;
        }
        actions = {
            ping_do_update;
        }
        size = 8;
    }

    @stage(QUEUE_REG_STAGE1)
    table pong_update_tbl {
        key = {
            g_intr_md.pipe_id : exact;
            g_intr_md.qid : exact;
        }
        actions = {
            pong_do_update;
        }
        size = 8;
    }
    //**************************
    action ping2_do_update(bit<3> idx) {
        ping2_update.execute(idx);
    }

    action pong2_do_update(bit<3> idx) {
        pong2_update.execute(idx);
    }
    
    @stage(QUEUE_REG_STAGE2)
    table ping2_update_tbl {
        key = {
            g_intr_md.pipe_id : exact;
            g_intr_md.qid : exact;
        }
        actions = {
            ping2_do_update;
        }
        size = 8;
    }

    @stage(QUEUE_REG_STAGE2)
    table pong2_update_tbl {
        key = {
            g_intr_md.pipe_id : exact;
            g_intr_md.qid : exact;
        }
        actions = {
            pong2_do_update;
        }
        size = 8;
    }
    
    //**************************

    action ping3_do_update(bit<3> idx) {
        ping3_update.execute(idx);
    }
    
    action pong3_do_update(bit<3> idx) {
        pong3_update.execute(idx);
    }

    @stage(QUEUE_REG_STAGE3)
    table ping3_update_tbl {
        key = {
            g_intr_md.pipe_id : exact;
            g_intr_md.qid : exact;
        }
        actions = {
            ping3_do_update;
        }
        size = 8;
    }

    @stage(QUEUE_REG_STAGE3)
    table pong3_update_tbl {
        key = {
            g_intr_md.pipe_id : exact;
            g_intr_md.qid : exact;
        }
        actions = {
            pong3_do_update;
        }
        size = 8;
    }

    //**************************

    action ping4_do_update(bit<3> idx) {
        ping4_update.execute(idx);
    }
    
    action pong4_do_update(bit<3> idx) {
        pong4_update.execute(idx);
    }

    @stage(QUEUE_REG_STAGE4)
    table ping4_update_tbl {
        key = {
            g_intr_md.pipe_id : exact;
            g_intr_md.qid : exact;
        }
        actions = {
            ping4_do_update;
        }
        size = 8;
    }

    @stage(QUEUE_REG_STAGE4)
    table pong4_update_tbl {
        key = {
            g_intr_md.pipe_id : exact;
            g_intr_md.qid : exact;
        }
        actions = {
            pong4_do_update;
        }
        size = 8;
    }

    //**************************

    action ping5_do_update(bit<3> idx) {
        ping5_update.execute(idx);
    }
    
    action pong5_do_update(bit<3> idx) {
        pong5_update.execute(idx);
    }

    @stage(QUEUE_REG_STAGE5)
    table ping5_update_tbl {
        key = {
            g_intr_md.pipe_id : exact;
            g_intr_md.qid : exact;
        }
        actions = {
            ping5_do_update;
        }
        size = 8;
    }

    @stage(QUEUE_REG_STAGE4)
    table pong5_update_tbl {
        key = {
            g_intr_md.pipe_id : exact;
            g_intr_md.qid : exact;
        }
        actions = {
            pong5_do_update;
        }
        size = 8;
    }

    //**************************
    apply {
        if (g_intr_md.ping_pong == 1) {
            ping_update_tbl.apply();
            ping2_update_tbl.apply();
            ping3_update_tbl.apply();
            ping4_update_tbl.apply();
            ping5_update_tbl.apply();
        } else {
            pong_update_tbl.apply();
            pong2_update_tbl.apply();
            pong3_update_tbl.apply();
            pong4_update_tbl.apply();
            pong5_update_tbl.apply();
        }
    }
}

control iDprsr(packet_out packet, inout headers hdr, in metadata meta,
               in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprs) {
    
    Mirror() mirror;

    apply{
        if (ig_intr_md_for_dprs.mirror_type == MIRROR_TYPE_I2E)
        {
            mirror.emit<mirror_h>(meta.mirror_session, meta.mirror);
        }
        packet.emit(hdr);
    }
}

parser ePrsr(packet_in packet, out headers hdr, out egress_metadata_t eg_md,
             out egress_intrinsic_metadata_t eg_intr_md) {
    state start {
        packet.extract(eg_intr_md);
        mirror_h mirror_md = packet.lookahead<mirror_h>();
        transition select(mirror_md.pkt_type) {
            PKT_TYPE_CAPTURE        : parse_capture;
            default                 : parse_bridge;
        }
    }

    state parse_capture {
        packet.extract(eg_md.ing_port_mirror);
        hdr.capture.setValid();
        transition accept;
    }

    state parse_bridge {
        packet.extract(eg_md.bridge);
        packet.extract(hdr.ethernet);
        packet.extract(hdr.ipv4);
    }
}

control egress(inout headers hdr,
               inout egress_metadata_t eg_md,
               in egress_intrinsic_metadata_t eg_intr_md,
               in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
               inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprs,
               inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {

    bit<16> eg_seq_no;

    Register<bit<16>, bit<3>>(size=1, initial_value=0) sequence_no;
    RegisterAction<bit<16>, bit<3>, bit<16>>(sequence_no)
    update_seq_no = {
        void apply(inout bit<16> register_data, out bit<16> result)
        {
            result = register_data;
            if (register_data == 16w0x7ff)
                register_data = 0;
            else
                register_data = register_data + 1;
        }
    };

    action insert_seq_no( bit<16> calculated_ov)
    {
        eg_md.mirror.capture_seq_no[15:0] = calculated_ov;
        eg_md.mirror.capture_seq_no[31:16] = calculated_ov;
    }

    table insertOverheadTbl {
    key = {
        eg_seq_no : exact;
    }
    actions = {
        insert_seq_no;
    }
      size = 2048;
    }

    action insert_capture()
    {
        hdr.capture.seq_no = eg_md.ing_port_mirror.capture_seq_no;
        hdr.capture.timestamp = eg_md.ing_port_mirror.mac_timestamp;
    }

    action set_mirror_session_capture(MirrorId_t mirror_session) {
        eg_intr_md_for_dprs.mirror_type = MIRROR_TYPE_E2E;
        eg_md.mirror_session = mirror_session;
        eg_md.mirror.mac_timestamp = (bit<32>)(eg_intr_md_from_prsr.global_tstamp);
        eg_md.mirror.pkt_type = PKT_TYPE_CAPTURE;
        eg_seq_no = update_seq_no.execute(hdr.bridge.capture_group);
#if __TARGET_TOFINO__ != 1
// E2E mirroring for Tofino2 & future ASICs, or you'll see extra bytes prior to ethernet
        eg_intr_md_for_dprs.mirror_io_select = 1;
#endif
    }

    table captureTbl {
        key = {
            eg_intr_md.egress_port   : exact;
            hdr.bridge.capture_group : exact;
            hdr.bridge.rich_register : exact;
        }
        actions = {
            set_mirror_session_capture;
            NoAction;
        }
        default_action = NoAction;
        size = 4;
    }
    //***************************************************************
    apply {

       if ( hdr.capture.isValid())
       {
            insert_capture();
       }
       else
       {
            captureTbl.apply();
            insertOverheadTbl.apply();
       }
    }
}

control eDprsr(packet_out packet, inout headers hdr, in egress_metadata_t eg_md,
               in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprs) {

    Mirror() mirror;
    apply{
        if (eg_intr_md_for_dprs.mirror_type == MIRROR_TYPE_E2E) {
            mirror.emit<mirror_h>(eg_md.mirror_session,  eg_md.mirror);
        }
        packet.emit(hdr);
    }
}

Pipeline(iPrsr(), ingress(), iDprsr(), ePrsr(), egress(), eDprsr(), ghost()) pipe;
Switch(pipe) main;

