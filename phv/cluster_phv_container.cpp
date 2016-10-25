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
    avail_bits_lo_i = 0;
    avail_bits_hi_i = (int) width_i - 1;
}//PHV_Container

void
PHV_Container::taint(int start, int width, const PhvInfo::Field *field)
{
    taint_color_i += '1' - '0';
    for (auto i=start; i < start+width; i++)
    {
         bits_i[i] = taint_color_i;
    }
    if(start == 0)
    {   // first use: container placement
        //
        avail_bits_lo_i = start + width;
    }
    else
    {
        // packing from right most slice to honor alignment
        //
        avail_bits_hi_i -= width;
    }
    //
    //?? assert avail_bits_lo_i <= avail_bits_hi_i + 1
    //
    if(avail_bits_lo_i == avail_bits_hi_i + 1)
    {
        status_i = Container_status::FULL;
    }
    else
    {
        status_i = Container_status::PARTIAL;
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
            out << '[' << c->avail_bits_lo() << ".." << c->avail_bits_hi() << ']';
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

