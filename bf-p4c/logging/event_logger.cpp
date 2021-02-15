#include "event_logger.h"
#include <spdlog/spdlog.h>
#include <spdlog/sinks/basic_file_sink.h>
#include <ctime>
#include "logging.h"
#include "lib/log.h"

bool EventLogger::isVerbosityAtLeast(unsigned level, const std::string &file) const {
    return level <= MAX_LOGGING_LEVEL && ::Log::fileLogLevelIsAtLeast(file.c_str(), level);
}

std::string EventLogger::getCurrentTimestamp() {
    return std::to_string(std::time(nullptr));
}

void EventLogger::logStart() {
    /* TODO: implementation */
}

void EventLogger::passChange(const std::string &, const std::string &, unsigned ) {
    /* TODO: implementation */
}

EventLogger::EventLogger() {
    constexpr bool TRUNCATE = true;

    // TODO: Figure out location of the log
    // TOOD: Add location to manifest.json

    /* NOTE: spdlog supports asynchronous loggers, but garbage collection somehow
       frees some resources prematurely, causing it to SIGSEGV. Thus, for now, we
       only use synchronous logger with multithread safety. */
    auto logger = spdlog::basic_logger_mt("logger", "/tmp/events.json", TRUNCATE);

    /* NOTE: Following command flushes log after every single message so P4I always
       gets valid objects. If this proves to be a bottleneck, we would have to remove
       it and P4I would have to implement some stream parsing solution. */
    logger->flush_on(spdlog::level::err);

    spdlog::set_default_logger(logger);
    spdlog::set_pattern("%v");  // print just the message, no decorations

    logStart();
}

EventLogger &EventLogger::get() {
    static EventLogger instance;
    return instance;
}

void EventLogger::parserError(const std::string &, const Util::SourceInfo &) {
    /* TODO: implementation */
}

void EventLogger::error(const std::string &, const std::string &,
                        const Util::SourceInfo *) {
    /* TODO: implementation */
}

void EventLogger::warning(const std::string &, const std::string &,
                          const Util::SourceInfo *) {
    /* TODO: implementation */
}

void EventLogger::debug(unsigned level, const std::string &file, const std::string &message) {
    if (!isVerbosityAtLeast(level, file)) return;

    ::Log::Detail::fileLogOutput(file.c_str())
        << ::Log::Detail::OutputLogPrefix(file.c_str(), level) << message << std::endl;

    /* TODO: implementation */
}

void EventLogger::decision(unsigned level, const std::string &file, const std::string &description,
                           const std::string &what, const std::string &why) {
    if (!isVerbosityAtLeast(level, file)) return;

    const std::string message = description + ", choosing: " + what + ", because: " + why;
    ::Log::Detail::fileLogOutput(file.c_str())
        << ::Log::Detail::OutputLogPrefix(file.c_str(), level) << message << std::endl;

    /* TODO: implementation */
}
