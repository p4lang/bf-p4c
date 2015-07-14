#include "sections.h"
#include "stage.h"
#include "phv.h"
#include "range.h"
#include "input_xbar.h"
#include "top_level.h"

unsigned char Stage::action_bus_slot_map[ACTION_DATA_BUS_BYTES];
unsigned char Stage::action_bus_slot_size[ACTION_DATA_BUS_SLOTS];

class AsmStage : public Section {
    void start(int lineno, VECTOR(value_t) args);
    void input(VECTOR(value_t) args, value_t data);
    void process();
    void output();
    AsmStage();
    ~AsmStage() {}
    std::vector<Stage>  stage;
    static AsmStage     singleton_object;
public:
    static int numstages() { return singleton_object.stage.size(); }
} AsmStage::singleton_object;

AsmStage::AsmStage() : Section("stage") {
    int slot = 0, byte = 0;
    stage.reserve(NUM_MAU_STAGES);
    //if (options.match_compiler)
    //    stage.resize(NUM_MAU_STAGES);
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
    else if (args[0].i < 0)
        error(lineno, "invalid stage number");
    else if ((unsigned)args[0].i >= stage.size()) {
        if (args[0].i >= NUM_MAU_STAGES)
            warning(lineno, "tofino only supports %d stages, using %d",
                    NUM_MAU_STAGES, args[0].i + 1);
        stage.resize(args[0].i + 1);
        for (unsigned  i = 0; i < stage.size(); i++)
            stage[i].stageno = i; }
}

void AsmStage::input(VECTOR(value_t) args, value_t data) {
    if (!CHECKTYPE(data, tMAP)) return;
    int stageno = args[0].i;
    assert(stageno >= 0 && (unsigned)stageno < stage.size());
    gress_t gress = args[1] == "egress" ? EGRESS : INGRESS;
    for (auto &kv : data.map) {
        if (kv.key == "dependency") {
            if (stage[stageno].stage_dep[gress])
                error(kv.key.lineno, "Multiple dependencies specified for %sgress stage %d",
                      gress ? "e" : "in", stageno);
            else if (stageno == 0)
                warning(kv.key.lineno, "Stage dependency in stage 0 will be ignored");
            if (kv.value == "concurrent")
                stage[stageno].stage_dep[gress] = Stage::CONCURRENT;
            else if (kv.value == "action")
                stage[stageno].stage_dep[gress] = Stage::ACTION_DEP;
            else if (kv.value == "match")
                stage[stageno].stage_dep[gress] = Stage::MATCH_DEP;
            else
                error(kv.value.lineno, "Syntax error, invalid stage dependency");
            continue; }
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
    for (unsigned i = 0; i < stage.size(); i++) {
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
                Phv::setuse(gress, stage[i].action_set[gress]); }
#if 0
            /* if a stage is used only in ingress or egress, the compiler configures delays
             *  for the unused part to be match dependent rather than concurrent. */
            if (stage[i].stage_dep[INGRESS] && !stage[i].stage_dep[EGRESS])
                stage[i].stage_dep[EGRESS] = Stage::MATCH_DEP;
            else if (!stage[i].stage_dep[INGRESS] && stage[i].stage_dep[EGRESS])
                stage[i].stage_dep[INGRESS] = Stage::MATCH_DEP;
#endif
        }
    }
}

void AsmStage::output() {
    json::vector        tbl_cfg;
    for (unsigned i = 0; i < stage.size(); i++) {
        //if  (stage[i].tables.empty()) continue;
        for (auto table : stage[i].tables)
            table->pass2(); }
    if (error_count > 0) return;
    for (gress_t gress : Range(INGRESS, EGRESS)) {
        bitvec set_regs = stage[0].action_set[gress];
        for (unsigned i = 1; i < stage.size(); i++) {
            if (!stage[i].stage_dep[gress]) {
                if (stage[i].match_use[gress].intersects(set_regs)) {
                    LOG1("stage " << i << " " << gress << " is match dependent on previous stage");
                    stage[i].stage_dep[gress] = Stage::MATCH_DEP;
                } else if (stage[i].action_use[gress].intersects(set_regs)) {
                    LOG1("stage " << i << " " << gress << " is action dependent on previous stage");
                    stage[i].stage_dep[gress] = Stage::ACTION_DEP;
                } else {
                    LOG1("stage " << i << " " << gress << " is concurrent with previous stage");
                    stage[i].stage_dep[gress] = Stage::CONCURRENT; } }
            if (stage[i].stage_dep[gress] == Stage::MATCH_DEP)
                set_regs = stage[i].action_set[gress];
            else
                set_regs |= stage[i].action_set[gress]; }
        stage[0].group_table_use[gress] = stage[0].table_use[gress];
        /* propagate group_table_use to adjacent stages that are not match-dependent */
        for (unsigned i = 1; i < stage.size(); i++) {
            stage[i].group_table_use[gress] = stage[i].table_use[gress];
            if (stage[i].stage_dep[gress] != Stage::MATCH_DEP)
                stage[i].group_table_use[gress] |= stage[i-1].group_table_use[gress]; }
        for (unsigned i = stage.size()-1; i > 0; i--)
            if (stage[i].stage_dep[gress] != Stage::MATCH_DEP)
                stage[i-1].group_table_use[gress] |= stage[i].group_table_use[gress]; }
    for (unsigned i = 0; i < stage.size(); i++) {
        // if  (stage[i].tables.empty()) continue;
        for (auto table : stage[i].tables) {
            table->write_regs();
            table->gen_tbl_cfg(tbl_cfg); }
        stage[i].write_regs();
        stage[i].regs.emit_json(*open_output("regs.match_action_stage.%02x.cfg.json", i) , i);
        char buf[64];
        sprintf(buf, "regs.match_action_stage.%02x", i);
        TopLevel::all.reg_pipe.mau[i] = buf; }
    *open_output("tbl-cfg") << '[' << &tbl_cfg << (options.match_compiler ? ",\n[] " : "")
                            << ']' << std::endl;
    TopLevel::all.mem_pipe.mau.disable();
}

Stage::Stage() {
    static_assert(sizeof(Stage_data) == sizeof(Stage),
                  "All non-static Stage fields must be in Stage_data");
    table_use[0] = table_use[1] = NONE;
    stage_dep[0] = stage_dep[1] = NONE;
    declare_registers(&regs, sizeof(regs),
        [this](std::ostream &out, const char *addr, const void *end) {
            out << "mau[" << stageno << "]";
            regs.emit_fieldname(out, addr, end); });
}

Stage::~Stage() {
    undeclare_registers(&regs);
}

Stage::Stage(Stage &&a) : Stage_data(std::move(a)) {
    for (auto ref : all_refs)
        *ref = this;
    declare_registers(&regs, sizeof(regs),
        [this](std::ostream &out, const char *addr, const void *end) {
            out << "mau[" << stageno << "]";
            regs.emit_fieldname(out, addr, end); });
}

static int tcam_delay(int use_flags) {
    return use_flags & Stage::USE_TCAM ? use_flags & Stage::USE_TCAM_PIPED ? 4 : 4 : 0;
}
static int adr_dist_delay(int use_flags) {
    if (use_flags & Stage::USE_SELECTOR)
        return 9;
    else if (use_flags & Stage::USE_METER)
        return 5;
    else if (use_flags & Stage::USE_STATEFUL)
        return 4;
    else
        return 0;
}

static int pipelength(int use_flags) {
    return 14 + tcam_delay(use_flags) + adr_dist_delay(use_flags);
}
static int pred_cycle(int use_flags) {
    return 7 + tcam_delay(use_flags);
}

void Stage::write_regs() {
    /* FIXME -- most of the values set here are 'placeholder' constants copied
     * from build_pipeline_output_2.py in the compiler */
    auto &merge = regs.rams.match.merge;
    // FIXME -- there are a number of places where the compiler appears to use the
    // FIXME -- use stats of just the current stage, rather than a group of concurrent
    // FIXME -- stages to program delays.
    int *match_compiler_table_use = options.match_compiler ? table_use : group_table_use;
    merge.exact_match_delay_config.exact_match_delay_ingress =
        match_compiler_table_use[INGRESS] & (Stage::USE_TCAM | Stage::USE_WIDE_SELECTOR) ? 3 : 0;
    merge.exact_match_delay_config.exact_match_delay_egress =
        match_compiler_table_use[EGRESS] & (Stage::USE_TCAM | Stage::USE_WIDE_SELECTOR) ? 3 : 0;
    for (gress_t gress : Range(INGRESS, EGRESS)) {
        if (stageno == 0) {
            merge.predication_ctl[gress].start_table_fifo_delay0 = pred_cycle(table_use[gress]) - 1;
            merge.predication_ctl[gress].start_table_fifo_delay1 = 0;
            merge.predication_ctl[gress].start_table_fifo_enable = 1;
        } else switch (stage_dep[gress]) {
        case MATCH_DEP:
            if (options.match_compiler) {
                merge.predication_ctl[gress].start_table_fifo_delay0 =
                    pipelength(this[-1].table_use[gress])
                    - pred_cycle(this[-1].table_use[gress])
                    + pred_cycle(table_use[gress]) - 1;
                merge.predication_ctl[gress].start_table_fifo_delay1 =
                    pipelength(this[-1].table_use[gress])
                    - pred_cycle(this[-1].table_use[gress]) + 1;
            } else {
                merge.predication_ctl[gress].start_table_fifo_delay0 =
                    pipelength(this[-1].group_table_use[gress])
                    - pred_cycle(this[-1].table_use[gress])
                    + pred_cycle(table_use[gress]) - 1;
                merge.predication_ctl[gress].start_table_fifo_delay1 =
                    pipelength(this[-1].group_table_use[gress])
                    - pred_cycle(this[-1].table_use[gress]) + 1;
            }
            merge.predication_ctl[gress].start_table_fifo_enable = 3;
            break;
        case ACTION_DEP:
            merge.predication_ctl[gress].start_table_fifo_delay0 = 1;
            merge.predication_ctl[gress].start_table_fifo_delay1 = 0;
            merge.predication_ctl[gress].start_table_fifo_enable = 1;
            break;
        case CONCURRENT:
            merge.predication_ctl[gress].start_table_fifo_enable = 0;
            break;
        default:
            assert(0); }
        regs.rams.match.adrdist.adr_dist_pipe_delay[gress] = adr_dist_delay(match_compiler_table_use[gress]);
        auto &deferred_eop_bus_delay = regs.rams.match.adrdist.deferred_eop_bus_delay[gress];
        deferred_eop_bus_delay.eop_internal_delay_fifo = pred_cycle(match_compiler_table_use[gress]);
        /* FIXME -- making this depend on the dependecny of the next stage seems wrong */
        if (stageno == AsmStage::numstages()-1)
            deferred_eop_bus_delay.eop_output_delay_fifo = pipelength(match_compiler_table_use[gress]);
        else if (this[1].stage_dep[gress] == MATCH_DEP)
            deferred_eop_bus_delay.eop_output_delay_fifo = pipelength(match_compiler_table_use[gress]);
        else if (this[1].stage_dep[gress] == ACTION_DEP)
            deferred_eop_bus_delay.eop_output_delay_fifo = 2;
        else
            deferred_eop_bus_delay.eop_output_delay_fifo = 1;
        deferred_eop_bus_delay.eop_delay_fifo_en = 1;
        regs.dp.action_output_delay[gress] = pipelength(match_compiler_table_use[gress]) - 3;
        regs.dp.pipelength_added_stages[gress] = pipelength(match_compiler_table_use[gress]) - 14;
        if (stageno != 0) {
            regs.dp.cur_stage_dependency_on_prev[gress] = MATCH_DEP - stage_dep[gress];
            if (stage_dep[gress] == CONCURRENT)
                regs.dp.stage_concurrent_with_prev |= 1U << gress; }
        if (stageno != AsmStage::numstages()-1)
            regs.dp.next_stage_dependency_on_cur[gress] = MATCH_DEP - this[1].stage_dep[gress];
        if (stageno == 0 || stage_dep[gress] == MATCH_DEP)
            regs.dp.match_ie_input_mux_sel |= 1 << gress;
    }
    /* FIXME -- need to set based on interstage dependencies */
    regs.dp.phv_fifo_enable.phv_fifo_ingress_action_output_enable = stage_dep[INGRESS] != ACTION_DEP;
    regs.dp.phv_fifo_enable.phv_fifo_ingress_final_output_enable = stage_dep[INGRESS] == ACTION_DEP;
    regs.dp.phv_fifo_enable.phv_fifo_egress_action_output_enable = stage_dep[EGRESS] != ACTION_DEP;
    regs.dp.phv_fifo_enable.phv_fifo_egress_final_output_enable = stage_dep[EGRESS] == ACTION_DEP;
    bitvec in_use = match_use[INGRESS] | action_use[INGRESS] | action_set[INGRESS];
    bitvec eg_use = match_use[EGRESS] | action_use[EGRESS] | action_set[EGRESS];
    if (options.match_compiler) {
        /* the compiler occasionally programs extra uses of random registers on
         * busses where it doesn't actually use them.  Sometimes, these regs
         * are in use by the other thread, so rely on the deparser to correctly
         * set the Phv::use info and strip out registers it says are used by
         * the other thread */
        in_use -= Phv::use(EGRESS);
        eg_use -= Phv::use(INGRESS);
        in_use |= Phv::use(INGRESS);
        eg_use |= Phv::use(EGRESS); }
    for (int i = 0; i < 2; i++) {
        for (int j = 0; j < 7; j++) {
            regs.dp.phv_ingress_thread[i][j] = in_use.getrange(32*j, 32);
            regs.dp.phv_egress_thread[i][j] = eg_use.getrange(32*j, 32); } }
    for (auto gress : Range(INGRESS, EGRESS))
        if (table_use[gress] & USE_TCAM_PIPED)
            regs.tcams.tcam_piped |=  options.match_compiler ? 3 : 1 << gress;
    /* FIXME - by default always enable slow mode (match compiler), but should be configurable */
    for (int row = 0; row < SRAM_ROWS; row++)
        regs.rams.map_alu.row[row].adrmux.adrmux_row_mem_slow_mode = 1;
    regs.cfg_regs.mau_cfg_mem_slow_mode = 1;
}
