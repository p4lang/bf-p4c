#ifndef _EXTENSIONS_BF_P4C_LOGGING_MANIFEST_H_
#define _EXTENSIONS_BF_P4C_LOGGING_MANIFEST_H_

#include <rapidjson/document.h>
#include <rapidjson/prettywriter.h>
#include <cstdarg>
#include <fstream>
#include <map>
#include <set>
#include <string>
#include <utility>

#include "bf-p4c/arch/arch.h"
#include "bf-p4c/bf-p4c-options.h"
#include "bf-p4c/ir/gress.h"
#include "lib/cstring.h"
#include "lib/path.h"

namespace Logging {

/// A manifest file is the TOC for the compiler outputs.
/// It is a JSON file, specified by the schema defined in archive_manifest.py
/// We derive it from an inspector, since it needs access to the P4 blocks to
/// figure out what graphs were generated. Ideally, it should be passed to the
/// p4-graphs calls and generate the signature there. But we won't pollute
/// that code with BFN internals.
class Manifest : public Inspector {
    using Writer = rapidjson::PrettyWriter<rapidjson::StringBuffer>;
    using PathAndType = std::pair<cstring, cstring>;

    // to use PathAndType as std::set
    struct PathCmp {
        bool operator()(const PathAndType& lhs, const PathAndType& rhs) const {
            auto l = std::string(lhs.first) + std::string(lhs.second);
            auto r = std::string(rhs.first) + std::string(rhs.second);
            return std::less<std::string>()(l, r);
        }
    };

 private:
    /// the collection of inputs for the program
    struct InputFiles {
        cstring           _rootPath;
        cstring           _sourceInfo;  // path to source.json relative to manifest.json
        std::set<cstring> _includePaths;
        std::set<cstring> _defines;

        explicit InputFiles(const BFN_Options &options);
        void serialize(Writer &writer);
    };

    /// represents a graph file
    struct GraphOutput {
        cstring _path;
        gress_t _gress;
        cstring _type;
        cstring _format;
        GraphOutput(cstring path, gress_t gress, cstring type, cstring format = ".dot") :
            _path(path), _gress(gress), _type(type), _format(format) {}

        void serialize(Writer &writer) {
            writer.StartObject();
            writer.Key("path");
            writer.String(_path.c_str());
            writer.Key("gress");
            writer.String(toString(_gress).c_str());
            writer.Key("graph_type");
            writer.String(_type.c_str());
            writer.Key("graph_format");
            writer.String(_format.c_str());
            writer.EndObject();
        }

        cstring getHash() const {
            return _path + toString(_gress) + _type + _format;
        }
    };

    struct GraphOutputCmp {
        bool operator()(const GraphOutput& lhs, const GraphOutput& rhs) const {
            return std::less<const char *>()(lhs.getHash().c_str(), rhs.getHash().c_str());
        }
    };

    /// the collection of outputs for each pipe
    struct OutputFiles {
        cstring                               _context;  // path to the context file
        cstring                               _binary;   // path to the binary file
        // pairs of path and resource type
        std::set<PathAndType, PathCmp>        _resources;
        // pairs of path and log type
        std::set<PathAndType, PathCmp>        _logs;
        std::set<GraphOutput, GraphOutputCmp> _graphs;

        void serialize(Writer &writer) {
            writer.Key("files");
            writer.StartObject();
            // Should be overwritten by assembler or driver on successful compile
            writer.Key("context");
            writer.StartObject();
            writer.Key("path");
            if (_context)
                writer.String(_context);
            else
                writer.String("");
            writer.EndObject();

            // Should be written by assembler or driver on successful compile
            if (_binary) {
                writer.Key("binary");
                writer.StartObject();
                writer.Key("path");
                writer.String(_context);
                writer.EndObject();
            }

            writer.Key("resources");
            writer.StartArray();
            for (auto r : _resources) {
                writer.StartObject();
                writer.Key("path");
                writer.String(r.first.c_str());
                writer.Key("type");
                writer.String(r.second.c_str());
                writer.EndObject();
            }
            writer.EndArray();

            writer.Key("graphs");
            writer.StartArray();
            for (auto c : _graphs)
                c.serialize(writer);
            writer.EndArray();

            writer.Key("logs");
            writer.StartArray();
            for (auto l : _logs) {
                writer.StartObject();
                writer.Key("path");
                writer.String(l.first.c_str());
                writer.Key("log_type");
                writer.String(l.second.c_str());
                writer.EndObject();
            }
            writer.EndArray();
            writer.EndObject();  // files
        }
    };

    const BFN_Options &        _options;
    // pairs of <pipe_id, pipe_name>
    std::map<unsigned, cstring> _pipes;
    /// map of pipe-id to OutputFiles
    std::map<unsigned, OutputFiles *> _pipeOutputs;
    InputFiles                        _programInputs;
    cstring                    _eventLogPath;
    /// reference to ProgramThreads to generate the architecture configuration
    BFN::ProgramThreads        _threads;
    int                        _pipeId = -1;  /// the current pipe id (for the visitor methods)
    /// to generate parser and control graphs
    P4::ReferenceMap *         _refMap = nullptr;
    P4::TypeMap *              _typeMap = nullptr;
    std::ofstream              _manifestStream;
    /// compilation succeeded or failed
    bool _success = false;

 private:
    Manifest() : _options(BackendOptions()), _programInputs(BackendOptions()) {
        auto path = Util::PathName(_options.outputDir).join("manifest.json");
        _manifestStream.open(path.toString().c_str(), std::ofstream::out);
        if (!_manifestStream)
            std::cerr << "Failed to open manifest file " << path.toString() << std::endl;
    }

    ~Manifest() {
        for (auto p : _pipeOutputs) {
            delete p.second;
        }

        _manifestStream.flush();
        _manifestStream.close();
    }

    OutputFiles *getPipeOutputs(unsigned pipe) {
        auto it = _pipeOutputs.find(pipe);
        if (it != _pipeOutputs.end())
            return it->second;
        auto p = _pipeOutputs.emplace(pipe, new OutputFiles());
        return p.first->second;
    }

 public:
    /// Return the singleton object
    static Manifest &getManifest() {
        static Manifest instance;
        return instance;
    }

    /// Visitor methods to generate graphs
    void postorder(const IR::BFN::TnaParser *parser) override;
    void postorder(const IR::BFN::TnaControl *control) override;
    /// helper methods for the graph generators
    /// one can set any of the maps and invoke the appropriate visitors
    void setRefAndTypeMap(P4::ReferenceMap *refMap, P4::TypeMap *typeMap) {
        _refMap = refMap;
        _typeMap = typeMap;
    }

    void setPipe(int pipe_id, cstring pipe_name) {
        _pipeId = pipe_id;
        _pipes.emplace(_pipeId, pipe_name);
        // and add implicitly add the pipe outputs so that even if there are no
        // files produced by the compiler, we get the pipe structure. P4C-2160
        getPipeOutputs(pipe_id);
    }

    void setSuccess(bool success) { _success = success; }

    void addContext(int pipe, cstring path) {
        auto *files = getPipeOutputs(pipe);
        files->_context = path;
    }
    void addResources(int pipe, cstring path, cstring type = "resources") {
        auto *files = getPipeOutputs(pipe);
        files->_resources.insert(PathAndType(path, type));
    }
    void addGraph(int pipe, cstring graphType,
            cstring graphName, gress_t gress, cstring ext = ".dot") {
        auto path = BFNContext::get().getOutputDirectory("graphs", pipe)
            .substr(_options.outputDir.size()+1) + "/" + graphName + ext;
        auto *files = getPipeOutputs(pipe);
        files->_graphs.insert(GraphOutput(path, gress, graphType, ext));
    }
    void addLog(int pipe, cstring logType, cstring logName) {
        auto path = BFNContext::get().getOutputDirectory("logs", pipe)
            .substr(_options.outputDir.size()+1) + "/" + logName;
        auto *files = getPipeOutputs(pipe);
        files->_logs.insert(PathAndType(path, logType));
    }
    void addArchitecture(const BFN::ProgramThreads &threads) {
        _threads.insert(threads.cbegin(), threads.cend());
    }
    void setSourceInfo(cstring path) {
        BUG_CHECK(_programInputs._sourceInfo.size() == 0,
            "Trying to redefine path to source info!");
        _programInputs._sourceInfo = path;
    }
    void setEventLog(cstring path) {
        BUG_CHECK(_eventLogPath.size() == 0,
            "Trying to redefine path to source info!");
        _eventLogPath = path;
    }

    /// serialize the entire manifest
    virtual void serialize();

 private:
    void serializeArchConfig(Writer &writer);

    /// serialize all the output in an array of pipes ("pipes" : [ OutputFiles ])
    void serializePipes(Writer &writer);

    void sendTo(Writer &writer, int pipe, gress_t gress);
};
}  // end namespace Logging

#endif  /* _EXTENSIONS_BF_P4C_LOGGING_MANIFEST_H_ */
