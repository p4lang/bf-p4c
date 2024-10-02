#include "filelog.h"

std::set<cstring> Logging::FileLog::filesWritten;

// static
const cstring& Logging::FileLog::name2type(cstring logName) {
    static const cstring unknown("Unknown");
    static const std::map<cstring, cstring> logNames2Type = {
        {"clot_allocation"_cs,             "parser"_cs},
        {"decaf"_cs,                       "parser"_cs},
        {"flexible_packing"_cs,            "parser"_cs},
        {"ixbar"_cs,                       "mau"_cs},
        {"parser.characterize"_cs,         "parser"_cs},
        {"parser"_cs,                      "parser"_cs},
        {"phv_allocation"_cs,              "phv"_cs},
        {"phv_optimization"_cs,            "phv"_cs},
        {"phv_incremental_allocation"_cs,  "phv"_cs},
        {"phv_trivial_allocation"_cs,      "phv"_cs},
        {"phv_greedy_allocation"_cs,       "phv"_cs},
        {"table_"_cs,                      "mau"_cs},
        {"pragmas"_cs,                     "phv"_cs},
        {"live_range_split"_cs,            "phv"_cs},
        {"backend_passes"_cs,              "text"_cs}
    };

    for (auto &logType : logNames2Type)
        if (logName.startsWith(logType.first.string_view()))
            return logType.second;
    return unknown;
}
