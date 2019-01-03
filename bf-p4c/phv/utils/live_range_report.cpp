#include "bf-p4c/phv/utils/live_range_report.h"
#include "bf-p4c/common/table_printer.h"

cstring use_type(unsigned use) {
    if (use == 0) return "";
    std::stringstream ss;
    bool checkLiveness = true;
    if (use & LiveRangeReport::READ) {
        ss << "R";
        checkLiveness = false;
    }
    if (use & LiveRangeReport::WRITE) {
        ss << "W";
        checkLiveness = false;
    }
    if (checkLiveness && (use & LiveRangeReport::LIVE))
        ss << "~";
    return ss.str();
}

std::map<int, unsigned> LiveRangeReport::processUseDefSet(
        const FieldDefUse::LocPairSet& defuseSet,
        unsigned usedef) const {
    const int DEPARSER = maxStages;
    const int PARSER = -1;
    std::map<int, unsigned> fieldMap;
    for (const FieldDefUse::locpair use : defuseSet) {
        const IR::BFN::Unit* use_unit = use.first;
        if (use_unit->is<IR::BFN::ParserState>() || use_unit->is<IR::BFN::Parser>()) {
            auto* ps = use_unit->to<IR::BFN::ParserState>();
            cstring use_location;
            if (!ps)
                use_location = " to parser";
            else
                use_location = " to parser state " + ps->name;
            fieldMap[PARSER] |= usedef;
            LOG4("\tAssign " << use_type(usedef) << use_location);
        } else if (use_unit->is<IR::BFN::Deparser>()) {
            fieldMap[DEPARSER] |= usedef;
            LOG4("\tAssign " << use_type(usedef) << " to deparser");
        } else if (use_unit->is<IR::MAU::Table>()) {
            const auto* t = use_unit->to<IR::MAU::Table>();
            auto stages = alloc.stages(t);
            for (auto stage : stages) {
                fieldMap[stage] |= usedef;
                LOG4("\tAssign " << use_type(usedef) << " to stage " << stage);
            }
        } else {
            BUG("Unknown unit encountered %1%", use_unit->toString());
        }
    }
    return fieldMap;
}

void LiveRangeReport::setFieldLiveMap(
        const PHV::Field* f,
        ordered_map<const PHV::Field*, std::map<int, unsigned>>& livemap) const {
    auto usemap = processUseDefSet(defuse.getAllUses(f->id), READ);
    auto defmap = processUseDefSet(defuse.getAllDefs(f->id), WRITE);
    // Combine the maps into a single map.
    for (auto kv : defmap)
        usemap[kv.first] |= kv.second;
    int min = maxStages + 1;
    int max = -2;
    for (auto kv : usemap) {
        min = kv.first < min ? kv.first : min;
        max = kv.first > max ? kv.first : max;
    }
    LOG4("Min-max for " << f->name << " : [" << min << ", " << max << "]");
    if (min != maxStages + 1 && max != -2) {
        for (int i = min; i <= max; i++)
            usemap[i] |= LIVE;
    }
    livemap[f] = usemap;
}

cstring LiveRangeReport::printFieldLiveness(
        const ordered_map<const PHV::Field*, std::map<int, unsigned>>& livemap) {
    std::stringstream ss;
    ss << std::endl << "Live Ranges for Fields:" << std::endl;
    std::vector<std::string> headers;
    headers.push_back("Field");
    headers.push_back("Bit Size");
    headers.push_back("P");
    for (int i = 0; i < maxStages; i++)
        headers.push_back(std::to_string(i));
    headers.push_back("D");
    TablePrinter tp(ss, headers, TablePrinter::Align::LEFT);
    for (auto kv : livemap) {
        std::vector<std::string> row;
        // Add field name.
        row.push_back(std::string(kv.first->name));
        row.push_back(std::to_string(kv.first->size));
        for (int i = -1; i <= maxStages; i++) {
            if (kv.second.count(i)) {
                row.push_back(std::string(use_type(kv.second.at(i))));
                if (kv.second.at(i) & READ)
                    stageToReadBits[i] += kv.first->size;
                if (kv.second.at(i) & WRITE)
                    stageToWriteBits[i] += kv.first->size;
                if (kv.second.at(i) & LIVE)
                    stageToLiveBits[i] += kv.first->size;
            } else {
                row.push_back("");
            }
        }
        tp.addRow(row);
    }
    tp.print();
    return ss.str();
}

std::vector<std::string> LiveRangeReport::createStatRow(
        std::string title,
        const std::map<int, int>& data) const {
    std::vector<std::string> rv;
    rv.push_back(title);
    for (int i = -1; i <= maxStages; i++) {
        if (data.count(i))
            rv.push_back(std::to_string(data.at(i)));
        else
            rv.push_back(std::to_string(0));
    }
    return rv;
}

cstring LiveRangeReport::printBitStats() const {
    std::stringstream ss;
    ss << std::endl << "Number of bits per stage:" << std::endl;
    std::vector<std::string> headers;
    headers.push_back("Statistic");
    headers.push_back("P");
    for (int i = 0; i < maxStages; i++)
        headers.push_back(std::to_string(i));
    headers.push_back("D");
    TablePrinter tp(ss, headers, TablePrinter::Align::LEFT);
    tp.addRow(createStatRow("Bits Read", stageToReadBits));
    tp.addRow(createStatRow("Bits Written", stageToWriteBits));
    tp.addRow(createStatRow("Bits Live", stageToLiveBits));
    tp.print();
    return ss.str();
}

Visitor::profile_t LiveRangeReport::init_apply(const IR::Node* root) {
    stageToReadBits.clear();
    stageToWriteBits.clear();
    stageToAccessBits.clear();
    stageToLiveBits.clear();

    int maxStagesInAlloc = alloc.maxStages();
    int maxDeviceStages = Device::numStages();
    maxStages = (maxStagesInAlloc > maxDeviceStages) ? maxStagesInAlloc : maxDeviceStages;
    ordered_map<const PHV::Field*, std::map<int, unsigned>> livemap;
    for (const PHV::Field& f : phv)
        setFieldLiveMap(&f, livemap);
    LOG1(printFieldLiveness(livemap));
    LOG1(printBitStats());
    return Inspector::init_apply(root);
}
