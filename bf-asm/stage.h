#ifndef BF_ASM_STAGE_H_
#define BF_ASM_STAGE_H_

#include <fstream>
#include <vector>

#include "tables.h"
#include "bitvec.h"
#include "input_xbar.h"
#include "bf-p4c/common/alloc.h"

class AsmStage : public Section {
    void start(int lineno, VECTOR(value_t) args);
    void input(VECTOR(value_t) args, value_t data);
    void process();
    void output(json::map &);

    /// Propagates group_table_use to adjacent stages that are not match-dependent.
    void propagate_group_table_use();

    unsigned compute_latency(gress_t gress);
    AsmStage();
    ~AsmStage() {}
    std::vector<Stage>  pipe;
#if HAVE_FLATROCK
    std::vector<Stage>  epipe;   // for separate egress pipe
#endif
    static AsmStage     singleton_object;
    bitvec              stages_seen[NUM_GRESS_T];

 public:
    static int numstages() { return singleton_object.pipe.size(); }
    static std::vector<Stage> &stages(gress_t gress) {
#if HAVE_FLATROCK
        if (gress == EGRESS && Target::EGRESS_SEPARATE())
            return singleton_object.epipe;
#endif
        return singleton_object.pipe; }
};

class Stage_data {
    /* we encapsulate all the Stage non-static fields in a base class to automate the
     * generation of the move construtor properly */
 public:
    int                         stageno;
    std::vector<Table *>        tables;
    std::set<Stage **>          all_refs;
    BFN::Alloc2Dbase<Table *>                                sram_use;
    BFN::Alloc2D<Table *, SRAM_ROWS, 2>                      sram_search_bus_use;
    BFN::Alloc2D<Table *, SRAM_ROWS, 2>                      match_result_bus_use;
    BFN::Alloc2D<Table *, SRAM_ROWS, MAPRAM_UNITS_PER_ROW>   mapram_use;
    BFN::Alloc2Dbase<Table *>                                tcam_use;
    BFN::Alloc2D<Table *, TCAM_ROWS, 2>                      tcam_match_bus_use;
    BFN::Alloc2D<std::pair<Table *, int>, TCAM_ROWS, 2>      tcam_byte_group_use;
    BFN::Alloc2D<Table *, SRAM_ROWS, 2>                      tcam_indirect_bus_use;
    BFN::Alloc2D<GatewayTable *, SRAM_ROWS, 2>               gw_unit_use;
    BFN::Alloc2D<GatewayTable *, SRAM_ROWS, 2>               gw_payload_use;
    BFN::Alloc1D<Table *, LOGICAL_TABLES_PER_STAGE>          logical_id_use;
    BFN::Alloc1D<Table *, PHYSICAL_TABLES_PER_STAGE>         physical_id_use;
    BFN::Alloc1D<Table *, TCAM_TABLES_PER_STAGE>             tcam_id_use;
    ordered_map<InputXbar::Group, std::vector<InputXbar *>>  ixbar_use;
    BFN::Alloc1D<Table *, TCAM_XBAR_INPUT_BYTES>             tcam_ixbar_input;
    BFN::Alloc1D<std::vector<InputXbar *>, HASH_TABLES>      hash_table_use;
    BFN::Alloc1D<std::vector<InputXbar *>, EXACT_HASH_GROUPS>hash_group_use;
    BFN::Alloc1D<std::vector<HashDistribution *>, 6>         hash_dist_use;
    BFN::Alloc1D<Table *, ACTION_DATA_BUS_SLOTS>             action_bus_use;
    BFN::Alloc1D<Table *, LOGICAL_SRAM_ROWS>                 action_data_use,
                                                             meter_bus_use,
                                                             stats_bus_use,
                                                             selector_adr_bus_use,
                                                             overflow_bus_use;
    BFN::Alloc1D<Table *, IDLETIME_BUSSES>                   idletime_bus_use;
    bitvec      action_bus_use_bit_mask;
    BFN::Alloc2D<Table::Actions::Action *, 2, ACTION_IMEM_ADDR_MAX> imem_addr_use;
    bitvec      imem_use[ACTION_IMEM_SLOTS];
    BFN::Alloc1D<Table::NextTables *, MAX_LONGBRANCH_TAGS>  long_branch_use;
    unsigned                                                long_branch_thread[3] = { 0 };
    unsigned                                                long_branch_terminate = 0;

    // for timing, ghost thread is tied to ingress, so we track ghost as ingress here
    enum { USE_TCAM = 1, USE_STATEFUL = 4, USE_METER = 8, USE_METER_LPF_RED = 16,
           USE_SELECTOR = 32, USE_WIDE_SELECTOR = 64, USE_STATEFUL_DIVIDE = 128 };
    int /* enum */      table_use[2], group_table_use[2];

    enum { NONE = 0, CONCURRENT = 1, ACTION_DEP = 2, MATCH_DEP = 3 } stage_dep[2];
    bitvec              match_use[3], action_use[3], action_set[3];

    // there's no error mode registers for ghost thread, so we don't allow it to be set
    enum { NO_CONFIG = 0, PROPAGATE, MAP_TO_IMMEDIATE, DISABLE_ALL_TABLES }
                        error_mode[2];

    // MPR stage config
    int mpr_stage_id[3] = { 0 };  // per-gress
    int mpr_always_run = 0;
    int mpr_bus_dep_glob_exec[3] = { 0 };
    int mpr_bus_dep_long_branch[3] = { 0 };
    // per gress, per logical table
    BFN::Alloc2D<int, 3, LOGICAL_TABLES_PER_STAGE> mpr_next_table_lut;
    // per global execute bit
    BFN::Alloc1D<int, LOGICAL_TABLES_PER_STAGE> mpr_glob_exec_lut;
    // per long branch tag
    BFN::Alloc1D<int, MAX_LONGBRANCH_TAGS> mpr_long_brch_lut;

    // When TCAMs are shared between separate ingress and egress Stage objects, this points
    // at the ingress stage that shares with a given egress stage
    Stage *shared_tcam_stage = nullptr;

    int pass1_logical_id = -1, pass1_tcam_id = -1;

    // True egress accounting (4 buses) Tofino2/3 ONLY
    static std::map<int, std::pair<bool, int>> teop;

 protected:
    Stage_data(int stage, bool egress_only) : stageno(stage),
        sram_use(Target::SRAM_ROWS(egress_only ? EGRESS : INGRESS), Target::SRAM_UNITS_PER_ROW()),
        tcam_use(Target::TCAM_ROWS(), Target::TCAM_UNITS_PER_ROW())
        {}
    Stage_data(const Stage_data &) = delete;
    Stage_data(Stage_data &&) = default;
    ~Stage_data() {}
};

class Stage : public Stage_data {
 public:
    static unsigned char action_bus_slot_map[ACTION_DATA_BUS_BYTES];
    static unsigned char action_bus_slot_size[ACTION_DATA_BUS_SLOTS];  // size in bits

    explicit Stage(int stageno, bool egress_only);
    Stage(const Stage &) = delete;
    Stage(Stage &&);
    ~Stage();
    template<class TARGET> void output(json::map &ctxt_json, bool egress_only = false);
    template<class REGS> void fixup_regs(REGS &regs);
    template<class REGS>
        void gen_configuration_cache_common(REGS &regs, json::vector &cfg_cache);
    template<class REGS>
        void gen_configuration_cache(REGS &regs, json::vector &cfg_cache);
    template<class REGS>
        void gen_gfm_json_info(REGS &regs, std::ostream &out);
    template<class REGS>
        void gen_mau_stage_characteristics(REGS &regs, json::vector &stg_characteristics);
    template<class REGS>
        void gen_mau_stage_extension(REGS &regs, json::map &extend);
    template<class REGS> void write_regs(REGS &regs, bool egress_only);
    template<class TARGET> void write_common_regs(typename TARGET::mau_regs &regs);
    template<class REGS> void write_teop_regs(REGS &regs);
    int adr_dist_delay(gress_t gress);
    int pipelength(gress_t gress);
    int pred_cycle(gress_t gress);
    int tcam_delay(gress_t gress);
    int cycles_contribute_to_latency(gress_t gress);
    void verify_have_mpr(std::string key, int line_number);
    static int first_table(gress_t gress);
    static unsigned end_of_pipe() { return Target::END_OF_PIPE(); }
    static Stage *stage(gress_t gress, int stageno);
    void log_hashes(std::ofstream& out) const;
    bitvec imem_use_all() const;
};

#endif /* BF_ASM_STAGE_H_ */
