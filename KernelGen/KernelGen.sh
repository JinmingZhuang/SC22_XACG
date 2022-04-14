if [ "$#" -eq 1 ] 
then
  	input=../$1;
else
	input="../config_files/input.cfg";
fi

for ((n=1;n<=21;n++));
do
	read -r line
	if (( ${n} == 1 ))
	then
		IFS=':' read -ra Key <<< "$line";
		value_temp="${Key[1]}"; 
		unset IFS
		IFS=';' read -ra Value <<< "$value_temp";
		platform="${Value[0]}"; 
	elif (( ${n} == 3 ))
	then
		IFS=':' read -ra Key <<< "$line";
		value_temp="${Key[1]}"; 
		unset IFS
		IFS=';' read -ra Value <<< "$value_temp";
		data_type="${Value[0]}"; 
	elif (( ${n} == 4 ))
	then
		IFS=':' read -ra Key <<< "$line";
		value_temp="${Key[1]}"; 
		unset IFS
		IFS=';' read -ra Value <<< "$value_temp";
		kernel_type="${Value[0]}";
	elif (( ${n} == 5 ))
	then
		IFS=':' read -ra Key <<< "$line";
		value_temp="${Key[1]}"; 
		unset IFS
		IFS=';' read -ra Value <<< "$value_temp";
		i="${Value[0]}";
	elif (( ${n} == 6 ))
	then
		IFS=':' read -ra Key <<< "$line";
		value_temp="${Key[1]}"; 
		unset IFS
		IFS=';' read -ra Value <<< "$value_temp";
		k="${Value[0]}";
	elif (( ${n} == 7 ))
	then
		IFS=':' read -ra Key <<< "$line";
		value_temp="${Key[1]}"; 
		unset IFS
		IFS=';' read -ra Value <<< "$value_temp";
		j="${Value[0]}";
	elif (( ${n} == 8 ))
	then
		IFS=':' read -ra Key <<< "$line";
		value_temp="${Key[1]}"; 
		unset IFS
		IFS=';' read -ra Value <<< "$value_temp";
		IO_Gen="${Value[0]}";
 	elif (( ${n} == 13 ))
	then
		IFS=':' read -ra Key <<< "$line";
		value_temp="${Key[1]}"; 
		unset IFS
		IFS=';' read -ra Value <<< "$value_temp";
		Sys_Gen="${Value[0]}";
 	elif (( ${n} == 21 ))
	then
		IFS=':' read -ra Key <<< "$line";
		value_temp="${Key[1]}"; 
		unset IFS
		IFS=';' read -ra Value <<< "$value_temp";
		Auto_Gen="${Value[0]}";
 	fi
done < "$input"

if (( ${IO_Gen} == 1 )) || (( ${Sys_Gen} == 1 ))
then
	kernel_type=1;
	i=32;
	j=32;
	k=32;
fi



#read -p "Please input data type(fp32, int32, int16, int8)>>>: " data_type;
if [ ${data_type} != "fp32" ] && [ ${data_type} != "int32" ] && [ ${data_type} != "int16" ] && [ ${data_type} != "int8" ]
then
	echo "
	Please input the following data type fp32, int32, int16, int8
	";
	#read -p "Please input data type>>>: " data_type;
fi

#read -p "Please input single kernel type 0 or 1(0:O=L*R, 1: O=L*R+O_pre)>>>: " kernel_type;
if [ ${kernel_type} != 0 ] && [ ${kernel_type} != 1 ]
then
	echo "
	Please input following single kernel type 0 or 1 (0:O=L*R, 1: O=L*R+O_pre)
	";
	#read -p "
#Please input single kernel type 0 or 1>>>: " kernel_type;
fi
#read -p "Please input single kernel size((i k j))>>>: " i k j;
if [ ${data_type} == "int32" ] || [ ${data_type} == "fp32" ]
then
	let size=${i}*${j}+${j}*${k}+${i}*${k};
	if [ ${size} -gt 4096 ]
	then
		echo "
		${size}=i*k+k*j+i*j should not be more than 4096
		";
		#read -p "
#Please input single kernel size((i k j))>>>: " i k j;
	fi
fi

dir_name="${data_type}_${i}_${k}_${j}_ker${kernel_type}_${platform}";
let enable=1;
for e in ${data_type}_*;
do
	file_name="$e";
	if [[ "$file_name" == "$dir_name" ]]
	then
		echo "
Project $dir_name exsists and can be used in the later steps
		";
		enable=0;
	fi
done

if (( ${enable} == 1 ))
then
mkdir ./${dir_name};
mkdir ./${dir_name}/aie;
cp -r Makefile ./${dir_name};

if [[ "$platform" == "VCK5000" ]] || [[ "$platform" == "vck5000" ]]
then

	echo \
	"source /opt/tools/xilinx/Vitis/2021.2/settings64.sh;
source /opt/xilinx/xrt/setup.sh;

make aiesim PLATFORM_NAME=xilinx_vck5000_gen3x16_xdma_1_202120_1;">> ./${dir_name}/run_aie.sh;
chmod +x ./${dir_name}/run_aie.sh;

elif [[ "$platform" == "VCK190" ]] || [[ "$platform" == "vck190" ]]
then

	echo \
	"VIV_VER=2021.1 SDA_VER=2021.1 . with-sdaccel;

make aiesim PLATFORM_NAME=xilinx_vck190_base_202110_1;">> ./${dir_name}/run_aie.sh;
chmod +x ./${dir_name}/run_aie.sh;
else 
	echo "Specified platform currently is not supported. Please input VCK5000 or VCK190"
fi


sim_name="${data_type}_${i}_${k}_${j}";
if [ "$sim_name" == "int32_32_32_32" ] || [ "$sim_name" == "int32_16_32_32" ] || [ "$sim_name" == "int32_16_16_32" ] || [ "$sim_name" == "int32_8_16_32" ] || [ "$sim_name" == "int32_8_8_32" ] || [ "$sim_name" == "int32_8_8_16" ] || [ "$sim_name" == "int32_8_8_8" ]
then
	din_name="int32_data/${sim_name}_";
elif [ "$sim_name" == "int16_48_48_48" ] || [ "$sim_name" == "int16_32_48_48" ] || [ "$sim_name" == "int16_32_32_48" ] || [ "$sim_name" == "int16_16_32_48" ] || [ "$sim_name" == "int16_16_16_48" ] || [ "$sim_name" == "int16_16_16_32" ] || [ "$sim_name" == "int16_16_16_8" ]
then	
	din_name="int16_data/${sim_name}_";
else
	din_name="data/";
fi



if [ ${data_type} == "int32" ] && [ ${kernel_type} == 0 ]
then
echo \
"#include <adf.h>
#include <stdio.h>
#include "'"para.h"'"
void mm_kernel0(input_window_int32* __restrict matA,
		input_window_int32* __restrict matB,
		output_window_int32* __restrict matC){

	v16int32 buf_matB = undef_v16int32();
	v16int32 buf_matA = undef_v16int32();

	buf_matB = upd_v(buf_matB,0,window_read_v4(matB));
	window_incr(matB,w1);
	buf_matB = upd_v(buf_matB,1,window_read_v4(matB));
	window_decr(matB,w1-4);

	buf_matA=upd_w(buf_matA,0,window_read_v8(matA));
	window_incr(matA,h1);
	
	for (unsigned int i=0;i<boundary_i;i++) 
	chess_prepare_for_pipelining
	chess_loop_range(boundary_i,)
	{	
		
		for (unsigned int j=0;j<boundary_j;j++)
		chess_prepare_for_pipelining
		chess_loop_range(boundary_j,){
			v8acc80 acc0=null_v8acc80();
			v8acc80 acc1=null_v8acc80();
			int jump=h1;
			if (j==judge_j){
				jump=h1+8;
			}
			else{
				jump=h1;
			}
			for (unsigned int k=0;k<boundary_k;k++)
			chess_prepare_for_pipelining
			chess_loop_range(boundary_k,)
			{
				acc0 = lmac8(acc0,buf_matA,0,0x76543210,ext_w(buf_matB,0),0,0x0); 
				buf_matA = upd_w(buf_matA,1,window_read_v8(matA));
				window_incr(matA,h1);
				buf_matB = upd_v(buf_matB,2,window_read_v4(matB));
				window_incr(matB,w1);	
				acc1 = lmac8(acc1,buf_matA,0,0x76543210,ext_w(buf_matB,0),4,0x0); 
				buf_matB = upd_v(buf_matB,3,window_read_v4(matB));
				window_decr(matB,w1-4); 
		
				acc0 = lmac8(acc0,buf_matA,8,0x76543210,ext_w(buf_matB,0),1,0x0); 
				buf_matA = upd_w(buf_matA,0,window_read_v8(matA));
				window_incr(matA,h1);
				acc1 = lmac8(acc1,buf_matA,8,0x76543210,ext_w(buf_matB,0),5,0x0);
			
				acc0 = lmac8(acc0,buf_matA,0,0x76543210,ext_w(buf_matB,0),2,0x0);
				buf_matA = upd_w(buf_matA,1,window_read_v8(matA));
				window_incr(matA,h1);
				acc1 = lmac8(acc1,buf_matA,0,0x76543210,ext_w(buf_matB,0),6,0x0);
		
				acc0 = lmac8(acc0,buf_matA,8,0x76543210,ext_w(buf_matB,0),3,0x0);
				buf_matA = upd_w(buf_matA,0,window_read_v8(matA));
				window_incr(matA,h1);
				acc1 = lmac8(acc1,buf_matA,8,0x76543210,ext_w(buf_matB,0),7,0x0);
		
		
				////////////////////////////////////////////////////////////////////////
				acc0 = lmac8(acc0,buf_matA,0,0x76543210,ext_w(buf_matB,1),0,0x0);
				buf_matA = upd_w(buf_matA,1,window_read_v8(matA));
				window_incr(matA,h1);	
				acc1 = lmac8(acc1,buf_matA,0,0x76543210,ext_w(buf_matB,1),4,0x0);
				
		
				acc0 = lmac8(acc0,buf_matA,8,0x76543210,ext_w(buf_matB,1),1,0x0);
				buf_matA = upd_w(buf_matA,0,window_read_v8(matA));
				window_incr(matA,h1);
				acc1 = lmac8(acc1,buf_matA,8,0x76543210,ext_w(buf_matB,1),5,0x0);
			
				acc0 = lmac8(acc0,buf_matA,0,0x76543210,ext_w(buf_matB,1),2,0x0);
				buf_matA = upd_w(buf_matA,1,window_read_v8(matA));
				window_incr(matA,h1);
				acc1 = lmac8(acc1,buf_matA,0,0x76543210,ext_w(buf_matB,1),6,0x0);
		
				acc0 = lmac8(acc0,buf_matA,8,0x76543210,ext_w(buf_matB,1),3,0x0);
				//window_write(matC,srs(acc0,0));
				//window_incr(matC,h1);
				buf_matA = upd_w(buf_matA,0,window_read_v8(matA));
				window_incr(matA,h1);
				buf_matB = upd_v(buf_matB,0,window_read_v4(matB));
				window_incr(matB,w1);
				acc1 = lmac8(acc1,buf_matA,8,0x76543210,ext_w(buf_matB,1),7,0x0);
				//window_write(matC,srs(acc1,0));
				//window_incr(matC,h1+8);
				buf_matB = upd_v(buf_matB,1,window_read_v4(matB));
				window_decr(matB,w1-4);
			}
			acc0 = lmac8(acc0,buf_matA,0,0x76543210,ext_w(buf_matB,0),0,0x0); 
			buf_matA = upd_w(buf_matA,1,window_read_v8(matA));
			window_incr(matA,h1);
			buf_matB = upd_v(buf_matB,2,window_read_v4(matB));
			window_incr(matB,w1);	
			acc1 = lmac8(acc1,buf_matA,0,0x76543210,ext_w(buf_matB,0),4,0x0); 
			buf_matB = upd_v(buf_matB,3,window_read_v4(matB));
			window_incr(matB,4); 
	
			acc0 = lmac8(acc0,buf_matA,8,0x76543210,ext_w(buf_matB,0),1,0x0); 
			buf_matA = upd_w(buf_matA,0,window_read_v8(matA));
			window_incr(matA,h1);
			acc1 = lmac8(acc1,buf_matA,8,0x76543210,ext_w(buf_matB,0),5,0x0);
		
			acc0 = lmac8(acc0,buf_matA,0,0x76543210,ext_w(buf_matB,0),2,0x0);
			buf_matA = upd_w(buf_matA,1,window_read_v8(matA));
			window_incr(matA,h1);
			acc1 = lmac8(acc1,buf_matA,0,0x76543210,ext_w(buf_matB,0),6,0x0);
	
			acc0 = lmac8(acc0,buf_matA,8,0x76543210,ext_w(buf_matB,0),3,0x0);
			buf_matA = upd_w(buf_matA,0,window_read_v8(matA));
			window_incr(matA,h1);
			acc1 = lmac8(acc1,buf_matA,8,0x76543210,ext_w(buf_matB,0),7,0x0);
	
	
			////////////////////////////////////////////////////////////////////////
			acc0 = lmac8(acc0,buf_matA,0,0x76543210,ext_w(buf_matB,1),0,0x0);
			buf_matA = upd_w(buf_matA,1,window_read_v8(matA));
			window_incr(matA,h1);	
			acc1 = lmac8(acc1,buf_matA,0,0x76543210,ext_w(buf_matB,1),4,0x0);
			
	
			acc0 = lmac8(acc0,buf_matA,8,0x76543210,ext_w(buf_matB,1),1,0x0);
			buf_matA = upd_w(buf_matA,0,window_read_v8(matA));
			window_incr(matA,h1);
			acc1 = lmac8(acc1,buf_matA,8,0x76543210,ext_w(buf_matB,1),5,0x0);
		
			acc0 = lmac8(acc0,buf_matA,0,0x76543210,ext_w(buf_matB,1),2,0x0);
			buf_matA = upd_w(buf_matA,1,window_read_v8(matA));
			window_incr(matA,jump);
			acc1 = lmac8(acc1,buf_matA,0,0x76543210,ext_w(buf_matB,1),6,0x0);
	
			acc0 = lmac8(acc0,buf_matA,8,0x76543210,ext_w(buf_matB,1),3,0x0);
			window_write(matC,srs(acc0,0));
			window_incr(matC,h1);
			buf_matA = upd_w(buf_matA,0,window_read_v8(matA));
			window_incr(matA,h1);
			buf_matB = upd_v(buf_matB,0,window_read_v4(matB));
			window_incr(matB,w1);
			acc1 = lmac8(acc1,buf_matA,8,0x76543210,ext_w(buf_matB,1),7,0x0);
			window_write(matC,srs(acc1,0));
			window_incr(matC,jump);
			buf_matB = upd_v(buf_matB,1,window_read_v4(matB));
			window_decr(matB,w1-4);	
		}
	}
}
">> ./${dir_name}/aie/mm_kernel0.cc;

echo \
"#ifndef __PARA_H__
#define __PARA_H__

#include <adf/stream/types.h>

#define h1 ${i}
#define w1 ${k}
#define w2 ${j}
const int boundary_i=h1/8;
const int boundary_j=w2/2;
const int boundary_k=w1/8-1;
const int judge_j=boundary_j-1;

void mm_kernel0(input_window_int32* matA, input_window_int32* matB, output_window_int32* matC);
#endif
">> ./${dir_name}/aie/para.h;

echo \
"#ifndef __GRAPH_H__
#define __GRAPH_H__

#include <adf.h>
#include "'"para.h"'"
using namespace adf;

class simpleGraph : public graph {
   private:
    kernel mm;

   public:
    port<input> in0, in1;
    port<output> out;

    simpleGraph() {
        mm = kernel::create(mm_kernel0);

        connect<window<h1*w1*4>>(in0, mm.in[0]);
        connect<window<w1*w2*4>>(in1, mm.in[1]);
        connect<window<h1*w2*4>>(mm.out[0], out);


        source(mm) = "'"mm_kernel0.cc"'";

        runtime<ratio>(mm) = 1;
    };
};

#endif
">> ./${dir_name}/aie/aie_graph.h;

echo \
"#include "'"aie_graph.h"'"
using namespace adf;

PLIO* in0 = new PLIO("'"DataIn0"'", adf::plio_32_bits, \"../${din_name}input0.txt\",1000);
PLIO* in1 = new PLIO("'"DataIn1"'", adf::plio_32_bits, \"../${din_name}input1.txt\",1000);
PLIO* out = new PLIO("'"DataOut"'", adf::plio_32_bits, "'"data/output.txt"'",1000);

simulation::platform<2, 1> platform(in0, in1, out);

simpleGraph addergraph;

connect<> net0(platform.src[0], addergraph.in0);
connect<> net1(platform.src[1], addergraph.in1);

connect<> net2(addergraph.out, platform.sink[0]);

#ifdef __AIESIM__
int main(int argc, char** argv) {
    addergraph.init();
    addergraph.run(1);
    addergraph.end();
    return 0;
}
#endif
">> ./${dir_name}/aie/aie_graph.cpp;

elif [ ${data_type} == "int32" ] && [ ${kernel_type} == 1 ]
then

echo \
"#include <adf.h>
#include <stdio.h>
#include "'"para.h"'"
void mm_kernel0(input_window_int32* __restrict matA,
		input_window_int32* __restrict matB,
		output_window_int32* __restrict matC){

	v16int32 buf_matB = undef_v16int32();
	v16int32 buf_matA = undef_v16int32();

	buf_matB = upd_v(buf_matB,0,window_read_v4(matB));
	window_incr(matB,w1);
	buf_matB = upd_v(buf_matB,1,window_read_v4(matB));
	window_decr(matB,w1-4);

	buf_matA=upd_w(buf_matA,0,window_read_v8(matA));
	window_incr(matA,h1);
	
	for (unsigned int i=0;i<boundary_i;i++) 
	chess_prepare_for_pipelining
	chess_loop_range(boundary_i,)
	{	
		
		for (unsigned int j=0;j<boundary_j;j++)
		chess_prepare_for_pipelining
		chess_loop_range(boundary_j,){
			v8acc80 acc0=null_v8acc80();
			v8acc80 acc1=null_v8acc80();
			int jump=h1;
			if (j==judge_j){
				jump=h1+8;
			}
			else{
				jump=h1;
			}
			for (unsigned int k=0;k<boundary_k;k++)
			chess_prepare_for_pipelining
			chess_loop_range(boundary_k,)
			{
				acc0 = lmac8(acc0,buf_matA,0,0x76543210,ext_w(buf_matB,0),0,0x0); 
				buf_matA = upd_w(buf_matA,1,window_read_v8(matA));
				window_incr(matA,h1);
				buf_matB = upd_v(buf_matB,2,window_read_v4(matB));
				window_incr(matB,w1);	
				acc1 = lmac8(acc1,buf_matA,0,0x76543210,ext_w(buf_matB,0),4,0x0); 
				buf_matB = upd_v(buf_matB,3,window_read_v4(matB));
				window_decr(matB,w1-4); 
		
				acc0 = lmac8(acc0,buf_matA,8,0x76543210,ext_w(buf_matB,0),1,0x0); 
				buf_matA = upd_w(buf_matA,0,window_read_v8(matA));
				window_incr(matA,h1);
				acc1 = lmac8(acc1,buf_matA,8,0x76543210,ext_w(buf_matB,0),5,0x0);
			
				acc0 = lmac8(acc0,buf_matA,0,0x76543210,ext_w(buf_matB,0),2,0x0);
				buf_matA = upd_w(buf_matA,1,window_read_v8(matA));
				window_incr(matA,h1);
				acc1 = lmac8(acc1,buf_matA,0,0x76543210,ext_w(buf_matB,0),6,0x0);
		
				acc0 = lmac8(acc0,buf_matA,8,0x76543210,ext_w(buf_matB,0),3,0x0);
				buf_matA = upd_w(buf_matA,0,window_read_v8(matA));
				window_incr(matA,h1);
				acc1 = lmac8(acc1,buf_matA,8,0x76543210,ext_w(buf_matB,0),7,0x0);
		
		
				////////////////////////////////////////////////////////////////////////
				acc0 = lmac8(acc0,buf_matA,0,0x76543210,ext_w(buf_matB,1),0,0x0);
				buf_matA = upd_w(buf_matA,1,window_read_v8(matA));
				window_incr(matA,h1);	
				acc1 = lmac8(acc1,buf_matA,0,0x76543210,ext_w(buf_matB,1),4,0x0);
				
		
				acc0 = lmac8(acc0,buf_matA,8,0x76543210,ext_w(buf_matB,1),1,0x0);
				buf_matA = upd_w(buf_matA,0,window_read_v8(matA));
				window_incr(matA,h1);
				acc1 = lmac8(acc1,buf_matA,8,0x76543210,ext_w(buf_matB,1),5,0x0);
			
				acc0 = lmac8(acc0,buf_matA,0,0x76543210,ext_w(buf_matB,1),2,0x0);
				buf_matA = upd_w(buf_matA,1,window_read_v8(matA));
				window_incr(matA,h1);
				acc1 = lmac8(acc1,buf_matA,0,0x76543210,ext_w(buf_matB,1),6,0x0);
		
				acc0 = lmac8(acc0,buf_matA,8,0x76543210,ext_w(buf_matB,1),3,0x0);
				//window_write(matC,srs(acc0,0));
				//window_incr(matC,h1);
				buf_matA = upd_w(buf_matA,0,window_read_v8(matA));
				window_incr(matA,h1);
				buf_matB = upd_v(buf_matB,0,window_read_v4(matB));
				window_incr(matB,w1);
				acc1 = lmac8(acc1,buf_matA,8,0x76543210,ext_w(buf_matB,1),7,0x0);
				//window_write(matC,srs(acc1,0));
				//window_incr(matC,h1+8);
				buf_matB = upd_v(buf_matB,1,window_read_v4(matB));
				window_decr(matB,w1-4);
			}
			acc0 = lmac8(acc0,buf_matA,0,0x76543210,ext_w(buf_matB,0),0,0x0); 
			buf_matA = upd_w(buf_matA,1,window_read_v8(matA));
			window_incr(matA,h1);
			buf_matB = upd_v(buf_matB,2,window_read_v4(matB));
			window_incr(matB,w1);	
			acc1 = lmac8(acc1,buf_matA,0,0x76543210,ext_w(buf_matB,0),4,0x0); 
			buf_matB = upd_v(buf_matB,3,window_read_v4(matB));
			window_incr(matB,4); 
	
			acc0 = lmac8(acc0,buf_matA,8,0x76543210,ext_w(buf_matB,0),1,0x0); 
			buf_matA = upd_w(buf_matA,0,window_read_v8(matA));
			window_incr(matA,h1);
			acc1 = lmac8(acc1,buf_matA,8,0x76543210,ext_w(buf_matB,0),5,0x0);
		
			acc0 = lmac8(acc0,buf_matA,0,0x76543210,ext_w(buf_matB,0),2,0x0);
			buf_matA = upd_w(buf_matA,1,window_read_v8(matA));
			window_incr(matA,h1);
			acc1 = lmac8(acc1,buf_matA,0,0x76543210,ext_w(buf_matB,0),6,0x0);
	
			acc0 = lmac8(acc0,buf_matA,8,0x76543210,ext_w(buf_matB,0),3,0x0);
			buf_matA = upd_w(buf_matA,0,window_read_v8(matA));
			window_incr(matA,h1);
			acc1 = lmac8(acc1,buf_matA,8,0x76543210,ext_w(buf_matB,0),7,0x0);
	
	
			////////////////////////////////////////////////////////////////////////
			acc0 = lmac8(acc0,buf_matA,0,0x76543210,ext_w(buf_matB,1),0,0x0);
			buf_matA = upd_w(buf_matA,1,window_read_v8(matA));
			window_incr(matA,h1);	
			acc1 = lmac8(acc1,buf_matA,0,0x76543210,ext_w(buf_matB,1),4,0x0);
			
	
			acc0 = lmac8(acc0,buf_matA,8,0x76543210,ext_w(buf_matB,1),1,0x0);
			buf_matA = upd_w(buf_matA,0,window_read_v8(matA));
			window_incr(matA,h1);
			acc1 = lmac8(acc1,buf_matA,8,0x76543210,ext_w(buf_matB,1),5,0x0);
		
			acc0 = lmac8(acc0,buf_matA,0,0x76543210,ext_w(buf_matB,1),2,0x0);
			buf_matA = upd_w(buf_matA,1,window_read_v8(matA));
			window_incr(matA,jump);
			acc1 = lmac8(acc1,buf_matA,0,0x76543210,ext_w(buf_matB,1),6,0x0);
	
			acc0 = lmac8(acc0,buf_matA,8,0x76543210,ext_w(buf_matB,1),3,0x0);
			window_write(matC,srs(acc0,0));
			window_incr(matC,h1);
			buf_matA = upd_w(buf_matA,0,window_read_v8(matA));
			window_incr(matA,h1);
			buf_matB = upd_v(buf_matB,0,window_read_v4(matB));
			window_incr(matB,w1);
			acc1 = lmac8(acc1,buf_matA,8,0x76543210,ext_w(buf_matB,1),7,0x0);
			window_write(matC,srs(acc1,0));
			window_incr(matC,jump);
			buf_matB = upd_v(buf_matB,1,window_read_v4(matB));
			window_decr(matB,w1-4);	
		}
	}
}
">> ./${dir_name}/aie/mm_kernel0.cc;

echo \
"#include <adf.h>
#include <stdio.h>
#include "'"para.h"'"
void mm_kernel1(input_window_int32* __restrict matA,
		input_window_int32* __restrict matB,
		input_window_int32* __restrict acc_in,
		output_window_int32* __restrict matC){

	v8acc80 acc0=null_v8acc80();//For first output column
	v8acc80 acc1=null_v8acc80();//For second output column
	v16int32 buf_matB = undef_v16int32();
	v16int32 buf_matA = undef_v16int32();

	buf_matB = upd_v(buf_matB,0,window_read_v4(matB));
	window_incr(matB,w1);
	buf_matB = upd_v(buf_matB,1,window_read_v4(matB));
	window_decr(matB,w1-4);

	buf_matA=upd_w(buf_matA,0,window_read_v8(matA));
	window_incr(matA,h1);
	
	//v8acc80 acc0=null_v8acc80();//For first output column
	//v8acc80 acc1=null_v8acc80();//For second output column
	for (unsigned int i=0;i<boundary_i;i++) 
	chess_prepare_for_pipelining
	chess_loop_range(boundary_i,)
	{	

		for (unsigned int j=0;j<boundary_j;j++)
		chess_prepare_for_pipelining
		chess_loop_range(boundary_j,){
			int jump=h1;
			if (j==judge_j){
				jump=h1+8;
			}
			else{
				jump=h1;
			}
			acc0=lups(window_read_v8(acc_in),0);
			window_incr(acc_in,h1);
			acc1=lups(window_read_v8(acc_in),0);
			window_incr(acc_in,jump);
			for (unsigned int k=0;k<boundary_k;k++)
			chess_prepare_for_pipelining
			chess_loop_range(boundary_k,)
			{
				acc0 = lmac8(acc0,buf_matA,0,0x76543210,ext_w(buf_matB,0),0,0x0); 
				buf_matA = upd_w(buf_matA,1,window_read_v8(matA));
				window_incr(matA,h1);
				buf_matB = upd_v(buf_matB,2,window_read_v4(matB));
				window_incr(matB,w1);	
				acc1 = lmac8(acc1,buf_matA,0,0x76543210,ext_w(buf_matB,0),4,0x0); 
				buf_matB = upd_v(buf_matB,3,window_read_v4(matB));
				window_decr(matB,w1-4); 
		
				acc0 = lmac8(acc0,buf_matA,8,0x76543210,ext_w(buf_matB,0),1,0x0); 
				buf_matA = upd_w(buf_matA,0,window_read_v8(matA));
				window_incr(matA,h1);
				acc1 = lmac8(acc1,buf_matA,8,0x76543210,ext_w(buf_matB,0),5,0x0);
			
				acc0 = lmac8(acc0,buf_matA,0,0x76543210,ext_w(buf_matB,0),2,0x0);
				buf_matA = upd_w(buf_matA,1,window_read_v8(matA));
				window_incr(matA,h1);
				acc1 = lmac8(acc1,buf_matA,0,0x76543210,ext_w(buf_matB,0),6,0x0);
		
				acc0 = lmac8(acc0,buf_matA,8,0x76543210,ext_w(buf_matB,0),3,0x0);
				buf_matA = upd_w(buf_matA,0,window_read_v8(matA));
				window_incr(matA,h1);
				acc1 = lmac8(acc1,buf_matA,8,0x76543210,ext_w(buf_matB,0),7,0x0);
		
		
				////////////////////////////////////////////////////////////////////////
				acc0 = lmac8(acc0,buf_matA,0,0x76543210,ext_w(buf_matB,1),0,0x0);
				buf_matA = upd_w(buf_matA,1,window_read_v8(matA));
				window_incr(matA,h1);	
				acc1 = lmac8(acc1,buf_matA,0,0x76543210,ext_w(buf_matB,1),4,0x0);
				
		
				acc0 = lmac8(acc0,buf_matA,8,0x76543210,ext_w(buf_matB,1),1,0x0);
				buf_matA = upd_w(buf_matA,0,window_read_v8(matA));
				window_incr(matA,h1);
				acc1 = lmac8(acc1,buf_matA,8,0x76543210,ext_w(buf_matB,1),5,0x0);
			
				acc0 = lmac8(acc0,buf_matA,0,0x76543210,ext_w(buf_matB,1),2,0x0);
				buf_matA = upd_w(buf_matA,1,window_read_v8(matA));
				window_incr(matA,h1);
				acc1 = lmac8(acc1,buf_matA,0,0x76543210,ext_w(buf_matB,1),6,0x0);
		
				acc0 = lmac8(acc0,buf_matA,8,0x76543210,ext_w(buf_matB,1),3,0x0);
				//window_write(matC,srs(acc0,0));
				//window_incr(matC,h1);
				buf_matA = upd_w(buf_matA,0,window_read_v8(matA));
				window_incr(matA,h1);
				buf_matB = upd_v(buf_matB,0,window_read_v4(matB));
				window_incr(matB,w1);
				acc1 = lmac8(acc1,buf_matA,8,0x76543210,ext_w(buf_matB,1),7,0x0);
				//window_write(matC,srs(acc1,0));
				//window_incr(matC,h1+8);
				buf_matB = upd_v(buf_matB,1,window_read_v4(matB));
				window_decr(matB,w1-4);
			}
			acc0 = lmac8(acc0,buf_matA,0,0x76543210,ext_w(buf_matB,0),0,0x0); 
			buf_matA = upd_w(buf_matA,1,window_read_v8(matA));
			window_incr(matA,h1);
			buf_matB = upd_v(buf_matB,2,window_read_v4(matB));
			window_incr(matB,w1);	
			acc1 = lmac8(acc1,buf_matA,0,0x76543210,ext_w(buf_matB,0),4,0x0); 
			buf_matB = upd_v(buf_matB,3,window_read_v4(matB));
			window_incr(matB,4); 
	
			acc0 = lmac8(acc0,buf_matA,8,0x76543210,ext_w(buf_matB,0),1,0x0); 
			buf_matA = upd_w(buf_matA,0,window_read_v8(matA));
			window_incr(matA,h1);
			acc1 = lmac8(acc1,buf_matA,8,0x76543210,ext_w(buf_matB,0),5,0x0);
		
			acc0 = lmac8(acc0,buf_matA,0,0x76543210,ext_w(buf_matB,0),2,0x0);
			buf_matA = upd_w(buf_matA,1,window_read_v8(matA));
			window_incr(matA,h1);
			acc1 = lmac8(acc1,buf_matA,0,0x76543210,ext_w(buf_matB,0),6,0x0);
	
			acc0 = lmac8(acc0,buf_matA,8,0x76543210,ext_w(buf_matB,0),3,0x0);
			buf_matA = upd_w(buf_matA,0,window_read_v8(matA));
			window_incr(matA,h1);
			acc1 = lmac8(acc1,buf_matA,8,0x76543210,ext_w(buf_matB,0),7,0x0);
	
	
			////////////////////////////////////////////////////////////////////////
			acc0 = lmac8(acc0,buf_matA,0,0x76543210,ext_w(buf_matB,1),0,0x0);
			buf_matA = upd_w(buf_matA,1,window_read_v8(matA));
			window_incr(matA,h1);	
			acc1 = lmac8(acc1,buf_matA,0,0x76543210,ext_w(buf_matB,1),4,0x0);
			
	
			acc0 = lmac8(acc0,buf_matA,8,0x76543210,ext_w(buf_matB,1),1,0x0);
			buf_matA = upd_w(buf_matA,0,window_read_v8(matA));
			window_incr(matA,h1);
			acc1 = lmac8(acc1,buf_matA,8,0x76543210,ext_w(buf_matB,1),5,0x0);
		
			acc0 = lmac8(acc0,buf_matA,0,0x76543210,ext_w(buf_matB,1),2,0x0);
			buf_matA = upd_w(buf_matA,1,window_read_v8(matA));
			window_incr(matA,jump);
			acc1 = lmac8(acc1,buf_matA,0,0x76543210,ext_w(buf_matB,1),6,0x0);
	
			acc0 = lmac8(acc0,buf_matA,8,0x76543210,ext_w(buf_matB,1),3,0x0);
			window_write(matC,srs(acc0,0));
			window_incr(matC,h1);
			buf_matA = upd_w(buf_matA,0,window_read_v8(matA));
			window_incr(matA,h1);
			buf_matB = upd_v(buf_matB,0,window_read_v4(matB));
			window_incr(matB,w1);
			acc1 = lmac8(acc1,buf_matA,8,0x76543210,ext_w(buf_matB,1),7,0x0);
			window_write(matC,srs(acc1,0));
			window_incr(matC,jump);
			buf_matB = upd_v(buf_matB,1,window_read_v4(matB));
			window_decr(matB,w1-4);	

			
		}
	}
}
">> ./${dir_name}/aie/mm_kernel1.cc;


echo \
"#ifndef __PARA_H__
#define __PARA_H__

#include <adf/stream/types.h>

#define h1 ${i}
#define w1 ${k}
#define w2 ${j}
const int boundary_i=h1/8;
const int boundary_j=w2/2;
const int boundary_k=w1/8-1;
const int judge_j=boundary_j-1;

void mm_kernel0(input_window_int32* matA, input_window_int32* matB, output_window_int32* matC);
void mm_kernel1(input_window_int32* matA, input_window_int32* matB, input_window_int32* acc_in, output_window_int32* matC);
#endif
">> ./${dir_name}/aie/para.h;

echo \
"#ifndef __GRAPH_H__
#define __GRAPH_H__

#include <adf.h>
#include "'"para.h"'"
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



        source(mm) = "'"mm_kernel0.cc"'";
        source(mm1) = "'"mm_kernel1.cc"'";
        runtime<ratio>(mm) = 1;
        runtime<ratio>(mm1) = 1;
    };
};

#endif
">> ./${dir_name}/aie/aie_graph.h;
echo \
"#include "'"aie_graph.h"'"
using namespace adf;

PLIO* in0 = new PLIO("'"DataIn0"'", adf::plio_32_bits, \"../${din_name}input0.txt\",1000);
PLIO* in1 = new PLIO("'"DataIn1"'", adf::plio_32_bits, \"../${din_name}input1.txt\",1000);
PLIO* in2 = new PLIO("'"DataIn2"'", adf::plio_32_bits, \"../${din_name}input0.txt\",1000);
PLIO* in3 = new PLIO("'"DataIn3"'", adf::plio_32_bits, \"../${din_name}input1.txt\",1000);
PLIO* out = new PLIO("'"DataOut"'", adf::plio_32_bits, "'"data/output.txt"'",1000);

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
">> ./${dir_name}/aie/aie_graph.cpp;

elif [ ${data_type} == "fp32" ] && [ ${kernel_type} == 0 ]
then
	echo \
"#include <adf.h>
#include <stdio.h>
#include \"para.h\"
void mm_kernel0(input_window_float* __restrict matA,
		input_window_float* __restrict matB,
		output_window_float* __restrict matC){

	v16float buf_matB = undef_v16float();
	v16float buf_matA = undef_v16float();

	buf_matB = upd_v(buf_matB,0,window_read_v4(matB));
	window_incr(matB,w1);
	buf_matB = upd_v(buf_matB,1,window_read_v4(matB));
	window_decr(matB,w1-4);

	buf_matA=upd_w(buf_matA,0,window_read_v8(matA));
	window_incr(matA,h1);
	
	//v8float  acc0=undef_v8float();//For first output column
	//v8float  acc1=undef_v8float();//For second output column
	for (unsigned int i=0;i<boundary_i;i++) 
	chess_prepare_for_pipelining
	chess_loop_range(boundary_i,)
	{	
		
		for (unsigned int j=0;j<boundary_j;j++)
		chess_prepare_for_pipelining
		chess_loop_range(boundary_j,){
			v8float  acc0=null_v8float();//For first output column
			v8float  acc1=null_v8float();//For second output column
			int jump=h1;
			if (j==judge_j){
				if(i==judge_i){
					jump=8;
				}
				else{
					jump=h1+8;
				}
			}
			else{
				jump=h1;
			}
			for (unsigned int k=0;k<boundary_k;k++)
			chess_prepare_for_pipelining
			chess_loop_range(boundary_k,)
			{
				acc0 = fpmac(acc0,buf_matA,0,0x76543210,ext_w(buf_matB,0),0,0x0); 
				buf_matA = upd_w(buf_matA,1,window_read_v8(matA));
				window_incr(matA,h1);
				buf_matB = upd_v(buf_matB,2,window_read_v4(matB));
				window_incr(matB,w1);	
				acc1 = fpmac(acc1,buf_matA,0,0x76543210,ext_w(buf_matB,0),4,0x0); 
				buf_matB = upd_v(buf_matB,3,window_read_v4(matB));
				window_decr(matB,w1-4); 
		
				acc0 = fpmac(acc0,buf_matA,8,0x76543210,ext_w(buf_matB,0),1,0x0); 
				buf_matA = upd_w(buf_matA,0,window_read_v8(matA));
				window_incr(matA,h1);
				acc1 = fpmac(acc1,buf_matA,8,0x76543210,ext_w(buf_matB,0),5,0x0);
			
				acc0 = fpmac(acc0,buf_matA,0,0x76543210,ext_w(buf_matB,0),2,0x0);
				buf_matA = upd_w(buf_matA,1,window_read_v8(matA));
				window_incr(matA,h1);
				acc1 = fpmac(acc1,buf_matA,0,0x76543210,ext_w(buf_matB,0),6,0x0);
		
				acc0 = fpmac(acc0,buf_matA,8,0x76543210,ext_w(buf_matB,0),3,0x0);
				buf_matA = upd_w(buf_matA,0,window_read_v8(matA));
				window_incr(matA,h1);
				acc1 = fpmac(acc1,buf_matA,8,0x76543210,ext_w(buf_matB,0),7,0x0);
		
		
				////////////////////////////////////////////////////////////////////////
				acc0 = fpmac(acc0,buf_matA,0,0x76543210,ext_w(buf_matB,1),0,0x0);
				buf_matA = upd_w(buf_matA,1,window_read_v8(matA));
				window_incr(matA,h1);	
				acc1 = fpmac(acc1,buf_matA,0,0x76543210,ext_w(buf_matB,1),4,0x0);
				
		
				acc0 = fpmac(acc0,buf_matA,8,0x76543210,ext_w(buf_matB,1),1,0x0);
				buf_matA = upd_w(buf_matA,0,window_read_v8(matA));
				window_incr(matA,h1);
				acc1 = fpmac(acc1,buf_matA,8,0x76543210,ext_w(buf_matB,1),5,0x0);
			
				acc0 = fpmac(acc0,buf_matA,0,0x76543210,ext_w(buf_matB,1),2,0x0);
				buf_matA = upd_w(buf_matA,1,window_read_v8(matA));
				window_incr(matA,h1);
				acc1 = fpmac(acc1,buf_matA,0,0x76543210,ext_w(buf_matB,1),6,0x0);
		
				acc0 = fpmac(acc0,buf_matA,8,0x76543210,ext_w(buf_matB,1),3,0x0);
				buf_matA = upd_w(buf_matA,0,window_read_v8(matA));
				window_incr(matA,h1);
				buf_matB = upd_v(buf_matB,0,window_read_v4(matB));
				window_incr(matB,w1);
				acc1 = fpmac(acc1,buf_matA,8,0x76543210,ext_w(buf_matB,1),7,0x0);
				buf_matB = upd_v(buf_matB,1,window_read_v4(matB));
				window_decr(matB,w1-4);
			}
			acc0 = fpmac(acc0,buf_matA,0,0x76543210,ext_w(buf_matB,0),0,0x0); 
			buf_matA = upd_w(buf_matA,1,window_read_v8(matA));
			window_incr(matA,h1);
			buf_matB = upd_v(buf_matB,2,window_read_v4(matB));
			window_incr(matB,w1);	
			acc1 = fpmac(acc1,buf_matA,0,0x76543210,ext_w(buf_matB,0),4,0x0); 
			buf_matB = upd_v(buf_matB,3,window_read_v4(matB));
			window_incr(matB,4); 
	
			acc0 = fpmac(acc0,buf_matA,8,0x76543210,ext_w(buf_matB,0),1,0x0); 
			buf_matA = upd_w(buf_matA,0,window_read_v8(matA));
			window_incr(matA,h1);
			acc1 = fpmac(acc1,buf_matA,8,0x76543210,ext_w(buf_matB,0),5,0x0);
		
			acc0 = fpmac(acc0,buf_matA,0,0x76543210,ext_w(buf_matB,0),2,0x0);
			buf_matA = upd_w(buf_matA,1,window_read_v8(matA));
			window_incr(matA,h1);
			acc1 = fpmac(acc1,buf_matA,0,0x76543210,ext_w(buf_matB,0),6,0x0);
	
			acc0 = fpmac(acc0,buf_matA,8,0x76543210,ext_w(buf_matB,0),3,0x0);
			buf_matA = upd_w(buf_matA,0,window_read_v8(matA));
			window_incr(matA,h1);
			acc1 = fpmac(acc1,buf_matA,8,0x76543210,ext_w(buf_matB,0),7,0x0);
	
	
			////////////////////////////////////////////////////////////////////////
			acc0 = fpmac(acc0,buf_matA,0,0x76543210,ext_w(buf_matB,1),0,0x0);
			buf_matA = upd_w(buf_matA,1,window_read_v8(matA));
			window_incr(matA,h1);	
			acc1 = fpmac(acc1,buf_matA,0,0x76543210,ext_w(buf_matB,1),4,0x0);
			
	
			acc0 = fpmac(acc0,buf_matA,8,0x76543210,ext_w(buf_matB,1),1,0x0);
			buf_matA = upd_w(buf_matA,0,window_read_v8(matA));
			window_incr(matA,h1);
			acc1 = fpmac(acc1,buf_matA,8,0x76543210,ext_w(buf_matB,1),5,0x0);
		
			acc0 = fpmac(acc0,buf_matA,0,0x76543210,ext_w(buf_matB,1),2,0x0);
			buf_matA = upd_w(buf_matA,1,window_read_v8(matA));
			window_incr(matA,jump);
			acc1 = fpmac(acc1,buf_matA,0,0x76543210,ext_w(buf_matB,1),6,0x0);
	
			acc0 = fpmac(acc0,buf_matA,8,0x76543210,ext_w(buf_matB,1),3,0x0);
			window_write(matC,acc0);
			window_incr(matC,h1);
			buf_matA = upd_w(buf_matA,0,window_read_v8(matA));
			window_incr(matA,h1);
			buf_matB = upd_v(buf_matB,0,window_read_v4(matB));
			window_incr(matB,w1);
			acc1 = fpmac(acc1,buf_matA,8,0x76543210,ext_w(buf_matB,1),7,0x0);
			window_write(matC,acc1);
			window_incr(matC,jump);
			buf_matB = upd_v(buf_matB,1,window_read_v4(matB));
			window_decr(matB,w1-4);	
		}
	}
}
">> ./${dir_name}/aie/mm_kernel0.cc;

echo \
"#ifndef __PARA_H__
#define __PARA_H__

#include <adf/stream/types.h>

#define h1 ${i}
#define w1 ${k}
#define w2 ${j}
const int boundary_i=h1/8;
const int boundary_j=w2/2;
const int boundary_k=w1/8-1;
const int judge_i=boundary_i-1;
const int judge_j=boundary_j-1;
void mm_kernel0(input_window_float* matA, input_window_float* matB, output_window_float* matC);

#endif
">> ./${dir_name}/aie/para.h;

echo \
"#ifndef __GRAPH_H__
#define __GRAPH_H__

#include <adf.h>
#include \"para.h\"
using namespace adf;

class simpleGraph : public graph {
   private:
    kernel mm;

   public:
    port<input> in0, in1;
    port<output> out;

    simpleGraph() {
        mm = kernel::create(mm_kernel0);

        connect<window<h1*w1*4>>(in0, mm.in[0]);
        connect<window<w1*w2*4>>(in1, mm.in[1]);
        connect<window<h1*w2*4>>(mm.out[0], out);


        source(mm) = \"mm_kernel0.cc\";

        runtime<ratio>(mm) = 1;
    };
};

#endif
">> ./${dir_name}/aie/aie_graph.h;

echo \
"#include \"aie_graph.h\"
using namespace adf;

PLIO* in0 = new PLIO(\"DataIn0\", adf::plio_32_bits, \"../${din_name}input0.txt\",1000);
PLIO* in1 = new PLIO(\"DataIn1\", adf::plio_32_bits, \"../${din_name}input1.txt\",1000);
PLIO* out = new PLIO(\"DataOut\", adf::plio_32_bits, \"data/output.txt\",1000);

simulation::platform<2, 1> platform(in0, in1, out);

simpleGraph addergraph;

connect<> net0(platform.src[0], addergraph.in0);
connect<> net1(platform.src[1], addergraph.in1);

connect<> net2(addergraph.out, platform.sink[0]);

#ifdef __AIESIM__
int main(int argc, char** argv) {
    addergraph.init();
    addergraph.run(1);
    addergraph.end();
    return 0;
}
#endif
">> ./${dir_name}/aie/aie_graph.cpp;

elif [ ${data_type} == "fp32" ] && [ ${kernel_type} == 1 ]
then
echo \
"#include <adf.h>
#include <stdio.h>
#include \"para.h\"
void mm_kernel0(input_window_float* __restrict matA,
		input_window_float* __restrict matB,
		output_window_float* __restrict matC){

	v16float buf_matB = undef_v16float();
	v16float buf_matA = undef_v16float();

	buf_matB = upd_v(buf_matB,0,window_read_v4(matB));
	window_incr(matB,w1);
	buf_matB = upd_v(buf_matB,1,window_read_v4(matB));
	window_decr(matB,w1-4);

	buf_matA=upd_w(buf_matA,0,window_read_v8(matA));
	window_incr(matA,h1);
	
	//v8float  acc0=undef_v8float();//For first output column
	//v8float  acc1=undef_v8float();//For second output column
	for (unsigned int i=0;i<boundary_i;i++) 
	chess_prepare_for_pipelining
	chess_loop_range(boundary_i,)
	{	
		
		for (unsigned int j=0;j<boundary_j;j++)
		chess_prepare_for_pipelining
		chess_loop_range(boundary_j,){
			v8float  acc0=null_v8float();//For first output column
			v8float  acc1=null_v8float();//For second output column
			int jump=h1;
			if (j==judge_j){
				if(i==judge_i){
					jump=8;
				}
				else{
					jump=h1+8;
				}
			}
			else{
				jump=h1;
			}
			for (unsigned int k=0;k<boundary_k;k++)
			chess_prepare_for_pipelining
			chess_loop_range(boundary_k,)
			{
				acc0 = fpmac(acc0,buf_matA,0,0x76543210,ext_w(buf_matB,0),0,0x0); 
				buf_matA = upd_w(buf_matA,1,window_read_v8(matA));
				window_incr(matA,h1);
				buf_matB = upd_v(buf_matB,2,window_read_v4(matB));
				window_incr(matB,w1);	
				acc1 = fpmac(acc1,buf_matA,0,0x76543210,ext_w(buf_matB,0),4,0x0); 
				buf_matB = upd_v(buf_matB,3,window_read_v4(matB));
				window_decr(matB,w1-4); 
		
				acc0 = fpmac(acc0,buf_matA,8,0x76543210,ext_w(buf_matB,0),1,0x0); 
				buf_matA = upd_w(buf_matA,0,window_read_v8(matA));
				window_incr(matA,h1);
				acc1 = fpmac(acc1,buf_matA,8,0x76543210,ext_w(buf_matB,0),5,0x0);
			
				acc0 = fpmac(acc0,buf_matA,0,0x76543210,ext_w(buf_matB,0),2,0x0);
				buf_matA = upd_w(buf_matA,1,window_read_v8(matA));
				window_incr(matA,h1);
				acc1 = fpmac(acc1,buf_matA,0,0x76543210,ext_w(buf_matB,0),6,0x0);
		
				acc0 = fpmac(acc0,buf_matA,8,0x76543210,ext_w(buf_matB,0),3,0x0);
				buf_matA = upd_w(buf_matA,0,window_read_v8(matA));
				window_incr(matA,h1);
				acc1 = fpmac(acc1,buf_matA,8,0x76543210,ext_w(buf_matB,0),7,0x0);
		
		
				////////////////////////////////////////////////////////////////////////
				acc0 = fpmac(acc0,buf_matA,0,0x76543210,ext_w(buf_matB,1),0,0x0);
				buf_matA = upd_w(buf_matA,1,window_read_v8(matA));
				window_incr(matA,h1);	
				acc1 = fpmac(acc1,buf_matA,0,0x76543210,ext_w(buf_matB,1),4,0x0);
				
		
				acc0 = fpmac(acc0,buf_matA,8,0x76543210,ext_w(buf_matB,1),1,0x0);
				buf_matA = upd_w(buf_matA,0,window_read_v8(matA));
				window_incr(matA,h1);
				acc1 = fpmac(acc1,buf_matA,8,0x76543210,ext_w(buf_matB,1),5,0x0);
			
				acc0 = fpmac(acc0,buf_matA,0,0x76543210,ext_w(buf_matB,1),2,0x0);
				buf_matA = upd_w(buf_matA,1,window_read_v8(matA));
				window_incr(matA,h1);
				acc1 = fpmac(acc1,buf_matA,0,0x76543210,ext_w(buf_matB,1),6,0x0);
		
				acc0 = fpmac(acc0,buf_matA,8,0x76543210,ext_w(buf_matB,1),3,0x0);
				buf_matA = upd_w(buf_matA,0,window_read_v8(matA));
				window_incr(matA,h1);
				buf_matB = upd_v(buf_matB,0,window_read_v4(matB));
				window_incr(matB,w1);
				acc1 = fpmac(acc1,buf_matA,8,0x76543210,ext_w(buf_matB,1),7,0x0);
				buf_matB = upd_v(buf_matB,1,window_read_v4(matB));
				window_decr(matB,w1-4);
			}
			acc0 = fpmac(acc0,buf_matA,0,0x76543210,ext_w(buf_matB,0),0,0x0); 
			buf_matA = upd_w(buf_matA,1,window_read_v8(matA));
			window_incr(matA,h1);
			buf_matB = upd_v(buf_matB,2,window_read_v4(matB));
			window_incr(matB,w1);	
			acc1 = fpmac(acc1,buf_matA,0,0x76543210,ext_w(buf_matB,0),4,0x0); 
			buf_matB = upd_v(buf_matB,3,window_read_v4(matB));
			window_incr(matB,4); 
	
			acc0 = fpmac(acc0,buf_matA,8,0x76543210,ext_w(buf_matB,0),1,0x0); 
			buf_matA = upd_w(buf_matA,0,window_read_v8(matA));
			window_incr(matA,h1);
			acc1 = fpmac(acc1,buf_matA,8,0x76543210,ext_w(buf_matB,0),5,0x0);
		
			acc0 = fpmac(acc0,buf_matA,0,0x76543210,ext_w(buf_matB,0),2,0x0);
			buf_matA = upd_w(buf_matA,1,window_read_v8(matA));
			window_incr(matA,h1);
			acc1 = fpmac(acc1,buf_matA,0,0x76543210,ext_w(buf_matB,0),6,0x0);
	
			acc0 = fpmac(acc0,buf_matA,8,0x76543210,ext_w(buf_matB,0),3,0x0);
			buf_matA = upd_w(buf_matA,0,window_read_v8(matA));
			window_incr(matA,h1);
			acc1 = fpmac(acc1,buf_matA,8,0x76543210,ext_w(buf_matB,0),7,0x0);
	
	
			////////////////////////////////////////////////////////////////////////
			acc0 = fpmac(acc0,buf_matA,0,0x76543210,ext_w(buf_matB,1),0,0x0);
			buf_matA = upd_w(buf_matA,1,window_read_v8(matA));
			window_incr(matA,h1);	
			acc1 = fpmac(acc1,buf_matA,0,0x76543210,ext_w(buf_matB,1),4,0x0);
			
	
			acc0 = fpmac(acc0,buf_matA,8,0x76543210,ext_w(buf_matB,1),1,0x0);
			buf_matA = upd_w(buf_matA,0,window_read_v8(matA));
			window_incr(matA,h1);
			acc1 = fpmac(acc1,buf_matA,8,0x76543210,ext_w(buf_matB,1),5,0x0);
		
			acc0 = fpmac(acc0,buf_matA,0,0x76543210,ext_w(buf_matB,1),2,0x0);
			buf_matA = upd_w(buf_matA,1,window_read_v8(matA));
			window_incr(matA,jump);
			acc1 = fpmac(acc1,buf_matA,0,0x76543210,ext_w(buf_matB,1),6,0x0);
	
			acc0 = fpmac(acc0,buf_matA,8,0x76543210,ext_w(buf_matB,1),3,0x0);
			window_write(matC,acc0);
			window_incr(matC,h1);
			buf_matA = upd_w(buf_matA,0,window_read_v8(matA));
			window_incr(matA,h1);
			buf_matB = upd_v(buf_matB,0,window_read_v4(matB));
			window_incr(matB,w1);
			acc1 = fpmac(acc1,buf_matA,8,0x76543210,ext_w(buf_matB,1),7,0x0);
			window_write(matC,acc1);
			window_incr(matC,jump);
			buf_matB = upd_v(buf_matB,1,window_read_v4(matB));
			window_decr(matB,w1-4);	
		}
	}
}
">> ./${dir_name}/aie/mm_kernel0.cc;

echo \
"#include <adf.h>
#include <stdio.h>
#include \"para.h\"
void mm_kernel1(input_window_float* __restrict matA,
		input_window_float* __restrict matB,
		input_window_float* __restrict acc_in,
		output_window_float* __restrict matC){

	v8float acc0=null_v8float();//For first output column
	v8float acc1=null_v8float();//For second output column
	v16float buf_matB = undef_v16float();
	v16float buf_matA = undef_v16float();

	buf_matB = upd_v(buf_matB,0,window_read_v4(matB));
	window_incr(matB,w1);
	buf_matB = upd_v(buf_matB,1,window_read_v4(matB));
	window_decr(matB,w1-4);

	buf_matA=upd_w(buf_matA,0,window_read_v8(matA));
	window_incr(matA,h1);
	
	for (unsigned int i=0;i<boundary_i;i++) 
	chess_prepare_for_pipelining
	chess_loop_range(boundary_i,)
	{	

		for (unsigned int j=0;j<boundary_j;j++)
		chess_prepare_for_pipelining
		chess_loop_range(boundary_j,){
			int jump=h1;
			if (j==judge_j){
				if(i==judge_i){
					jump=8;
				}
				else{
					jump=h1+8;
				}
			}
			else{
				jump=h1;
			}
			acc0=window_read_v8(acc_in);
			window_incr(acc_in,h1);
			acc1=window_read_v8(acc_in);
			window_incr(acc_in,jump);
			for (unsigned int k=0;k<boundary_k;k++)
			chess_prepare_for_pipelining
			chess_loop_range(boundary_k,)
			{
				acc0 = fpmac(acc0,buf_matA,0,0x76543210,ext_w(buf_matB,0),0,0x0); 
				buf_matA = upd_w(buf_matA,1,window_read_v8(matA));
				window_incr(matA,h1);
				buf_matB = upd_v(buf_matB,2,window_read_v4(matB));
				window_incr(matB,w1);	
				acc1 = fpmac(acc1,buf_matA,0,0x76543210,ext_w(buf_matB,0),4,0x0); 
				buf_matB = upd_v(buf_matB,3,window_read_v4(matB));
				window_decr(matB,w1-4); 
		
				acc0 = fpmac(acc0,buf_matA,8,0x76543210,ext_w(buf_matB,0),1,0x0); 
				buf_matA = upd_w(buf_matA,0,window_read_v8(matA));
				window_incr(matA,h1);
				acc1 = fpmac(acc1,buf_matA,8,0x76543210,ext_w(buf_matB,0),5,0x0);
			
				acc0 = fpmac(acc0,buf_matA,0,0x76543210,ext_w(buf_matB,0),2,0x0);
				buf_matA = upd_w(buf_matA,1,window_read_v8(matA));
				window_incr(matA,h1);
				acc1 = fpmac(acc1,buf_matA,0,0x76543210,ext_w(buf_matB,0),6,0x0);
		
				acc0 = fpmac(acc0,buf_matA,8,0x76543210,ext_w(buf_matB,0),3,0x0);
				buf_matA = upd_w(buf_matA,0,window_read_v8(matA));
				window_incr(matA,h1);
				acc1 = fpmac(acc1,buf_matA,8,0x76543210,ext_w(buf_matB,0),7,0x0);
		
		
				////////////////////////////////////////////////////////////////////////
				acc0 = fpmac(acc0,buf_matA,0,0x76543210,ext_w(buf_matB,1),0,0x0);
				buf_matA = upd_w(buf_matA,1,window_read_v8(matA));
				window_incr(matA,h1);	
				acc1 = fpmac(acc1,buf_matA,0,0x76543210,ext_w(buf_matB,1),4,0x0);
				
		
				acc0 = fpmac(acc0,buf_matA,8,0x76543210,ext_w(buf_matB,1),1,0x0);
				buf_matA = upd_w(buf_matA,0,window_read_v8(matA));
				window_incr(matA,h1);
				acc1 = fpmac(acc1,buf_matA,8,0x76543210,ext_w(buf_matB,1),5,0x0);
			
				acc0 = fpmac(acc0,buf_matA,0,0x76543210,ext_w(buf_matB,1),2,0x0);
				buf_matA = upd_w(buf_matA,1,window_read_v8(matA));
				window_incr(matA,h1);
				acc1 = fpmac(acc1,buf_matA,0,0x76543210,ext_w(buf_matB,1),6,0x0);
		
				acc0 = fpmac(acc0,buf_matA,8,0x76543210,ext_w(buf_matB,1),3,0x0);
				//window_write(matC,srs(acc0,0));
				//window_incr(matC,h1);
				buf_matA = upd_w(buf_matA,0,window_read_v8(matA));
				window_incr(matA,h1);
				buf_matB = upd_v(buf_matB,0,window_read_v4(matB));
				window_incr(matB,w1);
				acc1 = fpmac(acc1,buf_matA,8,0x76543210,ext_w(buf_matB,1),7,0x0);
				//window_write(matC,srs(acc1,0));
				//window_incr(matC,h1+8);
				buf_matB = upd_v(buf_matB,1,window_read_v4(matB));
				window_decr(matB,w1-4);
			}
			acc0 = fpmac(acc0,buf_matA,0,0x76543210,ext_w(buf_matB,0),0,0x0); 
			buf_matA = upd_w(buf_matA,1,window_read_v8(matA));
			window_incr(matA,h1);
			buf_matB = upd_v(buf_matB,2,window_read_v4(matB));
			window_incr(matB,w1);	
			acc1 = fpmac(acc1,buf_matA,0,0x76543210,ext_w(buf_matB,0),4,0x0); 
			buf_matB = upd_v(buf_matB,3,window_read_v4(matB));
			window_incr(matB,4); 
	
			acc0 = fpmac(acc0,buf_matA,8,0x76543210,ext_w(buf_matB,0),1,0x0); 
			buf_matA = upd_w(buf_matA,0,window_read_v8(matA));
			window_incr(matA,h1);
			acc1 = fpmac(acc1,buf_matA,8,0x76543210,ext_w(buf_matB,0),5,0x0);
		
			acc0 = fpmac(acc0,buf_matA,0,0x76543210,ext_w(buf_matB,0),2,0x0);
			buf_matA = upd_w(buf_matA,1,window_read_v8(matA));
			window_incr(matA,h1);
			acc1 = fpmac(acc1,buf_matA,0,0x76543210,ext_w(buf_matB,0),6,0x0);
	
			acc0 = fpmac(acc0,buf_matA,8,0x76543210,ext_w(buf_matB,0),3,0x0);
			buf_matA = upd_w(buf_matA,0,window_read_v8(matA));
			window_incr(matA,h1);
			acc1 = fpmac(acc1,buf_matA,8,0x76543210,ext_w(buf_matB,0),7,0x0);
	
	
			////////////////////////////////////////////////////////////////////////
			acc0 = fpmac(acc0,buf_matA,0,0x76543210,ext_w(buf_matB,1),0,0x0);
			buf_matA = upd_w(buf_matA,1,window_read_v8(matA));
			window_incr(matA,h1);	
			acc1 = fpmac(acc1,buf_matA,0,0x76543210,ext_w(buf_matB,1),4,0x0);
			
	
			acc0 = fpmac(acc0,buf_matA,8,0x76543210,ext_w(buf_matB,1),1,0x0);
			buf_matA = upd_w(buf_matA,0,window_read_v8(matA));
			window_incr(matA,h1);
			acc1 = fpmac(acc1,buf_matA,8,0x76543210,ext_w(buf_matB,1),5,0x0);
		
			acc0 = fpmac(acc0,buf_matA,0,0x76543210,ext_w(buf_matB,1),2,0x0);
			buf_matA = upd_w(buf_matA,1,window_read_v8(matA));
			window_incr(matA,jump);
			acc1 = fpmac(acc1,buf_matA,0,0x76543210,ext_w(buf_matB,1),6,0x0);
	
			acc0 = fpmac(acc0,buf_matA,8,0x76543210,ext_w(buf_matB,1),3,0x0);
			window_write(matC,acc0);
			window_incr(matC,h1);
			buf_matA = upd_w(buf_matA,0,window_read_v8(matA));
			window_incr(matA,h1);
			buf_matB = upd_v(buf_matB,0,window_read_v4(matB));
			window_incr(matB,w1);
			acc1 = fpmac(acc1,buf_matA,8,0x76543210,ext_w(buf_matB,1),7,0x0);
			window_write(matC,acc1);
			window_incr(matC,jump);
			buf_matB = upd_v(buf_matB,1,window_read_v4(matB));
			window_decr(matB,w1-4);	

			
		}
	}
}

">> ./${dir_name}/aie/mm_kernel1.cc;

echo \
"#ifndef __PARA_H__
#define __PARA_H__

#include <adf/stream/types.h>

#define h1 ${i}
#define w1 ${k}
#define w2 ${j}
const int boundary_i=h1/8;
const int boundary_j=w2/2;
const int boundary_k=w1/8-1;
const int judge_i=boundary_i-1;
const int judge_j=boundary_j-1;
void mm_kernel0(input_window_float* matA, input_window_float* matB, output_window_float* matC);
void mm_kernel1(input_window_float* matA, input_window_float* matB, input_window_float* acc_in, output_window_float* matC);
#endif
">> ./${dir_name}/aie/para.h;

echo \
"#ifndef __GRAPH_H__
#define __GRAPH_H__

#include <adf.h>
#include "'"para.h"'"
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



        source(mm) = "'"mm_kernel0.cc"'";
        source(mm1) = "'"mm_kernel1.cc"'";
        runtime<ratio>(mm) = 1;
        runtime<ratio>(mm1) = 1;
    };
};

#endif
">> ./${dir_name}/aie/aie_graph.h;
echo \
"#include "'"aie_graph.h"'"
using namespace adf;

PLIO* in0 = new PLIO("'"DataIn0"'", adf::plio_32_bits, \"../${din_name}input0.txt\",1000);
PLIO* in1 = new PLIO("'"DataIn1"'", adf::plio_32_bits, \"../${din_name}input1.txt\",1000);
PLIO* in2 = new PLIO("'"DataIn2"'", adf::plio_32_bits, \"../${din_name}input0.txt\",1000);
PLIO* in3 = new PLIO("'"DataIn3"'", adf::plio_32_bits, \"../${din_name}input1.txt\",1000);
PLIO* out = new PLIO("'"DataOut"'", adf::plio_32_bits, "'"data/output.txt"'",1000);

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
">> ./${dir_name}/aie/aie_graph.cpp;

elif [ ${data_type} == "int16" ] && [ ${kernel_type} == 0 ]
then
echo \
"#include <adf.h>
#include <stdio.h>
#include \"para.h\"

void mm_kernel0(input_window_int16* __restrict matA,
		input_window_int16* __restrict matB,
		output_window_int16* __restrict matC){

	v32int16 buf_matB=undef_v32int16();
	v64int16 buf_matA = undef_v64int16();

	buf_matB = upd_v(buf_matB,0,window_read_v8(matB));  //0
	
	window_incr(matB,w1);
	buf_matB = upd_v(buf_matB,1,window_read_v8(matB));  //1

	window_decr(matB,w1-8);    //w1-8
	buf_matA=upd_w(buf_matA,0,window_read_v16(matA));  //0
	window_incr(matA,h1);                                
	buf_matA=upd_w(buf_matA,1,window_read_v16(matA));  //1
	window_incr(matA,h1);

	v16acc48 acc0=null_v16acc48();//For first output column
	v16acc48 acc1=null_v16acc48();//For second output column
	for (unsigned int i=0;i<boundary_i;i++)  //i/16
	chess_prepare_for_pipelining
	chess_loop_range(boundary_i,)
	{
		for (unsigned int j=0;j<boundary_j;j++)  // j/2
	chess_prepare_for_pipelining
	chess_loop_range(boundary_j,)
		{
			acc0=null_v16acc48();
			acc1=null_v16acc48();
			int jump=h1;
			if (j==judge_j){
				jump=h1+16;
			}
			else{
				jump=h1;
			}
			for (unsigned int k=0;k<boundary_k;k++)  // k/16 - 1
		chess_prepare_for_pipelining
		chess_loop_range(boundary_k,)
			{	
				acc0 = mac16(acc0,buf_matA,0,0x73727170,0x77767574,0x3120,ext_w(buf_matB,0),0,0x0,0x0,1);  //0 1
				buf_matA=upd_w(buf_matA,2,window_read_v16(matA));    //2
				buf_matB = upd_v(buf_matB,2,window_read_v8(matB));   //2
				window_incr(matA,h1);
				window_incr(matB,w1); 
				acc1 = mac16(acc1,buf_matA,0,0x73727170,0x77767574,0x3120,ext_w(buf_matB,0),8,0x0,0x0,1);  //0 1
				buf_matB = upd_v(buf_matB,3,window_read_v8(matB));   //3
				buf_matA=upd_w(buf_matA,3,window_read_v16(matA));    //3
				window_incr(matA,h1);
				window_decr(matB,w1-8); 
		
				acc0 = mac16(acc0,buf_matA,32,0x73727170,0x77767574,0x3120,ext_w(buf_matB,0),2,0x0,0x0,1); //2 3
				buf_matA=upd_w(buf_matA,0,window_read_v16(matA));    //4
				window_incr(matA,h1);
				acc1 = mac16(acc1,buf_matA,32,0x73727170,0x77767574,0x3120,ext_w(buf_matB,0),10,0x0,0x0,1);//2 3
				buf_matA=upd_w(buf_matA,1,window_read_v16(matA));    //5
				window_incr(matA,h1);
		
				acc0 = mac16(acc0,buf_matA,0,0x73727170,0x77767574,0x3120,ext_w(buf_matB,0),4,0x0,0x0,1);  //4 5
				buf_matA=upd_w(buf_matA,2,window_read_v16(matA));    //6
				window_incr(matA,h1);
				acc1 = mac16(acc1,buf_matA,0,0x73727170,0x77767574,0x3120,ext_w(buf_matB,0),12,0x0,0x0,1); //4 5
				buf_matA=upd_w(buf_matA,3,window_read_v16(matA));    //7
				window_incr(matA,h1);
		
				acc0 = mac16(acc0,buf_matA,32,0x73727170,0x77767574,0x3120,ext_w(buf_matB,0),6,0x0,0x0,1); //6 7
				buf_matA=upd_w(buf_matA,0,window_read_v16(matA));    //8
				window_incr(matA,h1);
				acc1 = mac16(acc1,buf_matA,32,0x73727170,0x77767574,0x3120,ext_w(buf_matB,0),14,0x0,0x0,1); //6 7
				buf_matA=upd_w(buf_matA,1,window_read_v16(matA));    //9
				window_incr(matA,h1);
		
		
				acc0 = mac16(acc0,buf_matA,0,0x73727170,0x77767574,0x3120,ext_w(buf_matB,1),0,0x0,0x0,1);  //8 9
				buf_matA=upd_w(buf_matA,2,window_read_v16(matA));    //10
				window_incr(matA,h1);
				acc1 = mac16(acc1,buf_matA,0,0x73727170,0x77767574,0x3120,ext_w(buf_matB,1),8,0x0,0x0,1);  //8 9
				buf_matA=upd_w(buf_matA,3,window_read_v16(matA));    //11
				window_incr(matA,h1);
				
		
				acc0 = mac16(acc0,buf_matA,32,0x73727170,0x77767574,0x3120,ext_w(buf_matB,1),2,0x0,0x0,1); //10 11
				buf_matA=upd_w(buf_matA,0,window_read_v16(matA));    //12
				window_incr(matA,h1);
				acc1 = mac16(acc1,buf_matA,32,0x73727170,0x77767574,0x3120,ext_w(buf_matB,1),10,0x0,0x0,1);//10 11
				buf_matA=upd_w(buf_matA,1,window_read_v16(matA));    //13
				window_incr(matA,h1);
		
				acc0 = mac16(acc0,buf_matA,0,0x73727170,0x77767574,0x3120,ext_w(buf_matB,1),4,0x0,0x0,1);  //12 13
				buf_matA=upd_w(buf_matA,2,window_read_v16(matA));    //14
				window_incr(matA,h1);
				acc1 = mac16(acc1,buf_matA,0,0x73727170,0x77767574,0x3120,ext_w(buf_matB,1),12,0x0,0x0,1); //12 13
				buf_matA=upd_w(buf_matA,3,window_read_v16(matA));    //15
				window_incr(matA,h1);
		
				acc0 = mac16(acc0,buf_matA,32,0x73727170,0x77767574,0x3120,ext_w(buf_matB,1),6,0x0,0x0,1); //14 15
				buf_matA=upd_w(buf_matA,0,window_read_v16(matA));    //0
				buf_matB=upd_v(buf_matB,0,window_read_v8(matB));     //0
				window_incr(matA,h1);
				window_incr(matB,w1);
		
		
				acc1 = mac16(acc1,buf_matA,32,0x73727170,0x77767574,0x3120,ext_w(buf_matB,1),14,0x0,0x0,1); //14 15
				buf_matA=upd_w(buf_matA,1,window_read_v16(matA));    //1
				buf_matB=upd_v(buf_matB,1,window_read_v8(matB));  //1
				window_incr(matA,h1);
				window_decr(matB,w1-8); 
				
			}
			acc0 = mac16(acc0,buf_matA,0,0x73727170,0x77767574,0x3120,ext_w(buf_matB,0),0,0x0,0x0,1);  //0 1
			buf_matA=upd_w(buf_matA,2,window_read_v16(matA));    //2
			buf_matB = upd_v(buf_matB,2,window_read_v8(matB));   //2
			window_incr(matA,h1);
			window_incr(matB,w1); 
			acc1 = mac16(acc1,buf_matA,0,0x73727170,0x77767574,0x3120,ext_w(buf_matB,0),8,0x0,0x0,1);  //0 1
			buf_matB = upd_v(buf_matB,3,window_read_v8(matB));   //3
			buf_matA=upd_w(buf_matA,3,window_read_v16(matA));    //3
			window_incr(matA,h1);
			window_incr(matB,8);
			acc0 = mac16(acc0,buf_matA,32,0x73727170,0x77767574,0x3120,ext_w(buf_matB,0),2,0x0,0x0,1); //2 3
			buf_matA=upd_w(buf_matA,0,window_read_v16(matA));    //4
			window_incr(matA,h1);
			acc1 = mac16(acc1,buf_matA,32,0x73727170,0x77767574,0x3120,ext_w(buf_matB,0),10,0x0,0x0,1);//2 3
			buf_matA=upd_w(buf_matA,1,window_read_v16(matA));    //5
			window_incr(matA,h1);
	
			acc0 = mac16(acc0,buf_matA,0,0x73727170,0x77767574,0x3120,ext_w(buf_matB,0),4,0x0,0x0,1);  //4 5
			buf_matA=upd_w(buf_matA,2,window_read_v16(matA));    //6
			window_incr(matA,h1);
			acc1 = mac16(acc1,buf_matA,0,0x73727170,0x77767574,0x3120,ext_w(buf_matB,0),12,0x0,0x0,1); //4 5
			buf_matA=upd_w(buf_matA,3,window_read_v16(matA));    //7
			window_incr(matA,h1);
	
			acc0 = mac16(acc0,buf_matA,32,0x73727170,0x77767574,0x3120,ext_w(buf_matB,0),6,0x0,0x0,1); //6 7
			buf_matA=upd_w(buf_matA,0,window_read_v16(matA));    //8
			window_incr(matA,h1);
			acc1 = mac16(acc1,buf_matA,32,0x73727170,0x77767574,0x3120,ext_w(buf_matB,0),14,0x0,0x0,1); //6 7
			buf_matA=upd_w(buf_matA,1,window_read_v16(matA));    //9
			window_incr(matA,h1);
	
	
			acc0 = mac16(acc0,buf_matA,0,0x73727170,0x77767574,0x3120,ext_w(buf_matB,1),0,0x0,0x0,1);  //8 9
			buf_matA=upd_w(buf_matA,2,window_read_v16(matA));    //10
			window_incr(matA,h1);
			acc1 = mac16(acc1,buf_matA,0,0x73727170,0x77767574,0x3120,ext_w(buf_matB,1),8,0x0,0x0,1);  //8 9
			buf_matA=upd_w(buf_matA,3,window_read_v16(matA));    //11
			window_incr(matA,h1);
			
	
			acc0 = mac16(acc0,buf_matA,32,0x73727170,0x77767574,0x3120,ext_w(buf_matB,1),2,0x0,0x0,1); //10 11
			buf_matA=upd_w(buf_matA,0,window_read_v16(matA));    //12
			window_incr(matA,h1);
			acc1 = mac16(acc1,buf_matA,32,0x73727170,0x77767574,0x3120,ext_w(buf_matB,1),10,0x0,0x0,1);//10 11
			buf_matA=upd_w(buf_matA,1,window_read_v16(matA));    //13
			window_incr(matA,h1);
	
			acc0 = mac16(acc0,buf_matA,0,0x73727170,0x77767574,0x3120,ext_w(buf_matB,1),4,0x0,0x0,1);  //12 13
			buf_matA=upd_w(buf_matA,2,window_read_v16(matA));    //14
			window_incr(matA,h1);
			acc1 = mac16(acc1,buf_matA,0,0x73727170,0x77767574,0x3120,ext_w(buf_matB,1),12,0x0,0x0,1); //12 13
			buf_matA=upd_w(buf_matA,3,window_read_v16(matA));    //15
			window_incr(matA,jump);
	
	
			acc0 = mac16(acc0,buf_matA,32,0x73727170,0x77767574,0x3120,ext_w(buf_matB,1),6,0x0,0x0,1); //14 15
			window_write(matC,srs(acc0,0));
			window_incr(matC,h1);
	
			buf_matA=upd_w(buf_matA,0,window_read_v16(matA));    //0
			buf_matB=upd_v(buf_matB,0,window_read_v8(matB));     //0
			window_incr(matA,h1);
			window_incr(matB,w1);
	
	
			acc1 = mac16(acc1,buf_matA,32,0x73727170,0x77767574,0x3120,ext_w(buf_matB,1),14,0x0,0x0,1); //14 15
			window_write(matC,srs(acc1,0));
			window_incr(matC,jump);                       //h1+16
	
			
			buf_matA=upd_w(buf_matA,1,window_read_v16(matA));    //1
			buf_matB=upd_v(buf_matB,1,window_read_v8(matB));  //1
			window_incr(matA,h1);
			window_decr(matB,w1-8); 
		}
	}	
}
">> ./${dir_name}/aie/mm_kernel0.cc;

echo \
"#ifndef __PARA_H__
#define __PARA_H__

#include <adf/stream/types.h>

#define h1 ${i}
#define w1 ${k}
#define w2 ${j}
const int boundary_i=h1/16;
const int boundary_j=w2/2;
const int boundary_k=w1/16-1;
const int judge_j=boundary_j-1;
void mm_kernel0(input_window_int16* matA, input_window_int16* matB, output_window_int16* matC);
#endif
">> ./${dir_name}/aie/para.h;


echo \
"#ifndef __GRAPH_H__
#define __GRAPH_H__

#include <adf.h>
#include \"para.h\"
using namespace adf;

class simpleGraph : public graph {
   private:
    kernel mm;

   public:
    port<input> in0, in1;
    port<output> out;

    simpleGraph() {
        mm = kernel::create(mm_kernel0);

        connect<window<h1*w1*2>>(in0, mm.in[0]);
        connect<window<w1*w2*2>>(in1, mm.in[1]);
        connect<window<h1*w2*2>>(mm.out[0], out);


        source(mm) = \"mm_kernel0.cc\";

        runtime<ratio>(mm) = 1;
    };
};

#endif
">> ./${dir_name}/aie/aie_graph.h;

echo \
"#include \"aie_graph.h\"
using namespace adf;

PLIO* in0 = new PLIO(\"DataIn0\",adf::plio_32_bits,\"../${din_name}input0.txt\",1000);
PLIO* in1 = new PLIO(\"DataIn1\",adf::plio_32_bits,\"../${din_name}input1.txt\",1000);
PLIO* out = new PLIO(\"DataOut\",adf::plio_32_bits,\"data/output.txt\",1000);

simulation::platform<2, 1> platform(in0, in1, out);

simpleGraph addergraph;

connect<> net0(platform.src[0], addergraph.in0);
connect<> net1(platform.src[1], addergraph.in1);

connect<> net2(addergraph.out, platform.sink[0]);

#ifdef __AIESIM__
int main(int argc, char** argv) {
    addergraph.init();
    addergraph.run(1);
    addergraph.end();
    return 0;
}
#endif
">> ./${dir_name}/aie/aie_graph.cpp;

elif [ ${data_type} == "int16" ] && [ ${kernel_type} == 1 ]
then
echo \
"#include <adf.h>
#include <stdio.h>
#include \"para.h\"

void mm_kernel0(input_window_int16* __restrict matA,
		input_window_int16* __restrict matB,
		output_window_int16* __restrict matC){

	v32int16 buf_matB=undef_v32int16();
	v64int16 buf_matA = undef_v64int16();

	buf_matB = upd_v(buf_matB,0,window_read_v8(matB));  //0
	
	window_incr(matB,w1);
	buf_matB = upd_v(buf_matB,1,window_read_v8(matB));  //1

	window_decr(matB,w1-8);    //w1-8
	buf_matA=upd_w(buf_matA,0,window_read_v16(matA));  //0
	window_incr(matA,h1);                                
	buf_matA=upd_w(buf_matA,1,window_read_v16(matA));  //1
	window_incr(matA,h1);

	v16acc48 acc0=null_v16acc48();//For first output column
	v16acc48 acc1=null_v16acc48();//For second output column
	for (unsigned int i=0;i<boundary_i;i++)  //i/16
	chess_prepare_for_pipelining
	chess_loop_range(boundary_i,)
	{
		for (unsigned int j=0;j<boundary_j;j++)  // j/2
	chess_prepare_for_pipelining
	chess_loop_range(boundary_j,)
		{
			acc0=null_v16acc48();
			acc1=null_v16acc48();
			int jump=h1;
			if (j==judge_j){
				jump=h1+16;
			}
			else{
				jump=h1;
			}
			for (unsigned int k=0;k<boundary_k;k++)  // k/16 - 1
		chess_prepare_for_pipelining
		chess_loop_range(boundary_k,)
			{	
				acc0 = mac16(acc0,buf_matA,0,0x73727170,0x77767574,0x3120,ext_w(buf_matB,0),0,0x0,0x0,1);  //0 1
				buf_matA=upd_w(buf_matA,2,window_read_v16(matA));    //2
				buf_matB = upd_v(buf_matB,2,window_read_v8(matB));   //2
				window_incr(matA,h1);
				window_incr(matB,w1); 
				acc1 = mac16(acc1,buf_matA,0,0x73727170,0x77767574,0x3120,ext_w(buf_matB,0),8,0x0,0x0,1);  //0 1
				buf_matB = upd_v(buf_matB,3,window_read_v8(matB));   //3
				buf_matA=upd_w(buf_matA,3,window_read_v16(matA));    //3
				window_incr(matA,h1);
				window_decr(matB,w1-8); 
		
				acc0 = mac16(acc0,buf_matA,32,0x73727170,0x77767574,0x3120,ext_w(buf_matB,0),2,0x0,0x0,1); //2 3
				buf_matA=upd_w(buf_matA,0,window_read_v16(matA));    //4
				window_incr(matA,h1);
				acc1 = mac16(acc1,buf_matA,32,0x73727170,0x77767574,0x3120,ext_w(buf_matB,0),10,0x0,0x0,1);//2 3
				buf_matA=upd_w(buf_matA,1,window_read_v16(matA));    //5
				window_incr(matA,h1);
		
				acc0 = mac16(acc0,buf_matA,0,0x73727170,0x77767574,0x3120,ext_w(buf_matB,0),4,0x0,0x0,1);  //4 5
				buf_matA=upd_w(buf_matA,2,window_read_v16(matA));    //6
				window_incr(matA,h1);
				acc1 = mac16(acc1,buf_matA,0,0x73727170,0x77767574,0x3120,ext_w(buf_matB,0),12,0x0,0x0,1); //4 5
				buf_matA=upd_w(buf_matA,3,window_read_v16(matA));    //7
				window_incr(matA,h1);
		
				acc0 = mac16(acc0,buf_matA,32,0x73727170,0x77767574,0x3120,ext_w(buf_matB,0),6,0x0,0x0,1); //6 7
				buf_matA=upd_w(buf_matA,0,window_read_v16(matA));    //8
				window_incr(matA,h1);
				acc1 = mac16(acc1,buf_matA,32,0x73727170,0x77767574,0x3120,ext_w(buf_matB,0),14,0x0,0x0,1); //6 7
				buf_matA=upd_w(buf_matA,1,window_read_v16(matA));    //9
				window_incr(matA,h1);
		
		
				acc0 = mac16(acc0,buf_matA,0,0x73727170,0x77767574,0x3120,ext_w(buf_matB,1),0,0x0,0x0,1);  //8 9
				buf_matA=upd_w(buf_matA,2,window_read_v16(matA));    //10
				window_incr(matA,h1);
				acc1 = mac16(acc1,buf_matA,0,0x73727170,0x77767574,0x3120,ext_w(buf_matB,1),8,0x0,0x0,1);  //8 9
				buf_matA=upd_w(buf_matA,3,window_read_v16(matA));    //11
				window_incr(matA,h1);
				
		
				acc0 = mac16(acc0,buf_matA,32,0x73727170,0x77767574,0x3120,ext_w(buf_matB,1),2,0x0,0x0,1); //10 11
				buf_matA=upd_w(buf_matA,0,window_read_v16(matA));    //12
				window_incr(matA,h1);
				acc1 = mac16(acc1,buf_matA,32,0x73727170,0x77767574,0x3120,ext_w(buf_matB,1),10,0x0,0x0,1);//10 11
				buf_matA=upd_w(buf_matA,1,window_read_v16(matA));    //13
				window_incr(matA,h1);
		
				acc0 = mac16(acc0,buf_matA,0,0x73727170,0x77767574,0x3120,ext_w(buf_matB,1),4,0x0,0x0,1);  //12 13
				buf_matA=upd_w(buf_matA,2,window_read_v16(matA));    //14
				window_incr(matA,h1);
				acc1 = mac16(acc1,buf_matA,0,0x73727170,0x77767574,0x3120,ext_w(buf_matB,1),12,0x0,0x0,1); //12 13
				buf_matA=upd_w(buf_matA,3,window_read_v16(matA));    //15
				window_incr(matA,h1);
		
				acc0 = mac16(acc0,buf_matA,32,0x73727170,0x77767574,0x3120,ext_w(buf_matB,1),6,0x0,0x0,1); //14 15
				buf_matA=upd_w(buf_matA,0,window_read_v16(matA));    //0
				buf_matB=upd_v(buf_matB,0,window_read_v8(matB));     //0
				window_incr(matA,h1);
				window_incr(matB,w1);
		
		
				acc1 = mac16(acc1,buf_matA,32,0x73727170,0x77767574,0x3120,ext_w(buf_matB,1),14,0x0,0x0,1); //14 15
				buf_matA=upd_w(buf_matA,1,window_read_v16(matA));    //1
				buf_matB=upd_v(buf_matB,1,window_read_v8(matB));  //1
				window_incr(matA,h1);
				window_decr(matB,w1-8); 
				
			}
			acc0 = mac16(acc0,buf_matA,0,0x73727170,0x77767574,0x3120,ext_w(buf_matB,0),0,0x0,0x0,1);  //0 1
			buf_matA=upd_w(buf_matA,2,window_read_v16(matA));    //2
			buf_matB = upd_v(buf_matB,2,window_read_v8(matB));   //2
			window_incr(matA,h1);
			window_incr(matB,w1); 
			acc1 = mac16(acc1,buf_matA,0,0x73727170,0x77767574,0x3120,ext_w(buf_matB,0),8,0x0,0x0,1);  //0 1
			buf_matB = upd_v(buf_matB,3,window_read_v8(matB));   //3
			buf_matA=upd_w(buf_matA,3,window_read_v16(matA));    //3
			window_incr(matA,h1);
			window_incr(matB,8);
			acc0 = mac16(acc0,buf_matA,32,0x73727170,0x77767574,0x3120,ext_w(buf_matB,0),2,0x0,0x0,1); //2 3
			buf_matA=upd_w(buf_matA,0,window_read_v16(matA));    //4
			window_incr(matA,h1);
			acc1 = mac16(acc1,buf_matA,32,0x73727170,0x77767574,0x3120,ext_w(buf_matB,0),10,0x0,0x0,1);//2 3
			buf_matA=upd_w(buf_matA,1,window_read_v16(matA));    //5
			window_incr(matA,h1);
	
			acc0 = mac16(acc0,buf_matA,0,0x73727170,0x77767574,0x3120,ext_w(buf_matB,0),4,0x0,0x0,1);  //4 5
			buf_matA=upd_w(buf_matA,2,window_read_v16(matA));    //6
			window_incr(matA,h1);
			acc1 = mac16(acc1,buf_matA,0,0x73727170,0x77767574,0x3120,ext_w(buf_matB,0),12,0x0,0x0,1); //4 5
			buf_matA=upd_w(buf_matA,3,window_read_v16(matA));    //7
			window_incr(matA,h1);
	
			acc0 = mac16(acc0,buf_matA,32,0x73727170,0x77767574,0x3120,ext_w(buf_matB,0),6,0x0,0x0,1); //6 7
			buf_matA=upd_w(buf_matA,0,window_read_v16(matA));    //8
			window_incr(matA,h1);
			acc1 = mac16(acc1,buf_matA,32,0x73727170,0x77767574,0x3120,ext_w(buf_matB,0),14,0x0,0x0,1); //6 7
			buf_matA=upd_w(buf_matA,1,window_read_v16(matA));    //9
			window_incr(matA,h1);
	
	
			acc0 = mac16(acc0,buf_matA,0,0x73727170,0x77767574,0x3120,ext_w(buf_matB,1),0,0x0,0x0,1);  //8 9
			buf_matA=upd_w(buf_matA,2,window_read_v16(matA));    //10
			window_incr(matA,h1);
			acc1 = mac16(acc1,buf_matA,0,0x73727170,0x77767574,0x3120,ext_w(buf_matB,1),8,0x0,0x0,1);  //8 9
			buf_matA=upd_w(buf_matA,3,window_read_v16(matA));    //11
			window_incr(matA,h1);
			
	
			acc0 = mac16(acc0,buf_matA,32,0x73727170,0x77767574,0x3120,ext_w(buf_matB,1),2,0x0,0x0,1); //10 11
			buf_matA=upd_w(buf_matA,0,window_read_v16(matA));    //12
			window_incr(matA,h1);
			acc1 = mac16(acc1,buf_matA,32,0x73727170,0x77767574,0x3120,ext_w(buf_matB,1),10,0x0,0x0,1);//10 11
			buf_matA=upd_w(buf_matA,1,window_read_v16(matA));    //13
			window_incr(matA,h1);
	
			acc0 = mac16(acc0,buf_matA,0,0x73727170,0x77767574,0x3120,ext_w(buf_matB,1),4,0x0,0x0,1);  //12 13
			buf_matA=upd_w(buf_matA,2,window_read_v16(matA));    //14
			window_incr(matA,h1);
			acc1 = mac16(acc1,buf_matA,0,0x73727170,0x77767574,0x3120,ext_w(buf_matB,1),12,0x0,0x0,1); //12 13
			buf_matA=upd_w(buf_matA,3,window_read_v16(matA));    //15
			window_incr(matA,jump);
	
	
			acc0 = mac16(acc0,buf_matA,32,0x73727170,0x77767574,0x3120,ext_w(buf_matB,1),6,0x0,0x0,1); //14 15
			window_write(matC,srs(acc0,0));
			window_incr(matC,h1);
	
			buf_matA=upd_w(buf_matA,0,window_read_v16(matA));    //0
			buf_matB=upd_v(buf_matB,0,window_read_v8(matB));     //0
			window_incr(matA,h1);
			window_incr(matB,w1);
	
	
			acc1 = mac16(acc1,buf_matA,32,0x73727170,0x77767574,0x3120,ext_w(buf_matB,1),14,0x0,0x0,1); //14 15
			window_write(matC,srs(acc1,0));
			window_incr(matC,jump);                       //h1+16
	
			
			buf_matA=upd_w(buf_matA,1,window_read_v16(matA));    //1
			buf_matB=upd_v(buf_matB,1,window_read_v8(matB));  //1
			window_incr(matA,h1);
			window_decr(matB,w1-8); 
		}
	}	
}
">> ./${dir_name}/aie/mm_kernel0.cc;

echo \
"#include <adf.h>
#include <stdio.h>
#include \"para.h\"

void mm_kernel1(input_window_int16* __restrict matA,
		input_window_int16* __restrict matB,
		input_window_int16* __restrict acc_in,
		output_window_int16* __restrict matC){

	v32int16 buf_matB=undef_v32int16();
	v64int16 buf_matA = undef_v64int16();

	buf_matB = upd_v(buf_matB,0,window_read_v8(matB));  //0
	
	window_incr(matB,w1);
	buf_matB = upd_v(buf_matB,1,window_read_v8(matB));  //1

	window_decr(matB,w1-8);    //w1-8
	buf_matA=upd_w(buf_matA,0,window_read_v16(matA));  //0
	window_incr(matA,h1);                                
	buf_matA=upd_w(buf_matA,1,window_read_v16(matA));  //1
	window_incr(matA,h1);

	v16acc48 acc0=null_v16acc48();//For first output column
	v16acc48 acc1=null_v16acc48();//For second output column
	for (unsigned int i=0;i<boundary_i;i++)  //i/16
	chess_prepare_for_pipelining
	chess_loop_range(boundary_i,)
	{
		for (unsigned int j=0;j<boundary_j;j++)  // j/2
	chess_prepare_for_pipelining
	chess_loop_range(boundary_j,)
		{
			acc0=null_v16acc48();
			acc1=null_v16acc48();
			int jump=h1;
			if (j==judge_j){
				jump=h1+16;
			}
			else{
				jump=h1;
			}
			acc0=ups(window_read_v16(acc_in),0);
			window_incr(acc_in,h1);
			acc1=ups(window_read_v16(acc_in),0);
			window_incr(acc_in,jump);
			for (unsigned int k=0;k<boundary_k;k++)  // k/16 - 1
		chess_prepare_for_pipelining
		chess_loop_range(boundary_k,)
			{	
				acc0 = mac16(acc0,buf_matA,0,0x73727170,0x77767574,0x3120,ext_w(buf_matB,0),0,0x0,0x0,1);  //0 1
				buf_matA=upd_w(buf_matA,2,window_read_v16(matA));    //2
				buf_matB = upd_v(buf_matB,2,window_read_v8(matB));   //2
				window_incr(matA,h1);
				window_incr(matB,w1); 
				acc1 = mac16(acc1,buf_matA,0,0x73727170,0x77767574,0x3120,ext_w(buf_matB,0),8,0x0,0x0,1);  //0 1
				buf_matB = upd_v(buf_matB,3,window_read_v8(matB));   //3
				buf_matA=upd_w(buf_matA,3,window_read_v16(matA));    //3
				window_incr(matA,h1);
				window_decr(matB,w1-8); 
		
				acc0 = mac16(acc0,buf_matA,32,0x73727170,0x77767574,0x3120,ext_w(buf_matB,0),2,0x0,0x0,1); //2 3
				buf_matA=upd_w(buf_matA,0,window_read_v16(matA));    //4
				window_incr(matA,h1);
				acc1 = mac16(acc1,buf_matA,32,0x73727170,0x77767574,0x3120,ext_w(buf_matB,0),10,0x0,0x0,1);//2 3
				buf_matA=upd_w(buf_matA,1,window_read_v16(matA));    //5
				window_incr(matA,h1);
		
				acc0 = mac16(acc0,buf_matA,0,0x73727170,0x77767574,0x3120,ext_w(buf_matB,0),4,0x0,0x0,1);  //4 5
				buf_matA=upd_w(buf_matA,2,window_read_v16(matA));    //6
				window_incr(matA,h1);
				acc1 = mac16(acc1,buf_matA,0,0x73727170,0x77767574,0x3120,ext_w(buf_matB,0),12,0x0,0x0,1); //4 5
				buf_matA=upd_w(buf_matA,3,window_read_v16(matA));    //7
				window_incr(matA,h1);
		
				acc0 = mac16(acc0,buf_matA,32,0x73727170,0x77767574,0x3120,ext_w(buf_matB,0),6,0x0,0x0,1); //6 7
				buf_matA=upd_w(buf_matA,0,window_read_v16(matA));    //8
				window_incr(matA,h1);
				acc1 = mac16(acc1,buf_matA,32,0x73727170,0x77767574,0x3120,ext_w(buf_matB,0),14,0x0,0x0,1); //6 7
				buf_matA=upd_w(buf_matA,1,window_read_v16(matA));    //9
				window_incr(matA,h1);
		
		
				acc0 = mac16(acc0,buf_matA,0,0x73727170,0x77767574,0x3120,ext_w(buf_matB,1),0,0x0,0x0,1);  //8 9
				buf_matA=upd_w(buf_matA,2,window_read_v16(matA));    //10
				window_incr(matA,h1);
				acc1 = mac16(acc1,buf_matA,0,0x73727170,0x77767574,0x3120,ext_w(buf_matB,1),8,0x0,0x0,1);  //8 9
				buf_matA=upd_w(buf_matA,3,window_read_v16(matA));    //11
				window_incr(matA,h1);
				
		
				acc0 = mac16(acc0,buf_matA,32,0x73727170,0x77767574,0x3120,ext_w(buf_matB,1),2,0x0,0x0,1); //10 11
				buf_matA=upd_w(buf_matA,0,window_read_v16(matA));    //12
				window_incr(matA,h1);
				acc1 = mac16(acc1,buf_matA,32,0x73727170,0x77767574,0x3120,ext_w(buf_matB,1),10,0x0,0x0,1);//10 11
				buf_matA=upd_w(buf_matA,1,window_read_v16(matA));    //13
				window_incr(matA,h1);
		
				acc0 = mac16(acc0,buf_matA,0,0x73727170,0x77767574,0x3120,ext_w(buf_matB,1),4,0x0,0x0,1);  //12 13
				buf_matA=upd_w(buf_matA,2,window_read_v16(matA));    //14
				window_incr(matA,h1);
				acc1 = mac16(acc1,buf_matA,0,0x73727170,0x77767574,0x3120,ext_w(buf_matB,1),12,0x0,0x0,1); //12 13
				buf_matA=upd_w(buf_matA,3,window_read_v16(matA));    //15
				window_incr(matA,h1);
		
				acc0 = mac16(acc0,buf_matA,32,0x73727170,0x77767574,0x3120,ext_w(buf_matB,1),6,0x0,0x0,1); //14 15
				buf_matA=upd_w(buf_matA,0,window_read_v16(matA));    //0
				buf_matB=upd_v(buf_matB,0,window_read_v8(matB));     //0
				window_incr(matA,h1);
				window_incr(matB,w1);
		
		
				acc1 = mac16(acc1,buf_matA,32,0x73727170,0x77767574,0x3120,ext_w(buf_matB,1),14,0x0,0x0,1); //14 15
				buf_matA=upd_w(buf_matA,1,window_read_v16(matA));    //1
				buf_matB=upd_v(buf_matB,1,window_read_v8(matB));  //1
				window_incr(matA,h1);
				window_decr(matB,w1-8); 
				
			}
			acc0 = mac16(acc0,buf_matA,0,0x73727170,0x77767574,0x3120,ext_w(buf_matB,0),0,0x0,0x0,1);  //0 1
			buf_matA=upd_w(buf_matA,2,window_read_v16(matA));    //2
			buf_matB = upd_v(buf_matB,2,window_read_v8(matB));   //2
			window_incr(matA,h1);
			window_incr(matB,w1); 
			acc1 = mac16(acc1,buf_matA,0,0x73727170,0x77767574,0x3120,ext_w(buf_matB,0),8,0x0,0x0,1);  //0 1
			buf_matB = upd_v(buf_matB,3,window_read_v8(matB));   //3
			buf_matA=upd_w(buf_matA,3,window_read_v16(matA));    //3
			window_incr(matA,h1);
			window_incr(matB,8);
			acc0 = mac16(acc0,buf_matA,32,0x73727170,0x77767574,0x3120,ext_w(buf_matB,0),2,0x0,0x0,1); //2 3
			buf_matA=upd_w(buf_matA,0,window_read_v16(matA));    //4
			window_incr(matA,h1);
			acc1 = mac16(acc1,buf_matA,32,0x73727170,0x77767574,0x3120,ext_w(buf_matB,0),10,0x0,0x0,1);//2 3
			buf_matA=upd_w(buf_matA,1,window_read_v16(matA));    //5
			window_incr(matA,h1);
	
			acc0 = mac16(acc0,buf_matA,0,0x73727170,0x77767574,0x3120,ext_w(buf_matB,0),4,0x0,0x0,1);  //4 5
			buf_matA=upd_w(buf_matA,2,window_read_v16(matA));    //6
			window_incr(matA,h1);
			acc1 = mac16(acc1,buf_matA,0,0x73727170,0x77767574,0x3120,ext_w(buf_matB,0),12,0x0,0x0,1); //4 5
			buf_matA=upd_w(buf_matA,3,window_read_v16(matA));    //7
			window_incr(matA,h1);
	
			acc0 = mac16(acc0,buf_matA,32,0x73727170,0x77767574,0x3120,ext_w(buf_matB,0),6,0x0,0x0,1); //6 7
			buf_matA=upd_w(buf_matA,0,window_read_v16(matA));    //8
			window_incr(matA,h1);
			acc1 = mac16(acc1,buf_matA,32,0x73727170,0x77767574,0x3120,ext_w(buf_matB,0),14,0x0,0x0,1); //6 7
			buf_matA=upd_w(buf_matA,1,window_read_v16(matA));    //9
			window_incr(matA,h1);
	
	
			acc0 = mac16(acc0,buf_matA,0,0x73727170,0x77767574,0x3120,ext_w(buf_matB,1),0,0x0,0x0,1);  //8 9
			buf_matA=upd_w(buf_matA,2,window_read_v16(matA));    //10
			window_incr(matA,h1);
			acc1 = mac16(acc1,buf_matA,0,0x73727170,0x77767574,0x3120,ext_w(buf_matB,1),8,0x0,0x0,1);  //8 9
			buf_matA=upd_w(buf_matA,3,window_read_v16(matA));    //11
			window_incr(matA,h1);
			
	
			acc0 = mac16(acc0,buf_matA,32,0x73727170,0x77767574,0x3120,ext_w(buf_matB,1),2,0x0,0x0,1); //10 11
			buf_matA=upd_w(buf_matA,0,window_read_v16(matA));    //12
			window_incr(matA,h1);
			acc1 = mac16(acc1,buf_matA,32,0x73727170,0x77767574,0x3120,ext_w(buf_matB,1),10,0x0,0x0,1);//10 11
			buf_matA=upd_w(buf_matA,1,window_read_v16(matA));    //13
			window_incr(matA,h1);
	
			acc0 = mac16(acc0,buf_matA,0,0x73727170,0x77767574,0x3120,ext_w(buf_matB,1),4,0x0,0x0,1);  //12 13
			buf_matA=upd_w(buf_matA,2,window_read_v16(matA));    //14
			window_incr(matA,h1);
			acc1 = mac16(acc1,buf_matA,0,0x73727170,0x77767574,0x3120,ext_w(buf_matB,1),12,0x0,0x0,1); //12 13
			buf_matA=upd_w(buf_matA,3,window_read_v16(matA));    //15
			window_incr(matA,jump);
	
	
			acc0 = mac16(acc0,buf_matA,32,0x73727170,0x77767574,0x3120,ext_w(buf_matB,1),6,0x0,0x0,1); //14 15
			window_write(matC,srs(acc0,0));
			window_incr(matC,h1);
	
			buf_matA=upd_w(buf_matA,0,window_read_v16(matA));    //0
			buf_matB=upd_v(buf_matB,0,window_read_v8(matB));     //0
			window_incr(matA,h1);
			window_incr(matB,w1);
	
	
			acc1 = mac16(acc1,buf_matA,32,0x73727170,0x77767574,0x3120,ext_w(buf_matB,1),14,0x0,0x0,1); //14 15
			window_write(matC,srs(acc1,0));
			window_incr(matC,jump);                       //h1+16
	
			
			buf_matA=upd_w(buf_matA,1,window_read_v16(matA));    //1
			buf_matB=upd_v(buf_matB,1,window_read_v8(matB));  //1
			window_incr(matA,h1);
			window_decr(matB,w1-8); 
		}
	}	
}

">> ./${dir_name}/aie/mm_kernel1.cc;

echo \
"#ifndef __PARA_H__
#define __PARA_H__

#include <adf/stream/types.h>

#define h1 ${i}
#define w1 ${k}
#define w2 ${j}
const int boundary_i=h1/16;
const int boundary_j=w2/2;
const int boundary_k=w1/16-1;
const int judge_j=boundary_j-1;
void mm_kernel0(input_window_int16* matA, input_window_int16* matB, output_window_int16* matC);
void mm_kernel1(input_window_int16* matA, input_window_int16* matB, input_window_int16* acc_in,output_window_int16* matC);
#endif
">> ./${dir_name}/aie/para.h;

echo \
"#ifndef __GRAPH_H__
#define __GRAPH_H__

#include <adf.h>
#include \"para.h\"
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

        connect<window<h1*w1*2>>(in0, mm.in[0]);
        connect<window<w1*w2*2>>(in1, mm.in[1]);
        connect<window<h1*w1*2>>(in2, mm1.in[0]);
        connect<window<w1*w2*2>>(in3, mm1.in[1]);
        connect<window<h1*w2*2>>(mm.out[0], mm1.in[2]);
        connect<window<h1*w2*2>>(mm1.out[0], out);


        source(mm) = \"mm_kernel0.cc\";
        source(mm1) = \"mm_kernel1.cc\";
        runtime<ratio>(mm) = 1;
        runtime<ratio>(mm1) = 1;
    };
};

#endif
">> ./${dir_name}/aie/aie_graph.h;

echo \
"#include \"aie_graph.h\"
using namespace adf;

PLIO* in0 = new PLIO(\"DataIn0\", adf::plio_32_bits, \"../${din_name}input0.txt\",1000);
PLIO* in1 = new PLIO(\"DataIn1\", adf::plio_32_bits, \"../${din_name}input1.txt\",1000);
PLIO* in2 = new PLIO(\"DataIn2\", adf::plio_32_bits, \"../${din_name}input0.txt\",1000);
PLIO* in3 = new PLIO(\"DataIn3\", adf::plio_32_bits, \"../${din_name}input1.txt\",1000);
PLIO* out = new PLIO(\"DataOut\", adf::plio_32_bits, \"data/output.txt\",1000);

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
">> ./${dir_name}/aie/aie_graph.cpp;

fi

if (( ${Auto_Gen} == 1 ))
then
	if [ "$sim_name" == "int32_32_32_32" ] || [ "$sim_name" == "int32_16_32_32" ] || [ "$sim_name" == "int32_16_16_32" ] || [ "$sim_name" == "int32_8_16_32" ] || [ "$sim_name" == "int32_8_8_32" ] || [ "$sim_name" == "int32_8_8_16" ] || [ "$sim_name" == "int32_8_8_8" ] || [ "$sim_name" == "int16_48_48_48" ] || [ "$sim_name" == "int16_32_48_48" ] || [ "$sim_name" == "int16_32_32_48" ] || [ "$sim_name" == "int16_16_32_48" ] || [ "$sim_name" == "int16_16_16_48" ] || [ "$sim_name" == "int16_16_16_32" ] || [ "$sim_name" == "int16_16_16_8" ] 
	then
		if (( ${IO_Gen} == 0 )) && (( ${Sys_Gen} == 0 )) 
		then
			cd ${dir_name};
			./run_aie.sh;
			cd ..;
		fi
	fi
fi

echo "
Project $dir_name created successfully!
		";
fi