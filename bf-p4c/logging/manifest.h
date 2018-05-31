#ifndef _EXTENSIONS_BF_P4C_LOGGING_MANIFEST_H_
#define _EXTENSIONS_BF_P4C_LOGGING_MANIFEST_H_

#include <rapidjson/document.h>
#include <rapidjson/prettywriter.h>
#include <cstdarg>
#include <fstream>
#include <map>
#include <string>

#include "bf-p4c-options.h"
#include "common/run_id.h"
#include "ir/ir.h"
#include "lib/cstring.h"
#include "version.h"

namespace Logging {

/// A manifest file is the TOC for the compiler outputs.
/// It is a JSON file, specified by the schema defined in archive_manifest.py
/// We derive it from an inspector, since it needs access to the P4 blocks to
/// figure out what graphs were generated. Ideally, it should be passed to the
/// p4-graphs calls and generate the signature there. But we won't pollute
/// that code with BFN internals.
class Manifest : public Inspector {
 private:
    std::map<int, cstring>     _contexts;
    std::map<cstring, cstring> _graphs;
    std::map<cstring, cstring> _logs;
    const BFN_Options &        _options;
    std::ofstream              _manifestStream;

 public:
    explicit Manifest(const BFN_Options &o) : _options(o) {
        auto path = Util::PathName(o.outputDir).join("manifest.json");
        _manifestStream.open(path.toString().c_str(), std::ofstream::out);
        if (!_manifestStream)
            std::cerr << "Failed to open manifest file " << path.toString() << std::endl;
    }
    ~Manifest() {
        _manifestStream.flush();
        _manifestStream.close();
    }

    void postorder(const IR::P4Parser *parser) override {
        if (parser && parser->name) {
            auto path = Util::PathName("graphs").join(parser->name + ".dot");
            addGraph("parser", path.toString());
        }
    }

    void postorder(const IR::PackageBlock *block) override {
        for (auto it : block->constantValue) {
            if (!it.second) continue;
            if (!it.second->is<IR::ControlBlock>())
                continue;
            auto name = it.second->to<IR::ControlBlock>()->container->name;
            auto path = Util::PathName("graphs").join(name + ".dot");
            addGraph("control", path.toString());
        }
    }

    virtual void serialize() {
        rapidjson::StringBuffer sb;
        using Writer = rapidjson::PrettyWriter<rapidjson::StringBuffer>;
        Writer writer(sb);

        writer.StartObject();  // start BFNCompilerArchive
        writer.Key("schema_version");
        writer.String("1.0.0");
        writer.Key("target");
        if (_options.target)
            writer.String(_options.target.c_str());
        else
            writer.String("tofino");
        writer.Key("architecture");
        if (_options.arch) {
            writer.String(_options.arch.c_str());
        } else {
            if (_options.isv1())
                writer.String("v1model");
            else
                writer.String("PISA");
        }
        writer.Key("build_date");
        const time_t now = time(NULL);
        char build_date[1024];
        strftime(build_date, 1024, "%c", localtime(&now));
        writer.String(build_date);
        writer.Key("compiler_version");
        writer.String(BF_P4C_VERSION);
        writer.Key("programs");
        writer.StartArray();   // start programs
        writer.StartObject();  // start CompiledProgram
        writer.Key("program_name");
        cstring program_name = _options.programName + ".p4";
        writer.String(program_name.c_str());
        writer.Key("run_id");
        writer.String(RunId::getId().c_str());
        writer.Key("contexts");
        writer.StartArray();
        for (auto c : _contexts) {
            writer.StartObject();
            writer.Key("pipe");
            writer.Int(c.first);
            writer.Key("path");
            writer.String(c.second.c_str());
            writer.EndObject();
        }
        writer.EndArray();

        writer.Key("binaries");
        writer.StartArray();
        writer.EndArray();  // Should be written by assembler or driver on successful compile

        writer.Key("graphs");
        writer.StartArray();
        for (auto c : _graphs) {
            writer.StartObject();
            writer.Key("graph_type");
            writer.String(c.second.c_str());
            writer.Key("graph_format");
            writer.String(".dot");
            writer.Key("path");
            writer.String(c.first.c_str());
            writer.EndObject();
        }
        writer.EndArray();

        writer.Key("logs");
        writer.StartArray();
        // Future work!
        for (auto l : _logs) {
            writer.StartObject();
            writer.Key("log_type");
            writer.String(l.second);
            writer.Key("path");
            writer.String(l.first.c_str());
            writer.EndObject();
        }
        writer.EndArray();

        // generate the archive manifest
        writer.EndObject();  // end CompiledProgram
        writer.EndArray();   // end "programs"
        writer.EndObject();  // end BFNCompilerArchive

        _manifestStream << sb.GetString();
    }

    // add context
    void addContext(int pipe_id, cstring path) {
        _contexts.emplace(pipe_id, path);
    }
    void addGraph(cstring graph_type, cstring path) {
        _graphs.emplace(path, graph_type);
    }
    void addLog(cstring log_type, cstring path) {
        _logs.emplace(path, log_type);
    }
};
}  // end namespace Logging

#endif  /* _EXTENSIONS_BF_P4C_LOGGING_MANIFEST_H_ */
