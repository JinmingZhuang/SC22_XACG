source /opt/tools/xilinx/Vitis/2021.2/settings64.sh;
source /opt/xilinx/xrt/setup.sh;
./hostexe mm_hw.xclbin 1024  1024  1024 40000 >> result_1K.log;
./hostexe mm_hw.xclbin 2048  2048  2048 8000 >> result_2K.log;
./hostexe mm_hw.xclbin 4096  4096  4096 1800 >> result_4K.log;
./hostexe mm_hw.xclbin 8192  8192  8192 230 >> result_8K.log;
./hostexe mm_hw.xclbin 16384 16384 16384 36 >> result_16K.log;

rm -rf TableVI_Pre.log;
for filename in result_*;
do
	let n=1;
	while read line; do
		if (( ${n} == 6 ))
		then
			my_str=$line;
			echo "${filename}:${my_str}" >>TableVI_Pre.log; 
		fi
		let n=${n}+1;
	done < ./$filename
done

rm -rf result_*;

./hostexe mm_hw.xclbin 1536  1024  81920 600 >> result_1536_1024_81920.log;
./hostexe mm_hw.xclbin 1536  2048  25600 1440 >> result_1536_2048_25600.log;
./hostexe mm_hw.xclbin 768  1280  122880 1300 >> result_768_1280_122880.log;
./hostexe mm_hw.xclbin 768  1792  81920 3600 >> result_768_1792_81920.log;
./hostexe mm_hw.xclbin 1536 1792 25600 450 >> result_1536_1792_25600.log;

rm -rf TableVII_Pre.log;
for filename in result_*;
do
	let n=1;
	while read line; do
		if (( ${n} == 6 ))
		then
			my_str=$line;
			echo "${filename}:${my_str}" >>TableVII_Pre.log; 
		fi
		let n=${n}+1;
	done < ./$filename
done

rm -rf result_*;