#ifndef _EXTENSIONS_BF_P4C_RUNID_H_
#define _EXTENSIONS_BF_P4C_RUNID_H_

#include <openssl/sha.h>
#include <string>
#include <time.h>

class RunId
{
 public:
    static const std::string &getId() {
        static RunId instance;
        return instance._runId;
    }
 private:
    std::string _runId;
    RunId() {
        const time_t now = time(NULL);
        char input[1024];
        strftime(input, 1024, "%c", localtime(&now));
        unsigned char hash[SHA256_DIGEST_LENGTH];
        SHA256_CTX sha256;
        SHA256_Init(&sha256);
        SHA256_Update(&sha256, input, strlen(input));
        SHA256_Final(hash, &sha256);
        char outputHash[65];
        for (int n = 0; n < SHA256_DIGEST_LENGTH; n++)
            sprintf(outputHash + (n*2), "%02x", hash[n]);
        outputHash[64] = 0;
        _runId = outputHash;
    }

 public:
    // disable any other constructors
    RunId(RunId const&)           = delete;
    void operator=(RunId const&)  = delete;
};

#endif  // _EXTENSIONS_BF_P4C_RUNID_H_
