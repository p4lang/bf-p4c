#ifndef BF_P4C_LOGGING_GROUP_CONSTRAINT_EXTRACTOR_H_
#define BF_P4C_LOGGING_GROUP_CONSTRAINT_EXTRACTOR_H_

#include <vector>
#include <map>
#include <set>

#include "bf-p4c/phv/phv_fields.h"
#include "bf-p4c/phv/utils/utils.h"
#include "bf-p4c/logging/constrained_fields.h"

class PhvInfo;

/**
 *  \brief Blueprint for group constraint extractor classes
 */
class GroupConstraintExtractor {
 public:
    using Group = std::vector<ConstrainedSlice>;

 protected:
    std::vector<Group> groups;
    std::map<cstring, std::set<unsigned>> fieldToGroupMap;  // Key is name of the field

    void processSlice(unsigned groupId, const PHV::FieldSlice &slice,
                        const ConstrainedFieldMap &map);

 public:
    std::vector<const Group*> getGroups(const cstring &name) const;

    // For a given field, check whether it is contained in any group
    bool isFieldInAnyGroup(const cstring &name) const;
};

/**
 *  Class for extracting MAU Group information from result of Clustering class
 */
class MauGroupExtractor : public GroupConstraintExtractor {
 public:
    using MauGroup = Group;

 private:
    bool superClusterContainsOnlySingleField(const PHV::SuperCluster *sc) const;

 public:
    MauGroupExtractor(const std::list<PHV::SuperCluster*> &clusterGroups,
                       const ConstrainedFieldMap &map);
};

/**
 *  Class for extracting Equivalent Alignment constraint from result of Clustering class
 */
class EquivalentAlignExtractor : public GroupConstraintExtractor {
 private:
    void processCluster(const PHV::AlignedCluster *cluster, const ConstrainedFieldMap &map);

 public:
    EquivalentAlignExtractor(const std::list<PHV::SuperCluster*> &superclusters,
                        const ConstrainedFieldMap &map);
};

#endif  /* BF_P4C_LOGGING_GROUP_CONSTRAINT_EXTRACTOR_H_ */
