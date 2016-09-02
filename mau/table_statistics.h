#ifndef _TOFINO_MAU_TABLE_STATISTICS_H_
#define _TOFINO_MAU_TABLE_STATISTICS_H_

#include "mau_visitor.h"

struct RamsForKb{
    bool is_ternary = false;
    double match = 0;
    double action = 0;
    double attached = 0;
};

struct MatchTableOption {
    int entries_per_row = 0;
    int table_width = 0;
    bool action_necessary = false;
    double utilization = 0.0;
    int min_mems_used = 0;
    int max_mems_used = 0;
};

struct ActionTableOption {
    int action_bytes = 0;
    int entries_per_row = 0;
    int table_width = 0;
    int min_mems_used = 0;
    double min_utilization = 0;
    int max_mems_used = 0;
    double max_utilization = 0;
};

struct LayoutOption {
    MatchTableOption match;
};

struct MatchGather {
    bool is_ternary = 0;
    int match_bits = false;
    int overhead_bits = 0; 
};

struct PackingOptions {
    MatchGather table_info;
    vector<LayoutOption> packing_structs;
    ActionTableOption action;
};

struct TableStats {

    int sram_tables_count = 0;
    int tcam_tables_count = 0;
   
    int unknown_sram_tables = 0;
    int unknown_tcam_tables = 0;

    int min_srams_known = 0;
    int max_srams_known = 0;

    int min_tcams_known = 0;
    int max_tcams_known = 0;

    int small_sram_tables = 0;

    vector<RamsForKb> ram_calcs;
    map<cstring, PackingOptions> options;
};


class TableStatistics : public MauInspector {
  private:   
    bool preorder(const IR::MAU::Table *) override;
    void end_apply(const IR::Node *) override;

    TableStats &tstats;

  public:
    TableStatistics(TableStats &t) : tstats(t) {};
    
};

#endif
