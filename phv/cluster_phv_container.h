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
    enum Container_status {EMPTY = 'V', PARTIAL = 'P', FULL = 'F'};
                                                              // V = Vacant, E = Egress_Only
    enum Ingress_Egress {Ingress_Only = 'I', Egress_Only = 'E', Ingress_Or_Egress = ' '};
    //
    class Container_Content {
     private:
        const PHV_Container *container_i;  // parent container
        int lo_i;  // low of bit range in container for field
        int hi_i;  // high of bit range in container for field
        const PhvInfo::Field *field_i;
        const int field_bit_lo_i;  // start of field bit in this container

     public:
        //
        Container_Content(
            const PHV_Container *c,
            int l,
            int h,
            const PhvInfo::Field *f,
            int field_bit_lo = 0);
        //
        int lo() const                  { return lo_i; }
        void lo(int l)                  { lo_i = l; }
        int hi() const                  { return hi_i; }
        void hi(int h)                  { hi_i = h; }
        int width() const               { return hi_i - lo_i + 1; }
        const PhvInfo::Field *field()   { return field_i; }
        int field_bit_lo() const        { return field_bit_lo_i; }
        const PHV_Container *container() { return container_i; }
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
    std::vector<Container_Content *> fields_in_container_i;  // fields binned in this container
    char *bits_i;                                            // tainted bits in container
    char taint_color_i = '0';                                // each resident field separate color
                                                             // highest number=#fields in container
    int avail_bits_i = 0;                                    // available bits in container
    ordered_map<int, int> ranges_i;                          // available ranges in this container
    //
    Container_status o_status_i = Container_status::EMPTY;
    std::vector<Container_Content *> o_fields_in_container_i;
                                                             // fields to overlay in this container
    char o_taint_color_i = '0';                              // each resident field separate color
    char *o_bits_i;                                          // tainted bits for overlay fields
    int avail_o_bits_i = 0;                                  // available overlay bits
    ordered_map<int, int> o_ranges_i;                        // available overlay ranges
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
    std::string asm_string()                                    { return asm_string_i; }
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
    Container_status o_status()                                 { return o_status_i; }
    char *bits()                                                { return bits_i; }
    char *o_bits()                                              { return o_bits_i; }
    void taint(
        int start,
        int width,
        const PhvInfo::Field *field,
        int range_start = 0,
        int field_bit_lo = 0,
        bool process_overflow = false /* default */);
    int avail_bits()                                            { return avail_bits_i; }
    int avail_o_bits()                                          { return avail_o_bits_i; }
    ordered_map<int, int>& ranges()                             { return ranges_i; }
    ordered_map<int, int>& o_ranges()                           { return o_ranges_i; }
    std::vector<Container_Content *>& fields_in_container()     { return fields_in_container_i; }
    std::vector<Container_Content *>& o_fields_in_container()   { return o_fields_in_container_i; }
    void create_ranges();
    void clear();
    void clean_ranges();
    //
    static bool constraint_no_cohabit(const PhvInfo::Field *field) {
        if (field->deparser_no_pack
            || field->mau_phv_no_pack) {
            //
            return true;
        }
        return false;
    }
    //
    void sanity_check_container(const std::string& msg);
    void sanity_check_container_avail(int lo, int hi, const std::string&);
    void sanity_check_container_ranges(const std::string&);
    //
};  // class PHV_Container
//
//
std::ostream &operator<<(std::ostream &, PHV_Container::Container_Content *);
std::ostream &operator<<(std::ostream &, std::vector<PHV_Container::Container_Content *>&);
std::ostream &operator<<(std::ostream &, std::set<PHV_Container::Container_Content *>&);
std::ostream &operator<<(std::ostream &, ordered_map<int, int>&);
std::ostream &operator<<(std::ostream &, const PHV_Container*);
std::ostream &operator<<(std::ostream &, PHV_Container*);
std::ostream &operator<<(std::ostream &, PHV_Container&);
std::ostream &operator<<(std::ostream &, std::vector<PHV_Container *>&);
std::ostream &operator<<(std::ostream &, std::list<PHV_Container *>&);
//
#endif /* _TOFINO_PHV_CLUSTER_PHV_CONTAINER_H_ */
