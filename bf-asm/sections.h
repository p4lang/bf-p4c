#ifndef _sections_h_
#define _sections_h_

#include "asm-types.h"
#include "json.h"
#include "map.h"
#include <string>
#include <stdarg.h>
#include "tfas.h"

class Section {
    static std::map<std::string, Section *>     *sections;
    std::string name;
    static Section *get(const char *name) { return ::get(sections, name); }
protected:
    Section(const char *name_) : name(name_) {
        if (!sections) sections = new std::map<std::string, Section *>();
        if (get(name_)) {
            fprintf(stderr, "Duplicate section handler for %s\n", name_);
            exit(1); }
        (*sections)[name] = this; }
    virtual ~Section() {
        sections->erase(name);
        if (sections->empty()) {
            delete sections;
            sections = 0; } }
    virtual void start(int lineno, VECTOR(value_t) args) { }
    virtual void input(VECTOR(value_t) args, value_t data) = 0;
    virtual void process() {}
    virtual void output(json::map &ctxtJson) = 0;
public:
    static int start_section(int lineno, char *name, VECTOR(value_t) args) {
        if (Section *sec = get(name)) {
            int prev_error_count = error_count;
            sec->start(lineno, args);
            return error_count > prev_error_count;
        } else {
            warning(lineno, "Unknown section %s, ignoring\n", name);
            return 1; } }
    static void asm_section(char *name, VECTOR(value_t) args, value_t data) {
        if (Section *sec = get(name)) sec->input(args, data); }
    static void process_all() {
        if (sections)
            for (auto &it : *sections)
                it.second->process(); }
    static void output_all(json::map &ctxtJson) {
        if (sections)
            for (auto &it : *sections)
                it.second->output(ctxtJson); }
};

#endif /* _sections_h_ */
