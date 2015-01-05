#include "sections.h"
#include "stage.h"
#include "phv.h"
#include <fstream>

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
        for (auto table : stage[i].tables)
            table->write_regs();
        char buffer[64];
        sprintf(buffer, "regs.match_action_stage.%02x.cfg.json", i);
        std::ofstream out(buffer);
        stage[i].regs.emit_json(out, i);
    }
}

