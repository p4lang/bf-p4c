#include <config.h>
#include <time.h>

#include "sections.h"
#include "stage.h"
#include "phv.h"
#include "deparser.h"
#include "parser.h"
#include "range.h"
#include "input_xbar.h"
#include "top_level.h"
#include "target.h"
#include "misc.h"

extern std::string asmfile_name;

unsigned char Stage::action_bus_slot_map[ACTION_DATA_BUS_BYTES];
unsigned char Stage::action_bus_slot_size[ACTION_DATA_BUS_SLOTS];

class AsmStage : public Section {
    void start(int lineno, VECTOR(value_t) args);
    void input(VECTOR(value_t) args, value_t data);
    void process();
    void output(json::map &);
    AsmStage();
    ~AsmStage() {}
    std::vector<Stage>  stage;
    static AsmStage     singleton_object;
public:
    static int numstages() { return singleton_object.stage.size(); }
    static std::vector<Stage> &stages() { return singleton_object.stage; }
} AsmStage::singleton_object;

AsmStage::AsmStage() : Section("stage") {
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
    size_t oldsize = stage.size();
    if (stage.size() < Target::NUM_MAU_STAGES())
        stage.resize(Target::NUM_MAU_STAGES());
    if (args.size != 2 || args[0].type != tINT ||
        (args[1] != "ingress" && args[1] != "egress" &&
         (args[1] != "ghost" || options.target < JBAY)))
        error(lineno, "stage must specify number and ingress%s or egress",
            options.target >= JBAY ? ", ghost" : "");
    else if (args[0].i < 0)
        error(lineno, "invalid stage number");
    else if ((unsigned)args[0].i >= stage.size()) {
        stage.resize(args[0].i + 1); }
    for (size_t i = oldsize; i < stage.size(); i++)
        stage[i].stageno = i;
}

void AsmStage::input(VECTOR(value_t) args, value_t data) {
    if (!CHECKTYPE(data, tMAP)) return;
    int stageno = args[0].i;
    assert(stageno >= 0 && (unsigned)stageno < stage.size());
    gress_t gress = args[1] == "ingress" ? INGRESS
                  : args[1] == "egress" ? EGRESS
                  : args[1] == "ghost" && options.target >= JBAY ? GHOST
                  : (error(args[1].lineno, "Invalid thread %s", value_desc(args[1])), INGRESS);
    for (auto &kv : MapIterChecked(data.map, true)) {
        if (kv.key == "dependency") {
            if (stageno == 0)
                warning(kv.key.lineno, "Stage dependency in stage 0 will be ignored");
            if (gress == GHOST) {
                error(kv.key.lineno, "Can't specify dependency in ghost thread; it is "
                      "locked to ingress");
            } else if (kv.value == "concurrent") {
                stage[stageno].stage_dep[gress] = Stage::CONCURRENT;
                if (stageno == Target::NUM_MAU_STAGES()/2)
                    error(kv.value.lineno, "stage %d must be match dependent", stageno);
#ifdef HAVE_JBAY
                else if (options.target == JBAY)
                    error(kv.value.lineno, "no concurrent execution on Tofino2");
#endif /* HAVE_JBAY */
            } else if (kv.value == "action") {
                stage[stageno].stage_dep[gress] = Stage::ACTION_DEP;
                if (stageno == Target::NUM_MAU_STAGES()/2)
                    error(kv.value.lineno, "stage %d must be match dependent", stageno);
            } else if (kv.value == "match")
                stage[stageno].stage_dep[gress] = Stage::MATCH_DEP;
            else
                error(kv.value.lineno, "Invalid stage dependency %s", value_desc(kv.value));
            continue;
        } else if (kv.key == "error_mode") {
            if (gress == GHOST)
                error(kv.key.lineno, "Can't specify error mode in ghost thread");
            else if (kv.value == "no_config")
                stage[stageno].error_mode[gress] = Stage::NO_CONFIG;
            else if (kv.value == "propagate")
                stage[stageno].error_mode[gress] = Stage::PROPAGATE;
            else if (kv.value == "map_to_immediate")
                stage[stageno].error_mode[gress] = Stage::MAP_TO_IMMEDIATE;
            else if (kv.value == "disable")
                stage[stageno].error_mode[gress] = Stage::DISABLE_ALL_TABLES;
            else
                error(kv.value.lineno, "Unknown error mode %s", value_desc(kv.value));
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
            table->pass0();
    }
    for (unsigned i = 0; i < stage.size(); i++) {
        for (auto table : stage[i].tables)
            table->pass1();
        if (options.target == TOFINO) {
            if (i == Target::NUM_MAU_STAGES()/2) {
                /* to turn the corner, the middle stage must always be match dependent */
                for (gress_t gress : Range(INGRESS, EGRESS))
                    stage[i].stage_dep[gress] = Stage::MATCH_DEP; }
        }
        if (options.match_compiler || 1) {
            /* FIXME -- do we really want to do this?  In theory different stages could
             * FIXME -- use the same PHV slots differently, but the compiler always uses them
             * FIXME -- consistently, so we need this to get bit-identical results
             * FIXME -- we also don't correctly determine liveness, so need this */
            for (gress_t gress : Range(INGRESS, GHOST)) {
                Phv::setuse(gress, stage[i].match_use[gress]);
                Phv::setuse(gress, stage[i].action_use[gress]);
                Phv::setuse(gress, stage[i].action_set[gress]); }
        }
    }
}

void AsmStage::output(json::map &ctxt_json) {
    for (unsigned i = 0; i < stage.size(); i++) {
        for (auto table : stage[i].tables)
            table->pass2(); }
    for (unsigned i = 0; i < stage.size(); i++) {
        for (auto table : stage[i].tables)
            table->pass3(); }
    if (stage.size() > Target::NUM_MAU_STAGES())
        error(stage.back().tables.empty() ? 0 : stage.back().tables[0]->lineno,
              "%s supports up to %d stages, using %zd", Target::name(), Target::NUM_MAU_STAGES(),
              stage.size());
    if (error_count > 0) return;
    if (stage.empty()) return;

#if HAVE_JBAY
    /* Allow to set any stage as match dependent based on a pattern - Should never be used for
     * normal compilation */
    if (options.target == JBAY && !options.stage_dependency_pattern.empty()) {
        for (gress_t gress : Range(INGRESS, EGRESS)) {
            for (unsigned i = 0; i < stage.size(); i++) {
                    if ((options.stage_dependency_pattern.size() > i) &&
                        (options.stage_dependency_pattern.at(i) == '1')) {
                            LOG1("explicitly setting stage " << i << " " << gress
                                << " as match dependent on previous stage");
                            stage[i].stage_dep[gress] = Stage::MATCH_DEP;
                    }
            }
        }
    }
#endif

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
                    if (options.target == JBAY)
                        stage[i].stage_dep[gress] = Stage::ACTION_DEP;
                    else
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
        for (int i = stage.size()-1; i > 0; i--)
            if (stage[i].stage_dep[gress] != Stage::MATCH_DEP)
                stage[i-1].group_table_use[gress] |= stage[i].group_table_use[gress]; }

    for (unsigned i = 0; i < stage.size(); i++)
        SWITCH_FOREACH_TARGET(options.target, stage[i].output<TARGET>(ctxt_json);)


}

static FakeTable invalid_rams("RAMS NOT PRESENT");

Stage::Stage() {
    static_assert(sizeof(Stage_data) == sizeof(Stage),
                  "All non-static Stage fields must be in Stage_data");
    table_use[0] = table_use[1] = NONE;
    stage_dep[0] = stage_dep[1] = NONE;
    error_mode[0] = error_mode[1] = PROPAGATE;
    for (int i = 0; i < SRAM_ROWS; i++)
        sram_use[i][0] = sram_use[i][1] = &invalid_rams;
}

Stage::~Stage() {
}

int Stage::first_table(gress_t gress) {
    for (auto &st : AsmStage::stages()) {
        int min_logical_id = INT_MAX;
        for (auto tbl : st.tables) {
            if (tbl->gress != gress) continue;
            if (tbl->logical_id < min_logical_id)
                min_logical_id = tbl->logical_id; }
        if (min_logical_id >= 0 && min_logical_id != INT_MAX) {
            assert((min_logical_id & ~0xf) == 0);
            return (st.stageno << 4) + min_logical_id; } }
    return -1;
}

Stage::Stage(Stage &&a) : Stage_data(std::move(a)) {
    for (auto ref : all_refs)
        *ref = this;
}

int Stage::tcam_delay(gress_t gress) {
    if (group_table_use[timing_thread(gress)] & Stage::USE_TCAM_PIPED)
        return 2;
    if (group_table_use[timing_thread(gress)] & Stage::USE_TCAM)
        return 2;
    if (group_table_use[timing_thread(gress)] & Stage::USE_WIDE_SELECTOR)
        return 2;
    return 0;
}

int Stage::adr_dist_delay(gress_t gress) {
    if (group_table_use[timing_thread(gress)] & Stage::USE_SELECTOR)
        return 8;
    else if (group_table_use[timing_thread(gress)] & Stage::USE_STATEFUL_DIVIDE)
        return 5;
    else if (group_table_use[timing_thread(gress)] & Stage::USE_STATEFUL)
        return 4;
    else if (group_table_use[timing_thread(gress)] & Stage::USE_METER_LPF_RED)
        return 4;
    else
        return 0;
}

int Stage::pipelength(gress_t gress) {
    return Target::MAU_BASE_DELAY() + tcam_delay(gress) + adr_dist_delay(gress);
}

int Stage::pred_cycle(gress_t gress) {
    return Target::MAU_BASE_PREDICATION_DELAY() + tcam_delay(gress);
}

#include "tofino/stage.cpp"
#ifdef HAVE_JBAY
#include "jbay/stage.cpp"
#endif /* HAVE_JBAY */

template<class TARGET> void Stage::write_common_regs(typename TARGET::mau_regs &regs) {
    /* FIXME -- most of the values set here are 'placeholder' constants copied
     * from build_pipeline_output_2.py in the compiler */
    auto &merge = regs.rams.match.merge;
    auto &adrdist = regs.rams.match.adrdist;
    //merge.exact_match_delay_config.exact_match_delay_ingress = tcam_delay(INGRESS);
    //merge.exact_match_delay_config.exact_match_delay_egress = tcam_delay(EGRESS);
    for (gress_t gress : Range(INGRESS, EGRESS)) {
        if (tcam_delay(gress) > 0) {
            merge.exact_match_delay_thread[0] |= 1U << gress;
            merge.exact_match_delay_thread[1] |= 1U << gress;
            merge.exact_match_delay_thread[2] |= 1U << gress; }
        regs.rams.match.adrdist.adr_dist_pipe_delay[gress][0] =
        regs.rams.match.adrdist.adr_dist_pipe_delay[gress][1] = adr_dist_delay(gress);
        regs.dp.action_output_delay[gress] = pipelength(gress) - 3;
        regs.dp.pipelength_added_stages[gress] = pipelength(gress) - TARGET::MAU_BASE_DELAY;
        if (stageno > 0 && stage_dep[gress] == MATCH_DEP)
            regs.dp.match_ie_input_mux_sel |= 1 << gress;
    }

    for (gress_t gress : Range(INGRESS, EGRESS)) {
      if (stageno == 0) {
        /* Credit is set to 2 - Every 512 cycles the credit is reset and every
         * bubble request decrements this credit. Acts like a filter to cap bubble
         * requests */
        adrdist.bubble_req_ctl[gress].bubble_req_fltr_crd = 0x2;
        adrdist.bubble_req_ctl[gress].bubble_req_fltr_en = 0x1;
      }
      adrdist.bubble_req_ctl[gress].bubble_req_interval = 0x100;
      adrdist.bubble_req_ctl[gress].bubble_req_en = 0x1;
      adrdist.bubble_req_ctl[gress].bubble_req_interval_eop = 0x100;
      adrdist.bubble_req_ctl[gress].bubble_req_en_eop = 0x1;
      adrdist.bubble_req_ctl[gress].bubble_req_ext_fltr_en = 0x1;
    }

    /* FIXME -- need to set based on interstage dependencies */
    regs.dp.phv_fifo_enable.phv_fifo_ingress_action_output_enable = stage_dep[INGRESS] != ACTION_DEP;
    regs.dp.phv_fifo_enable.phv_fifo_egress_action_output_enable = stage_dep[EGRESS] != ACTION_DEP;
    if (stageno != AsmStage::numstages()-1) {
        regs.dp.phv_fifo_enable.phv_fifo_ingress_final_output_enable =
            this[1].stage_dep[INGRESS] == ACTION_DEP;
        regs.dp.phv_fifo_enable.phv_fifo_egress_final_output_enable =
            this[1].stage_dep[EGRESS] == ACTION_DEP; }
    for (gress_t gress : Range(INGRESS, EGRESS))
        if (table_use[gress] & USE_TCAM_PIPED)
            regs.tcams.tcam_piped |=  options.match_compiler ? 3 : 1 << gress;

    /* Error handling related */
    for (gress_t gress : Range(INGRESS, EGRESS)) {
        int err_delay = tcam_delay(gress) ? 1 : 0;
        switch (error_mode[gress]) {
        case NO_CONFIG:
            break;
        case PROPAGATE:
            merge.tcam_match_error_ctl[gress].tcam_match_error_ctl_o_err_en = 1;
            merge.tind_ecc_error_ctl[gress].tind_ecc_error_ctl_o_err_en = 1;
            merge.gfm_parity_error_ctl[gress].gfm_parity_error_ctl_o_err_en = 1;
            merge.emm_ecc_error_ctl[gress].emm_ecc_error_ctl_o_err_en = 1;
            merge.gfm_parity_error_ctl[gress].gfm_parity_error_ctl_delay = err_delay;
            merge.emm_ecc_error_ctl[gress].emm_ecc_error_ctl_delay = err_delay;
            break;
        case MAP_TO_IMMEDIATE:
            merge.tcam_match_error_ctl[gress].tcam_match_error_ctl_idata_ovr = 1;
            merge.tind_ecc_error_ctl[gress].tind_ecc_error_ctl_idata_ovr = 1;
            merge.gfm_parity_error_ctl[gress].gfm_parity_error_ctl_idata_ovr = 1;
            merge.emm_ecc_error_ctl[gress].emm_ecc_error_ctl_idata_ovr = 1;
            merge.gfm_parity_error_ctl[gress].gfm_parity_error_ctl_delay = err_delay;
            merge.emm_ecc_error_ctl[gress].emm_ecc_error_ctl_delay = err_delay;
            break;
        case DISABLE_ALL_TABLES:
            merge.tcam_match_error_ctl[gress].tcam_match_error_ctl_dis_pred = 1;
            merge.tind_ecc_error_ctl[gress].tind_ecc_error_ctl_dis_pred = 1;
            merge.gfm_parity_error_ctl[gress].gfm_parity_error_ctl_dis_pred = 1;
            merge.emm_ecc_error_ctl[gress].emm_ecc_error_ctl_dis_pred = 1;
            merge.gfm_parity_error_ctl[gress].gfm_parity_error_ctl_delay = err_delay;
            merge.emm_ecc_error_ctl[gress].emm_ecc_error_ctl_delay = err_delay;
            break;
        default:
            assert(false); } }

    /*--------------------
    * Since a stats ALU enable bit is missing from mau_cfg_stats_alu_lt, need to make sure that for
    * unused stats ALUs, they are programmed to point to a logical table that is either unused or
    * to one that does not use a stats table. */

    bool unused_stats_alus = false;
    for (auto &salu : regs.cfg_regs.mau_cfg_stats_alu_lt)
        if (!salu.modified())
            unused_stats_alus = true;
    if (unused_stats_alus) {
        unsigned avail = 0xffff;
        int no_stats = -1;
        /* odd pattern of tests to replicate what the old compiler does */
        for (auto tbl : tables) {
            avail &= ~(1U << tbl->logical_id);
            if (no_stats < 0 && (!tbl->get_attached() || tbl->get_attached()->stats.empty()))
                no_stats = tbl->logical_id; }
        if (avail) {
            for (int i = 15; i >= 0; --i)
                if ((avail >> i) & 1) {
                    no_stats = i;
                    break; } }
        for (auto &salu : regs.cfg_regs.mau_cfg_stats_alu_lt)
            if (!salu.modified())
                salu = no_stats; }
}

template<class TARGET>
void Stage::output(json::map &ctxt_json) {
    auto *regs = new typename TARGET::mau_regs();
    declare_registers(regs, stageno);
    json::map &names = TopLevel::all->name_lookup["stages"][std::to_string(stageno)];
    Phv::output_names(names["containers"]);
    json::map &table_names = names["logical_tables"];
    for (auto table : tables) {
        table->write_regs(*regs);
        table->gen_tbl_cfg(ctxt_json["tables"]);
        if (table->logical_id >= 0)
            table->gen_name_lookup(table_names[std::to_string(table->logical_id)]); }
    write_regs(*regs);
    if (options.condense_json) {
        regs->disable_if_reset_value();
        // if any part of the gf matrix is enabled, we can't elide any part of it when
        // generating .cfg.json, as otherwise walle will generate an invalid block write
        if (options.gen_json && !regs->dp.xbar_hash.hash.galois_field_matrix.disabled())
            regs->dp.xbar_hash.hash.galois_field_matrix.enable(); }
    // Enable mapram_config and imem regs -
    // These are cached by the driver, so if they are disabled they wont go
    // into tofino.bin as dma block writes and driver will complain
    // The driver needs the regs to do parity error correction at runtime and it
    // checks for the base address of the register blocks to do a block DMA
    // during tofino.bin download
    regs->dp.imem.enable();
    for(int row = 0; row < SRAM_ROWS; row++)
        for(int col = 0; col < MAPRAM_UNITS_PER_ROW; col++)
            regs->rams.map_alu.row[row].adrmux.mapram_config[col].enable();
    if (error_count == 0 && options.gen_json)
        regs->emit_json(*open_output("regs.match_action_stage.%02x.cfg.json", stageno) , stageno);
    char buf[64];
    sprintf(buf, "regs.match_action_stage.%02x", stageno);
    if (stageno < Target::NUM_MAU_STAGES())
        TopLevel::all->set_mau_stage(stageno, buf, regs);
    gen_stage_dependency(*regs, ctxt_json["stage_dependency"]);
    gen_configuration_cache(*regs, ctxt_json["configuration_cache"]);
}

template<class REGS>
void Stage::gen_stage_dependency(REGS &regs, json::vector &stg_dependency) {
    for (gress_t gress : Range(INGRESS, EGRESS)) {
        json::map anon;
        anon["stage"] = stageno;
        anon["gress"] = (gress == INGRESS) ? "ingress" : "egress";
        anon["match_dependent"] = (regs.dp.cur_stage_dependency_on_prev[gress] == 0)
                                       ? true : false;
        stg_dependency.push_back(std::move(anon));
    }
}

template<class REGS>
void Stage::gen_configuration_cache(REGS &regs, json::vector &cfg_cache) {
    std::string reg_fqname;
    std::string reg_name;
    unsigned reg_value;
    std::string reg_value_str;
    unsigned reg_width = 8;

    // meter_sweep_ctl
    auto &meter_sweep_ctl = regs.rams.match.adrdist.meter_sweep_ctl;
    for (int i = 0; i < 4; i++) {
        reg_fqname = "mau[" + std::to_string(stageno)
            + "].rams.match.adrdist.meter_sweep_ctl["
            + std::to_string(i) + "]";
        if (options.match_compiler) { //FIXME: Temp fix to match glass typo
            reg_fqname = "mau[" + std::to_string(stageno)
                + "].rams.match.adrdist.meter_sweep_ctl.meter_sweep_ctl["
                + std::to_string(i) + "]"; }
        reg_name = "stage_" + std::to_string(stageno) + "_meter_sweep_ctl_" + std::to_string(i);
        reg_value = (meter_sweep_ctl[i].meter_sweep_en              & 0x00000001)
                 | ((meter_sweep_ctl[i].meter_sweep_offset          & 0x0000003F) << 1)
                 | ((meter_sweep_ctl[i].meter_sweep_size            & 0x0000003F) << 7)
                 | ((meter_sweep_ctl[i].meter_sweep_remove_hole_pos & 0x00000003) << 13)
                 | ((meter_sweep_ctl[i].meter_sweep_remove_hole_en  & 0x00000001) << 16)
                 | ((meter_sweep_ctl[i].meter_sweep_interval        & 0x0000001F) << 17);
        if ((reg_value != 0) || (options.match_compiler)) {
            reg_value_str = int_to_hex_string(reg_value, reg_width);
            add_cfg_reg(cfg_cache, reg_fqname, reg_name, reg_value_str); } }

    // match_input_xbar_din_power_ctl
    auto &mixdpctl = regs.dp.match_input_xbar_din_power_ctl;
    reg_value_str = "";
    for (int i = 0; i < 2; i++) {
        for (int j = 0; j < 16; j++) {
            reg_value = mixdpctl[i][j];
            reg_value_str = reg_value_str +
                int_to_hex_string(reg_value, reg_width); } }
     if (!check_zero_string(reg_value_str) || options.match_compiler) {
         reg_fqname = "mau[" + std::to_string(stageno)
             + "].dp.match_input_xbar_din_power_ctl";
         reg_name = "stage_" + std::to_string(stageno)
             + "_match_input_xbar_din_power_ctl";
         add_cfg_reg(cfg_cache, reg_fqname, reg_name, reg_value_str); }

    // hash_seed
    auto &hash_seed = regs.dp.xbar_hash.hash.hash_seed;
    reg_value_str = "";
    for (int i = 0; i < 52; i++) {
       reg_value = hash_seed[i];
       reg_value_str = reg_value_str +
           int_to_hex_string(reg_value, reg_width); }
    if (!check_zero_string(reg_value_str) || options.match_compiler) {
        reg_fqname = "mau[" + std::to_string(stageno)
            + "].dp.xbar_hash.hash.hash_seed";
        reg_name = "stage_" + std::to_string(stageno) + "_hash_seed";
        add_cfg_reg(cfg_cache, reg_fqname, reg_name, reg_value_str); }

    // parity_group_mask
    auto &parity_group_mask = regs.dp.xbar_hash.hash.parity_group_mask;
    reg_value_str = "";
    for (int i = 0; i < 8; i++) {
        for (int j = 0; j < 2; j++) {
            reg_value = parity_group_mask[i][j];
            reg_value_str = reg_value_str +
                int_to_hex_string(reg_value, reg_width); } }
    if (!check_zero_string(reg_value_str) || options.match_compiler) {
        reg_fqname = "mau[" + std::to_string(stageno)
            + "].dp.xbar_hash.hash.parity_group_mask";
        reg_name = "stage_" + std::to_string(stageno) + "_parity_group_mask";
        add_cfg_reg(cfg_cache, reg_fqname, reg_name, reg_value_str); }
}
