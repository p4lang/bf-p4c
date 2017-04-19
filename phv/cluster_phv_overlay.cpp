#include "cluster_phv_mau.h"
#include "cluster_phv_overlay.h"
#include "lib/log.h"

//
//***********************************************************************************************
//
// (1) overlay clusters to clusters
//     considers mapping cluster to cluster only
//     (i) cluster cannot straddle clusters
//     (ii) cluster straddles containers
//     sort overlay_clusters, substratum_clusters <number, width> decreasing
//     search down for overlay o_cl to s_cl, if (o_cl-><n,w> > s_cl<n,w>) do next o_cl
//
// (2) overlay cluster to mau group
//     (i) cluster can straddle clusters as fields straddle fields in container(s)
//     field must be overlay-able on entire container upto field width
//     (ii) non-singleton clusters, alignment always begins @ bit 0 of container
//     if substratum field straddles containers, overlay field follows
//
// first try (1)
// overflow clusters attempted by (2)
//
// use PHV_Interference::mutually_exclusive(field1, field2)
// to check if two fields can be overlayed to the same PHV container
// phv_interference->mutually_exclusive(f1, f2) considers ccgf fields as well as overlayed fields
//
// assuming overlayed field has packing constraints all fields in target container are checked
// for non_constrained overlay fields, this restriction can be relaxed (TODO)
//
// for overlay fields with move-based operations only,
// it suffices to only check substratum fields that span the overlay width (TODO)
// also, alignment restrictions are not needed (TODO)
//
//***********************************************************************************************
//

bool Cluster_PHV_Overlay::overlay_field_to_container(
    const PhvInfo::Field *field,
    PHV_Container *c) {
    //
    // field can be larger than one container
    // field widths larger than container,
    // considered by cluster-to-cluster overlay
    //
    if (field->phv_use_width() > c->width()) {
        return false;
    }
    for (auto *cc : Values(c->fields_in_container())) {
        if (!phv_interference_i.mutually_exclusive(field, cc->field())) {
            return false;
        }
    }
    return true;
}  // overlay_field_to_container

//
//***********************************************************************************
//
// Overlay one cluster to one MAU group
// Two phases:
// 1. check if the cluster can be overlayed to containers in the mau group.
// 2. if check succeeds, commit the cluster overlay to mau group.
//    else, nothing changes, try next mau group.
//
//***********************************************************************************
//

bool
Cluster_PHV_Overlay::overlay_cluster_to_mau_group(Cluster_PHV *cl, PHV_MAU_Group *g) {
    //
    // 3a.honor MAU group In/Egress only constraints
    //
    if (phv_mau_i.gress_in_compatibility(g->gress(), cl->gress())) {
        //
        // gress mismatch, skip cluster for this MAU group
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
    // 3b.pick next cl, put in Group with overlay-able fields
    //    field f may need several containers, e.g., f:128 --> C1[32],C2,C3,C4
    //    each C single or partial field, e.g., f:24 --> C1[16], C2[8/16]
    //
    // Phase 1: test if cluster can overlay to containers in the same group.
    LOG3("..... attempt to overlay cluster .....");
    LOG3(cl);
    ordered_map<const PhvInfo::Field *, PHV_Container *> field_container_map;
    std::list<PHV_Container *> container_list(
        g->phv_containers().begin(),
        g->phv_containers().end());
    for (size_t i=0; i < cl->cluster_vec().size(); i++) {
        const PhvInfo::Field *field = cl->cluster_vec()[i];
        for (auto &c : container_list) {
            //
            //      check field alignment in clusters residing in separate containers.
            //      e.g.,
            //      cluster {f1, f2, f3} maybe mapped to
            //      containers | f1 ....... |
            //                 | ... f2 ... |
            //                 | f3 ....... |
            //      which would be incorrect for arithmeric operators
            //      if field can overlay all fields in container
            //      then field can be placed anywhere in container
            //      i.e., it can respect alignment
            //
            if (overlay_field_to_container(field, c)) {
                field_container_map[field] = c;
                break;
            }
        }  // for
        // if any field in cluster fails to overlay
        // then cluster cannot overlay
        //
        if (field_container_map.count(field)) {
            //
            // remove container from container_list
            // other members of this cluster cannot use this container
            // as each member must be in a separate container
            //
            container_list.remove(field_container_map[field]);
        } else {
            LOG3("..... unable to overlay field ..... " << field->id << ":" << field->name);
            return false;
        }
    }  // for
    // Phase 2: commit cluster to containers in the group.
    LOG3("..... can overlay .....");
    LOG3(field_container_map);
    //
    // go through field container map
    // assign fields to containers
    // i.e., enter additional cc for overlayed field in container
    //
    for (auto &e : field_container_map) {
        PhvInfo::Field *f = const_cast<PhvInfo::Field *>(e.first);
        PHV_Container *c = const_cast<PHV_Container *>(e.second);
        int start = 0;
        int field_bit_lo = 0;
        c->single_field_overlay(
            f,
            start,
            f->phv_use_width(),
            field_bit_lo,
            PHV_Container::Container_Content::Cluster_Overlay);
        //
        // for all fields f_s overlapped by f in container
        // update field_overlay_map info in f_s' owner field
        //
        ordered_set<const PhvInfo::Field *> f_set;
        c->fields_in_container(start, start + f->phv_use_width() - 1, f_set);
        for (auto &f_s : f_set) {
            const_cast<PhvInfo::Field *>(f_s)->field_overlay(f);
        }
    }  // for
    //
    return true;
}  // overlay_cluster_to_mau_group

//
//***********************************************************************************
//
// Overlay a list of clusters to a list of mau groups
//
//***********************************************************************************
//
void
Cluster_PHV_Overlay::overlay_clusters_to_mau_groups(
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
         << msg
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
        clusters_remove.clear();
        for (auto &cl : clusters_to_be_assigned) {
            if (overlay_cluster_to_mau_group(cl, g)) {
                clusters_remove.push_back(cl);
            }
        }  // for clusters
        // remove clusters already assigned
        for (auto &cl : clusters_remove) {
            clusters_to_be_assigned.remove(cl);
        }
    }  // for phv groups
    //
    phv_mau_i.status(clusters_to_be_assigned, msg);
    phv_mau_i.status(phv_groups_to_be_overlayed, msg);
}  // overlay_clusters_to_mau_groups

//
//***********************************************************************************
//
// Overlay one cluster to another cluster
//
//***********************************************************************************
//

bool
Cluster_PHV_Overlay::overlay_field_to_field(
    const PhvInfo::Field &f_o,
    const PhvInfo::Field &f_s) {
    //
    if (f_o.phv_use_width() > f_s.phv_use_width()) {
        return false;
    }
    if (!phv_interference_i.mutually_exclusive(&f_o, &f_s)) {
        return false;
    }
    // field overlay acceptable
    return true;
}

bool
Cluster_PHV_Overlay::overlay_cluster_to_cluster(
    Cluster_PHV *cl_o,
    Cluster_PHV *cl_s) {
    //
    // honor MAU group In/Egress only constraints
    //
    if (phv_mau_i.gress_in_compatibility(cl_o->gress(), cl_s->gress())) {
        //
        // gress mismatch, skip cluster
        //
        return false;
    }
    // assumption
    // cluster of fields are sorted decreasing field width
    //
    ordered_map<const PhvInfo::Field *, const PhvInfo::Field *> overlay_substratum_map;
    std::list<const PhvInfo::Field *> substratum_fields(
        cl_s->cluster_vec().begin(),
        cl_s->cluster_vec().end());
    for (auto &f_o : cl_o->cluster_vec()) {
        const PhvInfo::Field *remove_field = 0;
        for (auto &f_s : substratum_fields) {
            if (overlay_field_to_field(*f_o, *f_s)) {
                overlay_substratum_map[f_o] = f_s;
                remove_field = f_s;
                break;
            }
        }  // for
        if (remove_field) {
            // other fields in cl_o can no longer use f_o/f_s' positions
            substratum_fields.remove(remove_field);
        }
    }  // for
    if (overlay_substratum_map.size() != cl_o->cluster_vec().size()) {
        // could not map all fields
        return false;
    }
    // overlay fields in cl_o to mapped fields in cl_s
    //
    // go through overlay_substratum map
    // assign fields to containers
    // i.e., enter additional cc for overlayed field in container
    //
    LOG3("..... cluster_phv_overlay: cl_to_cl .....");
    for (auto &e : overlay_substratum_map) {
        PhvInfo::Field *f_o = const_cast<PhvInfo::Field *>(e.first);
        PhvInfo::Field *f_s = const_cast<PhvInfo::Field *>(e.second);
        LOG3("\t" << f_o);
        LOG3("\t==> " << f_s);
        int f_o_width = f_o->phv_use_width();
        int f_o_bit_lo = 0;
        if (f_s->phv_containers_i.empty()) {
            LOG1("*****cluster_phv_overlay:sanity_FAIL*****");
            LOG1(f_s);
            LOG1(" should not be a substratum field, it has no PHV allocated ");
            continue;
        }
        for (auto &c : f_s->phv_containers_i) {
            PHV_Container *c1 = const_cast<PHV_Container *>(c);
            std::pair<int, int> f_s_start_bit_and_width_in_c = c1->start_bit_and_width(f_s);
            int width = std::min(f_o_width, f_s_start_bit_and_width_in_c.second);
            c1->single_field_overlay(
                f_o,
                f_s_start_bit_and_width_in_c.first /* start */,
                width,
                f_o_bit_lo /* field_bit_lo */,
                PHV_Container::Container_Content::Cluster_Overlay);
            // set values for next iteration
            f_o_bit_lo += width;
            f_o_width -= width;
            if (f_o_width <= 0) {
                break;
            }
        }  // for
        // update field_overlay_map info in f_s' owner field
        f_s->field_overlay(f_o);
    }  // for

    return true;
}  // overlay_cluster_to_cluster

//
//***********************************************************************************
//
// Overlay a list of clusters to a list of substratum clusters
//
//***********************************************************************************
//
void
Cluster_PHV_Overlay::overlay_clusters_to_clusters(
    std::list<Cluster_PHV *>& clusters_to_be_assigned,
    std::list<Cluster_PHV *>& substratum_clusters,
    const char *msg) {
    //
    // sorted clusters requirement <number, width> decreasing
    clusters_to_be_assigned.sort([](Cluster_PHV *l, Cluster_PHV *r) {
        if (l->num_containers() == r->num_containers()) {
            return l->width() > r->width();
        }
        return l->num_containers() > r->num_containers();
    });
    // sort fields in cluster, in preparation for cluster_to_cluster_overlay attempt
    // cluster vector = sorted decreasing field width
    //
    for (auto &cl : clusters_to_be_assigned) {
        std::sort(cl->cluster_vec().begin(),
                  cl->cluster_vec().end(),
                  [](const PhvInfo::Field *l, const PhvInfo::Field *r) {
                      if (l->phv_use_width() == r->phv_use_width()) {
                          // sort by cluster id_num to prevent non-determinism
                          return l->id < r->id;
                      }
                      return l->phv_use_width() > r->phv_use_width(); });
    }
    LOG4("..........Clusters to be assigned ("
         << clusters_to_be_assigned.size()
         << ").........."
         << msg
         << std::endl);
    LOG4(clusters_to_be_assigned);
    //
    // sorted clusters requirement <number, width> decreasing
    substratum_clusters.sort([](Cluster_PHV *l, Cluster_PHV *r) {
        if (l->num_containers() == r->num_containers()) {
            return l->width() > r->width();
        }
        return l->num_containers() > r->num_containers();
    });
    // sort fields in cluster, in preparation for cluster_to_cluster_overlay attempt
    // cluster vector = sorted decreasing field width
    //
    for (auto &cl : substratum_clusters) {
        std::sort(cl->cluster_vec().begin(),
                  cl->cluster_vec().end(),
                  [](const PhvInfo::Field *l, const PhvInfo::Field *r) {
                      if (l->phv_use_width() == r->phv_use_width()) {
                          // sort by cluster id_num to prevent non-determinism
                          return l->id < r->id;
                      }
                      return l->phv_use_width() > r->phv_use_width(); });
    }
    //
    LOG4("..........Substratum Clusters ("
         << substratum_clusters.size()
         << ").........."
         << msg
         << std::endl);
    LOG4(substratum_clusters);
    std::list<Cluster_PHV *> clusters_overlayed;
    clusters_overlayed.clear();
    for (auto &cl_o : clusters_to_be_assigned) {
        for (auto &cl_s : substratum_clusters) {
            if (cl_o->num_containers() > cl_s->num_containers()
                || cl_o->width() > cl_s->width()) {
                //
                // this cl_o, no further matches possible in sorted down cl_s
                // attempt next cl_o
                //
                break;
            }
            if (overlay_cluster_to_cluster(cl_o, cl_s)) {
                clusters_overlayed.push_back(cl_o);
                break;
            }
        }  // for clusters
    }  // for phv groups
    // remove clusters already assigned
    for (auto &cl : clusters_overlayed) {
        clusters_to_be_assigned.remove(cl);
    }
    //
    phv_mau_i.status(clusters_to_be_assigned, msg);
}  // overlay_clusters_to_clusters

//
//
//***********************************************************************************
//
// Cluster_PHV overlay pass
//
//***********************************************************************************
//
//
const IR::Node *
Cluster_PHV_Overlay::apply_visitor(const IR::Node *node, const char *name) {
    LOG1("..........Cluster_PHV_Overlay::apply_visitor()..........");
    if (name) {
        LOG1(name);
    }
    // PHV overlay cl->cl
    // overlay cluster to cluster, no straddling
    //
    if (phv_mau_i.phv_clusters().size()) {
        overlay_clusters_to_clusters(
            phv_mau_i.phv_clusters(),
            phv_mau_i.substratum_phv_clusters(),
            "Clusters_PHV_Overlay:PHV cl->cl");
    }
    // PHV overlay cl->Mau_g
    // overlay cluster to MAU group, allows cluster straddling
    //
    if (phv_mau_i.phv_clusters().size()) {
        std::list<PHV_MAU_Group *> phv_groups_to_be_overlayed;
        for (auto &it : phv_mau_i.phv_mau_map()) {
            for (auto &g : it.second) {
                phv_groups_to_be_overlayed.push_front(g);
            }
        }
        overlay_clusters_to_mau_groups(
            phv_mau_i.phv_clusters(),
            phv_groups_to_be_overlayed,
            "Clusters_PHV_Overlay:PHV cl->Mau_g");
    }
    // T_PHV overlay cl->cl
    // overlay cluster to cluster, no straddling
    //
    if (phv_mau_i.t_phv_clusters().size()) {
        overlay_clusters_to_clusters(
            phv_mau_i.t_phv_clusters(),
            phv_mau_i.substratum_t_phv_clusters(),
            "Clusters_PHV_Overlay:T_PHV cl->cl");
    }
    // PHV overlay cl->Mau_g
    // overlay cluster to MAU group, allows cluster straddling
    //
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
        overlay_clusters_to_mau_groups(
            phv_mau_i.t_phv_clusters(),
            t_phv_groups_to_be_overlayed,
            "Cluster_PHV_Overlay:T_PHV cl->Mau_g");
    }
    return node;
}  // apply_visitor

//
//***********************************************************************************
//
// output stream <<
//
//***********************************************************************************
//
//

std::ostream &operator<<(
    std::ostream &out,
    ordered_map<const PhvInfo::Field *, PHV_Container *>& field_container_map) {
    for (auto &e : field_container_map) {
        const PhvInfo::Field *f = e.first;
        const PHV_Container *c = e.second;
        out << "\t"
            << f
            << std::endl
            << "cluster_phv_overlay ==> "
            << c
            << std::endl;
    }
    return out;
}
