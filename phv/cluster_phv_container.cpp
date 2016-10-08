#include "cluster_phv_container.h"
#include "lib/log.h"
#include "lib/stringref.h"
#include "base/logging.h"

//***********************************************************************************
//
// PHV_Container::PHV_Container constructor
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
PHV_Container::taint(int start, int width)
{
   for (auto i=start; i < start+width; i++)
   {
        bits_i[i] = '1';
   }
}

//***********************************************************************************
//
// output stream <<
// 
//***********************************************************************************
//
// phv_container output
//
std::ostream &operator<<(std::ostream &out, std::vector<PHV_Container::content>& c)
{
    for (auto s: c)
    {
        out << s.field() << '{' << s.lo() << ".." << s.hi() << '[' << s.width() << ']';
    }

    return out;
}
std::ostream &operator<<(std::ostream &out, PHV_Container *c)
{
    if(c)
    {
        out << "\tC" << c->number() << '[' << (int)(c->width()) << ']'
            << '(' << (char)(c->status()) << c->fields() << ')';
        out << '\t';
        out << c->bits();
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

