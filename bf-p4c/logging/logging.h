#ifndef _EXTENSIONS_BF_P4C_LOGGING_H_
#define _EXTENSIONS_BF_P4C_LOGGING_H_

#include <cstdarg>
#include <fstream>
#include <rapidjson/document.h>
#include <rapidjson/prettywriter.h>
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
    Logger(const char *filename, LogLevel_t level = INFO) :
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

#if 0
    // \TODO: how do we reconcile these logging functions with the
    // JSON objects?
    void log(const char *format, ...) {
        va_list args;
        va_start(args, format);
        __log(LOG, format, args);
        va_end(args);
    }
    void debug(const char *format, ...) {
        va_list args;
        va_start(args, format);
        __log(DEBUG, format, args);
        va_end(args);
    }
    void info(const char *format, ...)  {
        va_list args;
        va_start(args, format);
        __log(INFO, format, args);
        va_end(args);
    }
    void warning(const char *format, ...) {
        va_list args;
        va_start(args, format);
        __log(WARNING, format, args);
        va_end(args);
    }
    void error(const char *format, ...) {
        va_list args;
        va_start(args, format);
        __log(ERROR, format, args);
        va_end(args);
    }
    void critical(const char *format, ...) {
        va_list args;
        va_start(args, format);
        __log(CRITICAL, format, args);
        va_end(args);
    }
 private:
    virtual void __log(LogLevel_t level, const char *format, va_list args) {
        if (level < _level)
            return;
        vfprintf(_logFile.rdbuf()..., format, args);
    }
#endif // 0
};
};  // end namespace Logging

#endif  // _EXTENSIONS_BF_P4C_LOGGING_H_
