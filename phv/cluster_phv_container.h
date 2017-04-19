#ifndef _TOFINO_PHV_CLUSTER_PHV_CONTAINER_H_
#define _TOFINO_PHV_CLUSTER_PHV_CONTAINER_H_

#include "phv.h"
#include "phv_fields.h"
#include "ir/ir.h"
#include "lib/map.h"
#include "lib/ordered_map.h"
#include "lib/range.h"
#include "tofino/ir/thread_visitor.h"
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
    enum PHV_Word {b32 = 32, b16 = 16, b8 = 8};
    enum Containers {MAX = 16};
    enum Container_status {EMPTY = 'V', PARTIAL = 'P', FULL = 'F'};  // V = Vacant, E = Egress_Only
    enum Ingress_Egress {Ingress_Only = 'I', Egress_Only = 'E', Ingress_Or_Egress = ' '};
    //
    class Container_Content {
     public:
        enum Overlay_Pass {None = '=', Field_Interference = '~', Cluster_Overlay = '%'};

     private:
        const PHV_Container *container_i;  // parent container
        int lo_i;                          // low of bit range in container for field
        int hi_i;                          // high of bit range in container for field
        const PhvInfo::Field *field_i;
        const int field_bit_lo_i;          // start of field bit in this container
        std::string taint_color_i = "?";   // taint color of this field in container
        bool overlayed_field_i = false;    // true if field overlays another field in container
        Overlay_Pass pass_i = None;        // tracks pass that performs overlay

     public:
        //
        Container_Content(
            const PHV_Container *c,
            const int l,
            const int h,
            const PhvInfo::Field *f,
            const int field_bit_lo = 0,
            const std::string taint_color = "?",
            bool overlayed = false,
            Overlay_Pass = None);
        //
        int lo() const                   { return lo_i; }
        void lo(int l)                   { lo_i = l; }
        int hi() const                   { return hi_i; }
        void hi(int h)                   { hi_i = h; }
        int width() const                { return hi_i - lo_i + 1; }
        const PhvInfo::Field *field()    { return field_i; }
        int field_bit_lo() const         { return field_bit_lo_i; }
        int field_bit_hi() const         { return field_bit_lo_i + width() - 1; }
        const PHV_Container *container() { return container_i; }
        void container(PHV_Container *c) { container_i = c; }   // during transfer parser container
        std::string& taint_color()       { return taint_color_i; }
        bool overlayed()                 { return overlayed_field_i; }
        Overlay_Pass pass()              { return pass_i; }
        //
        void sanity_check_container(PHV_Container *, const std::string&);
    };
    //
 private:
    PHV_MAU_Group *phv_mau_group_i;                          // parent PHV MAU Group
    PHV_Word width_i;                                        // width of container
    int phv_number_i;                                        // PHV_number 0..223
                                                             // 32b:   0..63
                                                             //  8b:  64..127
                                                             // 16b: 128..223
    std::string asm_string_i;                                // assembler syntax for this container
                                                             // PHV-0   ..  63 =  W0 .. 63
                                                             // PHV-64  .. 127 =  B0 .. 63
                                                             // PHV-128 .. 223 =  H0 .. 95
                                                             // PHV-256 .. 287 = TW0 .. 31
                                                             // PHV-288 .. 319 = TB0 .. 31
                                                             // PHV-320 .. 367 = TH0 .. 47
    Ingress_Egress gress_i;                                  // Ingress_Only,
                                                             // Egress_Only,
                                                             // Ingress_Or_Egress
    Container_status status_i = Container_status::EMPTY;
    ordered_map<const PhvInfo::Field *, Container_Content *>
        fields_in_container_i;                               // fields binned in this container
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
        PHV_Word w,
        int phv_number,
        std::string asm_string,
        Ingress_Egress gress);
    //
    PHV_MAU_Group *phv_mau_group()                              { return phv_mau_group_i; }
    PHV_Word width()                                            { return width_i; }
    int phv_number()                                            { return phv_number_i; }
    std::string phv_number_string() {
        std::stringstream ss;
        ss << phv_number_i;
        return "PHV-" + ss.str();
    }
    std::string& asm_string()                                   { return asm_string_i; }
    void
    gress(Ingress_Egress gress_p) {  // set when MAU group's gress is set
        gress_i = gress_p;
    }
    Ingress_Egress gress()                                      { return gress_i; }
    static Ingress_Egress gress(const PhvInfo::Field *field) {
        if (const_cast<const PhvInfo::Field *>(field)->gress == INGRESS) {
            return PHV_Container::Ingress_Egress::Ingress_Only;
        } else {
            if (const_cast<const PhvInfo::Field *>(field)->gress == EGRESS) {
                return PHV_Container::Ingress_Egress::Egress_Only;
            }
        }
        return PHV_Container::Ingress_Egress::Ingress_Or_Egress;
    }
    Container_status status()                                   { return status_i; }
    char *bits()                                                { return bits_i; }
    char taint_color(int bit) {
        // taint color for bit in container
        assert(bit >= 0 && bit < width_i);
        return bits_i[bit];
    }
    std::string taint_color(int lo, int hi, bool overlayed = true) {
        // taint color for range of bits lo .. hi in container
        assert(lo >= 0 && lo < width_i);
        assert(hi >= 0 && hi < width_i);
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
        const PhvInfo::Field *field,
        int range_start = 0,
        int field_bit_lo = 0);
    int taint_ccgf(
        int start,
        int width,
        const PhvInfo::Field *field,
        int field_bit_lo);
    void update_ccgf(
        PhvInfo::Field *f,
        int processed_members,
        int processed_width);
    void overlay_ccgf_field(
        PhvInfo::Field *field,
        int start,
        int width,
        Container_Content::Overlay_Pass pass = Container_Content::Overlay_Pass::Field_Interference);
    void single_field_overlay(
        PhvInfo::Field *f,
        int start,
        int width,
        const int field_bit_lo,
        Container_Content::Overlay_Pass pass = Container_Content::Overlay_Pass::Field_Interference);
    void field_overlays(
        PhvInfo::Field *field,
        int start,
        int width,
        const int field_bit_lo);
    void field_overlays();
    ordered_map<std::string, std::pair<int, int>>* lowest_bit_and_ccgf_width();
    void taint_bits(
        int start,
        int width,
        const PhvInfo::Field *field,
        int field_bit_lo);
    int avail_bits()                                            { return avail_bits_i; }
    ordered_map<int, int>& ranges()                             { return ranges_i; }
    ordered_map<const PhvInfo::Field *, Container_Content *>& fields_in_container() {
        return fields_in_container_i;
    }
    void fields_in_container(const PhvInfo::Field *f, Container_Content *cc) {
        assert(f);
        assert(cc);
        assert(!fields_in_container_i.count(f));
        //
        fields_in_container_i[f] = cc;
    }
    void fields_in_container(int start, int end, ordered_set<const PhvInfo::Field *>& f_set) {
        //
        // fields that overlap start .. end in container
        // Sub     |xxxxxx|
        // Ovl  xxx|x     |
        // Ovl     | xxxx |
        // Ovl   xx|xxxxxx|xx
        // Ovl     |     x|xxx
        //
        for (auto &cc : Values(fields_in_container_i)) {
            if ((cc->lo() < start && cc->hi() >= start)
                || (cc->lo() >= start && cc->lo() <= end)) {
                //
                f_set.insert(cc->field());
            }
        }  // for
    }
    std::pair<int, int>
        start_bit_and_width(const PhvInfo::Field *f) {
        //
        assert(f);
        assert(fields_in_container_i.count(f));
        //
        Container_Content *cc = fields_in_container_i[f];
        return std::make_pair(cc->lo(), cc->width());
    }
    void create_ranges();
    void clear();
    void clean_ranges();
    //
    static bool constraint_no_cohabit(const PhvInfo::Field *field) {
        return field->deparser_no_pack || field->mau_phv_no_pack;
    }
    static bool constraint_no_holes(const PhvInfo::Field *field) {
        return field->deparser_no_holes;
    }
    static bool constraint_no_cohabit_exclusive_mau(const PhvInfo::Field *field) {
        return field->mau_phv_no_pack && !field->deparser_no_pack;
    }
    static int ceil_phv_use_width(PhvInfo::Field* f, int min_ceil = 0) {
        assert(f);
        //
        if (f->size <= PHV_Word::b8 && PHV_Word::b8 >= min_ceil) {
            return PHV_Word::b8;
        } else {
            if (f->size <= PHV_Word::b16 && PHV_Word::b16 >= min_ceil) {
                return PHV_Word::b16;
            } else {
                if (f->size <= PHV_Word::b32 && PHV_Word::b32 >= min_ceil) {
                    return PHV_Word::b32;
                }
            }
        }
        return std::max(f->size, min_ceil);
    }
    //
    void sanity_check_container(const std::string& msg);
    void sanity_check_overlayed_fields(const std::string& msg);
    void sanity_check_container_avail(int lo, int hi, const std::string&);
    void sanity_check_container_ranges(const std::string&, int lo = -1, int hi = -1);
    //
};  // class PHV_Container
//
//
std::ostream &operator<<(std::ostream &, PHV_Container::Container_Content *);
std::ostream &operator<<(std::ostream &, std::vector<PHV_Container::Container_Content *>&);
std::ostream &operator<<(std::ostream &, ordered_set<PHV_Container::Container_Content *>&);
std::ostream &operator<<(std::ostream &, ordered_map<int, int>&);
std::ostream &operator<<(std::ostream &, const PHV_Container*);
std::ostream &operator<<(std::ostream &, PHV_Container*);
std::ostream &operator<<(std::ostream &, PHV_Container&);
std::ostream &operator<<(std::ostream &, std::vector<PHV_Container *>&);
std::ostream &operator<<(std::ostream &, std::list<PHV_Container *>&);
std::ostream &operator<<(
    std::ostream &,
    ordered_map<const PhvInfo::Field *, PHV_Container::Container_Content *>&);
//
#endif /* _TOFINO_PHV_CLUSTER_PHV_CONTAINER_H_ */
