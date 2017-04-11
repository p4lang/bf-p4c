#include "cluster_phv_req.h"
#include "lib/log.h"
#include "lib/stringref.h"

//***********************************************************************************
//
// Cluster_PHV_Requirements::apply_visitor()
//
// input:
//      clusters: cluster.dst_map()
// output:
//      creates sorted PHV container requirements for clusters
//      map<PHV_Container::PHV_Word, map<int, std::vector<Cluster_PHV *>>> Cluster_PHV_i;
//      sorted PHV requirements <number_of_containers, width_of_containers>
//      number decreasing then width decreasing
//
//***********************************************************************************


const IR::Node *
Cluster_PHV_Requirements::apply_visitor(const IR::Node *node, const char *name) {
    //
    LOG1("..........Cluster_PHV_Requirements::apply_visitor()..........");
    if (name) {
        LOG1(name);
    }
    //
    // create PHV Requirements from clusters
    if (!cluster_i.dst_map().size()) {
        LOG1("***************Cluster_PHV_Requirements called w/ 0 clusters***************");
    }
    //
    int cluster_num = 0;
    for (auto &set_of_fields : Values(cluster_i.dst_map())) {
        Cluster_PHV *m = new Cluster_PHV(set_of_fields, cluster_num, "phv_");
        Cluster_PHV_i.push_back(m);
        cluster_num++;
    }
    //
    // cluster PHV requirement = [qty, width]
    // sort based on width requirement, greatest width first
    // for each width sort based on quantity requirement
    //
    std::sort(Cluster_PHV_i.begin(), Cluster_PHV_i.end(), [](Cluster_PHV *l, Cluster_PHV *r) {
        if (l->width() == r->width()) {
            if (l->num_containers() == r->num_containers()) {
                if (l->max_width() == r->max_width()) {
                    if (l->cluster_vec().size() == r->cluster_vec().size()) {
                        // sort by uniform_width first
                        if (l->uniform_width() == true && r->uniform_width() == true) {
                            // sort by cluster id_num to prevent non-determinism
                            return l->id_num() < r->id_num();
                        }
                        if (l->uniform_width() == true && r->uniform_width() == false) {
                            // sort by cluster id_num to prevent non-determinism
                            return true;
                        }
                        if (l->uniform_width() == false && r->uniform_width() == true) {
                            // sort by cluster id_num to prevent non-determinism
                            return false;
                        }
                        if (l->uniform_width() == false && r->uniform_width() == false) {
                            // same size, descending widths <2:_16_10> <2:_16_9> <2:_16_5>
                            int lf_phv_use_width = 0;
                            for (auto &lf : l->cluster_vec()) {
                                lf_phv_use_width += lf->phv_use_width();
                            }
                            int rf_phv_use_width = 0;
                            for (auto &rf : r->cluster_vec()) {
                                rf_phv_use_width += rf->phv_use_width();
                            }
                            if (lf_phv_use_width == rf_phv_use_width) {
                                // sort by cluster id_num to prevent non-determinism
                                return l->id_num() < r->id_num();
                            }
                            return lf_phv_use_width >= rf_phv_use_width;
                        }
                    }
                    return l->cluster_vec().size() > r->cluster_vec().size();
                }
                return l->max_width() > r->max_width();
            }
            return l->num_containers() > r->num_containers();
        }
        return l->width() > r->width();
    });
    //
    // POV Requirements from clusters
    // allocate all bits to PHVs only if they are used
    // some POV fields, e.g., header stacks, have width > 1
    // allocation of POV field bits must be contiguous
    // sort based on use: fld->phv_use_hi - fld->phv_use_lo
    // sort based on width requirement, greatest width first
    //
    for (auto p : cluster_i.pov_fields_not_in_cluster()) {
        pov_fields_i.push_back(new Cluster_PHV(p, cluster_num, "pov_"));
        cluster_num++;
    }
    std::sort(pov_fields_i.begin(), pov_fields_i.end(),
        [](Cluster_PHV *l, Cluster_PHV *r) {
            const PhvInfo::Field *fl =  *(l->cluster_vec().begin());
            const PhvInfo::Field *fr =  *(r->cluster_vec().begin());
            int l_range = fl->phv_use_hi - fl->phv_use_lo;
            int r_range = fr->phv_use_hi - fr->phv_use_lo;
            if (l_range == r_range) {
                if (fl->phv_use_width() == fr->phv_use_width()) {
                    if (fl->size == fr->size) {
                        // sort by cluster id_num to prevent non-determinism
                        return l->id_num() < r->id_num();
                    }
                    return fl->size > fr->size;
                }
                return fl->phv_use_width() > fr->phv_use_width();
            }
            return l_range > r_range;
        });
    //
    // T_PHV Requirements from clusters
    // sort based on width requirement, greatest width first
    //
    for (auto p : cluster_i.fields_no_use_mau()) {
        t_phv_fields_i.push_back(new Cluster_PHV(p, cluster_num, "t_phv_"));
        cluster_num++;
    }
    std::sort(t_phv_fields_i.begin(), t_phv_fields_i.end(),
        [](Cluster_PHV *l, Cluster_PHV *r) {
            const PhvInfo::Field *fl =  *(l->cluster_vec().begin());
            const PhvInfo::Field *fr =  *(r->cluster_vec().begin());
            int l_range = fl->phv_use_hi - fl->phv_use_lo;
            int r_range = fr->phv_use_hi - fr->phv_use_lo;
            if (l_range == r_range) {
                if (fl->phv_use_width() == fr->phv_use_width()) {
                    if (fl->size == fr->size) {
                        // sort by cluster id_num to prevent non-determinism
                        return l->id_num() < r->id_num();
                    }
                    return fl->size > fr->size;
                }
                return fl->phv_use_width() > fr->phv_use_width();
            }
            return l_range > r_range;
        });
    //
    LOG3(*this);
    //
    return node;
}

//***********************************************************************************
//
// Cluster_PHV::Cluster_PHV constructor
//
// input
//      cluster set of fields
// output
//      sorted cluster vector of fields, width decreasing
//      std::vector<const PhvInfo::Field *> cluster_vec_i
//
//***********************************************************************************

Cluster_PHV::Cluster_PHV(
    ordered_set<const PhvInfo::Field *> *p,
    const int id_n,
    std::string id_p)
    : cluster_vec_i(p->begin(), p->end()),
      id_num_i(id_n) {
    //
    if (!p) {
        LOG1("*****Cluster_PHV called w/ nullptr cluster_set******");
    }
    // set string id for cluster
    //
    std::stringstream ss;
    ss << id_n;
    id_i = id_p + ss.str();
    //
    // set gress for this cluster
    // ignore gress of temp vars ($tmp1, $tmp2, ....)
    // consider gress of field vars in cluster
    //
    gress_i = PHV_Container::Ingress_Egress::Ingress_Or_Egress;
    for (auto &f : cluster_vec_i) {
        if (strncmp(f->name, "$tmp", strlen("$tmp")) == 0) {
            continue;
        } else {
            if (gress_i == PHV_Container::Ingress_Egress::Ingress_Or_Egress) {
                gress_i = PHV_Container::gress(f);
            } else {
                assert(gress_i == PHV_Container::gress(f));
            }
        }
        // set cluster id in field
        const_cast<PhvInfo::Field *>(f)->cl(id_i);
    }
    //
    compute_requirements();
    //
}  // Cluster_PHV

void
Cluster_PHV::compute_requirements() {
    //
    uniform_width_i =
        std::adjacent_find(
            cluster_vec_i.begin(),
            cluster_vec_i.end(),
            [](const PhvInfo::Field *l, const PhvInfo::Field *r) {
                return l->phv_use_width() != r->phv_use_width(); })
        == cluster_vec_i.end();
    //
    //
    // although uniform width, width_req cannot use cluster_vec_i.front()->phv_use_width()
    // as fields may be ccgf with members phv_no_pack
    // e.g., <1:12>[4,8] = {2*8} better than {2*16}
    // compute_width_req() performs this analysis
    //
    auto width_req = compute_width_req();
    //
    // <8:_32_16_16_16_16_16_16_16> => {9*b16} vs {8*b32}
    // <8:_16_16_16_16_16_16_16_9>  => {8*b16}
    //
    size_t scale_down = 0;
    for (auto &pfield : cluster_vec_i) {
        if (pfield->deparser_no_pack) {
            // cannot scale-down egress_spec<9:0..15> into 8-bit containers
            scale_down = 0;
            break;
        }
        if (pfield->phv_use_width() * 2 <= container_width(width_req)) {
            scale_down++;
        }
    }
    if (scale_down * 2 >= cluster_vec_i.size()) {
        width_req = width_req / 2;
    }
    // container width
    width_i = container_width(width_req);
    // num containers of width
    num_containers_i = num_containers(cluster_vec_i, width_i);
    //
    // recompute requirements based on width_i for ccgf fields containing no_pack members
    // e.g.,
    // 2 constrained fields each require separate containers
    // if container width = 8b then 2*8b containers, total width required = 16b
    // if containers width is 16b then 2*16b containers, total width required = 32b
    //
    // count constrained fields, preference given during container placement
    //
    for (auto &f : cluster_vec_i) {
        const_cast<PhvInfo::Field *>(f)->phv_use_width(f->ccgf == f, width_i);
        if (PHV_Container::constraint_no_cohabit(f)) {
            num_fields_no_cohabit_i++;
        }
    }
    //
    // cluster vector = sorted decreasing field width
    //
    std::sort(cluster_vec_i.begin(),
              cluster_vec_i.end(),
              [](const PhvInfo::Field *l, const PhvInfo::Field *r) {
                  return l->phv_use_width() > r->phv_use_width(); });
    //
    // max width of field in cluster, computed after sorting cluster fields
    //
    max_width_i = compute_max_width();
    //
}  // compute requirements

int
Cluster_PHV::compute_max_width() {
    //
    int width = static_cast<int>(width_i);
    const PhvInfo::Field *field = cluster_vec_i.front();
    if (uniform_width_i) {
        if (cluster_vec_i.size() == 1 && field->ccgf == field) {
            int constrained_width = 0;
            for (auto &m : field->ccgf_fields) {
                if (PHV_Container::constraint_no_cohabit(m)) {
                    if (m->ccgf == m) {
                        constrained_width = std::max(constrained_width, width);
                    } else {
                        constrained_width = std::max(constrained_width, m->phv_use_width());
                    }
                }
            }   // for
            return constrained_width? constrained_width: field->phv_use_width();
        } else {
            return field->phv_use_width();
        }
    } else {
        return std::max(field->phv_use_width(), width);
    }
    return width_i;
}  // compute_max_width

//
// compute max width required by field
// field can be ccgf with member phv_no_pack
//
int
Cluster_PHV::compute_width_req() {
    int max_width = 0;
    for (auto &field : cluster_vec_i) {
        if (field->ccgf == field) {
            bool phv_no_pack = false;
            for (auto &m : field->ccgf_fields) {
                if (PHV_Container::constraint_no_cohabit(m)) {
                    phv_no_pack = true;
                    if (m->ccgf == m) {
                        max_width = std::max(max_width, m->size);
                    } else {
                        max_width = std::max(max_width, m->phv_use_width());
                    }
                }
            }
            if (!phv_no_pack) {
                max_width = std::max(max_width, field->phv_use_width());
            }
        } else {
            max_width = std::max(max_width, field->phv_use_width());
        }
    }
    return max_width;
}  // compute_width_req

//
// given width of field, return container width required
//
PHV_Container::PHV_Word
Cluster_PHV::container_width(int field_width) {
    //
    if (field_width > PHV_Container::PHV_Word::b16) {
        return PHV_Container::PHV_Word::b32;
    } else {
        if (field_width > PHV_Container::PHV_Word::b8) {
            return PHV_Container::PHV_Word::b16;
        }
    }
    return PHV_Container::PHV_Word::b8;
}

//
// Cluster_PHV::num_containers()
// input
//      cluster vector of fields*, container width
// output
//      num_containers based on field width
//

int
Cluster_PHV::num_containers(
    std::vector<const PhvInfo::Field *>& cluster_vec, PHV_Container::PHV_Word width) {
    //
    // num containers of width
    int num_containers = 0;
    for (auto &pfield : cluster_vec) {
        //
        // fields can span containers  (e.g., 48b = 2*32b or 3*16b = 6*8b)
        // no sharing of containers with cohabitant fields
        // sharing needs analyses:
        // (i)  container single-write table interference
        // (ii) surround interference
        //
        int field_width = pfield->phv_use_width();
        num_containers += field_width / width + (field_width % width? 1 : 0);
    }
    if (num_containers > PHV_Container::Containers::MAX) {
        LOG1(
            "*****Cluster_PHV::get_num_containers: "
            << "cluster "
            << this->id()
            << " requires num_containers = "
            << num_containers
            << " > "
            << PHV_Container::Containers::MAX
            << " of width "
            << width
            << " ******");
    }
    return num_containers;
}

//***********************************************************************************
//
// output stream <<
//
//***********************************************************************************
//
// cluster_phv output
//
std::ostream &operator<<(std::ostream &out, Cluster_PHV &cp) {
    //
    // cluster summary
    //
    out << "<" << cp.cluster_vec().size() << ':';
    if (cp.uniform_width() == true) {
        out << cp.max_width();
    } else {
        for (auto f : cp.cluster_vec()) {
            out << '_' << f->phv_use_width();
        }
    }
    out << '>';
    out << '{'
        << cp.num_containers()
        << '*'
        << cp.width()
        << '}';
    if (cp.max_width() != cp.width()) {
        out << '['
            << cp.needed_bits()
            << ']';
    }
    out << static_cast<char>(cp.gress());
    return out;
}

std::ostream &operator<<(std::ostream &out, Cluster_PHV *cp) {
    //
    // cluster details
    //
    if (cp) {
        // cluster summary
        out << *cp;
        // fields in cluster
        out << "( "
            << cp->id()
            << std::endl
            << cp->cluster_vec()
            << ')'
            << std::endl;
    } else {
        out << "-cp-";
    }
    return out;
}

std::ostream &operator<<(std::ostream &out, std::list<Cluster_PHV *> &cluster_list) {
    for (auto c : cluster_list) {
        // cluster summary
        out << c << std::endl;
    }
    return out;
}

std::ostream &operator<<(std::ostream &out, std::vector<Cluster_PHV *> *cluster_vec) {
    out << '[';
    if (cluster_vec) {
        out << std::endl;
        for (auto cl : *cluster_vec) {
           // cluster summary
           out << *cl << std::endl;
        }
    } else {
        out << "-clv-";
    }
    out << ']' << std::endl;
    return out;
}

std::ostream &operator<<(std::ostream &out, std::vector<Cluster_PHV *> &cluster_phv_vec) {
    out << ".....{"
        << cluster_phv_vec.front()->num_containers()
        << ','
        << cluster_phv_vec.front()->width()
        << "}#"
        << cluster_phv_vec.size()
        << " ....."
        << std::endl;
    for (auto cp : cluster_phv_vec) {
        // cluster details
        out << cp;
    }
    return out;
}

// ordered_map
std::ostream &operator<<(
    std::ostream &out,
    ordered_map<int, std::vector<Cluster_PHV *>>& phv_req_map) {
    //
    for (auto rit = phv_req_map.rbegin(); rit != phv_req_map.rend(); ++rit) {
        // print key <number> of phv_req_map
        out << '[' << rit->first << "]*" << rit->second.size() << "   \t= ";
        // summarize clusters
        for (auto &cp : rit->second) {
            // cluster summary
            out << *cp << ' ';
        }
        out << std::endl;
    }
    return out;
}

std::ostream &operator<<(std::ostream &out,
    ordered_map<PHV_Container::PHV_Word, ordered_map<int, std::vector<Cluster_PHV *>>>& print_map) {
    //
    for (auto rit = print_map.rbegin();
        rit != print_map.rend();
        ++rit) {
        //
        int num_clusters = 0;
        for (auto &it_2 : rit->second) {
            num_clusters += it_2.second.size();
        }
        out << "[----------"
            << rit->first
            << "---------#"
            << num_clusters
            << ']'
            << std::endl;
        for (auto rit_2 = rit->second.rbegin(); rit_2 != rit->second.rend(); ++rit_2) {
            out << rit_2->second;
        }
    }
    out << std::endl
        << ".......... Container Requirements .........."
        << std::endl
        << std::endl;
    for (auto rit = print_map.rbegin();
        rit != print_map.rend();
        ++rit) {
        out << "[----------" << rit->first << "----------]" << std::endl;
        out << rit->second;
    }
    out << std::endl;
    return out;
}

std::ostream &operator<<(std::ostream &out, Cluster_PHV_Requirements &phv_requirements) {
    out << std::endl
        << "++++++++++++++++++++ Begin Cluster PHV Requirements ++++++++++++++++++++"
        << std::endl
        << std::endl;
    //
    ordered_map<PHV_Container::PHV_Word,
         ordered_map<int, std::vector<Cluster_PHV *>>> print_map;
    print_map.clear();
    for (auto &cl : phv_requirements.cluster_phv_fields()) {
        print_map[cl->width()][cl->num_containers()].push_back(cl);
    }
    out << "..........PHV Requirements.........."
        << std::endl;
    out << print_map;
    //
    print_map.clear();
    for (auto &cl : phv_requirements.t_phv_fields()) {
        print_map[cl->width()][cl->num_containers()].push_back(cl);
    }
    out << "..........T_PHV Requirements.........."
        << std::endl;
    out << print_map;
    out << std::endl
        << "++++++++++++++++++++ End Cluster PHV Requirements ++++++++++++++++++++"
        << std::endl
        << std::endl;
    //
    return out;
}
