#include "json.h"
#include <iomanip>

namespace json {

std::istream &operator>>(std::istream &in, std::unique_ptr<obj> &json) {
    while (in) {
	char ch;
	in >> ch;
	switch(ch) {
	case '0': case '1': case '2': case '3': case '4':
	case '5': case '6': case '7': case '8': case '9':
	case '-': {
	    in.unget();
	    long l;
	    in >> l;
	    json.reset(new number(l));
	    return in; }
	case '"': {
	    std::string s;
	    getline(in, s, '"');
	    json.reset(new string(std::move(s)));
	    return in; }
	case '[': {
	    std::unique_ptr<vector> rv(new vector());
	    do {
		std::unique_ptr<obj> o;
		in >> o >> ch;
		rv->push_back(std::move(o));
		if (ch != ',' && ch != ']') {
		    std::cerr << "missing ',' in vector" << std::endl;
		    in.unget(); }
	    } while (in && ch != ']');
	    json = std::move(rv);
	    return in; }
	case '{': {
	    std::unique_ptr<map> rv(new map());
	    do {
		std::unique_ptr<obj> key, val;
		in >> key >> ch;
		if (ch == '}') {
		    std::cerr << "missing value in map" << std::endl;
		} else {
		    if (ch != ':') {
			std::cerr << "missing ':' in map" << std::endl;
			in.unget(); }
		    in >> val >> ch; }
		(*rv)[key.release()] = std::move(val);
		if (ch != ',' && ch != '}') {
		    std::cerr << "missing ',' in map" << std::endl;
		    in.unget(); }
	    } while (in && ch != '}');
	    json = std::move(rv);
	    return in; }
	default:
	    std::cerr << "unexpected character '" << ch << "'" << std::endl;
	}
    }
    return in;
}

void vector::print_on(std::ostream &out, int indent, int width) const {
    int twidth = width;
    bool first = true;
    bool oneline = test_width(twidth);
    out << '[';
    indent += 2;
    for (auto &e : *this) {
	if (!first) out << ',';
	if (!oneline) out << '\n' << std::setw(indent);
	out << ' ' << std::setw(0);
	e->print_on(out, indent, width - 2);
	first = false;
    }
    indent -= 2;
    if (!first) out << ' ';
    out << ']';
}

void map::print_on(std::ostream &out, int indent, int width) const {
    int twidth = width;
    bool first = true;
    bool oneline = test_width(twidth);
    //std::cout << "*** width=" << width << "  twdith=" << twidth << std::endl;
    out << '{';
    indent += 2;
    for (auto &e : *this) {
	if (!first) out << ',';
	if (!oneline) out << '\n' << std::setw(indent);
	out << ' ' << std::setw(0);
	e.first->print_on(out, indent, width - 2);
	out << ": ";
	e.second->print_on(out, indent, width - 2);
	first = false;
    }
    indent -= 2;
    if (!first) out << ' ';
    out << '}';
}


}
