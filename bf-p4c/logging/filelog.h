/**
 * Copyright (C) 2024 Intel Corporation
 *
 * Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file
 * except in compliance with the License.  You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software distributed under the
 * License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
 * either express or implied.  See the License for the specific language governing permissions
 * and limitations under the License.
 *
 *
 * SPDX-License-Identifier: Apache-2.0
 */

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

/// \enum Mode specifies how the log file is created and/or reused.
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
    std::ofstream *log = nullptr;

    static const cstring& name2type(cstring logName);
    static std::set<cstring> filesWritten;

 public:
    explicit FileLog(int pipe, cstring logName, Mode mode = AUTO) {
        bool append = true;
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
            Manifest::getManifest().addLog(pipe, name2type(logName), logName);
            clog_buff = std::clog.rdbuf();
            auto flags = std::ios_base::out;
            if (append) flags |= std::ios_base::app;
            log = new std::ofstream(fileName, flags);
            std::clog.rdbuf(log->rdbuf());
        }
    }

    /// Closes the log using close
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

    /// Closes a FileLog and cleans up.
    static void close(FileLog*& log) {
        if (!log) return;
        delete log;
        log = nullptr;
    }
};

}  // end namespace Logging

#endif  /* _EXTENSIONS_BF_P4C_LOGGING_FILELOG_H_ */
