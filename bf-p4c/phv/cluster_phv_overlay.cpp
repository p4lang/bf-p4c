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
//     (iii) overlay does not consider empty spaces in containers
//     (iv) attempt overlay T-PHV candidates to PHV clusters
//     sort overlay_clusters, substratum_clusters <number, width> decreasing
//     search down for overlay o_cl to s_cl, if (o_cl<n,w> > s_cl<n,w>) do next o_cl
//
// (2) overlay cluster to mau group
//     (i) cluster can straddle clusters as fields straddle fields in container(s)
//         field must be overlay-able on container upto field width
//     (ii) if substratum field straddles containers, overlay field follows
//     (iii) overlay considers empty spaces in containers
//     (iv) non-singleton clusters, alignment always begins @ bit 0 of container
//     (v) singleton clusters as well as T-PHV candidates do not care about alignment
//     (vi) attempt overlay T-PHV candidates to PHV MAU
//
// first, attempt (1)
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

//
//***********************************************************************************
//
// Cluster_PHV overlay pass
// apply_visitor()
//
//***********************************************************************************
//

const IR::Node *
Cluster_PHV_Overlay::apply_visitor(const IR::Node *node, const char *name) {
    if (name) {
        LOG1(name);
    }
    if (!phv_mau_i.phv_clusters().size() && !phv_mau_i.t_phv_clusters().size()) {
        LOG3("++++++++++++++++++++Cluster_PHV_Overlay NOT NEEDED++++++++++++++++++++");
        return node;
    }
    LOG3("Begin..............................Cluster_PHV_Overlay..............................");
    LOG3("\tPHV Clusters = " << phv_mau_i.phv_clusters().size());
    LOG3("\tT_PHV Clusters = " << phv_mau_i.t_phv_clusters().size());
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
        // obtain PHV MAU groups
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
    // T_PHV overlay cl->cl substratum T_PHV clusters
    // overlay cluster to cluster, no straddling
    //
    if (phv_mau_i.t_phv_clusters().size()) {
        overlay_clusters_to_clusters(
            phv_mau_i.t_phv_clusters(),
            phv_mau_i.substratum_t_phv_clusters(),
            "Clusters_PHV_Overlay:T_PHV cl->T_PHV_cl");
    }
    // T_PHV overlay cl->cl substratum PHV clusters
    // overlay cluster to cluster, no straddling
    //
    if (phv_mau_i.t_phv_clusters().size()) {
        overlay_clusters_to_clusters(
            phv_mau_i.t_phv_clusters(),
            phv_mau_i.substratum_phv_clusters(),
            "Clusters_PHV_Overlay:T_PHV cl->PHV_cl");
    }
    // T_PHV overlay cl->Mau_g T_PHV MAUg
    // overlay cluster to MAU group, allows cluster straddling
    //
    if (phv_mau_i.t_phv_clusters().size()) {
        // obtain T_PHV groups
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
            "Cluster_PHV_Overlay:T_PHV cl->T_PHV_Mau_g");
    }
    // T_PHV overlay cl->Mau_g PHV Mau_g
    // overlay cluster to MAU group, allows cluster straddling
    //
    if (phv_mau_i.t_phv_clusters().size()) {
        // obtain PHV MAU groups
        std::list<PHV_MAU_Group *> phv_groups_to_be_overlayed;
        for (auto &it : phv_mau_i.phv_mau_map()) {
            for (auto &g : it.second) {
                phv_groups_to_be_overlayed.push_front(g);
            }
        }
        overlay_clusters_to_mau_groups(
            phv_mau_i.t_phv_clusters(),
            phv_groups_to_be_overlayed,
            "Cluster_PHV_Overlay:T_PHV cl->PHV_Mau_g");
    }
    //
    LOG3(*this);
    LOG3("\tPHV Clusters = " << phv_mau_i.phv_clusters().size());
    LOG3("\tT_PHV Clusters = " << phv_mau_i.t_phv_clusters().size());
    LOG3("End..............................Cluster_PHV_Overlay..............................");
    //
    return node;
}  // apply_visitor

//
//***********************************************************************************************
//
// (1) Overlay Clusters to Clusters
//
//***********************************************************************************************
//
//
//
//***********************************************************************************
//
// check Overlay one field to another field
//
//***********************************************************************************
//

bool
Cluster_PHV_Overlay::overlay_field_to_field(
    PhvInfo::Field *f_o,
    Cluster_PHV *cl_f_o,
    PhvInfo::Field *f_s,
    bool exceed_substratum) {
    //
    assert(f_o);
    assert(f_s);
    //
    // overlay_slice should not exceed entire substratum
    // overlay field phv_use_width qualified by slice but substratum un-qualified
    //
    if (!exceed_substratum
        && f_o->phv_use_width(cl_f_o) > f_s->phv_use_width()) {
        LOG3(".....overlay_field_to_field....."
            << "overlay field width = "
            << f_o->phv_use_width(cl_f_o)
            << ", substratum field width = "
            << f_s->phv_use_width());
        return false;
    }
    if (!phv_interference_i.mutually_exclusive(f_o, f_s)) {
        LOG3(".....overlay_field_to_field....."
            << "not mutually exclusive");
        return false;
    }
    // field overlay acceptable
    return true;
}
//
//***********************************************************************************
//
// Overlay one cluster to another cluster
//
//***********************************************************************************
//

bool
Cluster_PHV_Overlay::overlay_cluster_to_cluster(
    Cluster_PHV *cl_o,
    Cluster_PHV *cl_s) {
    //
    // honor MAU group In/Egress only constraints
    //
    if (!phv_mau_i.gress_compatibility(cl_o->gress(), cl_s->gress())) {
        //
        // gress mismatch, skip cluster
        //
        return false;
    }
    LOG3("..... attempt to overlay Cluster to Cluster ....."
        << cl_o->id() << " -> " << cl_s->id());
    // LOG3(cl_o);
    // LOG3(cl_s);
    //
    // assumption
    // cluster of fields are sorted decreasing field width
    //
    ordered_map<PhvInfo::Field *, PhvInfo::Field *> overlay_substratum_map;
    std::list<PhvInfo::Field *> substratum_fields(
        cl_s->cluster_vec().begin(),
        cl_s->cluster_vec().end());
    for (auto &f_o : cl_o->cluster_vec()) {
        PhvInfo::Field *remove_field = 0;
        for (auto &f_s : substratum_fields) {
            if (overlay_field_to_field(f_o, cl_o, f_s /* , do not exceed substratum */)) {
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
    LOG3("+++++ Overlay cl->cl Passed +++++");
    LOG3(overlay_substratum_map);
    for (auto &e : overlay_substratum_map) {
        PhvInfo::Field *f_o = e.first;
        PhvInfo::Field *f_s = e.second;
        LOG3("\t" << f_o);
        LOG3("\t==> " << f_s);
        int f_o_width = f_o->phv_use_width(cl_o);
        int f_o_bit_lo = 0;
        if (f_s->phv_containers().empty()) {
            LOG1("*****cluster_phv_overlay:sanity_FAIL*****");
            LOG1(f_s);
            LOG1(" should not be a substratum field, it has no PHV allocated ");
            continue;
        }
        for (auto &c : f_s->phv_containers()) {
            std::pair<int, int> f_s_start_bit_and_width_in_c = c->start_bit_and_width(f_s);
            int width = std::min(f_o_width, f_s_start_bit_and_width_in_c.second);
            c->single_field_overlay(
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
                  [](PhvInfo::Field *l, PhvInfo::Field *r) {
                      if (l->phv_use_width() == r->phv_use_width()) {
                          // sort by cluster id_num to prevent non-determinism
                          return l->id < r->id;
                      }
                      return l->phv_use_width() > r->phv_use_width(); });
    }
    LOG4("..........Overlay_clusters_to_clusters: Clusters to be assigned ("
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
                  [](PhvInfo::Field *l, PhvInfo::Field *r) {
                      if (l->phv_use_width() == r->phv_use_width()) {
                          // sort by cluster id_num to prevent non-determinism
                          return l->id < r->id;
                      }
                      return l->phv_use_width() > r->phv_use_width(); });
    }
    //
    LOG4("..........Overlay_clusters_to_clusters: Substratum Clusters ("
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
//***********************************************************************************************
//
// (2) Overlay Cluster to Mau Group
//
//***********************************************************************************************
//
//
bool Cluster_PHV_Overlay::overlay_field_to_container(
    Cluster_PHV *cl,
    PhvInfo::Field *field,
    PHV_Container *c,
    int run_width,
    int &start_bit) {
    //
    // can check overlay only upto width of container c
    //
    assert(cl);
    assert(field);
    assert(run_width <= c->width());
    if (field->deparsed() && run_width != c->width()) {
        return false;
    }
    //
    // overlay field can be larger than one container: straddles containers if substratum straddles
    // (ii) if substratum field straddles containers, overlay field follows
    // (iii) overlay considers empty spaces in containers
    // (v) singleton clusters as well as T-PHV candidates do not care about alignment
    //
    bool care_alignment = true;
    if (cl->cluster_vec().size() == 1
        || strstr(cl->id().c_str(), "t_phv")) {
        //
        care_alignment = false;
    }
    std::list<PHV_Container::Container_Content *> cc_list;
    c->fields_in_container(cc_list);  // sorted in bit order
    for (auto &cc : cc_list) {
        if (cc->lo() > start_bit + run_width - 1) {
            //
            // field must be overlay-able on container upto field width only
            // packing-constraints in fields must be reflected in phv_use_width()
            // ref: cluster_phv_operations.cpp PHV_Container::ceil_phv_use_width(&f)
            //
            // already matched required width
            // e.g., c<8> = ++++++11, width req <= bit 6, cc field starts at bit 6
            // field is overlaying parts of container to left of this cc field
            // if this cc is the first field then container is empty to the left
            //
            return true;
        }
        if (start_bit + run_width > c->width()) {
            //
            // current start position + required width exceeds container limit
            // e.g., c<8> = ------11, width req = 3, start at bit 6
            //
            return false;
        }
        if (!overlay_field_to_field(
                field, cl, cc->field() /* substratum */, true /* can exceed substratum */)) {
            if (care_alignment) {
                return false;
            } else {
                //
                // if substratum has packing constraints, run-width is entire container
                //
                if (cc->field()->constrained(true /* packing constraint only */)) {
                    // cannot proceed for further matches
                    return false;
                } else {
                    //
                    // block all bits to left of this substratum
                    // start_bit should be beyond this non-matching field
                    // try next subtratum which can be trailing empty part of container
                    //
                    start_bit = cc->hi() + 1;
                    continue;
                }
            }
        }
    }  // for
    if (start_bit + run_width <= c->width()) {
        return true;
    }
    return false;
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
    if (!phv_mau_i.gress_compatibility(g->gress(), cl->gress())) {
        //
        // gress mismatch, skip cluster for this MAU group
        //
        return false;
    }
    // pick next cl, put in Group with overlay-able fields
    // field f may need several containers, e.g., f:128 --> C1[32],C2,C3,C4
    // each C single or partial field, e.g., f:24 --> C1[16], C2[8/16]
    //
    // Phase 1: test if cluster can overlay to containers in the same group.
    LOG3("..... attempt to overlay Cluster to MAU group ....."
        << cl->id() << " -> "
        << "G" << g->number() << "<" << g->width() << "b>" << '.' << static_cast<char>(g->gress()));
    // LOG3(cl);
    //
    ordered_map<PhvInfo::Field *,
        std::list<std::pair<PHV_Container *, int>>> field_container_map;
    std::list<PHV_Container *> container_list(
        g->phv_containers().begin(),
        g->phv_containers().end());
    for (size_t i=0; i < cl->cluster_vec().size(); i++) {
        PhvInfo::Field *field = cl->cluster_vec()[i];
        int field_width = field->phv_use_width(cl);
        for (auto &c : container_list) {
            //
            // check field alignment in clusters residing in separate containers.
            // e.g.,
            // cluster {f1, f2, f3} maybe mapped to
            // containers | f1 ....... |
            //            | ... f2 ... |
            //            | f3 ....... |
            // which would be incorrect for arithmeric operators
            // if field can overlay all fields in container
            // then field can be placed anywhere in container, i.e., it can respect alignment
            // start @ bit 0 of container
            //
            int run_width = std::min(field_width, static_cast<int>(c->width()));
            int start_bit = 0;
            if (overlay_field_to_container(cl, field, c, run_width, start_bit)) {
                field_container_map[field].push_back(std::make_pair(c, start_bit));
                field_width -= run_width;
                if (field_width <= 0) {
                    break;
                }
                // else straddle more container(s) for same field
            }
        }  // for
        //
        // if field_width is +ve then field was not completely overlayed, e.g., needs 2c but got 1c
        // if any field in cluster fails to overlay then cluster cannot overlay
        //
        if (field_width <= 0) {
            //
            // remove container(s) from container_list
            // other members of this cluster cannot use this cluster member's container(s)
            // as each member must be in a separate container
            //
            for (auto &pair : field_container_map[field]) {
                container_list.remove(pair.first);
            }
        } else {
            // field_width not accommodated
            // LOG3("----- overlay failed [" << field_width << "b] ----- "
            //   << field->id << ":" << field->name);
            return false;
        }
    }  // for
    // Phase 2: commit cluster to containers in the group.
    LOG3("+++++ Overlay cl->maug Passed +++++");
    LOG3(field_container_map);
    //
    // go through field container map
    // assign fields to containers
    // i.e., enter additional cc for overlayed field in container
    //
    for (auto &e : field_container_map) {
        PhvInfo::Field *f = e.first;
        int field_bit_lo = f->phv_use_lo(cl);
        int field_width = f->phv_use_width(cl);
        // field straddles containers when e.second.size() > 1
        for (auto &pair : e.second) {
            PHV_Container *c = pair.first;
            int start = pair.second;
            int use_width = std::min(field_width, static_cast<int>(c->width()));
            assert(use_width > 0);
            c->single_field_overlay(
                f,
                start,
                use_width,
                field_bit_lo,
                PHV_Container::Container_Content::Cluster_Overlay);
            //
            // for all fields f_s overlapped by f in container
            // update field_overlay_map info in f_s' owner field
            //
            ordered_set<PhvInfo::Field *> f_set;
            c->fields_in_container(start, start + use_width - 1, f_set);
            for (auto &f_s : f_set) {
                f_s->field_overlay(f);
            }
            // next iteration
            field_width -= use_width;
            field_bit_lo += use_width;
        }  // for
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
    LOG4("..........Overlay_clusters_to_MAU_Groups: Clusters to be assigned ("
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
    LOG4("..........Overlay_clusters_to_MAU_Groups:  PHV_Groups to be filled ("
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
// output stream <<
//
//***********************************************************************************
//
//

std::ostream &operator<<(
    std::ostream &out,
    ordered_map<PhvInfo::Field *, PhvInfo::Field *>& overlay_substratum_map) {
    //
    out << "..... Overlay Field -> Field map ....." << std::endl;
    for (auto &e : overlay_substratum_map) {
        out << "\t"
            << e.first
            << std::endl
            << "cluster_phv_overlay cl->cl ==> "
            << e.second;
    }
    return out;
}

std::ostream &operator<<(
    std::ostream &out,
    ordered_map<PhvInfo::Field *, std::list<std::pair<PHV_Container *, int>>>&
        field_container_map) {
    //
    out << "..... Overlay Field -> Container_map ....." << std::endl;
    for (auto &e : field_container_map) {
        out << "\t"
            << e.first
            << std::endl
            << "cluster_phv_overlay cl->maug ==> ";
        if (e.second.size() == 1) {
            out << e.second.front().first;
        } else {
            out << "(";
            for (auto &pair : e.second) {
                out << pair.first << ";";
            }
            out << ")";
        }
        out << std::endl;
    }
    return out;
}

std::ostream &operator<<(std::ostream &out, Cluster_PHV_Overlay &cluster_phv_overlay) {
    out << std::endl
        << cluster_phv_overlay.phv_mau()
        << std::endl;
    return out;
}
