#include "mau_group_extractor.h"

using MauGroup = MauGroupExtractor::MauGroup;

bool MauGroupExtractor::isFieldInAnyGroup(const cstring &name) const {
    return fieldToGroupMap.find(name) != fieldToGroupMap.end();
}

std::vector<const MauGroup*> MauGroupExtractor::getGroups(const cstring &name) const {
    BUG_CHECK(isFieldInAnyGroup(name), "Field %s is not present in any MAU group!", name.c_str());

    std::vector<const MauGroup*> result;
    for (auto &item : fieldToGroupMap.at(name)) {
        result.push_back(&groups[item]);
    }

    return result;
}

bool MauGroupExtractor::superClusterContainsOnlySingleField(const PHV::SuperCluster *sc) const {
    cstring fieldName = "";
    return sc->all_of_fieldslices([&fieldName] (const PHV::FieldSlice &slice) {
        if (fieldName == "") fieldName = slice.field()->name;
        return fieldName == slice.field()->name;
    });
}

MauGroupExtractor::MauGroupExtractor(const std::list<PHV::SuperCluster*> &clusterGroups,
                                      const ConstrainedFieldMap &map) {
    for (auto &sc : clusterGroups) {
        if (superClusterContainsOnlySingleField(sc)) continue;

        groups.push_back(MauGroup());
        auto &group = groups.back();
        unsigned groupId = groups.size() - 1;

        sc->forall_fieldslices([&] (const PHV::FieldSlice &slice) {
            auto &field = map.at(slice.field()->name);

            for (auto &ls : field.getSlices()) {
                if (slice.range() != ls.getRange()) continue;

                group.push_back(ls);
                fieldToGroupMap[field.getName()].insert(groupId);
            }
        });
    }
}
