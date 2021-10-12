#include <stdio.h>

#include "gtest/gtest.h"

// Add the component's unit-tests here.
#include "depositfield.cpp"
#include "asm-types.cpp"
#include "mirror.cpp"

GTEST_API_ int main(int argc, char **argv) {
  printf("running gtestasm\n");
  testing::InitGoogleTest(&argc, argv);
  return RUN_ALL_TESTS();
}
