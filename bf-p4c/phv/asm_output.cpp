#include <set>
#include <random>
#include "asm_output.h"
#include "bf-p4c/common/asm_output.h"
#include "bf-p4c/common/field_defuse.h"
#include "bf-p4c-options.h"
#include "bf-p4c/phv/phv.h"
#include "bf-p4c/phv/phv_fields.h"
#include "lib/stringref.h"

PhvAsmOutput::PhvAsmOutput(const PhvInfo &p, const FieldDefUse& defuse,
                           const TableSummary& tbl_summary,
                           const LiveRangeReport* live_range_report, bool have_ghost)
    : phv(p), defuse(defuse), tbl_summary(tbl_summary),
      live_range_report(live_range_report), have_ghost(have_ghost) {
}

void PhvAsmOutput::getLiveRanges(LiveRangePerContainer &lr) const {
    const auto &livemap = live_range_report->get_livemap();
    for (const auto &kv : livemap) {
        auto f = kv.first;
        int min = live_range_report->get_max_stages(), max = -1;
        for (const auto &stg : kv.second) {
            if (stg.first < min) min = stg.first;
            if (stg.first > max) max = stg.first;
        }
        f->foreach_alloc([&](const PHV::Field::alloc_slice& alloc) {
            auto c = alloc.container;
            cstring fname = cstring::to_cstring(canon_name(f->externalName()));
            std::set<cstring> mutex_fields;
            for (const auto* f2 : phv.fields_in_container(c)) {
                if (phv.isFieldMutex(f, f2)) {
                    cstring mfname = cstring::to_cstring(canon_name(f2->externalName()));
                    mutex_fields.insert(mfname);
                }
            }
            int last_stage = PhvInfo::getDeparserStage();

            int alloc_min = (alloc.min_stage.second.isWrite()) ?
                        alloc.min_stage.first + 1 : alloc.min_stage.first;
            int alloc_max = (alloc.max_stage.second.isWrite()) ?
                        alloc.max_stage.first + 1 : alloc.max_stage.first;

            int newMin = min, newMax = max;
            // Skip POV bits as they are always used in deparser
            if (!f->pov) {
                // FIXME: Skip Tofino field slices, since slice information does
                // not reflect the correct deparser stage. The deparser stage
                // value is set through the table dependency graph based on min
                // stage calculation. After table placement, no. of stages can
                // be >= min stage. However the slices created for phv
                // allocation already have the min stage info which is
                // incorrect. This needs to be updated after table placement.
                // This needs revisiting if/when stage based phv allocation is
                // implemented for Tofino Ideally this check should go away once
                // slices have updated info on max stage.
                if (Device::currentDevice() != Device::TOFINO) {
                    // Defuse information coming through livemap does not
                    // account for stage based allocation in TOFINO2+
                    // architectures. This information is provided through
                    // min/max stage values in field slices. Here, we adjust the
                    // live range based on slice info
                    if (alloc_min > min) newMin = alloc_min;
                    if (alloc_max < max && alloc_max != last_stage) newMax = alloc_max;
                }
            }

            FieldUse fuse = { fname, f->gress, newMin, newMax, mutex_fields };
            auto &fieldsInContainer = lr[f->gress][c];
            fieldsInContainer[fname].push_back(fuse);
            LOG5(" Slice : " << alloc
                      << ", Slice min stage : " << alloc.min_stage
                      << ", Slice max stage : " << alloc.max_stage
                      << ", Parsed : " << f->parsed()
                      << ", Deparsed : " << f->deparsed()
                      << ", New min stage : " << newMin
                      << ", New max stage : " << newMax);
        });
    }
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
        // // Collect all fields used on a per container basis with required live
        // // range info for assembly. This info is used by P4i hence only output
        // // when debug flag is set.
        if (live_range_report) {
            LiveRangePerContainer lr;
            int maxStages = live_range_report->get_max_stages();
            getLiveRanges(lr);
            for (auto cf : lr[gress]) {
                out << "    " << cf.first << ":\n";
                for (auto f : cf.second) {
                    auto fuses = f.second;
                    auto fname = f.first;
                    for (auto fuse : fuses) {
                        auto live_start = fuse.get_live_start(maxStages);
                        auto live_end = fuse.get_live_end(maxStages);
                        out << "    - { name : " << fname      << ", ";
                        out << "live_start : " << live_start << ", ";
                        out << "live_end : "   << live_end   << ", ";
                        out << "mutually_exclusive_with: [ ";
                        std::string sep = "";
                        for (auto mf : fuse.mutex_fields) {
                            out << sep << mf;
                           if (sep == "") sep = ", ";
                        }
                        out << " ] }" << std::endl;
                    }
                }
            }
        } else {
            ::warning("Live range information not generated in assembly/context.json");
        }
    }
}

std::ostream &operator<<(std::ostream &out, const PhvAsmOutput& phvasm) {
    phvasm.emit_gress(out, INGRESS);
    phvasm.emit_gress(out, EGRESS);
    if (phvasm.have_ghost)
        phvasm.emit_gress(out, GHOST);
    return out;
}
