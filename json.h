#ifndef _json_h_
#define _json_h_

#include <iostream>
#include <map>
#include <memory>
#include <string>
#include <typeindex>
#include <vector>
#include <assert.h>

#if defined(__GNUC__) && __GNUC__ == 4 && __GNUC__MINOR__ <= 8
/* missing from gcc 4.8 stdlib <memory> */
namespace std {
    template<class T, class...Args>
    std::unique_ptr<T> make_unique(Args&&... args)
    {
        std::unique_ptr<T> ret (new T(std::forward<Args>(args)...));
        return ret;
    }
}
#endif

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
    virtual void print_on(std::ostream &out, int indent=0, int width=80, const char *pfx="") const = 0;
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
    void print_on(std::ostream &out, int indent=0, int width=80, const char *pfx="") const { out << val; }
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
    void print_on(std::ostream &out, int indent=0, int width=80, const char *pfx="") const {
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
	    return (p1 == end() && p2 == b->end()); }
	return false; }
    void print_on(std::ostream &out, int indent=0, int width=80, const char *pfx="") const;
    bool test_width(int &limit) const {
	limit -= 2;
	for (auto &e : *this) {
	    if (!e->test_width(limit)) return false;
	    if ((limit -= 2) < 0 ) return false; }
	return true; }
    using vector_base::push_back;
    void push_back(long n) {
	number tmp(n);
        emplace_back(std::make_unique<number>(std::move(tmp))); }
    void push_back(const char *s) {
	string tmp(s);
        emplace_back(std::make_unique<string>(std::move(tmp))); }
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
	    return (p1 == end() && p2 == b->end()); }
	return false; }
    void print_on(std::ostream &out, int indent=0, int width=80, const char *pfx="") const;
    bool test_width(int &limit) const {
	limit -= 2;
	for (auto &e : *this) {
	    if (!e.first->test_width(limit)) return false;
	    if (!e.second->test_width(limit)) return false;
	    if ((limit -= 4) < 0 ) return false; }
	return true; }
    using map_base::count;
    map_base::size_type count(const char *str) const {
	string tmp(str);
        return count(&tmp); }
    map_base::size_type count(long n) const {
	number tmp(n);
        return count(&tmp); }
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
private:
    class element_ref {
        map                     &self;
        std::unique_ptr<obj>    key;
        map_base::iterator      iter;
    public:
        element_ref(map &s, const char *k) : self(s) {
            string tmp(k);
            iter = self.find(&tmp);
            if (iter == self.end())
                key.reset(new string(std::move(tmp))); }
        element_ref(map &s, long k) : self(s) {
            number tmp(k);
            iter = self.find(&tmp);
            if (iter == self.end())
                key.reset(new number(std::move(tmp))); }
        const char *operator=(const char *v) {
            if (key)
                iter = self.emplace(key.release(), std::unique_ptr<obj>(new string(v))).first;
            else { assert(iter != self.end());
                iter->second.reset(new string(v)); }
            return v; }
        long operator=(long v) {
            if (key)
                iter = self.emplace(key.release(), std::unique_ptr<obj>(new number(v))).first;
            else { assert(iter != self.end());
                iter->second.reset(new number(v)); }
            return v; }
        const std::unique_ptr<obj> &operator=(std::unique_ptr<obj> &&v) {
            if (key) iter = self.emplace(key.release(), std::move(v)).first;
            else { assert(iter != self.end());
                iter->second = std::move(v); }
            return iter->second; }
        explicit operator bool() const { return !key; }
        obj *get() const { return key ? 0 : iter->second.get(); }
        obj *operator->() const { return key ? 0 : iter->second.get(); }
    };
    friend std::ostream &operator<<(std::ostream &out, const element_ref &el);
public:
    element_ref operator[](const char *str) { return element_ref(*this, str); }
    element_ref operator[](long n) { return element_ref(*this, n); }
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
inline std::ostream &operator<<(std::ostream &out, const std::unique_ptr<obj> &json) {
    return out << json.get(); }
inline std::ostream &operator<<(std::ostream &out, const map::element_ref &el) {
    el->print_on(out);
    return out; }

}

#endif /* _json_h_ */
