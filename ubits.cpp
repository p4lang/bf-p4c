#include "ubits.h"
#include <map>
#include "log.h"
#include <sstream>

struct regrange {
    const char  *base;
    size_t      sz;
    std::function<void(std::ostream &, const char *, const void *)> fn;
};

static std::map<const char *, regrange> *registers;

void declare_registers(const void *addr_, size_t sz, std::function<void(std::ostream &, const char *, const void *)> fn) {
    const char *addr = (const char *)addr_;
    if (!registers)
        registers = new std::map<const char *, regrange>();
    registers->emplace(addr, regrange{ addr, sz, fn });
}

void undeclare_registers(const void *addr_) {
    const char *addr = (const char *)addr_;
    registers->erase(addr);
    if (registers->empty()) {
        delete registers;
        registers = 0; }
}

void print_regname(std::ostream &out, const void *addr_, const void *end) {
    const char *addr = (const char *)addr_;
    if (registers) {
        auto it = registers->upper_bound(addr);
        if (it != registers->begin()) {
            it--;
            it->second.fn(out, addr, end);
            return; } }
    out << "???";
}

void ubits_base::log(const char *op, unsigned long v) const {
    std::ostringstream tmp;
    LOG1(this << ' ' << op << ' ' << v <<
         (v != value ?  tmp << " (now " << value << ")", tmp : tmp).str()); }

void ustring::log() const { LOG1(this << " = \"" << value << "\""); }

