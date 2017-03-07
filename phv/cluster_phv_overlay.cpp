#include "cluster_phv_mau.h"
#include "cluster_phv_overlay.h"
#include "lib/log.h"
#include "base/logging.h"

//***********************************************************************************
// Use mutex_i() to check if two fields can be overlayed to the same PHV.
// If ccgf, all ccgf fields must be exclusive to all fields in target container.
// If non-ccgf, field must be exclusive to all fields in target container.
// NOTE: This check does not consider field that is smaller than container width,
//       in which case not all fields in target container need to be checked.
//***********************************************************************************

bool Cluster_PHV_Overlay::check_field_with_container(const PhvInfo::Field *field,
                                                     PHV_Container *c) {
    bool can_overlay = false;
    // if overlay candidate field is ccgf
    if (field->ccgf) {
        for (auto *cc : c->fields_in_container()) {
            for (auto *f : field->ccgf_fields) {
                can_overlay = mutex_i(f->id, cc->field()->id);
                if (!can_overlay) {
                    //
                    break;
                }
            }
        }
    } else {
        for (auto *cc : c->fields_in_container()) {
            can_overlay = mutex_i(field->id, cc->field()->id);
            if (!can_overlay) {
                //
                break;
            }
        }
    }
    return can_overlay;
}

//***********************************************************************************
// Overlay one cluster to one MAU group
// Two phases:
// 1. check if the cluster can be overlayed to containers in the mau group.
// 2. if check succeeds, commit the cluster overlay to mau group.
//    else, nothing changes, try next mau group.
//***********************************************************************************

bool Cluster_PHV_Overlay::overlay_cluster_to_group(Cluster_PHV *cl, PHV_MAU_Group *g) {
    //
    // 3a.honor MAU group In/Egress only constraints
    //
    if (phv_mau_i.gress_in_compatibility(g->gress(), cl->gress())) {
        // gress mismatch
        // skip cluster for this MAU group
        //
        return false;
    }
    // try to exact match cl width to g width  -- parser placement contraints
    // fields less than byte use byte
    if (g->width() > PHV_Container::PHV_Word::b8
            && cl->width() * 2 <= g->width()) {
        //
        return false;
    }
    // 3b.pick next cl, put in Group with available non-occupied <container, width>
    //    field f may need several containers, e.g., f:128 --> C1[32],C2,C3,C4
    //    each C single or partial field, e.g., f:24 --> C1[16], C2[8/16]
    //
    auto req_containers = cl->num_containers();  // ?!
    if (g->width() < cl->width()) {
        // scale cl width down
        // <2:_48_32>{3*32} => <2:_48_32>{5*16}
        req_containers = cl->num_containers(cl->cluster_vec(), g->width());
    }
    // TODO hanw: check and use empty containers if exist.

    // Phase 1: test if cluster can overlay to containers in the same group.
    LOG3("... try to overlay cluster ..." << cl);
    std::vector<PHV_Container*>* cc_set = new std::vector<PHV_Container*>;
    for (auto i=0, j=0; i < cl->cluster_vec().size(); i++) {
        bool field_can_overlay = false;
        // field can be larger than one container..
        const PhvInfo::Field *field = cl->cluster_vec()[i];
        auto field_width = field->phv_use_width();
        // TODO hanw: check field alignment in clusters residing in separate containers.
        //      e.g.
        //      cluster {f1, f2, f3} maybe mapped to
        //      containers | f1 ....... |
        //                 | ... f2 ... |
        //                 | f3 ....... |
        //      which could be incorrect for arithmeric operators.
        for (auto field_stride=0;
             j < req_containers && field_width > 0;
             j++, field_stride++) {
            // field uses one or more containers, tracked by field_width
            for (auto &c : g->phv_containers()) {
                if (c->o_status() != PHV_Container::Container_status::EMPTY)
                    continue;
                auto it = std::find(cc_set->begin(), cc_set->end(), c);
                if (it != cc_set->end())
                    continue;
                field_can_overlay = check_field_with_container(field, c);
                if (field_can_overlay) {
                    // found a candidate container.
                    field_width -= g->width();
                    // mark container as used for this cluster
                    cc_set->push_back(c);
                    break;
                }
            }
        }
        // if any field in the cluster fails to overlay, the cluster cannot overlay
        if (!field_can_overlay) {
            LOG3("... unable to overlay field ... "
                << field);
            return false;
        }
    }
    // Phase 2: commit cluster to containers in the group.
    LOG3("... can overlay ..." << cc_set->size() << " containers.");
    for (auto i=0, j=0; i < cl->cluster_vec().size(); i++) {
        bool field_can_overlay = false;
        const PhvInfo::Field *field = cl->cluster_vec()[i];
        auto field_width = field->phv_use_width();
        for (auto field_stride=0;
             j < req_containers && field_width > 0;
             j++, field_stride++) {
            // pop container from the front of the vector
            int taint_bits = g->width();
            if (field_width < g->width()) {
                taint_bits = field_width;
            }
            field_width -= g->width();
            auto c = cc_set->front();
            c->taint(
                0,
                taint_bits,
                field,
                0, /* range_start */
                field_stride * g->width() /* field_bit_lo */,
                true);
            cc_set->erase(cc_set->begin());
        }
    }
    // TODO gana: to check if parser constraint is met.
    return true;
}

//***********************************************************************************
// Overlay a list of clusters to a list of mau groups
//***********************************************************************************
void
Cluster_PHV_Overlay::overlay_clusters_to_groups(
    std::list<Cluster_PHV *>& clusters_to_be_assigned,
    std::list<PHV_MAU_Group *>& phv_groups_to_be_overlayed,
    const char *msg) {

    // 1. sorted clusters requirement <number, width> decreasing
    clusters_to_be_assigned.sort([](Cluster_PHV *l, Cluster_PHV *r) {
        if (l->num_containers() == r->num_containers()) {
            return l->width() > r->width();
        }
        return l->num_containers() > r->num_containers();
    });
    //
    LOG4("..........Clusters to be assigned ("
         << clusters_to_be_assigned.size()
         << ").........."
         << std::endl);
    LOG4(clusters_to_be_assigned);
    //
    // sort PHV_Groups in order 32b, 16b, 8b
    // for given width, I/E tagged MAU groups first
    //
    phv_groups_to_be_overlayed.sort([](PHV_MAU_Group *l, PHV_MAU_Group *r) {
        if (l->width() == r->width()) {
            return l->gress() == PHV_Container::Ingress_Egress::Ingress_Only
                || l->gress() == PHV_Container::Ingress_Egress::Egress_Only;
        }
        return l->width() > r->width();
    });
    //
    LOG4(".......... PHV_Groups to be filled ("
         << phv_groups_to_be_overlayed.size()
         << ").........." << std::endl);
    LOG4(phv_groups_to_be_overlayed);
    for (auto &g : phv_groups_to_be_overlayed) {
        std::list<Cluster_PHV *> clusters_remove;
        for (auto &cl : clusters_to_be_assigned) {
            auto succeed = overlay_cluster_to_group(cl, g);
            if (succeed) {
                clusters_remove.push_back(cl);
            }
        }  // for cluster
        // remove clusters already assigned
        for (auto &cl : clusters_remove) {
            clusters_to_be_assigned.remove(cl);
        }
    }  // for phv groups
    //
    phv_mau_i.status(clusters_to_be_assigned, msg);
    phv_mau_i.status(phv_groups_to_be_overlayed, msg);
}
//
//***********************************************************************************
// PHV overlay pass
//***********************************************************************************
const IR::Node *
Cluster_PHV_Overlay::apply_visitor(const IR::Node *node, const char *name) {
    LOG1("..........Cluster_PHV_Overlay::apply_visitor()..........");
    if (name) {
        LOG1(name);
    }
    // PHV overlay
    if (phv_mau_i.phv_clusters().size()) {
        std::list<PHV_MAU_Group *> phv_groups_to_be_overlayed;
        for (auto &it : phv_mau_i.phv_mau_map()) {
            for (auto &g : it.second) {
                phv_groups_to_be_overlayed.push_front(g);
            }
        }
        overlay_clusters_to_groups(
            phv_mau_i.phv_clusters(),
            phv_groups_to_be_overlayed,
            "Overlay_Clusters_MAU_Group:PHV");
    }
    // T_PHV overlay
    if (phv_mau_i.t_phv_clusters().size()) {
        ordered_set<PHV_MAU_Group *> t_phv_group_set;
        for (auto &it : phv_mau_i.t_phv_map()) {
            for (auto &it_2 : it.second) {
                for (auto &c : it_2.second) {
                    t_phv_group_set.insert(c->phv_mau_group());
                }
            }
        }
        std::list<PHV_MAU_Group *> t_phv_groups_to_be_overlayed(
            t_phv_group_set.begin(),
            t_phv_group_set.end());
        overlay_clusters_to_groups(
            phv_mau_i.t_phv_clusters(),
            t_phv_groups_to_be_overlayed,
            "Overlay_Clusters_MAU_Group:T_PHV");
    }
    return node;
}

