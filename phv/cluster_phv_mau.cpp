#include "cluster_phv_mau.h"
#include "lib/log.h"
#include "lib/stringref.h"
#include "base/logging.h"

//***********************************************************************************
//
// PHV_MAU_Group::Container_Content::Container_Content constructor
//
//***********************************************************************************

PHV_MAU_Group::Container_Content::Container_Content(int l, int w, PHV_Container *c)
    : lo_i(l), hi_i(l+w-1), container_i(c) {
    //
    BUG_CHECK(container_i,
        "*****PHV_MAU_Group::Container_Content constructor called with null container ptr*****");
    container_i->ranges()[lo_i] = hi_i;
    container_i->sanity_check_container_ranges("PHV_MAU_Group::Container_Content constructor");
}

//***********************************************************************************
//
// PHV_MAU_Group::PHV_MAU_Group
//
//***********************************************************************************

PHV_MAU_Group::PHV_MAU_Group(
    PHV_Container::PHV_Word w,
    int n,
    int& phv_number,
    std::string asm_encoded,
    PHV_Container::Ingress_Egress gress,
    const int containers_in_group)
    : width_i(w), number_i(n), gress_i(gress), empty_containers_i(containers_in_group) {
    //
    // asm register offset encoded in asm_string "T?W|H|B...")
    //
    int offset_position = asm_encoded[0] == 'T'? 2: 1;
    int asm_offset = std::stoi(asm_encoded.substr(offset_position));
    asm_encoded.erase(offset_position);
    //
    // create containers within group
    for (int i=1; i <= containers_in_group; i++) {
        std::stringstream ss;
        ss << phv_number - asm_offset;
        std::string asm_reg_string = asm_encoded + ss.str();
        //
        PHV_Container *c = new PHV_Container(this, width_i, phv_number++, asm_reg_string, gress);
        phv_containers_i.push_back(c);
    }
}  // PHV_MAU_Group


//***********************************************************************************
//
// PHV_MAU_Group::create_aligned_container_slices
//
// slice partially filled containers
// to obtain larger number of sub-containers with reduced width
//
// (a) within MAU group, aligned container slices
//     (i)  honor alignment across members of cluster
//     (ii) increase number (albeit decreased width)
//
// (b) sort aligned slices to match clusters fast with available Containers <w, n>
//     slicing algorithm
//     (i)   can produce several <container_packs> for given w
//     (ii)  a container can be member of several <container_packs>
//     (iii) guarantees that for given w, given n only one <container_pack> in G
//           as every slice reduces n by 1 from previous slicing operation
//
//     container packs sorted with increasing w, increasing n
//     map[width][number]--> <G:container_packs>
//
//***********************************************************************************


void PHV_MAU_Group::create_aligned_container_slices(std::list<PHV_Container *>& container_list) {
    //
    // larger n in <n:w> possible only when 2 or more containers
    // create aligned slices only when all container range hi's match
    // else no alignment, consider separate containers with constituent slices
    // singleton containers with available space useful for horizontal packing where possible,
    // e.g., POV bit/header_stack bit array
    //
    std::set<int> set_of_hi_s;
    set_of_hi_s.clear();
    for (auto &c : container_list) {
       set_of_hi_s.insert(c->ranges().begin()->second);
    }
    if (set_of_hi_s.size() > 1) {
        return;  // no aligned slices computed
    }
    // for each slice group, obtain max of all lows in each partial container
    //
    int lo = *(set_of_hi_s.begin()) + 1;
    for (; container_list.size() > 0; ) {
        int hi = lo - 1;
        lo = 0;
        for (auto &c : container_list) {
           lo = std::max(lo, c->ranges().begin()->first);
        }
        // for each partial container slice lo .. hi
        //
        int width = hi - lo + 1;
        std::list<PHV_Container *> c_remove;
        std::set<Container_Content *> *cc_set = new std::set<Container_Content *>;
        for (auto &c : container_list) {
            cc_set->insert(new Container_Content(lo, width, c));  // insert in cc_set
            if (c->ranges().begin()->first == lo) {
                c_remove.push_back(c);
            }
        }
        aligned_container_slices_i[width][container_list.size()].insert(*cc_set);
                                                           // insert in map[w][n]
        // remove containers completely sliced
        for (auto &c : c_remove) {
            container_list.remove(c);
        }
    }
}


void PHV_MAU_Group::create_aligned_container_slices() {
    //
    // Ingress Containers and Egress Containers cannot be shared
    // split packable containers into Ingress_Only list and Egress_Only list
    //
    aligned_container_slices_i.clear();
    //
    std::list<PHV_Container *> ingress_container_list;
    std::list<PHV_Container *> egress_container_list;
    std::list<PHV_Container *> vacant_container_list;
    //
    for (auto &c : phv_containers_i) {
        c->create_ranges();
        if (c->status() == PHV_Container::Container_status::PARTIAL) {
            if (c->gress() == PHV_Container::Ingress_Egress::Ingress_Only) {
                ingress_container_list.push_back(c);
            } else {
                if (c->gress() == PHV_Container::Ingress_Egress::Egress_Only) {
                    egress_container_list.push_back(c);
                } else {
                    LOG1(c);
                    BUG("*****PHV_MAU_Group::create_aligned_slices gress not set!*****");
                }
            }
        } else if (c->status() == PHV_Container::Container_status::EMPTY) {
            vacant_container_list.push_back(c);
        }
    }
    //
    if (ingress_container_list.size()) {
        std::map<int, std::list<PHV_Container *>> container_hi_s;
        container_hi_s.clear();
        for (auto &c : ingress_container_list) {
           container_hi_s[c->ranges().begin()->second].push_back(c);
        }
        for (auto &entry : container_hi_s) {
            create_aligned_container_slices(entry.second);
        }
    }
    if (egress_container_list.size()) {
        std::map<int, std::list<PHV_Container *>> container_hi_s;
        container_hi_s.clear();
        for (auto &c : egress_container_list) {
           container_hi_s[c->ranges().begin()->second].push_back(c);
        }
        for (auto &entry : container_hi_s) {
            create_aligned_container_slices(entry.second);
        }
    }
    if (vacant_container_list.size()) {
        create_aligned_container_slices(vacant_container_list);
    }
    //
    sanity_check_container_packs("PHV_MAU_Group::create_aligned_container_slices()..");
    //
}  // create_aligned_container_slices


//***********************************************************************************
//
// PHV_MAU_Group_Assignments::apply_visitor()
//
//***********************************************************************************


const IR::Node *
PHV_MAU_Group_Assignments::apply_visitor(const IR::Node *node, const char *name) {
    //
    LOG1("..........PHV_MAU_Group_Assignments::apply_visitor()..........");
    if (name) {
        LOG1(name);
    }
    //
    // create PHV Group Assignments from PHV Requirements
    //
    if (!phv_requirements_i.cluster_phv_map().size()) {
        LOG1("**********PHV_MAU_Group_Assignments apply_visitor w/ 0 Requirements***********");
    }
    create_MAU_groups();
    create_TPHV_collections();
    //
    cluster_PHV_placements();
    cluster_TPHV_placements();    // consider TPHVoverflow => PHV before POV placements
    cluster_POV_placements();     // POV placements after TPHVoverflow => PHV
    cluster_nibble_PHV_placements();  // nibble cluster PHV placements
    //
    container_cohabit_summary();  // summarize recommendations to TP
    //
    sanity_check_group_containers("PHV_MAU_Group_Assignments::PHV_MAU_Group_Assignments()..");
    //
    LOG3(*this);
    //
    return node;
    //
}  // PHV_MAU_Group_Assignments::apply_visitor

void
PHV_MAU_Group_Assignments::create_MAU_groups() {
    //
    // create MAU Groups
    //
    for (auto &x : num_groups_i) {
        int phv_number = phv_number_start_i[x.first];
        std::stringstream ss;
        ss << phv_number;
        std::string asm_encoded = asm_prefix_i[x.first] + ss.str();
        //
        for (int i=1; i <= x.second; i++) {
            // does this group phv containers fall in ingress_only or egress_only category
            //
            PHV_Container::Ingress_Egress gress = PHV_Container::Ingress_Egress::Ingress_Or_Egress;
            for (auto ie : ingress_egress_i) {
                std::pair<int, int> limits = ie.first;
                if (phv_number < limits.first) {
                    break;
                }
                if (phv_number >= limits.first && phv_number <= limits.second) {
                    gress = ie.second;
                    break;
                }
            }
            //
            PHV_MAU_Group *g = new PHV_MAU_Group(x.first, i, phv_number, asm_encoded, gress);
            PHV_MAU_i[g->width()].push_back(g);
            //
            // fill PHV_groups_i list of MAU containers
            //
            PHV_groups_i.push_front(g);
        }
    }
}  // PHV_MAU_Group_Assignments::create_MAU_groups

void
PHV_MAU_Group_Assignments::create_TPHV_collections() {
    //
    // create TPHV collections
    //
    for (auto &x : num_groups_i) {
        int phv_number = t_phv_number_start_i[x.first];
        std::stringstream ss;
        ss << phv_number;
        std::string asm_encoded = "T" + asm_prefix_i[x.first] + ss.str();
        std::list<PHV_MAU_Group *> t_phv_groups;
        //
        // place 4(32b,8b), 6(16b) containers per "tphv group" corresponding to T_PHV Collections
        // any TPHV collection can be Ingress, Egress but not both
        // initialize 1/2 to Ingress, the other 1/2 to Egress
        // fill T_PHV_groups_i list of T_PHV containers in order 32b, 16b, 8b
        //
        PHV_Container::Ingress_Egress gress = PHV_Container::Ingress_Egress::Ingress_Only;
        for (int i=1; i <= x.second*2; i++) {
            if (i > x.second) {
                gress = PHV_Container::Ingress_Egress::Egress_Only;
            }
            PHV_MAU_Group *g = new PHV_MAU_Group(
                                            x.first,
                                            i,
                                            phv_number,
                                            asm_encoded,
                                            gress,
                                            static_cast<int>(PHV_Container::Containers::MAX)/4);
            t_phv_groups.push_back(g);
            T_PHV_groups_i.push_front(g);
        }
        // collections T_PHV_i
        int collection = 0;
        int i = 0;
        for (auto &g : t_phv_groups) {
            for (auto &c : g->phv_containers()) {
                if (i++ % x.second == 0) {
                    collection++;
                }
                T_PHV_i[collection][g->width()].push_back(c);
            }
        }
    }
    sanity_check_T_PHV_collections("PHV_MAU_Group_Assignments::PHV_MAU_Group_Assignments()..");
    //
}  // PHV_MAU_Group_Assignments::create_TPHV_collections

void
PHV_MAU_Group_Assignments::cluster_PHV_placements() {
    //
    // cluster placement in containers conforming to MAU group constraints
    //
    for (auto &it : phv_requirements_i.cluster_phv_map()) {
        //
        // 1-bit clusters separated from others
        // placement for 1-bit cls after TPHVoverflow, POV
        //
        for (auto &it_2 : it.second) {
            for (auto &cl : it_2.second) {
                if (cl->max_width() <= Nibble::nibble) {
                    clusters_to_be_assigned_nibble_i.push_front(cl);
                } else {
                    clusters_to_be_assigned_i.push_front(cl);
                }
            }
        }
    }
    //
    container_no_pack(clusters_to_be_assigned_i, PHV_groups_i, "PHV_smallest_container_width");
    if (clusters_to_be_assigned_i.size()) {
        //
        // attempt placement without smallest_container_width
        // e.g., empty 32b, 16b containers for 8b clusters
        //
        container_no_pack(
            clusters_to_be_assigned_i,
            PHV_groups_i,
            "PHV_any_container_width",
            false/*smallest_container_width*/);
        if (clusters_to_be_assigned_i.size()) {
            //
            // pack remaining clusters to partially filled containers
            //
            container_pack_cohabit(clusters_to_be_assigned_i, aligned_container_slices_i, "PHV");
        }
    }
}  // PHV_MAU_Group_Assignments::cluster_PHV_placements

void
PHV_MAU_Group_Assignments::cluster_POV_placements() {
    //
    // POV fields in PHV containers
    //
    pov_fields_i.assign(
        phv_requirements_i.pov_fields().begin(),
        phv_requirements_i.pov_fields().end());
    //
    // place POVs: bit occupies whole container => reduces opportunities for TPHV overflow into PHV
    // pack POVs horizontally
    // avoid initial placement
    // initial placement with POV_any_container_width gobbles large containers
    // initial placement with POV_smallest_container_width gobbles byte sized containers
    //
    // container_no_pack(
    //   pov_fields_i,
    //   PHV_groups_i,
    //   "POV_any_container_width",
    //   false/*smallest_container_width*/);
    //
    // container_no_pack(pov_fields_i, PHV_groups_i, "POV_smallest_container_width");
    //
    if (pov_fields_i.size()) {
        //
        // pack remaining clusters to partially filled containers
        //
        container_pack_cohabit(pov_fields_i, aligned_container_slices_i, "POV");
    }
}  // PHV_MAU_Group_Assignments::cluster_POV_placements

void
PHV_MAU_Group_Assignments::cluster_TPHV_placements() {
    //
    // T_PHV fields allocation
    // initial placement as in Clusters & PHV placement constraints
    // later pack in containers conforming to T_PHV Collection constraints
    // T_PHV_container_slices populated before container_pack_cohabit()
    //
    t_phv_fields_i.assign(
        phv_requirements_i.t_phv_fields().begin(),
        phv_requirements_i.t_phv_fields().end());
    container_no_pack(t_phv_fields_i, T_PHV_groups_i, "T_PHV_smallest_container_width");
    //
    if (t_phv_fields_i.size()) {
        //
        // attempt placement without smallest_container_width
        // e.g., empty 32b, 16b containers for 8b clusters
        //
        container_no_pack(
            t_phv_fields_i,
            T_PHV_groups_i,
            "T_PHV_any_container_width",
            false/*smallest_container_width*/);
        if (t_phv_fields_i.size()) {
            //
            // pack remaining clusters to partially filled containers
            //
            container_pack_cohabit(t_phv_fields_i, T_PHV_container_slices_i, "T_PHV");
            //
            // try overflow T_PHVs in PHV remaining spaces
            //
            if (t_phv_fields_i.size()) {
                //
                LOG3("..........T_PHV Overflow ==> PHV ..........");
                //
                container_pack_cohabit(
                    t_phv_fields_i,
                    aligned_container_slices_i,
                    "PHV <== TPHV_Overflow");
            }
        }
    }
}  // PHV_MAU_Group_Assignments::cluster_TPHV_placements

void
PHV_MAU_Group_Assignments::cluster_nibble_PHV_placements() {
    if (clusters_to_be_assigned_nibble_i.size()) {
        //
        // pack remaining clusters to partially filled containers
        //
        container_pack_cohabit(
            clusters_to_be_assigned_nibble_i,
            aligned_container_slices_i,
            "PHV_Nibble");
    }
}  // PHV_MAU_Group_Assignments::cluster_nibble_PHV_placements

//***********************************************************************************
//
// PHV_MAU_Group_Assignments::container_no_pack
//
// 1. sorted clusters requirement decreasing, sorted mau groups width decreasing
//
// 2. each CLUSTER FIELD in SEPARATE containers
//    addresses
//        surround effects within container,
//        alignment issues (start @ 0)
//        single-write constraint,
//
// 3a.honor MAU group In/Egress only constraints
// 3b.pick next cl, put in Group with available non-occupied <container, width>
//    s.t., after assignment, G.remaining_containers != 1 as forall cl, |cl| >= 2
//    field f may need several containers, e.g., f:128 --> C1<32>,C2,C3,C4
//    but each C single or partial field only => C does not contain 2 fields
//
// 4. when all G exhausted
//    clusters_to_be_assigned contains clusters not assigned
//
//***********************************************************************************

void
PHV_MAU_Group_Assignments::container_no_pack(
    std::list<Cluster_PHV *>& clusters_to_be_assigned,
    std::list<PHV_MAU_Group *>& phv_groups_to_be_filled,
    const char *msg,
    bool smallest_container_width)  {
    //
    // 1. sorted clusters requirement <number, width> decreasing
    //
    // 2. assign clusters_to_be_assigned to phv_groups_to_be_filled
    //    each cluster field in separate containers
    //    addresses
    //        single-write constraint,
    //        surround effects within container,
    //        alignment issues (start @ 0)
    //
    // sort clusters number decreasing, width decreasing
    //
    clusters_to_be_assigned.sort([](Cluster_PHV *l, Cluster_PHV *r) {
        if (l->num_containers() == r->num_containers()) {
            //
            // when placement, no pack, consider container_width, not field width (max_width())
            //
            return l->width() > r->width();
        }
        return l->num_containers() > r->num_containers();
    });
    //
    LOG3("..........Begin PHV Container NO PACK ("
         << clusters_to_be_assigned.size()
         << ").........."
         << msg
         << std::endl);
    LOG3(clusters_to_be_assigned);
    //
    // sort PHV_Groups in order 32b, 16b, 8b
    // for given width, I/E tagged MAU groups first
    //
    phv_groups_to_be_filled.sort([](PHV_MAU_Group *l, PHV_MAU_Group *r) {
        if (static_cast<int>(l->width()) == static_cast<int>(r->width())) {
            return l->gress() == PHV_Container::Ingress_Egress::Ingress_Only
                || l->gress() == PHV_Container::Ingress_Egress::Egress_Only;
        }
        return static_cast<int>(l->width()) > static_cast<int>(r->width());
    });
    //
    LOG3(".......... PHV_Groups to be filled ("
         << phv_groups_to_be_filled.size()
         << ").........." << std::endl);
    LOG3(phv_groups_to_be_filled);
    //
    LOG3(".......... No Pack Placements .........." << std::endl);
    std::set<PHV_Container *> fix_parser_containers;  // partial containers with parser fields
    for (auto &g : phv_groups_to_be_filled) {
        std::list<Cluster_PHV *> clusters_remove;
        for (auto &cl : clusters_to_be_assigned) {
            //
            // 3a.honor MAU group In/Egress only constraints
            //
            if (gress_in_compatibility(g->gress(), cl->gress())) {
                // gress mismatch
                // skip cluster for this MAU group
                //
                continue;
            }
            if (smallest_container_width) {
                //
                // try to exact match cl width to g width  -- parser placement contraints
                // fields less than byte use byte
                //
                if (static_cast<int>(g->width()) > static_cast<int>(PHV_Container::PHV_Word::b8)
                 && static_cast<int>(cl->width()) * 2 <= static_cast<int>(g->width())) {
                    //
                    continue;
                }
            }
            //
            // 3b.pick next cl, put in Group with available non-occupied <container, width>
            //    field f may need several containers, e.g., f:128 --> C1[32],C2,C3,C4
            //    each C single or partial field, e.g., f:24 --> C1[16], C2[8/16]
            //
            auto req_containers = cl->num_containers();
            if (g->width() < cl->width()) {
                // scale cl width down
                // <2:_48_32>{3*32} => <2:_48_32>{5*16}
                req_containers = cl->num_containers(cl->cluster_vec(), g->width());
            }
            if (req_containers <= g->empty_containers()) {
                // assign cl to g
                //
                // if scaled width, update num_containers
                cl->num_containers(req_containers);
                cl->width(g->width());
                //
                LOG3("....." << *g << " <-- " << *cl);
                g->clusters().push_back(cl);
                clusters_remove.push_back(cl);
                //
                // fix MAU group's gress Ingress Or Egress
                //
                if (g->gress() == PHV_Container::Ingress_Egress::Ingress_Or_Egress) {
                    g->gress(cl->gress());
                    for (auto &c : g->phv_containers()) {
                        c->gress(cl->gress());
                    }
                }
                //
                // pick next Empty container in MAU group g
                // for each container assigned to cluster, taint bits that are filled
                //
                for (auto i=0, j=0; i < static_cast<int>(cl->cluster_vec().size()); i++) {
                    auto field_width = cl->cluster_vec()[i]->phv_use_width();
                    for (auto field_stride=0;
                         j < req_containers && field_width > 0;
                         j++, field_stride++) {
                        //
                        int taint_bits = static_cast<int>(g->width());
                        if (field_width < static_cast<int>(g->width())) {
                            taint_bits = field_width;
                        }
                        field_width -= static_cast<int>(g->width());
                        //
                        PHV_Container *container = g->empty_container();
                        const PhvInfo::Field *field = cl->cluster_vec()[i];
                        container->taint(
                            0,
                            taint_bits,
                            field,
                            0 /* range_start */,
                            field_stride * static_cast<int>(g->width()) /* field_bit_lo */);
                        LOG3("\t\t" << container);
                        //
                        // check if this container is partially filled with parser field
                        //
                        if (!field->metadata && !field->pov
                            && container->status() == PHV_Container::Container_status::PARTIAL) {
                            fix_parser_containers.insert(container);
                        }
                    }
                }
                if (g->empty_containers() == 0) {
                    break;
                }
            }
        }  // for clusters
        // remove clusters already assigned
        for (auto &cl : clusters_remove) {
            clusters_to_be_assigned.remove(cl);
        }
    }  // for phv groups
    //
    // all mau groups searched
    //
    // fix parser constraints
    // parser / deparser require fully packed containers
    // ensure parser field parts are in full containers
    // e.g.,
    // field 48b -> 32b+16b and not 32b+32b half-filled
    // header field:
    // <data.x1.32-47: W1(0..15), data.x1.0-31: W0>
    // should be
    // <data.x1.16-47: W1, data.x1.0-15: H1>
    // or
    // <data.x1.0-31: W0, data.x1.32-47: H2>
    //
    for (auto &c : fix_parser_containers) {
        PHV_Container::Container_Content *cc = c->fields_in_container()[0];
        PHV_Container::Container_Content *cc_1 = 0;
        if (cc->width() > static_cast<int>(PHV_Container::PHV_Word::b32)) {
            WARNING("parser_container width > PHV_Word::b32 " << cc);
            BUG_CHECK(0, "*****PHV_MAU_Group_Assignments::container_no_pack *****");
        } else {
            if (cc->width() > static_cast<int>(PHV_Container::PHV_Word::b16)) {
                int width_diff = cc->width() - static_cast<int>(PHV_Container::PHV_Word::b16);
                cc_1 = new PHV_Container::Container_Content(
                    c,
                    0,
                    static_cast<int>(PHV_Container::PHV_Word::b16),
                    cc->field(),
                    width_diff);
                cc = new PHV_Container::Container_Content(
                    c,
                    0,
                    width_diff,
                    cc->field(),
                    cc->field_bit_lo());
            } else {
                // width < 16, <=> 8
                if (cc->width() % static_cast<int>(PHV_Container::PHV_Word::b8)) {
                    WARNING("parser_container width<PHV_Word::b8..pack@header analysis? "
                        << cc->width()
                        << cc
                        << c);
                }
            }
        }
        PHV_Container *c_transfer =
            parser_container_no_holes(c->gress(), cc, phv_groups_to_be_filled);
        if (c_transfer) {
            LOG3("----->Transfer parser container----->" << c << "--to-->" << c_transfer);
            if (cc_1) {
                PHV_Container *c_transfer_1 =
                    parser_container_no_holes(c->gress(), cc_1, phv_groups_to_be_filled);
                if (c_transfer_1) {
                    LOG3("----->Transfer parser container----->" << c << "--to-->" << c_transfer_1);
                }
            }
            c->clear();
        }
    }
    //
    std::list<PHV_MAU_Group *> phv_groups_remove;
    for (auto &g : phv_groups_to_be_filled) {
        if (g->empty_containers() == 0) {
            phv_groups_remove.push_back(g);
        }
    }
    // remove groups that are full
    for (auto &g : phv_groups_remove) {
        phv_groups_to_be_filled.remove(g);
    }
    //
    LOG3("..........End PHV Container NO PACK ("
         << clusters_to_be_assigned.size()
         << ").........."
         << msg
         << std::endl);
    if (strstr(msg, "T_PHV")) {
        LOG3(T_PHV_i);
    } else {
        LOG3(PHV_MAU_i);
    }
    //
    status(clusters_to_be_assigned, msg);
    status(phv_groups_to_be_filled, msg);
    //
}  // container_no_pack

PHV_Container *
PHV_MAU_Group_Assignments::parser_container_no_holes(
    PHV_Container::Ingress_Egress gress,
    PHV_Container::Container_Content *cc,
    std::list<PHV_MAU_Group *>& phv_groups_to_be_filled) {
    //
    // find empty container with exact width
    //
    for (auto &g : phv_groups_to_be_filled) {
        if (g->empty_containers() == 0
         || static_cast<int>(g->width()) != cc->width()
         || gress_in_compatibility(g->gress(), gress)) {
            //
            // width or gress mismatch
            // skip cluster field for this MAU group
            //
            continue;
        }
        for (auto &c_transfer : g->phv_containers()) {
            if (c_transfer->status() == PHV_Container::Container_status::EMPTY) {
                //
                c_transfer->taint(
                    0,
                    static_cast<int>(g->width()),
                    cc->field(),
                    0 /* range_start */,
                    cc->field_bit_lo() /* field_bit_lo */);
                //
                return c_transfer;
            }
        }  // for
    }  // for
    WARNING("parser_container_no_holes() transfer unsuccessful check width: " << cc);
    return 0;
}  // parser_container_no_holes


//***********************************************************************************
//
// PHV_MAU_Group_Assignments::create_aligned_container_slices
//
// for all MAU groups with partially filled containers
// slice to obtain larger number of sub-containers with reduced width
//
// input:
//      all mau groups
// output:
//      in each PHV_MAU_Group, map[width][number] of aligned_container_slices
//      consider all PHV_MAU_Groups,
//      create composite map[width][number] --> <set of <set of container_packs>>
//      map has sorted order width increasing, number increasing
//
//***********************************************************************************

void PHV_MAU_Group_Assignments::create_aligned_container_slices() {
    //
    // create composite map[width][number] --> <set of <set of container_packs>>
    // from all mau groups aligned_container_slices
    // map automatically has sorted order width increasing, number increasing
    //
    aligned_container_slices_i.clear();
    for (auto rit = PHV_MAU_i.rbegin(); rit != PHV_MAU_i.rend(); ++rit) {
        // groups within this word size
        for (auto g : rit->second) {
            g->create_aligned_container_slices();
            //
            for (auto w : g->aligned_container_slices()) {
                for (auto n : w.second) {
                    for (auto cc_set : n.second) {
                        aligned_container_slices_i[w.first][n.first].insert(cc_set);
                           // insert in composite  map[w][n]
                    }
                }
            }
        }
    }
    LOG3("..........PHV Container Packs Avail ..........");
    LOG3(aligned_container_slices_i);
    //
    // pack remaining fields to partially filled containers
    // conforming to T_PHV Collection constraints
    // T_PHV_container_slices determined before container_pack_cohabit()
    //
    T_PHV_container_slices_i.clear();
    for (auto &coll : T_PHV_i) {
        for (auto &m : coll.second) {
            std::set<PHV_MAU_Group::Container_Content *> *set_cc
                = new std::set<PHV_MAU_Group::Container_Content *>;
            for (auto &c : m.second) {
                if (c->status() == PHV_Container::Container_status::EMPTY) {
                    set_cc->insert(
                        new PHV_MAU_Group::Container_Content(
                            0,
                            static_cast<int>(c->width()),
                            c));
                } else if (c->status() == PHV_Container::Container_status::PARTIAL) {
                    int start = c->ranges().begin()->first;
                    int partial_width = c->avail_bits();
                    std::set<PHV_MAU_Group::Container_Content *> *set_cc_partial
                        = new std::set<PHV_MAU_Group::Container_Content *>;
                    set_cc_partial->insert(
                        new PHV_MAU_Group::Container_Content(start, partial_width, c));
                    T_PHV_container_slices_i[partial_width][1].insert(*set_cc_partial);
                }
            }
            if (set_cc->size()) {
                T_PHV_container_slices_i
                   [static_cast<int>(m.first)][set_cc->size()].insert(*set_cc);
            }
        }
    }
    LOG3("..........T_PHV Container Packs avail ..........");
    LOG3(T_PHV_container_slices_i);
}  // PHV_MAU_Group_Assignments::create_aligned_container_slices()

//***********************************************************************************
//
// PHV_MAU_Group_Assignments::container_pack_cohabit
//
// 4. when all G exhausted, attempt to pack C with available widths
//    (i)  co-habit         (need Table "single-write", surround side-effects (move-based ops))
//    (ii) no overlay       (need liveness, ifce graph)
//    e.g.,
//    clusters remain              G.avail
//    --------------               -------
//        <num, width>             <num containers, bit width>
//         7 1                     G1: 1:3
//         6 8                     G2: 1:7
//         5 8                     G3: 1:1, 1:1
//         5 4                     G4: 1:1, 1:7
//         5 1                     G5: 1:8, 1:13
//         4 3                     G6: 1:3, 1:6, 1:7
//         4 1                     G7: 4:8
//         3 8                     G8: 4:12
//         3 8                     G9: 5:8, 5:16
//         3 8 8 5                 G10: 1:1, 10:16
//         3 5
//         3 5
//         3 2
//         3 1
//         3 1
//         3 1
//         2 9
//         2 8
//         2 1
//
//   (i) Pack co-habit
//       remaining clusters sorted with decreasing n, decreasing w
//       sort avail G:<n,w>, G:n increasing, and within G, w increasing
//       already available as map[w][n]--> <G:container_pack>
//       create composite map[w][n]--> <set of <container_pack>>
//           as several G's can produce map[w][n]--> <G:container_pack>
//       fill container packs, automatically aligment honored
//
//       for members in cluster
//           pick top member<cn, cw> from sorted list
//           search map[cw] upto end of map
//               if map[mw][mn] accommodates member<cn, cw>
//                   if mw > cw, mn > cn
//                       split container_pack <mw, mn>
//                           --> <mw, mn-cn>, (<mw, cn> --> <mw-cw, cn>, <cw, cn>)
//                       map.insert new container_packs
//                   allocate member<cn, cw> to container_pack<cw, cn>
//                       C.update_record member<cn, cw>
//                       for each cohabit field, taint bits packing from righmost slice
//                       -- honors alignment among cluster members
//                       -- ref: PHV_MAU_Group::create_aligned_container_slices()
//                       map.remove container_pack<mw, mn>
//           if member not allocated then "cannot pack member"
//
//       G.singleton C use later if necessary for
//       (i) horizontal pack
//       (ii) status bits e.g., POVs for headers that honor single-write constraint
//
// 5. vertical distribution => no horizontal distribution
//        x.y => sigma Ca.y where x = number of containers = sigma Ca
//        addresses
//        (i)   sibling operands cannot reside in same container
//        (ii)  single-write constraint for cluster members
//        (iii) single-write constraint across clusters cohabiting container may exist
//              these fields are output as a recommedation to Table-Placement
//        within new cl selected for co-habit, packing should ensure no G.rem = 1.X
//        as no future cl can use this remnant unless horizontal packing enabled
//
// input:
//        (i)  clusters_to_be_assigned
//        (ii) all PHV_MAU_Groups w/ map<int, map<int, std::set<Container_Content *>>>
//                 aligned_container_slices_i
//             forall G,C sorted aligned_slices
//             --------------------------------
//             map[width][number]
//             [1][1]
//             [1][2]*2
//             [1][11]
//             [3][1]
//             [3][2]
//             [3][3]
//             [5][1]
//             [6][1]
//             [7][1]
//             [8][2]
//             [8][4]
//             [8][5]
//             [8][10]
//             [12][4]
//             [15][10]
// output:
//      clusters (cohabit) packed into available containers
//
//***********************************************************************************

void PHV_MAU_Group_Assignments::container_pack_cohabit(
    std::list<Cluster_PHV *>& clusters_to_be_assigned,
    ordered_map<int, ordered_map<int, std::set<std::set<PHV_MAU_Group::Container_Content *>>>>&
        aligned_slices,
    const char *msg) {
    //
    // slice containers to form groups that can accommodate larger number for given width in <n:w>
    //
    create_aligned_container_slices();
    //
    // sort clusters number decreasing, width decreasing
    //
    clusters_to_be_assigned.sort([](Cluster_PHV *l, Cluster_PHV *r) {
        if (l->num_containers() == r->num_containers()) {
            //
            // width() = width of container
            // max_width() = max width of field in cluster
            // max_width() <= width()
            // when packing consider field width
            //
            // return l->width() > r->width();
            return l->max_width() > r->max_width();
        }
        return l->num_containers() > r->num_containers();
    });
    LOG3("..........Begin Pack Cohabit ("
         << clusters_to_be_assigned.size()
         << ").....Sorted Clusters to be packed....."
         << msg
         << std::endl);
    LOG3(clusters_to_be_assigned);
    //
    // pack sorted clusters<n,w> to containers[w][n]
    //
    LOG3("..........Packing.........." << std::endl);
    //
    std::list<Cluster_PHV *> clusters_remove;
    for (auto &cl : clusters_to_be_assigned) {
        int cl_w = cl->max_width();
                            // ?? assert width < container_width,
                            // also consider non uniform widths of fields
        int cl_n = cl->num_containers();
        //
        bool found_match = false;
        for (auto &i : aligned_slices) {
            int m_w = i.first;
            if (m_w >= cl_w) {
                for (auto &j : i.second) {
                    //
                    // split container_pack <mw, mn>
                    // --> <mw, mn-cn>, (<mw, cn> --> <mw-cw, cn>, <cw, cn>)
                    //
                    int m_n = j.first;
                    if (m_n >= cl_n) {
                        // honor gress compatible match
                        //
                        std::set<PHV_MAU_Group::Container_Content *> cc_set;
                        PHV_Container::Ingress_Egress c_gress
                            = PHV_Container::Ingress_Egress::Ingress_Or_Egress;
                        cc_set.clear();
                        for (auto &cc_set_x : j.second) {
                            c_gress = (*(cc_set_x.begin()))->container()->gress();
                            if (!gress_in_compatibility(c_gress, cl->gress())) {
                                cc_set = cc_set_x;
                                //
                                // remove matching PHV_MAU_Group Container Content from set_of_sets
                                // if set_of_sets empty then remove map[m_w] entry
                                //
                                j.second.erase(cc_set_x);
                                if (j.second.empty()) {
                                    i.second.erase(j.first);
                                }
                                //
                                break;
                            }
                        }
                        if (cc_set.empty()) {
                            //
                            // not gress compatible
                            //
                            LOG3("-----<"
                                << cl_n
                                << ','
                                << cl_w
                                << '>'
                                << static_cast<char>(cl->gress())
                                << "-----["
                                << m_w
                                << "]("
                                << m_n
                                << ')'
                                << static_cast<char>(c_gress) /*<< j.second*/);
                            //
                            continue;
                        }
                        //
                        LOG3(".....<"
                             << cl_n
                             << ','
                             << cl_w
                             << '>'
                             << static_cast<char>(cl->gress())
                             <<  "-->["
                             << m_w
                             << "]("
                             << m_n
                             << ')'
                             << static_cast<char>(c_gress)
                             << cc_set);
                        //
                        // mau availability number > cluster requirement number
                        //
                        if (m_n > cl_n) {
                            //
                            // create new container pack <mw, mn-cn>
                            // n = m_n - cl_n containers
                            // insert in map[n]
                            //
                            std::set<PHV_MAU_Group::Container_Content *>* cc_n
                                = new std::set<PHV_MAU_Group::Container_Content *>;
                            auto n = m_n - cl_n;
                            for (auto i = 0; i < n; i++) {
                                cc_n->insert(*(cc_set.begin()));
                                cc_set.erase(cc_set.begin());
                            }
                            i.second[n].insert(*cc_n);
                            LOG3("\t==>["
                                 << m_w
                                 << "]-->["
                                 << m_w
                                 << "]("
                                 << n
                                 << ')'
                                 << std::endl
                                 << '\t'
                                 << *cc_n);
                        }
                        //
                        // container tracking based on cc_set ... <cl_n, cl_w>;
                        //
                        auto field = 0;
                        for (auto &cc : cc_set) {
                            // to honor alignment of fields in clusters
                            // start with rightmost vertical slice that accommodates this width
                            //
                            int start = cc->hi() + 1 - cl_w;
                            cc->container()->taint(start,
                                                   cl_w,
                                                   cl->cluster_vec()[field++],
                                                   cc->lo() /* range_start */);
                            cc->container()->sanity_check_container_ranges(
                                "PHV_MAU_Group_Assignments::container_pack_cohabit..");
                            LOG3("\t\t" << *(cc->container()));
                        }
                        //
                        // mau availabilty width > cluster requirement width
                        //
                        if (m_w > cl_w) {
                            //
                            // create new container pack <mw-cw, cn>
                            // new width w = m_w - cl_w;
                            // insert in map[m_w-cl_w][cl_n]
                            //
                            std::set<PHV_MAU_Group::Container_Content *>* cc_w
                                = new std::set<PHV_MAU_Group::Container_Content *>;
                            *cc_w = cc_set;
                            for (auto &cc : *cc_w) {
                                cc->hi(cc->hi() - cl_w);
                            }
                            auto w = m_w - cl_w;
                            aligned_slices[w][cl_n].insert(*cc_w);
                            LOG3("\t==>("
                                << cl_n
                                << ")-->["
                                << w
                                << "]("
                                << cl_n
                                << ')'
                                << std::endl
                                << '\t'
                                << *cc_w);
                        }
                        // remove cl
                        //
                        clusters_remove.push_back(cl);
                        //
                        found_match = true;  // next cluster cl
                        break;
                    }
                }
            }
            if (found_match) {
                break;
            }
        }
    }
    //
    sanity_check_container_fields_gress("PHV_MAU_Group_Assignments::container_pack_cohabit()..");
    //
    // remove clusters already assigned
    //
    for (auto &cl : clusters_remove) {
        clusters_to_be_assigned.remove(cl);
    }
    //
    // clean up aligned_slices
    //
    for (auto &i : aligned_slices) {
        bool clear_i = true;
        for (auto &x : i.second) {
            if (!x.second.empty()) {
                clear_i = false;
                break;
            }
        }
        if (clear_i == true) {
            aligned_slices[i.first].clear();
        }
    }
    bool clear_i = true;
    for (auto &i : aligned_slices) {
        if (!i.second.empty()) {
            clear_i = false;
            break;
        }
    }
    if (clear_i == true) {
        aligned_slices.clear();
    }
    //
    // update groups with Empty containers
    //
    std::list<PHV_MAU_Group *>& phv_groups = PHV_groups_i;
    if (&aligned_slices != &aligned_container_slices_i) {
        phv_groups = T_PHV_groups_i;
    }
    std::set<PHV_MAU_Group *> phv_groups_remove;
    for (auto &g : phv_groups) {
        g->empty_containers() = 0;
        for (auto &c : g->phv_containers()) {
            if (c->status() == PHV_Container::Container_status::EMPTY) {
                g->empty_containers()++;
            }
        }
        if (g->empty_containers() == 0) {
            phv_groups_remove.insert(g);
        }
    }
    for (auto &g : phv_groups_remove) {
        phv_groups.remove(g);
    }
    //
    sanity_check_container_avail("container_pack_cohabit ()..");
    //
    // update correct state for aligned slices in all groups
    //
    create_aligned_container_slices();
    //
    LOG3("..........End Pack Cohabit ("
         << clusters_to_be_assigned.size()
         << ").........."
         << msg
         << std::endl);
    if (strstr(msg, "T_PHV")) {
        LOG3(T_PHV_i);
    } else {
        LOG3(PHV_MAU_i);
    }
    status(clusters_to_be_assigned, msg);
    status(aligned_slices, msg);
}  // container_pack_cohabit


void PHV_MAU_Group_Assignments::consolidate_slices_in_group(
    ordered_map<int,
    ordered_map<int,
    std::set<std::set<PHV_MAU_Group::Container_Content *>>>>& aligned_slices) {
    //
    // consolidate to get larger number same width only when all aligned and same MAU group
    // [3](2)*2 ((PHV-149<3>{8..10}, PHV-147), (PHV-145<3>{8..10}, PHV-151)) ==> [3](4)*1
    //
    for (auto w : aligned_slices) {
        for (auto n : w.second) {
            if (n.second.size() > 1) {
                //
                // multiple sets in set of sets
                // attempt to consolidate only within same MAU group
                //
                ordered_map<PHV_MAU_Group *,
                ordered_map<int, std::set<std::set<PHV_MAU_Group::Container_Content *>>>> g_lo;
                for (auto &cc_set : n.second) {
                    PHV_Container *c = (*(cc_set.begin()))->container();
                    int lo = (*(cc_set.begin()))->lo();
                    g_lo[c->phv_mau_group()][lo].insert(cc_set);
                }
                // all elements of g_lo[g][lo] must be used for aligned_slices[w][n]
                //
                aligned_slices[w.first].erase(n.first);
                for (auto &g : g_lo) {
                    for (auto &l : g.second) {
                        if (l.second.size() > 1) {
                            //
                            // make a composite set from all sets in l.second
                            //
                            std::set<PHV_MAU_Group::Container_Content *> *set_u
                                = new std::set<PHV_MAU_Group::Container_Content *>;
                            for (auto &cc_set : l.second) {
                                for (auto &cc : cc_set) {
                                    set_u->insert(cc);
                                }
                            }
                            aligned_slices[w.first][set_u->size()].insert(*set_u);
                        } else {
                            //
                            // use existing singleton set
                            //
                            aligned_slices[w.first][n.first].insert(*(l.second.begin()));
                        }
                    }
                }
            }
        }
    }
}  // consolidate_slices_in_group

//
// container cohabit summary
// recommendations to TP phase
// avoid single write issue
// consider only containers that have more than 1 field each with mau_write
//

void PHV_MAU_Group_Assignments::container_cohabit_summary() {
    for (auto &gg : PHV_MAU_i) {
        // groups within this word size
        for (auto &g : gg.second) {
            for (auto &c : g->phv_containers()) {
                if (c->fields_in_container().size() > 1) {
                    int fields_written = 0;
                    for (auto &cc : c->fields_in_container()) {
                        if (cc->field()->mau_write) {
                            fields_written++;
                        }
                    }
                    if (fields_written > 1) {
                        cohabit_fields_i.push_back(c);
                    }
                }
            }
        }
    }
}  // container_cohabit_summary


//***********************************************************************************
//
// status
//
//***********************************************************************************


bool PHV_MAU_Group_Assignments::status(
    std::list<Cluster_PHV *>& clusters_to_be_assigned,
    const char *msg) {
    //
    if (clusters_to_be_assigned.size() > 0) {
        ordered_map<PHV_Container::Ingress_Egress,
            ordered_map<PHV_Container::PHV_Word, int>> needed_containers;
            //
        for (auto &w : num_groups_i) {
            needed_containers[PHV_Container::Ingress_Egress::Ingress_Only][w.first] = 0;
            needed_containers[PHV_Container::Ingress_Egress::Egress_Only][w.first] = 0;
        }
        int needed_bits = 0;
        for (auto &cl : clusters_to_be_assigned) {
           needed_containers[cl->gress()][cl->width()] += cl->num_containers();
           needed_bits += cl->num_containers() * static_cast<int>(cl->width());
        }
        std::stringstream ss;
        for (auto &n_c : needed_containers) {
            for (auto &n : n_c.second) {
                if (n.second) {
                    ss << " " << n.second
                       << "<" << static_cast<int>(n.first) << "b>"
                       << static_cast<char>(n_c.first);
                }
            }
        }
        if (needed_bits) {
            ss << " (bits=" << needed_bits << ");";
        }
        std::string s = ss.str();
        LOG3(std::endl << "---------- Status: Clusters NOT Assigned ("
            << clusters_to_be_assigned.size()
            << ")"
            << s
            << "----------"
            << msg
            << std::endl
            << clusters_to_be_assigned);
        return false;
    } else {
        LOG3(' ');
        LOG3("++++++++++++++++++++ Status: ALL clusters Assigned ++++++++++++++++++++"
            << msg);
        LOG3(' ');
        return true;
    }
}

bool PHV_MAU_Group_Assignments::status(
    ordered_map<int, ordered_map<int, std::set<std::set<PHV_MAU_Group::Container_Content *>>>>&
        aligned_slices,
    const char *msg) {
    //
    if (aligned_slices.empty()) {
        LOG3("----------Status: NO Container Packs Available----------"
            << msg
            << std::endl);
        return false;
    } else {
        int bits_available = 0;
        for (auto &w : aligned_slices) {
            for (auto &n : w.second) {
                bits_available += w.first * n.first * n.second.size();
            }
        }
        LOG3("..........Status: Container Packs Available"
            << " ("
            << bits_available
            << " bits).........."
            << msg
            << std::endl
            << aligned_slices);
        return true;
    }
}

bool PHV_MAU_Group_Assignments::status(
    std::list<PHV_MAU_Group *>& phv_mau_groups,
    const char *msg) {
    //
    if (phv_mau_groups.empty()) {
        LOG3("----------Status: NO MAU Groups w/ empty Containers Available----------"
            << std::endl);
        return false;
    } else {
        LOG3("..........Status: MAU Groups w/ empty Containers Available.........."
            << phv_mau_groups);
        return true;
    }
}

//***********************************************************************************
//
// sanity checks
//
//***********************************************************************************


void PHV_MAU_Group::Container_Content::sanity_check_container(const std::string& msg) {
    //
    const std::string msg_1 = msg+"PHV_MAU_Group::Container_Content..";
    //
    container_i->sanity_check_container_avail(lo_i, hi_i, msg_1);
}

void PHV_MAU_Group::sanity_check_container_packs(const std::string& msg) {
    //
    // for all aligned container_packs in MAU Group
    // check width of each slice
    // check only one slice range per map[w][n]
    //
    for (auto w : aligned_container_slices_i) {
        for (auto n : w.second) {
            for (auto cc_set : n.second) {
                // for all members check width and range lo .. hi
                // also check all containers belong to the same gress
                //
                std::set<int> lo;
                std::set<int> hi;
                lo.clear();
                hi.clear();
                std::set<PHV_Container::Ingress_Egress> gress;
                for (auto cc : cc_set) {
                    if (cc->width() != w.first) {
                        LOG1(
                           "*****cluster_phv_mau.cpp:sanity_FAIL*****cluster_pack width differs .."
                               << w.first
                               << " vs "
                               << cc
                               << ' '
                               << msg);
                    }
                    lo.insert(cc->lo());
                    hi.insert(cc->hi());
                    //
                    gress.insert(cc->container()->gress());
                }
                if (lo.size() != 1) {
                    LOG1("*****cluster_phv_mau.cpp:sanity_FAIL*****cluster_pack lo differs .."
                            << '['
                            << w.first
                            << "]["
                            << n.first
                            << ' '
                            << msg);
                }
                if (hi.size() != 1) {
                    LOG1("*****cluster_phv_mau.cpp:sanity_FAIL*****cluster_pack hi differs .."
                           << '['
                           << w.first
                           << "]["
                           << n.first
                           << ' '
                           << msg);
                }
                if (gress.size() != 1) {
                    LOG1("*****cluster_phv_mau.cpp:sanity_FAIL***** "
                           << "gress differs ....."
                           << n.second
                           << std::endl
                           << "\t"
                           << msg);
                }
            }
        }
    }
}

void PHV_MAU_Group::sanity_check_container_fields_gress(const std::string& msg) {
    //
    // all fields contained in this container are gress compatible with container gress
    // all containers in group have the same gress
    //
    PHV_Container::Ingress_Egress g_gress = phv_containers_i.front()->gress();
    for (auto c : phv_containers_i) {
        for (auto cc : c->fields_in_container()) {
            const PhvInfo::Field *field = cc->field();
            PHV_Container::Ingress_Egress f_gress = PHV_Container::gress(field);
            if (f_gress != c->gress()) {
                LOG1("*****cluster_phv_mau.cpp:sanity_FAIL***** "
                       << "field ~ container gress differ ..... "
                       << static_cast<char>(f_gress)
                       << " vs "
                       << static_cast<char>(c->gress())
                       << "..."
                       << msg
                       << c);
            }
        }
        if (g_gress != c->gress()) {
            LOG1("*****cluster_phv_mau.cpp:sanity_FAIL***** "
                   << "MAU group ~ container gress differ ..... "
                   << static_cast<char>(g_gress)
                   << " vs "
                   << static_cast<char>(c->gress())
                   << "..."
                   << msg
                   << c);
        }
    }
}

void PHV_MAU_Group::sanity_check_group_containers(const std::string& msg) {
    for (auto &w : aligned_container_slices_i) {
        for (auto &n : w.second) {
            for (auto &cc_set : n.second) {
                for (auto &cc : cc_set) {
                    cc->sanity_check_container(msg
                        + "PHV_MAU_Group::sanity_check_group_containers..");
                }
            }
        }
    }
    for (auto &c : phv_containers_i) {
        c->sanity_check_container(msg
           + "PHV_MAU_Group::sanity_check_group_containers phv_containers..");
    }
}

void PHV_MAU_Group_Assignments::sanity_check_container_avail(const std::string& msg) {
    const std::string msg_1 = msg+"PHV_MAU_Group_Assignments::sanity_check_container_avail..";
    //
    // check aligned_container_slices map agrees with container filling
    //
    for (auto &w : aligned_container_slices_i) {
        for (auto &n : w.second) {
            for (auto &cc_set : n.second) {
                for (auto &cc : cc_set) {
                    PHV_Container *c = cc->container();
                    c->sanity_check_container_avail(cc->lo(), cc->hi(), msg_1);
                    BUG_CHECK(cc->hi() >= cc->lo(),
                        "*****PHV_MAU_Group_Assignments::sanity_check_container_avail *****"
                        "PHV-%d, ranges[%d] = %d, should be %d",
                        c->phv_number(), cc->lo(), c->ranges()[cc->lo()], cc->hi());
                    PHV_MAU_Group *g = c->phv_mau_group();
                    g->sanity_check_group_containers(msg_1);
                    LOG4("~~~~~G"
                         << g->number()
                         <<":["
                         << w.first
                         << "]["
                         << n.first
                         << "]="
                         << cc_set);
                }
            }
        }
    }
}

void PHV_MAU_Group_Assignments::sanity_check_container_fields_gress(const std::string& msg) {
    for (auto groups : PHV_MAU_i) {
        for (auto g : groups.second) {
            g->sanity_check_container_fields_gress(msg);
        }
    }
}

void PHV_MAU_Group_Assignments::sanity_check_group_containers(const std::string& msg) {
    //
    // sanity check PHV_MAU_Group_Assignments aligned_container_slices with individual MAU Groups
    //
    for (auto &w : aligned_container_slices_i) {
        for (auto &n : w.second) {
            for (auto &cc_set : n.second) {
                PHV_Container *c = (*(cc_set.begin()))->container();
                PHV_MAU_Group *g = c->phv_mau_group();
                if (g->aligned_container_slices()[w.first][n.first].count(cc_set) != 1) {
                    LOG1("*****cluster_phv_mau.cpp:sanity_FAIL*****.."
                            << msg
                            << g
                            << " aligned_container_slices does not contain"
                            << cc_set);
                }
            }
        }
    }
    // sanity check individual MAU Groups aligned_container_slices
    // with composite PHV_MAU_Group_Assignments
    // for each MAU Group sanity check constituent containers
    //
    for (auto groups : PHV_MAU_i) {
        for (auto g : groups.second) {
            for (auto &w : g->aligned_container_slices()) {
                for (auto &n : w.second) {
                    for (auto &cc_set : n.second) {
                        if (aligned_container_slices_i[w.first][n.first].count(cc_set) != 1) {
                            LOG1("*****cluster_phv_mau.cpp:sanity_FAIL*****.."
                                    << msg
                                    << " composite aligned_container_slices does not contain"
                                    << cc_set
                                    << " from "
                                    << g);
                        }
                    }
                }
            }
            g->sanity_check_group_containers(msg);
        }
    }
    // sanity check a field is not duplicately allocated
    // check spans all groups, containers
    // field can straddle containers but should not be allocated again
    //
    ordered_map<const PhvInfo::Field *,
        std::set<PHV_Container::Container_Content *>> field_container_map;
    for (auto groups : PHV_MAU_i) {
        for (auto g : groups.second) {
            for (auto c : g->phv_containers()) {
                for (auto cc : c->fields_in_container()) {
                    const PhvInfo::Field *field = cc->field();
                    field_container_map[field].insert(cc);
                }
            }
        }
    }
    for (auto &entry : field_container_map) {
        auto field = entry.first;
        auto cc_s = entry.second;
        //
        // assert width allocated in container(s) matches field width
        // width will exceed when field duplicately allocated
        //
        int width_in_c = 0;
        for (auto &cc : cc_s) {
            width_in_c += cc->width();
        }
        int field_width = field->phv_use_width();
        if (field_width != width_in_c) {
            LOG1("*****cluster_phv_mau.cpp:sanity_FAIL*****");
            LOG1(msg);
            if (cc_s.size() > 1) {
                LOG1(".....field duplicated in containers.....");
            } else {
                LOG1(".....allocated space exceeds field width (non-uniform cluster ?).....");
            }
            LOG1(field);
            LOG1("width_in_c = " << width_in_c << ", phv_use_width = " << field_width);
            LOG1(cc_s);
        }
    }
}

void PHV_MAU_Group_Assignments::sanity_check_T_PHV_collections(const std::string& msg) {
    //
    // sanity check T_PHV collections containers have same gress
    //
    for (auto &coll : T_PHV_i) {
        std::set<PHV_Container::Ingress_Egress> gress_set;
        for (auto &v : coll.second) {
            for (auto &c : v.second) {
                gress_set.insert(c->gress());
            }
        }
        if (gress_set.size() != 1) {
            LOG1("*****cluster_phv_mau.cpp:sanity_FAIL***** T_PHV Collection.."
                    << coll.second
                    << "..."
                    << msg);
        }
    }
}

//***********************************************************************************
//
// output stream <<
//
//***********************************************************************************
//
// PHV_MAU_Group Container_Content output
//
std::ostream &operator<<(std::ostream &out, PHV_MAU_Group::Container_Content *c) {
    if (c) {
        out << c->container()
            << '<'
            << c->width()
            << '>'
            << '{' << c->lo()
            << ".."
            << c->hi()
            << '}';
    } else {
        out << "--cc--";
    }

    return out;
}
//
//
std::ostream &operator<<(std::ostream &out, std::set<PHV_MAU_Group::Container_Content *>& slices) {
    out << '(';
    for (auto c : slices) {
        if (c->container()->status() != PHV_Container::Container_status::FULL) {
            out << c << ' ';
        }
    }
    out << std::endl << "\t)";

    return out;
}
//
//
std::ostream &operator<<(
    std::ostream &out,
    ordered_map<int, ordered_map<int, std::set<std::set<PHV_MAU_Group::Container_Content *>>>>&
    all_container_packs) {
    //
    // map[w][n] --> <set of <set of container_packs>>
    //
    // output in sorted order, not in map insertion order
    //
    std::map<int, std::map<int, std::set<std::set<PHV_MAU_Group::Container_Content *>>>> cpks;
    for (auto &w : all_container_packs) {
        for (auto &n : w.second) {
            cpks[w.first][n.first] = all_container_packs[w.first][n.first];
        }
    }
    for (auto &w : cpks) {
        for (auto &n : w.second) {
            out << std::endl << "\t" << "[w" << w.first << "](n" << n.first << ')';
            if (n.second.size() > 1) {
                out << '*' << n.second.size();
            }
            out << std::endl << '\t';
            for (auto s : n.second) {
                out << s;
            }
        }
    }
    out << std::endl;

    return out;
}
//
// phv_mau_group output
//
std::ostream &operator<<(std::ostream &out, PHV_MAU_Group &g) {
    //
    // mau group summary
    //
    out << 'G' << g.number() << "[w" << static_cast<int>(g.width()) << ']';
    out << static_cast<char>(g.gress());
    if (g.empty_containers()) {
        out << "(V" << g.empty_containers() << ')';
    }
    // summarize packable containers
    std::set<PHV_Container *> containers_pack;
    for (auto c : g.phv_containers()) {
        if (c->status() != PHV_Container::Container_status::FULL) {
            containers_pack.insert(c);
        }
    }
    if (containers_pack.size()) {
        out << "\t{ ";
        for (auto c : containers_pack) {
            out << c << ' ';
        }
        out << std::endl << "\t}";
    }
    // summarize container slice groups
    if (!g.aligned_container_slices().empty()) {
        for (auto w : g.aligned_container_slices()) {
            for (auto n : w.second) {
                out << std::endl << "\t" << "[w" << w.first << "](n" << n.first << ')' << std::endl;
                for (auto s : n.second) {
                    out << '\t' << s;
                }
            }
        }
    }

    return out;
}

std::ostream &operator<<(std::ostream &out, PHV_MAU_Group *g) {
    //
    // mau group details
    //
    if (g) {
        out << *g << std::endl       // summary
            << g->phv_containers();  // details
    } else {
        out << "-g-";
    }

    return out;
}

std::ostream &operator<<(std::ostream &out, std::list<PHV_MAU_Group *> &phv_mau_list) {
    out << std::endl;
    for (auto m : phv_mau_list) {
        // summary
        out << *m << std::endl;
    }

    return out;
}

std::ostream &operator<<(std::ostream &out, std::vector<PHV_MAU_Group *> *phv_mau_vec) {
    out << '[';
    if (phv_mau_vec) {
        out << std::endl;
        for (auto g : *phv_mau_vec) {
           // mau group summary
           out << *g << std::endl;
        }
    } else {
        out << "-mgv-";
    }
    out << ']' << std::endl;

    return out;
}

std::ostream &operator<<(std::ostream &out, std::vector<PHV_MAU_Group *> &phv_mau_vec) {
    out << std::endl;
    out << "++++++++++ #mau_groups=" << phv_mau_vec.size() << " ++++++++++" << std::endl;
    for (auto m : phv_mau_vec) {
        out << std::endl;
        out << m;
    }
    out << std::endl;

    return out;
}

//
// phv_mau_group_assignments output
//

std::ostream &operator<<(
    std::ostream &out,
    ordered_map<PHV_Container::PHV_Word, std::vector<PHV_Container *>>& coll) {
    //
    for (auto m : coll) {
        out << m.second;
    }
    out << std::endl;

    return out;
}

std::ostream &operator<<(
    std::ostream &out,
    ordered_map<PHV_Container::PHV_Word, std::vector<PHV_MAU_Group *>>& phv_mau_map) {
    //
    for (auto &m : phv_mau_map) {
        out << m.second;
    }
    out << std::endl;

    return out;
}

std::ostream &operator<<(
    std::ostream &out,
    ordered_map<int, ordered_map<PHV_Container::PHV_Word, std::vector<PHV_Container *>>>&
        t_phv_mau_map) {
    //
    for (auto &m : t_phv_mau_map) {
        out << m.second;
    }
    out << std::endl;

    return out;
}

std::ostream &operator<<(std::ostream &out, PHV_MAU_Group_Assignments &phv_mau_grps) {
    out << "++++++++++ PHV MAU Group Assignments ++++++++++" << std::endl;
    for (auto rit = phv_mau_grps.phv_mau_map().rbegin();
         rit != phv_mau_grps.phv_mau_map().rend();
         ++rit) {
        out << rit->second;
    }
    //
    out << std::endl
        << "++++++++++ T_PHV Collections ++++++++++" << std::endl;
    for (auto coll : phv_mau_grps.t_phv_map()) {
        out << std::endl << "Collection" << coll.first;
        out << coll.second;
    }
    //
    out << std::endl
        << "++++++++++ Container Cohabit Summary .....("
        << phv_mau_grps.cohabit_fields().size()
        << ")..... ++++++++++"
        << std::endl
        << std::endl;
    for (auto cof : phv_mau_grps.cohabit_fields()) {
        out << '<' << cof->fields_in_container().size() << ':' << *cof << std::endl;
        out << '>' << std::endl;
    }

    return out;
}
