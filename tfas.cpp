#include "tfas.h"
#include "sections.h"
#include <fstream>
#include <iostream>

config_version_t config_version = CONFIG_BOTH;

int main(int ac, char **av) {
    for (int i = 1; i < ac; i++) {
        if (av[i][0] == '-' && av[i][1] == 0) {
            asm_parse_file("<stdin>", stdin);
        } else if (av[i][0] == '-' || av[i][0] == '+') {
            bool flag = av[i][0] == '+';
            for (char *arg = av[i]+1; *arg;)
                switch (*arg++) {
                case 'l':
                    if (auto *tmp = new std::ofstream(av[++i])) {
                        if (*tmp) {
                            /* FIXME -- tmp leaks, but if we delete it, the log
                             * redirect fails, and we crash on exit */
                            std::clog.rdbuf(tmp->rdbuf());
                        } else {
                            fprintf(stderr, "Can't open %s for writing\n", av[i-1]);
                            delete tmp; } }
                    break;
                case 'q':
                    std::clog.setstate(std::ios::failbit);
                    break;
                default:
                    fprintf(stderr, "Unknown option %c%c\n", flag ? '+' : '-',
                            arg[-1]);
                    fprintf(stderr, "usage: %s file\n", av[0]);
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

