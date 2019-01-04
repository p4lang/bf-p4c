#include <fstream>
#include <iostream>
#include <string>

#include "json.h"
#include "sections.h"

class DynHash : public Section {

    int lineno = -1;
    std::unique_ptr<json::obj> _dynhash = nullptr;
    std::string _dynhashFileName;

    DynHash() : Section("dynhash") {}

    void input(VECTOR(value_t) args, value_t data) {
        lineno = data.lineno;
        if (!CHECKTYPE(data, tSTR)) return;
        _dynhashFileName = data.s;
    }

    void process() {
        if (_dynhashFileName.empty()) return;
        std::ifstream inputFile(_dynhashFileName);
        inputFile >> _dynhash;
        if (!inputFile) {
            warning(lineno, "%s: not valid dynhash json representation",
                    _dynhashFileName.c_str());
            _dynhash.reset(new json::map());
        }
    }

    void output(json::map &ctxtJson) {
        if (_dynhash) {
           ctxtJson.merge(_dynhash->to<json::map>());
        }
    }

    static DynHash singleton_dynhash;
} DynHash::singleton_dynhash;
