#include "cluster_phv_bind.h"
#include "lib/log.h"
#include "lib/stringref.h"
#include "base/logging.h"

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
    // collect all allocated containers from phv_mau_map, t_phv_map
    //
    containers_i.clear();
    for (auto &it : phv_mau_i.phv_mau_map()) {
        for (auto &g : it.second) {
            for (auto &c : g->phv_containers()) {
                if (c->fields_in_container().size()) {
                    containers_i.push_front(c);
                }
            }
        }
    }
    for (auto &coll : phv_mau_i.t_phv_map()) {
        for (auto &c_s : coll.second) {
            for (auto &c : c_s.second) {
                if (c->fields_in_container().size()) {
                    containers_i.push_front(c);
                }
            }
        }
    }
    //
    // accumulate fields to be bound
    // create equivalent asm containers
    //
    ordered_map<const PHV_Container*, PHV::Container *> phv_to_asm_map;
    for (auto &c : containers_i) {
        for (auto &cc : const_cast<PHV_Container *>(c)->fields_in_container()) {
            fields_i.insert(cc->field());
        }
        phv_to_asm_map[c] =
            new PHV::Container(const_cast<PHV_Container *>(c)->asm_string().c_str());
    }
    //
    std::set<const PhvInfo::Field *> fields_overflow;  // all - PHV_Bind fields
    sanity_check_container_fields("PHV_Bind::PHV_Bind()..", fields_overflow);
    //
    // binding fields to containers
    // clear previous field alloc information if any
    //
    for (auto &f : fields_i) {
        PhvInfo::Field *f1 = const_cast<PhvInfo::Field *>(f);
        f1->alloc.clear();
        // header stack pov members
        if (f1->pov_fields.size()) {
            for (auto &pov_f : f1->pov_fields) {
                pov_f->alloc.clear();
            }
        }
    }
    for (auto &c : containers_i) {
        for (auto &cc : const_cast<PHV_Container *>(c)->fields_in_container()) {
            PhvInfo::Field *f1 = const_cast<PhvInfo::Field *>(cc->field());
            int field_bit = cc->field_bit_lo();
            int container_bit = cc->lo();
            int container_width = cc->width();
            PHV::Container *asm_container = phv_to_asm_map[c];
            f1->alloc.emplace_back(*asm_container, field_bit, container_bit, container_width);
            //
            // container contiguous allocation
            // for header fields it is complete, i.e., no holes
            // for header stack povs it may contain holes at the end
            //
            if (f1->pov_fields.size()) {
                if (f1->hdr_stk_pov == f1) {
                    // contigous container group allocation
                    // consider MSB order
                    f1->alloc.clear();
                    int container_bit = static_cast<int>(
                                        const_cast<PHV_Container *>(c)->width());
                    for (auto &member : f1->pov_fields) {
                        int field_bit = member->phv_use_lo;
                        container_bit -= member->size;
                        member->alloc.emplace_back(
                            *asm_container,
                            field_bit,
                            container_bit,
                            member->size);
                    }
                } else {
                    //
                    // header stack pov members
                    // constituent members of header stack povs must fit header stk pov
                    // this condition should be guaranteed by phv_fields.cpp allocatePOV()
                    //
                    int container_bit = container_width + 1;
                    for (auto &pov_f : f1->pov_fields) {
                        int field_bit = pov_f->phv_use_lo;
                        int pov_width = pov_f->size;
                        container_bit -= pov_width;
                        //
                        // check constituent members do fit hdr stk pov 
                        //
                        if (container_bit < 0) {
                            WARNING( "*****PHV_Bind: header stack overrun *****"
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
        }
    }
    //
    // phv_fields.h vector<alloc_slice> alloc;  // sorted MSB (field) first
    // for all fields sort
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
    //
    // Trivially allocating overflow fields
    //
    // trivial_allocate(fields_overflow);
    //
    LOG3(*this);
    //
    return node;
}


void
PHV_Bind::trivial_allocate(std::set<const PhvInfo::Field *>& fields) {
    //
    // trivially allocating overflow fields
    //
    LOG3("********** Overflow Allocation **********");
    std::map<PHV_Container::PHV_Word, int> overflow_reg {
        {PHV_Container::PHV_Word::b32, 64},
        {PHV_Container::PHV_Word::b16, 224},
        {PHV_Container::PHV_Word::b8,  128},
    };
    PHV_Container::PHV_Word container_width = PHV_Container::PHV_Word::b8;
    std::string container_prefix = "B";
    for (auto &f : fields) {
        if (!uses_i.use[0][f->gress][f->id]) {
            continue;
        }
        PhvInfo::Field *f1 = const_cast<PhvInfo::Field *>(f);
        int field_bit = 0;
        int container_bit = 0;
        if (f->size >= 16) {
            container_width = PHV_Container::PHV_Word::b32;
            container_prefix = "W";
        } else if (f->size >= 8) {
            container_width = PHV_Container::PHV_Word::b16;
            container_prefix = "H";
        }
        for (field_bit = 0; field_bit < f->size; field_bit++) {
            std::stringstream ss;
            ss << overflow_reg[container_width];
            overflow_reg[container_width]++;
            std::string reg_string = container_prefix + ss.str();
            const char *reg_name = reg_string.c_str();
            PHV::Container *asm_container = new PHV::Container(reg_name);
            f1->alloc.emplace_back(
                *asm_container, field_bit, container_bit, static_cast<int> (container_width));
            LOG3("....." << f << '[' << field_bit << "].." << reg_name);
            field_bit += static_cast<int> (container_width)-1;
        }
    }
}


//***********************************************************************************
//
// sanity checks
//
//***********************************************************************************


void PHV_Bind::sanity_check_container_fields(
    const std::string& msg,
    std::set<const PhvInfo::Field *>& s3) {
    //
    const std::string msg_1 = msg+"PHV_Bind::sanity_check_container_fields";
    //
    // set difference phv_i fields, fields_i must be 0
    //
    std::set<const PhvInfo::Field *> s1;                                // all fields
    for (auto &field : phv_i) {
        s1.insert(&field);
    }
    // s3 = all - PHV_Bind fields
    set_difference(
        s1.begin(),
        s1.end(),
        fields_i.begin(),
        fields_i.end(),
        std::inserter(s3, s3.end()));
    //
    // ?? fields may be unused in ingress, egress, need additional check before howling
    //
    if (s3.size()) {
        LOG1(std::endl
            << "*****cluster_phv_bind.cpp:sanity_FAIL*****"
            << msg
            << ".....phv bind fields != all....."
            << std::endl
            << s3);
    }
    //
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
        << "++++++++++ PHV Bind Containers to Fields ++++++++++"
        << std::endl
        << std::endl;
    for (auto &f : phv_bind.fields()) {
        out << f;
        for (auto &as : f->alloc) {
            out << std::endl
                << '\t'
                << as;
        }
        out << std::endl;
    }
    out << std::endl;

    return out;
}
