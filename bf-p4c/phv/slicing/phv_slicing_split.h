#ifndef BF_P4C_PHV_SLICING_PHV_SLICING_SPLIT_H_
#define BF_P4C_PHV_SLICING_PHV_SLICING_SPLIT_H_

#include <utility>

#include <boost/optional.hpp>

#include "lib/bitvec.h"
#include "lib/ordered_map.h"

#include "bf-p4c/phv/utils/utils.h"

/** PHV Slicing Split functions
 * Basic functions to split a supercluster.
 */

namespace PHV {
namespace Slicing {

// Helper type
using ListClusterPair = std::pair<SuperCluster::SliceList*, const RotationalCluster*>;
using SplitSchema = ordered_map<SuperCluster::SliceList*, bitvec>;

/// Split a SuperCluster with slice lists according to @split_schema. Apply this function
/// on SuperCluster with slice_lists only. The @p schema maps slice lists to the split point.
boost::optional<std::list<SuperCluster*>> split(const SuperCluster* sc, const SplitSchema& schema);

/// Split the RotationalCluster in a SuperCluster without a slice list
/// according to @split_schema. Because there is no slice lists in the super cluster
/// the @p split_schema is a bitvec that a `1` on n-th bit means to split before the
/// the n-th bit.
boost::optional<std::list<PHV::SuperCluster*>> split_rotational_cluster(
    const PHV::SuperCluster* sc, bitvec split_schema);

}  // namespace Slicing
}  // namespace PHV

std::ostream& operator<<(std::ostream& out, const PHV::Slicing::ListClusterPair& pair);
std::ostream& operator<<(std::ostream& out, const PHV::Slicing::ListClusterPair* pair);
std::ostream& operator<<(std::ostream& out, const PHV::Slicing::SplitSchema& schema);

#endif /* BF_P4C_PHV_SLICING_PHV_SLICING_SPLIT_H_ */
