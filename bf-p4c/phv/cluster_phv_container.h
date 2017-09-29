#ifndef BF_P4C_PHV_CLUSTER_PHV_CONTAINER_H_
#define BF_P4C_PHV_CLUSTER_PHV_CONTAINER_H_

#include <limits>
#include "phv.h"
#include "phv_fields.h"
#include "ir/ir.h"
#include "lib/map.h"
#include "lib/ordered_map.h"
#include "lib/range.h"
#include "bf-p4c/ir/thread_visitor.h"
//
//
//***********************************************************************************
//
// class PHV_Container represents the state of a PHV container word
// after PHV Assignment, Fields are mapped to PHV_Containers
//
//***********************************************************************************
//
//
class PHV_MAU_Group;
//
//
class PHV_Container {
 public:
    enum Container_status {EMPTY = 'V', PARTIAL = 'P', FULL = 'F'};  // V = Vacant, E = Egress_Only
    enum Ingress_Egress {Ingress_Only = 'I', Egress_Only = 'E', Ingress_Or_Egress = ' '};

    /** Marks the contents of a PHV container. */
    class Container_Content {
     public:
        enum Pass {
            None = '=',
            Header_Stack_Pov_Ccgf = '^',
            Aggregate = '@',
            Field_Interference = '~',
            Cluster_Overlay = '%',
            Cluster_Slicing = '|',
            Phv_Bind = '$'};

     private:
        const PHV_Container *container_i;  // parent container
        int lo_i;                          // low of bit range in container for field
        int hi_i;                          // high of bit range in container for field
        PhvInfo::Field *field_i;
        const int field_bit_lo_i;          // start of field bit in this container
        std::string taint_color_i = "?";   // taint color of this field in container
        Pass pass_i = None;                // tracks pass that creates this cc: overlay, slicing

     public:
        Container_Content(
            const PHV_Container *c,
            const int l,
            const int h,
            PhvInfo::Field *f,
            const int field_bit_lo = 0,
            const std::string taint_color = "?",
            Pass = None);
        //
        int lo() const                   { return lo_i; }
        void lo(int l)                   { lo_i = l; }
        int hi() const                   { return hi_i; }
        void hi(int h)                   { hi_i = h; }
        int width() const                { return hi_i - lo_i + 1; }
        PhvInfo::Field *field()          { return field_i; }
        int field_bit_lo() const         { return field_bit_lo_i; }
        int field_bit_hi() const         { return field_bit_lo_i + width() - 1; }
        const PHV_Container *container() { return container_i; }
        void container(PHV_Container *c) { container_i = c; }   // during transfer parser container
        std::string& taint_color()       { return taint_color_i; }
        Pass pass()                      { return pass_i; }
        void pass(Pass pass)             { pass_i = pass; }
        bool overlayed()                 { return pass_i == Cluster_Overlay
                                               || pass_i == Field_Interference; }
        bool header_stack_overlayed()    { return pass_i == Header_Stack_Pov_Ccgf; }
        bool sliced()                    { return field_i->sliced(); }
        bool phv_bind()                  { return pass_i == Phv_Bind; }
        //
        void sanity_check_container(PHV_Container *, const std::string&);
    };
    //
 private:
    /* how phv_mau_group_i is used:
     * cluster_phv_container.cpp:
     * - gress
     * - inc_empty_containers() when container is cleared
     * - dec_empty_containers() when container is used
     * cluster_phv_mau.cpp:
     * - to determine which containers are in the same group (i.e. group by container group)
     * cluster_phv_overlay.cpp:
     * - an indirect way to get a list of tphv groups to overlay
     */
    PHV_MAU_Group *phv_mau_group_i;                          // parent PHV MAU Group
    PHV::Size width_i;                                       // width of container
    unsigned container_id_i;                                 // phv container id
                                                             // see phv.h for details
    Ingress_Egress gress_i;                                  // Ingress_Only,
                                                             // Egress_Only,
                                                             // Ingress_Or_Egress
    Container_status status_i = Container_status::EMPTY;
    ordered_map<PhvInfo::Field *, std::list<Container_Content *>>
        fields_in_container_i;                               // fields binned in this container
                                                             // list of ccs necessary for multiple
                                                             // sliced fields in same container
    bool deparsed_i = false;                                 // true if container is deparsed
                                                             // has deparsed field(s)
    //
    char *bits_i;                                            // tainted bits in container
    std::string taint_color_i = "0";                         // each resident field separate color
                                                             // highest number=#fields in container
    int avail_bits_i = 0;                                    // available bits in container
    ordered_map<int, int> ranges_i;                          // available ranges in this container
    //
 public:
    PHV_Container(
        PHV_MAU_Group *g,
        PHV::Size w,
        unsigned phv_number,
        Ingress_Egress gress);
    //
    PHV_MAU_Group *phv_mau_group()                              { return phv_mau_group_i; }
    PHV::Size width() const                                     { return width_i; }

    /// @return true if width is exactly a (nonzero) container size, as defined in phv.h.
    static bool exact_container(int width) {
        return width == int(PHV::Size::b32)
            || width == int(PHV::Size::b16)
            || width == int(PHV::Size::b8);
    }

    unsigned phv_number() const                                      { return container_id_i; }
    std::string phv_number_string() const {
        std::stringstream ss;
        ss << container_id_i;
        return "PHV-" + ss.str();
    }
    void
    gress(Ingress_Egress gress_p) {  // set when MAU group's gress is set
        gress_i = gress_p;
    }
    Ingress_Egress gress()                                      { return gress_i; }
    static Ingress_Egress gress(PhvInfo::Field *field) {
        if (field->gress == INGRESS) {
            return PHV_Container::Ingress_Egress::Ingress_Only;
        } else {
            if (field->gress == EGRESS) {
                return PHV_Container::Ingress_Egress::Egress_Only;
            }
        }
        return PHV_Container::Ingress_Egress::Ingress_Or_Egress;
    }
    Container_status status()                                   { return status_i; }
    char *bits() const                                          { return bits_i; }
    char taint_color(int bit) {
        // taint color for bit in container
        BUG_CHECK(bit >= 0 && bit < int(width_i), "Bad range");
        return bits_i[bit];
    }
    std::string taint_color(int lo, int hi, bool overlayed = true) {
        // taint color for range of bits lo .. hi in container
        BUG_CHECK(lo >= 0 && lo < int(width_i), "Bad range");
        BUG_CHECK(hi >= 0 && hi < int(width_i), "Bad range");
        if (taint_color(lo) == taint_color(hi)) {
            return std::string(1, taint_color(lo));
        } else {
            // for substratum fields range must be same
            assert(overlayed);
            // for overlayed fields range can differ
            // concatenate start taint, end taint for overlayed, straddling ccgf member
            return std::string(1, taint_color(lo)) + std::string(1, taint_color(hi));
        }
    }
    int taint(
        int start,
        int width,
        PhvInfo::Field *field,
        int field_bit_lo = 0,
        Container_Content::Pass pass = Container_Content::Pass::None,
        bool process_ccgf = true);
    int taint_ccgf(
        int start,
        int width,
        PhvInfo::Field *field,
        int field_bit_lo,
        Container_Content::Pass pass = Container_Content::Pass::None);
    void update_ccgf(
        PhvInfo::Field *f,
        int processed_members,
        int processed_width);
    void overlay_ccgf_field(
        PhvInfo::Field *field,
        int start,
        const int width,
        int field_bit_lo,
        Container_Content::Pass pass = Container_Content::Pass::Field_Interference);
    void single_field_overlay(
        PhvInfo::Field *f,
        const int start,
        int width,
        const int field_bit_lo,
        Container_Content::Pass pass = Container_Content::Pass::Field_Interference);
    void field_overlays(
        PhvInfo::Field *field,
        int start,
        int width,
        const int field_bit_lo);
    void field_overlays();
    ordered_map<int, std::pair<int, int>>*
        lowest_bit_and_ccgf_width(bool by_cluster_id = true);
    Container_Content*
        taint_bits(
            int start,
            int width,
            PhvInfo::Field *field,
            int field_bit_lo,
            Container_Content::Pass pass = Container_Content::Pass::None);
    int avail_bits()                                            { return avail_bits_i; }
    ordered_map<int, int>& ranges()                             { return ranges_i; }
    const ordered_map<PhvInfo::Field *,
              std::list<Container_Content *>>& fields_in_container() const {
        return fields_in_container_i;
    }
    ordered_map<PhvInfo::Field *,
        std::list<Container_Content *>>& fields_in_container() { return fields_in_container_i; }
    void fields_in_container(std::list<Container_Content *>& cc_list);
    void fields_in_container(PhvInfo::Field *f, Container_Content *cc);
    void fields_in_container(int start, int end, ordered_set<PhvInfo::Field *>& f_set);

    std::pair<int, int> start_bit_and_width(PhvInfo::Field *f);
    static void holes(
        std::vector<char>& bits,
        char empty,
        std::list<std::pair<int, int>>& holes_list);
    void holes(std::list<std::pair<int, int>>& holes_list) const;

    bool deparsed() const                                       { return deparsed_i; }
    void set_deparsed(bool b)                                   { deparsed_i = b; }
    //
    void create_ranges();
    void clear();
    void clean_ranges();
    //
    static bool constraint_no_holes(PhvInfo::Field *field) {
        return field->deparsed();
    }
    static bool constraint_no_cohabit(PhvInfo::Field *field) {
        return field->deparsed_no_pack() || field->mau_phv_no_pack();
    }
    static bool constraint_no_cohabit_exclusive_mau(PhvInfo::Field *field) {
        return field->mau_phv_no_pack() && !field->deparsed_no_pack();
    }
    static bool constraint_bottom_bits(PhvInfo::Field *field) {
        return field->deparsed_bottom_bits();
    }
    static int ceil_phv_use_width(PhvInfo::Field* f, int min_ceil = 0) {
        BUG_CHECK(f, "NULL field");
        if (f->size <= int(PHV::Size::b8) && int(PHV::Size::b8) >= min_ceil) {
            return int(PHV::Size::b8);
        } else if (f->size <= int(PHV::Size::b16) && int(PHV::Size::b16) >= min_ceil) {
            return int(PHV::Size::b16);
        } else if (f->size <= int(PHV::Size::b32) && int(PHV::Size::b32) >= min_ceil) {
            return int(PHV::Size::b32);
        }
        return std::max(f->size, min_ceil);
    }
    //
    bool sanity_check_deparsed_container_violation(
        const PhvInfo::Field *&deparsed_header,
        const PhvInfo::Field *&non_deparsed_field) const;
    void sanity_check_container(const std::string& msg, bool check_deparsed = true);
    void sanity_check_overlayed_fields(const std::string& msg);
    void sanity_check_container_avail(int lo, int hi, const std::string&);
    void sanity_check_container_ranges(const std::string&, int lo = -1, int hi = -1);
    //
};  // class PHV_Container
//
//
std::ostream &operator<<(std::ostream &, PHV_Container::Container_Content *);
std::ostream &operator<<(std::ostream &, std::list<PHV_Container::Container_Content *>&);
std::ostream &operator<<(std::ostream &, std::vector<PHV_Container::Container_Content *>&);
std::ostream &operator<<(std::ostream &, ordered_set<PHV_Container::Container_Content *>&);
std::ostream &operator<<(std::ostream &, ordered_map<int, int>&);
std::ostream &operator<<(std::ostream &, PHV_Container*);
std::ostream &operator<<(std::ostream &, const PHV_Container*);
std::ostream &operator<<(std::ostream &, PHV_Container&);
std::ostream &operator<<(std::ostream &, ordered_set<PHV_Container *>&);
std::ostream &operator<<(std::ostream &, ordered_set<PHV_Container *>*);
std::ostream &operator<<(std::ostream &, std::vector<PHV_Container *>&);
std::ostream &operator<<(std::ostream &, std::list<PHV_Container *>&);
std::ostream &operator<<(
    std::ostream &,
    ordered_map<PhvInfo::Field *, std::list<PHV_Container::Container_Content *>>&);
//
#endif /* BF_P4C_PHV_CLUSTER_PHV_CONTAINER_H_ */
