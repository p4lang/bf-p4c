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

/**
 *  Enum for logging type of each event.
 */
enum class EventType : int {
    Properties = 0, PassChange, ParseError, Error, Warning,
    Debug, Decision, PipeChange, IterationChange,
};

/**
 *  Map of event type enum to string description
 *
 *  This map is emmited as a part of EventType::Start
 */
static const std::map<EventType, std::string> EVENT_ENUM_MAP = {
    { EventType::Properties, "Properties" },
    { EventType::ParseError, "Parse Error" },
    { EventType::Error, "Compilation Error" },
    { EventType::Warning, "Compilation Warning" },
    { EventType::PassChange, "Pass Changed" },
    { EventType::PipeChange, "Pipe Changed" },
    { EventType::IterationChange, "Iteration Changed" },
    { EventType::Debug, "Debug" },
    { EventType::Decision, "Decision"}
};

namespace std {
    string to_string(EventLogger::AllocPhase phase) {
        if (phase == EventLogger::AllocPhase::PhvAllocation) return "phv_allocation";
        else if (phase == EventLogger::AllocPhase::TablePlacement) return "table_placement";
        return "error";
    }
}

using Schema = Logging::Event_Log_Schema_Logger;

static Schema::SourceInfo *getSourceInfo(unsigned fileId, const Util::SourceInfo &info) {
    return new Schema::SourceInfo(info.column, fileId, info.line);
}

/* (de)construction */

EventLogger::EventLogger() {
    nullInit();
}

EventLogger::~EventLogger() {
    deinit();
}

EventLogger &EventLogger::get() {
    static EventLogger instance;
    return instance;
}

/* Helpers */
static int getId(const std::string &key, int &id, std::map<std::string, int> &lookup,
                 std::vector<std::string> &list) {
    if (lookup.count(key) == 0) {
        lookup[key] = id++;
        list.push_back(key);
    }
    return lookup.at(key);
}

int EventLogger::getManagerId(const std::string &name) {
    return getId(name, managerId, managerNameToIds, managerNames);
}

int EventLogger::getFileNameId(const std::string &name) {
    return getId(name, fileId, fileNameToIds, fileNames);
}

int EventLogger::getTimeDifference() const {
    return int(std::time(nullptr) - BEGIN_TIME);
}

std::string EventLogger::getStartTimestamp() const {
    return std::to_string(BEGIN_TIME);
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

/* Setup & Cleanups */

void EventLogger::nullInit() {
    // Unless explicitly initialized via init(), logs to null sink
    auto logger = spdlog::create<spdlog::sinks::null_sink_st>("null_logger");
    spdlog::set_default_logger(logger);
}

void EventLogger::init(const std::string &OUTDIR, const std::string &FILENAME) {
    constexpr bool TRUNCATE = true;

    /* NOTE: spdlog supports asynchronous loggers, but garbage collection somehow
       frees some resources prematurely, causing it to SIGSEGV. Thus, for now, we
       only use synchronous logger with multithread safety. */
    auto logger = spdlog::basic_logger_mt("logger", OUTDIR + "/" + FILENAME, TRUNCATE);

    spdlog::set_default_logger(logger);
    spdlog::set_pattern("%v");  // print just the message, no decorations

    initialized = true;
}

void EventLogger::logProperties() {
    const int id = int(EventType::Properties);
    const auto timestamp = getStartTimestamp();

    std::vector<std::string> eventNames;
    for (auto &kv : EVENT_ENUM_MAP) eventNames.push_back(kv.second);

    auto ls = new Schema::EventLoggerProperties(
        enabled, eventNames, fileNames, id, managerNames, EVENT_LOG_SCHEMA_VERSION, timestamp);
    logSink(ls);  // emit properties
}

void EventLogger::deinit() {
    if (initialized) {
        logProperties();
    }

    spdlog::shutdown();

    // Restore all auxiliary variables to defaults for testing purposes
    fileId = 0;
    managerId = 0;
    managerNameToIds.clear();
    managerNames.clear();
    fileNameToIds.clear();
    fileNames.clear();
    lastManager = "";
    lastPass = "";
    lastSeq = 0;

    initialized = false;
    enabled = false;
}



/* Event serializations */

void EventLogger::passChange(const std::string &manager, const std::string &pass, unsigned seq) {
    if (!enabled) return;
    if (manager == lastManager && pass == lastPass && seq == lastSeq) return;
    lastManager = manager;
    lastPass = pass;
    lastSeq = seq;

    const int id = int(EventType::PassChange);
    const int mgr = getManagerId(manager);

    auto pc = new Schema::EventPassChanged(id, mgr, pass, seq, getTimeDifference());
    logSink(pc);
    delete pc;  // GC seems to fail to collect on this pointer
}

void EventLogger::parserError(const std::string &message, const Util::SourceInfo &info) {
    if (!enabled) return;
    const int id = int(EventType::ParseError);
    auto src = getSourceInfo(getFileNameId(info.filename.c_str()), info);
    auto pe = new Schema::EventParserError(id, message, src, getTimeDifference());
    logSink(pe);
    delete pe;  // GC seems to fail to collect on this pointer
}

void EventLogger::error(const std::string &message, const std::string &type,
                        const Util::SourceInfo *info) {
    if (!enabled) return;
    const int id = int(EventType::Error);
    auto src = info ? getSourceInfo(getFileNameId(info->filename.c_str()), *info) : nullptr;
    auto ce = new Schema::EventCompilationError(id, message, getTimeDifference(), type, src);
    logSink(ce);
    delete ce;  // GC seems to fail to collect on this pointer
}

void EventLogger::warning(const std::string &message, const std::string &type,
                          const Util::SourceInfo *info) {
    if (!enabled) return;
    const int id = int(EventType::Warning);
    auto src = info ? getSourceInfo(getFileNameId(info->filename.c_str()), *info) : nullptr;
    auto cw = new Schema::EventCompilationWarning(id, message, getTimeDifference(), type, src);
    logSink(cw);
    delete cw;  // GC seems to fail to collect on this pointer
}

void EventLogger::debug(unsigned verbosity, const std::string &file, const std::string &message) {
    getDebugStream(verbosity, file) << message << std::endl;

    if (!enabled) return;
    const int id = int(EventType::Debug);
    const int fileId = getFileNameId(file);
    auto d = new Schema::EventDebug(fileId, id, message, getTimeDifference(), verbosity);
    logSink(d);
    delete d;  // GC seems to fail to collect on this pointer
}

void EventLogger::decision(unsigned verbosity, const std::string &file,
                           const std::string &description, const std::string &what,
                           const std::string &why) {
    const std::string message = description + ", choosing: " + what + ", because: " + why;
    getDebugStream(verbosity, file) << message << std::endl;

    if (!enabled) return;
    const int id = int(EventType::Decision);
    const int fileId = getFileNameId(file);
    auto d = new Schema::EventDecision(what, fileId, id, description, why,
                                       getTimeDifference(), verbosity);
    logSink(d);
    delete d;  // GC seems to fail to collect on this pointer
}

void EventLogger::iterationChange(unsigned iteration, AllocPhase phase) {
    if (!enabled) return;
    const int id = int(EventType::IterationChange);
    auto ic = new Schema::EventIterationChanged(id, iteration, std::to_string(phase),
                                                getTimeDifference());
    logSink(ic);
    delete ic;  // GC seems to fail to collect on this pointer
}

void EventLogger::pipeChange(int pipeId) {
    if (!enabled) return;
    const int id = int(EventType::PipeChange);
    auto pps = new Schema::EventPipeProcessingStarted(id, pipeId, getTimeDifference());
    logSink(pps);
    delete pps;  // GC seems to fail to collect on this pointer
}