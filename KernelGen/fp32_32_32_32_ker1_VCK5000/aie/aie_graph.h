#ifndef __GRAPH_H__
#define __GRAPH_H__

#include <adf.h>
#include "para.h"
using namespace adf;

class simpleGraph : public graph {
   private:
    kernel mm;
    kernel mm1;

   public:
    port<input> in0, in1, in2, in3;
    port<output> out;

    simpleGraph() {
        mm = kernel::create(mm_kernel0);
        mm1 = kernel::create(mm_kernel1);

        connect<window<h1*w1*4>>(in0, mm.in[0]);
        connect<window<w1*w2*4>>(in1, mm.in[1]);
        connect<window<h1*w1*4>>(in2, mm1.in[0]);
        connect<window<w1*w2*4>>(in3, mm1.in[1]);
        connect<window<h1*w2*4>>(mm.out[0], mm1.in[2]);
        connect<window<h1*w2*4>>(mm1.out[0], out);



        source(mm) = "mm_kernel0.cc";
        source(mm1) = "mm_kernel1.cc";
        runtime<ratio>(mm) = 1;
        runtime<ratio>(mm1) = 1;
    };
};

#endif

