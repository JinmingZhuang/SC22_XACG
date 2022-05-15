#include "aie_graph.h"
using namespace adf;

PLIO* in0 = new PLIO("DataIn0", adf::plio_32_bits, "../data/input0.txt",1000);
PLIO* in1 = new PLIO("DataIn1", adf::plio_32_bits, "../data/input1.txt",1000);
PLIO* in2 = new PLIO("DataIn2", adf::plio_32_bits, "../data/input0.txt",1000);
PLIO* in3 = new PLIO("DataIn3", adf::plio_32_bits, "../data/input1.txt",1000);
PLIO* out = new PLIO("DataOut", adf::plio_32_bits, "data/output.txt",1000);

simulation::platform<4, 1> platform(in0, in1, in2, in3, out);

simpleGraph addergraph;

connect<> net0(platform.src[0], addergraph.in0);
connect<> net1(platform.src[1], addergraph.in1);
connect<> net2(platform.src[2], addergraph.in2);
connect<> net3(platform.src[3], addergraph.in3);

connect<> net4(addergraph.out, platform.sink[0]);

#ifdef __AIESIM__
int main(int argc, char** argv) {
    addergraph.init();
    addergraph.run(1);
    addergraph.end();
    return 0;
}
#endif

