#include "cluster_phv_bind.h"
#include "lib/log.h"
#include "lib/stringref.h"

//***********************************************************************************
//
// PHV_Bind::apply_visitor()
//
//***********************************************************************************


const IR::Node *
PHV_Bind::apply_visitor(const IR::Node *node, const char *name) {
    //
    LOG1("..........PHV_Bind::apply_visitor()..........");
    if (name) {
        LOG1(name);
    }
    //
    // uses_i recomputed after dead-code elimination
    //
    node->apply(*uses_i);
    //
    create_phv_asm_container_map();
    //
    collect_containers_with_fields();
    //
    // during phv_analysis phase (cluster analysis) fields that are metadata,
    // e.g.,
    // 3:ingress::standard_metadata.clone_spec[32]{0..31} I off=81 meta
    // becomes
    // 3:ingress::standard_metadata.clone_spec[32]{0..31} I off=81 ref meta
    // 'ref' is set by PhvInfo::SetReferenced pass, called twice in the backend
    // once after ElimUnused (before phv_bind) and also before asm generation
    // if these references are used (parser, mau, or deparser, (or multiple)),
    // need phv allocation
    //
    if (fields_overflow_i.size()) {
        phv_tphv_allocate(fields_overflow_i);
        collect_containers_with_fields();
    }
    //
    sanity_check_all_fields_allocated("PHV_Bind::apply_visitor()..");
    sanity_check_field_duplicate_containers("PHV_Bind::apply_visitor()..");
    //
    bind_fields_to_containers();
    //
    // Trivially allocating overflow fields
    // some clusters yet not assigmed after
    //     mutex headers overlap
    //     interference gragh
    //     cluster slicing
    // perhaps due to Ingress / Egress partitions
    // e.g., Ingress containers available, but Egress clusters remain & vice versa
    //
    if (fields_overflow_i.size()) {
        trivial_allocate(fields_overflow_i);
    }
    //
    LOG3(*this);
    //
    return node;
}  // apply_visitor

void
PHV_Bind::create_phv_asm_container_map() {
    //
    // PHV_MAU_i[width] = vector of groups
    for (auto &x : phv_mau_i.phv_mau_map()) {
        for (auto &y : x.second) {
            for (auto &c : y->phv_containers()) {
                phv_to_asm_map_i[c] =
                    new PHV::Container(const_cast<PHV_Container *>(c)->asm_string().c_str());
            }
        }
    }
    // T_PHV_i[collection][width] = vector of containers
    for (auto &x : phv_mau_i.t_phv_map()) {
        for (auto &y : x.second) {
            for (auto &c : y.second) {
                phv_to_asm_map_i[c] =
                    new PHV::Container(const_cast<PHV_Container *>(c)->asm_string().c_str());
            }
        }
    }
}

void
PHV_Bind::collect_containers_with_fields() {
    //
    // collect all allocated containers from phv_mau_map, t_phv_map
    // accumulate containers_i, fields_i
    //
    containers_i.clear();
    // fields_i.clear();
    fields_overflow_i.clear();
    //
    for (auto &it : phv_mau_i.phv_mau_map()) {
        for (auto &g : it.second) {
            for (auto &c : g->phv_containers()) {
                if (c->fields_in_container().size()) {
                    containers_i.push_front(c);
                    for (auto &entry : c->fields_in_container()) {
                        fields_i.insert(entry.first);
                    }
                }
            }
        }
    }
    for (auto &coll : phv_mau_i.t_phv_map()) {
        for (auto &c_s : coll.second) {
            for (auto &c : c_s.second) {
                if (c->fields_in_container().size()) {
                    containers_i.push_front(c);
                    for (auto &entry : c->fields_in_container()) {
                        fields_i.insert(entry.first);
                    }
                }
            }
        }
    }
    //
    // set difference (All phv_i fields, fields_i) => fields_overflow_i
    //
    std::set<const PhvInfo::Field *> s1;
    // All Fields
    for (auto &field : phv_i) {
        //
        // discard fields that are not used
        //
        bool use_mau = uses_i->use[1][field.gress][field.id];
        bool use_parde = uses_i->use[0][field.gress][field.id];
        if (field.pov
           || use_mau
           || use_parde) {
            //
            s1.insert(&field);
        } else {
            LOG3("PHV_Bind::collect_containers.....discarding field (use_mau=0,use_parde=0)....."
                << &field);
        }
    }
    std::set<const PhvInfo::Field *> s2(fields_i.begin(), fields_i.end());
    // fields_overflow_i = All - PHV_Bind fields
    set_difference(
        s1.begin(),
        s1.end(),
        s2.begin(),
        s2.end(),
        std::back_inserter(fields_overflow_i));
    //
    fields_overflow_i.sort(
        [](const PhvInfo::Field *l, const PhvInfo::Field *r) {
            // sort by cluster id_num to prevent non-determinism
            return l->id < r->id;
        });
    //
}  // collect_containers_with_fields

void
PHV_Bind::phv_tphv_allocate(std::list<const PhvInfo::Field *>& fields) {
    std::list<Cluster_PHV *> phv_clusters;
    std::list<Cluster_PHV *> t_phv_clusters;
    //
    int cluster_num = 0;
    ordered_set<const PhvInfo::Field *> remove_set;
    for (auto &f : fields) {
        if (f->ccgf && f->ccgf != f) {
            // no separate allocation required for ccgf members, remove field
            remove_set.insert(f);
            continue;
        }
        if (uses_i->use[1][f->gress][f->id]) {
            // used in MAU
            phv_clusters.push_back(new Cluster_PHV(f, cluster_num, "phv_bind_phv_"));
            cluster_num++;
        } else {
            if (uses_i->use[0][f->gress][f->id]) {
                // used in parser / deparser
                t_phv_clusters.push_back(new Cluster_PHV(f, cluster_num, "phv_bind_t_phv_"));
                cluster_num++;
            } else {
                // no allocation required, remove field
                remove_set.insert(f);
            }
        }
    }
    for (auto &f : remove_set) {
        fields.remove(f);
    }
    if (phv_clusters.size()) {
        phv_mau_i.container_pack_cohabit(
            phv_clusters,
            phv_mau_i.aligned_container_slices(),
            "PHV_Bind:PHV");
    }
    if (t_phv_clusters.size()) {
        phv_mau_i.container_pack_cohabit(
            t_phv_clusters,
            phv_mau_i.T_PHV_container_slices(),
            "PHV_Bind:T_PHV");
    }
}  // phv_tphv_allocate

void
PHV_Bind::bind_fields_to_containers() {
    //
    // binding fields to containers
    // clear previous field alloc information if any
    //
    for (auto &f : fields_i) {
        PhvInfo::Field *f1 = const_cast<PhvInfo::Field *>(f);
        f1->alloc.clear();
        // ccgf members
        if (f1->ccgf_fields.size()) {
            for (auto &m : f1->ccgf_fields) {
                m->alloc.clear();
            }
        }
    }
    for (auto &c : containers_i) {
        for (auto &entry : const_cast<PHV_Container *>(c)->fields_in_container()) {
            PHV_Container::Container_Content *cc = entry.second;
            PhvInfo::Field *f1 = const_cast<PhvInfo::Field *>(entry.first);
            int field_bit = cc->field_bit_lo();
            int container_bit = cc->lo();
            int width_in_container = cc->width();
            PHV::Container *asm_container = phv_to_asm_map_i[c];
            //
            // ignore allocation for owners of
            // non-header stack ccgs
            // simple header ccgs
            //
            f1->alloc.emplace_back(
               *asm_container,
               field_bit,
               container_bit,
               width_in_container);

            // contiguous container group allocation
            // in case bypassing MAU PHV allocation PHV_container::taint() recursion
            //
            // int container_width = const_cast<PHV_Container *>(c)->width();
            // container_contiguous_alloc(f1,
            //                            container_width,
            //                            asm_container,
            //                            width_in_container);
        }
    }
    //
    // phv_fields.h vector<alloc_slice> alloc;
    // sorted MSB (field) first
    // sort fields' alloc
    //
    for (auto &f : fields_i) {
        PhvInfo::Field *f1 = const_cast<PhvInfo::Field *>(f);
        if (f1->alloc.size() > 1) {
            std::sort(f1->alloc.begin(), f1->alloc.end(),
                [](PhvInfo::Field::alloc_slice l, PhvInfo::Field::alloc_slice r) {
                    return l.field_bit > r.field_bit;
            });
        }
    }
}  // bind_fields_to_containers

void
PHV_Bind::container_contiguous_alloc(
    PhvInfo::Field* f1,
    int container_width,
    PHV::Container *asm_container,
    int width_in_container) {
    //
    // container contiguous allocation
    // header fields allocation permits no holes in container
    // header stack povs allocation permits leading / trailing holes beside ccgf
    //
    if (f1->ccgf_fields.size()) {
        if (f1->ccgf == f1) {
            // contiguous container group allocation
            // cases bypassing MAU PHV allocation PHV_container::taint() recursion
            // consider MSB order
            int processed_members = 0;
            // container_bit start
            int start = container_width;
            for (auto &member : f1->ccgf_fields) {
                int member_bit_lo = member->phv_use_lo;
                int use_width = member->size - member->phv_use_rem;
                start -= use_width;
                if (start < 0) {
                    // member straddles containers
                    // remainder bits processed
                    // in subsequent container allocated to owner
                    use_width += start;
                    start = 0;
                    member_bit_lo = member->size - member->phv_use_rem - use_width;
                    member->phv_use_rem += use_width;  // spans several containers
                                                       // aggregate used bits
                                                       // [width 20] = 12..19[8b] 4..11[8b] 0..3[4b]
                } else {
                    processed_members++;
                    member->phv_use_rem = 0;
                }
                // -- reentrant PHV_Bind, preserve entry state of member
                // member->ccgf = 0;
                member->alloc.emplace_back(
                    *asm_container,
                    member_bit_lo,
                    start,
                    use_width);
                if (start <= 0) {
                    break;
                }
            }
            // -- reentrant PHV_Bind, preserve entry state of f1
            // f1->ccgf_fields.erase(
                // f1->ccgf_fields.begin(),
                // f1->ccgf_fields.begin() + processed_members);
            // if (f1->ccgf_fields.size()) {
                // f1->ccgf = f1;
            // }
        } else {
            //
            // header stack pov members
            // constituent members of header stack povs must fit header stk pov
            // this condition should be guaranteed by phv_fields.cpp allocatePOV()
            //
            int container_bit = width_in_container + 1;
            for (auto &pov_f : f1->ccgf_fields) {
                int field_bit = pov_f->phv_use_lo;
                int pov_width = pov_f->size;
                container_bit -= pov_width;
                if (f1->simple_header_pov_ccgf) {  // simple header ccgf
                    container_bit -= 2;
                    f1->phv_use_hi = f1->size - 1;
                }
                //
                // check constituent members do fit hdr stk pov
                //
                if (container_bit < 0) {
                    WARNING("*****PHV_Bind: header stack overrun *****"
                        << " hdr stk pov: "
                        << f1
                        << " pov member: "
                        << pov_f
                        << " container_bit: "
                        << container_bit);
                }
                pov_f->alloc.emplace_back(
                    *asm_container,
                    field_bit,
                    container_bit,
                    pov_width);
            }
        }
    }
}  // container_contiguous_alloc

void
PHV_Bind::trivial_allocate(std::list<const PhvInfo::Field *>& fields) {
    //
    // trivially allocating overflow fields
    //
    LOG3("********** Overflow Allocation **********");
    ordered_map<PHV_Container::PHV_Word, int> overflow_reg {
        {PHV_Container::PHV_Word::b32, 64},
        {PHV_Container::PHV_Word::b16, 224},
        {PHV_Container::PHV_Word::b8,  128},
    };
    //
    // binding fields to containers
    // clear previous field alloc information if any
    //
    for (auto &f : fields) {
        PhvInfo::Field *f1 = const_cast<PhvInfo::Field *>(f);
        f1->alloc.clear();
        // ccgf members
        if (f1->ccgf_fields.size()) {
            for (auto &pov_f : f1->ccgf_fields) {
                pov_f->alloc.clear();
            }
        }
    }
    PHV_Container::PHV_Word container_width = PHV_Container::PHV_Word::b8;
    for (auto &f : fields) {
        //
        // skip members of ccgfs as owners will allocate for them
        //
        if (f->ccgf && !f->ccgf_fields.size()) {
            continue;
        }
        std::string container_prefix = "";
        if (!uses_i->use[1][f->gress][f->id]
            && uses_i->use[0][f->gress][f->id]) {
            //
            // not used in mau && used in paser / deparser
            //
            container_prefix = "T";
        }
        PhvInfo::Field *f1 = const_cast<PhvInfo::Field *>(f);
        int field_bit = 0;
        int container_bit = 0;
        if (f->phv_use_width() > 16) {
            container_width = PHV_Container::PHV_Word::b32;
            container_prefix += "W";
        } else if (f->phv_use_width() > 8) {
            container_width = PHV_Container::PHV_Word::b16;
            container_prefix += "H";
        } else {
            container_width = PHV_Container::PHV_Word::b8;
            container_prefix += "B";
        }
        PHV::Container *asm_container;
        for (field_bit = 0; field_bit < f->phv_use_width(); /* nil */) {
            std::stringstream ss;
            ss << overflow_reg[container_width];
            overflow_reg[container_width]++;
            std::string reg_string = container_prefix + ss.str();
            const char *reg_name = reg_string.c_str();
            asm_container = new PHV::Container(reg_name);
            int width_in_container = f->size - f->phv_use_rem;
            if (width_in_container > container_width) {
                width_in_container = container_width;
                f1->phv_use_rem += width_in_container;  // spans several containers
                                                        // aggregate used bits
                                                        // [width 20]= 12..19[8b] 4..11[8b] 0..3[4b]
            } else {
                f1->phv_use_rem = 0;
            }
            f1->alloc.emplace_back(
                *asm_container, field_bit, container_bit, width_in_container);
            LOG3(f << '[' << field_bit << ".." << f->phv_use_width()-1 << "] ..... " << reg_name);
            field_bit += width_in_container;
        }
        // ccgf owners allocate for members
        if (f->ccgf_fields.size()) {
            if (!f->header_stack_pov_ccgf) {
                //
                // do not remove allocation for owners
                // that are not members of ccgf, e.g., header stack povs
                // egress::mpls.$stkvalid[6]{0..6}-r- --ccgf-> egress::mpls.$stkvalid
                // [       egress::vxlan_gpe_int_header.$valid[1]
                //         egress::mpls.$push[3]
                //         egress::mpls[0].$valid[1]
                //         egress::mpls[1].$valid[1]
                //         egress::mpls[2].$valid[1]
                // :7]
                //
                // when owner is member of ccgf,
                // remove owner's allocation
                // egress::tunnel_metadata.tunnel_src_index[9]{0..31}-r- --ccgf->
                // e.g., [31:0]->[W109]        -- removed
                //       [8:0]->[W109](23..31) -- fresh allocation
                //
                f1->alloc.clear();
            }
            container_contiguous_alloc(f1,
                                       container_width,
                                       asm_container,
                                       container_width);
        }
    }
}


//***********************************************************************************
//
// sanity checks
//
//***********************************************************************************


void PHV_Bind::sanity_check_field_duplicate_containers(
    const std::string& msg) {
    //
    const std::string msg_1 = msg+"PHV_Bind::sanity_check_field_duplicate_containers";
    //
    for (auto &f : fields_i) {
        ordered_set<int> hi_s;
        for (auto &as : f->alloc) {
            if (hi_s.count(as.field_bit)) {
                LOG1(std::endl
                    << "*****cluster_phv_bind.cpp:sanity_FAIL***** "
                    << msg_1
                    << std::endl
                    << ".....PHV_Bind Field Container duplication..... "
                    << std::endl
                    << f
                    << "\t"
                    << as);
            } else {
                hi_s.insert(as.field_bit);
            }
        }
    }
}


void PHV_Bind::sanity_check_all_fields_allocated(
    const std::string& msg) {
    //
    const std::string msg_1 = msg+"PHV_Bind::sanity_check_all_fields_allocated";
    //
    if (fields_overflow_i.size()) {
        LOG1(std::endl
            << "*****cluster_phv_bind.cpp:sanity_FAIL***** "
            << msg_1
            << std::endl
            << ".....Phv Bind fields != All Fields..... "
            << ".....need OverFlow Allocation....."
            << std::endl
            << std::endl
            << fields_overflow_i);
    }
}

//***********************************************************************************
//
// output stream <<
//
//***********************************************************************************
//
//

std::ostream &operator<<(std::ostream &out, PHV_Bind &phv_bind) {
    out << std::endl
        << "Begin ++++++++++++++++++++ PHV Bind Containers to Fields ++++++++++++++++++++"
        << std::endl
        << std::endl;
    for (auto &f : phv_bind.fields()) {
        out << f
            << std::endl;
    }
    if (phv_bind.fields_overflow().size()) {
        out << std::endl
            << "Begin .......... Overflow Fields ("
            << phv_bind.fields_overflow().size()
            << ") ........................"
            << std::endl
            << std::endl;
        for (auto &f : phv_bind.fields_overflow()) {
            out << f;
            for (auto &as : f->alloc) {
                out << std::endl
                    << '\t'
                    << as;
            }
            out << std::endl;
        }
        out << std::endl
            << "End .......... Overflow Fields ("
            << phv_bind.fields_overflow().size()
            << ") ........................"
            << std::endl
            << std::endl;
    }
    out << std::endl
        << "End ++++++++++++++++++++ PHV Bind Containers to Fields ++++++++++++++++++++"
        << std::endl
        << std::endl;
    return out;
}
