#include <libgen.h>
#include <cstdlib>
#include <string>

#include "manifest.h"
#include "backends/graphs/controls.h"
#include "backends/graphs/parsers.h"
#include "bf-p4c/common/run_id.h"
#include "bf-p4c/version.h"
#include "ir/ir.h"

using Manifest = Logging::Manifest;

void Manifest::postorder(const IR::BFN::TnaParser *parser) {
    auto pipeName = _pipes.at(_pipeId);
    if (parser && (_pipes.size() == 1 || parser->pipeName == pipeName) && parser->name) {
        CHECK_NULL(_refMap); CHECK_NULL(_typeMap);
        auto graphsDir = BFNContext::get().getOutputDirectory("graphs", _pipeId);
        graphs::ParserGraphs pgen(_refMap, _typeMap, graphsDir);
        parser->apply(pgen);
        addGraph(_pipeId, "parser", parser->name, parser->thread);
    }
}

void Manifest::postorder(const IR::BFN::TnaControl *control) {
    auto controlName = control->name.name;
    auto pipeName = _pipes.at(_pipeId);
    if (control && control->pipeName == pipeName && controlName) {
        // FIXME(cc): not yet sure why we can't generate control graphs unless invoked at
        // the top level.
        // CHECK_NULL(_refMap); CHECK_NULL(_typeMap);
        // auto graphsDir = BFNContext::get().getOutputDirectory("graphs", _pipeId);
        // graphs::ControlGraphs cgen(_refMap, _typeMap, graphsDir);
        // control->apply(cgen);
        addGraph(_pipeId, "control", controlName, control->thread);
    }
}

Manifest::InputFiles::InputFiles(const BFN_Options &options) {
    char *filePath = strndup(options.file.c_str(), options.file.size());
    _rootPath = cstring(dirname(filePath));
    free(filePath);

    // walk the command line arguments and collect includes
    char *ppFlags = strndup(options.preprocessor_options.c_str(),
                            options.preprocessor_options.size());
    char *brkt;
    const char *sep = " ";
    for (auto *word = strtok_r(ppFlags, sep, &brkt); word; word = strtok_r(nullptr, sep, &brkt)) {
        if (word[0] == '-' && word[1] == 'I')
            _includePaths.insert(cstring(word+2));
        else if (word[0] == '-' && word[1] == 'D')
            _defines.insert(cstring(word+2));
        else if (word[0] == '-' && word[1] == 'U')
            _defines.erase(cstring(word+2));
    }
    free(ppFlags);
}

void Manifest::InputFiles::serialize(Writer &writer) {
    writer.Key("source_files");
    writer.StartObject();
    writer.Key("src_root");
    writer.String(_rootPath.c_str());
    writer.Key("includes");
    writer.StartArray();
    for (auto i : _includePaths)
        writer.String(i.c_str());
    writer.EndArray();
    writer.Key("defines");
    writer.StartArray();
    for (auto d : _defines)
        writer.String(d.c_str());
    writer.EndArray();
    writer.EndObject();
}

/// serialize the entire manifest
void Manifest::serialize() {
    rapidjson::StringBuffer sb;
    Writer writer(sb);

    writer.StartObject();  // start BFNCompilerArchive
    writer.Key("schema_version");
    writer.String(MANIFEST_SCHEMA_VERSION);
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
    writer.Key("compilation_time");
    writer.String("0.0");
    writer.Key("run_id");
    writer.String(RunId::getId().c_str());

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
    _programInputs.serialize(writer);
    serializePipes(writer);
    writer.EndObject();  // end CompiledProgram
    writer.EndArray();   // end "programs"
    writer.EndObject();  // end BFNCompilerArchive

    BUG_CHECK(_manifestStream, "manifest.json has been serialized already!");

    _manifestStream << sb.GetString();
    _manifestStream.flush();
    _manifestStream.close();
}

void Manifest::serializeArchConfig(Writer &writer) {
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
    for (auto p : _pipes) {
        writer.StartObject();
        writer.Key("pipe");
        writer.Int(p.first);
        for (auto g : { INGRESS, EGRESS}) {
            auto t = _threads.find(std::pair<int, gress_t>(p.first, g));
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
                    for (auto np : _pipes)
                        sendTo(writer, np.first, EGRESS);
                    break;
                case EGRESS:
                    if (p.first != 0) {
                        // pipe 0 egress always goes out
                        // any other pipe goes to its ingress
                        sendTo(writer, p.first, INGRESS);
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

/// serialize all the output in an array of pipes ("pipes" : [ OutputFiles ])
void Manifest::serializePipes(Writer &writer) {
    writer.Key("pipes");
    writer.StartArray();  // for each pipe
    for (auto p : _pipeOutputs) {
        writer.StartObject();
        writer.Key("pipe_id");
        writer.Int(p.first);
        writer.Key("pipe_name");
        writer.String(_pipes.at(p.first).c_str());
        p.second->serialize(writer);
        writer.EndObject();
    }
    writer.EndArray();
}

void Manifest::sendTo(Writer &writer, int pipe, gress_t gress) {
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
