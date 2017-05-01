#include "cluster_phv_interference.h"
#include "lib/log.h"
#include "lib/stringref.h"

//***********************************************************************************
//
// PHV_Interference::apply_visitor()
//
// 1. ignore clusters of size 1
// 2. interference graph: if A liveness overlaps C, A cannot overlay C, edge A---C
// 3. sort fields in clusters
//    greater widths first to avoid container adjacency violations
// 4. scan cluster fields, assign chromatic number(s), >1 based on container width
//    node.chromatic number = lowest ( {cluster universe} - {neighbor numbers} )
//    if reg_map[r]  // owner field
//        cl->field_overlay_map()[owner][r]->push_back)field)
//    else
//        reg_map[r] = field
// 5. create overlay_map in cluster
// 6. recompute reduced cluster requirements <number, width>
// 7. during container placements (cluster_phv_mau.cpp)
//    traverse overlay_map to add overlay fields (ccgfs: consider members) to container
//
// e.g.,
//    A     = B<2w> op C
//    D     = C     op E
//    F<2w> = D     op A
//
//    D---A (A---E---C, A---C) C---B  F
//    8 containers reduced to {D E B F} {A B F} {C D F}  = 3 containers
//    widths, e.g., <2w>, within {} can overlap
//
//    sort to minimize container_adjacency violation: [F B A C D E]
//
//    reduced cluster = cl<8w> - {B A D E} = {F(c0,c1) C(c2)}<3w>
//
//    cluster.overlay_map:
//    F -- [0] -- B[0], A
//      -- [1] -- B[1], D, E
//    assume overlay is exact fit so F --> B otherwise don't overlay
//    F -- [0] -- B<w1>, A
//      -- [1] -- B<w2>, D, E
//
//    if F(c1,c2), C(c3), B needs adjacent containers, cannot use c0
//    B(c4,c5)
//    cl = {F C B}<5w>
//
//***********************************************************************************


const IR::Node *
PHV_Interference::apply_visitor(const IR::Node *node, const char *name) {
    //
    LOG1("..........PHV_Interference::apply_visitor()..........");
    if (name) {
        LOG1(name);
    }
    //
    interference_reduction(
        phv_requirements_i.cluster_phv_fields(),
        "phv");
    //
    // t_phv fields can benefit from mutex header fields
    //
    interference_reduction(
        phv_requirements_i.t_phv_fields(),
        "t_phv");
    //
    LOG3(*this);
    //
    return node;
}

void
PHV_Interference::aggregate_singleton_clusters(
    std::vector<Cluster_PHV *>& cluster_vec,
    std::vector<Cluster_PHV *>& c_vec,
    ordered_map<PHV_Container::Ingress_Egress,
        ordered_map<int,
            std::vector<Cluster_PHV *>>>& singletons) {
    //
    for (auto &entry : singletons) {
        for (auto &entry_2 : entry.second) {
            //
            // lone cluster with single field, cannot be reduced further
            //
            if (entry_2.second.size() > 1) {
                //
                // compose an aggregate cluster from singleton clusters
                // insert in c_vec
                //
                ordered_set<PhvInfo::Field *> *set_of_fields =
                    new ordered_set<PhvInfo::Field *>;             // new set
                for (auto &cl : entry_2.second) {
                    assert(cl->cluster_vec().size() == 1);
                    set_of_fields->insert(cl->cluster_vec().front());
                    //
                    // remove singleton cluster from cluster_vec
                    // after they are aggregated and reduced
                    // surviving fields are added back to cluster_vec as singleton clusters
                    //
                    // removing from vector
                    // move element to end of vector then erase
                    //
                    cluster_vec.erase(
                        std::remove(cluster_vec.begin(), cluster_vec.end(), cl),
                        cluster_vec.end());
                }
                Cluster_PHV *aggregate = new Cluster_PHV(
                    set_of_fields,
                    std::string(1, PHV_Container::Container_Content::Pass::Aggregate));
                c_vec.push_back(aggregate);
            }
        }
    }
}  // aggregate_singleton_clusters

void
PHV_Interference::interference_reduction_singleton_clusters(
    std::vector<Cluster_PHV *>& cluster_vec,
    ordered_map<PHV_Container::Ingress_Egress,
        ordered_map<int,
            std::vector<Cluster_PHV *>>> singletons,
    const std::string& msg) {
    //
    LOG3("..........Begin: PHV_Interference::reduction_singleton_clusters().........." << msg);
    //
    std::vector<Cluster_PHV *> c_vec;
    c_vec.clear();
    aggregate_singleton_clusters(cluster_vec, c_vec, singletons);
    //
    interference_reduction(
        c_vec,
        msg + "_" + PHV_Container::Container_Content::Pass::Aggregate);
    //
    // create singleton clusters from every field that survived reduction
    // from c_vec add it back to cluster_vec
    //
    for (auto &cl : c_vec) {
        std::sort(cl->cluster_vec().begin(), cl->cluster_vec().end(),
            [](PhvInfo::Field *l, PhvInfo::Field *r) {
                // sort by cluster id_num to prevent non-determinism
                return l->id < r->id;
            });
        for (auto &field : cl->cluster_vec()) {
            cluster_vec.push_back(
                new Cluster_PHV(
                    field,
                    PHV_Container::Container_Content::Pass::Field_Interference + cl->id()));
        }
    }
    LOG3("..........End: PHV_Interference::reduction_singleton_clusters().........." << msg);
    //
}  // interference_reduction_singleton_clusters

void
PHV_Interference::interference_reduction(
    std::vector<Cluster_PHV *>& cluster_vec,
    const std::string& msg) {
    //
    LOG3("..........Begin: PHV_Interference::interference_reduction().........." << msg);
    //
    // process each cluster, interference based reduction in needs
    //
    ordered_map<PHV_Container::Ingress_Egress,
        ordered_map<int,
            std::vector<Cluster_PHV *>>> singletons;                    // gather singleton clusters
    singletons.clear();
    for (auto &cl : cluster_vec) {
        if (!cl->cluster_vec().size()) {
            LOG1("*****cluster_phv_interference:sanity_FAIL*****"
                 " cluster with O fields!"
                 << cl);
            continue;
        }
        if (cl->cluster_vec().size() == 1) {
            //
            // cluster-requirement-reduction for singleton clusters
            // ccgfs considered as a unit so no special treatment
            // accumulate singletons into separate groups: ingress, egress
            // a separate routine aggregates these singleton fields to clusters
            // then attempt reduction on these aggregate clusters
            //
            singletons[cl->gress()][cl->max_width()].push_back(cl);
            //
            continue;
        }
        LOG3(".........." << msg << ".....attempting to reduce.....");
        LOG3(cl);
        //
        // cluster: field interference with siblings
        //
        for (auto &f : cl->cluster_vec()) {
            interference_edge_i[f] = new ordered_set<PhvInfo::Field *>;  // new set
        }
        ordered_set<PhvInfo::Field *> f_set;
        for (auto &f : cl->cluster_vec()) {
            f_set.insert(f);
        }
        for (auto &f1 : cl->cluster_vec()) {
            f_set.erase(f1);
            for (auto &f2 : f_set) {
                bool can_overlay = mutually_exclusive(f2, f1);
                if (!can_overlay) {
                    create_interference_edge(f2, f1);
                }
            }
        }
        //
        sanity_check_interference(cl, "PHV_Interference::apply_visitor()..");
        //
        // sort fields within cluster
        // highest width first
        // such fields become "owners" of containers
        // other non-interfering fields point to these owners
        // avoids container_adjacency_violation for fields exceeding container width
        // e.g., F<2c> = adjacent <c1,c2> instead of <c1,c3>
        //
        std::sort(cl->cluster_vec().begin(), cl->cluster_vec().end(),
            [](PhvInfo::Field *l, PhvInfo::Field *r) {
            if (l->phv_use_width() == r->phv_use_width()) {
                // sort by cluster id_num to prevent non-determinism
                return l->id < r->id;
            }
            //
            return l->phv_use_width() > r->phv_use_width();
        });
        //
        // for each field in cluster
        // assign ownership to containers
        // for overlaps, entry in field_overlay_map[owner][reg#]
        //
        ordered_map<int, PhvInfo::Field*> reg_map;  // register r owner field
        reg_map.clear();
        for (auto &f : cl->cluster_vec()) {
            assign_virtual_container(cl, f, reg_map);
        }
        sanity_check_overlay_maps(reg_map, cl, "PHV_Interference::apply_visitor()");
        LOG3(reg_map);
        //
        // recompute reduced cluster requirements
        //
        std::list<PhvInfo::Field *> map_remove_list;
        cl->cluster_vec().clear();                         // remove all fields in cluster
        for (auto &entry : cl->field_overlay_map()) {
            if (entry.second.empty()) {
                continue;
            } else {
                cl->cluster_vec().push_back(entry.first);  // add field to cluster
            }
            //
            // if other fields do not overlay on this field 'entry.first'
            // remove field from cl's field_overlay_map
            //
            int overlays = 0;
            for (auto &n : entry.second) {
                overlays += n.second->size();
            }
            if (!overlays) {
                map_remove_list.push_back(entry.first);    // remove from cluster's interference map
            }
        }
        for (auto &fp : map_remove_list) {
            cl->field_overlay_map().erase(fp);             // erase map key
        }
        cl->compute_requirements();                        // recompute cluster requirements
    }
    if (!singletons.empty()) {
        interference_reduction_singleton_clusters(cluster_vec, singletons, msg);
    }
    LOG3("..........End: PHV_Interference::interference_reduction().........." << msg);
}  // interference_reduction

bool
PHV_Interference::mutually_exclusive(PhvInfo::Field *f1, PhvInfo::Field *f2) {
    //
    // f1, f2 having overlay fields: field->field_overlay_map()
    //
    std::list<PhvInfo::Field *> f1_overlays;
    f1->field_overlays(f1_overlays);
    std::list<PhvInfo::Field *> f2_overlays;
    f2->field_overlays(f2_overlays);
    for (auto &f1_x : f1_overlays) {
        for (auto &f2_x : f2_overlays) {
            if (!mutex_i(f1_x->id, f2_x->id)) {
                return false;
            }
        }
    }
    //
    // check m1, m2
    if (f1->ccgf_fields.size() && f2->ccgf_fields.size()) {
        for (auto &m1 : f1->ccgf_fields) {
            for (auto &m2 : f2->ccgf_fields) {
                if (!mutex_i(m1->id, m2->id)) {
                    return false;
                }
            }
        }
        return true;
    }
    // check m1, f2
    if (f1->ccgf_fields.size()) {
        for (auto &m1 : f1->ccgf_fields) {
            if (!mutex_i(m1->id, f2->id)) {
                return false;
            }
        }
        return true;
    }
    // check m2, f1
    if (f2->ccgf_fields.size()) {
        for (auto &m2 : f2->ccgf_fields) {
            if (!mutex_i(m2->id, f1->id)) {
                return false;
            }
        }
        return true;
    }
    // check f1, f2
    return mutex_i(f1->id, f2->id);
}

void
PHV_Interference::create_interference_edge(PhvInfo::Field *f2, PhvInfo::Field *f1) {
    //
    assert(interference_edge_i[f2]);
    assert(interference_edge_i[f1]);
    interference_edge_i[f2]->insert(f1);
    interference_edge_i[f1]->insert(f2);
}

void
PHV_Interference::virtual_container_overlay(
    Cluster_PHV *cl,
    PhvInfo::Field *field,
    ordered_map<int, PhvInfo::Field*>& reg_map,
    const int r) {
    //
    if (reg_map[r]) {
        //
        // container r has owner
        // insert field in owner's list
        //
        PhvInfo::Field *owner = reg_map[r];
        cl->field_overlay_map()[owner][r]->push_back(field);
        //
        // insert field in owner field's field_overlay_map
        // modify overlayed field's cluster id so it differs w/ other overlayed fields in container
        // this is necessary to pass sanity_check_overlayed_fields() in container
        //
        owner->field_overlay_map(r, field);  // fld->field_overlay_map
        //
        // original cluster with x fields have been interference-reduced to y fields
        // trail of interference chain in field's cl_id starting with substratum/owner
        // all cluster fields depict new cluster id, i.e., chain of reduced fields
        // e.g.,
        // 37:ingress::icmp../phv_9,/ [r0] = [69;79;125;127;137;] ==> /phv_9 ~37_69_79_125_127_137,/
        // 70:ingress::tcp.../phv_10,/[r2] = [80;128;138;]        ==> /phv_10 ~70_80_128_138,/
        //
        std::string pad("");
        if (!strstr(field->cl_id().c_str(), std::to_string(owner->id).c_str())) {
            pad += std::string(" ")
                   + PHV_Container::Container_Content::Pass::Field_Interference
                   + std::to_string(owner->id);
        }
        field->cl_id(field->cl_id() + pad + "_" + std::to_string(field->id));
    } else {
        reg_map[r] = field;
        cl->field_overlay_map()[field][r] = new std::vector<PhvInfo::Field *>;
    }
}  // virtual_container_overlay

void
PHV_Interference::assign_virtual_container(
    Cluster_PHV *cl,
    PhvInfo::Field *field,
    ordered_map<int, PhvInfo::Field*>& reg_map) {
    //
    // assign color(s) to field such that they don't conflict with neighbors
    //
    int field_containers =
        field->phv_use_width() / cl->width() + (field->phv_use_width() % cl->width() ? 1 : 0);
    if (interference_edge_i[field]) {
        ordered_set<int> universe_colors;
        for (int i = 0; i < cl->num_containers(); i++) {
            universe_colors.insert(i);
        }
        ordered_set<int> neighbor_colors;
        for (auto &neighbor : *(interference_edge_i[field])) {
            for (auto &x : cl->field_overlay_map()[neighbor]) {
                neighbor_colors.insert(x.first);
            }
        }
        //
        // s_diff = universe_colors - neighbor colors
        //
        ordered_set<int> s_diff = universe_colors;
        s_diff -= neighbor_colors;
        assert(s_diff.size());
        //
        // new color(s) for field
        //
        for (int i = 0; i < field_containers; i++) {
            int r = *std::min_element(s_diff.begin(), s_diff.end());
            s_diff.erase(r);  // remove r from consideration when s_diff used in next iteration
            virtual_container_overlay(cl, field, reg_map, r);
        }
    } else {
        for (int r = 0; r < field_containers; r++) {
            virtual_container_overlay(cl, field, reg_map, r);
        }
    }
}  // assign_virtual_container


//***********************************************************************************
//
// sanity checks
//
//***********************************************************************************

void PHV_Interference::sanity_check_interference(
    Cluster_PHV *cl,
    const std::string& msg) {
    //
    const std::string msg_1 = msg+"PHV_Interference::sanity_check_clusters";
    for (auto &f1 : cl->cluster_vec()) {
        for (auto &f2 : cl->cluster_vec()) {
            if (interference_edge_i[f2]
                    && interference_edge_i[f2]->count(f2)) {
                LOG1("*****cluster_phv_interference:sanity_FAIL*****" << msg_1);
                LOG1("field --interference-- self ");
                LOG1(f2);
            }
            if (interference_edge_i[f2] && interference_edge_i[f2]->count(f1)) {
                if (mutually_exclusive(f2, f1)) {
                    LOG1("*****cluster_phv_interference:sanity_FAIL*****" << msg_1);
                    LOG1("field1 --interference-- field2 should be NOT mutex ");
                    LOG1(f2);
                    LOG1(f1);
                }
            } else {
                if (f2 != f1
                    && interference_edge_i[f2] && !interference_edge_i[f2]->count(f1)) {
                    if (!mutually_exclusive(f2, f1)) {
                        LOG1("*****cluster_phv_interference:sanity_FAIL*****" << msg_1);
                        LOG1("field1 --NO interference-- field2 should BE mutex ");
                        LOG1(f2);
                        LOG1(f1);
                    }
                }
            }
        }
    }
}

void PHV_Interference::sanity_check_overlay_maps(
    ordered_map<int, PhvInfo::Field*>& reg_map,
    Cluster_PHV *cl,
    const std::string& msg) {
    //
    const std::string msg_1 = msg+"PHV_Interference::sanity_check_overlay_maps";
    //
    // ownership in reg map agrees with cluster's field_overlay_map
    //
    for (auto &r : reg_map) {
        PhvInfo::Field *owner = reg_map[r.first];
        if (!cl->field_overlay_map()[owner].count(r.first)) {
            LOG1("*****cluster_phv_interference:sanity_FAIL*****" << msg_1);
            LOG1(owner << " .....register ownership missing..... [" << r.first << "]");
        }
    }
    //
    // ownership in field_overlay_map has unique registers
    //
    ordered_map<int, const PhvInfo::Field*> reg_owner;
    int num_overlays = 0;
    for (auto &entry : cl->field_overlay_map()) {
        for (auto &entry_2 : entry.second) {
            if (reg_owner[entry_2.first]) {
                LOG1("*****cluster_phv_interference:sanity_FAIL*****" << msg_1);
                LOG1(".....[" << entry_2.first << "]..... has multiple owners .....");
                LOG1("\t" << reg_owner[entry_2.first]);
                LOG1("\t" << entry.first);
            } else {
                reg_owner[entry_2.first] = entry.first;
            }
            if (entry_2.second) {
                num_overlays += entry_2.second->size();
            }
        }
    }
    //
    // min registers used + overlays = cl num_containers()
    //
    if (reg_map.size() + num_overlays != size_t(cl->num_containers())) {
        LOG1("*****cluster_phv_interference:sanity_FAIL*****" << msg_1);
        LOG1(" .....reconciliation issue..... min_regs = "
            << reg_map.size()
            << " num_overlays = "
            << num_overlays
            << " cl num_container requirement = "
            << cl->num_containers());
    }
}

//***********************************************************************************
//
// output stream <<
//
//***********************************************************************************
//
//

std::ostream &operator<<(std::ostream &out, ordered_map<int, PhvInfo::Field*>& reg_map) {
    for (auto &r : reg_map) {
        out << "\treg[" << r.first << "] --> "
            << r.second
            << std::endl;
    }
    return out;
}

std::ostream &operator<<(std::ostream &out,
    ordered_map<PHV_Container::Ingress_Egress,
        ordered_map<int,
            std::vector<Cluster_PHV *>>> &aggregates) {
    out << "Begin ....................Singleton cluster aggregates...................."
        << std::endl;
    for (auto &entry : aggregates) {
        out << '/' << entry.first << '/' << std::endl;
        for (auto &entry_2 : entry.second) {
            out << '\t' << '|' << entry_2.first << '|' << std::endl;
            for (auto &cl : entry_2.second) {
                out << "\t\t" << cl << std::endl;
            }
        }
    }
    out << "End ....................Singleton cluster aggregates...................."
        << std::endl;
    return out;
}

std::ostream &operator<<(std::ostream &out, PHV_Interference &phv_interference) {
    out << std::endl
        << "Begin ++++++++++++++++++++ PHV Interference ++++++++++++++++++++"
        << std::endl
        << std::endl;
    out << phv_interference.phv_requirements();
    out << std::endl
        << "End ++++++++++++++++++++ PHV Interference ++++++++++++++++++++"
        << std::endl
        << std::endl;
    return out;
}
