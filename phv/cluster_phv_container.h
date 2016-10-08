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
    enum class Container_status {EMPTY='E', PARTIAL='P', FULL='F'};
    struct content
    {
        int lo_i, hi_i;					// range of bits within container used by field
        const PhvInfo::Field *field_i;
        int lo() const			{ return lo_i; }
        int hi() const			{ return hi_i; }
        int width() const		{ return hi_i - lo_i + 1; }
        const PhvInfo::Field *field()	{ return field_i; }
    };
    //
 private:
    PHV_Word width_i;					// width of container
    int number_i;					// 1..16 within group
    Container_status status_i = Container_status::EMPTY;
    std::vector<content> fields_i;			// fields mapped to this container
    char *bits_i;
 public:
    PHV_Container(PHV_Word w, int n);
    //
    PHV_Word width()					{ return width_i; }
    int number()					{ return number_i; }
    Container_status status()				{ return status_i; }
    void status(Container_status s)			{ status_i = s; }
    std::vector<content>& fields()			{ return fields_i; }
    void taint(int start, int width);
    char *bits()					{ return bits_i; }
};
//
//
std::ostream &operator<<(std::ostream &, std::vector<PHV_Container::content>&);
std::ostream &operator<<(std::ostream &, PHV_Container*);
std::ostream &operator<<(std::ostream &, std::vector<PHV_Container *>&);
//
#endif /* _TOFINO_PHV_CLUSTER_PHV_CONTAINER_H_ */
