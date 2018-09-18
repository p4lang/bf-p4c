#ifndef _EXTENSIONS_BF_P4C_COMMON_RUN_ID_H_
#define _EXTENSIONS_BF_P4C_COMMON_RUN_ID_H_

#include <string>

class RunId {
 public:
    static const std::string &getId() {
        static RunId instance;
        return instance._runId;
    }

 private:
    std::string _runId;
    RunId();

 public:
    // disable any other constructors
    RunId(RunId const&)           = delete;
    void operator=(RunId const&)  = delete;
};

#endif  /* _EXTENSIONS_BF_P4C_COMMON_RUN_ID_H_ */
