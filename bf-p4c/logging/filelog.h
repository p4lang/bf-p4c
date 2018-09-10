#ifndef _EXTENSIONS_BF_P4C_LOGGING_FILELOG_H_
#define _EXTENSIONS_BF_P4C_LOGGING_FILELOG_H_

#include <sys/stat.h>
#include <fstream>
#include <streambuf>
#include <string>
#include <utility>

#include "lib/cstring.h"
#include "lib/path.h"

namespace Logging {

/// A FileLog is used to redirect the logging output of a visitor pass to a file.

class FileLog {
 private:
    std::basic_streambuf<char>* clog_buff = nullptr;
    std::ofstream *log;
    static cstring outputDir;

 public:
    explicit FileLog(cstring logName) {
        auto logDir = Util::PathName(outputDir).join("logs").toString();
        int rc = mkdir(logDir.c_str(), 0755);
        if (rc != 0 && errno != EEXIST) {
            std::cerr << "Failed to create directory: " << logDir << std::endl;
        } else {
            auto fileName = Util::PathName(logDir).join(logName).toString();
            clog_buff = std::clog.rdbuf();
            log = new std::ofstream(fileName, std::ios_base::out);
            std::clog.rdbuf(log->rdbuf());
        }
    }

    ~FileLog() {
        if (clog_buff != nullptr) {
            std::clog.rdbuf(clog_buff);  // Untie clog from the logging file
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
