#ifndef EXTENSIONS_BF_P4C_PHV_ANALYSIS_FIELD_INTERFERENCE_H_
#define EXTENSIONS_BF_P4C_PHV_ANALYSIS_FIELD_INTERFERENCE_H_

#include "bf-p4c/phv/make_clusters.h"
#include "bf-p4c/phv/utils/utils.h"
#include "ir/ir.h"
#include "lib/ordered_map.h"
#include "lib/symbitmatrix.h"

/** Generate a slice-to-slice interference graph for all input slices and use
  * vertex coloring to create a map from fieldslice to color.
  *
  * The colors are represented as an integer, which is not guaranteed to start
  * from 0, not contiguous.
  *
  * Since we use SliceList as the unit for allocation to a container, all FieldSlices
  * in a single SliceList should be treated as just ONE node in this analysis.
  * It's important to produce an relatively accurate result to evaluate a slicing schema.
  * SliceList's mutually_exclusiveness is defined as:
  * (Forall x from A, y from B, x <--mutually_exclusive--> y) => A <-mutually_exclusive-> B.
  * The reason we do not need to check mutually_exsclusive for contiguous-sublists
  * if A is smaller than B is that all fields in a slice lists are sharing a same live range.
  */
class FieldInterference {
 public:
    using SliceColorMap = std::map<PHV::FieldSlice, int>;
    using SliceVector   = std::vector<PHV::FieldSlice>;

 private:
    /// Internal representation of slice lists.
    using SliceList     = std::vector<PHV::FieldSlice>;
    using SliceListVector = std::vector<SliceList>;

    const SymBitMatrix&               mutex_i;
    const PhvUse&                     uses_i;  // for is_tphv_candidate

    /** @return all slices of the @p gress from @p clusters
      */
    SliceListVector
    getSliceLists(const std::list<PHV::SuperCluster *>& clusters,
                 gress_t gress,
                 bool is_tagalong) const;

    bool is_mutually_exclusive(const SliceList& a, const SliceList& b) const;

    SliceColorMap constructFieldInterference(SliceListVector &slice_lists) const;

    friend std::ostream &operator<<(std::ostream &out,
                                    const FieldInterference::SliceList&);

 public:
    FieldInterference(const SymBitMatrix& mutex_m, const PhvUse& uses)
        : mutex_i(mutex_m), uses_i(uses) { }

    /** Build a fieldslice interference graph for all the slices
      * @returns a SliceColorMap that map a PHV::FieldSlice to its color.
      */
    SliceColorMap
    calcSliceInterference(const std::list<PHV::SuperCluster *>& clusters) const;

    /** Pretty print a SliceColorMap, containing the results of vertex coloring on the field
      * interference graph
      */
    void printFieldColorMap(SliceColorMap& m) const;
};  // class FieldInterference

std::ostream &operator<<(std::ostream &out, const FieldInterference::SliceList&);

#endif /* EXTENSIONS_BF_P4C_PHV_ANALYSIS_FIELD_INTERFERENCE_H_ */
