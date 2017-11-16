#include "bf-p4c/phv/cluster_phv_req.h"
#include "bf-p4c/phv/cluster_phv_mau.h"
#include "bf-p4c/phv/phv_fields.h"
#include "lib/log.h"
#include "lib/stringref.h"

static int cluster_id_g = 0;                // global counter for assigning cluster ids

//***********************************************************************************
//
// Cluster_PHV_Requirements::apply_visitor()
//
// input:
//      clusters: cluster.dst_map()
// output:
//      creates sorted PHV container requirements for clusters
//      map<PHV::Size, map<int, std::vector<Cluster_PHV *>>> Cluster_PHV_i;
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
    for (auto &set_of_fields : Values(cluster_i.dst_map())) {
        Cluster_PHV *m = new Cluster_PHV(set_of_fields, "phv");
        Cluster_PHV_i.push_back(m);
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
                            return true;
                        }
                        if (l->uniform_width() == false && r->uniform_width() == true) {
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
    for (auto &p : cluster_i.pov_fields_not_in_cluster()) {
        pov_fields_i.push_back(new Cluster_PHV(p, "pov"));
    }
    std::sort(pov_fields_i.begin(), pov_fields_i.end(),
        [](Cluster_PHV *l, Cluster_PHV *r) {
            PHV::Field *fl =  *(l->cluster_vec().begin());
            PHV::Field *fr =  *(r->cluster_vec().begin());
            int l_range = fl->phv_use_hi() - fl->phv_use_lo();
            int r_range = fr->phv_use_hi() - fr->phv_use_lo();
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
    for (auto &p : cluster_i.fields_no_use_mau())
        t_phv_fields_i.push_back(new Cluster_PHV(p, "t_phv"));

    std::sort(t_phv_fields_i.begin(), t_phv_fields_i.end(),
        [](Cluster_PHV *l, Cluster_PHV *r) {
            PHV::Field *fl =  *(l->cluster_vec().begin());
            PHV::Field *fr =  *(r->cluster_vec().begin());
            int l_range = fl->phv_use_hi() - fl->phv_use_lo();
            int r_range = fr->phv_use_hi() - fr->phv_use_lo();
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

    LOG3(*this);
    return node;
}

std::pair<int, int> Cluster_PHV_Requirements::gress(std::list<Cluster_PHV *>& cluster_list) {
    std::pair<int, int> gress_pair = {0, 0};
    for (auto &cl : cluster_list) {
        switch (cl->gress()) {
          case INGRESS:
            gress_pair.first++;
            break;
          case EGRESS:
            gress_pair.second++;
            break; } }

    return gress_pair;
}

//***********************************************************************************
//
// Cluster_PHV::Cluster_PHV constructor
//
// input
//      (i) cluster -- sliced cluster
//      (ii) set of fields -- non-sliced cluster
// output
//      sorted cluster vector of fields, width decreasing
//      std::vector<const PHV::Field *> cluster_vec_i
//
//***********************************************************************************


// Cluster Slicing interface
Cluster_PHV::Cluster_PHV(Cluster_PHV *cl, bool lo)
      : id_num_i(cluster_id_g) {
    assert(cl);
    cluster_vec_i = cl->cluster_vec();
    // sliced cluster keeps string id issued by caller = non-sliced cl id + _lo, _hi
    const char *suffix = lo? "_lo": "_hi";
    id_i = cl->id() + suffix;
    sliced_i = true;
    uniform_width_i = cl->uniform_width();
    assert(uniform_width_i == true);
    gress_i = cl->gress();
    //
    insert_field_clusters(cl, lo);
    //
}

// cluster singleton field
Cluster_PHV::Cluster_PHV(PHV::Field *f, std::string id_s /* = "???" */)
    : Cluster_PHV(field_set(f), id_s) {}

// non-sliced cluster
Cluster_PHV::Cluster_PHV(
    ordered_set<PHV::Field *> *p,
    std::string id_s)
    : cluster_vec_i(p->begin(), p->end()), id_num_i(cluster_id_g), id_i(id_s) {
    //
    if (!p) {
        LOG1("*****Cluster_PHV called w/ nullptr cluster_set******");
    }
    id_num_i = cluster_id_g++;
    //
    // set string id for non-sliced cluster
    //
    std::stringstream ss;
    ss << id_num_i;
    id_i = id_s + "_" + ss.str();
    //
    set_gress();
    //
    num_overlays_i = compute_num_overlays();
    //
    insert_field_clusters();
    //
    set_exact_containers();
    //
    compute_requirements();
    //
}  // Cluster_PHV

int Cluster_PHV::compute_num_overlays() {
    int num_overlays = 0;
    for (auto* field : cluster_vec_i)
        for (auto set_of_f : Values(field->field_overlay_map()))
            num_overlays += set_of_f->size();
    return num_overlays;
}

void
Cluster_PHV::set_exact_containers() {
    for (auto* field : cluster_vec_i) {
        // Deparsed header fields need exact containers as they go out on the
        // wire. Metadata does not go on the wire so exactness can normally be
        // relaxed; however, the correctness of the egress parser for bridged
        // metadata requires that some compiler-generated fields be placed in a
        // container of a specific size, so we'll still obey the
        // `exact_containers` constraint if it was explicitly applied to the
        // field. (`$bridged_metadata_indicator` is an example of such a case.)
        if (field->deparsed()
            && (!field->metadata || field->exact_containers())
            && (field->phv_use_width() % int(PHV::Size::b8) == 0)) {
                                                                   // ok 24,40,48,56b, not <b8,9,23b
            // e.g., cannot map W47 as
            //     icmp.hdrChecksum<16:0..15>: W47(0..15), ipv4.hdrChecksum<16:0..15>: W47(16..31)
            // the parser can only extract whole containers, so extract to W47 => extract 4 bytes
            // these vars need to be in either 8-bit or 16-bit containers
            //     ipv4.hdrChecksum<16:0..15>: --> H227
            //     icmp.hdrChecksum<16:0..15>: --> TH228
            //
            // similarly, 48b field participating in MAU operations + deparsed cannot be in 32b
            // in principle, if "move based" operations only, slice 48b to 32b, 16b
            //
            // set clusters exact_containers so that
            //     cluster_phv_mau::container_pack_cohabit() honors exact width match
            //     can happen when packing attempted on field before placement attempt
            //     e.g., when PHV <== TPHV_Overflow
            //
            const int align_start = field->phv_alignment().get_value_or(0);
            if (align_start == 0) {
                exact_containers_i = true;
                field->set_exact_containers(true);
            }
        }
    }
}  // set_exact_containers

void Cluster_PHV::set_gress() {
    //
    // set gress for this cluster
    //
    boost::optional<gress_t> gress_check = boost::none;
    for (auto *f : cluster_vec_i) {
        gress_i = f->gress;
        if (!gress_check)
            gress_check = f->gress;
        BUG_CHECK(
            *gress_check == f->gress,
            "*****Cluster_PHV::set_gress()*****%s gress = %c, field = %d:%s, gress = %c",
            id_i, gress_check, f->id, f->name, f->gress); }
}

void Cluster_PHV::insert_field_clusters(Cluster_PHV *parent_cl, bool slice_lo) {
    //
    for (auto &f : cluster_vec_i) {
        // update field's list of clusters, keep child, remove parent_cl
        // sliced cluster
        if (sliced_i) {
            Cluster_PHV *remove_parent_cl = nullptr;
            assert(parent_cl);
            int lo = 0, hi = 0;
            if (parent_cl->sliced()) {
                // if cluster has been sliced before, use _lo and _hi from slices
                lo = f->phv_use_lo(parent_cl);
                if (slice_lo) {
                    hi = lo + parent_cl->max_width() / 2 - 1;
                } else {
                    lo += parent_cl->max_width() / 2;
                    hi = f->phv_use_hi(parent_cl);
                    // now that both slices have been formed, first lo then hi, remove parent
                    remove_parent_cl = parent_cl;
                }
            } else {
                // use _lo and _hi from original field
                lo = f->phv_use_lo();
                if (slice_lo) {
                    hi = lo + f->size / 2 - 1;
                } else {
                    lo += f->size / 2;
                    hi = f->phv_use_hi();
                    // now that both slices have been formed, first lo then hi, remove parent
                    remove_parent_cl = parent_cl;
                }
            }
            f->set_field_slices(this, lo, hi, remove_parent_cl);
            // width of field slice in this cluster
            if (max_width_i) {
                assert(max_width_i == hi - lo + 1);
            } else {
                max_width_i = hi - lo + 1;
                // container width
                width_i = container_width(max_width_i);
            }
            // number of containers
            num_containers_i +=
                max_width_i / int(width_i) + (max_width_i % int(width_i) ? 1 : 0);
        } else {
            f->set_field_slices(this, f->phv_use_lo(), f->phv_use_hi());
        }
    }  // for
}  // insert_field_clusters

void
Cluster_PHV::compute_requirements() {
    //
    uniform_width_i =
        std::adjacent_find(
            cluster_vec_i.begin(),
            cluster_vec_i.end(),
            [](PHV::Field *l, PHV::Field *r) {
                return l->phv_use_width() != r->phv_use_width(); })
        == cluster_vec_i.end();
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
        if (pfield->deparsed_no_pack()) {
            // cannot scale-down egress_spec<9:0..15> into 8-bit containers
            scale_down = 0;
            break;
        }
        auto start_with_alignment = pfield->phv_alignment();
        if (start_with_alignment) {
            if (*start_with_alignment + pfield->phv_use_width() == width_req) {
                // cannot scale down below minimum requirement
                scale_down = 0;
                break;
            }
        }
        if (pfield->phv_use_width() * 2 <= int(container_width(width_req))) {
            scale_down++;
        }
    }
    if (scale_down * 2 >= cluster_vec_i.size()) {
        width_req = width_req / 2;
    }
    // container width
    width_i = container_width(width_req);
    // num containers of width
    num_containers_i = num_containers(cluster_vec_i);
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
        if (f->is_ccgf()) {
            f->set_ccgf_phv_use_width(int(width_i));
        }
        if (PHV_Container::constraint_no_cohabit(f)
            || PHV_Container::constraint_bottom_bits(f)) {
            //
            num_constraints_i++;
        }
    }
    //
    // cluster vector = sorted decreasing field width
    //
    std::sort(cluster_vec_i.begin(),
              cluster_vec_i.end(),
              [](PHV::Field *l, PHV::Field *r) {
                  if (l->phv_use_width() == r->phv_use_width()) {
                      // sort by cluster id_num to prevent non-determinism
                      return l->id < r->id;
                  }
                  return l->phv_use_width() > r->phv_use_width(); });
    //
    // max width of field in cluster, computed after sorting cluster fields
    //
    max_width_i = compute_max_width();
}

int
Cluster_PHV::compute_max_width() {
    //
    int width = static_cast<int>(width_i);
    PHV::Field *field = cluster_vec_i.front();
    if (uniform_width_i) {
        if (cluster_vec_i.size() == 1 && field->is_ccgf()) {
            int constrained_width = 0;
            for (auto &m : field->ccgf_fields()) {
                if (PHV_Container::constraint_no_cohabit(m)) {
                    if (m->is_ccgf()) {
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
    return int(width_i);
}  // compute_max_width

//
// compute max width required by field
// field can be ccgf with member phv_no_pack
//
int
Cluster_PHV::compute_width_req() {
    int max_width = 0;
    for (auto &field : cluster_vec_i) {
        const int align_start = field->phv_alignment().get_value_or(0);
        if (field->is_ccgf()) {
            bool phv_no_pack = false;
            for (auto &m : field->ccgf_fields()) {
                if (PHV_Container::constraint_no_cohabit(m)) {
                    phv_no_pack = true;
                    if (m->is_ccgf()) {
                        max_width = std::max(max_width, m->size);
                    } else {
                        max_width = std::max(max_width, m->phv_use_width());
                    }
                }
            }
            if (!phv_no_pack) {
                max_width = std::max(max_width, field->phv_use_width() + align_start);
            }
        } else {
            max_width = std::max(max_width, field->phv_use_width() + align_start);
        }
    }
    return max_width;
}  // compute_width_req

//
// given width of field, return container width required
//
PHV::Size
Cluster_PHV::container_width(int field_width) {
    //
    if (exact_containers_i) {
        //
        // exact_containers estimate reduces stress on
        // PHV_MAU_Group_Assignments::container_no_pack() ..... downsize_mau_group()
        //
        if (field_width % int(PHV::Size::b32) == 0) {
            return PHV::Size::b32;
        }
        if (field_width % int(PHV::Size::b16) == 0) {
            return PHV::Size::b16;
        }
        if (field_width % int(PHV::Size::b8) == 0) {
            return PHV::Size::b8;
        }
        LOG3("*****Cluster_PHV::container_width() cannot satisfy exactness for field_width = "
            << field_width << "******");
        LOG3(this);
        // continue below for container width determination
    }
    if (field_width > int(PHV::Size::b16)) {
        return PHV::Size::b32;
    }
    if (field_width > int(PHV::Size::b8)) {
        return PHV::Size::b16;
    }
    return PHV::Size::b8;
}

// Cluster_PHV::num_containers()
// input
//      (1) field, width of container
//      (2) cluster vector of fields*, width of container
// output
//      num_containers

int Cluster_PHV::num_containers(PHV::Field *field) {
    // num containers of width for field
    return num_containers(field, width_i);
}

int Cluster_PHV::num_containers(PHV::Field *field, PHV::Size width) {
    // num containers of width for field
    int field_width = field->phv_use_width();
    return field_width / int(width) + (field_width % int(width) ? 1 : 0);
}

int Cluster_PHV::num_containers(std::vector<PHV::Field *>& cluster_vec) {
    return num_containers(cluster_vec, width_i);
}

int Cluster_PHV::num_containers(std::vector<PHV::Field *>& cluster_vec, PHV::Size width) {
    // num containers of width for cluster
    int num_c = 0;
    for (auto *field : cluster_vec)
        // fields can span containers  (e.g., 48b = 2*32b or 3*16b = 6*8b)
        // container cannot contain two fields from same cluster
        num_c += num_containers(field, width);

    if (num_c > PHV_MAU_Group_Assignments::Constants::phv_mau_group_size)
        LOG1("*****Cluster_PHV::get_num_containers: " << "cluster " << this->id()
            << " requires num_containers = " << num_c << " > "
            << PHV_MAU_Group_Assignments::Constants::phv_mau_group_size << " of width " << width
            << " ******");

    return num_c;
}


int
Cluster_PHV::req_containers_bottom_bits() {
    //
    // number of fields that have restrictions on bottom bits only, e.g., learning digest
    //
    int req = 0;
    for (auto &f : cluster_vec_i) {
        if (f->deparsed_bottom_bits()) {
            req++;
        }
    }
    return req;
}

int Cluster_PHV::get_field_placement_size(const PHV::Field *f) const {
    BUG_CHECK(!(sliced_i && f->is_ccgf()),
              "CCGF fields cannot be sliced, but CCGF field %1% appears in sliced cluster %2%",
              cstring::to_cstring(f), this);
    if (sliced_i) {
        auto hi_lo_pair = f->field_slices(this);
        return le_bitrange(FromTo(hi_lo_pair.first, hi_lo_pair.second)).size(); }
    if (f->is_ccgf()) {
        int aggregate_size = 0;
        for (auto member : f->ccgf_fields())
            aggregate_size += member->size;
        return aggregate_size; }
    return f->size;
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
    if (cp.max_width() != int(cp.width())) {
        out << '['
            << cp.needed_bits()
            << ']';
    }
    out << cp.gress();
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
    ordered_map<PHV::Size, ordered_map<int, std::vector<Cluster_PHV *>>>& print_map) {
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
    ordered_map<PHV::Size,
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
