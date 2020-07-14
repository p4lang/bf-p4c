#include <errno.h>
#include <fcntl.h>
#include "hex.h"
#include <iostream>
#include <limits.h>
#include "log.h"
#include <signal.h>
#include <string.h>
#include <sys/wait.h>
#include <unistd.h>

#include "config.h"
#ifdef HAVE_EXECINFO_H
#include <execinfo.h>
#endif
#ifdef HAVE_UCONTEXT_H
#include <ucontext.h>
#endif

static const char *signames[] = {
    "NONE", "HUP", "INT","QUIT", "ILL","TRAP",  "ABRT", "BUS",  "FPE","KILL",
    "USR1","SEGV","USR2","PIPE","ALRM","TERM","STKFLT","CHLD", "CONT","STOP",
    "TSTP","TTIN","TTOU", "URG","XCPU","XFSZ","VTALRM","PROF","WINCH","POLL",
    "PWR" , "SYS"
};

char *program_name = nullptr;

#ifdef MULTITHREAD
#include <pthread.h>
std::vector<pthread_t *>        thread_ids;
__thread        int             my_id;

void register_thread() {
    static std::mutex           lock;
    std::lock_guard<std::mutex> acquire(lock);
    my_id = thread_ids.size();
    thread_ids.push_back(pthread_self());
}
#define MTONLY(...)     __VA_ARGS__
#else
#define MTONLY(...)
#endif // MULTITHREAD

static void sigint_shutdown(int sig, siginfo_t *info, void *uctxt)
{
    LOG1("Exiting with SIG" << signames[sig]);
    _exit(sig + 0x80);
}

/*
 * call external program addr2line WITHOUT using malloc or stdio or anything
 * else that might be problematic if there's memory corruption or exhaustion
 */
const char *addr2line(void *addr, const char *text)
{
    int pfd[2], len;
    pid_t child;
    static char buffer[1024];
    char *p = buffer;
    const char *argv[4] = { "/bin/sh", "-c", buffer, 0 }, *t;
    strcpy(p, "addr2line "); p += strlen(p);
    uintptr_t a = (uintptr_t)addr;
    int shift = (CHAR_BIT * sizeof(uintptr_t) - 1) & ~3;
    while (shift > 0 && (a >> shift) == 0) shift -= 4;
    while (shift >= 0) {
        *p++ = "0123456789abcdef"[(a >> shift) & 0xf];
        shift -= 4; }
    strcpy(p, " -fsipe $(which "); p += strlen(p);
    if (text && (t = strchr(text, '('))) {
        strncpy(p, text, t-text);
        p += t-text;
    } else if (program_name != nullptr) {
        strncpy(p, program_name, (buffer+1023-p));
        // Below fix is for Klockwork to not report critical errors.  Ensure
        // buffer is always null terminated, even when add2line is called
        // multiple times.
        buffer[1023] = 0;
        p += strlen(p); }
    else {
      return nullptr;
    }
    strcpy(p, ") | c++filt");
    p += strlen(p);
#ifdef __linux__
    if (pipe2(pfd, O_CLOEXEC) < 0) return 0;
#else
    // pipe2 is Linux specific
    if (pipe(pfd) < 0) return 0;
#endif // __linux__
    while ((child = fork()) == -1 && errno == EAGAIN);
    if (child == -1) return 0;
    if (child == 0) {
        dup2(pfd[1], 1);
        dup2(pfd[1], 2);
        execvp(argv[0], (char*const*)argv);
        _exit(-1); }
    close(pfd[1]);
    p = buffer;
    while (p < buffer + sizeof(buffer) - 1 &&
           (len = read(pfd[0], p, buffer+sizeof(buffer)-p-1)) > 0 &&
           (p += len) && !memchr(p-len, '\n', len));
    close(pfd[0]);
    waitpid(child, &len, WNOHANG);
    *p = 0;
    if ((p = strchr(buffer, '\n'))) *p = 0;
    if (buffer[0] == 0 || buffer[0] == '?')
        return 0;
    return buffer;
}

#ifdef HAVE_UCONTEXT_H
static void dumpregs(mcontext_t *mctxt)
{
#if defined(REG_EAX)
    LOG1(" eax=" << hex(mctxt->gregs[REG_EAX], 8, '0') <<
         " ebx=" << hex(mctxt->gregs[REG_EBX], 8, '0') <<
         " ecx=" << hex(mctxt->gregs[REG_ECX], 8, '0') <<
         " edx=" << hex(mctxt->gregs[REG_EDX], 8, '0'));
    LOG1(" edi=" << hex(mctxt->gregs[REG_EDI], 8, '0') <<
         " esi=" << hex(mctxt->gregs[REG_ESI], 8, '0') <<
         " ebp=" << hex(mctxt->gregs[REG_EBP], 8, '0') <<
         " esp=" << hex(mctxt->gregs[REG_ESP], 8, '0'));
#elif defined(REG_RAX)
    LOG1(" rax=" << hex(mctxt->gregs[REG_RAX], 16, '0') <<
         " rbx=" << hex(mctxt->gregs[REG_RBX], 16, '0') <<
         " rcx=" << hex(mctxt->gregs[REG_RCX], 16, '0'));
    LOG1(" rdx=" << hex(mctxt->gregs[REG_RDX], 16, '0') <<
         " rdi=" << hex(mctxt->gregs[REG_RDI], 16, '0') <<
         " rsi=" << hex(mctxt->gregs[REG_RSI], 16, '0'));
    LOG1(" rbp=" << hex(mctxt->gregs[REG_RBP], 16, '0') <<
         " rsp=" << hex(mctxt->gregs[REG_RSP], 16, '0') <<
         "  r8=" << hex(mctxt->gregs[REG_R8],  16, '0'));
    LOG1("  r9=" << hex(mctxt->gregs[REG_R9],  16, '0') <<
         " r10=" << hex(mctxt->gregs[REG_R10], 16, '0') <<
         " r11=" << hex(mctxt->gregs[REG_R11], 16, '0'));
    LOG1(" r12=" << hex(mctxt->gregs[REG_R12], 16, '0') <<
         " r13=" << hex(mctxt->gregs[REG_R13], 16, '0') <<
         " r14=" << hex(mctxt->gregs[REG_R14], 16, '0'));
    LOG1(" r15=" << hex(mctxt->gregs[REG_R15], 16, '0'));
#elif defined(__i386__)
    LOG1(" eax=" << hex(mctxt->mc_eax, 8, '0') <<
         " ebx=" << hex(mctxt->mc_ebx, 8, '0') <<
         " ecx=" << hex(mctxt->mc_ecx, 8, '0') <<
         " edx=" << hex(mctxt->mc_edx, 8, '0'));
    LOG1(" edi=" << hex(mctxt->mc_edi, 8, '0') <<
         " esi=" << hex(mctxt->mc_esi, 8, '0') <<
         " ebp=" << hex(mctxt->mc_ebp, 8, '0') <<
         " esp=" << hex(mctxt->mc_esp, 8, '0'));
#elif defined(__amd64__)
    LOG1(" rax=" << hex(mctxt->mc_rax, 16, '0') <<
         " rbx=" << hex(mctxt->mc_rbx, 16, '0') <<
         " rcx=" << hex(mctxt->mc_rcx, 16, '0'));
    LOG1(" rdx=" << hex(mctxt->mc_rdx, 16, '0') <<
         " rdi=" << hex(mctxt->mc_rdi, 16, '0') <<
         " rsi=" << hex(mctxt->mc_rsi, 16, '0'));
    LOG1(" rbp=" << hex(mctxt->mc_rbp, 16, '0') <<
         " rsp=" << hex(mctxt->mc_rsp, 16, '0') <<
         "  r8=" << hex(mctxt->mc_r8,  16, '0'));
    LOG1("  r9=" << hex(mctxt->mc_r9,  16, '0') <<
         " r10=" << hex(mctxt->mc_r10, 16, '0') <<
         " r11=" << hex(mctxt->mc_r11, 16, '0'));
    LOG1(" r12=" << hex(mctxt->mc_r12, 16, '0') <<
         " r13=" << hex(mctxt->mc_r13, 16, '0') <<
         " r14=" << hex(mctxt->mc_r14, 16, '0'));
    LOG1(" r15=" << hex(mctxt->mc_r15, 16, '0'));
#else
#warning "unknown machine type"
#endif
}
#endif

static void crash_shutdown(int sig, siginfo_t *info, void *uctxt)
{
    MTONLY( static std::recursive_mutex lock;
            static int threads_dumped = 0;
            static bool killed_all_threads = false;
            lock.lock();
            if (!killed_all_threads) {
                killed_all_threads = true;
                for (int i = 0; i < num_threads; i++)
                    if (i != my_id-1)
                        pthread_kill(thread_ids[i], SIGABRT); } )
    LOG1(MTONLY("Thread #" << my_id << " " <<) "exiting with SIG" <<
          signames[sig] << ", trace:");
    if (sig == SIGILL || sig == SIGFPE || sig == SIGSEGV ||
        sig == SIGBUS || sig == SIGTRAP)
        LOG1("  address = " << hex(info->si_addr));
#ifdef HAVE_UCONTEXT_H
    dumpregs(&((ucontext_t *)uctxt)->uc_mcontext);
#endif
#ifdef HAVE_EXECINFO_H
    static void *buffer[64];
    int size = backtrace(buffer, 64);
    char **strings = backtrace_symbols(buffer, size);
    for (int i = 1; i < size; i++) {
        if (strings)
            LOG1("  " << strings[i]);
        if (const char *line = addr2line(buffer[i], strings ? strings[i] : 0))
          LOG1("    " << line); }
    if (size < 1)
        LOG1("backtrace failed");
#endif
    MTONLY( if (++threads_dumped < num_threads) {
                lock.unlock();
                pthread_exit(0);
            } else
                lock.unlock(); )
    if (!LOGGING(1))
        std::clog << "exiting with SIG" << signames[sig] << std::endl;
    _exit(sig + 0x80);
}

void register_exit_signals()
{
    struct sigaction    sigact;
    sigact.sa_sigaction = sigint_shutdown;
    sigact.sa_flags = SA_SIGINFO;
    sigemptyset(&sigact.sa_mask);
    sigaction(SIGHUP, &sigact, 0);
    sigaction(SIGINT, &sigact, 0);
    sigaction(SIGQUIT, &sigact, 0);
    sigaction(SIGTERM, &sigact, 0);
    sigact.sa_sigaction = crash_shutdown;
    sigaction(SIGILL, &sigact, 0);
    sigaction(SIGABRT, &sigact, 0);
    sigaction(SIGFPE, &sigact, 0);
    sigaction(SIGSEGV, &sigact, 0);
    sigaction(SIGBUS, &sigact, 0);
    sigaction(SIGTRAP, &sigact, 0);
    signal(SIGPIPE, SIG_IGN);
}
