#include "cluster_phv_slicing.h"
#include "lib/log.h"

//***********************************************************************************
//
// Cluster Slicing
//
// slice clusters into smaller clusters
// attempt packing with reduced width requirements
// slicing also improves overlay possibilities due to lesser width
// although number and mutual exclusion of fields don't change
//
// 1. iterate over all fields in cluster,
//    if all operations on field are "move" based
//        cluster can be sliced
//    else
//        cluster cannot sliced
//
// 2. slice cluster by half, or +/- 1-bit around center
//
//***********************************************************************************
//

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
    // PHV Slices
    //
    if (phv_mau_i.phv_clusters().size() && phv_mau_i.aligned_container_slices().size()) {
        const char *tag = (const char *)"Sliced_PHV";
        LOG3(".........." << tag << "..........");
        cluster_slice(phv_mau_i.phv_clusters());
        //
        // pack cluster slices to PHV containers empty slots
        //
        phv_mau_i.container_pack_cohabit(
            phv_mau_i.phv_clusters(),
            phv_mau_i.aligned_container_slices(),
            tag);
    }
    // T_PHV Slices
    //
    if (phv_mau_i.t_phv_clusters().size() && phv_mau_i.T_PHV_container_slices().size()) {
        const char *tag = (const char *)"Sliced_T_PHV_to_T_PHV";
        LOG3(".........." << tag << "..........");
        cluster_slice(phv_mau_i.t_phv_clusters());
        //
        // pack cluster slices to T_PHV containers empty slots
        //
        phv_mau_i.container_pack_cohabit(
            phv_mau_i.t_phv_clusters(),
            phv_mau_i.T_PHV_container_slices(),
            tag);
    }
    if (phv_mau_i.t_phv_clusters().size() && phv_mau_i.aligned_container_slices().size()) {
        //
        // pack cluster slices to PHV containers empty slots
        //
        const char *tag = (const char *)"Sliced_T_PHV_to_PHV";
        LOG3(".........." << tag << "..........");
        phv_mau_i.container_pack_cohabit(
            phv_mau_i.t_phv_clusters(),
            phv_mau_i.aligned_container_slices(),
            tag);
    }
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
Cluster_Slicing::cluster_slice(std::list<Cluster_PHV *>& cluster_list) {
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
            if (f->ccgf != NULL) {
                sliceable = false;
                break;
            }
            // no constraints on f
            if (f->constrained()) {
                sliceable = false;
                break;
            }
            // "move"-based ops only -- don't care for T_PHV fields
            for (auto &op : f->operations) {
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
    // remove sliced PHV
    for (auto &cl : clusters_remove) {
        cluster_list.remove(cl);
    }
    // add generated PHV
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
