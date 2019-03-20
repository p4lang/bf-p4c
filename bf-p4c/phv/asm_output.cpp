#include <set>
#include <random>
#include "asm_output.h"
#include "bf-p4c/common/asm_output.h"
#include "bf-p4c/common/field_defuse.h"
#include "bf-p4c-options.h"
#include "bf-p4c/phv/phv_fields.h"
#include "lib/stringref.h"

PhvAsmOutput::PhvAsmOutput(const PhvInfo &p, const FieldDefUse& defuse, bool have_ghost)
: phv(p), defuse(defuse), have_ghost(have_ghost) {
    liveRanges.clear();
    getLiveRanges();
}

PhvAsmOutput::LiveRange PhvAsmOutput::LiveRange::operator|=(const PhvAsmOutput::LiveRange& other) {
    if (first && other.first)
        first = first->stage() < other.first->stage() ? first : other.first;
    else if (!first)
        first = other.first;

    if (last && other.last)
        last = last->stage() < other.last->stage() ? other.last : last;
    else if (!last)
        last = other.last;

    return *this;
}

void PhvAsmOutput::getLiveRanges() {
    for (auto& f : phv)
        for (auto& def : defuse.getAllDefs(f.id))
            for (auto& use : defuse.getUses(def))
                liveRanges[&f] |= { .first = def.first, .last = use.first };
}

void emit_alloc(
        std::ostream& out,
        const PHV::Field::alloc_slice& alloc,
        PHV::Field* f) {
    out << "  " << canon_name(f->externalName());
    if (alloc.field_bit > 0 || alloc.width < f->size)
        out << '.' << alloc.field_bit << '-' << alloc.field_hi();
    out << ": " << alloc.container;
    if (alloc.container_bit > 0 || alloc.container.size() != static_cast<size_t>(alloc.width)) {
        out << '(' << alloc.container_bit;
        if (alloc.width > 1)
            out << ".." << alloc.container_hi();
        out << ')'; }
    out << std::endl;
}

/* For testing assmbler's stage based allocation - takes the current PVH allocation 
 * and writes it out as a set of random stage based allocation
 */
void emit_stage_alloc(
        std::ostream& out,
        const PHV::Field::alloc_slice& alloc,
        PHV::Field* f) {
    out << "  " << canon_name(f->externalName());
    if (alloc.field_bit > 0 || alloc.width < f->size)
        out << '.' << alloc.field_bit << '-' << alloc.field_hi();

    std::set<int> stageset;
    std::random_device rd;
    std::mt19937 mteng(rd());
    std::uniform_int_distribution<> dist(0, Device::numStages());
    stageset.insert(0);
    stageset.insert(Device::numStages());
    for (int i = 0; i < dist(mteng); i++) {
      stageset.insert(dist(mteng));
    }

    out << ": " << " { ";
    int first = *(stageset.begin());
    stageset.erase(stageset.cbegin());
    bool prntc = true;
    for (auto it : stageset) {
        if (prntc)
          prntc = false;
        else
          out << ',';
        out << " stage " << first << ".." << it << ": " << alloc.container;
        if (alloc.container_bit > 0 || alloc.container.size() != static_cast<size_t>(alloc.width)) {
            out << '(' << alloc.container_bit;
        if (alloc.width > 1)
            out << ".." << alloc.container_hi();
        out << ") "; }
        first = it + 1;
    }

    out << " } ";
    out << std::endl;
}

void emit_phv_field(
        std::ostream& out,
        PHV::Field* field) {
    field->foreach_alloc([&](const PHV::Field::alloc_slice& slice) {
#if BAREFOOT_INTERNAL
        // Testing only
        if (BackendOptions().stage_allocation)
            emit_stage_alloc(out, slice, field);
        else
#endif
            emit_alloc(out, slice, field);
    });
}

void PhvAsmOutput::emit_phv_field_info(
        std::ostream& out,
        const PHV::Field* f,
        const ordered_set<const PHV::Field*>& fieldsInContainer) const {
    out << "      " << canon_name(f->externalName()) << ":" << std::endl;

    // Print live range info.
    auto PrintStage = [](const IR::BFN::Unit* u) {
        if (u->is<IR::BFN::AbstractParser>() || u->is<IR::BFN::ParserState>())
            return std::string("parser");
        else if (auto* t = u->to<IR::MAU::Table>())
            return std::to_string(int(t->logical_id/16));
        else if (u->is<IR::BFN::AbstractDeparser>())
            return std::string("deparser");
        BUG("Unit is not parser, table, or deparser: %1%", cstring::to_cstring(u));
    };

    if (liveRanges.count(f)) {
        auto& range = liveRanges.at(f);
        out << "          " << "live_start: " << PrintStage(range.first) << std::endl;
        out << "          " << "live_end: " << PrintStage(range.last) << std::endl; }

    // Print mutual exclusion information.
    out << "          " << "mutually_exclusive_with: [ ";
    std::string sep = "";
    for (const auto* f2 : fieldsInContainer) {
        if (phv.isFieldMutex(f, f2)) {
            out << sep << canon_name(f2->externalName());
            if (sep == "") sep = ", "; } }
    out << " ]" << std::endl;
}

void PhvAsmOutput::emit_gress(std::ostream& out, gress_t gress) const {
    out << "phv " << gress << ":\n";
    // FIXME -- for now, all ghost PHV are allocated as ingress, so we just
    // FIXME -- duplicate the ingress phv
    if (gress == GHOST) gress = INGRESS;
    for (auto &f : phv) {
        if (f.gress == gress) {
            emit_phv_field(out, &f); } }
    if (BackendOptions().debugInfo) {
        out << "  " << "context_json:\n";
        // Collect set of all containers that are allocated to a particular gress.
        std::set<PHV::Container> allocatedContainers;
        for (const auto& f : phv) {
            if (f.gress != gress) continue;
            f.foreach_alloc([&](const PHV::Field::alloc_slice& slice) {
                allocatedContainers.insert(slice.container);
            });
        }
        for (const auto& c : allocatedContainers) {
            out << "    " << c << ":\n";
            const auto& fieldsInContainer = phv.fields_in_container(c);
            for (const auto* f : fieldsInContainer) {
                if (f->gress == gress && !f->is_unallocated()) {
                    emit_phv_field_info(out, f, fieldsInContainer); } } } }
}

std::ostream &operator<<(std::ostream &out, const PhvAsmOutput& phvasm) {
    phvasm.emit_gress(out, INGRESS);
    phvasm.emit_gress(out, EGRESS);
    if (phvasm.have_ghost)
        phvasm.emit_gress(out, GHOST);
    return out;
}
