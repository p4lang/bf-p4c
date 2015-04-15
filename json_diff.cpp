#include <fstream>
#include <iomanip>
#include "json.h"
#include <set>

static bool show_deletion = true;
static bool show_addition = true;
static const char *list_map_key = 0;
static std::set<std::string> ignore_keys;

bool is_list_map(json::vector *v, const char *key) {
    if (!key) return false;
    for (auto &e : *v)
        if (json::map *m = dynamic_cast<json::map *>(e.get())) {
            if (!m->count(key)) return false;
        } else
            return false;
    return true;
}

bool ignore(json::obj *o) {
    if (json::string *s = dynamic_cast<json::string *>(o))
        if (ignore_keys.count(*s)) return true;
    return false;
}
bool ignore(std::unique_ptr<json::obj> &o) { return ignore(o.get()); }

std::map<json::obj *, json::map *, json::obj::ptrless> build_list_map(json::vector *v, const char *key) {
    std::map<json::obj *, json::map *, json::obj::ptrless> rv;
    assert(key);
    for (auto &e : *v) {
        json::map *m = dynamic_cast<json::map *>(e.get());
        assert(m);
        rv[(*m)[key].get()] = m; }
    return rv;
}

void do_prefix(int indent, const char *prefix) {
    std::cout << '\n' << prefix;
    if (indent) std::cout << std::setw(indent) << ' ' << std::setw(0);
}

void do_output(json::obj *o, int indent, const char *prefix, const char *suffix = "") {
    do_prefix(indent, prefix);
    o->print_on(std::cout, indent, 80-indent, prefix);
    std::cout << suffix;
}

void do_output(int index, json::vector::iterator p, int indent, const char *prefix) {
    do_prefix(indent, prefix);
    std::cout << '[' << index << "] ";
    (*p)->print_on(std::cout, indent, 80-indent, prefix);
}

void do_output(json::map::iterator p, int indent, const char *prefix) {
    do_prefix(indent, prefix);
    p->first->print_on(std::cout, indent, 80-indent, prefix);
    std::cout << ": ";
    p->second->print_on(std::cout, indent, 80-indent, prefix);
}

void do_output(std::map<json::obj *, json::map *, json::obj::ptrless>::iterator p, int indent, const char *prefix) {
    do_prefix(indent, prefix);
    p->first->print_on(std::cout, indent, 80-indent, prefix);
    std::cout << ": ";
    p->second->print_on(std::cout, indent, 80-indent, prefix);
}

bool equiv(json::obj *a, json::obj *b);
bool equiv(std::unique_ptr<json::obj> &a, json::obj *b) {
    return equiv(a.get(), b); }
bool equiv(std::unique_ptr<json::obj> &a, std::unique_ptr<json::obj> &b) {
    return equiv(a.get(), b.get()); }
void print_diff(json::obj *a, json::obj *b, int indent);
void print_diff(std::unique_ptr<json::obj> &a, std::unique_ptr<json::obj> &b, int indent) {
    return print_diff(a.get(), b.get(), indent); }

json::vector::iterator find(json::vector::iterator p, json::vector::iterator end, json::obj *m) {
    while (p < end && !equiv(*p, m)) ++p;
    return p;
}

bool list_map_equiv(json::vector *a, json::vector *b) {
    auto bmap = build_list_map(b, list_map_key);
    for (auto &e : *a) {
        json::map *m = dynamic_cast<json::map *>(e.get());
        json::obj *ekey = (*m)[list_map_key].get();
        if (!bmap.count(ekey)) {
            if (show_deletion && !ignore(ekey)) return false;
            continue; }
        if (!ignore(ekey) && !equiv(m, bmap[ekey])) return false;
        bmap.erase(ekey); }
    if (show_addition)
        for (auto &e : bmap)
            if (!ignore(e.first)) return false;
    return true;
}
void list_map_print_diff(json::vector *a, json::vector *b, int indent) {
    auto amap = build_list_map(a, list_map_key);
    auto bmap = build_list_map(b, list_map_key);
    auto p1 = amap.begin(), p2 = bmap.begin();
    std::cout << " [";
    indent += 2;
    while (p1 != amap.end() && p2 != bmap.end()) {
        if (*p1->first < *p2->first) {
            if (show_deletion && !ignore(p1->first))
                do_output(p1, indent, "-");
            p1++;
            continue; }
        if (*p2->first < *p1->first) {
            if (show_addition && !ignore(p1->first))
                do_output(p2, indent, "+");
            p2++;
            continue; }
        if (!ignore(p1->first) && !equiv(p1->second, p2->second)) {
            do_output(p1->first, indent, " ", ":");
            print_diff(p1->second, p2->second, indent); }
        p1++;
        p2++; }
    if (show_deletion) while (p1 != amap.end()) {
        if (!ignore(p1->first))
            do_output(p1, indent, "-");
        p1++; }
    if (show_addition) while (p2 != bmap.end()) {
        if (!ignore(p2->first))
            do_output(p2, indent, "+");
        p2++; }
    indent -= 2;
    do_prefix(indent, " ");
    std::cout << ']';
}

bool equiv(json::vector *a, json::vector *b) {
    if (is_list_map(a, list_map_key) && is_list_map(b, list_map_key))
        return list_map_equiv(a, b);
    auto p1 = a->begin(), p2 = b->begin();
    while (p1 != a->end() && p2 != b->end()) {
        if (!equiv(*p1, *p2)) {
            auto s1 = find(p1, a->end(), p2->get());
            auto s2 = find(p2, b->end(), p1->get());
            if (typeid(**p1) == typeid(**p2) && p1 - a->begin() == p2 - b->begin() &&
                (s1 - p1 == s2 - p2 || typeid(**p1) == typeid(json::vector) ||
                 typeid(**p1) == typeid(json::map)))
                return false;
            if (s1 - p1 <= s2 - p2) {
                if (show_deletion) return false;
                ++p1;
            } else {
                if (show_addition) return false;
                ++p2; }
        } else {
            ++p1;
            ++p2; } }
    if (p1 != a->end() && show_deletion) return false;
    if (p2 != b->end() && show_addition) return false;
    return true;
}
void print_diff(json::vector *a, json::vector *b, int indent) {
    if (is_list_map(a, list_map_key) && is_list_map(b, list_map_key)) {
        list_map_print_diff(a, b, indent);
        return; }
    auto p1 = a->begin(), p2 = b->begin();
    std::cout << " [";
    indent += 2;
    while (p1 != a->end() && p2 != b->end()) {
        if (!equiv(*p1, *p2)) {
            auto s1 = find(p1, a->end(), p2->get());
            auto s2 = find(p2, b->end(), p1->get());
            if (typeid(**p1) == typeid(**p2) && p1 - a->begin() == p2 - b->begin() &&
                (s1 - p1 == s2 - p2 || typeid(**p1) == typeid(json::vector) ||
                 typeid(**p1) == typeid(json::map)))
            {
                do_prefix(indent, " ");
                std::cout << '[' << p1 - a->begin() << "]";
                print_diff(p1->get(), p2->get(), indent);
            } else {
                if (s1 - p1 <= s2 - p2) {
                    if (show_deletion)
                        do_output(p1 - a->begin(), p1, indent, "-");
                    ++p1;
                } else {
                    if (show_addition)
                        do_output(p2 - b->begin(), p2, indent, "+");
                    ++p2; }
                continue; } }

        ++p1;
        ++p2; }
    if (show_deletion) while (p1 != a->end()) {
        do_output(p1 - a->begin(), p1, indent, "-");
        ++p1; }
    if (show_addition) while (p2 != b->end()) {
        do_output(p2 - b->begin(), p2, indent, "+");
        ++p2; }
    indent -= 2;
    do_prefix(indent, " ");
    std::cout << ']';
}

bool equiv(json::map *a, json::map *b) {
    auto p1 = a->begin(), p2 = b->begin();
    while (p1 != a->end() && p2 != b->end()) {
        if (*p1->first < *p2->first) {
            if (show_deletion && !ignore(p1->first)) return false;
            ++p1;
        } else if (*p2->first < *p1->first) {
            if (show_addition && !ignore(p2->first)) return false;
            ++p2;
        } else if (!ignore(p1->first) && !(equiv(p1->second, p2->second))) {
            return false;
        } else {
            ++p1;
            ++p2; } }
    if (show_deletion)
        for (;p1 != a->end(); ++p1)
            if (!ignore(p1->first)) return false;
    if (show_addition)
        for (;p2 != b->end(); ++p2)
            if (!ignore(p2->first)) return false;
    return true;
}
void print_diff(json::map *a, json::map *b, int indent) {
    auto p1 = a->begin(), p2 = b->begin();
    std::cout << " {";
    indent += 2;
    while (p1 != a->end() && p2 != b->end()) {
        if (*p1->first < *p2->first) {
            if (show_deletion && !ignore(p1->first))
                do_output(p1, indent, "-");
            p1++;
            continue; }
        if (*p2->first < *p1->first) {
            if (show_addition && !ignore(p2->first))
                do_output(p2, indent, "+");
            p2++;
            continue; }
        if (!ignore(p1->first) && !equiv(p1->second, p2->second)) {
            do_output(p1->first, indent, " ", ":");
            print_diff(p1->second, p2->second, indent); }
        p1++;
        p2++; }
    if (show_deletion)
        for (;p1 != a->end(); ++p1)
            if (!ignore(p1->first))
                do_output(p1, indent, "-");
    if (show_addition)
        for (;p2 != b->end(); ++p2)
            if (!ignore(p2->first))
                do_output(p2, indent, "+");
    indent -= 2;
    do_prefix(indent, " ");
    std::cout << '}';

}

bool equiv(json::obj *a, json::obj *b) {
    if (a == b) return true;
    if (!a || !b) return false;
    if (typeid(*a) != typeid(*b)) return false;
    if (typeid(*a) == typeid(json::vector))
        return equiv(static_cast<json::vector *>(a), static_cast<json::vector *>(b));
    if (typeid(*a) == typeid(json::map))
        return equiv(static_cast<json::map *>(a), static_cast<json::map *>(b));
    return *a == *b;
}
void print_diff(json::obj *a, json::obj *b, int indent) {
    if (equiv(a, b)) return;
    else if (!a) {
        if (show_deletion) do_output(b, indent, "+");
        return;
    } else if (!b) {
        if (show_addition) do_output(a, indent, "-");
        return;
    } else if (typeid(*a) == typeid(*b)) {
        if (typeid(*a) == typeid(json::vector)) {
            print_diff(static_cast<json::vector *>(a), static_cast<json::vector *>(b), indent);
            return;
        } else if (typeid(*a) == typeid(json::map)) {
            print_diff(static_cast<json::map *>(a), static_cast<json::map *>(b), indent);
            return; } } 
    do_output(a, indent, "-");
    do_output(b, indent, "+");
}

int do_diff(const char *a_name, json::obj *a, const char *b_name, json::obj *b) {
    if (equiv(a, b)) return 0;
    std::cout << "--- " << a_name << std::endl;
    std::cout << "+++ " << b_name << std::endl;
    print_diff(a, b, 0);
    std::cout << std::endl;
    return 1;
}
int do_diff(const char *a_name, std::unique_ptr<json::obj> &a, const char *b_name, std::unique_ptr<json::obj> &b) {
    return do_diff(a_name, a.get(), b_name, b.get()); }

int main(int ac, char **av) {
    int error = 0;
    std::unique_ptr<json::obj>  file1;
    const char                  *file1_name;
    for (int i = 1; i < ac; i++)
        if (av[i][0] == '-' && av[i][1] == 0) {
            if (file1) {
                std::unique_ptr<json::obj> file2;
                if (!(std::cin >> file2) || !file2) {
                    std::cerr << "Failed reading json from stdin" << std::endl;
                    error = 2;
                } else if (!(error & 2))
                    error |= do_diff(file1_name, file1, "<stdin>", file2);
            } else if (!(std::cin >> file1) || !file1) {
                std::cerr << "Failed reading json from stdin" << std::endl;
                error = 2;
            } else file1_name = "<stdin>";
        } else if (av[i][0] == '-' || av[i][0] == '+') {
            bool flag = av[i][0] == '+';
            for (char *arg = av[i]+1; *arg;)
                switch(*arg++) {
                case 'a': show_addition = flag; break;
                case 'd': show_deletion = flag; break;
                case 'i': ignore_keys.insert(av[++i]); break;
                case 'l': list_map_key = av[++i]; break;
                default:
                    std::cerr << "Unknown option " << (flag ? '+' : '-') << arg[-1] << std::endl;
                    error = 2; }
        } else {
            std::ifstream file(av[i]);
            if (!file) {
                std::cerr << "Can't open " << av[i] << " for reading" << std::endl;
                error = 2;
            } else if (file1) {
                std::unique_ptr<json::obj> file2;
                if (!(file >> file2) || !file2) {
                    std::cerr << "Failed reading json from " << av[i] << std::endl;
                    error = 2;
                } else if (!(error & 2))
                    error |= do_diff(file1_name, file1, av[i], file2);
            } else if (!(file >> file1) || !file1) {
                std::cerr << "Failed reading json from " << av[i] << std::endl;
                error = 2;
            } else file1_name = av[i]; }
    if (error & 2)
        std::cerr << "usage: " << av[0] << " [-adi:l:] file1 file2" << std::endl;
    return error;
}
