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

PHV_Container::PHV_Container(PHV_MAU_Group *g, PHV_Word w, int n, int phv_n, Ingress_Egress gress)
	: phv_mau_group_i(g), width_i(w), number_i(n), phv_number_i(phv_n), gress_i(gress)
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
    // container may be part of POV that is Ingress Or Egress
    // however for any stage it can be used for Ingress or for Egress
    // cannot share container with Ingress fields and Egress fields
    // transition behavior for such sharing unclear
    //
    gress_i = gress(field);
}


//***********************************************************************************
//
// sanity checks
// 
//***********************************************************************************


void PHV_Container::Container_Content::sanity_check_container(const std::string& msg)
{
}


void PHV_Container::sanity_check_container(const std::string& msg)
{
}

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
std::ostream &operator<<(std::ostream &out, PHV_Container *c)
{
    // summary output 
    //
    if(c)
    {
        out << std::endl << '\t';
        out << "PHV-" << c->phv_number() << " C" << c->number() << (char) c->gress();
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

