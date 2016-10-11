#include "cluster_phv_container.h"
#include "lib/log.h"
#include "lib/stringref.h"
#include "base/logging.h"

//***********************************************************************************
//
// PHV_Container::Container_Content::Container_Content constructor
// 
//***********************************************************************************

PHV_Container::Container_Content::Container_Content(int l, int w, const PhvInfo::Field *f) : lo_i(l), hi_i(w-l-1), field_i(f)
{
    BUG_CHECK(field_i, "*****Container_Content constructor called with null field ptr*****");
}

//***********************************************************************************
//
// PHV_Container::PHV_Container
// 
//***********************************************************************************

PHV_Container::PHV_Container(PHV_Word w, int n) : width_i(w), number_i(n)
{
    bits_i = new char[(int) width_i];
    for (auto i=0; i < (int) width_i; i++)
    {
        bits_i[i] = '0';
    }
}//PHV_Container

void
PHV_Container::taint(int start, int width, const PhvInfo::Field *field_i)
{
   for (auto i=start; i < start+width; i++)
   {
        bits_i[i] = '1';
   }
   //
   if(width == (int) width_i)
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
   fields_in_container_i.push_back(new Container_Content(start, width, field_i));
}

//***********************************************************************************
//
// output stream <<
// 
//***********************************************************************************
//
// Container_content output
//
std::ostream &operator<<(std::ostream &out, std::vector<PHV_Container::Container_Content *>& c)
{
    for (auto f: c)
    {
        out << f->field() << '<' << f->width() << '>' << '{' << f->lo() << ".." << f->hi() << '}';
    }

    return out;
}
//
// phv_container output
//
std::ostream &operator<<(std::ostream &out, PHV_Container *c)
{
    if(c)
    {
        out << "\tC" << c->number() << '[' << (int)(c->width()) << ']'
            << '(' << (char)(c->status()) << ')'
            << '\t' << c->bits()
            << '\t' << c->fields_in_container();
    }
    else
    {
        out << "-c-";
    }
    out << std::endl;

    return out;
}

std::ostream &operator<<(std::ostream &out, std::vector<PHV_Container *> &phv_containers)
{
    for (auto m: phv_containers)
    {
        out << m;
    }

    return out;
}

