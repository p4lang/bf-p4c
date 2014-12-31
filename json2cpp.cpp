#include <assert.h>
#include <fstream>
#include <iomanip>
#include "json.h"
#include <limits.h>
#include <string.h>

enum { BOTH, DECL_ONLY, DEFN_ONLY } gen_definitions = BOTH,
mod_definitions[2][3] = {
    { BOTH, BOTH, DECL_ONLY },
    { DECL_ONLY, DEFN_ONLY, DEFN_ONLY } };

static bool test_sanity(json::obj *data, std::string name) {
    if (json::vector *v = dynamic_cast<json::vector *>(data)) {
	data = 0;
	for (auto &a : *v) {
	    if (!data) data = a.get();
	    else if (*data != *a) {
		std::cerr << "array element mismatch: " << name << std::endl;
		return false; } }
	return test_sanity(data, name+"[]"); }
    if (json::map *m = dynamic_cast<json::map *>(data)) {
	for (auto &a : *m) {
	    if (json::string *key = dynamic_cast<json::string *>(a.first)) {
		if ((*key)[0] == '_') continue;
		for (char ch : *key)
		    if (!isalnum(ch) && ch != '_') {
			std::cerr << "field not identifier: " << name << '.'
				  << *key << std::endl;
			return false; }
		if (name.size()) name += '.';
		name += *key;
	    } else {
		std::cerr << "field not string: " << name << std::endl;
		return false; }
	    if (!test_sanity(a.second.get(), name)) return false; }
	return true; }
    if (json::number *n = dynamic_cast<json::number *>(data)) {
	if (n->val >= 0 && (size_t)n->val <= sizeof(unsigned long) * CHAR_BIT)
	    return true;
	std::cerr << "size out of range: " << name << " " << n->val
		   << std::endl; }
    return false;
}

static json::obj *get_indexes(json::obj *t, std::vector<int> &indexes) {
    while (json::vector *v = dynamic_cast<json::vector *>(t)) {
	indexes.push_back(v->size());
	t = v->begin()->get(); }
    return t;
}

static json::obj *singleton_obj(json::obj *t, json::string *name) {
    if (json::map *m = dynamic_cast<json::map *>(t))
	if (m->size() == 1 && m->find(name) != m->end()) {
            json::obj *o = m->find(name)->second.get();
            /* FIXME -- could deal with vectors here?  Callers need to be
             * changed */
            if (!dynamic_cast<json::vector *>(o))
                return o; }
    return t;
}

static int tabsz = 4;

static void gen_emit_method(std::ostream &out, json::map *m, int indent,
                            const std::string &classname, const char *objname,
                            int nameargs)
{
    out << std::setw(2*indent++) << "" << "void ";
    if (gen_definitions == DEFN_ONLY) out << classname << "::";
    out << "emit_json(std::ostream &out, ";
    for (int i = 0; i < nameargs; i++)
        out << "int na" << i << ", ";
    out << "int indent";
    if (gen_definitions != DEFN_ONLY) out << "=1";
    out << ')';
    if (gen_definitions == DECL_ONLY) {
        out << ";" << std::endl;
        return; }
    out << " {" << std::endl;
    out << std::setw(2*indent) << "" << "out << '{' << std::endl;"
	<< std::endl;
    bool first = true;
    for (auto &a : *m) {
	if (!first)
	    out << std::setw(2*indent) << "" << "out << \", \\n\";"
		<< std::endl;
	json::string *name = dynamic_cast<json::string *>(a.first);
        if (objname && *name == "_name") {
            if (nameargs > 0) {
                out << std::setw(2*indent) << "" << "char tmp["
                    << (strlen(objname) + nameargs*10) << "];" << std::endl;
                out << std::setw(2*indent) << "" << "sprintf(tmp, \""
                    << objname << "\"";
                for (int i = 0; i < nameargs; i++)
                    out << ", na" << i;
                out << ");" << std::endl; }
            out << std::setw(2*indent) << "" << "out << std::setw(" << tabsz
                << "*indent)" << " << \"\" << \"\\\"_name\\\": \\\"";
            if (nameargs > 0)
                out << "\" << tmp << \"";
            else
                out << objname;
            out << "\\\"\";" << std::endl;
            first = false;
            continue;
	} else if ((*name)[0] == '_') {
            json::string *val = dynamic_cast<json::string *>(a.second.get());
            if (!val) continue;
            out << std::setw(2*indent) << "" << "out << std::setw(" << tabsz
                << "*indent)" << " << \"\" << \"\\\"" << *name << "\\\": \\\""
                << *val << "\\\"\";" << std::endl;
            first = false;
            continue; }
	out << std::setw(2*indent) << "" << "out << std::setw(" << tabsz
            << "*indent)" << " << \"\" << \"\\\"" << *name << "\\\": \";"
            << std::endl;
	std::vector<int> indexes;
	json::obj *type = get_indexes(a.second.get(), indexes);
	int index_num = 0;
	for (int idx : indexes) {
	    out << std::setw(2*indent) << "" << "out << \"[\\n\" << "
		<< "std::setw(" << tabsz << "*++indent) << \"\";" << std::endl;
	    out << std::setw(2*indent++) << "" << "for (int i" << index_num
		<< " = 0; i" << index_num << " < " << idx << "; i"
		<< index_num << "++) { " << std::endl;
	    out << std::setw(2*indent) << "" << "if (i" << index_num
		<< ") out << \", \\n\" << std::setw(" << tabsz
                << "*indent) << \"\";" << std::endl;
	    index_num++; }
	json::obj *single = singleton_obj(type, name);
	if (single != type) {
	    out << std::setw(2*indent) << "" << "out << \"{\\n\" << "
		<< "std::setw(" << tabsz << "*(indent+1)) << \"\" << \"\\\""
                << *name << "\\\": \" << " << *name;
	    for (int i = 0; i < index_num; i++)
		out << "[i" << i << ']';
	    out << " << '\\n';" << std::endl;
	    out << std::setw(2*indent) << "" << "out << " << "std::setw("
                << tabsz << "*indent) << \"\" << '}';" << std::endl;
	} else if (dynamic_cast<json::map *>(type)) {
	    out << std::setw(2*indent) << "" << *name;
	    for (int i = 0; i < index_num; i++)
		out << "[i" << i << ']';
	    out << ".emit_json" << "(out, indent+1);" << std::endl;
	} else {
	    out << std::setw(2*indent) << "" << "out << " << *name;
	    for (int i = 0; i < index_num; i++)
		out << "[i" << i << ']';
	    out << ';' << std::endl; }
	while (--index_num >= 0) {
	    out << std::setw(2*--indent) << "" << "}" << std::endl;
	    out << std::setw(2*indent) << "" << "out << '\\n' << "
		<< "std::setw(" << tabsz << "*--indent) << \"\" << ']';"
                << std::endl; }
	first = false; }
    out << std::setw(2*indent) << "" << "out << '\\n' << " << "std::setw("
        << tabsz << "*(indent-1)) << \"\" << \"}\";" << std::endl;
    out << std::setw(2*--indent) << "" << '}' << std::endl;
}

static void gen_fieldname_method(std::ostream &out, json::map *m, int indent,
                                 const std::string &classname)
{
    out << std::setw(2*indent++) << "" << "void ";
    if (gen_definitions == DEFN_ONLY) out << classname << "::";
    out << " emit_fieldname(std::ostream &out, " << "const char *addr)";
    if (gen_definitions == DECL_ONLY) {
        out << ";" << std::endl;
        return; }
    out << " {" << std::endl;
    bool first = true;
    for (auto it = m->rbegin(); it != m->rend(); it++) {
	std::vector<int> indexes;
	json::string *name = dynamic_cast<json::string *>(it->first);
	if ((*name)[0] == '_') continue;
	json::obj *type = get_indexes(it->second.get(), indexes);
        out << std::setw(2*indent) << "";
        if (first) first = false;
        else out << "} else ";
        out << "if (addr >= (char *)&" << *name << ") {" << std::endl;
        out << std::setw(2*++indent) << "" << "out << \"." << *name << "\";"
            << std::endl;
        for (size_t i = 0; i < indexes.size(); i++) {
            out << std::setw(2*indent) << "" << "int i" << i
                << " = (addr - (char *)&" << *name;
            for (size_t j = 0; j < i; j++)
                out << "[i" << j << ']';
            out << ")/sizeof(" << *name;
            for (size_t j = 0; j <= i; j++)
                out << "[0]";
            out << ");" << std::endl;;
            out << std::setw(2*indent) << "" << "out << '[' << i" << i
                << " << ']';" << std::endl; }
	json::obj *single = singleton_obj(type, name);
	if (dynamic_cast<json::map *>(single)) {
	    out << std::setw(2*indent) << "" << *name;
	    for (size_t i = 0; i < indexes.size(); i++)
		out << "[i" << i << ']';
	    out << ".emit_fieldname" << "(out, addr);" << std::endl; }
        indent--; }
    out << std::setw(2*indent--) << "" << "}" << std::endl;
    out << std::setw(2*indent) << "" << "}" << std::endl;
}

static void gen_unpack_method(std::ostream &out, json::map *m, int indent,
                              const std::string &classname)
{
    out << std::setw(2*indent++) << "" << "int ";
    if (gen_definitions == DEFN_ONLY) out << classname << "::";
    out << "unpack_json(json::obj *obj)";
    if (gen_definitions == DECL_ONLY) {
        out << ";" << std::endl;
        return; }
    out << " {" << std::endl;
    out << std::setw(2*indent) << "" << "int rv = 0;" << std::endl;
    out << std::setw(2*indent) << ""
	<< "json::map *m = dynamic_cast<json::map *>(obj);" << std::endl;
    out << std::setw(2*indent) << "" << "if (!m) return -1;" << std::endl;
    for (auto &a : *m) {
	std::vector<int> indexes;
	json::string *name = dynamic_cast<json::string *>(a.first);
	if ((*name)[0] == '_') continue;
	json::obj *type = get_indexes(a.second.get(), indexes);
	int index_num = 0;
	for (int idx : indexes) {
	    out << std::setw(2*indent++) << "" << "if (json::vector *v"
		<< index_num << " = dynamic_cast<json::vector *>(";
	    if (index_num) {
                out << "(*v" << (index_num-1) << ")[i" << (index_num-1)
                    << "].get()";
	    } else out << "(*m)[" << name << "]";
	    out << "))" << std::endl;
	    out << std::setw(2*indent++) << "" << "for (int i" << index_num
                << " = 0; i" << index_num << " < " << idx << "; i" << index_num
                << "++)" << std::endl;
	    index_num++; }
	json::obj *single = singleton_obj(type, name);
	if (single != type) {
	    out << std::setw(2*indent++) << ""
		<< "if (json::map *s = dynamic_cast<json::map *>(";
	    if (index_num) {
                out << "(*v" << (index_num-1) << ")[i" << (index_num-1)
                    << "].get()";
	    } else out << "(*m)[" << name << "]";
	    out << "))" << std::endl;
	    out << std::setw(2*indent++) << ""
		<< "if (json::number *n = dynamic_cast<json::number *>((*s)["
		<< name << "]))" << std::endl;
	    out << std::setw(2*indent) << "" << *name;
	    for (int i = 0; i < index_num; i++)
		out << "[i" << i << ']';
	    out << " = n->val;" << std::endl;
	    out << std::setw(2*--indent) << "" << "else rv = -1;" << std::endl;
	    out << std::setw(2*--indent) << "" << "else rv = -1;" << std::endl;
	} else if (dynamic_cast<json::map *>(type)) {
	    out << std::setw(2*indent) << "" << "rv |= " << *name;
	    for (int i = 0; i < index_num; i++)
		out << "[i" << i << ']';
	    out << ".unpack_json(";
	    if (index_num) {
                out << "(*v" << (index_num-1) << ")[i" << (index_num-1)
                    << "].get()";
	    } else out << "(*m)[" << name << "]";
	    out << ");" << std::endl;
	} else {
	    out << std::setw(2*indent++) << ""
		<< "if (json::number *n = dynamic_cast<json::number *>(";
	    if (index_num) {
                out << "(*v" << (index_num-1) << ")[i" << (index_num-1)
                    << "].get()";
	    } else out << "(*m)[" << name << "]";
	    out << "))" << std::endl;
	    out << std::setw(2*indent) << "" << *name;
	    for (int i = 0; i < index_num; i++)
		out << "[i" << i << ']';
	    out << " = n->val;" << std::endl;
	    out << std::setw(2*--indent) << "" << "else rv = -1;" << std::endl;
	}
	while (--index_num >= 0) {
	    indent -= 2;
	    out << std::setw(2*indent) << "" << "else rv = -1;" << std::endl;
	}
    }
    out << std::setw(2*indent) << "" << "return rv;" << std::endl;
    out << std::setw(2*--indent) << "" << '}' << std::endl;
}

static void gen_dump_unread_method(std::ostream &out, json::map *m, int indent,
                                   const std::string &classname)
{
#pragma GCC diagnostic ignored "-Wunused-variable"
    out << std::setw(2*indent++) << "" << "void ";
    if (gen_definitions == DEFN_ONLY) out << classname << "::";
    out << "dump_unread(std::ostream &out, prefix *pfx)";
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
                out << std::setw(2*indent) << "" << "prefix lpfx(pfx, 0);"
                    << std::endl;
                need_lpfx = false; }
	    out << std::setw(2*indent) << "" << "lpfx.str = \"" << *name;
            for (int idx : indexes) out << "[" << idx << "]";
            out << "\";" << std::endl;
	    out << std::setw(2*indent) << "" << *name;
            for (int idx : indexes) out << "[0]";
            out << ".dump_unread(out, &lpfx);" << std::endl;
        } else {
	    out << std::setw(2*indent) << "" << "if (!" << *name;
            for (int idx : indexes) out << "[0]";
            out << ".read) out << pfx << \"." << *name;
            for (int idx : indexes) out << "[" << idx << "]";
            out << "\" << std::endl;" << std::endl;
        }
    }
    out << std::setw(2*--indent) << "" << '}' << std::endl;
#pragma GCC diagnostic pop
}

bool gen_emit = true;
bool gen_fieldname = true;
bool gen_unpack = true;
bool gen_unread = true;

static void gen_type(std::ostream &out, const std::string &parent,
                     const char *name, json::obj *t, int indent)
{
    if (json::map *m = dynamic_cast<json::map *>(t)) {
        int nameargs = 0;
        std::string namestr;
        if (name) {
            for (const char *c = name; *c; c++) {
                if (isalnum(*c) || *c == '_') namestr += *c;
                else if (*c == '.') namestr += '_';
                else {
                    if (*c == '%')
                        nameargs++;
                    break; } } }
        std::string classname = parent;
        if (!classname.empty()) classname += "::";
        classname += namestr;
        if (gen_definitions != DEFN_ONLY) {
            indent++;
            out << "struct " << namestr << " {" << std::endl; }
        for (auto &a : *m) {
            std::vector<int> indexes;
            json::string *name = dynamic_cast<json::string *>(a.first);
            if ((*name)[0] == '_') continue;
            json::obj *type = get_indexes(a.second.get(), indexes);
            type = singleton_obj(type, name);
            if (gen_definitions != DEFN_ONLY)
                out << std::setw(2*indent) << "";
            gen_type(out, classname, ("_" + *name).c_str(), type, indent);
            if (gen_definitions != DEFN_ONLY) {
                out << ' ' << *name;
                for (int idx : indexes) out << '[' << idx << ']';
                out << ";" << std::endl; } }
        if (gen_emit)
            gen_emit_method(out, m, indent, classname, name, nameargs);
        if (gen_fieldname) gen_fieldname_method(out, m, indent, classname);
        if (gen_unpack) gen_unpack_method(out, m, indent, classname);
        if (gen_unread) gen_dump_unread_method(out, m, indent, classname);
        if (gen_definitions != DEFN_ONLY) {
            out << std::setw(2*--indent) << "" << '}'; }
    } else if (json::number *n = dynamic_cast<json::number *>(t)) {
        if (gen_definitions != DEFN_ONLY)
            out << "ubits<" << (n->val ? n->val : 32) << ">";
    } else
	assert(0);
}

int main(int ac, char **av) {
    bool gen_hdrs = true;
    int test = 0;
    int error = 0;
    const char *name = 0;
    const char *declare = 0;
    std::vector<const char *> includes;
    for (int i = 1; i < ac; i++) {
        if (av[i][0] == '-' || av[i][0] == '+') {
            bool flag = av[i][0] == '+';
            for (char *arg = av[i]+1; *arg;)
                switch(*arg++) {
                case 'd': declare = av[++i]; break;
                case 'D': gen_definitions =
                            mod_definitions[flag][gen_definitions];
                case 'e': gen_emit = flag; break;
                case 'f': gen_fieldname = flag; break;
                case 'h': gen_hdrs = flag; break;
                case 'I': includes.push_back(av[++i]); break;
                case 'n': name = av[++i]; break;
                case 'r': gen_unread = flag; break;
                case 'u': gen_unpack = flag; break;
                case 't': test = *arg++; break;
                case 'i':
                    if (int v = strtol(arg, &arg, 10)) {
                        if (v > 0 && v < 20) {
                            tabsz = v;
                            break; } }
                    // fall through
                default:
                    std::cerr << "Unknown option -" << arg[-1] << std::endl;
                    std::cerr << "usage: " << av[0] << " -/+dehi?nrut? files"
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
        std::cout << "/* Autogenerated from " << av[i] << " -- DO NOT EDIT */"
                  << std::endl;
        if (name && !*name && !declare)
            name = 0;
        if (!name && gen_definitions != BOTH) {
            std::cerr << "+D requires -n option" << std::endl;
            exit(1); }
        for (auto n : includes)
            std::cout << "#include \"" << n << '"' << std::endl;
        if (gen_hdrs) {
            if (gen_emit || gen_fieldname || gen_unread || test) {
                std::cout << "#include <iostream>" << std::endl;
                std::cout << "#include <iomanip>" << std::endl; }
            if (gen_unpack || test)
                std::cout << "#include \"json.h\"" << std::endl;
            std::cout << "#include \"ubits.h\"" << std::endl;
            std::cout << std::endl;
            gen_hdrs = false; }
	gen_type(std::cout, "", name, data, 0);
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
            std::cout << "  if (!std::cin || " << declare
                      << ".unpack_json(data))" << std::endl;
            std::cout << "    return 1;" << std::endl;
            std::cout << "  " << declare << ".emit_json(std::cout, ";
            if (name)
                for (const char *p = strchr(name, '%'); p; p = strchr(p+1, '%'))
                    std::cout << "0, ";
            std::cout << "1);" << std::endl;
            std::cout << "  return 0;" << std::endl;
            std::cout << "}" << std::endl;
            break;
        case '2':
            std::cout << "int main() {" << std::endl;
            std::cout << "  " << declare << ".dump_unread(std::cout, 0);"
                      << std::endl;
            std::cout << "  return 0;" << std::endl;
            std::cout << "}" << std::endl;
            break;
        default:
            std::cerr << "Unknown test -t" << (char)test << std::endl;
            break; }
        name = declare = 0; }
    return error;
}
