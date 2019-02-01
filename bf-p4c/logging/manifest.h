#ifndef _EXTENSIONS_BF_P4C_LOGGING_MANIFEST_H_
#define _EXTENSIONS_BF_P4C_LOGGING_MANIFEST_H_

#include <rapidjson/document.h>
#include <rapidjson/prettywriter.h>
#include <cstdarg>
#include <fstream>
#include <map>
#include <string>
#include <utility>

#include "bf-p4c/arch/arch.h"
#include "bf-p4c/bf-p4c-options.h"
#include "bf-p4c/common/run_id.h"
#include "ir/ir.h"
#include "lib/cstring.h"
#include "bf-p4c/version.h"

namespace Logging {

/// A manifest file is the TOC for the compiler outputs.
/// It is a JSON file, specified by the schema defined in archive_manifest.py
/// We derive it from an inspector, since it needs access to the P4 blocks to
/// figure out what graphs were generated. Ideally, it should be passed to the
/// p4-graphs calls and generate the signature there. But we won't pollute
/// that code with BFN internals.
class Manifest : public Inspector {
 private:
    /// map pipe-id to <pipe name, context path>
    std::map<int, std::pair<cstring, cstring> > _contexts;
    // map path to <pipe_id, type_of_resource>
    std::map<cstring, std::pair<int, cstring> > _resources;
    std::map<cstring, cstring> _graphs;
    std::map<cstring, cstring> _logs;
    BFN::ProgramThreads        _threads;
    const BFN_Options &        _options;
    std::ofstream              _manifestStream;
    bool _success = false;

 public:
    /// Return the singleton object
    static Manifest &getManifest() {
        static Manifest instance;
        return instance;
    }

 private:
    Manifest() : _options(BackendOptions()) {
        auto path = Util::PathName(_options.outputDir).join("manifest.json");
        _manifestStream.open(path.toString().c_str(), std::ofstream::out);
        if (!_manifestStream)
            std::cerr << "Failed to open manifest file " << path.toString() << std::endl;
    }

    ~Manifest() {
        _manifestStream.flush();
        _manifestStream.close();
    }

 public:
    void postorder(const IR::P4Parser *parser) override {
        if (parser && parser->name) {
            auto path = Util::PathName("graphs").join(parser->name + ".dot");
            addGraph("parser", path.toString());
        }
    }

    void postorder(const IR::PackageBlock *block) override {
        for (auto it : block->constantValue) {
            if (!it.second) continue;
            if (it.second->is<IR::ControlBlock>()) {
                auto name = it.second->to<IR::ControlBlock>()->container->name;
                auto path = Util::PathName("graphs").join(name + ".dot");
                addGraph("control", path.toString());
            } else if (it.second->is<IR::PackageBlock>()) {
                visit(it.second->getNode());
            }
        }
    }

    using Writer = rapidjson::PrettyWriter<rapidjson::StringBuffer>;
    virtual void serialize() {
        rapidjson::StringBuffer sb;
        Writer writer(sb);

        writer.StartObject();  // start BFNCompilerArchive
        writer.Key("schema_version");
        writer.String("1.5.1");
        writer.Key("target");
        if (_options.target)
            writer.String(_options.target.c_str());
        else
            writer.String("tofino");
        writer.Key("build_date");
        const time_t now = time(NULL);
        char build_date[1024];
        strftime(build_date, 1024, "%c", localtime(&now));
        writer.String(build_date);
        writer.Key("compiler_version");
        writer.String(BF_P4C_VERSION);
        writer.Key("compilation_succeeded");
        writer.Bool(_success);
        serializeArchConfig(writer);
        writer.Key("programs");
        writer.StartArray();   // start programs
        writer.StartObject();  // start CompiledProgram
        writer.Key("program_name");
        cstring program_name = _options.programName + ".p4";
        writer.String(program_name.c_str());
        writer.Key("p4_version");
        writer.String((_options.langVersion == BFN_Options::FrontendVersion::P4_14) ?
                      "p4-14" : "p4-16");
        writer.Key("run_id");
        writer.String(RunId::getId().c_str());
        writer.Key("contexts");
        writer.StartArray();
        for (auto c : _contexts) {
            writer.StartObject();
            writer.Key("pipe");
            writer.Int(c.first);
            writer.Key("pipe_name");
            writer.String(c.second.first.c_str());
            writer.Key("path");
            writer.String(c.second.second.c_str());
            writer.EndObject();
        }
        writer.EndArray();

        writer.Key("binaries");
        writer.StartArray();
        writer.EndArray();  // Should be written by assembler or driver on successful compile

        writer.Key("p4i");
        writer.StartArray();
        for (auto r : _resources) {
            writer.StartObject();
            writer.Key("path");
            writer.String(r.first.c_str());
            writer.Key("pipe");
            writer.Int(r.second.first);
            writer.Key("type");
            writer.String(r.second.second.c_str());
            writer.EndObject();
        }
        writer.EndArray();

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
        _manifestStream.flush();
        _manifestStream.close();
    }
    void setSuccess(bool success) {
        _success = success;
    }

    void addContext(int pipe, cstring pipe_name, cstring path) {
        _contexts.emplace(pipe, std::make_pair(pipe_name, path));
    }
    void addResources(int pipe, cstring path, cstring type = "resources") {
        _resources.emplace(path, std::make_pair(pipe, type));
    }
    void addGraph(cstring graph_type, cstring path) {
        _graphs.emplace(path, graph_type);
    }
    void addLog(cstring log_type, cstring path) {
        _logs.emplace(path, log_type);
    }
    void addArchitecture(const BFN::ProgramThreads &threads) {
        _threads.insert(threads.cbegin(), threads.cend());
    }

    void serializeArchConfig(Writer &writer) {
        writer.Key("architecture");
        if (_options.arch) {
            writer.String(_options.arch.c_str());
        } else {
            if (_options.isv1())
                writer.String("v1model");
            else
                writer.String("PISA");
        }

        if (_threads.size() == 0)
            return;

        writer.Key("architectureConfig");
        writer.StartObject();
        writer.Key("name");
        auto numPorts = std::to_string(64/_threads.size()*2) + "q";
        writer.String(numPorts.c_str());
        writer.Key("pipes");
        writer.StartArray();
        std::set<int> pipes;
        for (auto t : _threads)
            pipes.insert(t.first.first);
        for (auto p : pipes) {
            writer.StartObject();
            writer.Key("pipe");
            writer.Int(p);
            for (auto g : { INGRESS, EGRESS}) {
                auto t = _threads.find(std::pair<int, gress_t>(p, g));
                if (t != _threads.end()) {
                    writer.Key(t->first.second == INGRESS ? "ingress" : "egress");
                    writer.StartObject();
                    writer.Key("pipeName");
                    writer.String(t->second->mau->externalName().c_str());
                    writer.Key("nextControl");
                    writer.StartArray();
                    switch (g) {
                    case INGRESS:
                        // ingress can go to any other pipe's egress
                        for (auto np : pipes)
                            sendTo(writer, np, EGRESS);
                        break;
                    case EGRESS:
                        if (p != 0) {
                            // pipe 0 egress always goes out
                            // any other pipe goes to its ingress
                            sendTo(writer, p, INGRESS);
                        }
                        break;
                    default: break; }
                    writer.EndArray();
                    writer.EndObject();
                }
            }
            writer.EndObject();
        }
        writer.EndArray();
        writer.EndObject();
    }

    void sendTo(Writer &writer, int pipe, gress_t gress) {
        auto t = _threads.find(std::pair<int, gress_t>(pipe, gress));
        if (t != _threads.end()) {
            writer.StartObject();
            writer.Key("pipe");
            writer.Int(pipe);
            writer.Key("pipeName");
            writer.String(t->second->mau->externalName().c_str());
            writer.EndObject();
        }
    }
};
}  // end namespace Logging

#endif  /* _EXTENSIONS_BF_P4C_LOGGING_MANIFEST_H_ */
