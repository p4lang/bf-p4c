#if __TARGET_TOFINO__ == 2
#include <t2na.p4>
#else
#include <tna.p4>
#endif
#include "headers.p4"
control egress_cmp(in ghost_intrinsic_metadata_t g_intr_md,
                    inout ingress_metadata_t meta,
                    in bit<8> idx, out bit<16> rich_register) {

    bit<16> temp_rich_register_1;
    bit<16> temp_rich_register_2;
    bit<8> compare  = 0;

    MinMaxAction<bit<16>, bit<8>, bit<16>>(ping_egress_reg) ping_egress_get = {
        void apply(inout bit<128> value, out bit<16> rv, out bit<16> subindex) {
            subindex = 0;
            rv = this.min16(value, 0x3E, subindex[2:0]);
        }
    };
    MinMaxAction<bit<16>, bit<8>, bit<16>>(pong_egress_reg) pong_egress_get = {
        void apply(inout bit<128> value, out bit<16> rv, out bit<16> subindex) {
            subindex = 0;
            rv = this.min16(value, 0x3E, subindex[2:0]);
        }
    };

    action ping_get_depth() {
        ping_egress_get.execute(idx, temp_rich_register_1);
    }
    action pong_get_depth() {
        pong_egress_get.execute(idx, temp_rich_register_1);
    }
    @stage(EG_QUEUE_REG_STAGE1)
    table ping_read_tbl {
        actions = {
            ping_get_depth;
        }
        default_action = ping_get_depth;
    }

    @stage(EG_QUEUE_REG_STAGE1)
    table pong_read_tbl {
        actions = {
            pong_get_depth;
        }
        default_action = pong_get_depth;
    }

/*********************************************************/
    MinMaxAction<bit<16>, bit<8>, bit<16>>(ping_egress_reg2) ping_egress_get2 = {
    void apply(inout bit<128> value, out bit<16> rv, out bit<16> subindex) {
            subindex = 0;
            rv = this.min16(value, 0x3C, subindex[2:0]);
        }
    };
    MinMaxAction<bit<16>, bit<8>, bit<16>>(pong_egress_reg2) pong_egress_get2 = {
        void apply(inout bit<128> value, out bit<16> rv, out bit<16> subindex) {
            subindex = 0;
            rv = this.min16(value, 0x3C, subindex[2:0]);
        }
    };

    MinMaxAction<bit<16>, bit<8>, bit<16>>(ping_egress_reg2) ping_egress_get3 = {
    void apply(inout bit<128> value, out bit<16> rv, out bit<16> subindex) {
            subindex = 0;
            rv = this.min16(value, 0x3A, subindex[2:0]);
        }
    };
    MinMaxAction<bit<16>, bit<8>, bit<16>>(pong_egress_reg2) pong_egress_get3 = {
        void apply(inout bit<128> value, out bit<16> rv, out bit<16> subindex) {
            subindex = 0;
            rv = this.min16(value, 0x3A, subindex[2:0]);
        }
    };

    MinMaxAction<bit<16>, bit<8>, bit<16>>(ping_egress_reg2) ping_egress_get4 = {
    void apply(inout bit<128> value, out bit<16> rv, out bit<16> subindex) {
            subindex = 0;
            rv = this.min16(value, 0x36, subindex[2:0]);
        }
    };
    MinMaxAction<bit<16>, bit<8>, bit<16>>(pong_egress_reg2) pong_egress_get4 = {
        void apply(inout bit<128> value, out bit<16> rv, out bit<16> subindex) {
            subindex = 0;
            rv = this.min16(value, 0x36, subindex[2:0]);
        }
    };

    MinMaxAction<bit<16>, bit<8>, bit<16>>(ping_egress_reg3) ping_egress_get5 = {
    void apply(inout bit<128> value, out bit<16> rv, out bit<16> subindex) {
            subindex = 0;
            rv = this.min16(value, 0x1E, subindex[2:0]);
        }
    };
    MinMaxAction<bit<16>, bit<8>, bit<16>>(pong_egress_reg3) pong_egress_get5 = {
        void apply(inout bit<128> value, out bit<16> rv, out bit<16> subindex) {
            subindex = 0;
            rv = this.min16(value, 0x1E, subindex[2:0]);
        }
    };

    MinMaxAction<bit<16>, bit<8>, bit<16>>(ping_egress_reg3) ping_egress_get6 = {
    void apply(inout bit<128> value, out bit<16> rv, out bit<16> subindex) {
            subindex = 0;
            rv = this.min16(value, 0x2E, subindex[2:0]);
        }
    };
    MinMaxAction<bit<16>, bit<8>, bit<16>>(pong_egress_reg3) pong_egress_get6 = {
        void apply(inout bit<128> value, out bit<16> rv, out bit<16> subindex) {
            subindex = 0;
            rv = this.min16(value, 0x2E, subindex[2:0]);
        }
    };

    //-------------------------------------------------------
    action ping_get_depth2() {
        ping_egress_get2.execute(idx, temp_rich_register_2);
    }
    action ping_get_depth3() {
        ping_egress_get3.execute(idx, temp_rich_register_2);
    }
    action ping_get_depth4() {
        ping_egress_get4.execute(idx, temp_rich_register_2);
    }
    action ping_get_depth5() {
        ping_egress_get5.execute(idx, temp_rich_register_2);
    }
    action ping_get_depth6() {
        ping_egress_get6.execute(idx, temp_rich_register_2);
    }

    action pong_get_depth2() {
        pong_egress_get2.execute(idx, temp_rich_register_2);
    }
    action pong_get_depth3() {
        pong_egress_get3.execute(idx, temp_rich_register_2);
    }
    action pong_get_depth4() {
        pong_egress_get4.execute(idx, temp_rich_register_2);
    }
    action pong_get_depth5() {
        pong_egress_get5.execute(idx, temp_rich_register_2);
    }
    action pong_get_depth6() {
        pong_egress_get6.execute(idx, temp_rich_register_2);
    }

    @stage(EG_QUEUE_REG_STAGE2)
    table ping_read2_tbl {
        key = {
            temp_rich_register_1 : exact;
        }
        actions = {
            ping_get_depth2;
            ping_get_depth3;
            ping_get_depth4;
            NoAction;
        }
        default_action = NoAction;
    }

    @stage(EG_QUEUE_REG_STAGE2)
    table pong_read2_tbl {
        key = {
            temp_rich_register_1 : exact;
        }
        actions = {
            pong_get_depth2;
            pong_get_depth3;
            pong_get_depth4;
            NoAction;
        }
        default_action = NoAction;
    }

    table ping_read2_p2_tbl {
        key = {
            temp_rich_register_1 : exact;
        }
        actions = {
            ping_get_depth5;
            ping_get_depth6;
            NoAction;
        }
        default_action = NoAction;
    }

    table pong_read2_p2_tbl {
        key = {
            temp_rich_register_1 : exact;
        }
        actions = {
            pong_get_depth5;
            pong_get_depth6;
            NoAction;
        }
        default_action = NoAction;
    }

    Register<bit<16>, bit<8>>(size=8, initial_value=5) last_rich;
    RegisterAction<bit<16>, bit<8>, bit<16>>(last_rich)
    update_last = {
        void apply(inout bit<16> register_data, out bit<16> result)
        {
            result = register_data;
            if (register_data == temp_rich_register_1)
                register_data = temp_rich_register_2;
            else
                register_data = temp_rich_register_1;
        }
    };


    /*Register<bit<8>, bit<1>>(size=1, initial_value=0) cmp_rich;
    RegisterAction<bit<8>, bit<1>, bit<8>>(cmp_rich)
    compare_rich = {
        void apply(inout bit<8> register_data, out bit<8> result)
        {
            result = register_data;
            if (register_data == 1)
                register_data = 0;
            else
                register_data = 1;
        }
    };

    Register<rich_pair, bit<16>>(size=8) rich_pair_reg;
    RegisterAction<rich_pair, bit<8>, bit<16>>(rich_pair_reg) read_first_and_update_second = {
        void apply(inout rich_pair value, out bit<16> read_value){
            read_value = value.first;
            if (value.first == temp_rich_register_1)
                value.second = temp_rich_register_2;
            else
                value.second = temp_rich_register_1;
        }
    };
    RegisterAction<rich_pair, bit<8>, bit<16>>(rich_pair_reg) read_second_and_update_first = {
        void apply(inout rich_pair value, out bit<16> read_value) {
            read_value = value.second;
            if (value.second == temp_rich_register_1)
                value.first = temp_rich_register_2;
            else
                value.first = temp_rich_register_1;
        }
    };

    action cmp_act_1() {
        rich_register = read_first_and_update_second.execute(idx);
    }
    action cmp_act_2() {
        rich_register = read_second_and_update_first.execute(idx);
    }

    @stage(QUEUE_REG_STAGE4)
    table compare_step_3_tbl {
    	key = {
            compare : exact;
    	}
        actions = {
            cmp_act_1;
            cmp_act_2;
        }
        const entries = {
            (  0  ) : cmp_act_1();
            (  1  ) : cmp_act_2();
    	}
    }*/


/************************************************************************************/
    apply {
        //compare = compare_rich.execute(0);
        if (g_intr_md.ping_pong == 0) {
            ping_read_tbl.apply();
            ping_read2_tbl.apply();
            ping_read2_p2_tbl.apply();
        }
        else {
            pong_read_tbl.apply();
            pong_read2_tbl.apply();
            pong_read2_p2_tbl.apply();
        }
        //compare_step_3_tbl.apply();
        rich_register = update_last.execute(idx);
    }
}
