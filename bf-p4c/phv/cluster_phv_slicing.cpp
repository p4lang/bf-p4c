#include "cluster_phv_slicing.h"
#include "lib/log.h"
#include "bf-p4c/ir/bitrange.h"

const IR::Node *
Cluster_Slicing::apply_visitor(const IR::Node *node, const char *name) {
    //
    if (name) {
        LOG1(name);
    }
    if (!phv_mau_i.phv_clusters().size() && !phv_mau_i.t_phv_clusters().size()) {
        LOG3("++++++++++++++++++++Cluster_PHV_Slicing NOT NEEDED++++++++++++++++++++");
        return node;
    }
    LOG3("Begin..............................Cluster_PHV_Slicing..............................");
    LOG3("\tPHV Clusters = " << phv_mau_i.phv_clusters().size());
    LOG3("\tPHV aligned_slices available = " << phv_mau_i.aligned_container_slices().size());
    LOG3("\tT_PHV Clusters = " << phv_mau_i.t_phv_clusters().size());
    LOG3("\tT_PHV aligned_slices available = " << phv_mau_i.T_PHV_container_slices().size());
    //
    // PHV Slices
    //
    if (phv_mau_i.phv_clusters().size() && phv_mau_i.aligned_container_slices().size()) {
        const char *tag = (const char *)"Sliced_PHV";
        LOG3(".........." << tag << "..........");
        //
        cluster_slice(phv_mau_i.phv_clusters());
        //
        if (!gress_compatibility(
                phv_mau_i.phv_requirements().gress(phv_mau_i.phv_clusters()),
                phv_mau_i.gress(phv_mau_i.aligned_container_slices()))) {
            LOG3("...................."
                << tag
                << ": gress incompatible, No Packing ....................");
        } else {
            //
            // pack cluster slices to PHV containers empty slots
            //
            phv_mau_i.container_pack_cohabit(
                phv_mau_i.phv_clusters(),
                phv_mau_i.aligned_container_slices(),
                tag);
        }
    }
    // T_PHV Slices
    //
    bool t_phv_clusters_sliced = false;
    if (phv_mau_i.t_phv_clusters().size() && phv_mau_i.T_PHV_container_slices().size()) {
        const char *tag = (const char *)"Sliced_T_PHV_to_T_PHV";
        LOG3(".........." << tag << "..........");
        //
        cluster_slice(phv_mau_i.t_phv_clusters());
        t_phv_clusters_sliced = true;
        //
        if (!gress_compatibility(
                phv_mau_i.phv_requirements().gress(phv_mau_i.t_phv_clusters()),
                phv_mau_i.gress(phv_mau_i.T_PHV_container_slices()))) {
            LOG3("...................."
                << tag
                << ": gress incompatible, No Packing ....................");
        } else {
            //
            // pack cluster slices to T_PHV containers empty slots
            //
            phv_mau_i.container_pack_cohabit(
                phv_mau_i.t_phv_clusters(),
                phv_mau_i.T_PHV_container_slices(),
                tag);
        }
    }
    if (phv_mau_i.t_phv_clusters().size() && phv_mau_i.aligned_container_slices().size()) {
        //
        // pack cluster slices to PHV containers empty slots
        //
        const char *tag = (const char *)"Sliced_T_PHV_to_PHV";
        LOG3(".........." << tag << "..........");
        //
        if (!t_phv_clusters_sliced) {
            cluster_slice(phv_mau_i.t_phv_clusters());
            t_phv_clusters_sliced = true;
        }
        //
        if (!gress_compatibility(
                phv_mau_i.phv_requirements().gress(phv_mau_i.t_phv_clusters()),
                phv_mau_i.gress(phv_mau_i.aligned_container_slices()))) {
            LOG3("...................."
                << tag
                << ": gress incompatible, No Packing ....................");
        } else {
            //
            phv_mau_i.container_pack_cohabit(
                phv_mau_i.t_phv_clusters(),
                phv_mau_i.aligned_container_slices(),
                tag);
        }
    }
    //
    sanity_check_cluster_slices("Cluster_Slicing::apply_visitor()");
    //
    LOG3(*this);
    LOG3("\tPHV Clusters = " << phv_mau_i.phv_clusters().size());
    LOG3("\tPHV aligned_slices available = " << phv_mau_i.aligned_container_slices().size());
    LOG3("\tT_PHV Clusters = " << phv_mau_i.t_phv_clusters().size());
    LOG3("\tT_PHV aligned_slices available = " << phv_mau_i.T_PHV_container_slices().size());
    LOG3("End..............................Cluster_PHV_Slicing..............................");
    //
    return node;
}  // apply_visitor

bool
Cluster_Slicing::gress_compatibility(
    std::pair<int, int> gress_pair_1,
    std::pair<int, int> gress_pair_2) {
    //
    return (gress_pair_1.first && gress_pair_2.first)
        || (gress_pair_1.second && gress_pair_2.second);
}

std::pair<Cluster_PHV *, Cluster_PHV *>
Cluster_Slicing::cluster_slice(Cluster_PHV *cl) {
    //
    assert(cl);
    Cluster_PHV *slice_lo = new Cluster_PHV(cl /*, lo = true */);
    Cluster_PHV *slice_hi = new Cluster_PHV(cl, false /* lo = false */);
    //
    LOG3("++++++++++ Cluster Sliced ++++++++++");
    LOG3(cl << slice_lo << slice_hi);
    //
    return std::make_pair(slice_lo, slice_hi);
}  // cluster_slice single cluster

void
Cluster_Slicing::cluster_slice(
    std::list<Cluster_PHV *>& cluster_list) {
    //
    std::list<Cluster_PHV *> clusters_remove;
    std::list<Cluster_PHV *> clusters_add;
    LOG3(".......... Clusters to be sliced ("
        << cluster_list.size()
        << ")..........");
    for (auto &cl : cluster_list) {
        //
        // cluster sliceable if:
        // all fields in the cluster are uniform in size
        // no POV fields
        // no ccgf fields
        // all operations on fields are "move"-based -- op does not affect surround container bits
        //
        // do not slice non-uniform cluster
        if (!cl->uniform_width()) {
            continue;
        }
        // cannot slice cluster with fields of size 1
        if (cl->max_width() <= 1) {
            continue;
        }
        bool sliceable = true;
        for (auto &f : cl->cluster_vec()) {
            // do not slice pov
            if (f->pov) {
                sliceable = false;
                break;
            }
            // do not slice ccgf (container contiguous group field)
            if (f->ccgf() != NULL) {
                sliceable = false;
                break;
            }
            // no constraints on f
            if (f->constrained()) {
                sliceable = false;
                break;
            }
            // do not slice deparsed fields as slices need contiguity
            // need to place all bits contiguously so they can be (de)parsed
            if (f->deparsed()) {
                sliceable = false;
                break;
            }
            // "move"-based ops only -- don't care for T_PHV fields
            for (auto &op : f->operations()) {
                // element 0 in tuple is 'is_move_op'
                if (std::get<0>(op) != true) {
                    sliceable = false;
                    break;
                }
            }
            if (!sliceable) {
                break;
            }
        }  // for
        // create new clusters
        if (sliceable) {
            std::pair<Cluster_PHV *, Cluster_PHV *> cl_slices = cluster_slice(cl);
            clusters_add.push_back(cl_slices.first);
            clusters_add.push_back(cl_slices.second);
            clusters_remove.push_back(cl);
        }
    }  // for
    // remove sliced parents
    for (auto &cl : clusters_remove) {
        cluster_list.remove(cl);
    }
    // add generated slices
    for (auto &cl : clusters_add) {
        cluster_list.push_back(cl);
    }
    LOG3(".......... Clusters after Slicing ("
        << cluster_list.size()
        << ")..........");
}  // cluster_slice list of clusters

//
//***********************************************************************************
//
// sanity checks
//
//***********************************************************************************
//
//
void
Cluster_Slicing::sanity_check_cluster_slices(const std::string& msg) {
    //
    const std::string msg_1 = msg + "..Cluster_Slicing::sanity_check_cluster_slices";
    for (auto &f : phv_l) {
        if (f.sliced()) {
            // there must be field slices
            BUG_CHECK(!f.field_slices().empty(),
                "sliced cluster has no field slices for %1%", cstring::to_cstring(f));
            // every slice has unique cl_id
            // no overlapping slices
            // all slices correctly add up to unsliced field width
            ordered_set<std::string> set_of_cl_ids;
            ordered_set<std::pair<int, int>> set_of_ranges;
            int slice_widths = 0;
            for (auto &e : f.field_slices()) {
                std::string id = e.first->id();
                BUG_CHECK(!set_of_cl_ids.count(id),
                    "cluster ids for slices not unique id=%1%, f= %2%", id, cstring::to_cstring(f));
                set_of_cl_ids.insert(id);
                //
                int lo = e.second.first;
                int hi = e.second.second;
                for (auto &r : set_of_ranges) {
                    int lo_r = r.first;
                    int hi_r = r.second;
                    BUG_CHECK(!((lo_r >= lo && lo_r <= hi) || (hi_r >= lo && hi_r <= hi)),
                        "cluster slice ranges overlap <%1%,%2%><%3%,%4%> f=%5%", lo, hi, lo_r, hi_r,
                        cstring::to_cstring(f)); }  // for
                set_of_ranges.insert({lo, hi});
                slice_widths += hi - lo + 1; }  // for
            BUG_CHECK(slice_widths == f.size,
                "adding cluster slice ranges != field size, slice_widths=%1%, f.size=%2%, f=%3%",
                slice_widths, f.size, cstring::to_cstring(f));
            // several field slices in container must be orderly allocated
            // parser can't support two slices allocated to the same container but not in order.
            // slices placed in the wrong order can result in flip around on the wire when deparsed.
            for (auto* c : f.phv_containers()) {
                auto cc_list = c->fields_in_container()[&f];
                if (cc_list.size() > 1) {
                    ordered_map<int, le_bitrange> flo_cbits;
                    for (auto* cc : cc_list)
                        flo_cbits[cc->field_bit_lo()] = FromTo(cc->lo(), cc->hi());
                    le_bitinterval usedBits;
                    for (auto x : Values(flo_cbits)) {
                        // field slice ranges, ascending field bits,
                        // ensure x.lo > previous hi && x.hi >= x.lo
                        BUG_CHECK(!usedBits.overlaps(toHalfOpenRange(x)),
                            "field slices for field %1% placed disorderly in container %2%, lo=%3%",
                            cstring::to_cstring(f), cstring::to_cstring(c), x.lo);
                            usedBits = usedBits.unionWith(FromTo(0, x.hi)); }}}}}  // forall f
}  // sanity_check_cluster_slices

//
//***********************************************************************************
//
// output stream <<
//
//***********************************************************************************
//
//

std::ostream &operator<<(std::ostream &out, Cluster_Slicing &cluster_slicing) {
    out << std::endl
        << cluster_slicing.phv_mau()
        << std::endl;
    return out;
}

//
//***********************************************************************************
//
// Notes
//
//***********************************************************************************
//
// Note 1
//
// Is it for two or more container slices in the same field to be allocated to the same container?
//
// even without recursive slicing, two slices can land in the same container
// consider a cluster with 2 fields f1<16> f2<16> but available containers in group are
// C1<16b> C2<8b out of 16b> and C3 <8b out of 16b>
// so, initially no fit
// after cluster slicing, f21, f22 in C2, C3, whereas f11, f12 in C1
//
// if we recursively slice,
// it is possible for two or more slices of the same field to land in the same container
// e.g., we have field f1<16b> but available space = two containers having 8b avail each
// f1 sliced into f11, f12 and further to f111, f112, f121, f122 each 4b wide.
// each of the above 2 containers will contain 2 slices of the same field
//
// Note 2
//
// inter-cluster overlaying, slices overlaid fields the same as the field being overlaid.
// however this will not give rise to two slices of the same field being the same container
//
