#ifndef _p4_table_h_
#define _p4_table_h_

#include "asm-types.h"
#include "json.h"
#include <map>
#include <string>

class Table;

class P4Table {
    int                 lineno = -1;
    std::string         name, preferred_match_type;
    unsigned            handle = 0;
    bool                explicit_size = false;
    json::map           *config = 0;
    P4Table() {}
public:
    unsigned            size = 0;
    std::string         match_type, action_profile = "";
    enum type { MatchEntry=1, ActionData=2, Selection=3, Statistics=4, Meter=5, Stateful=6 };
    enum alpm_type { PreClassifier=1, Atcam=2 };
    static const char *type_name[];
    std::map<std::string, unsigned> action_handles;
private:
    static std::map<unsigned, P4Table *>                        by_handle;
    static std::map<type, std::map<std::string, P4Table *>>     by_name;
    static unsigned                             max_handle[];
    struct alpm_t {
        std::string partition_field_name = "";
        unsigned alpm_atcam_table_handle = 0;
        unsigned alpm_pre_classifier_table_handle = 0;
        unsigned set_partition_action_handle = 0;
        json::map *alpm_atcam_table_cfg = 0; // handle to cjson alpm table
        json::map *alpm_pre_classifier_table_cfg = 0; // handle to cjson ternary pre classifier table
    };
    alpm_t alpm;
public:
    static P4Table *get(type t, VECTOR(pair_t) &d);
    static P4Table *alloc(type t, Table *tbl);
    void check(Table *tbl);
    const char *p4_name() { return name.empty() ? 0 : name.c_str(); }
    unsigned get_handle() { return handle; }
    unsigned p4_size() { return size; }
    json::map *base_tbl_cfg(json::vector &out, int size, Table *table);
    void base_alpm_tbl_cfg(json::map &out, int size, Table *table, P4Table::alpm_type atype);
    bool is_alpm() {
        if (match_type == "alpm") return true;
        return false; }
    void set_partition_action_handle(unsigned handle) {
        alpm.set_partition_action_handle = handle; }
    void set_partition_field_name(std::string name) {
        alpm.partition_field_name = name; }
    std::string get_partition_field_name() {
        return alpm.partition_field_name; }
    unsigned get_partition_action_handle() {
        return alpm.set_partition_action_handle; }
    unsigned get_alpm_atcam_table_handle() {
        return alpm.alpm_atcam_table_handle; }
};

#endif /* _p4_table_h_ */
