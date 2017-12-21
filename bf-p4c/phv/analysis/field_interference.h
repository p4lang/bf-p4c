#ifndef EXTENSIONS_BF_P4C_PHV_ANALYSIS_FIELD_INTERFERENCE_H_
#define EXTENSIONS_BF_P4C_PHV_ANALYSIS_FIELD_INTERFERENCE_H_

#include "bf-p4c/phv/make_clusters.h"
#include "bf-p4c/phv/utils.h"
#include "ir/ir.h"
#include "lib/ordered_map.h"
#include "lib/symbitmatrix.h"

/** Generate a slice-to-slice interference graph for all input slices and use
  * vertex coloring to create a map from fieldslice to color.
  *
  * The colors are represented as an integer, which is not guaranteed to start
  * from 0, not contiguous.
  */
class FieldInterference {
 public:
    using SliceColorMap = std::map<PHV::FieldSlice, int>;
    using SliceVector   = std::vector<PHV::FieldSlice>;

 private:
    const SymBitMatrix&               mutex_i;

    /** @return all slices of the @p gress from @p clusters
      */
    SliceVector
    getAllSlices(const std::list<PHV::SuperCluster *>& clusters,
                 gress_t gress,
                 bool is_tagalong) const;

    SliceColorMap constructFieldInterference(SliceVector &fields) const;

 public:
    explicit FieldInterference(const SymBitMatrix& mutex_m)
        : mutex_i(mutex_m) { }

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

#endif /* EXTENSIONS_BF_P4C_PHV_ANALYSIS_FIELD_INTERFERENCE_H_ */
