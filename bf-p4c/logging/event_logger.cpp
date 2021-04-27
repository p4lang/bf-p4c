#include "event_logger.h"
#include <spdlog/spdlog.h>
#include <spdlog/sinks/basic_file_sink.h>
#include <spdlog/sinks/null_sink.h>
#include <rapidjson/prettywriter.h>
#include <ctime>

#include "event_log_schema.h"
#include "rapidjson_adapter.h"

#ifndef EVENT_LOG_SCHEMA_VERSION
#error "event_logger.cpp: EVENT_LOG_SCHEMA_VERSION is not defined!"
#endif

using Schema = Logging::Event_Log_Schema_Logger;

EventLogger::~EventLogger() {}

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

void EventLogger::nullInit() {
    // Unless explicitly initialized via init(), logs to null sink
    auto logger = spdlog::create<spdlog::sinks::null_sink_st>("null_logger");
    spdlog::set_default_logger(logger);
}

EventLogger::EventLogger() {
    nullInit();
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

template<typename T>
inline void EventLogger::logSink(const T *obj) {
    rapidjson::StringBuffer sb;
    Logging::PlainWriterAdapter writerAdapter(sb);
    obj->serialize(writerAdapter);

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
    logSink(ls);
}

void EventLogger::passChange(const std::string &manager, const std::string &pass, unsigned seq) {
    if (manager == lastManager && pass == lastPass && seq == lastSeq) return;
    lastManager = manager;
    lastPass = pass;
    lastSeq = seq;

    auto pc = new Schema::EventPassChanged(manager, pass, seq, getCurrentTimestamp());
    logSink(pc);
}

void EventLogger::parserError(const std::string &message, const Util::SourceInfo &info) {
    auto src = getSourceInfo(info);
    auto pe = new Schema::EventParserError(message, src, getCurrentTimestamp());
    logSink(pe);
}

void EventLogger::error(const std::string &message, const std::string &type,
                        const Util::SourceInfo *info) {
    auto src = info ? getSourceInfo(*info) : nullptr;
    auto ce = new Schema::EventCompilationError(message, getCurrentTimestamp(), src, type);
    logSink(ce);
}

void EventLogger::warning(const std::string &message, const std::string &type,
                          const Util::SourceInfo *info) {
    auto src = info ? getSourceInfo(*info) : nullptr;
    auto cw = new Schema::EventCompilationWarning(message, getCurrentTimestamp(), src, type);
    logSink(cw);
}

void EventLogger::debug(unsigned verbosity, const std::string &file, const std::string &message) {
    getDebugStream(verbosity, file) << message << std::endl;

    auto d = new Schema::EventDebug(file, message, getCurrentTimestamp(), verbosity);
    logSink(d);
}

void EventLogger::decision(unsigned verbosity, const std::string &file,
                           const std::string &description, const std::string &what,
                           const std::string &why) {
    const std::string message = description + ", choosing: " + what + ", because: " + why;
    getDebugStream(verbosity, file) << message << std::endl;

    auto d = new Schema::EventDecision(what, file, description, why,
                                       getCurrentTimestamp(), verbosity);
    logSink(d);
}

void EventLogger::iterationChange(unsigned iteration, AllocPhase phase) {
    auto ic = new Schema::EventIterationChanged(iteration, std::to_string(phase),
                                                getCurrentTimestamp());
    logSink(ic);
}

void EventLogger::pipeChange(int pipeId) {
    auto pps = new Schema::EventPipeProcessingStarted(pipeId, getCurrentTimestamp());
    logSink(pps);
}
