#include "bfas.h"
#include "sections.h"
#include "target.h"
#include "top_level.h"
#include <fstream>
#include <iostream>
#include "indent.h"
#include "constants.h"
#include <string>
#include <vector>
#include <sys/stat.h>
#include <unistd.h>
#include "../bf-p4c/version.h" // for BF_P4C_VERSION
#include "misc.h"
#include "version.h"

#define MAJOR_VERSION   1
#define MINOR_VERSION   0

const std::string SCHEMA_VERSION = CONTEXT_SCHEMA_VERSION;

option_t options = {
    .binary = PIPE0,
    .condense_json = true,
    .debug_info = false,
    .disable_egress_latency_padding = false,
    .disable_long_branch = false,
    .disable_power_gating = false,
    .gen_json = false,
    //FIXME-P4C: Compiler currently does not reserve 51st bit for hash parity.
    //Flip 'hash_parity_enabled' to true when 51st bit is reserved.
    .hash_parity_enabled = false,
    .high_availability_enabled = true,
    .match_compiler = false,
#if HAVE_JBAY || HAVE_CLOUDBREAK
    .singlewrite = true,
#else
    .singlewrite = false,
#endif
    .multi_parsers = true, // TODO:Remove option after testing
    .stage_dependency_pattern = "",
    .target = NO_TARGET,
    .version = CONFIG_OLD,
    .werror = false,
    .nowarn = false,
};

std::string asmfile_name;

int log_error = 0;
static std::string output_dir;
extern char *program_name;

// or-ed with table_handle[31:30] to generate unique table handle
unsigned unique_table_offset = 0;

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

std::string usage(std::string tfas) {
    std::string u = "usage: ";
    u.append(tfas);
    u.append(" [-l:Mo:gqtvh] file...");
    return u; }

void output_all() {
    auto targetName = "unknown";
    switch (options.target) {
#define SET_TOP_LEVEL(TARGET)                                           \
    case Target::TARGET::tag:                                           \
        new TopLevelRegs<Target::TARGET::register_type>;                \
        targetName = Target::TARGET::name;                              \
        break;
    FOR_ALL_TARGETS(SET_TOP_LEVEL)
    default:
        std::cerr << "No target set" << std::endl;
        error_count++;
        return; }
    json::map ctxtJson;
    const time_t now = time(NULL);
    char build_date[1024];
    strftime(build_date, 1024, "%c", localtime(&now));
    ctxtJson["build_date"] = build_date;
    ctxtJson["schema_version"] = SCHEMA_VERSION;
    ctxtJson["compiler_version"] = BF_P4C_VERSION;
    ctxtJson["target"] = targetName;
    ctxtJson["program_name"] = asmfile_name;
    ctxtJson["learn_quanta"] = json::vector();
    ctxtJson["parser"] = json::map();
    ctxtJson["phv_allocation"] = json::vector();
    ctxtJson["tables"] = json::vector();
    ctxtJson["stage_dependency"] = json::vector();
    ctxtJson["configuration_cache"] = json::vector();

    Section::output_all(ctxtJson);
    TopLevel::output_all(ctxtJson);

    json::map driver_options;
    driver_options["hash_parity_enabled"] = options.hash_parity_enabled;
    driver_options["high_availability_enabled"] = options.high_availability_enabled;
    ctxtJson["driver_options"] = std::move(driver_options);

    auto json_out = open_output("context.json");
    *json_out << &ctxtJson;

    delete TopLevel::all;
}



#define MATCH_TARGET_OPTION(TARGET, OPT) \
    if (!strcasecmp(OPT, Target::TARGET::name)) options.target = Target::TARGET::tag; else
#define OUTPUT_TARGET(TARGET)           << " " << Target::TARGET::name

int main(int ac, char **av) {
    int srcfiles = 0;
    const char *firstsrc = 0;
    struct stat st;
    bool asmfile = false;
    bool disable_clog = true;
    extern void register_exit_signals();
    register_exit_signals();
    program_name = av[0];
    std::vector<char *> arguments(av, av+ac);
    if (auto opt = getenv("BFAS_OPTIONS")) {
        int add_at = 1;
        while (auto p = strsep(&opt, " \t\r\n")) {
            if (!*p) continue;
            arguments.insert(arguments.begin() + add_at++, p); }
        av = &arguments[0];
        ac = arguments.size(); }
    for (int i = 1; i < ac; i++) {
        int     val, len;
        if (av[i][0] == '-' && av[i][1] == 0) {
            asm_parse_file("<stdin>", stdin);
        } else if (!strcmp(av[i], "--allpipes")) {
            options.binary = FOUR_PIPE;
        } else if (!strcmp(av[i], "--disable-egress-latency-padding")) {
            options.disable_egress_latency_padding = true;
        } else if (!strcmp(av[i], "--disable-longbranch")) {
            options.disable_long_branch = true;
        } else if (!strcmp(av[i], "--enable-longbranch")) {
            if (options.target && Target::LONG_BRANCH_TAGS() == 0) {
                error(-1, "target %s does not support --enable-longbranch", Target::name());
                options.disable_long_branch = true;
            } else
                options.disable_long_branch = false;
        } else if (!strcmp(av[i], "--gen_json")) {
            options.gen_json = true;
            options.binary = NO_BINARY;
        } else if (!strcmp(av[i], "--hash_parity_disabled")) {
            options.hash_parity_enabled = false;
        } else if (!strcmp(av[i], "--high_availability_disabled")) {
            options.high_availability_enabled = false;
        } else if (!strcmp(av[i], "--no-condense")) {
            options.condense_json = false;
        } else if (!strcmp(av[i], "--no-bin")) {
            options.binary = NO_BINARY;
        } else if (!strcmp(av[i], "--no-warn")) {
            options.nowarn = true;
        } else if (!strcmp(av[i], "--old_json")) {
            std::cerr << "Old context json is no longer supported" << std::endl;
            error_count++;
        } else if (sscanf(av[i], "--pipe%d%n", &val, &len) > 0 && !av[i][len] &&
                   val >= 0 && val < 4) {
            options.binary = static_cast<binary_type_t>(PIPE0 + val);
        } else if (!strcmp(av[i], "--singlepipe")) {
            options.binary = ONE_PIPE;
        } else if (!strcmp(av[i], "--singlewrite")) {
            options.singlewrite = true;
        } else if (!strcmp(av[i], "--multi-parsers")) {
            options.multi_parsers = true;
        } else if (!strcmp(av[i], "--stage_dependency_pattern")) {
          ++i;
          if (!av[i]) {
            std::cerr << "No stage dependency pattern specified " << std::endl;
            error_count++;
            break;
          }
          options.stage_dependency_pattern = av[i];
        } else if (sscanf(av[i], "--table-handle-offset%d", &val) > 0 && val >= 0 && val < 4) {
            unique_table_offset = val;
        } else if (!strcmp(av[i], "--target")) {
            ++i;
            if (!av[i]) {
                std::cerr << "No target specified '--target <target>'" << std::endl;
                error_count++;
                break;}
            if (options.target != NO_TARGET) {
                std::cerr << "Multiple target options" << std::endl;
                error_count++;
                break; }
            FOR_ALL_TARGETS(MATCH_TARGET_OPTION, av[i]) {
                std::cerr << "Unknown target " << av[i] << std::endl;
                error_count++;
                std::cerr << "Supported targets:" FOR_ALL_TARGETS(OUTPUT_TARGET) << std::endl; }
        } else if (av[i][0] == '-' && av[i][1] == '-') {
            FOR_ALL_TARGETS(MATCH_TARGET_OPTION, av[i]+2) {
                std::cerr << "Unrecognized option " << av[i] << std::endl;
                error_count++; }
        } else if (av[i][0] == '-' || av[i][0] == '+') {
            bool flag = av[i][0] == '+';
            for (char *arg = av[i]+1; *arg;)
                switch (*arg++) {
                case 'a':
                    options.binary = FOUR_PIPE;
                    break;
                case 'C':
                    options.condense_json = true;
                    break;
                case 'G':
                    options.gen_json = true;
                    options.binary = NO_BINARY;
                    break;
                case 'g':
                    options.debug_info = true;
                    break;
                case 'h':
                    std::cout << usage(av[0]) << std::endl;
                    return 0;
                    break;
                case 'l':
                    ++i;
                    if (!av[i]) {
                        std::cerr << "No log file specified '-l <log file>'"
                            << std::endl;
                        error_count++;
                        break; }
                    disable_clog = false;
                    if (auto *tmp = new std::ofstream(av[i])) {
                        if (*tmp) {
                            /* FIXME -- tmp leaks, but if we delete it, the log
                             * redirect fails, and we crash on exit */
                            std::clog.rdbuf(tmp->rdbuf());
                        } else {
                            std::cerr << "Can't open " << av[i]
                                      << " for writing" << std::endl;
                            delete tmp; } }
                    break;
                case 'M':
                    options.match_compiler = true;
                    options.condense_json = false;
                    break;
                case 'o':
                    ++i;
                    if (!av[i]) {
                        std::cerr << "No output directory specified '-o <output dir>'"
                            << std::endl;
                        error_count++;
                        break; }
                    if (stat(av[i], &st)) {
                        if (mkdir(av[i], 0777) < 0) {
                            std::cerr << "Can't create output dir " << av[i] << ": "
                                      << strerror(errno) << std::endl;
                            error_count++; }
                    } else if (!S_ISDIR(st.st_mode)) {
                        std::cerr << av[i] << " exists and is not a directory" << std::endl;
                        error_count++; }
                    output_dir = av[i];
                    break;
                case 'p':
                    options.disable_power_gating = true;
                    break;
                case 'q':
                    std::clog.setstate(std::ios::failbit);
                    break;
                case 's':
                    options.binary = ONE_PIPE;
                    break;
                case 'T':
                    disable_clog = false;
                    if (*arg) {
                        Log::addDebugSpec(arg);
                        arg += strlen(arg);
                    } else if (++i < ac) {
                        Log::addDebugSpec(av[i]); }
                    break;
                case 't':
                    ++i;
                    if (!av[i]) {
                        std::cerr << "No target specified '-t <target>'" << std::endl;
                        error_count++;
                        break; }
                    if (options.target != NO_TARGET) {
                        std::cerr << "Multiple target options" << std::endl;
                        error_count++;
                        break; }
                    FOR_ALL_TARGETS(MATCH_TARGET_OPTION, av[i]) {
                        std::cerr << "Unknown target " << av[i];
                        error_count++; }
                    break;
                case 'v':
                    disable_clog = false;
                    Log::increaseVerbosity();
                    break;
                case 'W':
                    if (strcmp(arg, "error"))
                        options.werror = true;
                    else
                        std::cout << "Unknown warning option -W" << arg << std::endl;
                    arg += strlen(arg);
                    break;
                default:
                    std::cerr << "Unknown option " << (flag ? '+' : '-')
                              << arg[-1] << std::endl;
                    error_count++; }
        } else if (FILE *fp = fopen(av[i], "r")) {
            if (!srcfiles++) firstsrc = av[i];
            error_count += asm_parse_file(av[i], fp);
            if (error_count > 0) return 1;
            fclose(fp);
            asmfile = true;
            asmfile_name = get_filename(av[i]);
        } else {
            std::cerr << "Can't read " << av[i] << ": " << strerror(errno) << std::endl;
            error_count++; } }
    if (disable_clog)
        std::clog.setstate(std::ios_base::failbit);
    if (!asmfile) {
        std::cerr << "No assembly file specified" << std::endl;
        error_count++; }
    if (error_count > 0)
        std::cerr << usage(av[0]) << std::endl;
    if (error_count == 0) {
        // Check if file has no sections
        no_sections_error_exit();
        // Check if mandatory sections are present in assembly
        bool no_section = false;
        no_section |= no_section_error("deparser");
        no_section |= no_section_error("parser");
        no_section |= no_section_error("phv");
        no_section |= no_section_error("stage");
        if (no_section) exit(1);
        Section::process_all();
    }
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
        output_all(); }
    if (log_error > 0)
        warning(0, "%d config errors in log file", log_error);
    return error_count > 0 || (options.werror && warn_count > 0) ? 1 : 0;
}

void no_sections_error_exit() {
    if (Section::no_sections_in_assembly()) {
        std::cerr << "No valid sections found in assembly file" << std::endl; exit(1); }
}

bool no_section_error(const char* name) {
    if (!Section::section_in_assembly(name)) {
        std::cerr << "No '" << name << "' section found in assembly file" << std::endl;
        return true;
    }
    return false;
}

class Version : public Section {
    Version() : Section("version") {}

    void input(VECTOR(value_t) args, value_t data) {
        if (data.type == tINT || data.type == tVEC) {  // version 1.0.0
            parse_version(data);
        } else if (data.type == tMAP) {  // version 1.0.1
            for (auto &kv : MapIterChecked(data.map, true)) {
                if (kv.key == "version" && (kv.value.type == tVEC || kv.value.type == tINT)) {
                    parse_version(kv.value);
                } else if (kv.key == "run_id" && kv.value.type == tSTR) {
                    _run_id = kv.value.s;
                } else if (kv.key == "compiler") {
                    if (kv.value.type == tSTR)
                        _compiler = kv.value.s;
                    else if (kv.value.type == tINT)
                        _compiler = std::to_string(kv.value.i);
                    else if (kv.value.type == tVEC) {
                        const char *sep = "";
                        for (auto &el : kv.value.vec) {
                            _compiler += sep;
                            if (el.type == tSTR)
                                _compiler += el.s;
                            else if (el.type == tINT)
                                _compiler += std::to_string(el.i);
                            else
                                error(el.lineno, "can't understand compiler version");
                            sep = "."; } }
                } else if (kv.key == "target") {
                    if (kv.value.type == tSTR) {
                        auto old = options.target;
                        FOR_ALL_TARGETS(MATCH_TARGET_OPTION, kv.value.s) {
                            error(kv.value.lineno, "Unknown target %s", kv.value.s); }
                        if (old != NO_TARGET && old != options.target) {
                            options.target = old;
                            error(kv.value.lineno, "Inconsistent target %s (previously set to %s)",
                                  kv.value.s, Target::name()); }
                    } else {
                        error(kv.value.lineno, "Invalid target %s", value_desc(kv.value));
                    }
                } else
                    warning(kv.key.lineno, "ignoring unknown item %s in version",
                            value_desc(kv.key));
            }
        } else {
            error(data.lineno, "Invalid version section");
        }
    }

    void output(json::map &ctx_json) {
        if (!_compiler.empty())
            ctx_json["compiler_version"] = _compiler;
        ctx_json["run_id"] = _run_id; }

 private:
    void parse_version(value_t data) {
        if (data.type == tINT) {
            if (data.i != MAJOR_VERSION)
                error(data.lineno, "Version %" PRId64 " not supported", data.i);
        } else if (data.vec.size >= 2) {
            if (CHECKTYPE(data[0], tINT) && CHECKTYPE(data[1], tINT) &&
                (data[0].i != MAJOR_VERSION || data[1].i > MINOR_VERSION))
                error(data.lineno, "Version %" PRId64 ".%" PRId64 " not supported",
                      data[0].i, data[1].i);
        } else
            error(data.lineno, "Version not understood");
    }

    std::string _run_id, _compiler;
    static Version singleton_version;
} Version::singleton_version;
