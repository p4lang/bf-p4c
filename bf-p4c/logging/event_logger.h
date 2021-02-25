#ifndef _EXTENSIONS_BF_P4C_LOGGING_EVENT_LOGGER_H_
#define _EXTENSIONS_BF_P4C_LOGGING_EVENT_LOGGER_H_

#include <functional>
#include <string>

namespace IR {
class Node;  // Forward declare IR::Node for debug hook
}

namespace Util {
class SourceInfo;  // Forward declare Util::SourceInfo for errors/warnings
};

class EventBaseWrapper;  // Wraps Schema::Event_Log_Schema_Logger::Event_Base

// Copy typedef of DebugHook so we don't have to depend on ir/ir.h
typedef std::function<void(const char*, unsigned, const char*, const IR::Node*)> DebugHook;

/**
 *  Custom logger for emitting EventLog for P4I
 *  Almost every message in the compiler should be logged via this interface.
 *  This class manages backward compatibility of logs.
 *
 *  \warning By default this class dumps all messages to null sink. To log them
 *  into actual logfile, you need to call method init()
 */
class EventLogger {
 protected:
    // Used for deduplicating passChange messages
    std::string lastManager = "";
    std::string lastPass = "";
    unsigned lastSeq = 0;

    EventLogger();
    EventLogger(EventLogger &&other) = delete;
    EventLogger(const EventLogger &other) = delete;
    EventLogger &operator=(const EventLogger &other) = delete;
    ~EventLogger() {}

    /**
     *  Used in testing to manually reset spdlog at will
     */
    void deinit();

    /**
     *  Each message requires current timestamp in form of number of seconds
     *  since 1970-01-01 00:00
     */
    virtual std::string getCurrentTimestamp() const;

    /**
     *  Gets output stream to which LOGn messages are normally emitted
     *  (backwards compatibility)
     */
    virtual std::ostream &getDebugStream(unsigned level, const std::string &file) const;

    /**
     *  Uses lib/log.h capabilities to check whether particular C++ source file
     *  has verbosity level set to at least 'level'
     *
     *  Used to determine whether particular debug/decision log should be emitted
     *  (backwards compatibility)
     */
    virtual bool isVerbosityAtLeast(unsigned level, const std::string &file) const;

    /**
     *  This is sink function for all logging functions. It accepts object to
     *  be serialized, serializes it to JSON and then calls underlying logger
     *  to dump it to output.
     */
    void logSink(const EventBaseWrapper &obj);

    /**
     *  This function is called from constructor, bootstrapping event log with
     *  schema version so P4I can use correct parser
     */
    void logStart();

    /**
     *  This function is called through debug hooks from each pass manager
     */
    void passChange(const std::string &manager, const std::string &pass, unsigned seq);

 public:
    enum class AllocPhase {
        PhvAllocation, TablePlacement
    };

    static EventLogger &get();

    /**
     *  This function initializes the logger and emits EventLogStart to logfile
     *
     * \p outdir    Path to directory in which manifest.json is located
     * \p filename  Path to logfile, relative to manifest.json
     *
     * \note Until this function is called, all events go to null sink
     */
    void init(const std::string &outdir, const std::string &filename);

    /**
     *  This function is expected to be called from ErrorReporter
     *  as a custom sink for parser error messages
     */
    void parserError(const std::string &message, const Util::SourceInfo &info);

    /**
     *  This function is expected to be called from ErrorReporter
     *  as a custom sink for error messages
     */
    void error(const std::string &message, const std::string &type = "",
               const Util::SourceInfo *info = nullptr);

    /**
     *  This function is expected to be called from ErrorReporter
     *  as a custom sink for warning messages
     */
    void warning(const std::string &message, const std::string &type = "",
                 const Util::SourceInfo *info = nullptr);

    /**
     *  This function is expected to be called from LOG_DEBUGn macros
     */
    void debug(unsigned level, const std::string &file, const std::string &message);

    /**
     *  This function is expected to be called from LOG_DECISIONn macros
     */
    void decision(unsigned level, const std::string &file, const std::string &description,
                  const std::string &what, const std::string &why);

    /**
     *  This function should be called when new PhvAllocation or TablePlacement phase
     *  is started. Iteration number should be the same as in name of appropriate logfiles.
     */
    void iterationChange(unsigned iteration, AllocPhase phase);

    /**
     *  This function should be called when backend is executed on a particular pipe
     */
    void pipeChange(int pipeId);

    /**
     *  Get callback for logging changes in pass managers
     */
    static DebugHook getDebugHook() {
        return [] (const char *m, unsigned s, const char *p, const IR::Node*) {
            get().passChange(m, p, s);
        };
    }
};

/**
 *  NOTE: We need __FILE__ macro to look up whether source file in which this is called
 *  has logging level set to appropriate level or not. Because __FILE__ is used, we can't
 *  call EventLogger directly (unless we want to force developers to write down __FILE__
 *  manually all the time).
 *
 *  These macros log into both Event Log and regular LOGn.
 */
#define LOG_DEBUG(level, message) EventLogger::get().debug(level, __FILE__, message);
#define LOG_DEBUG1(message) LOG_DEBUG(1, message)
#define LOG_DEBUG2(message) LOG_DEBUG(2, message)
#define LOG_DEBUG3(message) LOG_DEBUG(3, message)
#define LOG_DEBUG4(message) LOG_DEBUG(4, message)
#define LOG_DEBUG5(message) LOG_DEBUG(5, message)
#define LOG_DEBUG6(message) LOG_DEBUG(6, message)
#define LOG_DEBUG7(message) LOG_DEBUG(7, message)
#define LOG_DEBUG8(message) LOG_DEBUG(8, message)
#define LOG_DEBUG9(message) LOG_DEBUG(9, message)

/**
 *  Logs structured decision into Event Log, as well as unstructured message into
 *  regular LOGn.
 */
#define LOG_DECISION(level, description, chosen, why) \
    EventLogger::get().decision(level, __FILE__, description, chosen, why);
#define LOG_DECISION1(description, chosen, why) LOG_DECISION(1, description, chosen, why);
#define LOG_DECISION2(description, chosen, why) LOG_DECISION(2, description, chosen, why);
#define LOG_DECISION3(description, chosen, why) LOG_DECISION(3, description, chosen, why);
#define LOG_DECISION4(description, chosen, why) LOG_DECISION(4, description, chosen, why);
#define LOG_DECISION5(description, chosen, why) LOG_DECISION(5, description, chosen, why);
#define LOG_DECISION6(description, chosen, why) LOG_DECISION(6, description, chosen, why);
#define LOG_DECISION7(description, chosen, why) LOG_DECISION(7, description, chosen, why);
#define LOG_DECISION8(description, chosen, why) LOG_DECISION(8, description, chosen, why);
#define LOG_DECISION9(description, chosen, why) LOG_DECISION(9, description, chosen, why);

#endif  /* _EXTENSIONS_BF_P4C_LOGGING_EVENT_LOGGER_H_ */
