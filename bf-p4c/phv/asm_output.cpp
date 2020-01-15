#include <set>
#include <random>
#include "asm_output.h"
#include "bf-p4c/common/asm_output.h"
#include "bf-p4c/common/field_defuse.h"
#include "bf-p4c-options.h"
#include "bf-p4c/phv/phv.h"
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

/* For testing assmbler's stage based allocation - takes the current PHV allocation
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

void emit_stage_phv_field(std::ostream& out, PHV::Field* field) {
    ordered_map<le_bitrange, std::vector<PHV::Field::alloc_slice>> fieldRangeToAllocMap;
    field->foreach_alloc([&](const PHV::Field::alloc_slice& alloc) {
        fieldRangeToAllocMap[alloc.field_bits()].push_back(alloc);
    });
    // No allocation for the field.
    if (fieldRangeToAllocMap.size() == 0) return;
    for (auto kv : fieldRangeToAllocMap) {
        unsigned numAllocSlices = kv.second.size();
        unsigned alloc_num = 0;
        bool stageAllocReqd = false;
        out << "  " << canon_name(field->externalName());
        if (kv.first.lo > 0 || kv.first.size() < field->size)
            out << '.' << kv.first.lo << '-' << kv.first.hi;
        out << ": ";
        std::sort(kv.second.begin(), kv.second.end(),
                [](const PHV::Field::alloc_slice& lhs, const PHV::Field::alloc_slice& rhs) {
            if (lhs.min_stage.first != rhs.min_stage.first)
                return lhs.min_stage.first < rhs.min_stage.first;
            return lhs.min_stage.second < rhs.min_stage.second;
        });
        for (auto& alloc : kv.second) {
            ++alloc_num;
            int min_stage, max_stage;
            if (alloc.min_stage.first == -1)
                min_stage = 0;
            else if (alloc.min_stage.second == PHV::FieldUse(PHV::FieldUse::WRITE))
                min_stage = alloc.min_stage.first + 1;
            else
                min_stage = alloc.min_stage.first;
            if (alloc.max_stage.second == PHV::FieldUse(PHV::FieldUse::WRITE) &&
                alloc.max_stage.first != PhvInfo::getDeparserStage())
                max_stage = alloc.max_stage.first + 1;
            else
                max_stage = alloc.max_stage.first;
            if (min_stage != 0 || max_stage != PhvInfo::getDeparserStage()) {
                stageAllocReqd = true;
                if (alloc_num == 1) out << "{ ";
                if (min_stage != max_stage)
                    out << " stage " << min_stage << ".." << max_stage << ": " << alloc.container;
                else
                    out << " stage " << min_stage << ": " << alloc.container;
            } else {
                out << alloc.container;
            }
            bool containerSliceReqd = alloc.container_bit > 0 ||
                alloc.container.size() != static_cast<size_t>(alloc.width);
            if (containerSliceReqd) {
                out << '(' << alloc.container_bit;
                if (alloc.width > 1) out << ".." << alloc.container_hi();
                out << ')';
            }
            if (alloc_num != numAllocSlices) out << ',';
        }
        if (stageAllocReqd) out << " } ";
        out << std::endl;
    }
}

void emit_phv_field(
        std::ostream& out,
        PHV::Field* field) {
    if (Device::currentDevice() == Device::JBAY) {
        emit_stage_phv_field(out, field);
#if HAVE_CLOUDBREAK
    } else if (Device::currentDevice() == Device::CLOUDBREAK) {
        emit_stage_phv_field(out, field);
#endif /* HAVE_CLOUDBREAK */
    } else if (Device::currentDevice() == Device::TOFINO) {
        field->foreach_alloc([&](const PHV::Field::alloc_slice& slice) {
            emit_alloc(out, slice, field);
        });
    }
}

void PhvAsmOutput::emit_phv_field_info(
        std::ostream& out,
        const PHV::Field* f,
        const PHV::Container& c) const {
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
        auto live_start = c.is(PHV::Kind::tagalong) ? "parser"   : PrintStage(range.first);
        auto live_end   = c.is(PHV::Kind::tagalong) ? "deparser" : PrintStage(range.last);
        out << "          " << "live_start: " << live_start << std::endl;
        out << "          " << "live_end: "   << live_end   << std::endl; }

    // Print mutual exclusion information.
    out << "          " << "mutually_exclusive_with: [ ";
    std::string sep = "";
    for (const auto* f2 : phv.fields_in_container(c)) {
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
                    emit_phv_field_info(out, f, c); } } } }
}

std::ostream &operator<<(std::ostream &out, const PhvAsmOutput& phvasm) {
    phvasm.emit_gress(out, INGRESS);
    phvasm.emit_gress(out, EGRESS);
    if (phvasm.have_ghost)
        phvasm.emit_gress(out, GHOST);
    return out;
}
