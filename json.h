#ifndef _json_h_
#define _json_h_

#include <iostream>
#include <map>
#include <memory>
#include <string>
#include <typeindex>
#include <vector>

namespace json {

class obj {
public:
    obj() {}
    obj(const obj &) = default;
    obj(obj &&) = default;
    obj &operator=(const obj &) & = default;
    obj &operator=(obj &&) & = default;
    virtual ~obj() {}
    virtual bool operator <(const obj &a) const = 0;
    bool operator >=(const obj &a) const { return !(*this < a); }
    bool operator >(const obj &a) const { return a < *this; }
    bool operator <=(const obj &a) const { return !(a < *this); }
    virtual bool operator ==(const obj &a) const = 0;
    bool operator !=(const obj &a) const { return !(*this == a); }
    struct ptrless {
	bool operator()(const obj *a, const obj *b) const
	    { return b ? a ? *a < *b : true : false; }
    };
    virtual void print_on(std::ostream &out, int indent=0, int width=80) const = 0;
    virtual bool test_width(int &limit) const = 0;
};

class number : public obj {
public:
    long	val;
    number(long l) : val(l) {}
    ~number() {}
    bool operator <(const obj &a) const {
	if (auto *b = dynamic_cast<const number *>(&a)) return val < b->val;
	return std::type_index(typeid(*this)) < std::type_index(typeid(a)); }
    bool operator ==(const obj &a) const {
	if (auto *b = dynamic_cast<const number *>(&a)) return val == b->val;
	return false; }
    void print_on(std::ostream &out, int indent, int width) const { out << val; }
    bool test_width(int &limit) const
	{ char buf[32]; limit -= sprintf(buf, "%ld", val); return limit >= 0; }
};

class string : public obj, public std::string {
public:
    string() {}
    string(const string &) = default;
    string(const std::string &a) : std::string(a) {}
    string(string &&) = default;
    string(std::string &&a) : std::string(a) {}
    string &operator=(const string &) & = default;
    string &operator=(string &&) & = default;
    ~string() {}
    bool operator <(const obj &a) const {
	if (const string *b = dynamic_cast<const string *>(&a))
	    return static_cast<const std::string &>(*this) <
		   static_cast<const std::string &>(*b);
	return std::type_index(typeid(*this)) < std::type_index(typeid(a)); }
    bool operator ==(const obj &a) const {
	if (const string *b = dynamic_cast<const string *>(&a))
	    return static_cast<const std::string &>(*this) ==
		   static_cast<const std::string &>(*b);
	return false; }
    void print_on(std::ostream &out, int indent, int width) const {
	out << '"' << *this << '"'; }
    bool test_width(int &limit) const { limit -= size()+2; return limit >= 0; }
};

typedef std::vector<std::unique_ptr<obj>> vector_base;
class vector : public obj, public vector_base {
public:
    vector() {}
    vector(const vector &) = default;
    vector(vector &&) = default;
    vector &operator=(const vector &) & = default;
    vector &operator=(vector &&) & = default;
    ~vector() {}
    bool operator <(const obj &a) const {
	if (const vector *b = dynamic_cast<const vector *>(&a)) {
	    auto p1 = begin(), p2 = b->begin();
	    while (p1 != end() && p2 != b->end()) {
		if (**p1 < **p2) return true;
		if (**p1 != **p2) return false;
		p1++; p2++; }
	    return p2 != b->end(); }
	return std::type_index(typeid(*this)) < std::type_index(typeid(a)); }
    bool operator ==(const obj &a) const {
	if (const vector *b = dynamic_cast<const vector *>(&a)) {
	    auto p1 = begin(), p2 = b->begin();
	    while (p1 != end() && p2 != b->end()) {
		if (**p1 != **p2) return false;
		p1++; p2++; }
	    if (p1 != end() || p2 != b->end())
		return false;
	    return true; }
	return false; }
    void print_on(std::ostream &out, int indent, int width) const;
    bool test_width(int &limit) const {
	limit -= 2;
	for (auto &e : *this) {
	    if (!e->test_width(limit)) return false;
	    if ((limit -= 2) < 0 ) return false; }
	return true; }

};

typedef std::map<obj *, std::unique_ptr<obj>, obj::ptrless> map_base;
class map : public obj, public map_base {
public:
    map() {}
    map(const map &) = default;
    map(map &&) = default;
    map &operator=(const map &) & = default;
    map &operator=(map &&) & = default;
    ~map() { for (auto &e : *this) delete e.first; }
    bool operator <(const obj &a) const {
	if (const map *b = dynamic_cast<const map *>(&a)) {
	    auto p1 = begin(), p2 = b->begin();
	    while (p1 != end() && p2 != b->end()) {
		if (*p1->first < *p2->first) return true;
		if (*p1->first != *p2->first) return false;
		if (*p1->second < *p2->second) return true;
		if (*p1->second != *p2->second) return false;
		p1++; p2++; }
	    return p2 != b->end(); }
	return std::type_index(typeid(*this)) < std::type_index(typeid(a)); }
    bool operator ==(const obj &a) const {
	if (const map *b = dynamic_cast<const map *>(&a)) {
	    auto p1 = begin(), p2 = b->begin();
	    while (p1 != end() && p2 != b->end()) {
		if (*p1->first != *p2->first) return false;
		if (*p1->second != *p2->second) return false;
		p1++; p2++; }
	    if (p1 != end() || p2 != b->end())
		return false;
	    return true; }
	return false; }
    void print_on(std::ostream &out, int indent, int width) const;
    bool test_width(int &limit) const {
	limit -= 2;
	for (auto &e : *this) {
	    if (!e.first->test_width(limit)) return false;
	    if (!e.second->test_width(limit)) return false;
	    if ((limit -= 4) < 0 ) return false; }
	return true; }
    using map_base::operator[];
    obj *operator[](const char *str) const {
	string tmp(str);
	auto rv = find(&tmp);
	if (rv != end()) return rv->second.get();
	return 0; }
    obj *operator[](long n) const {
	number tmp(n);
	auto rv = find(&tmp);
	if (rv != end()) return rv->second.get();
	return 0; }
};

std::istream &operator>>(std::istream &in, std::unique_ptr<obj> &json);
inline std::istream &operator>>(std::istream &in, obj *&json) {
    std::unique_ptr<obj> p;
    in >> p;
    if (in) json = p.release();
    return in;
}

inline std::ostream &operator<<(std::ostream &out, const obj *json) {
    json->print_on(out);
    return out; }
inline std::ostream &operator<<(std::ostream &out, const std::unique_ptr<obj> &json) { return out << json.get(); }

}
#endif /* _json_h_ */
