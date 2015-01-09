#include "sections.h"
#include "stage.h"
#include "phv.h"
#include <fstream>
#include "range.h"

#define NUM_MAU_STAGES  12

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
            error(kv.key[1].lineno, "Table %s already defined\n", kv.key[1].s);
            warning(old->lineno, "previously defined here\n");
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
            table->pass1(); }
}

void AsmStage::output() {
    for (int i = 0; i < NUM_MAU_STAGES; i++) {
        if  (stage[i].tables.empty()) continue;
        for (auto table : stage[i].tables)
            table->pass2();
        if (error_count > 0) return;
        for (auto table : stage[i].tables)
            table->write_regs();
        stage[i].write_regs();
        char buffer[64];
        sprintf(buffer, "regs.match_action_stage.%02x.cfg.json", i);
        std::ofstream out(buffer);
        stage[i].regs.emit_json(out, i);
    }
}

/* FIXME -- HW specs 11 for min delay, compiler uses 10 */
                                    /* !  TCAM   ! TCAM
                                     * !    !   STATEFUL  */   
static int action_output_delay[8] = { 10,  12,  15,  16,    /* not PIPED */
                                      10,  13,  15,  17 };  /* PIPED */

void Stage::write_regs() {
    /* FIXME -- most of the values set here are 'placeholder' constants copied
     * from build_pipeline_output_2.py in the compiler */
    auto &merge = regs.rams.match.merge;
    merge.exact_match_delay_config.exact_match_delay_ingress =
        table_use[INGRESS] & USE_TCAM ? 3 : 0;
    merge.exact_match_delay_config.exact_match_delay_egress =
        table_use[EGRESS] & USE_TCAM ? 3 : 0;
    for (int v : VersionIter(config_version)) {
        for (gress_t gress : Range(INGRESS, EGRESS)) {
            merge.predication_ctl[gress][v].start_table_fifo_delay0 = 15;
            merge.predication_ctl[gress][v].start_table_fifo_delay1 = 8;
            merge.predication_ctl[gress][v].start_table_fifo_enable = stageno ? 3 : 1;
            regs.dp.action_output_delay[gress][v] = action_output_delay[table_use[gress]];
            regs.dp.final_output_delay[gress][v] = 0;
            regs.dp.cur_stage_dependency_on_prev[gress][v] = 0;
            regs.dp.next_stage_dependency_on_cur[gress][v] = 0; }
        regs.dp.match_ie_input_mux_sel[v] = 3;
        regs.dp.stage_concurrent_with_prev[v] = stageno ? 0 : 3;
        regs.dp.phv_fifo_enable[v].phv_fifo_ingress_final_output_enable = 0;
        regs.dp.phv_fifo_enable[v].phv_fifo_egress_final_output_enable = 0;
        regs.dp.phv_fifo_enable[v].phv_fifo_ingress_action_output_enable = 1;
        regs.dp.phv_fifo_enable[v].phv_fifo_egress_action_output_enable = 1; }
    for (int i = 0; i < 2; i++) {
        for (int j = 0; j < 7; j++) {
            regs.dp.phv_ingress_thread[i][j] = phv_use[INGRESS].getrange(32*j, 32) |
                    Phv::use(INGRESS).getrange(32*j, 32);
            regs.dp.phv_egress_thread[i][j] = phv_use[EGRESS].getrange(32*j, 32) |
                    Phv::use(EGRESS).getrange(32*j, 32); } }
    if (table_use[INGRESS] & USE_TCAM_PIPED)
        regs.tcams.tcam_piped |= 1;
    if (table_use[EGRESS] & USE_TCAM_PIPED)
        regs.tcams.tcam_piped |= 2;
}

