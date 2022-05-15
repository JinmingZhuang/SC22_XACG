#ifndef __GRAPH_H__
#define __GRAPH_H__
#include <adf.h>
#include "para.h"
using namespace adf;


template <int COL_OFFSET, int ROW_OFFSET>
class mm_x8_graph : public adf::graph {
private:
	adf::kernel mm_x8 [NUM_ENGINES_PER_PAC];
	adf::pktsplit<4>  sp_a0;
	adf::pktsplit<4>  sp_a1;
	adf::pktsplit<4>  sp_b0;
	adf::pktsplit<4>  sp_b1;

public:
	adf::port<input>  in[4];
  	adf::port<output>  out;

	mm_x8_graph() {
    
		// packet stream to different engines
		sp_a0  = adf::pktsplit<4>::create();
		sp_a1  = adf::pktsplit<4>::create();
		sp_b0  = adf::pktsplit<4>::create();
		sp_b1  = adf::pktsplit<4>::create();
		adf::connect< adf::pktstream > (in[0], sp_a0.in[0]);
		adf::connect< adf::pktstream > (in[1], sp_a1.in[0]);
		adf::connect< adf::pktstream > (in[2], sp_b0.in[0]);
		adf::connect< adf::pktstream > (in[3], sp_b1.in[0]);

		// create NUM_ENGINES_PER_COL get_particles_i and n-body kernels
		for (int row =0; row<NUM_ENGINES_PER_PAC; row++)  {
			if(row==0){
				mm_x8[row]   = adf::kernel::create(mm_kernel0);
				adf::source(mm_x8[row])   = "aie/mm_kernel0.cc";
			}
			else{
				mm_x8[row]   = adf::kernel::create(mm_kernel1);
				adf::source(mm_x8[row])   = "aie/mm_kernel1.cc";
			}
		}
		for (int row =0; row<NUM_ENGINES_PER_PAC; row++)  {
			adf::runtime<ratio>(mm_x8[row]) = 1;
			adf::location<kernel>(mm_x8[row]) = adf::tile(COL_OFFSET,ROW_OFFSET+row);

			if(row<4){
				adf::connect<pktstream, window<h1*w1*4>> (sp_a0.out[row], mm_x8[row].in[0]);
				adf::connect<pktstream, window<w1*w2*4>> (sp_b0.out[row], mm_x8[row].in[1]);
			}
			else{
				adf::connect<pktstream, window<h1*w1*4>> (sp_a1.out[row-4], mm_x8[row].in[0]);
				adf::connect<pktstream, window<w1*w2*4>> (sp_b1.out[row-4], mm_x8[row].in[1]);
			}
			if(row<7){
				adf::connect<window<h1*w2*4>> (mm_x8[row].out[0], mm_x8[row+1].in[2]);
			}
			else{
				adf::connect<window<h1*w2*4>>(mm_x8[row].out[0], out);
			}
		}
		
	};
};

#endif

