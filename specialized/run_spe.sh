source /opt/tools/xilinx/Vitis/2021.2/settings64.sh;
source /opt/xilinx/xrt/setup.sh;

./hostexe_1536_1024_81920 mm_hw_1536_1024_81920.xclbin 1125 >> 1_result_1536_1024_81920;
./hostexe_1536_2048_25600 mm_hw_1536_2048_25600.xclbin 620 >> 2_result_1536_2048_25600;
./hostexe_768_1280_122880 mm_hw_768_1280_122880.xclbin 1750 >> 3_result_768_1280_122880;
sleep 30;
./hostexe_768_1792_81920 mm_hw_768_1792_81920.xclbin 1380 >> 4_result_768_1792_81920;
./hostexe_1536_1792_25600 mm_hw_1536_1792_25600.xclbin 600 >> 5_result_1536_1792_25600;

rm -rf TableVII_Spe.log;
for filename in *_result_*;
do
	let n=1;
	while read line; do
		if (( ${n} == 4 ))
		then
			my_str=$line;
			echo "${filename}:${my_str}" >>TableVII_Spe.log; 
		fi
		let n=${n}+1;
	done < ./$filename
done

rm -rf *_result_*;