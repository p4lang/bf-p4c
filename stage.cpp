#include "sections.h"
#include "stage.h"
#include "phv.h"
#include "range.h"
#include "input_xbar.h"

unsigned char Stage::action_bus_slot_map[ACTION_DATA_BUS_BYTES];
unsigned char Stage::action_bus_slot_size[ACTION_DATA_BUS_SLOTS];

class AsmStage : public Section {
    void start(int lineno, VECTOR(value_t) args);
    void input(VECTOR(value_t) args, value_t data);
    void process();
    void output();
    AsmStage();
    ~AsmStage() {}
    Stage stage[NUM_MAU_STAGES];
    static AsmStage     singleton_object;
} AsmStage::singleton_object;

AsmStage::AsmStage() : Section("stage") {
    for (int i = 0; i < NUM_MAU_STAGES; i++)
        stage[i].stageno = 0;
    int slot = 0, byte = 0;
    for (int i = 0; i < ACTION_DATA_8B_SLOTS; i++) {
        Stage::action_bus_slot_map[byte++] = slot;
        Stage::action_bus_slot_size[slot++] = 8; }
    for (int i = 0; i < ACTION_DATA_16B_SLOTS; i++) {
        Stage::action_bus_slot_map[byte++] = slot;
        Stage::action_bus_slot_map[byte++] = slot;
        Stage::action_bus_slot_size[slot++] = 16; }
    for (int i = 0; i < ACTION_DATA_32B_SLOTS; i++) {
        Stage::action_bus_slot_map[byte++] = slot;
        Stage::action_bus_slot_map[byte++] = slot;
        Stage::action_bus_slot_map[byte++] = slot;
        Stage::action_bus_slot_map[byte++] = slot;
        Stage::action_bus_slot_size[slot++] = 32; }
    assert(byte == ACTION_DATA_BUS_BYTES);
    assert(slot == ACTION_DATA_BUS_SLOTS);
}

void AsmStage::start(int lineno, VECTOR(value_t) args) {
    if (args.size != 2 || args[0].type != tINT || (args[1] != "ingress" && args[1] != "egress"))
        error(lineno, "stage must specify number and ingress or egress");
    else if (args[0].i < 0 || args[0].i >= NUM_MAU_STAGES)
        error(lineno, "stage numner out of range");
}

void AsmStage::input(VECTOR(value_t) args, value_t data) {
    if (!CHECKTYPE(data, tMAP)) return;
    int stageno = args[0].i;
    assert(stageno >= 0 && stageno < NUM_MAU_STAGES);
    gress_t gress = args[1] == "egress" ? EGRESS : INGRESS;
    for (auto &kv : data.map) {
        if (!CHECKTYPEM(kv.key, tCMD, "table declaration")) continue;
        if (!CHECKTYPE(kv.value, tMAP)) continue;
        auto tt = Table::Type::get(kv.key[0].s);
        if (!tt) {
            error(kv.key[0].lineno, "Unknown table type '%s'", kv.key[0].s);
            continue; }
        if (kv.key.vec.size < 2) {
            error(kv.key.lineno, "Need table name");
            continue; }
        if (!CHECKTYPE(kv.key[1], tSTR)) continue;
        if (kv.key.vec.size > 2 && !CHECKTYPE(kv.key[2], tINT)) continue;
        if (kv.key.vec.size > 3) warning(kv.key[3].lineno, "Ignoring extra stuff after table");
        if (auto old = ::get(Table::all, kv.key[1].s)) {
            error(kv.key[1].lineno, "Table %s already defined", kv.key[1].s);
            warning(old->lineno, "previously defined here");
            continue; }
        if (Table *table = tt->create(kv.key.lineno, kv.key[1].s, gress, &stage[stageno],
                                      kv.key.vec.size > 2 ? kv.key[2].i : -1, kv.value.map)) {
            stage[stageno].tables.push_back(table); } }
}

void AsmStage::process() {
    for (int i = 0; i < NUM_MAU_STAGES; i++) {
        stage[i].pass1_logical_id = -1;
        stage[i].pass1_tcam_id = -1;
        for (auto table : stage[i].tables)
            table->pass1();
        if (options.match_compiler) {
            /* FIXME -- do we really want to do this?  In theory different stages could
             * FIXME -- use the same PHV slots differently, but the compiler always uses them
             * FIXME -- consistently, so we need this to get bit-identical results */
            for (auto gress : Range(INGRESS, EGRESS)) {
                Phv::setuse(gress, stage[i].match_use[gress]);
                Phv::setuse(gress, stage[i].action_use[gress]);
                Phv::setuse(gress, stage[i].action_set[gress]); } } }
}

void AsmStage::output() {
    json::vector        tbl_cfg;
    for (int i = 0; i < NUM_MAU_STAGES; i++) {
        if  (stage[i].tables.empty()) continue;
        for (auto table : stage[i].tables)
            table->pass2();
        if (error_count > 0) return;
        for (auto table : stage[i].tables) {
            table->write_regs();
            table->gen_tbl_cfg(tbl_cfg); }
        stage[i].write_regs();
        stage[i].regs.emit_json(*open_output("regs.match_action_stage.%02x.cfg.json", i) , i);
    }
    *open_output("tbl-cfg") << &tbl_cfg << std::endl;
}

static int tcam_delay(int use_flags) {
    return use_flags & Stage::USE_TCAM ? use_flags & Stage::USE_TCAM_PIPED ? 3 : 2 : 0;
}

static int pipelength_added_stages(int use_flags) {
    int rv = tcam_delay(use_flags);
    if (use_flags & Stage::USE_SELECTOR)
        rv += 9;
    else if (use_flags & Stage::USE_METER)
        rv += 5;
    else if (use_flags & Stage::USE_STATEFUL)
        rv += 4;
    return rv;
}

void Stage::write_regs() {
    /* FIXME -- most of the values set here are 'placeholder' constants copied
     * from build_pipeline_output_2.py in the compiler */
    auto &merge = regs.rams.match.merge;
    merge.exact_match_delay_config.exact_match_delay_ingress = tcam_delay(table_use[INGRESS]);
    merge.exact_match_delay_config.exact_match_delay_egress = tcam_delay(table_use[EGRESS]);
    for (gress_t gress : Range(INGRESS, EGRESS)) {
        merge.predication_ctl[gress].start_table_fifo_delay0 = 6 + tcam_delay(table_use[gress]);
        merge.predication_ctl[gress].start_table_fifo_delay1 = 0;
        merge.predication_ctl[gress].start_table_fifo_enable = stageno ? 3 : 1;
        int add = pipelength_added_stages(table_use[gress]);
        regs.dp.action_output_delay[gress] = 11 + add;
        regs.dp.pipelength_added_stages[gress] = add;
        regs.dp.cur_stage_dependency_on_prev[gress] = 0;
        regs.dp.next_stage_dependency_on_cur[gress] = 0; }
    regs.dp.match_ie_input_mux_sel = 3;
    /* FIXME -- need to figure out interstage dependencies */
    regs.dp.stage_concurrent_with_prev = 0;
    regs.dp.phv_fifo_enable.phv_fifo_ingress_final_output_enable = 0;
    regs.dp.phv_fifo_enable.phv_fifo_egress_final_output_enable = 0;
    regs.dp.phv_fifo_enable.phv_fifo_ingress_action_output_enable = 1;
    regs.dp.phv_fifo_enable.phv_fifo_egress_action_output_enable = 1;
    bitvec in_use = match_use[INGRESS] | action_use[INGRESS] | action_set[INGRESS];
    bitvec eg_use = match_use[EGRESS] | action_use[EGRESS] | action_set[EGRESS];
    if (options.match_compiler) {
        in_use |= Phv::use(INGRESS);
        eg_use |= Phv::use(EGRESS); }
    for (int i = 0; i < 2; i++) {
        for (int j = 0; j < 7; j++) {
            regs.dp.phv_ingress_thread[i][j] = in_use.getrange(32*j, 32);
            regs.dp.phv_egress_thread[i][j] = eg_use.getrange(32*j, 32); } }
    for (auto gress : Range(INGRESS, EGRESS)) {
        if (table_use[gress] & USE_TCAM) {
            if (table_use[gress] & USE_TCAM_PIPED) {
                if (options.match_compiler)
                    regs.tcams.tcam_piped |= 3;
                else
                    regs.tcams.tcam_piped |= 1 << gress;
                merge.mau_thread_tcam_delay[gress] = 3;
            } else 
                merge.mau_thread_tcam_delay[gress] = 2; } }
}

int Stage::find_on_ixbar(Phv::Slice sl, int group) {
    for (auto *in : exact_ixbar[group]) {
        if (auto *i = in->find(sl, group)) {
            unsigned bit = (i->lo + sl.lo - i->what->lo);
            assert(bit%8 == 0);
            assert(bit < 128);
            return bit/8; } }
    assert(0);
    return -1;
}

