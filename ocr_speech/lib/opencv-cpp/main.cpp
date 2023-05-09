extern "C" __attribute__((visibility("default"))) __attribute__((used))
void Gaussian(char *);

extern "C" __attribute__((visibility("default"))) __attribute__((used))
void image_ffi (unsigned char *, unsigned int *);

extern "C" __attribute__((visibility("default"))) __attribute__((used)) void cropImage(char *);
extern "C" __attribute__((visibility("default"))) __attribute__((used)) void normalizeImage(char *);


#include "gaussian.cpp"
#include "image_ffi.cpp"
#include "crop2.cpp"
#include "nor.cpp"