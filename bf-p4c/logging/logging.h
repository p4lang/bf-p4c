#ifndef _EXTENSIONS_BF_P4C_LOGGING_LOGGING_H_
#define _EXTENSIONS_BF_P4C_LOGGING_LOGGING_H_

#include <string.h>
#include <time.h>
#include <rapidjson/document.h>
#include <rapidjson/prettywriter.h>
#include <cstdarg>
#include <fstream>

#include "bf-p4c/common/run_id.h"
#include "lib/exceptions.h"

namespace Logging {

using Writer = rapidjson::PrettyWriter<rapidjson::StringBuffer>;

/// Define the levels of logging. All messages above the set level for logger are logged.
enum LogLevel_t { LOG, DEBUG, INFO, WARNING, ERROR, CRITICAL };

/// Base class for logging to a file
class Logger : public rapidjson::Document {
 private:
    LogLevel_t       _level;
    std::ofstream    _logFile;

 public:
    explicit Logger(const char *filename, LogLevel_t level = INFO) :
        rapidjson::Document(rapidjson::Type::kObjectType),
        _level(level) { _logFile.open(filename, std::ofstream::out); }
    ~Logger() {
        _logFile.flush();
        _logFile.close();
    }

    void setLevel(LogLevel_t level) { _level = level; }
    virtual void serialize(Writer &) const = 0;
    virtual void log() {
        rapidjson::StringBuffer sb;
        Writer writer(sb);
        serialize(writer);
        _logFile << sb.GetString();
        _logFile.flush();
    }

    static const std::string buildDate(void) {
      const time_t now = time(NULL);
      struct tm tmp;
      BUG_CHECK(localtime_r(&now, &tmp), "Error calling localtime_r: %1%", strerror(errno));

      char bdate[1024];
      strftime(bdate, 1024, "%c", &tmp);
      return bdate;
    }
};
};  // end namespace Logging

#endif  /* _EXTENSIONS_BF_P4C_LOGGING_LOGGING_H_ */
