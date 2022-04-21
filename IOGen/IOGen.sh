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
	elif (( ${n} == 9 ))
	then
		IFS=':' read -ra Key <<< "$line";
		value_temp="${Key[1]}"; 
		unset IFS
		IFS=';' read -ra Value <<< "$value_temp";
		data_type="${Value[0]}"; 
	elif (( ${n} == 10 ))
	then
		IFS=':' read -ra Key <<< "$line";
		value_temp="${Key[1]}"; 
		unset IFS
		IFS=';' read -ra Value <<< "$value_temp";
		row_num="${Value[0]}";
	elif (( ${n} == 11 ))
	then
		IFS=':' read -ra Key <<< "$line";
		value_temp="${Key[1]}"; 
		unset IFS
		IFS=';' read -ra Value <<< "$value_temp";
		reduce_num="${Value[0]}";
	elif (( ${n} == 12 ))
	then
		IFS=':' read -ra Key <<< "$line";
		value_temp="${Key[1]}"; 
		unset IFS
		IFS=';' read -ra Value <<< "$value_temp";
		col_num="${Value[0]}";
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
		Auto_Compile="${Value[0]}";
 	fi
done < "$input"

if (( ${Sys_Gen} == 1 ))
then
	if [ ${data_type} == "fp32" ] || [ ${data_type} == "int32" ]
	then
		row_num=12;
		col_num=4;
	elif [ ${data_type} == "int16" ]
	then
		row_num=8;
		col_num=6;
	fi
fi

let start_pos=2;
dir_name="${data_type}_${row_num}_8_${col_num}_${platform}";
let enable=1;
for e in ${data_type}_*;
do
	file_name="$e";
	if [[ "$file_name" == "$dir_name" ]]
	then
		if (( Auto_Compile == 1 ))
		then
			cd ./${dir_name};
			./run_aie.sh;
			cd ../;
		fi
		echo "
Project $dir_name exsists and can be used in the later steps
		";
		enable=0;
	fi
done

if (( ${enable} == 1 ))
then
rm -rf ./${dir_name}/conn.cfg;
mkdir ./${dir_name};
mkdir ./${dir_name}/aie;
cp -r ../KernelGen/${data_type}_32_32_32_ker1_${platform}/aie/mm_kernel0.cc ./${dir_name}/aie
cp -r ../KernelGen/${data_type}_32_32_32_ker1_${platform}/aie/mm_kernel1.cc ./${dir_name}/aie 
cp -r ../KernelGen/${data_type}_32_32_32_ker1_${platform}/aie/para.h ./${dir_name}/aie
cp -r Makefile ./${dir_name};

if [[ "$platform" == "VCK5000" ]] || [[ "$platform" == "vck5000" ]]
then

	echo \
	"source with-sdaccel;
source /opt/tools/xilinx/Vitis/2021.2/settings64.sh;
source /opt/xilinx/xrt/setup.sh;


make aie PLATFORM_NAME=xilinx_vck5000_gen3x16_xdma_1_202120_1;">> ./${dir_name}/run_aie.sh;
chmod +x ./${dir_name}/run_aie.sh;

elif [[ "$platform" == "VCK190" ]] || [[ "$platform" == "vck190" ]]
then

	echo \
	"VIV_VER=2021.1 SDA_VER=2021.1 . with-sdaccel;

make aie PLATFORM_NAME=xilinx_vck190_base_202110_1;">> ./${dir_name}/run_aie.sh;
chmod +x ./${dir_name}/run_aie.sh;
else 
	echo "Specified platform currently is not supported. Please input VCK5000 or VCK190"
fi


echo \
"
#define NUM_ENGINES_PER_PAC 8
">> ./${dir_name}/aie/para.h

let k=${row_num}*${col_num};
let R_BRO=${col_num};
let C_BRO=2;
let boundry0=${col_num}/${R_BRO};
let boundry1=${row_num}/${C_BRO};
echo \
"#include \"mm_top.h\"
using namespace adf;
#define COL_OFFSET ${start_pos}

">> ./${dir_name}/aie/mm_top.cpp;

for ((i=0;i<${row_num}*2*${boundry0};i++));
do
	echo \
	"PLIO *in_r${i}  = new PLIO(\"in_r${i}\",  adf::plio_128_bits, \"data/input0.txt\", 250);">> ./${dir_name}/aie/mm_top.cpp;
done

for ((i=0;i<${col_num}*2*${boundry1};i++));
do
	echo \
	"PLIO *in_c${i}  = new PLIO(\"in_c${i}\",  adf::plio_128_bits, \"data/input0.txt\", 250);">> ./${dir_name}/aie/mm_top.cpp;
done

echo \
"	
		">> ./${dir_name}/aie/mm_top.cpp;

if (( ${k} % 4 == 0 ))
then
	for ((i=0;i<${k}/4;i++));
	do	
		echo \
		"PLIO *out_r${i} = new PLIO(\"out_r${i}\", adf::plio_128_bits, \"./data/output_r${i}.txt\", 250);" >> ./${dir_name}/aie/mm_top.cpp;
    done
else
	for ((i=0;i<${k}/4;i++));
	do	
		echo \
		"PLIO *out_r${i} = new PLIO(\"out_r${i}\", adf::plio_128_bits, \"./data/output_r${i}.txt\", 250);" >> ./${dir_name}/aie/mm_top.cpp;
    done
    let p=${k}/4;
    echo \
		"PLIO *out_r${p} = new PLIO(\"out_r${p}\", adf::plio_128_bits, \"./data/output_r${p}.txt\", 250);" >> ./${dir_name}/aie/mm_top.cpp;
fi

if (( ${k} % 4 == 0 ))
then
	let p=${row_num}*2*${boundry0}+${col_num}*2*${boundry1};
	let q=${k}/4;
	echo \
	"mm_x${k}_x8_graph<COL_OFFSET> myGraph;
	
	simulation::platform<${p},${q}> platform(">> ./${dir_name}/aie/mm_top.cpp;
else
	let p=${row_num}*2*${boundry0}+${col_num}*2*${boundry1};
	let q=${k}/4+1;
	echo \
	"mm_x${k}_x8_graph<COL_OFFSET> myGraph;
	
	simulation::platform<${p},${q}> platform(">> ./${dir_name}/aie/mm_top.cpp;
fi

for ((i=0;i<${row_num}*2*${boundry0};i++));
do
	echo \
	"                                  in_r${i},">> ./${dir_name}/aie/mm_top.cpp;
done

for ((i=0;i<${col_num}*2*${boundry1};i++));
do
	echo \
	"                                  in_c${i},">> ./${dir_name}/aie/mm_top.cpp;
done


if (( ${k} % 4 == 0 ))
then
	for ((i=0;i<${k}/4-1;i++));
	do
		echo \
		"                                  out_r${i},">> ./${dir_name}/aie/mm_top.cpp;
		
	done
	let p=${k}/4-1;
	echo \
		"                                  out_r${p}
													);">> ./${dir_name}/aie/mm_top.cpp;
else
	for ((i=0;i<${k}/4;i++));
	do
		echo \
		"                                  out_r${i},">> ./${dir_name}/aie/mm_top.cpp;
		
	done
	let p=${k}/4;
	echo \
	"                                  out_r${p}
											    );
											    ">> ./${dir_name}/aie/mm_top.cpp;
fi


for ((i=0;i<${row_num}*2*${boundry0};i++));
do  
	echo \
	"connect<> netir${i}(platform.src[${i}], myGraph.in_row[${i}]);">> ./${dir_name}/aie/mm_top.cpp;
done

for ((i=0;i<${col_num}*2*${boundry1};i++));
do  
	let p=i+${row_num}*2*${boundry0};
	echo \
	"connect<> netic${i}(platform.src[${p}], myGraph.in_col[${i}]);">> ./${dir_name}/aie/mm_top.cpp;
done

if (( ${k} % 4 == 0 ))
then
	for ((i=0;i<${k}/4;i++));
	do
		echo \
		"connect<> netor${i}(myGraph.out[${i}],  platform.sink[${i}]);">> ./${dir_name}/aie/mm_top.cpp;
		
	done
else
	for ((i=0;i<${k}/4+1;i++));
	do
		echo \
		"connect<> netor${i}(myGraph.out[${i}],  platform.sink[${i}]);">> ./${dir_name}/aie/mm_top.cpp;
		
	done
fi

echo \
"
#ifdef __AIESIM__

int main(void) {
  myGraph.init();
  myGraph.run(8);
  myGraph.end();
  return 0;
}

#endif">> ./${dir_name}/aie/mm_top.cpp;


echo \
"#include \"mm_graph.h\"

const int ROW=${row_num};
const int COL=${col_num};
const int R_BRO=${R_BRO};
const int C_BRO=${C_BRO};
const int NUM_PACKET_PAC=NUM_ENGINES_PER_PAC/4;    //number of packet in each graph
const int NUM_INSTANCES=ROW*COL;                   //graph number
const int NUM_OUT_PACK=NUM_INSTANCES/4;
using namespace adf;


template <int COL_OFFSET>
class mm_x${k}_x8_graph : public adf::graph {
	
public:
	input_port in_row[ROW*NUM_PACKET_PAC*COL/R_BRO];
	input_port in_col[COL*NUM_PACKET_PAC*ROW/C_BRO];">> ./${dir_name}/aie/mm_top.h;

if (( ${k} < 8 ))
then
	if (( ${k} % 4 == 0 ))
	then
	echo \
	"
		
		adf::pktmerge<4>  mg_out;
		output_port out;
	
		//COL 0-${k}">> ./${dir_name}/aie/mm_top.h;
	elif (( ${k} % 4 == 1 ))
	then
	echo \
	"
		adf::pktmerge<4>  mg_out;
		output_port out[NUM_OUT_PACK+1];
	
		//COL 0-${k}">> ./${dir_name}/aie/mm_top.h;
	
	else
	echo \
	"
		adf::pktmerge<4>  mg_out;
		adf::pktmerge<NUM_INSTANCES%4>  mg_out1;
		output_port out[NUM_OUT_PACK+1];
	
		//COL 0-${k}">> ./${dir_name}/aie/mm_top.h;
	fi
else	
	if (( ${k} % 4 == 0 ))
	then
	echo \
	"
		
		adf::pktmerge<4>  mg_out[NUM_OUT_PACK];
		output_port out[NUM_OUT_PACK];
	
		//COL 0-${k}">> ./${dir_name}/aie/mm_top.h;
		
	elif (( ${k} % 4 == 1 ))
	then
	echo \
	"
		adf::pktmerge<4>  mg_out[NUM_OUT_PACK];
		output_port out[NUM_OUT_PACK+1];
	
		//COL 0-${k}">> ./${dir_name}/aie/mm_top.h;
	else
	echo \
	"
		adf::pktmerge<4>  mg_out[NUM_OUT_PACK];
		adf::pktmerge<NUM_INSTANCES%4>  mg_out1;
		output_port out[NUM_OUT_PACK+1];
	
		//COL 0-${k}">> ./${dir_name}/aie/mm_top.h;
	fi
fi

for ((i=0;i<${k};i++));
do  
echo \
"       mm_x8_graph<COL_OFFSET+${i}, 0>  mm_x8_0_${i};">> ./${dir_name}/aie/mm_top.h;
done

if (( ${k} < 8 ))
then
	if (( ${k} % 4 == 0 )) || (( ${k} % 4 == 1 ))
	then
		echo \
		"	mm_x${k}_x8_graph() {
				
				mg_out = adf::pktmerge<4>::create();
				
		
				//Connect all input ports">> ./${dir_name}/aie/mm_top.h;
	else
		echo \
		"	mm_x${k}_x8_graph() {
				
				mg_out = adf::pktmerge<4>::create();
				mg_out1 = adf::pktmerge<NUM_INSTANCES%4>::create();
		
				//Connect all input ports">> ./${dir_name}/aie/mm_top.h;
	fi
elif (( ${k} % 4 == 0 )) || (( ${k} % 4 == 1 ))
then
	echo \
	"	mm_x${k}_x8_graph() {
			for (int i =0; i<NUM_OUT_PACK; i++)  {
				mg_out[i] = adf::pktmerge<4>::create();
			}
			//Connect all input ports">> ./${dir_name}/aie/mm_top.h;
else
	echo \
	"	mm_x${k}_x8_graph() {
			for (int i =0; i<NUM_OUT_PACK; i++)  {
				mg_out[i] = adf::pktmerge<4>::create();
			}
			mg_out1 = adf::pktmerge<NUM_INSTANCES%4>::create();
			//Connect all input ports">> ./${dir_name}/aie/mm_top.h;
fi


for ((n=0;n<2;n++));
do
for ((i=0;i<${row_num};i++));
do 	
	for ((l=0;l<${boundry0};l++));
	do
		for ((j=0;j<${R_BRO};j++));
		do
			let p=n*${row_num}*${boundry0}+i*${boundry0}+l;
			let q=i*${col_num}+j+l*${R_BRO};
			echo \
			"		connect< pktstream, window< h1*w1*4 > >(in_row[${p}], mm_x8_0_${q}.in[${n}]);">> ./${dir_name}/aie/mm_top.h;
		done
	done
done
done

echo \
"	
		">> ./${dir_name}/aie/mm_top.h;


for ((n=2;n<4;n++));
do
for ((i=0;i<${col_num};i++));
do 	
	for ((l=0;l<${boundry1};l++));
	do
		for ((j=0;j<${C_BRO};j++));
		do
			let p=(n-2)*${col_num}*${boundry1}+i*${boundry1}+l;
			let q=(j+l*${C_BRO})*${col_num}+i;
			echo \
			"		connect< pktstream, window< w1*w2*4 > >(in_col[${p}], mm_x8_0_${q}.in[${n}]);">> ./${dir_name}/aie/mm_top.h;
		done
	done
done
done

echo \
"	
		">> ./${dir_name}/aie/mm_top.h;

if (( ${k} < 8 ))
then
	if (( ${k} % 4 == 0 ))
	then
		for ((n=0;n<${k};n++));
		do
			let q=n%4;
			echo \
			"		adf::connect<adf::window<h1*w2*4>, adf::pktstream > (mm_x8_0_${n}.out, mg_out.in[${q}]);">> ./${dir_name}/aie/mm_top.h;
		done
	else
		for ((n=0;n<${k}-(${k}%4);n++));
		do
			let q=n%4;
			echo \
			"		adf::connect<adf::window<h1*w2*4>, adf::pktstream > (mm_x8_0_${n}.out, mg_out.in[${q}]);">> ./${dir_name}/aie/mm_top.h;
		done
		if (( ${k}%4 == 1 ))
		then
			for ((n=0;n<(${k}%4);n++));
			do
				let q=${k}%4;
				let p=${k}-q+n;
				echo \
				"		adf::connect<adf::window<h1*w2*4>, adf::pktstream > (mm_x8_0_${p}.out, out[NUM_OUT_PACK]);">> ./${dir_name}/aie/mm_top.h;
			done
		else
			for ((n=0;n<(${k}%4);n++));
			do
				let q=${k}%4;
				let p=${k}-q+n;
				echo \
				"		adf::connect<adf::window<h1*w2*4>, adf::pktstream > (mm_x8_0_${p}.out, mg_out1.in[${n}]);">> ./${dir_name}/aie/mm_top.h;
			done
		fi
	fi
else
	if (( ${k} % 4 == 0 ))
	then
		for ((n=0;n<${k};n++));
		do
			let p=n/4;
			let q=n%4;
			echo \
			"		adf::connect<adf::window<h1*w2*4>, adf::pktstream > (mm_x8_0_${n}.out, mg_out[${p}].in[${q}]);">> ./${dir_name}/aie/mm_top.h;
		done
	else
		for ((n=0;n<${k}-(${k}%4);n++));
		do
			let p=n/4;
			let q=n%4;
			echo \
			"		adf::connect<adf::window<h1*w2*4>, adf::pktstream > (mm_x8_0_${n}.out, mg_out[${p}].in[${q}]);">> ./${dir_name}/aie/mm_top.h;
		done
		if (( ${k}%4 == 1 ))
		then
			for ((n=0;n<(${k}%4);n++));
			do
				let q=${k}%4;
				let p=${k}-q+n;
				echo \
				"		adf::connect<adf::window<h1*w2*4>, adf::pktstream > (mm_x8_0_${p}.out, out[NUM_OUT_PACK]);">> ./${dir_name}/aie/mm_top.h;
			done
		else
			for ((n=0;n<(${k}%4);n++));
			do
				let q=${k}%4;
				let p=${k}-q+n;
				echo \
				"		adf::connect<adf::window<h1*w2*4>, adf::pktstream > (mm_x8_0_${p}.out, mg_out1.in[${n}]);">> ./${dir_name}/aie/mm_top.h;
			done
		fi
	fi
fi

if (( ${k} < 8 ))
then
	if (( ${k} % 4 == 0 ))
	then
	echo \
	"

	        adf::connect<adf::pktstream> (mg_out.out[0], out[0]);" >> ./${dir_name}/aie/mm_top.h;
	elif(( ${k} % 4 == 1 ))
	then
	echo \
	"
	       	adf::connect<adf::pktstream> (mg_out.out[0], out[0]);">> ./${dir_name}/aie/mm_top.h;	
	else
	echo \
	"
	       	adf::connect<adf::pktstream> (mg_out.out[0], out[0]);
	    	adf::connect<adf::pktstream> (mg_out1.out[0], out[NUM_OUT_PACK]);">> ./${dir_name}/aie/mm_top.h;
	fi
else
	if (( ${k} % 4 == 0 ))
	then
	echo \
	"
	    	for (int i=0; i<NUM_OUT_PACK; i++)  {
	        	adf::connect<adf::pktstream> (mg_out[i].out[0], out[i]);
	        }" >> ./${dir_name}/aie/mm_top.h;
	elif(( ${k} % 4 == 1 ))
	then
	echo \
	"
		for (int i=0; i<NUM_OUT_PACK; i++)  {
	       		adf::connect<adf::pktstream> (mg_out[i].out[0], out[i]);
	    	}" >> ./${dir_name}/aie/mm_top.h;
	else
	echo \
	"
		for (int i=0; i<NUM_OUT_PACK; i++)  {
	       		adf::connect<adf::pktstream> (mg_out[i].out[0], out[i]);
	    	} 
	    	adf::connect<adf::pktstream> (mg_out1.out[0], out[NUM_OUT_PACK]);">> ./${dir_name}/aie/mm_top.h;
	fi
fi
echo \
"   }
};">> ./${dir_name}/aie/mm_top.h;


echo \
"#ifndef __GRAPH_H__
#define __GRAPH_H__
#include <adf.h>
#include \"para.h\"
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
				adf::source(mm_x8[row])   = \"aie/mm_kernel0.cc\";
			}
			else{
				mm_x8[row]   = adf::kernel::create(mm_kernel1);
				adf::source(mm_x8[row])   = \"aie/mm_kernel1.cc\";
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
">> ./${dir_name}/aie/mm_graph.h;

echo \
"[connectivity]
nk=dma:1:dma_0
">> ./${dir_name}/conn.cfg;



for ((n=0;n<2;n++));
do
for ((i=0;i<${row_num};i++));
do 	

		let p=n*${row_num}+i;
		let q=i*${col_num}+j+l*${R_BRO};
		echo \
		"stream_connect = dma_0.txA_${p}:ai_engine_0.in_r${p}">> ./${dir_name}/conn.cfg;
done
done


for ((n=0;n<2;n++));
do
for ((i=0;i<${col_num};i++));
do 	
	for ((l=0;l<${boundry1};l++));
	do
		let p=i+n*${col_num};
		let q=l+i*${boundry1}+n*${boundry1}*${col_num};
		echo \
		"stream_connect = dma_0.txB_${p}_${l}:ai_engine_0.in_c${q}">> ./${dir_name}/conn.cfg;
	done
done
done

if (( ${k} % 4 == 0 ))
then
	for ((n=0;n<${k}/4;n++));
	do
		echo \
		"stream_connect = ai_engine_0.out_r${n}:dma_0.rxC_${n}">> ./${dir_name}/conn.cfg;
	done
else
	for ((n=0;n<${k}/4+1;n++));
	do
		echo \
		"stream_connect = ai_engine_0.out_r${n}:dma_0.rxC_${n}">> ./${dir_name}/conn.cfg;
	done
fi



echo \
"
[vivado]
param=project.writeIntermediateCheckpoints=1
prop=run.impl_1.STEPS.PLACE_DESIGN.ARGS.DIRECTIVE=ExtraNetDelay_high
prop=run.impl_1.STEPS.PHYS_OPT_DESIGN.ARGS.DIRECTIVE=AggressiveExplore
prop=run.impl_1.STEPS.ROUTE_DESIGN.ARGS.DIRECTIVE=AggressiveExplore">> ./${dir_name}/conn.cfg;

if (( Auto_Compile == 1 ))
then
	cd ./${dir_name};
	./run_aie.sh;
	cd ../;
fi

echo "
Project $dir_name created successfully!
		";
fi