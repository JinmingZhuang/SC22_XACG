# SC22_XACG
## Framework Overview
**This repo includes an automatic code generation(ACG) framework XACG for generating the source code targeting on dense matrix-matrix multiply(MM) for AMD/XILINX VCK190 and VCK5000 platforms**. 

**XACG** takes platform information and user-specified design point as input, and automatically generated the systen-level design by launching the following 3 template based components sequentially:<br>
**XACG-KernelGen:** XACG-KernelGen is launched to generate both the single AI Engine(AIE) C code and adaptive data flow (ADF) graph code in C++ for verfying the correctness of single kernel design. MM kernels with int16, int32, fp32 data type in different shape that can be fit in single kernel are supported in current version.<br>

**XACG-IOGen:** Based on the single kernel created by XACG-KernelGen, XACG-IOGen is launched to generate new ADF graph code that defines how packet-switch streams are connected to AIE array which contains 400 AIEs. Single kernel calculating 32x32x32 MM with int32 and fp32 data type is supported to scale out to the AIE array. <br>

**XACG-SysGen:** Based on the AIE array created by XACG-IOGen, XACG-SysGen is launched to generate PL streams, scheduling controller modules to communicate with AIE array and PL on-chip buffers, off-chip AXI data transfer modules to communicate with DDR. Differnet system level designs varying in on-chip buffer size and its implementation option (BRAM or URAM) for int32 and fp32 data type are supported.<br>
<br>
![XACG](https://user-images.githubusercontent.com/77606152/163127636-76361ad2-8057-4f91-9211-cfd0b2c13c8b.png)<br>

## Configuration File "./config_files/input.cfg"
In the following configuration file, users can specify platform, data type, kernel type and mapping strategy of each level. The feasible option of each parameter are illustrated in **( )** The rules of using this configuration file are listed below:
- **Platform** refers to the hardware platform used in the project. VCK5000 and VCK190 are supported in the current framework.
- **KernelGen, IOGen, SysGen** decide if the corresponding ACG should be launched (1 refers to launch). According  to the framework overview, the upper level ACGs are based on the lower level ACGs. Thus, lower level ACG parameter should be 1 when launching the upper level ACGs.([KernelGen, IOGen, SysGen]=[1,0,0] | [1,1,0] | [1,1,1]). When launch control parameter=0, the following parameters in its scope won't work thus can be random number.
- When multiple launch control parameter are assigned to 1, **DATA_TYPE** should be kept the same;
- **I, K, J** refers to the MM size stored and calculated in a single AIE.
- **A, B, C** refers to the BATCH level parameter.
- **X, Y, Z** refers to the BLOCK level parameter.
- **LHS_BUFF, RHS_BUFF, OUT_BUFF** dicide the implmentation option for LHS, RHS and output buffers. 1 refers to URAM and 0 refers to BRAM. For example, LHS_BUFF=1 means LHS buffer is implemented by URAM.
- **AutoCompile** decides whether to automatically run compilation flow after generating the source code. 1 refers to combining XACG and compilation together.
```sh
Platform:VCK5000;         #(VCK5000 | VCK190)
KernelGen:1;              #(0 | 1) scope 1
	DATA_TYPE:fp32;  #(int32 | int16 | fp32)
	KRL_TYPE:1;       #(0 | 1)
	I:16;             #MM with size I*K*J will be calculated in a single AIE
	K:16;            
	J:16;
IOGen:0;                  #(0 | 1) scope 2
	DATA_TYPE:fp32;  #(int32 | fp32)
	A:12;             #BATCH Level patameter A, B, C
	B:8;              #A*B*C -> Number of AIEs in AIE array
	C:4;
SysGen:0;                 #(0 | 1) scope 3
	DATA_TYPE:fp32;  #(int32 | fp32)
	X:4;              #BLOCK level parameter
	Y:8;              #X,Y,Z decide the on-chip buffer utilization
	Z:1;
	LHS_BUFF:1;       #On-chip buffer implementation option
	RHS_BUFF:0;      
	OUT_BUFF:0;     
AutoCompile:1;                #(0 | 1)
```

## Versal ACAP Experiment Environment<br>
Following environments are automatically set when launch each ACGs. The detail can be viewed in run.aie.sh or run.sys.sh after generating the corresponding code. <br>
1. VCK5000: Vitis 2021.2, XRT 2021.2 <br>
```sh
source /opt/tools/xilinx/Vitis/2021.2/settings64.sh
source /opt/xilinx/xrt/setup.sh
```
2. VCK190: Vitis 2021.1 <br>
```sh
VIV_VER=2021.1 SDA_VER=2021.1 . with-sdaccel
```

## VCK5000 Int32 MM Demo<br>
In this section, we take fp32 datatype of case 2 as an exmple to demonstrate how our framework works. In our experiment, we specify the single kernel computation as 32x32x32 and tiling factor of A, B and C to 12, 8, 4 respectively. All the different size listed in Table VI are the result of different X, Y, Z and T_Z. X, Y, Z are specified in **input.cfg** file, whereas T_Z is configured in /host/host.cpp. Thus for case 2 the corrsponded number of X, Y, Z and T_Z are shown bellow. To reproduce our experiment result, one can simply change the number of X, Y, Z since T_Z will be automatical generated.<br>
- Case 2 : 1536 × 2048 × 128 × 200 -> X=4, Y=8, Z=1, T_Z=200<br>

![image](https://user-images.githubusercontent.com/77606152/163144535-3d8dd67e-21da-4d1b-a0ac-4600cfbd9e5f.png)<br>

After getting the parameters, four simple steps are needed to reproduce the results.<br>
**1. Automatically generate source code, compilation and run demo**<br>
For convenience, by assigning 1 to the "AutoCompile" Parameter in ".cfg" file, our framework can automatically launch the compilation processes after XACG generate the source code. User could also do step by step code generation and compilation following the instructions in the later subsection.
```sh
git clone ${repo_path}
cd SC22_XACG
git checkout master
./AutoGen
./hostexe mm_hw.xclbin >> result.log
```
**2. ".cfg" file configuration**<br>
Start from here, the instructions described below acheives the same results of the first automatic step. We will use pre-defined file config_files/1536_2048_128_200.cfg as input in this demo. <br>
```sh
Platform:VCK5000;
KernelGen:1;
	DATA_TYPE:int32;
	KRL_TYPE:1;
	I:32;
	K:32;
	J:32;
IOGen:1;
	DATA_TYPE:int32;
	A:12;
	B:8;
	C:4;
SysGen:1;
	DATA_TYPE:int32;
	X:4;
	Y:8;
	Z:1;
	LHS_BUFF:1;
	RHS_BUFF:0;
	OUT_BUFF:1;
AutoCompile:0;
```

**3. Code generation by XACG**<br>
XACG takes ".cfg" as input file. In order to reproduce the experiment results, we prepared all the ".cfg" file of listed int32 experiments on VCK5000 in ./config_files with the name specify their MM size. If not specify input file. Then XACG will take input.cfg as default settting.<br>
```sh
./AutoGen.sh config_files/1536_2048_128_200.cfg
```
**4. Compilation flow of Single Kernel, AIE Array and System**<br>
1. KernelGen leverages AIE compiler as its banckend ( **3-5 min** )<br>
```sh
cd KernelGen/${PRO_PATH}
./run_aie.sh
```

2. IOGen leverages AIE compiler as its banckend ( **30-60 min** )<br>
```sh
cd IOGen/${PRO_PATH}
./run_aie.sh
```

3. SysGen leverages Vitis and Vivado as its banckend ( **3-7 hours** )<br>
```sh
cd SysGen/${PRO_PATH}
./run_sys.sh
```

4. On board execution ( **3-5 min** )<br><br>
By running the following instructions, user can view throughput and computation result in result.log.
```sh
source /opt/tools/xilinx/Vitis/2021.2/settings64.sh
source /opt/xilinx/xrt/setup.sh
cd SysGen/${PRO_PATH}
./hostexe mm_hw.xclbin >> result.log
```

**5. Expected demo result**<br>
It takes 4-8 hours to go through the whole processes. We run the MM for 4000 iterations and calculate the average throughput of a single iteration and the expected throughput should be 4.3-4.4 TOPs as shown in the following figure. For computation result comparison, we use  OpenMP library to leverage multiple threads of CPU.<br>
![image](https://user-images.githubusercontent.com/77606152/163462586-abfe4d07-749b-43cb-841c-916747b665a5.png)<br>

## NVIDIA A100 GPU FP32 MM<br>
We set up the A100 GPU experiment for MM with FP32 data type by using cublasSgemm() API in cuBLAS from CUDA Toolkit 11.3. Only one compilation is needed for testing of different MM shapes.<br>
**1. Compilation flow of MM on A100 GPU** ( **1-2 min** )<br>
```sh
cd GPU
make
```

**2. A100 GPU On board execution** ( **1-2 min** )<br>
In the following instruction, ${H1}, ${W1} and ${W2} refer to the total matrix size of our experiment design points. ${H1}=T_X x X x A x I, ${W1}=T_Y x Y x B x K, ${W2}=T_Z x Z x C x J. For the demo case with size 1536 × 2048 × 128 × 200, ${H1} should be set to 1536, ${W1} should be set to 2048, ${W2} should be set to 128 × 200 which means 25600.<br>
```sh
./matrixMulCUBLAS H1=${H1} W1=${W1} W2=${W2}
```

**3. Expected results on GPU for demo case** <br>
The same as VCK5000 experiment, we run the MM for 4000 iterations and calculate the average of throughput of a single iteration. The expected throughput of demo case on A100 GPU should be 16-17 TFLOPs as shown in the following figure.<br>
![image](https://user-images.githubusercontent.com/77606152/163463308-ab7df6ee-2dd3-4cb8-9c03-42ab1ae21394.png)<br>


## Experiment customization<br>
**1.System level Throuput Experiment**<br>
To reproduce the other experiment results, one can simply change the number of X, Y, Z and T_Z will be automatical generated. We listed our settings below. Users can use XACG in the same way as mentioned in demo section. The configuration file for these five design point of int32 data type on VCK5000 are prepared in config_files<br>
- Case 1 : 1536 × 1024 × 256 × 320 -> X=4, Y=4, Z=2, T_Z=320, [LHS_BUFF,RHS_BUFF,OUT_BUFF]=[1,0,1]
- Case 2 : 1536 × 2048 × 128 × 200 -> X=4, Y=8, Z=1, T_Z=200, [LHS_BUFF,RHS_BUFF,OUT_BUFF]=[1,0,1]
- Case 3 :  768 × 1280 × 384 × 320 -> X=2, Y=5, Z=3, T_Z=320, [LHS_BUFF,RHS_BUFF,OUT_BUFF]=[1,1,0]
- Case 4 :  768 × 1792 × 256 × 320 -> X=2, Y=7, Z=2, T_Z=320, [LHS_BUFF,RHS_BUFF,OUT_BUFF]=[1,1,0]
- Case 5 : 1536 × 1792 × 128 × 200 -> X=4, Y=7, Z=1, T_Z=200, [LHS_BUFF,RHS_BUFF,OUT_BUFF]=[1,0,1]

**2. Resource utilization and timig report**<br>
1. For VCK5000
```sh
cd SysGen/script_VCK5000
./hw_parse.sh 
./time_parse.sh
```

2. For VCK190
```sh
cd SysGen/script_VCK190
./hw_parse.sh 
./time_parse.sh
```
**3. Single Kernel Effciency**<br>
In this section, users can launch the KernelGen independently by assigning Sys_Gen and IO_Gen to 0. In the rest of this section, we will use int32 MM kernel 0 with size 32*32*32 as an example to showcase how to verify the efficiency of a single kernel. <br>

![image](https://user-images.githubusercontent.com/77606152/163173087-bd8604f9-d069-47a1-8a9c-0c0845e410ce.png)<br>

1. **Modify input.cfg file**<br>
```sh
Platform:VCK190;
KernelGen:1;
	DATA_TYPE:int32;
	KRL_TYPE:0;
	I:32;
	K:32;
	J:32;
IOGen:0;
	DATA_TYPE:any;
	A:any;
	B:any;
	C:any;
SysGen:0;
	DATA_TYPE:any;
	X:any;
	Y:any;
	Z:any;
	LHS_BUFF:any;
	RHS_BUFF:any;
	OUT_BUFF:any;
```

2. **Launch KernelGen**<br>
```sh
either cd KernelGen; ./KernelGen.sh;
or ./AutoGen.sh
```
3. **Compilation and Simulation**
```sh
cd KernelGen/${PRO_PATH}
./run_aie.sh
```

4. **Verify Single kernel Efficiency** <br>
```sh
VIV_VER=2021.1 SDA_VER=2021.1 . with-sdaccel   #VCK190 Environment
cd ${KEL_PRO_PATH}
vitis_analyzer aiesimulator_output/default.aierun_summary
```
After open the GUI of vitis_analyzer, we mark the start time and stop time of mm_kernel0 as shown in the following picture. The total elapsed cycle can be calculated as 5483-1154=4329 cycles. For int32 data type, it can calucalte 8 MACs/cyc. The theoretical execution cycle should be 32*32*32/8=4096 cycles. Thus the efficiency can be calculated as EFF = 4096/4329 ≈ 94.6%. Note that, there are small number of cycles variation during different launch of a single kernel thus lead to small changes in efficiency.<br>

![image](https://user-images.githubusercontent.com/77606152/163173178-0ac63bb5-fc3e-43b5-9ec1-90f2fda5c764.png)<br>
