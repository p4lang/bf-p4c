#ifndef BF_P4C_LOGGING_MAU_GROUP_EXTRACTOR_H_
#define BF_P4C_LOGGING_MAU_GROUP_EXTRACTOR_H_

#include <vector>
#include <map>
#include <set>

#include "bf-p4c/phv/phv_fields.h"
#include "bf-p4c/phv/utils/utils.h"
#include "bf-p4c/logging/constrained_fields.h"

class PhvInfo;

/**
 *  Class for extracting MAU Group information from result of Clustering class
 */
class MauGroupExtractor {
 public:
    using MauGroup = std::vector<ConstrainedSlice>;

 private:
    std::vector<MauGroup> groups;
    std::map<cstring, std::set<unsigned>> fieldToGroupMap;  // Key is name of the field

    bool superClusterContainsOnlySingleField(const PHV::SuperCluster *sc) const;

 public:
    // For a given field, check whether it is contained in any group
    bool isFieldInAnyGroup(const cstring &name) const;

    std::vector<const MauGroup*> getGroups(const cstring &name) const;

    MauGroupExtractor(const std::list<PHV::SuperCluster*> &clusterGroups,
                       const ConstrainedFieldMap &map);
};

#endif  /* BF_P4C_LOGGING_MAU_GROUP_EXTRACTOR_H_ */
