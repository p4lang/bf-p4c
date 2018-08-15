#include <fstream>
#include <iostream>
#include <string>

#include "json.h"
#include "sections.h"

class Primitives : public Section {

    int lineno = -1;
    std::unique_ptr<json::obj>_primitives = nullptr;
    std::string _primitivesFileName;

    Primitives() : Section("primitives") {}

    void input(VECTOR(value_t) args, value_t data) {
        lineno = data.lineno;
        if (!CHECKTYPE(data, tSTR)) return;
        _primitivesFileName = data.s;
    }

    void process() {
        if (_primitivesFileName.empty()) return;
        std::ifstream inputFile(_primitivesFileName);
        inputFile >> _primitives;
        if (!inputFile) {
            warning(lineno, "%s: not valid primitives json representation",
                    _primitivesFileName.c_str());
            _primitives.reset(new json::map());
        }
    }

    void output(json::map &ctxtJson) {
        if (_primitives) {
            json::vector &_tables = _primitives->to<json::map>()["tables"];
            json::vector &ctxt_tables = ctxtJson["tables"];
            for (auto &_table : _tables) {
                bool is_merged = false;
                for (auto &ctxt_table : ctxt_tables) {
                    if (*ctxt_table->to<json::map>()["name"] ==
                            *_table->to<json::map>()["name"]) {
                        _table->to<json::map>().merge(ctxt_table->to<json::map>());
                        is_merged = true;
                        break; } }
                if (!is_merged)
                    ctxt_tables.emplace_back(_table->clone()); } }
    }

    static Primitives singleton_primitives;
} Primitives::singleton_primitives;
