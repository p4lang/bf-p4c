#include <unistd.h>
#include <fstream>
#include "gtest/gtest.h"
#include "bf-p4c/logging/event_logger.h"
#include "lib/source_file.h"

namespace Test {

class EventLoggerTestable : public EventLogger {
 private:
    std::string getCurrentTimestamp() const override {
        return "TIMESTAMP";
    }

    std::ostream &getDebugStream(unsigned, const std::string &) const override {
        return std::clog;
    }

 public:
    static EventLoggerTestable &get2() {
        static EventLoggerTestable instance;
        return instance;
    }

    static DebugHook getDebugHook2() {
        return [] (const char *m, unsigned s, const char *p, const IR::Node*) {
            get2().passChange(m, p, s);
        };
    }

    void restore() {
        EventLogger::nullInit();
    }
};

class EventLoggerTest : public ::testing::Test {
 protected:
    using EventLogger = EventLoggerTestable;
    const std::string OUTDIR = "/tmp";
    const std::string FILE = "event-log-gtest.json";
    const std::string PATH = OUTDIR + "/" + FILE;
    const Util::SourceInfo srcInfo = Util::SourceInfo("file.cpp", 1, 10, "");

    void SetUp() {
        // ::EventLogger might be initialized from previous regressions, clear it
        ::EventLogger::get().deinit();
        unlink(PATH.c_str());
    }

    void TearDown() {
        // Clear logger
        EventLogger::get().deinit();
        // Restore null_logger so follow-up regression works
        EventLogger::get2().restore();
        unlink(PATH.c_str());
    }

    void initLogger() {
        EventLogger::get2().init(OUTDIR, FILE);
    }

    void deinitLogger() {
        // Normally logger is destroyed when program ends
        // We need to emulate this in the test so the stream
        // is flushed and closed
        EventLogger::get().deinit();
    }

    void compareFileWithExpected(std::ifstream &file,
                                 const std::vector<std::string> &expectedLines) {
        for (auto &expectedLine : expectedLines) {
            std::string actualLine;
            std::getline(file, actualLine);

            EXPECT_EQ(expectedLine, actualLine);
        }

        // Eat extra line at end to trigger EOF
        std::string nulls;
        std::getline(file, nulls);
    }
};

TEST_F(EventLoggerTest, DoesNothingWithoutInit) {
    // Expecting this logfile doesn't exist because
    // logger was not initialized
    EventLogger::get2().error("ERROR MSG");

    std::ifstream load(PATH);
    EXPECT_FALSE(load.good());
}

TEST_F(EventLoggerTest, ExportsEventLogStart) {
    initLogger();
    deinitLogger();

    std::ifstream load(PATH);
    EXPECT_TRUE(load.good());

    std::vector<std::string> expectedLines = {
        R"({"event_type":"start","schema_version":"1.0.0","time":"TIMESTAMP"})"
    };
    compareFileWithExpected(load, expectedLines);

    EXPECT_TRUE(load.eof());
}

TEST_F(EventLoggerTest, ExportsParserError) {
    initLogger();
    EventLogger::get2().parserError("Parser error", srcInfo);
    deinitLogger();

    std::ifstream load(PATH);
    EXPECT_TRUE(load.good());

    std::vector<std::string> expectedLines = {
        R"({"event_type":"start","schema_version":"1.0.0","time":"TIMESTAMP"})",
        R"({"event_type":"parser_error","message":"Parser error","src_info":{"column":10,"file":"file.cpp","line":1},"time":"TIMESTAMP"})"
    };
    compareFileWithExpected(load, expectedLines);

    EXPECT_TRUE(load.eof());
}

TEST_F(EventLoggerTest, ExportsEventCompilationError) {
    initLogger();
    EventLogger::get2().error("Plain error");
    EventLogger::get2().error("Error with only src info", "", &srcInfo);
    EventLogger::get2().error("Error with only type", "type");
    EventLogger::get2().error("Error with type and src", "type", &srcInfo);
    deinitLogger();

    std::ifstream load(PATH);
    EXPECT_TRUE(load.good());

    std::vector<std::string> expectedLines = {
        R"({"event_type":"start","schema_version":"1.0.0","time":"TIMESTAMP"})",
        R"({"event_type":"compilation_error","message":"Plain error","time":"TIMESTAMP"})",
        R"({"event_type":"compilation_error","message":"Error with only src info","time":"TIMESTAMP","src_info":{"column":10,"file":"file.cpp","line":1}})",
        R"({"event_type":"compilation_error","message":"Error with only type","time":"TIMESTAMP","type":"type"})",
        R"({"event_type":"compilation_error","message":"Error with type and src","time":"TIMESTAMP","src_info":{"column":10,"file":"file.cpp","line":1},"type":"type"})",
    };
    compareFileWithExpected(load, expectedLines);

    EXPECT_TRUE(load.eof());
}

TEST_F(EventLoggerTest, ExportsEventCompilationWarning) {
    initLogger();
    EventLogger::get2().warning("Plain warning");
    EventLogger::get2().warning("Warning with only src info", "", &srcInfo);
    EventLogger::get2().warning("Warning with only type", "type");
    EventLogger::get2().warning("Warning with type and src", "type", &srcInfo);
    deinitLogger();

    std::ifstream load(PATH);
    EXPECT_TRUE(load.good());

    std::vector<std::string> expectedLines = {
        R"({"event_type":"start","schema_version":"1.0.0","time":"TIMESTAMP"})",
        R"({"event_type":"compilation_warning","message":"Plain warning","time":"TIMESTAMP"})",
        R"({"event_type":"compilation_warning","message":"Warning with only src info","time":"TIMESTAMP","src_info":{"column":10,"file":"file.cpp","line":1}})",
        R"({"event_type":"compilation_warning","message":"Warning with only type","time":"TIMESTAMP","type":"type"})",
        R"({"event_type":"compilation_warning","message":"Warning with type and src","time":"TIMESTAMP","src_info":{"column":10,"file":"file.cpp","line":1},"type":"type"})",
    };
    compareFileWithExpected(load, expectedLines);

    EXPECT_TRUE(load.eof());
}

TEST_F(EventLoggerTest, ExportsEventDebug) {
    initLogger();
    EventLogger::get2().debug(6, "file.cpp", "Debug");
    deinitLogger();

    std::ifstream load(PATH);
    EXPECT_TRUE(load.good());

    std::vector<std::string> expectedLines = {
        R"({"event_type":"start","schema_version":"1.0.0","time":"TIMESTAMP"})",
        R"({"event_type":"debug","file":"file.cpp","message":"Debug","time":"TIMESTAMP","verbosity":6})"
    };
    compareFileWithExpected(load, expectedLines);

    EXPECT_TRUE(load.eof());
}

TEST_F(EventLoggerTest, ExportsEventDecision) {
    initLogger();
    EventLogger::get2().decision(3, "file.cpp", "Description", "Picked decision", "Reason");
    deinitLogger();

    std::ifstream load(PATH);
    EXPECT_TRUE(load.good());

    std::vector<std::string> expectedLines = {
        R"({"event_type":"start","schema_version":"1.0.0","time":"TIMESTAMP"})",
        R"({"event_type":"decision","decision":"Picked decision","file":"file.cpp","message":"Description","reason":"Reason","time":"TIMESTAMP","verbosity":3})"
    };
    compareFileWithExpected(load, expectedLines);

    EXPECT_TRUE(load.eof());
}

TEST_F(EventLoggerTest, ExportsDeduplicatedPassChange) {
    auto debugHook = EventLogger::getDebugHook2();

    initLogger();
    debugHook("mgr", 0, "pass", nullptr);
    debugHook("mgr", 1, "pass2", nullptr);
    debugHook("mgr", 1, "pass2", nullptr);  // this message should be deduplicated
    debugHook("mgr2", 0, "pass", nullptr);
    deinitLogger();

    std::ifstream load(PATH);
    EXPECT_TRUE(load.good());

    std::vector<std::string> expectedLines = {
        R"({"event_type":"start","schema_version":"1.0.0","time":"TIMESTAMP"})",
        R"({"event_type":"pass_change","manager":"mgr","passname":"pass","seq":0,"time":"TIMESTAMP"})",
        R"({"event_type":"pass_change","manager":"mgr","passname":"pass2","seq":1,"time":"TIMESTAMP"})",
        R"({"event_type":"pass_change","manager":"mgr2","passname":"pass","seq":0,"time":"TIMESTAMP"})"
    };
    compareFileWithExpected(load, expectedLines);

    EXPECT_TRUE(load.eof());
}

TEST_F(EventLoggerTest, ExportsPipeChange) {
    auto debugHook = EventLogger::getDebugHook2();

    initLogger();
    EventLogger::get2().pipeChange(1);
    deinitLogger();

    std::ifstream load(PATH);
    EXPECT_TRUE(load.good());

    std::vector<std::string> expectedLines = {
        R"({"event_type":"start","schema_version":"1.0.0","time":"TIMESTAMP"})",
        R"({"event_type":"pipe_started","pipe_id":1,"time":"TIMESTAMP"})"
    };
    compareFileWithExpected(load, expectedLines);

    EXPECT_TRUE(load.eof());
}

TEST_F(EventLoggerTest, ExportsIterationChange) {
    auto debugHook = EventLogger::getDebugHook2();

    initLogger();
    EventLogger::get2().iterationChange(1, EventLogger::AllocPhase::PhvAllocation);
    EventLogger::get2().iterationChange(2, EventLogger::AllocPhase::TablePlacement);
    deinitLogger();

    std::ifstream load(PATH);
    EXPECT_TRUE(load.good());

    std::vector<std::string> expectedLines = {
        R"({"event_type":"start","schema_version":"1.0.0","time":"TIMESTAMP"})",
        R"({"event_type":"iteration_change","num":1,"phase":"phv_allocation","time":"TIMESTAMP"})",
        R"({"event_type":"iteration_change","num":2,"phase":"table_placement","time":"TIMESTAMP"})"
    };
    compareFileWithExpected(load, expectedLines);

    EXPECT_TRUE(load.eof());
}

}  // namespace Test