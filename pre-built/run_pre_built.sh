source /opt/tools/xilinx/Vitis/2021.2/settings64.sh;
source /opt/xilinx/xrt/setup.sh;

echo \
"
Run starts, it takes 15-20min to finish
"


./hostexe mm_hw.xclbin 1024  1024  1024 40000 >> 1_result_1K;
sleep 30;
./hostexe mm_hw.xclbin 2048  2048  2048 8000 >> 2_result_2K;
sleep 30;
./hostexe mm_hw.xclbin 4096  4096  4096 1800 >> 3_result_4K;
sleep 30;
./hostexe mm_hw.xclbin 8192  8192  8192 230 >> 4_result_8K;
sleep 30;
./hostexe mm_hw.xclbin 16384 16384 16384 36 >> 5_result_16K;
sleep 30;

rm -rf TableVI_Pre.log;
for filename in *_result_*;
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

rm -rf *_result_*;

./hostexe mm_hw.xclbin 1536  1024  81920 600 >> 1_result_1536_1024_81920;
sleep 30;
./hostexe mm_hw.xclbin 1536  2048  25600 1440 >> 2_result_1536_2048_25600;
sleep 30;
./hostexe mm_hw.xclbin 768  1280  122880 360 >> 3_result_768_1280_122880;
sleep 30;
./hostexe mm_hw.xclbin 768  1792  81920 450 >> 4_result_768_1792_81920;
sleep 30;
./hostexe mm_hw.xclbin 1536 1792 25600 1450 >> 5_result_1536_1792_25600;
sleep 30;

rm -rf TableVII_Pre.log;
for filename in *_result_*;
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

rm -rf *_result_*;