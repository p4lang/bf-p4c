#include <openssl/sha.h>
#include <cstdio>
#include <cstring>
#include <ctime>

#include "bf-p4c/common/run_id.h"

RunId::RunId() {
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
        snprintf(outputHash + (n*2), 64-(n*2), "%02x", hash[n]);
    outputHash[64] = 0;
    char ss[17];
    for (int n =0; n < 16; ++n)
        ss[n] = outputHash[n];
    ss[16] = 0;
    _runId = ss;
}
