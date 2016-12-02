#include "tfas.h"
#include "sections.h"
#include "top_level.h"
#include <fstream>
#include <iostream>
#include "indent.h"
#include <string>
#include <vector>
#include <sys/stat.h>
#include <unistd.h>

#define MAJOR_VERSION   1
#define MINOR_VERSION   0

option_t options = {
    .version = CONFIG_OLD,
    .match_compiler = false,
    .condense_json = true,
};

int verbose = 0;
static std::vector<std::string> debug_specs;
static std::string output_dir;
int indent_t::tabsz = 2;

static bool match(const char *pattern, const char *name) {
    const char *pend = pattern + strcspn(pattern, ",:");
    const char *pbackup = 0;
    while(1) {
        while(pattern < pend && *pattern == *name) {
            pattern++;
            name++; }
        if (pattern == pend) {
            if (!strcmp(name, ".cpp")) return true;
            return *name == 0; }
        if (*pattern++ != '*') return false;
        if (pattern == pend) return true;
        while (*name && *name != *pattern) {
            if (pbackup && *name == *pbackup) {
                pattern = pbackup;
                break; }
            name++; }
        pbackup = pattern;
    }
}

int get_file_log_level(const char *file, int *level) {
    if (auto *p = strrchr(file, '/'))
        file = p+1;
    if (auto *p = strrchr(file, '.'))
        if (!strcmp(p, ".h")) return verbose-1;
    for (auto &s : debug_specs)
        for (auto *p = s.c_str(); p; p = strchr(p, ',')) {
            while (*p == ',') p++;
            if (match(p, file))
                if (auto *l = strchr(p, ':'))
                    return *level = atoi(l+1); }
    return *level = verbose > 0 ? verbose - 1 : 0;
}

static void check_debug_spec(const char *spec) {
    bool ok = false;
    for (const char *p = strchr(spec, ':'); p; p = strchr(p, ':')) {
        ok = true;
        strtol(p+1, const_cast<char **>(&p), 10);
        if (*p && *p != ',') {
            ok = false;
            break; } }
    if (!ok)
        std::cerr << "Invalid debug trace spec '" << spec << "'" << std::endl;
}

std::unique_ptr<std::ostream> open_output(const char *name, ...) {
    char namebuf[1024], *p = namebuf, *end = namebuf + sizeof(namebuf);
    va_list args;
    if (!output_dir.empty())
        p += sprintf(p, "%s/", output_dir.c_str());
    va_start(args, name);
    if (p < end)
        p += vsnprintf(p, end-p, name, args);
    va_end(args);
    if (p >= end) {
        std::cerr << "File name too long: " << namebuf << "..." << std::endl;
        sprintf(namebuf, "/dev/null"); }
    return std::unique_ptr<std::ostream>(new std::ofstream(namebuf));
}

int main(int ac, char **av) {
    int srcfiles = 0;
    const char *firstsrc = 0;
    struct stat st;
    extern void register_exit_signals();
    register_exit_signals();
    for (int i = 1; i < ac; i++) {
        if (av[i][0] == '-' && av[i][1] == 0) {
            asm_parse_file("<stdin>", stdin);
        } else if (av[i][0] == '-' || av[i][0] == '+') {
            bool flag = av[i][0] == '+';
            for (char *arg = av[i]+1; *arg;)
                switch (*arg++) {
                case 'T':
                    if (*arg) {
                        check_debug_spec(arg);
                        debug_specs.push_back(arg);
                        arg += strlen(arg);
                    } else if (++i < ac) {
                        check_debug_spec(av[i]);
                        debug_specs.push_back(av[i]); }
                    break;
                case 'l':
                    if (auto *tmp = new std::ofstream(av[++i])) {
                        if (*tmp) {
                            /* FIXME -- tmp leaks, but if we delete it, the log
                             * redirect fails, and we crash on exit */
                            std::clog.rdbuf(tmp->rdbuf());
                        } else {
                            std::cerr << "Can't open " << av[i-1]
                                      << " for writing" << std::endl;
                            delete tmp; } }
                    break;
                case 'C':
                    options.condense_json = true;
                    break;
                case 'M':
                    options.match_compiler = true;
                    options.condense_json = false;
                    break;
                case 'o':
                    if (stat(av[++i], &st)) {
                        if (mkdir(av[i], 0777) < 0) {
                            std::cerr << "Can't create output dir " << av[i] << ": "
                                      << strerror(errno) << std::endl;
                            error_count++; }
                    } else if (!S_ISDIR(st.st_mode)) {
                        std::cerr << av[i] << " exists and is not a directory" << std::endl;
                        error_count++; }
                    output_dir = av[i];
                    break;
                case 'q':
                    std::clog.setstate(std::ios::failbit);
                    break;
                case 'v':
                    verbose++;
                    break;
                default:
                    std::cerr << "Unknown option " << (flag ? '+' : '-')
                              << arg[-1] << std::endl;
                    std::cerr << "usage: " << av[0] << " [-l:D:Mo:qv] file..."
                              << std::endl;
                    error_count++; }
        } else if (FILE *fp = fopen(av[i], "r")) {
            if (!srcfiles++) firstsrc = av[i];
            asm_parse_file(av[i], fp);
            fclose(fp);
        } else {
            std::cerr << "Can't read " << av[i] << ": " << strerror(errno) << std::endl;
            error_count++; } }
    if (error_count == 0)
        Section::process_all();
    if (error_count == 0) {
        if (srcfiles == 1 && output_dir.empty()) {
            if (const char *p = strrchr(firstsrc, '/'))
                output_dir = p+1;
            else if (const char *p = strrchr(firstsrc, '\\'))
                output_dir = p+1;
            else
                output_dir = firstsrc;
            if (const char *e = strrchr(&output_dir[0], '.'))
                output_dir.resize(e - &output_dir[0]);
            output_dir += ".out";
            if (stat(output_dir.c_str(), &st) ? mkdir(output_dir.c_str(), 0777)
                                              : !S_ISDIR(st.st_mode))
                output_dir.clear(); }
        Section::output_all();
        TopLevel::output_all(); }
    return error_count != 0;
}

class Version : public Section {
    Version() : Section("version") {}
    void start(int lineno, VECTOR(value_t) args) {}
    void input(VECTOR(value_t) args, value_t data) {
        if (!CHECKTYPE2(data, tINT, tVEC)) return;
        if (data.type == tINT) {
            if (data.i != MAJOR_VERSION)
                error(data.lineno, "Version %d not supported", data.i);
        } else if (data.vec.size >= 2) {
            if (CHECKTYPE(data[0], tINT) && CHECKTYPE(data[1], tINT) &&
                (data[0].i != MAJOR_VERSION || data[1].i > MINOR_VERSION))
                error(data.lineno, "Version %d.%d not supported", data[0].i, data[1].i);
        } else
            error(data.lineno, "Version not understood");
    }
    void process() {}
    void output() {}
    static Version singleton_version;
} Version::singleton_version;
