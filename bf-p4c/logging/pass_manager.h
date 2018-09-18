#ifndef _EXTENSIONS_BF_P4C_LOGGING_PASS_MANAGER_H_
#define _EXTENSIONS_BF_P4C_LOGGING_PASS_MANAGER_H_

#include "ir/pass_manager.h"
#include "lib/cstring.h"
#include "bf-p4c/bf-p4c-options.h"
#include "bf-p4c/logging/filelog.h"

namespace Logging {

/// A Logging::PassManager is a wrapper around the base pass manager
/// that adds logging capabilities to a file. It's a common enough
/// pattern that we chose to encapsulate it into a class. Logging is
/// done using a FileLog object, which essentially redirects clog to
/// the opened file. The Logging::PassManager manages the logging
/// file, opening it in init_apply and closing it in end_apply.
class PassManager : public ::PassManager {
    cstring            _logFilePrefix;
    bool               _appendToLog;
    Logging::FileLog * _logFile;

 public:
    explicit PassManager(cstring logFilePrefix, bool append = false) :
        _logFilePrefix(logFilePrefix), _appendToLog(append), _logFile(nullptr) {}

 protected:
    profile_t init_apply(const IR::Node *root) override {
        if (BFNContext::get().options().verbose == 0)
            return ::PassManager::init_apply(root);

        static int invocation = 0;
        if (_logFilePrefix == "parser") {
            // parser logging is called from functions, inspectors and pass managers ...
            // so invocations is useless, it just ends up generating a slew of logs
            _logFile = new Logging::FileLog(_logFilePrefix + ".log", _appendToLog);
        } else {
            _logFile = new Logging::FileLog(_logFilePrefix + std::to_string(invocation) + ".log",
                                            _appendToLog);
            if (!_appendToLog) ++invocation;
        }
        return ::PassManager::init_apply(root);
    }

    void end_apply() override {
        if (_logFile != nullptr) {
            delete _logFile;
            _logFile = nullptr;
        }
        ::PassManager::end_apply();
    }
};
}  // end namespace Logging

#endif  // _EXTENSIONS_BF_P4C_LOGGING_PASS_MANAGER_H_
