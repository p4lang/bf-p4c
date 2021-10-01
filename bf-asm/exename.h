#ifndef BF_ASM_EXENAME_H_
#define BF_ASM_EXENAME_H_

/** Attempt to determine the executable name and return a static path to it.  Will use
 * argv0 if provided and nothing better can be found */
const char *exename(const char *argv0 = nullptr);

#endif /* BF_ASM_EXENAME_H_ */
