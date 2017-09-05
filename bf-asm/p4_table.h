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
    static const char *type_name[];
    std::map<std::string, unsigned> action_handles;
private:
    static std::map<unsigned, P4Table *>                        by_handle;
    static std::map<type, std::map<std::string, P4Table *>>     by_name;
    static unsigned                             max_handle[];
public:
    static P4Table *get(type t, VECTOR(pair_t) &d);
    static P4Table *alloc(type t, Table *tbl);
    void check(Table *tbl);
    const char *p4_name() { return name.empty() ? 0 : name.c_str(); }
    unsigned get_handle() { return handle; }
    json::map *base_tbl_cfg(json::vector &out, int size, Table *tbl);
};

#endif /* _p4_table_h_ */
