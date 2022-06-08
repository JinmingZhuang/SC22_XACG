./matrixMulCUBLAS H1=1024 W1=1024 W2=1024 Iter=48000 >> result_1K.log;
sleep 30;
./matrixMulCUBLAS H1=3048 W1=3048 W2=3048 Iter=6000 >> result_2K.log;
sleep 30;
./matrixMulCUBLAS H1=4096 W1=4096 W2=4096 Iter=94 >> result_4K.log;
sleep 30;
./matrixMulCUBLAS H1=8192 W1=8192 W2=8192 Iter=1300 >> result_8K.log;
sleep 30;
./matrixMulCUBLAS H1=16384 W1=16384 W2=16384 Iter=12 >> result_16K.log;
sleep 30;

rm -rf TableVI_Jetson.log;
for filename in result_*;
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

rm -rf result_*;