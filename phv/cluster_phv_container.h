#ifndef _TOFINO_PHV_CLUSTER_PHV_CONTAINER_H_
#define _TOFINO_PHV_CLUSTER_PHV_CONTAINER_H_

#include "phv.h"
#include "phv_fields.h"
#include "ir/ir.h"
#include "lib/map.h"
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
class PHV_Container
{
 public:
    enum class PHV_Word {b32=32, b16=16, b8=8};
    enum class Containers {MAX=16};
    enum class Container_status {EMPTY='E', PARTIAL='P', FULL='F'};
    class Container_Content
    {
      private:
        int lo_i;						// low of bit range in container for field
        int hi_i;						// high of bit range in container for field
        const PhvInfo::Field *field_i;
      public:
        //
        Container_Content(int l, int h, const PhvInfo::Field *f);
        //
        int lo() const			{ return lo_i; }
        void lo(int l)			{ lo_i = l; }
        int hi() const			{ return hi_i; }
        void hi(int h)			{ hi_i = h; }
        int width() const		{ return hi_i - lo_i + 1; }
        const PhvInfo::Field *field()	{ return field_i; }
    };
    //
 private:
    PHV_Word width_i;						// width of container
    int number_i;						// container number 1..16 within MAU group
    Container_status status_i = Container_status::EMPTY;
    std::vector<Container_Content *> fields_in_container_i;	// fields binned in this container
    char *bits_i;						// tainted bits in container
    int avail_bits_lo_i = 0;					// available bit range lo
    int avail_bits_hi_i;					// available bit range hi
 public:
    PHV_Container(PHV_Word w, int n);
    //
    PHV_Word width()						{ return width_i; }
    int number()						{ return number_i; }
    Container_status status()					{ return status_i; }
    char *bits()						{ return bits_i; }
    void taint(int start, int width, const PhvInfo::Field *field_i);
    int avail_bits_lo()						{ return avail_bits_lo_i; }
    int avail_bits_hi()						{ return avail_bits_hi_i; }
    std::vector<Container_Content *>& fields_in_container()	{ return fields_in_container_i; }
};
//
//
std::ostream &operator<<(std::ostream &, std::vector<PHV_Container::Container_Content *>&);
std::ostream &operator<<(std::ostream &, PHV_Container*);
std::ostream &operator<<(std::ostream &, PHV_Container&);
std::ostream &operator<<(std::ostream &, std::vector<PHV_Container *>&);
//
#endif /* _TOFINO_PHV_CLUSTER_PHV_CONTAINER_H_ */
