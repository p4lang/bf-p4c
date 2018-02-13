#include <fstream>
#include <iostream>
#include <string>

#include "json.h"
#include "sections.h"

class Resources : public Section {

    std::unique_ptr<json::obj>_resources = nullptr;
    std::string _resourcesFileName;

    Resources() : Section("resources") {}

    void input(VECTOR(value_t) args, value_t data) {
        if (!CHECKTYPE(data, tSTR)) return;
        _resourcesFileName = data.s;
    }

    void process() {
        std::ifstream inputFile(_resourcesFileName);
        inputFile >> _resources;
        if (!inputFile) {
            std::cerr << _resourcesFileName << ": not valid resources json representation"
                      << std::endl;
            _resources.reset(new json::map());
        }
    }

    void output(json::map &ctxtJson) {
        ctxtJson["resources"] = std::move(_resources);
    }

    static Resources singleton_resources;
} Resources::singleton_resources;
