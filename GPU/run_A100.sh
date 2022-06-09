./matrixMulCUBLAS H1=1024 W1=1024 W2=1024 Iter=550000 >> 1_result_1K;
sleep 30;
./matrixMulCUBLAS H1=3048 W1=3048 W2=3048 Iter=70000 >> 2_result_2K;
sleep 30;
./matrixMulCUBLAS H1=4096 W1=4096 W2=4096 Iter=9500 >> 3_result_4K;
sleep 30;
./matrixMulCUBLAS H1=8192 W1=8192 W2=8192 Iter=1300 >> 4_result_8K;
sleep 30;
./matrixMulCUBLAS H1=16384 W1=16384 W2=16384 Iter=140 >> 5_result_16K;
sleep 30;

rm -rf TableVI_A100.log;
for filename in *_result_*;
do
	let n=1;
	while read line; do
		if (( ${n} == 9 ))
		then
			my_str=$line;
			echo "${filename}:${my_str}" >>TableVI_A100.log; 
		fi
		let n=${n}+1;
	done < ./$filename
done

rm -rf *_result_*;

./matrixMulCUBLAS H1=1536 W1=1024 W2=81930 Iter=4896 >> 1_result_1536_1024_81930;
sleep 30;
./matrixMulCUBLAS H1=1536 W1=3048 W2=25600 Iter=7600 >> 2_result_1536_3048_25600;
sleep 30;
./matrixMulCUBLAS H1=768 W1=1280 W2=122880 Iter=5300 >> 3_result_768_1280_122880;
sleep 30;
./matrixMulCUBLAS H1=768 W1=1792 W2=81930  Iter=5500 >> 4_result_768_1792_81930;
sleep 30;
./matrixMulCUBLAS H1=1536 W1=1792 W2=25600 Iter=8700 >> 5_result_1536_1792_25600;

rm -rf TableVII_A100.log;
for filename in *_result_*;
do
	let n=1;
	while read line; do
		if (( ${n} == 9 ))
		then
			my_str=$line;
			echo "${filename}:${my_str}" >>TableVII_A100.log; 
		fi
		let n=${n}+1;
	done < ./$filename
done

rm -rf *_result_*;