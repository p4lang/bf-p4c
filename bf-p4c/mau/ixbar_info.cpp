#include "bf-p4c/common/table_printer.h"
#include "bf-p4c/logging/filelog.h"
#include "bf-p4c/mau/ixbar_info.h"
#include "bf-p4c/phv/phv_fields.h"

namespace BFN {

Visitor::profile_t CollectIXBarInfo::init_apply(const IR::Node* node) {
    auto rv = Inspector::init_apply(node);
    _stage.clear();
    _byteToTables.clear();
    return rv;
}

void CollectIXBarInfo::postorder(const IR::MAU::Table *tbl) {
    unsigned stage = tbl->logical_id / StageUse::MAX_LOGICAL_IDS;
    if (!tbl->resources->match_ixbar.ternary)
        return;
    for (auto& use : tbl->resources->match_ixbar.use) {
        _stage[stage].push_back(use);
        _byteToTables[use] = tbl;
    }
}

// Sort Use::Byte by (group, byte) tuple.
void CollectIXBarInfo::sort_ixbar_byte() {
    for (auto& stage : _stage) {
        std::sort(stage.second.begin(), stage.second.end(),
                [](const IXBar::Use::Byte &a, const IXBar::Use::Byte &b) {
                    if (a.loc.group != b.loc.group)
                        return a.loc.group < b.loc.group;
                    return a.loc.byte < b.loc.byte;
                });
    }
}

std::string CollectIXBarInfo::print_ixbar_byte() const {
    std::stringstream out;
    out << "TCAM IXBar Allocation:" << std::endl;

    TablePrinter tp(out, {"Stage", "Ord", "Group", "Byte", "Fields", "Bits", "PHV"},
                    TablePrinter::Align::CENTER);
    static PHV::FieldUse READ(PHV::FieldUse::READ);
    for (auto& stage : _stage) {
        tp.addSep();
        for (auto& use : stage.second) {
            BUG_CHECK(_byteToTables.count(use),
                      "No table found for input crossbar use.");
            const IR::MAU::Table* ctxt = _byteToTables.at(use);
            for (auto& fi : use.field_bytes) {
                auto *field = phv.field(fi.field);
                std::stringstream alloc;
                le_bitrange range = StartLen(fi.lo, fi.hi - fi.lo + 1);
                field->foreach_alloc(range, ctxt, &READ, [&](const PHV::Field::alloc_slice &slice) {
                    if (slice.field_bits().overlaps(fi.lo, fi.hi)) {
                        alloc << slice.container << " " << slice.container_bits();
                    }
                });
                tp.addRow({std::to_string(stage.first),
                           std::to_string(use.loc.getOrd(true)),
                           std::to_string(use.loc.group),
                           std::to_string(use.loc.byte),
                           fi.visualization_detail(),
                           std::to_string(fi.width()),
                           alloc.str()});
            }
        }
    }
    tp.print();
    out << std::endl;

    return out.str();
}

void CollectIXBarInfo::end_apply(const IR::Node *root) {
    const IR::BFN::Pipe *pipe = root->to<IR::BFN::Pipe>();
    Logging::FileLog ixbarLog(pipe->id, "ixbar.log");
    sort_ixbar_byte();
    LOG2(print_ixbar_byte());
}

}  // namespace BFN
