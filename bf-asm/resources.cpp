#include <fstream>
#include <iostream>
#include <string>

#include "json.h"
#include "sections.h"

class Resources : public Section {

    int lineno = -1;
    std::unique_ptr<json::obj>_resources = nullptr;
    std::string _resourcesFileName;

    Resources() : Section("resources") {}

    void input(VECTOR(value_t) args, value_t data) {
        lineno = data.lineno;
        if (!CHECKTYPE(data, tSTR)) return;
        _resourcesFileName = data.s;
    }

    void process() {
        if (_resourcesFileName.empty()) return;
        std::ifstream inputFile(_resourcesFileName);
        inputFile >> _resources;
        if (!inputFile) {
            warning(lineno, "%s: not valid resources json representation",
                    _resourcesFileName.c_str());
            _resources.reset(new json::map());
        }
    }

    void output(json::map &ctxtJson) {
        if (_resources)
            ctxtJson["resources"] = std::move(_resources);
    }

    static Resources singleton_resources;
} Resources::singleton_resources;
