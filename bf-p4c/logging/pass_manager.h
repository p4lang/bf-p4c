#ifndef _EXTENSIONS_BF_P4C_LOGGING_PASS_MANAGER_H_
#define _EXTENSIONS_BF_P4C_LOGGING_PASS_MANAGER_H_

#include "ir/ir.h"
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
 protected:
    cstring            _logFilePrefix;
    Logging::Mode      _logMode;
    Logging::FileLog * _logFile;

    /// Used to index logfiles based on how many times this class
    /// was instantiated and invoked on pipe nodes (when logMode is CREATE)
    static int         invocationCount;

 public:
    explicit PassManager(cstring logFilePrefix,
                         Logging::Mode logMode = Logging::Mode::CREATE) :
        _logFilePrefix(logFilePrefix), _logMode(logMode), _logFile(nullptr) {}

    static cstring getNewLogFileName(const cstring &prefix) {
        return prefix + std::to_string(invocationCount) + ".log";
    }

 protected:
    profile_t init_apply(const IR::Node *root) override {
        if (BackendOptions().verbose == 0) {
            return ::PassManager::init_apply(root);
        }

        auto pipe = root->to<IR::BFN::Pipe>();
        if (pipe) {
            if (_logMode == Logging::Mode::CREATE) {
                ++invocationCount;
                auto logFileName = getNewLogFileName(_logFilePrefix);
                _logFile = new Logging::FileLog(pipe->id, logFileName, _logMode);
            } else {
                _logFile = new Logging::FileLog(pipe->id, _logFilePrefix + ".log", _logMode);
            }
        }

        return ::PassManager::init_apply(root);
    }

    void end_apply() override {
        Logging::FileLog::close(_logFile);
        ::PassManager::end_apply();
    }
};
}  // end namespace Logging

#endif  // _EXTENSIONS_BF_P4C_LOGGING_PASS_MANAGER_H_
