#ifndef _EXTENSIONS_BF_P4C_LOGGING_FILELOG_H_
#define _EXTENSIONS_BF_P4C_LOGGING_FILELOG_H_

#include <sys/stat.h>
#include <fstream>
#include <streambuf>
#include <string>
#include <utility>

#include "lib/cstring.h"
#include "lib/path.h"
#include "bf-p4c/logging/manifest.h"

namespace Logging {

enum Mode {
    /// Appends to a log. Creates a new log if it doesn't already exist.
    APPEND,

    /// Creates a new log. Overwrites if the log already exists.
    CREATE,

    /// Creates if this is the first time writing to the log; otherwise, appends.
    AUTO
};

/// A FileLog is used to redirect the logging output of a visitor pass to a file.

class FileLog {
 private:
    std::basic_streambuf<char>* clog_buff = nullptr;
    std::ofstream *log;
    static cstring outputDir;

    static cstring name2type(cstring logName) {
        static const std::map<cstring, cstring> logNames2Type = {
            {"bridge_metadata", "parser"},
            {"parser.characterize", "parser"},
            {"parser", "parser"},
            {"phv_allocation", "phv"},
            {"table_", "mau"},
            {"ixbar", "mau"}
        };

        for (auto &logType : logNames2Type)
            if (logName.startsWith(logType.first))
                return logType.second;
        return cstring("Unknown");
    }

    static std::set<cstring> filesWritten;

 public:
    explicit FileLog(int pipe, cstring logName, Mode mode = AUTO) {
        bool append;
        switch (mode) {
        case APPEND: append = true; break;
        case CREATE: append = false; break;
        case AUTO : append = filesWritten.count(logName); break;
        }

        filesWritten.insert(logName);

        auto logDir = BFNContext::get().getOutputDirectory("logs", pipe);
        if (logDir) {
            auto fileName = Util::PathName(logDir).join(logName).toString();
            LOG1("Open logfile " << fileName << " append: " << append);
            if (!append)
                Manifest::getManifest().addLog(pipe, name2type(logName), logName);
            clog_buff = std::clog.rdbuf();
            auto flags = std::ios_base::out;
            if (append) flags |= std::ios_base::app;
            log = new std::ofstream(fileName, flags);
            std::clog.rdbuf(log->rdbuf());
        }
    }

    ~FileLog() {
        close();
    }

    /// Untie the file and close the filestream.
    void close() {
        if (clog_buff != nullptr) {
            std::clog.rdbuf(clog_buff);
        }
        if (log) {
            log->flush(); log->close();
            delete log;
            log = nullptr;
        }
    }

    static void setOutputDir(cstring &outDir) { outputDir = outDir; }
};
}  // end namespace Logging

#endif  /* _EXTENSIONS_BF_P4C_LOGGING_FILELOG_H_ */
