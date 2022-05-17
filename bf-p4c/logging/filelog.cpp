#include "filelog.h"

std::set<cstring> Logging::FileLog::filesWritten;

// static
const cstring& Logging::FileLog::name2type(cstring logName) {
    static const cstring unknown("Unknown");
    static const std::map<cstring, cstring> logNames2Type = {
        {"clot_allocation",             "parser"},
        {"decaf",                       "parser"},
        {"flexible_packing",            "parser"},
        {"ixbar",                       "mau"},
        {"parser.characterize",         "parser"},
        {"parser",                      "parser"},
        {"phv_allocation",              "phv"},
        {"phv_optimization",            "phv"},
        {"phv_incremental_allocation",  "phv"},
        {"phv_trivial_allocation",      "phv"},
        {"phv_greedy_allocation",       "phv"},
        {"table_",                      "mau"},
        {"pragmas",                     "phv"}
    };

    for (auto &logType : logNames2Type)
        if (logName.startsWith(logType.first))
            return logType.second;
    return unknown;
}
