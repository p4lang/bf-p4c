#include "event_logger.h"
#include <spdlog/spdlog.h>
#include <spdlog/sinks/basic_file_sink.h>
#include <spdlog/sinks/null_sink.h>
#include <rapidjson/prettywriter.h>
#include <ctime>
#include "event_log_schema.h"
#include "lib/log.h"

#ifndef EVENT_LOG_SCHEMA_VERSION
#error "event_logger.cpp: EVENT_LOG_SCHEMA_VERSION is not defined!"
#endif

using Writer = rapidjson::Writer<rapidjson::StringBuffer>;
using Schema = Logging::Event_Log_Schema_Logger;

/**
 *  Wrapper for Schema::Event_Base objects
 *  It enables schema header to be included in this file and
 *  not publicly in the header.
 */
class EventBaseWrapper {
    Schema::Event_Base *obj = nullptr;

 public:
    explicit EventBaseWrapper(Schema::Event_Base *base) : obj(base) {}

    void serialize(Writer &writer) const {
        obj->serialize(writer);
    }
};

namespace std {
    string to_string(EventLogger::AllocPhase phase) {
        if (phase == EventLogger::AllocPhase::PhvAllocation) return "phv_allocation";
        else if (phase == EventLogger::AllocPhase::TablePlacement) return "table_placement";
        return "error";
    }
}

static Schema::SourceInfo *getSourceInfo(const Util::SourceInfo &info) {
    return new Schema::SourceInfo(info.column, info.filename.c_str(), info.line);
}

EventLogger::EventLogger() {
    // Unless explicitly initialized via init(), logs to null sink
    auto logger = spdlog::create<spdlog::sinks::null_sink_st>("null_logger");
    spdlog::set_default_logger(logger);
}

void EventLogger::deinit() {
    spdlog::shutdown();
}

std::string EventLogger::getCurrentTimestamp() const {
    return std::to_string(std::time(nullptr));
}

std::ostream &EventLogger::getDebugStream(unsigned level, const std::string &file) const {
    return ::Log::Detail::fileLogOutput(file.c_str())
            << ::Log::Detail::OutputLogPrefix(file.c_str(), level);
}

bool EventLogger::isVerbosityAtLeast(unsigned level, const std::string &file) const {
    return level <= MAX_LOGGING_LEVEL && ::Log::fileLogLevelIsAtLeast(file.c_str(), level);
}

inline void EventLogger::logSink(const EventBaseWrapper &obj) {
    rapidjson::StringBuffer sb;
    Writer writer(sb);
    obj.serialize(writer);

    // Actual logging sink
    spdlog::error(sb.GetString());
}

EventLogger &EventLogger::get() {
    static EventLogger instance;
    return instance;
}

void EventLogger::init(const std::string &OUTDIR, const std::string &FILENAME) {
    constexpr bool TRUNCATE = true;

    /* NOTE: spdlog supports asynchronous loggers, but garbage collection somehow
       frees some resources prematurely, causing it to SIGSEGV. Thus, for now, we
       only use synchronous logger with multithread safety. */
    auto logger = spdlog::basic_logger_mt("logger", OUTDIR + "/" + FILENAME, TRUNCATE);

    /* NOTE: Following command flushes log after every single message so P4I always
       gets valid objects. If this proves to be a bottleneck, we would have to remove
       it and P4I would have to implement some stream parsing solution. */
    logger->flush_on(spdlog::level::err);

    spdlog::set_default_logger(logger);
    spdlog::set_pattern("%v");  // print just the message, no decorations

    logStart();
}

void EventLogger::logStart() {
    auto ls = new Schema::EventLogStart(EVENT_LOG_SCHEMA_VERSION, getCurrentTimestamp());
    logSink(EventBaseWrapper(ls));
}

void EventLogger::passChange(const std::string &manager, const std::string &pass, unsigned seq) {
    if (manager == lastManager && pass == lastPass && seq == lastSeq) return;
    lastManager = manager;
    lastPass = pass;
    lastSeq = seq;

    auto pc = new Schema::EventPassChanged(manager, pass, seq, getCurrentTimestamp());
    logSink(EventBaseWrapper(pc));
}

void EventLogger::parserError(const std::string &message, const Util::SourceInfo &info) {
    auto src = getSourceInfo(info);
    auto pe = new Schema::EventParserError(message, src, getCurrentTimestamp());
    logSink(EventBaseWrapper(pe));
}

void EventLogger::error(const std::string &message, const std::string &type,
                        const Util::SourceInfo *info) {
    auto src = info ? getSourceInfo(*info) : nullptr;
    auto ce = new Schema::EventCompilationError(message, getCurrentTimestamp(), src, type);
    logSink(EventBaseWrapper(ce));
}

void EventLogger::warning(const std::string &message, const std::string &type,
                          const Util::SourceInfo *info) {
    auto src = info ? getSourceInfo(*info) : nullptr;
    auto cw = new Schema::EventCompilationWarning(message, getCurrentTimestamp(), src, type);
    logSink(EventBaseWrapper(cw));
}

void EventLogger::debug(unsigned verbosity, const std::string &file, const std::string &message) {
    if (!isVerbosityAtLeast(verbosity, file)) return;

    getDebugStream(verbosity, file) << message << std::endl;

    auto d = new Schema::EventDebug(file, message, getCurrentTimestamp(), verbosity);
    logSink(EventBaseWrapper(d));
}

void EventLogger::decision(unsigned verbosity, const std::string &file,
                           const std::string &description, const std::string &what,
                           const std::string &why) {
    if (!isVerbosityAtLeast(verbosity, file)) return;

    const std::string message = description + ", choosing: " + what + ", because: " + why;
    getDebugStream(verbosity, file) << message << std::endl;

    auto d = new Schema::EventDecision(what, file, description, why,
                                       getCurrentTimestamp(), verbosity);
    logSink(EventBaseWrapper(d));
}

void EventLogger::iterationChange(unsigned iteration, AllocPhase phase) {
    auto ic = new Schema::EventIterationChanged(iteration, std::to_string(phase),
                                                getCurrentTimestamp());
    logSink(EventBaseWrapper(ic));
}

void EventLogger::pipeChange(int pipeId) {
    auto pps = new Schema::EventPipeProcessingStarted(pipeId, getCurrentTimestamp());
    logSink(EventBaseWrapper(pps));
}
