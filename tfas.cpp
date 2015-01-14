#include "tfas.h"
#include "sections.h"
#include <fstream>
#include <iostream>
#include <string>
#include <vector>

config_version_t config_version = CONFIG_OLD;

static int verbose = 0;
static std::vector<std::string> debug_specs;

static bool match(const char *pattern, const char *name) {
    const char *pend;
    if (!(pend = strchr(pattern, ':')) && !(pend = strchr(pattern, ',')))
        pend = pattern + strlen(pattern);
    const char *pbackup = 0;
    while(1) {
        while(pattern < pend && *pattern == *name) {
            pattern++;
            name++; }
        if (pattern == pend) return *name == 0;
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
    for (auto &s : debug_specs)
        for (auto *p = s.c_str(); p; p = strchr(p, ',')) {
            while (*p == ',') p++;
            if (match(p, file))
                if (auto *l = strchr(p, ':'))
                    return *level = atoi(l+1); }
    return *level = verbose;
}

int main(int ac, char **av) {
    for (int i = 1; i < ac; i++) {
        if (av[i][0] == '-' && av[i][1] == 0) {
            asm_parse_file("<stdin>", stdin);
        } else if (av[i][0] == '-' || av[i][0] == '+') {
            bool flag = av[i][0] == '+';
            for (char *arg = av[i]+1; *arg;)
                switch (*arg++) {
                case 'D':
                    if (++i < ac)
                        debug_specs.push_back(av[i]);
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
                case 'q':
                    std::clog.setstate(std::ios::failbit);
                    break;
                case 'v':
                    verbose++;
                    break;
                default:
                    std::cerr << "Unknown option " << (flag ? '+' : '-') 
                              << arg[-1] << std::endl;
                    std::cerr << "usage: " << av[0] << " [-l:D:qv] file..."
                              << std::endl;
                    error_count++; }
        } else if (FILE *fp = fopen(av[i], "r")) {
            asm_parse_file(av[i], fp);
            fclose(fp);
        } else {
            fprintf(stderr, "Can't read %s\n", av[i]);
            error_count++; } }
    if (error_count == 0)
        Section::process_all();
    if (error_count == 0)
        Section::output_all();
    return error_count != 0;
}

