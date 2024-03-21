//
// txna_pgr
//

#if   (__TARGET_TOFINO__ == 2)
#include <t2na.p4>
typedef bit<9> port_t;
#elif (__TARGET_TOFINO__ == 3)
#include <t3na.p4>
typedef bit<11> port_t;
#else
#error "only tofino2 or tofino3 supported"
#endif

//#define ORIG_P4_CODE

struct port_md_t {
    @pa_container_size("ingress", "ig_intr_prsr_md.global_tstamp[31:0]", 32)
    //@pa_container_size("ingress", "ingress.ts_tmp_1a", 32)
    //@pa_container_size("ingress", "md.port_md.dst_port", 16)
    bit<1>  do_dprsr_trigger;
    bit<1>  is_pktgen;
    bit<1>  is_valid;
    port_t  dst_port;
    bit<4>  dprsr_trigger_hdr_idx;
    bit<14> dprsr_trigger_offset;
    bit<10> dprsr_trigger_len;
    bit<40> pad;
}

struct metadata_t {
    port_md_t port_md;
    // @pa_solitary("ingress", "md.fifo_res")
    bit<32>   fifo_res;
    bit<4>    app_id;
    //@pa_container_size("ingress", "md.pkt_id", 16)
    bit<16>   pkt_id;
    @pa_container_size("ingress", "md.batch_id", 16)
    bit<16>   batch_id;
    bit<16>   batch_size;
    bit<16>   batch_count;
    bit<1>    pkt_id_check_result;
    bit<1>    batch_id_check_result;
    bit<1>    seq_num_chk_failed;
    bit<1>    app_ctx_chk_failed;

    /* Packet generator app type:
     * 0 - one shot timer
     * 1 - periodic timer
     * 2 - port down
     * 3 - recirc
     * 4 - deparser
     * 5 - PFC */
    bit<3>    app_type;
    @pa_atomic("ingress", "md.ts_tmp_1a")
    @pa_atomic("ingress", "md.ts_tmp_2a")
    bit<32>   ts_tmp_1a;
    bit<32>   ts_tmp_2a;
}

struct reg32x2_t {
    bit<32> lo;
    bit<32> hi;
}

header app_ctx_h {
    @pa_container_size("ingress", "hdr.app_ctx.data", 32, 32, 32, 32)
    bit<128> data;
}

header ethernet_h {
    bit<48> dst;
    bit<48> src;
    bit<16> etype;
}

struct headers_t {
    pktgen_timer_header_t     timer;
    pktgen_port_down_header_t port_down;
    pktgen_recirc_header_t    recirc_dprsr;
    pktgen_pfc_header_t       pfc;
    app_ctx_h                 app_ctx;
    ethernet_h                ethernet;
}

struct pvs_entry_t {
    bit<4> app_id;
}

parser ingress_parser
(
    packet_in                        packet,
    out headers_t                    hdr,
    out metadata_t                   md,
    out ingress_intrinsic_metadata_t ig_intr_md
) {
    value_set<pvs_entry_t>(16) timer_apps;
    value_set<pvs_entry_t>(16) port_down_apps;
    value_set<pvs_entry_t>(16) recirc_dprsr_apps;
    value_set<pvs_entry_t>(1)  pfc_apps;

    state start {
#ifndef ORIG_P4_CODE
        // init metadata output:
        md.port_md.do_dprsr_trigger      = 0;
        md.port_md.is_pktgen             = 0;
        md.port_md.is_valid              = 0;
        md.port_md.dst_port              = 0;
        md.port_md.dprsr_trigger_hdr_idx = 0;
        md.port_md.dprsr_trigger_offset  = 0;
        md.port_md.dprsr_trigger_len     = 0;
        md.port_md.pad                   = 0;
        md.fifo_res                      = 0;
        md.app_id                        = 0;
        md.pkt_id                        = 0;
        md.batch_id                      = 0;
        md.batch_size                    = 0;
        md.batch_count                   = 0;
        md.pkt_id_check_result           = 0;
        md.batch_id_check_result         = 0;
        md.seq_num_chk_failed            = 0;
        md.app_ctx_chk_failed            = 0;
        md.app_type                      = 0;
        md.ts_tmp_1a                     = 0;
        md.ts_tmp_2a                     = 0;
#endif
        // extract:
        packet.extract(ig_intr_md);
        transition select(ig_intr_md.resubmit_flag) {
            1 : parse_resubmit;
            0 : parse_port_md;
        }
    }

    state parse_resubmit {
        packet.advance(128);
        packet.advance(64);
        transition reject;
    }

    state parse_port_md {
        md.port_md = port_metadata_unpack<port_md_t>(packet);
        transition select(md.port_md.is_pktgen) {
            0 : parse_ethernet;
            1 : parse_pktgen;
        }
    }

    state parse_pktgen {
        bit<4> app_id = packet.lookahead<bit<8>>()[3:0];
        transition select(app_id) {
            timer_apps        : parse_pktgen_timer;
            port_down_apps    : parse_pktgen_port_down;
            recirc_dprsr_apps : parse_pktgen_recirc_dprsr;
            pfc_apps          : parse_pktgen_pfc;
            default           : reject;
        }
    }

    state parse_pktgen_timer {
        packet.extract(hdr.timer);
        transition accept;
    }

    state parse_pktgen_port_down {
        packet.extract(hdr.port_down);
        transition accept;
    }

    state parse_pktgen_recirc_dprsr {
        packet.extract(hdr.recirc_dprsr);
        packet.extract(hdr.app_ctx);
        transition accept;
    }

    state parse_pktgen_pfc {
        packet.extract(hdr.pfc);
        packet.extract(hdr.app_ctx);
        transition accept;
    }

    state parse_ethernet {
        md.app_id = 0;
        packet.extract(hdr.ethernet);
        transition accept;
    }
}

control ingress
(
    inout headers_t                                 hdr,
    inout metadata_t                                md,
    in    ingress_intrinsic_metadata_t              ig_intr_md,
    in    ingress_intrinsic_metadata_from_parser_t  ig_intr_prsr_md,
    inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md,
    inout ingress_intrinsic_metadata_for_tm_t       ig_intr_tm_md
) {

    Hash<bit< 5>>(HashAlgorithm_t.IDENTITY) id_hash_bit5;
    Hash<bit< 5>>(HashAlgorithm_t.IDENTITY) id_hash_bit5_again;
    Hash<port_t>(HashAlgorithm_t.IDENTITY) id_hash_bit_port_t;
    Hash<port_t>(HashAlgorithm_t.IDENTITY) id_hash_bit_port_t_again;
    Hash<bit<32>>(HashAlgorithm_t.IDENTITY) id_hash_bit32_a;
    Hash<bit<32>>(HashAlgorithm_t.IDENTITY) id_hash_bit32_b;

    action none() {}

    /* A table to validate the port metadata and increment a counter when it
     * matches the expected values. */
    Counter<bit<1>, port_t>(511, CounterType_t.PACKETS) port_metadata_cntr;

    action match() {
        port_metadata_cntr.count(ig_intr_md.ingress_port);
    }

    table port_metadata {
        key = {
            ig_intr_md.ingress_port          : exact;
            md.port_md.do_dprsr_trigger      : exact;
            md.port_md.is_pktgen             : exact;
            md.port_md.is_valid              : exact;
            md.port_md.dst_port              : exact;
            md.port_md.dprsr_trigger_hdr_idx : exact;
            md.port_md.dprsr_trigger_offset  : exact;
            md.port_md.dprsr_trigger_len     : exact;
            md.port_md.pad                   : exact;
        }
        actions = {
            none;
            match;
        }
        default_action = none();
        size = 288;
    }

    /* A table to set the destination of a packet if the phase0 data had a valid
     * port or set the drop control bits to discard the packet. */
    action drop() { ig_intr_dprsr_md.drop_ctl = 7; }

    action forward() {
        ig_intr_tm_md.ucast_egress_port = md.port_md.dst_port;
        ig_intr_tm_md.bypass_egress = 1w1;
    }

#ifdef ORIG_P4_CODE // original 
    table set_dest {
        key = { md.port_md.is_valid : exact; }
        actions = { forward; drop; }
        default_action = drop();
        size = 2;
        const entries = {
            (0) : drop();
            (1) : forward();
        }
    }
#endif

    action set_dprsr_trig_hdr(bit<128> h) {
        hdr.app_ctx.data = h;
        ig_intr_dprsr_md.pktgen = 1w1;
        ig_intr_dprsr_md.pktgen_address = md.port_md.dprsr_trigger_offset;
        ig_intr_dprsr_md.pktgen_length = md.port_md.dprsr_trigger_len;
    }

    table t_set_dprsr_trig_hdr {
        key = { md.port_md.dprsr_trigger_hdr_idx : exact; }
        actions = { set_dprsr_trig_hdr; }
        default_action = set_dprsr_trig_hdr(128w0);
        size = 16;
    }

    /* A table to copy the packet gen metadata from the headers to metadata based
     * on which header type/app type is valid. */
    action timer_info() {
        md.app_id         = hdr.timer.app_id;
        md.batch_id       = hdr.timer.batch_id;
        md.pkt_id         = hdr.timer.packet_id;
    }

    action port_down_info() {
        md.app_id          = hdr.port_down.app_id;
#if   (__TARGET_TOFINO__ == 2)
        md.batch_id[15:9]  = hdr.port_down._pad2[6:0];
        md.batch_id[8:0]   = hdr.port_down.port_num;
#elif (__TARGET_TOFINO__ == 3)
        md.batch_id[15:11] = hdr.port_down._pad2[4:0];
        md.batch_id[10:0]  = hdr.port_down.port_num;
#endif
        md.pkt_id          = hdr.port_down.packet_id;
    }

    action recirc_dprsr_info() {
        md.app_id         = hdr.recirc_dprsr.app_id;
        md.batch_id       = hdr.recirc_dprsr.batch_id;
        md.pkt_id         = hdr.recirc_dprsr.packet_id;
    }

    action pfc_info() {
        md.app_id         = hdr.pfc.app_id;
        md.batch_id       = 0;
        md.pkt_id         = 0;
    }

    table t_set_pgen_metadata {
        key = {
            hdr.timer.isValid()        : exact;
            hdr.port_down.isValid()    : exact;
            hdr.recirc_dprsr.isValid() : exact;
            hdr.pfc.isValid()          : exact;
        }
        actions = { timer_info; port_down_info; recirc_dprsr_info; pfc_info; }
        size = 4;
        const entries = {
            (true,  false, false, false) : timer_info();
            (false, true,  false, false) : port_down_info();
            (false, false, true,  false) : recirc_dprsr_info();
            (false, false, false, true ) : pfc_info();
        }
    }

    /* A simple table to get the expected packet counts for an app.  The entries
     * programmed in the table should match how the packet gen apps are
     * configured. */
    action init_app_info(bit<3> type, bit<16> batch_count, bit<16> batch_size) {
        md.app_type    = type;
        md.batch_count = batch_count;
        md.batch_size  = batch_size;
    }

    table app_info {
        key = { md.app_id : exact; }
        actions = { init_app_info; }
        default_action = init_app_info(0, 0, 0);
        size = 16;
    }

    /* A stateful FIFO to log the timestamp of each packet generated by an app. */
    Register<reg32x2_t, bit<32>>(47104) ts_fifo_1;
    Register<reg32x2_t, bit<32>>(47104) ts_fifo_2;

    RegisterAction<reg32x2_t, bit<32>, bit<32>>(ts_fifo_1) ts_fifo_enqueue_1 = {
        void apply(inout reg32x2_t value, out bit<32> rv) {
            //value.hi = 12w0 +++ md.app_id +++ ig_intr_prsr_md.global_tstamp[47:32];
            //value.hi = ig_intr_prsr_md.global_tstamp[47:16];
            value.hi = md.ts_tmp_1a;
            value.lo = md.ts_tmp_2a;
            rv = 0;
        }
        void overflow(inout reg32x2_t value, out bit<32> rv) {
            rv = 1;
        }
    };

    RegisterAction<reg32x2_t, bit<32>, bit<32>>(ts_fifo_2) ts_fifo_enqueue_2 = {
        void apply(inout reg32x2_t value) {
            //value.hi = 12w0 +++ md.app_id +++ ig_intr_prsr_md.global_tstamp[47:32];
            //value.hi = ig_intr_prsr_md.global_tstamp[47:16];
            value.hi = md.ts_tmp_1a;
            value.lo = md.ts_tmp_2a;
        }
    };

    action do_log_ts_1() {
        md.fifo_res = ts_fifo_enqueue_1.enqueue();
    }

    action do_log_ts_2() {
        ts_fifo_enqueue_2.enqueue();
    }

    table log_ts_1 {
        actions = { do_log_ts_1; }
        default_action = do_log_ts_1();
        size = 512; // tjnagler, added default size <-- REVISIT!!!
    }

    table log_ts_2 {
        actions = { do_log_ts_2; }
        default_action = do_log_ts_2();
        size = 512; // tjnagler, added default size <-- REVISIT!!!
    }

    /* A stateful table to validate the pkt-id.
     * Outputs 0 if the packet has an incorrect packet-id.
     * Outputs 1 if the packet has the expected packet-id. */
    Register<bit<16>, bit<4>>(16) pkt_seq_num;

    RegisterAction<bit<16>, bit<4>, bit<1>>(pkt_seq_num) pkt_seq_num_act1 = {
        void apply(inout bit<16> value, out bit<1> result) {
            if (value == md.pkt_id) {
                value = value + 1;
                result = 1;
            } else {
                result = 0;
            }
        }
    };

    RegisterAction<bit<16>, bit<4>, bit<1>>(pkt_seq_num) pkt_seq_num_act2 = {
        void apply(inout bit<16> value, out bit<1> result) {
            if (value == md.pkt_id) {
                value = 0;
                result = 1;
            } else {
                result = 0;
            }
        }
    };

    action check_and_inc_pkt_seq_num() {
        md.pkt_id_check_result = pkt_seq_num_act1.execute(md.app_id);
    }

    action check_and_clr_pkt_seq_num() {
        md.pkt_id_check_result = pkt_seq_num_act2.execute(md.app_id);
    }

    table t_check_and_inc_pkt_seq_num {
        actions = {check_and_inc_pkt_seq_num;}
        default_action = check_and_inc_pkt_seq_num;
        size = 512; // tjnagler, added default size <-- REVISIT!!!
    }

    table t_check_and_clr_pkt_seq_num {
        actions = {check_and_clr_pkt_seq_num;}
        default_action = check_and_clr_pkt_seq_num;
        size = 512; // tjnagler, added default size <-- REVISIT!!!
    }

    /* A stateful table to validate the pkt-id.
     * Outputs 0 if the packet has an incorrect batch-id.
     * Outputs 1 if the packet has the expected batch-id. */
    Register<bit<16>, bit<4>>(16) batch_seq_num;

    RegisterAction<bit<16>, bit<4>, bit<1>>(batch_seq_num) batch_seq_num_act1 = {
        void apply(inout bit<16> value, out bit<1> result) {
            if (value == md.batch_id) {
                result = 1;
            } else {
                result = 0;
            }
        }
    };

    RegisterAction<bit<16>, bit<4>, bit<1>>(batch_seq_num) batch_seq_num_act2 = {
        void apply(inout bit<16> value, out bit<1> result) {
            if (value == md.batch_id) {
                value = value + 1;
                result = 1;
            } else {
                result = 0;
            }
        }
    };

    RegisterAction<bit<16>, bit<4>, bit<1>>(batch_seq_num) batch_seq_num_act3 = {
        void apply(inout bit<16> value, out bit<1> result) {
            if (value == md.batch_id) {
                value = 0;
                result = 1;
            } else {
                result = 0;
            }
        }
    };

    action check_batch_seq_num() {
        md.batch_id_check_result = batch_seq_num_act1.execute(md.app_id);
    }

    action check_and_inc_batch_seq_num() {
        md.batch_id_check_result = batch_seq_num_act2.execute(md.app_id);
    }

    action check_and_clr_batch_seq_num() {
        md.batch_id_check_result = batch_seq_num_act3.execute(md.app_id);
    }

    //@stage(5)
    table t_check_batch_seq_num {
        actions = {check_batch_seq_num;} default_action = check_batch_seq_num();
        size = 512; // tjnagler, added default size <-- REVISIT!!!
    }

    //@stage(5)
    table t_check_and_inc_batch_seq_num {
        actions = {check_and_inc_batch_seq_num;} default_action = check_and_inc_batch_seq_num();
        size = 512; // tjnagler, added default size <-- REVISIT!!!
    }

    //@stage(5)
    table t_check_and_clr_batch_seq_num {
        actions = {check_and_clr_batch_seq_num;} default_action = check_and_clr_batch_seq_num();
        size = 512; // tjnagler, added default size <-- REVISIT!!!
    }

    action batch_id_okay() {
        md.batch_id_check_result = 1;
    }

    action batch_id_not_okay() {
        md.batch_id_check_result = 0;
    }

    table t_port_down_batch_check {
        key = { md.batch_id : exact; }
        actions = {batch_id_not_okay; batch_id_okay;}
        default_action = batch_id_not_okay;
        size = 512;
    }

    /* A counter to count good and bad packet sequence numbers. */
    Counter<bit<1>, bit<5>>(32, CounterType_t.PACKETS) seq_no_cntr;

    action count_seq_num_result() {
        seq_no_cntr.count(id_hash_bit5.get({md.app_id, md.seq_num_chk_failed}));
    }

    table t_count_seq_num_result {
        actions = {count_seq_num_result;}
        default_action = count_seq_num_result;
        size = 512; // tjnagler, added default size <-- REVISIT!!!
    }
    
    Counter<bit<1>, bit<5>>(32, CounterType_t.PACKETS) ctx_cntr;

    action app_ctx_okay() {
        md.app_ctx_chk_failed = 0;
    }

    action app_ctx_not_okay() {
        md.app_ctx_chk_failed = 1;
    }

    table t_app_ctx_check {
        key = {
            md.app_id : exact;
            hdr.app_ctx.data : exact;
        }
        actions = {
            app_ctx_okay;
            app_ctx_not_okay;
        }
        const default_action = app_ctx_not_okay();
        size = 16;
    }

    action count_app_ctx_result() {
        ctx_cntr.count(id_hash_bit5_again.get({md.app_id, md.app_ctx_chk_failed}));
    }

    table t_count_app_ctx_result {
        actions = {count_app_ctx_result;}
        default_action = count_app_ctx_result;
        size = 512; // tjnagler, added default size <-- REVISIT!!!
    }

    Counter<bit<1>, port_t>(512, CounterType_t.PACKETS) port_down_cntr;

    action inc_port_down_counter() {
        port_down_cntr.count(id_hash_bit_port_t.get({hdr.port_down.port_num}));
    }

    table t_port_down_counter {
        actions = {inc_port_down_counter;}
        default_action = inc_port_down_counter();
        size = 512; // tjnagler, added default size <-- REVISIT!!!
    }

    Counter<bit<1>, port_t>(512, CounterType_t.PACKETS_AND_BYTES) port_cntr;

    action inc_port_counter() {
        port_cntr.count(id_hash_bit_port_t_again.get({ig_intr_md.ingress_port}));
    }

    table t_port_counter {
        actions = {inc_port_counter;}
        default_action = inc_port_counter();
        size = 512; // tjnagler, added default size <-- REVISIT!!!
    }

    apply {
        /* Validate the port metadata by incrementing a counter if it matches the
         * expected values. */
        port_metadata.apply();

#ifdef  ORIG_P4_CODE
        /* Set the destination based on the port metadata. */
        set_dest.apply();
#else
        if (md.port_md.is_valid == 1) {
            forward();
        } else {
            drop(); // invalid, drop packet
        }
#endif        
        /* If the port metadata says we need to issue a deparser pktgen trigger set
         * it up now.  This will set 128 bits of metadata to pass in the trigger. */
        if (md.port_md.do_dprsr_trigger == 1) {
            t_set_dprsr_trig_hdr.apply();
        }

        md.ts_tmp_2a = id_hash_bit32_b.get({ig_intr_prsr_md.global_tstamp[31:0]});
        if (md.port_md.is_pktgen == 1) {
            /* Extract data from the various pgen headers into metadata. */
            t_set_pgen_metadata.apply();

            /* From the app id get the batch count and size as well as the type. */
            app_info.apply();
            md.ts_tmp_1a = id_hash_bit32_a.get({md.app_id +++ 12w0 +++ ig_intr_prsr_md.global_tstamp[47:32]});

            /* Log the packet's timestamp in a FIFO so the control plane can verify
             * the IPG and IBG. */
            log_ts_1.apply();
            /* Check the FIFO enqueue result to see if an overflow happened.  If so
             * enqueue to the second FIFO. */
            if (md.fifo_res != 0) {
                log_ts_2.apply();
            }

            /* Verify the packet-id and batch-id.  Note that for port down apps the
             * batch id should be the port number that went down.  For all other cases
             * verify that the packet id counts up to the limit and then resets to
             * zero and increments the batch id. */
            if (md.batch_size == md.pkt_id) {
                t_check_and_clr_pkt_seq_num.apply();
                if (md.app_type != 2) {
                    if (md.batch_count == md.batch_id) {
                        t_check_and_clr_batch_seq_num.apply();
                    } else {
                        t_check_and_inc_batch_seq_num.apply();
                    }
                } else {
                    t_port_down_batch_check.apply();
                }
            } else {
                t_check_and_inc_pkt_seq_num.apply();
                if (md.app_type != 2) {
                    t_check_batch_seq_num.apply();
                } else {
                    t_port_down_batch_check.apply();
                }
            }
            md.seq_num_chk_failed = ~(md.pkt_id_check_result & md.batch_id_check_result);

            t_count_seq_num_result.apply();

            /* Recirculation, Deparser, and PFC apps carry user data, verify that here. */
            if (md.app_type == 3 || md.app_type == 4 || md.app_type == 5) {
                t_app_ctx_check.apply();
                t_count_app_ctx_result.apply();
            }

            /* Port down apps carry the port-id, increment a counter with it. */
            if (md.app_type == 2) {
                t_port_down_counter.apply();
            }

            if (hdr.recirc_dprsr.isValid() == true) {
                hdr.app_ctx.setInvalid();
            }
        }
        /* Count packets per ingress port to verify ingress port spoofing. */
        t_port_counter.apply();
    }
}

control ingress_deparser
(
    packet_out                                           packet,
    inout      headers_t                                 hdr,
    in         metadata_t                                md,
    in         ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md
) {
    Pktgen() pgen;

    apply {
        if (ig_dprsr_md.pktgen == 1w1) {
            pgen.emit(hdr.app_ctx);
        }
        packet.emit(hdr.pfc);
        packet.emit(hdr.app_ctx);
        packet.emit(hdr.ethernet);
    }
}

parser egress_parser
(
    packet_in                             packet,
    out       headers_t                   hdr,
    out       metadata_t                  md,
    out       egress_intrinsic_metadata_t eg_intr_md
) {
    state start {
        // init metadata output:
        md.port_md.do_dprsr_trigger      = 0;
        md.port_md.is_pktgen             = 0;
        md.port_md.is_valid              = 0;
        md.port_md.dst_port              = 0;
        md.port_md.dprsr_trigger_hdr_idx = 0;
        md.port_md.dprsr_trigger_offset  = 0;
        md.port_md.dprsr_trigger_len     = 0;
        md.port_md.pad                   = 0;
        md.fifo_res                      = 0;
        md.app_id                        = 0;
        md.pkt_id                        = 0;
        md.batch_id                      = 0;
        md.batch_size                    = 0;
        md.batch_count                   = 0;
        md.pkt_id_check_result           = 0;
        md.batch_id_check_result         = 0;
        md.seq_num_chk_failed            = 0;
        md.app_ctx_chk_failed            = 0;
        md.app_type                      = 0;
        md.ts_tmp_1a                     = 0;
        md.ts_tmp_2a                     = 0;
        // reject:
        transition reject;
    }
}

control egress
(
    inout headers_t                                   hdr,
    inout metadata_t                                  md,
    in    egress_intrinsic_metadata_t                 eg_intr_md,
    in    egress_intrinsic_metadata_from_parser_t     eg_intr_md_from_prsr,
    inout egress_intrinsic_metadata_for_deparser_t    eg_intr_md_for_dprs,
    inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport
) {
    apply {}
}

control egress_deparser
(
    packet_out                                          packet,
    inout      headers_t                                hdr,
    in         metadata_t                               md,
    in         egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprs
) {
    apply {}
}

Pipeline
(
    ingress_parser(),
    ingress(),
    ingress_deparser(),
    egress_parser(),
    egress(),
    egress_deparser()

) pipe;

Switch(pipe) main;
