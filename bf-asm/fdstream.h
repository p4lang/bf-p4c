#ifndef _fdstream_h_
#define _fdstream_h_

#include <iostream>
#include <functional>
#include <streambuf>
#include <sys/types.h>
#include <sys/socket.h>


class fdstream : public std::iostream {
    struct buffer_t : public std::basic_streambuf<char> {
	int		fd;
    public:
	buffer_t(int _fd) : fd(_fd) {}
	~buffer_t() { delete[] eback(); delete[] pbase(); }
	int sync();
	int_type underflow();
	int_type overflow(int_type c = traits_type::eof());
	void reset() { setg(eback(), eback(), eback());
		       setp(pbase(), epptr()); }
    } buffer;
    std::function<void()>	closefn;
public:
    fdstream(int fd = -1) : std::iostream(&buffer), buffer(fd) { init(&buffer); }
    ~fdstream() { if (closefn) closefn(); }
    void connect(int fd) { flush(); buffer.reset(); buffer.fd = fd; }
    void setclose(std::function<void()> fn) { closefn = fn; }
};

#endif /* _fdstream_h_ */
