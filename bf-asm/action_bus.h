#ifndef _action_bus_h_
#define _action_bus_h_

#include <array>
#include "tables.h"

class ActionBus {
    static struct MeterBus_t {} MeterBus;
    struct Source {
        enum { None, Field, HashDist, RandomGen, TableOutput, TableColor, TableAddress,
               NameRef, ColorRef, AddressRef }
                                                        type;
        union {
            Table::Format::Field                        *field;
            HashDistribution                            *hd;
            Table                                       *table;
            Table::Ref                                  *name_ref;
            RandomNumberGen                             rng;
        };
        Source() : type(None) { field = nullptr; }
        Source(Table::Format::Field *f) : type(Field) { field = f; }
        Source(HashDistribution *h) : type(HashDist) { hd = h; }
        Source(Table *t, TableOutputModifier m = TableOutputModifier::NONE) : type(TableOutput) {
            switch (m) {
            case TableOutputModifier::Color: type = TableColor; break;
            case TableOutputModifier::Address: type = TableAddress; break; }
            table = t; }
        Source(Table::Ref *t, TableOutputModifier m = TableOutputModifier::NONE) : type(NameRef) {
            switch (m) {
            case TableOutputModifier::Color: type = ColorRef; break;
            case TableOutputModifier::Address: type = AddressRef; break; }
            name_ref = t; }
        Source(MeterBus_t, TableOutputModifier m = TableOutputModifier::NONE) : type(NameRef) {
            switch (m) {
            case TableOutputModifier::Color: type = ColorRef; break;
            case TableOutputModifier::Address: type = AddressRef; break; }
            name_ref = nullptr; }
        Source(RandomNumberGen r) : type(RandomGen) { field = nullptr; rng = r; }
        bool operator==(const Source &a) const {
            return type == a.type && field == a.field; }
        bool operator<(const Source &a) const {
            return type == a.type ? field < a.field : type < a.type; }
        std::string name(Table *tbl) const;
        std::string toString(Table *tbl) const;
    };
    // Check two Source refs to ensure that they are compatible (can be at the same
    // location on the aciton bus -- basically the same data)
    static bool compatible(const Source &a, unsigned a_off, const Source &b, unsigned b_off);
    struct Slot {
        std::string                 name;
        unsigned                    byte, size;  // size in bits
        std::map<Source, unsigned>  data;
        // offset in the specified source is in this slot -- corresponding bytes for different
        // action data formats will go into the same slot.
        Slot(std::string n, unsigned b, unsigned s) : name(n), byte(b), size(s) {}
        Slot(std::string n, unsigned b, unsigned s, Source src, unsigned off)
        : name(n), byte(b), size(s) { data.emplace(src, off); }
        unsigned lo(Table *tbl) const;  // low bit on the action data bus
        bool is_table_output() const {
            for (auto &d : data) {
                assert(d.first.type != Source::NameRef);
                if (d.first.type == Source::TableOutput)
                    return true; }
            return false; }
    };
    friend std::ostream &operator<<(std::ostream &, const Source &);
    friend std::ostream &operator<<(std::ostream &, const Slot &);
    friend std::ostream &operator<<(std::ostream &, const ActionBus &);
    std::map<unsigned, Slot>                        by_byte;
    std::map<Source, std::map<unsigned, unsigned>>  need_place;
    // bytes from the given sources are needed on the action bus -- the pairs in the map
    // are (offset,use) where offset is offset in bits, and use is a bitset of the needed
    // uses (bit index == log2 of the access size in bytes)

    std::vector<std::array<unsigned, ACTION_HV_XBAR_SLICES>>    action_hv_slice_use;
    // which bytes of input to the ixbar are used in each action_hv_xbar slice, for each
    // 128-bit slice of the action bus.
    bitvec      byte_use;  // bytes on the action data (input) bus or immediate bus in use
                           // for wide action tables, this may be >16 bytes...

    void setup_slot(int lineno, Table *tbl, const char *name, unsigned idx, Source src,
                    unsigned sz, unsigned off);
    int find_free(Table *tbl, int min, int max, int step, int lobyte, int bytes);
    int find_merge(Table *tbl, int offset, int bytes, int use);
    bool check_atcam_sharing(Table *tbl1, Table *tbl2);
    bool check_slot_sharing(ActionBus::Slot &slot, bitvec &action_bus);
public:
    int             lineno;
    ActionBus() : lineno(-1) {}
    ActionBus(Table *, VECTOR(pair_t) &);
    void pass1(Table *tbl);
    void pass3(Table *tbl);
    template<class REGS> void write_immed_regs(REGS &regs, Table *tbl);
    template<class REGS>
    void write_action_regs(REGS &regs, Table *tbl, unsigned homerow, unsigned action_slice);
    void do_alloc(Table *tbl, Source src, unsigned use, int lobyte, int bytes, unsigned offset);
    void alloc_field(Table *, Source src, unsigned offset, unsigned sizes_needed);
    void need_alloc(Table *tbl, Source src, unsigned lo, unsigned hi, unsigned size);
    void need_alloc(Table *tbl, Table *attached, TableOutputModifier mod,
                    unsigned lo, unsigned hi, unsigned size) {
        need_alloc(tbl, Source(attached, mod), lo, hi, size); }

    int find(Table::Format::Field *f, int lo, int hi, int size, int *len = 0);
    int find(const char *name, TableOutputModifier mod, int lo, int hi, int size, int *len = 0);
    int find(const char *name, int lo, int hi, int size, int *len = 0) {
        return find(name, TableOutputModifier::NONE, lo, hi, size, len); }
    int find(const std::string &name, TableOutputModifier mod, int lo, int hi,
             int size, int *len = 0) {
        return find(name.c_str(), mod, lo, hi, size, len); }
    int find(const std::string &name, int lo, int hi, int size, int *len = 0) {
        return find(name.c_str(), lo, hi, size, len); }
    int find(Source src, int lo, int hi, int size, int *len = 0);
    int find(Table *attached, TableOutputModifier mod, int lo, int hi, int size, int *len = 0) {
        return find(Source(attached, mod), lo, hi, size, len); }
    unsigned size() {
        unsigned rv = 0;
        for (auto &slot : by_byte) rv += slot.second.size;
        return rv; }
};

#endif /* _action_bus_h_ */
