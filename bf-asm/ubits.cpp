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

static regrange *find_regrange(const void *addr_) {
    const char *addr = static_cast<const char *>(addr_);
    if (registers) {
        auto it = registers->upper_bound(addr);
        if (it != registers->begin()) {
            it--;
            if (addr <= it->second.base + it->second.sz)
                return &it->second; } }
    return nullptr;
}

void declare_registers(const void *addr_, size_t sz,
                       std::function<void(std::ostream &, const char *, const void *)> fn) {
    const char *addr = static_cast<const char *>(addr_);
    if (!registers)
        registers = new std::map<const char *, regrange>();
    registers->emplace(addr, regrange{ addr, sz, fn });
}

void undeclare_registers(const void *addr_) {
    const char *addr = static_cast<const char *>(addr_);
    registers->erase(addr);
    if (registers->empty()) {
        delete registers;
        registers = 0; }
}

void print_regname(std::ostream &out, const void *addr, const void *end) {
    if (auto rr = find_regrange(addr))
        rr->fn(out, static_cast<const char *>(addr), end);
    else
        out << "???";
}

void ubits_base::log(const char *op, unsigned long v) const {
    if (LOGGING(1)) {
        std::ostringstream tmp;
        if (!find_regrange(this))
            return;
        LOG1(this << ' ' << op << ' ' << v <<
             (v != value ?  tmp << " (now " << value << ")", tmp : tmp).str()); } }

void ustring::log() const { LOG1(this << " = \"" << value << "\""); }

