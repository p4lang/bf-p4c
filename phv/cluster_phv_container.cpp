#include "cluster_phv_container.h"
#include "lib/log.h"
#include "lib/stringref.h"
#include "base/logging.h"

//***********************************************************************************
//
// PHV_Container::Container_Content::Container_Content constructor
// 
//***********************************************************************************

PHV_Container::Container_Content::Container_Content(int l, int w, const PhvInfo::Field *f) : lo_i(l), hi_i(l+w-1), field_i(f)
{
    BUG_CHECK(field_i, "*****PHV_Container::Container_Content constructor called with null field ptr*****");
}

//***********************************************************************************
//
// PHV_Container::PHV_Container
// 
//***********************************************************************************

PHV_Container::PHV_Container(PHV_MAU_Group *g, PHV_Word w, int phv_n, std::string asm_string, Ingress_Egress gress)
	: phv_mau_group_i(g), width_i(w), phv_number_i(phv_n), asm_string_i(asm_string), gress_i(gress)
{
    bits_i = new char[(int) width_i];
    for (auto i=0; i < (int) width_i; i++)
    {
        bits_i[i] = taint_color_i;
    }
    avail_bits_i = (int) width_i;
    ranges_i[0] = (int) width_i - 1;
    //
}//PHV_Container

void
PHV_Container::taint(int start, int width, const PhvInfo::Field *field, int range_start)
{
    BUG_CHECK((start+width <= (int) width_i),
	"*****PHV_Container::taint()*****PHV-%s start=%d width=%d width_i=%d",
	phv_number_i, start, width, (int) width_i);
    BUG_CHECK(start+width <= ranges_i[range_start]+1,
	"*****PHV_Container::taint()*****PHV-%s start=%d width=%d range_start=%d",
	phv_number_i, start, width, range_start);
    //
    taint_color_i += '1' - '0';
    if(taint_color_i < '0' || taint_color_i > '9')
    {
        taint_color_i = '*';
    }
    for (auto i=start; i < start+width; i++)
    {
         bits_i[i] = taint_color_i;
    }
    //
    avail_bits_i -= width;		// packing reduces available bits
    BUG_CHECK(avail_bits_i >= 0, "*****PHV_Container::taint()*****PHV-%s avail_bits = %d", phv_number_i, avail_bits_i);
    //
    // first container placement, packing start lo = start + width
    // after packing, non contiguous availability e.g., [15..15], [8..10] => ranges[15] = 15, ranges[8] = 10
    //
    if(avail_bits_i == 0)
    {
        status_i = Container_status::FULL;
        ranges_i.clear();
    }
    else
    {
        status_i = Container_status::PARTIAL;
        if(range_start == start)
        {
            if(start+width < ranges_i[start]+1)
            {
                ranges_i[start+width] = ranges_i[start];
            }
            ranges_i.erase(start);
        }
        else
        {
            ranges_i[range_start] = start-1;
        }
    }
    //
    // track fields in this container
    //
    fields_in_container_i.push_back(new Container_Content(start, width, field));
    //
    // set gress for this container
    // container may be part of MAU group that is Ingress Or Egress
    // however for any stage it is used exclusively for Ingress or for Egress
    // cannot share container with Ingress fields & Egress fields
    // transition behavior for such sharing unclear
    //
    gress_i = gress(field);
}


//***********************************************************************************
//
// sanity checks
// 
//***********************************************************************************


void PHV_Container::Container_Content::sanity_check_container(PHV_Container *container, const std::string& msg)
{
    const std::string msg_1 = msg + "..PHV_Container::Container_Content::sanity_check_container";
    //
    // fields can span containers
    //
    if(field_i->size <= width())
    {
        if(field_i->phv_use_hi - field_i->phv_use_lo + 1 != width())
        {
            LOG1("*****cluster_phv_container.cpp:sanity_FAIL*****.." << msg_1 << " field width does not match container use " << field_i->phv_use_lo << ".." << field_i->phv_use_hi << " vs " << lo_i << ".." << hi_i << ".." << field_i << *container);
        }
    }
}

void PHV_Container::sanity_check_container(const std::string& msg)
{
    const std::string msg_1 = msg + "..PHV_Container::sanity_check_container";
    //
    // for fields binned in this container check bits occupied
    //
    for (auto &cc: fields_in_container_i)
    {
        cc->sanity_check_container(this, msg_1);
        sanity_check_container_avail(cc->lo(), cc->hi(), msg_1 /*,taint=true*/);
    }
}

void PHV_Container::sanity_check_container_avail(int lo, int hi, const std::string& msg, bool taint)
{
    const std::string msg_1 = msg + "..PHV_Container::sanity_check_container_avail";
    //
    // check bits lo .. hi are 0
    //
    for (auto i = lo; i <= hi; i++)
    {
        if(taint == false && bits_i[i] != '0')
        {
            LOG1("*****cluster_phv_container.cpp:sanity_FAIL*****.." << msg_1 << " container bits should be '0' " << i << ".." << lo << ".." << hi << " vs " << *this);
        }
        if(taint == true && bits_i[i] == '0')
        {
            LOG1("*****cluster_phv_container.cpp:sanity_FAIL*****.." << msg_1 << " container bits should be tainted " << i << ".." << lo << ".." << hi << " vs " << *this);
        }
    }
    // check available bits in container
    //
    if(taint == false && avail_bits_i < hi - lo)
    {
        LOG1("*****cluster_phv_container.cpp:sanity_FAIL*****.." << msg_1 << " container avail bits " << lo << ".." << hi << " vs " << avail_bits_i);
    }
    if(taint == false && avail_bits_i == hi - lo)
    {   // check all other bits are not 0
        for (auto i=0; i < lo; i++)
        {
            if(bits_i[i] == '0')
            {
                LOG1("*****cluster_phv_container.cpp:sanity_FAIL*****.." << msg_1 << " container bits should be tainted " << i << ".." << lo << ".." << hi << " vs " << *this);
            }
        }
        for (auto i=hi+1; i < (int) width_i; i++)
        {
            if(bits_i[i] == '0')
            {
                LOG1("*****cluster_phv_container.cpp:sanity_FAIL*****.." << msg_1 << " container bits should be tainted " << i << ".." << lo << ".." << hi << " vs " << *this);
            }
        }
    }
    // check container status
    //
    if(taint == false && status_i != Container_status::PARTIAL)
    {
        LOG1("*****cluster_phv_container.cpp:sanity_FAIL*****.." << msg_1 << " container status " << (char) status_i << *this);
    }
    // check range map in container
    //
    if(taint == false && ranges_i[lo] != hi)
    {
        LOG1("*****cluster_phv_container.cpp:sanity_FAIL*****.." << msg_1 << " container ranges " << ranges_i << *this);
    } 
}//sanity_check_container_avail

//***********************************************************************************
//
// output stream <<
// 
//***********************************************************************************
//
// Container_Content output
//
std::ostream &operator<<(std::ostream &out, std::vector<PHV_Container::Container_Content *>& c)
{
    for (auto f: c)
    {
        out << std::endl << "\t\t\t\t\t";
        out << f->field() << '<' << f->width() << '>' << '{' << f->lo() << ".." << f->hi() << '}';
    }

    return out;
}

//
// phv_container output
//

std::ostream &operator<<(std::ostream &out, std::map<int, int>& ranges)
{
    out << ".....container ranges....." << std::endl;
    for (auto i: ranges)
    {
        out << '[' << i.first << "] -- " << i.second << std::endl;
    }

    return out;
}

std::ostream &operator<<(std::ostream &out, PHV_Container *c)
{
    // summary output 
    //
    if(c)
    {
        out << std::endl << '\t';
        out << "PHV-" << c->phv_number() << '.' << c->asm_string() << '.' << (char) c->gress();
        if(c->fields_in_container().size() > 1)
        {
            out << "p";
        }
        if(c->status() != PHV_Container::Container_status::FULL)
        {
            for (auto r: c->ranges())
            {
                out << '(' << r.first << ".." << r.second << ')';
            }
        }
        else
        {
            out << '\t';
        }
    }
    else
    {
        out << "-c-";
    }

    return out;
}

std::ostream &operator<<(std::ostream &out, PHV_Container &c)
{
    // detailed output
    //
    out << '\t' << &c
        << '\t' << c.bits()
        << c.fields_in_container();

    return out;
}

std::ostream &operator<<(std::ostream &out, std::vector<PHV_Container *> &phv_containers)
{
    for (auto m: phv_containers)
    {
        out << *m;
    }

    return out;
}

