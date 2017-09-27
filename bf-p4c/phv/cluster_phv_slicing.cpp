#include "cluster_phv_slicing.h"
#include "lib/log.h"

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
            if (f.field_slices().empty()) {
                LOG1(
                    "*****cluster_phv_slicing.cpp:sanity_FAIL*****....."
                    << msg_1
                    << std::endl
                    << ".....sliced cluster has no field slices....."
                    << std::endl
                    << &f);
            }
            // every slice has unique cl_id
            // no overlapping slices
            // all slices correctly add up to unsliced field width
            //
            ordered_set<std::string> set_of_cl_ids;
            ordered_set<std::pair<int, int>> set_of_ranges;
            int slice_widths = 0;
            for (auto &e : f.field_slices()) {
                //
                std::string id = e.first->id();
                if (set_of_cl_ids.count(id)) {
                    LOG1(
                        "*****cluster_phv_slicing.cpp:sanity_FAIL*****....."
                        << msg_1
                        << std::endl
                        << ".....cluster ids for slices are not unique....."
                        << id
                        << std::endl
                        << &f);
                }
                set_of_cl_ids.insert(id);
                //
                int lo = e.second.first;
                int hi = e.second.second;
                for (auto &r : set_of_ranges) {
                    int lo_r = r.first;
                    int hi_r = r.second;
                    if ((lo_r >= lo && lo_r <= hi)
                        || (hi_r >= lo && hi_r <= hi)) {
                        LOG1(
                            "*****cluster_phv_slicing.cpp:sanity_FAIL*****....."
                            << msg_1
                            << std::endl
                            << ".....cluster ranges for slices overlap....."
                            << " " << lo << ".." << hi
                            << " " << lo_r << ".." << hi_r
                            << std::endl
                            << &f);
                   }
                }
                set_of_ranges.insert({lo, hi});
                slice_widths += hi - lo + 1;
            }  // for
            if (slice_widths != f.size) {
                LOG1(
                    "*****cluster_phv_slicing.cpp:sanity_FAIL*****....."
                    << msg_1
                    << std::endl
                    << ".....cluster slice ranges do not add up to field size....."
                    << "slice_widths = " << slice_widths
                    << " field_size = " << f.size
                    << std::endl
                    << &f);
            }
        }
    }
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
