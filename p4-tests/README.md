# p4_tests

This is the common repository for Glass and Brig compiler Testcases.  
It includes two sub directories p4_14 and p4_16  

How to Run tests:  
=================

For Glass  
==========
1)Get p4c-tofino for glass compiler  
   git clone git@github.com:barefootnetworks/p4c-tofino.git  
2)Get the p4_tests  
   git clone git@github.com:barefootnetworks/p4_tests  
3)Start all the testcases  
   autoreconf --install  
   ./configure  
   make -j8 check  
   
For Brig  
==========
1)Get and do make for barefoot repo tofino-asm, model, p4l-bmv2, p4l-p4c-bmv2  
2)Get p4c from p4lang, create extensions directory inside p4c and get p4c-extension-tofino and p4_tests  
   mkdir extensions  
   cd extensions  
   git clone git@github.com:barefootnetworks/p4c-extension-tofino.git tofino  
   git clone git@github.com:barefootnetworks/p4_tests  
   
   cd $WORKSPACE/p4c  
   ./bootstrap.sh  
 3)Compile and run testcases  
    cd build  
    make -j8  
    make -j8 check  

If this last step gives you the error "/usr/bin/make: Argument list too long", you can run tests by running "make -j8 test-suite.log"

Adding a P4 test program:
=========================

When adding a new P4 program (P4_14 or P4_16), remember to check-in the compiler
output files for it. These files are generated when you run the test suite and
you can locate them with `git status`. To generate the output files without
running the entire test suite, you can use the following commands:
  - for a P4_14 program: `ctest -L p14_to_16 -R <prog name>`
  - for a P4_16 program: `ctest -L p4 -R <prog name>`
