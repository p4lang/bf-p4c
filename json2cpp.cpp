#include <assert.h>
#include <fstream>
#include "escape.h"
#include "indent.h"
#include "json.h"
#include <limits.h>
#include <string.h>

int indent_t::tabsz = 2;

enum { BOTH, DECL_ONLY, DEFN_ONLY } gen_definitions = BOTH,
mod_definitions[2][3] = {
    { BOTH, BOTH, DECL_ONLY },
    { DECL_ONLY, DEFN_ONLY, DEFN_ONLY } };

static bool test_sanity(json::obj *data, std::string name, bool sizes=true) {
    if (json::vector *v = dynamic_cast<json::vector *>(data)) {
        data = 0;
        for (auto &a : *v) {
            if (!data) data = a.get();
            else if (*data != *a) {
                std::cerr << "array element mismatch: " << name << std::endl;
                return false; } }
        return test_sanity(data, name+"[]", sizes); }
    if (json::map *m = dynamic_cast<json::map *>(data)) {
        for (auto &a : *m) {
            if (json::string *key = dynamic_cast<json::string *>(a.first)) {
                if ((*key)[0] == '_') continue;
                for (char ch : *key)
                    if (!isalnum(ch) && ch != '_') {
                        std::cerr << "field not identifier: " << name << '.' << *key << std::endl;
                        return false; }
                if (name.size()) name += '.';
                name += *key;
            } else {
                std::cerr << "field not string: " << name << std::endl;
                return false; }
            if (!test_sanity(a.second.get(), name, sizes)) return false; }
        return true; }
    if (json::number *n = dynamic_cast<json::number *>(data)) {
        if (!sizes ||
            (n->val >= 0 && (size_t)n->val <= sizeof(unsigned long) * CHAR_BIT))
            return true;
        std::cerr << "size out of range: " << name << " " << n->val << std::endl; }
    if (dynamic_cast<json::string *>(data))
        return true;
    return false;
}

static json::obj *get_indexes(json::obj *t, std::vector<int> &indexes) {
    while (json::vector *v = dynamic_cast<json::vector *>(t)) {
        indexes.push_back(v->size());
        t = v->begin()->get(); }
    return t;
}
static /*const*/ json::obj *skip_indexes(const json::obj *t) {
    while (const json::vector *v = dynamic_cast<const json::vector *>(t)) {
        t = v->begin()->get(); }
    return const_cast<json::obj *>(t); // return is const if argument was
}

static json::obj *singleton_obj(json::obj *t, json::string *name) {
    if (json::map *m = dynamic_cast<json::map *>(t))
        if (m->size() == 1 && m->find(name) != m->end()) {
            json::obj *o = m->find(name)->second.get();
            /* FIXME -- could deal with vectors here?  Callers need to be changed */
            if (!dynamic_cast<json::vector *>(o))
                return o; }
    return t;
}

static bool is_singleton(json::map *m) {
    if (m->size() != 1) return false;
    json::obj *o = m->begin()->second.get();
    if (dynamic_cast<json::vector *>(o)) return false;
    if (dynamic_cast<json::map *>(o)) return false;
    return true;
}

static int tabsz = 4;
static bool enable_disable = true;
static bool checked_array = true;

static void gen_emit_method(std::ostream &out, json::map *m, indent_t indent,
                            const std::string &classname, const char *objname,
                            const std::vector<const char *> &nameargs)
{
    out << indent++ << "void ";
    if (gen_definitions == DEFN_ONLY) out << classname << "::";
    out << "emit_json(std::ostream &out, ";
    int i = 0;
    for (auto t : nameargs)
        out << t << "na" << i++ << ", ";
    out << "indent_t indent";
    if (gen_definitions != DEFN_ONLY) out << " = 1";
    out << ") const";
    if (gen_definitions == DECL_ONLY) {
        out << ";" << std::endl;
        return; }
    out << " {" << std::endl;
    if (enable_disable) {
        out << indent++ << "if (disabled_) {" << std::endl;
        out << indent << "out << \"0\";" << std::endl;
        out << indent-- << "return; }" << std::endl; }
    out << indent << "out << '{' << std::endl;" << std::endl;
    bool first = true;
    for (auto &a : *m) {
        if (!first)
            out << indent << "out << \", \\n\";" << std::endl;
        json::string *name = dynamic_cast<json::string *>(a.first);
        if (objname && *name == "_name") {
            if (nameargs.size() > 0) {
                int tmplen = strlen(objname) + nameargs.size()*10 + 32;
                out << indent << "char tmp[" << tmplen << "];" << std::endl;
                out << indent << "snprintf(tmp, sizeof(tmp), \"" << objname << "\"";
                for (size_t i = 0; i < nameargs.size(); i++)
                    out << ", na" << i;
                out << ");" << std::endl; }
            out << indent << "out << indent << \"\\\"_name\\\": \\\"";
            if (nameargs.size() > 0)
                out << "\" << tmp << \"";
            else
                out << objname;
            out << "\\\"\";" << std::endl;
            first = false;
            continue;
        } else if ((*name)[0] == '_') {
            json::string *val = dynamic_cast<json::string *>(a.second.get());
            if (!val) continue;
            out << indent << "out << indent << \"\\\"" << *name << "\\\": \\\""
                << escape(*val) << "\\\"\";" << std::endl;
            first = false;
            continue; }
        out << indent << "out << indent << \"\\\"" << *name << "\\\": \";" << std::endl;
        std::vector<int> indexes;
        json::obj *type = get_indexes(a.second.get(), indexes);
        int index_num = 0;
        for (int idx : indexes) {
            if (enable_disable && checked_array) {
                out << indent++ << "if (" << *name;
                for (int i = 0; i < index_num; i++)
                    out << "[i" << i << ']';
                out << ".disabled()) {" << std::endl;
                out << indent << "out << \"0\";" << std::endl;
                out << indent-1 << "} else {" << std::endl; }
            out << indent << "out << \"[\\n\" << ++indent;" << std::endl;
            out << indent++ << "for (int i" << index_num << " = 0; i" << index_num << " < "
                << idx << "; i" << index_num << "++) { " << std::endl;
            out << indent << "if (i" << index_num << ") out << \", \\n\" << indent;" << std::endl;
            index_num++; }
        json::obj *single = singleton_obj(type, name);
        if (single != type) {
            out << indent << "out << \"{\\n\" << indent+1 << \"\\\"" << *name
                << "\\\": \" << " << *name;
            for (int i = 0; i < index_num; i++)
                out << "[i" << i << ']';
            out << " << '\\n';" << std::endl;
            out << indent << "out << indent << '}';" << std::endl;
        } else if (dynamic_cast<json::map *>(type)) {
            out << indent << *name;
            for (int i = 0; i < index_num; i++)
                out << "[i" << i << ']';
            out << ".emit_json(out, indent+1);" << std::endl;
        } else {
            out << indent << "out << " << *name;
            for (int i = 0; i < index_num; i++)
                out << "[i" << i << ']';
            out << ';' << std::endl; }
        while (--index_num >= 0) {
            out << --indent << "}" << std::endl;
            out << indent << "out << '\\n' << --indent << ']';" << std::endl;
            if (enable_disable && checked_array)
                out << --indent << "}" << std::endl; }
        first = false; }
    out << indent << "out << '\\n' << indent-1 << \"}\";" << std::endl;
    out << --indent << '}' << std::endl;
}

static void gen_fieldname_method(std::ostream &out, json::map *m, indent_t indent,
                                 const std::string &classname)
{
    out << indent++ << "void ";
    if (gen_definitions == DEFN_ONLY) out << classname << "::";
    out << "emit_fieldname(std::ostream &out, const char *addr, const void *end) const";
    if (gen_definitions == DECL_ONLY) {
        out << ";" << std::endl;
        return; }
    out << " {" << std::endl;
    if (!is_singleton(m))
        out << indent << "if ((void *)addr == this && end == this+1) return;" << std::endl;
    bool first = true;
    for (auto it = m->rbegin(); it != m->rend(); it++) {
        std::vector<int> indexes;
        json::string *name = dynamic_cast<json::string *>(it->first);
        if ((*name)[0] == '_') continue;
        json::obj *type = get_indexes(it->second.get(), indexes);
        out << indent;
        if (first) first = false;
        else out << "} else ";
        out << "if (addr >= (char *)&" << *name << ") {" << std::endl;
        out << ++indent << "out << \"." << *name << "\";" << std::endl;
        size_t i = 0;
        for (auto idx : indexes) {
            out << indent << "int i" << i << " = (addr - (char *)&" << *name;
            for (size_t j = 0; j < i; j++)
                out << "[i" << j << ']';
            out << "[0])/sizeof(" << *name;
            for (size_t j = 0; j <= i; j++)
                out << "[0]";
            out << ");" << std::endl;;
            if (idx > 1) {
                out << indent << "if (i" << i << " == 0 && 1 + &" << *name;
                    for (size_t j = 0; j < i; j++)
                        out << "[i" << j << ']';
                    out << " == end) return;" << std::endl; }
            out << indent << "out << '[' << i" << i << " << ']';" << std::endl;
            i++; }
        json::obj *single = singleton_obj(type, name);
        if (dynamic_cast<json::map *>(single)) {
            out << indent << *name;
            for (size_t i = 0; i < indexes.size(); i++)
                out << "[i" << i << ']';
            out << ".emit_fieldname" << "(out, addr, end);" << std::endl; }
        indent--; }
    out << indent-- << "}" << std::endl;
    out << indent << "}" << std::endl;
}

static void gen_unpack_method(std::ostream &out, json::map *m, indent_t indent,
                              const std::string &classname)
{
    out << indent++ << "int ";
    if (gen_definitions == DEFN_ONLY) out << classname << "::";
    out << "unpack_json(json::obj *obj)";
    if (gen_definitions == DECL_ONLY) {
        out << ";" << std::endl;
        return; }
    out << " {" << std::endl;
    out << indent << "int rv = 0;" << std::endl;
    out << indent << "json::map *m = dynamic_cast<json::map *>(obj);" << std::endl;
    out << indent << "if (!m) return -1;" << std::endl;
    for (auto &a : *m) {
        std::vector<int> indexes;
        json::string *name = dynamic_cast<json::string *>(a.first);
        if ((*name)[0] == '_') continue;
        json::obj *type = get_indexes(a.second.get(), indexes);
        int index_num = 0;
        for (int idx : indexes) {
            out << indent++ << "if (json::vector *v" << index_num
                << " = dynamic_cast<json::vector *>(";
            if (index_num) {
                out << "(*v" << (index_num-1) << ")[i" << (index_num-1) << "].get()";
            } else out << "(*m)[" << name << "].get()";
            out << "))" << std::endl;
            out << indent++ << "for (int i" << index_num << " = 0; i" << index_num << " < "
                << idx << "; i" << index_num << "++)" << std::endl;
            index_num++; }
        json::obj *single = singleton_obj(type, name);
        if (single != type) {
            out << indent++ << "if (json::map *s = dynamic_cast<json::map *>(";
            if (index_num) {
                out << "(*v" << (index_num-1) << ")[i" << (index_num-1) << "].get()";
            } else out << "(*m)[" << name << "].get()";
            out << "))" << std::endl;
            out << indent++ << "if (json::number *n = dynamic_cast<json::number *>((*s)["
                << name << "].get()))" << std::endl;
            out << indent << *name;
            for (int i = 0; i < index_num; i++)
                out << "[i" << i << ']';
            out << " = n->val;" << std::endl;
            out << --indent << "else rv = -1;" << std::endl;
            out << --indent << "else rv = -1;" << std::endl;
        } else if (dynamic_cast<json::map *>(type)) {
            out << indent << "rv |= " << *name;
            for (int i = 0; i < index_num; i++)
                out << "[i" << i << ']';
            out << ".unpack_json(";
            if (index_num) {
                out << "(*v" << (index_num-1) << ")[i" << (index_num-1) << "].get()";
            } else out << "(*m)[" << name << "].get()";
            out << ");" << std::endl;
        } else {
            const char *jtype = "json::number", *access = "n->val";
            if (dynamic_cast<json::string *>(type))
                jtype = "json::string", access = "*n";
            out << indent++ << "if (" << jtype << " *n = dynamic_cast<" << jtype << " *>(";
            if (index_num)
                out << "(*v" << (index_num-1) << ")[i" << (index_num-1) << "].get()";
            else out << "(*m)[" << name << "].get()";
            out << ")) {" << std::endl;
            out << indent << *name;
            for (int i = 0; i < index_num; i++)
                out << "[i" << i << ']';
            out << " = " << access << ";" << std::endl;
            if (dynamic_cast<json::string *>(type)) {
                out << indent++ << "else if (json::number *n = dynamic_cast<json::number *>(";
                if (index_num)
                    out << "(*v" << (index_num-1) << ")[i" << (index_num-1) << "].get()";
                else out << "(*m)[" << name << "].get()";
                out << ")) {" << std::endl;
                out << indent << "if (n->v) rv = -1;" << std::endl; }
            out << --indent << "} else rv = -1;" << std::endl; }
        while (--index_num >= 0)
            out << ----indent << "else rv = -1;" << std::endl;
    }
    out << indent << "return rv;" << std::endl;
    out << --indent << '}' << std::endl;
}

static void gen_dump_unread_method(std::ostream &out, json::map *m,
                                   indent_t indent,
                                   const std::string &classname)
{
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wunused-variable"
    out << indent++ << "void ";
    if (gen_definitions == DEFN_ONLY) out << classname << "::";
    out << "dump_unread(std::ostream &out, prefix *pfx) const";
    if (gen_definitions == DECL_ONLY) {
        out << ";" << std::endl;
        return; }
    out << " {" << std::endl;
    bool need_lpfx = true;
    for (auto &a : *m) {
        std::vector<int> indexes;
        json::string *name = dynamic_cast<json::string *>(a.first);
        if ((*name)[0] == '_') continue;
        json::obj *type = get_indexes(a.second.get(), indexes);
        json::obj *single = singleton_obj(type, name);
        if (dynamic_cast<json::map *>(single)) {
            if (need_lpfx) {
                out << indent << "prefix lpfx(pfx, 0);" << std::endl;
                need_lpfx = false; }
            out << indent << "lpfx.str = \"" << *name;
            for (int idx : indexes) out << "[" << idx << "]";
            out << "\";" << std::endl;
            out << indent << *name;
            for (int idx : indexes) out << "[0]";
            out << ".dump_unread(out, &lpfx);" << std::endl;
        } else {
            out << indent << "if (!" << *name;
            for (int idx : indexes) out << "[0]";
            out << ".read) out << pfx << \"." << *name;
            for (int idx : indexes) out << "[" << idx << "]";
            out << "\" << std::endl;" << std::endl;
        }
    }
    out << --indent << '}' << std::endl;
#pragma GCC diagnostic pop
}

static void gen_modified_method(std::ostream &out, json::map *m, indent_t indent,
                                const std::string &classname)
{
    out << indent++ << "bool ";
    if (gen_definitions == DEFN_ONLY) out << classname << "::";
    out << "modified() const";
    if (gen_definitions == DECL_ONLY) {
        out << ";" << std::endl;
        return; }
    out << " {" << std::endl;
    for (auto &a : *m) {
        json::string *name = dynamic_cast<json::string *>(a.first);
        if ((*name)[0] == '_') continue;
        if (!checked_array) {
            std::vector<int> indexes;
            get_indexes(a.second.get(), indexes);
            if (!indexes.empty()) {
                int index_num = 0;
                for (int idx : indexes) {
                    out << indent++ << "for (int i" << index_num << " = 0; i" << index_num << " < "
                        << idx << "; i" << index_num << "++)" << std::endl;
                    index_num++; }
                out << indent << "if (" << *name;
                for (unsigned i = 0; i < indexes.size(); i++)
                    out << "[i" << i << ']';
                out << ".modified()) return true;" << std::endl;
                indent -= indexes.size();
                continue; } }
        out << indent << "if (" << *name << ".modified()) return true;" << std::endl; }
    out << indent << "return false;" << std::endl;
    out << --indent << '}' << std::endl;
}

static void gen_disable_method(std::ostream &out, json::map *m, indent_t indent,
                               const std::string &classname)
{
    out << indent++ << "void ";
    if (gen_definitions == DEFN_ONLY) out << classname << "::";
    out << "disable()";
    if (gen_definitions == DECL_ONLY) {
        out << ";" << std::endl;
        return; }
    out << " {" << std::endl;
    out << indent++ << "if (modified()) {" << std::endl;
    out << indent << "std::cerr << \"Disabling modified record \";" << std::endl;
    out << indent << "print_regname(std::cerr, this, this+1);" << std::endl;
    out << indent-- << "std::cerr << std::endl; }" << std::endl;
    out << indent << "disabled_ = true;" << std::endl;
    out << --indent << '}' << std::endl;
}

static void gen_disable_if_zero_method(std::ostream &out, json::map *m, indent_t indent,
                                       const std::string &classname)
{
    out << indent++ << "bool ";
    if (gen_definitions == DEFN_ONLY) out << classname << "::";
    out << "disable_if_zero()";
    if (gen_definitions == DECL_ONLY) {
        out << ";" << std::endl;
        return; }
    out << " {" << std::endl;
    out << indent << "bool rv = true;" << std::endl;
    for (auto &a : *m) {
        json::string *name = dynamic_cast<json::string *>(a.first);
        if ((*name)[0] == '_') continue;
        if (!checked_array) {
            std::vector<int> indexes;
            get_indexes(a.second.get(), indexes);
            if (!indexes.empty()) {
                int index_num = 0;
                for (int idx : indexes) {
                    out << indent++ << "for (int i" << index_num << " = 0; i" << index_num << " < "
                        << idx << "; i" << index_num << "++)" << std::endl;
                    index_num++; }
                out << indent << "if (!" << *name;
                for (unsigned i = 0; i < indexes.size(); i++)
                    out << "[i" << i << ']';
                out << ".disable_if_zero()) rv = false;" << std::endl;
                indent -= indexes.size();
                continue; } }
        out << indent << "if (!" << *name << ".disable_if_zero()) rv = false;" << std::endl; }
    out << indent << "if (rv) disabled_ = true;" << std::endl;
    out << indent << "return rv;" << std::endl;
    out << --indent << '}' << std::endl;
}

static bool delete_copy = false;
static bool gen_emit = true;
static bool gen_fieldname = true;
static bool gen_unpack = true;
static bool gen_unread = true;
static std::map<std::string, json::map *> global_types;

static bool need_ctor(const json::map *m_init) {
    if (!m_init) return false;
    for (auto &a : *m_init) {
        json::string *name = dynamic_cast<json::string *>(a.first);
        auto *n_init = dynamic_cast<json::number *>
            (singleton_obj(skip_indexes(a.second.get()), name));
        if (n_init && n_init->val) return true; }
    return false;
}

static void gen_ctor(std::ostream &out, const std::string &namestr, const json::map *m_init,
                     bool enable_disable, indent_t indent) {
    out << indent << namestr << "() : ";
    bool first = true;
    if (enable_disable) {
        out << "disabled_(false)";
        first = false; }
    if (m_init) for (auto &a : *m_init) {
        json::string *name = dynamic_cast<json::string *>(a.first);
        if ((*name)[0] == '_') continue;
        auto *n_init = dynamic_cast<json::number *>
            (singleton_obj(skip_indexes(a.second.get()), name));
        if (n_init && n_init->val) {
            if (first) first = false; else out << ", ";
            out << *name << '(' << n_init->val << ')'; } }
    out << " {}" << std::endl;
}

static void gen_type(std::ostream &out, const std::string &parent,
                     const char *name, json::obj *t, const json::obj *init,
                     indent_t indent = indent_t())
{
    if (json::map *m = dynamic_cast<json::map *>(t)) {
        const json::map *m_init = dynamic_cast<const json::map *>(init);
        std::vector<const char *> nameargs;
        std::string namestr;
        if (name) {
            for (const char *c = name; *c; c++) {
                if (isalnum(*c) || *c == '_') namestr += *c;
                else if (*c == '.') namestr += '_';
                else if (*c == '%') {
                    while (isdigit(*++c));
                    bool islong = *c == 'l';
                    if (islong) c++;
                    switch (*c) {
                    case 'd': case 'i': case 'u': case 'x':
                        nameargs.push_back(islong ? "long " : "int ");
                        break;
                    case 'e': case 'f': case 'g':
                        nameargs.push_back(islong ? "double " : "float ");
                        break;
                    case 's':
                        nameargs.push_back("const char *");
                        break;
                    default:
                        std::cerr << "Unknown conversion '%" << *c << "' in name format string "
                                  << "-- ignoring" << std::endl;
                        break; }
                } else
                    std::cerr << "Bogus character '" << *c << "' in name format string "
                              << "-- ignoring" << std::endl; } }
        std::string classname = parent;
        if (!classname.empty()) classname += "::";
        classname += namestr;
        if (gen_definitions != DEFN_ONLY) {
            indent++;
            out << "struct " << namestr << " {" << std::endl;
            if (enable_disable)
                out << indent << "bool disabled_;" << std::endl;
            if (enable_disable || need_ctor(m_init))
                gen_ctor(out, namestr, m_init, enable_disable, indent); }
        for (auto &a : *m) {
            std::vector<int> indexes;
            json::string *name = dynamic_cast<json::string *>(a.first);
            if ((*name)[0] == '_') continue;
            init = m_init ? m_init->at(name).get() : 0;
            json::obj *type = get_indexes(a.second.get(), indexes);
            type = singleton_obj(type, name);
            init = singleton_obj(skip_indexes(init), name);
            bool notclass = !dynamic_cast<json::map *>(type);
            bool isglobal = global_types.count(*name) > 0;
            if (gen_definitions != DEFN_ONLY) {
                out << indent;
                if (checked_array && notclass && !indexes.empty())
                    for (int idx : indexes)
                        out << "checked_array<" << idx << ", "; }
            if (!isglobal)
                gen_type(out, classname, ("_" + *name).c_str(), type, init, indent);
            if (gen_definitions != DEFN_ONLY) {
                if (checked_array && !indexes.empty()) {
                    if (!notclass) {
                        if (!isglobal)
                            out << ";" << std::endl << indent;
                        for (int idx : indexes)
                            out << "checked_array<" << idx << ", ";
                        out << (isglobal ? "::" : "_") << *name; }
                    for (size_t i = 0; i < indexes.size(); i++) out << '>';
                    out << ' ' << *name << ";" << std::endl;
                } else {
                    out << ' ' << *name;
                    for (int idx : indexes) out << '[' << idx << ']';
                    out << ";" << std::endl; } } }
        if (delete_copy && gen_definitions != DEFN_ONLY) {
            if (!enable_disable && !need_ctor(m_init))
                out << indent << namestr << "() = default;" << std::endl;
            out << indent << namestr << "(const " << namestr << " &) = delete;" << std::endl;
            out << indent << namestr << "(" << namestr << " &&) = delete;" << std::endl; }
        if (gen_emit)
            gen_emit_method(out, m, indent, classname, name, nameargs);
        if (gen_fieldname) gen_fieldname_method(out, m, indent, classname);
        if (gen_unpack) gen_unpack_method(out, m, indent, classname);
        if (gen_unread) gen_dump_unread_method(out, m, indent, classname);
        if (enable_disable) {
            gen_modified_method(out, m, indent, classname);
            gen_disable_method(out, m, indent, classname);
            gen_disable_if_zero_method(out, m, indent, classname); }
        if (gen_definitions != DEFN_ONLY) {
            out << --indent << '}'; }
    } else if (json::number *n = dynamic_cast<json::number *>(t)) {
        //const json::number *n_init = dynamic_cast<const json::number *>(init);
        //if (n_init && n_init->val)
        //    std::clog << "init value " << n_init->val << std::endl;
        if (gen_definitions != DEFN_ONLY)
            out << "ubits<" << (n->val ? n->val : 32) << ">";
    } else if (dynamic_cast<json::string *>(t)) {
        if (gen_definitions != DEFN_ONLY)
            out << "ustring";
    } else
        assert(0);
}

static int gen_global_types(std::ostream &out, json::obj *t, const json::obj *init)
{
    int rv = 0;
    if (json::map *m = dynamic_cast<json::map *>(t)) {
        const json::map *m_init = dynamic_cast<const json::map *>(init);
        for (auto &a : *m) {
            std::vector<int> indexes;
            json::string *name = dynamic_cast<json::string *>(a.first);
            if ((*name)[0] == '_') continue;
            init = m_init ? m_init->at(name).get() : 0;
            json::obj *type = get_indexes(a.second.get(), indexes);
            type = singleton_obj(type, name);
            init = singleton_obj(skip_indexes(init), name);
            if (json::map *cl = dynamic_cast<json::map *>(type)) {
                rv |= gen_global_types(out, type, init);
                auto it = global_types.find(*name);
                if (it == global_types.end())
                    continue;
                if (it->second) {
                    if (*it->second != *cl) {
                        std::cerr << "Inconsitent definition of type " << name << std::endl;
                        rv = -1; }
                } else {
                    it->second = cl;
                    gen_type(out, "", name->c_str(), cl, init);
                    out << ";" << std::endl; } } } }
    return rv;
}

int main(int ac, char **av) {
    bool gen_hdrs = true;
    int test = 0;
    int error = 0;
    const char *name = 0;
    const char *declare = 0;
    std::vector<const char *> includes;
    json::obj *initvals = 0;
    for (int i = 1; i < ac; i++) {
        if (av[i][0] == '-' || av[i][0] == '+') {
            bool flag = av[i][0] == '+';
            for (char *arg = av[i]+1; *arg;)
                switch(*arg++) {
                case 'a': checked_array = flag; break;
                case 'c': {
                    std::ifstream file(av[++i]);
                    delete initvals;
                    file >> initvals;
                    if (!file || !test_sanity(initvals, "", false)) {
                        std::cerr << av[i] << ": not valid template" << std::endl;
                        error = 1; }
                    break; }
                case 'd': declare = av[++i]; break;
                case 'D': gen_definitions = mod_definitions[flag][gen_definitions];
                case 'e': gen_emit = flag; break;
                case 'f': gen_fieldname = flag; break;
                case 'g': global_types[av[++i]] = 0; break;
                case 'h': gen_hdrs = flag; break;
                case 'I': includes.push_back(av[++i]); break;
                case 'n': name = av[++i]; break;
                case 'r': gen_unread = flag; break;
                case 't': test = *arg++; break;
                case 'u': gen_unpack = flag; break;
                case 'x': delete_copy = flag; break;
                case 'X': enable_disable = flag; break;
                case 'i':
                    if (int v = strtol(arg, &arg, 10)) {
                        if (v > 0 && v < 20) {
                            tabsz = v;
                            break; } }
                    // fall through
                default:
                    std::cerr << "Unknown option -" << arg[-1] << std::endl;
                    std::cerr << "usage: " << av[0]
                              << " -/+dDefg:hi?I:n:rut?uxX files"
                              << std::endl;
                    exit(1); }
            continue; }
        std::ifstream file(av[i]);
        json::obj *data = 0;
        file >> data;
        if (!file || !test_sanity(data, "")) {
            std::cerr << av[i] << ": not valid template" << std::endl;
            name = declare = 0;
            error = 1;
            continue; }
        std::cout << "/* Autogenerated from " << av[i] << " -- DO NOT EDIT */" << std::endl;
        if (name && !*name && !declare)
            name = 0;
        if (!name && gen_definitions != BOTH) {
            std::cerr << "+D requires -n option" << std::endl;
            exit(1); }
        for (auto n : includes)
            std::cout << "#include \"" << n << '"' << std::endl;
        if (gen_hdrs) {
            if (gen_emit || gen_fieldname || gen_unread || test)
                std::cout << "#include \"indent.h\"" << std::endl;
            if (gen_unpack || test)
                std::cout << "#include \"json.h\"" << std::endl;
            if (checked_array)
                std::cout << "#include \"checked_array.h\"" << std::endl;
            std::cout << "#include \"ubits.h\"" << std::endl;
            std::cout << std::endl;
            gen_hdrs = false; }
        if (!global_types.empty() && gen_global_types(std::cout, data, initvals) < 0)
            exit(1);
        gen_type(std::cout, "", name, data, initvals);
        if (test && !declare) declare = "table";
        if (declare) std::cout << " " << declare;
        std::cout << ";" << std::endl;
        std::cout << std::endl;
        switch (test) {
        case 0:
            break;
        case '1':
            std::cout << "int main() {" << std::endl;
            std::cout << "  json::obj *data;" << std::endl;
            std::cout << "  std::cin >> data;" << std::endl;
            std::cout << "  if (!std::cin || " << declare << ".unpack_json(data))" << std::endl;
            std::cout << "    return 1;" << std::endl;
            std::cout << "  " << declare << ".emit_json(std::cout, ";
            if (name)
                for (const char *p = strchr(name, '%'); p; p = strchr(p+1, '%'))
                    std::cout << "0, ";
            std::cout << "indent_t(1));" << std::endl;
            std::cout << "  return 0;" << std::endl;
            std::cout << "}" << std::endl;
            break;
        case '2':
            std::cout << "int main() {" << std::endl;
            std::cout << "  " << declare << ".dump_unread(std::cout, 0);" << std::endl;
            std::cout << "  return 0;" << std::endl;
            std::cout << "}" << std::endl;
            break;
        default:
            std::cerr << "Unknown test -t" << (char)test << std::endl;
            break; }
        global_types.clear();
        delete data;
        delete initvals;
        initvals = 0;
        name = declare = 0; }
    delete initvals;
    return error;
}
