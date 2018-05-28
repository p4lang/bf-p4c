#ifndef _EXTENSIONS_BF_P4C_LOGGING_LOGGING_H_
#define _EXTENSIONS_BF_P4C_LOGGING_LOGGING_H_

#include <rapidjson/document.h>
#include <rapidjson/prettywriter.h>
#include <cstdarg>
#include <fstream>

#include "common/run_id.h"

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
        writer.StartObject();
        writer.Key("run_id");
        writer.String(RunId::getId().c_str());
        writer.EndObject();
        serialize(writer);
        _logFile << sb.GetString();
    }
};
};  // end namespace Logging

#endif  /* _EXTENSIONS_BF_P4C_LOGGING_LOGGING_H_ */
