#include "cluster_phv_slicing.h"
#include "lib/log.h"

//***********************************************************************************
//
// Slicing takes two steps
// 1. iterate all field in a cluster, check if all operations on a field are move based.
//  - if true, the cluster can be sliced.
//  - else, the cluster cannot sliced.
// 2. slicing the cluster by half, or +/- 1 bit around the center.
//
//***********************************************************************************

const IR::Node *
Cluster_Slicing::apply_visitor(const IR::Node *node, const char *name) {
    LOG3("..........Cluster_PHV_Slicing::apply_visitor()..........");
    if (name) {
        LOG1(name);
    }
    std::list<Cluster_PHV *> clusters_remove;
    std::list<Cluster_PHV *> clusters_add;
    LOG3("....... Cluster to be sliced ("
        << phv_mau_i.phv_clusters().size()
        << ")...");
    for (auto &cl : phv_mau_i.phv_clusters()) {
        // decide if a cluster is sliceable.
        // A cluster is sliceable if:
        // - all fields in the cluster are uniform in size
        // - no POV fields
        // - no ccgf fields
        // - all operations on fields are move-based (define move)
        //
        // do not slice non-uniform cluster
        if (!cl->uniform_width()) {
            LOG3("... skip non-uniform clusters ...");
            continue;
        }
        if (cl->max_width() <= 1) {
            // cannot slice cluster with field of size 1
            continue;
        }
        bool sliceable = true;
        for (auto &f : cl->cluster_vec()) {
            // do not slice pov group
            if (f->pov) {
                sliceable = false;
                break;
            }
            // do not slice cluster with ccgf (container contiguous group fields)
            if (f->ccgf != NULL) {
                sliceable = false;
                break;
            }
            for (auto &op : f->operations) {
                // element 0 in tuple is 'is_move_op'
                if (std::get<0>(op) != true) {
                    sliceable = false;
                    break;
                }
            }
            if (!sliceable)
                break;
        }
        // create new clusters
        if (sliceable) {
            LOG3("... cluster is sliceable ..." << cl->max_width());
            std::string id = cl->id();
            Cluster_PHV *m_lo = new Cluster_PHV(cl->cluster_vec()[0], -1, id);
            Cluster_PHV *m_hi = new Cluster_PHV(cl->cluster_vec()[0], -1, id);
            m_lo->sliceable(true);
            m_hi->sliceable(true);
            for (auto &f : cl->cluster_vec()) {
                int phv_use_lo_0, phv_use_hi_0, phv_use_lo_1, phv_use_hi_1;
                phv_use_lo_0 = phv_use_hi_0 = phv_use_lo_1 = phv_use_hi_1 = 0;
                // if cluster has been sliced before, use _lo and _hi from the slices.
                if (cl->sliceable()) {
                    phv_use_lo_0 = cl->field_slices()[f].first;
                    phv_use_hi_0 = phv_use_lo_0 + cl->max_width() / 2 - 1;
                    phv_use_lo_1 = phv_use_lo_0 + cl->max_width() / 2;
                    phv_use_hi_1 = cl->field_slices()[f].second;
                } else {
                    // else use _lo and _hi from original field.
                    phv_use_lo_0 = f->phv_use_lo;
                    phv_use_hi_0 = f->phv_use_lo + f->size / 2 - 1;
                    phv_use_lo_1 = f->phv_use_lo + f->size / 2;
                    phv_use_hi_1 = f->phv_use_hi;
                }
                LOG3("... cluster sliced width ..."
                        << phv_use_lo_0
                        << "..."
                        << phv_use_hi_0
                        << "..."
                        << phv_use_lo_1
                        << "..."
                        << phv_use_hi_1
                        << "...");
                m_lo->field_slices().emplace(f,
                        std::make_pair(phv_use_lo_0, phv_use_hi_0));
                m_lo->max_width(phv_use_hi_0 - phv_use_lo_0 + 1);
                m_hi->field_slices().emplace(f,
                        std::make_pair(phv_use_lo_1, phv_use_hi_1));
                m_hi->max_width(phv_use_hi_1 - phv_use_lo_1 + 1);
                LOG3("... "
                        << m_lo->max_width()
                        << "..."
                        << m_hi->max_width());
            }
            clusters_add.push_back(m_lo);
            clusters_add.push_back(m_hi);
            // remove clusters already sliced
            clusters_remove.push_back(cl);
        }
    }
    // remove sliced PHV
    for (auto &cl : clusters_remove) {
        phv_mau_i.phv_clusters().remove(cl);
    }
    // add generated PHV
    for (auto &cl : clusters_add) {
        // modify cluster reflect slicing
        phv_mau_i.phv_clusters().push_back(cl);
    }
    LOG3("....... Cluster after slicing ("
        << phv_mau_i.phv_clusters().size()
        << ")...");
    return node;
}

//***********************************************************************************
//
// fit clusters to slices again at the end of the pass
//
//***********************************************************************************

void Cluster_Slicing::end_apply() {
    // phv_mau_i.status (phv_mau_i.phv_clusters());
    // phv_mau_i.status (phv_mau_i.aligned_container_slices());
    phv_mau_i.container_pack_cohabit(phv_mau_i.phv_clusters(),
                                     phv_mau_i.aligned_container_slices());
}
