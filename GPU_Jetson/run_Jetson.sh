./matrixMulCUBLAS H1=1024 W1=1024 W2=1024 Iter=48000 >> 1_result_1K;
sleep 30;
./matrixMulCUBLAS H1=2048 W1=2048 W2=2048 Iter=6000 >> 2_result_2K;
sleep 30;
./matrixMulCUBLAS H1=4096 W1=4096 W2=4096 Iter=750 >> 3_result_4K;
sleep 30;
./matrixMulCUBLAS H1=8192 W1=8192 W2=8192 Iter=94 >> 4_result_8K;
sleep 30;
./matrixMulCUBLAS H1=16384 W1=16384 W2=16384 Iter=12 >> 5_result_16K;

rm -rf TableVI_Jetson.log;
for filename in *_result_*;
do
	let n=1;
	while read line; do
		if (( ${n} == 9 ))
		then
			my_str=$line;
			echo "${filename}:${my_str}" >>TableVI_Jetson.log; 
		fi
		let n=${n}+1;
	done < ./$filename
done

rm -rf *_result_*;