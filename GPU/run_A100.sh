./matrixMulCUBLAS H1=1024 W1=1024 W2=1024 Iter=550000 >> result_1K.log;
sleep 30;
./matrixMulCUBLAS H1=3048 W1=3048 W2=3048 Iter=70000 >> result_2K.log;
sleep 30;
./matrixMulCUBLAS H1=4096 W1=4096 W2=4096 Iter=9500 >> result_4K.log;
sleep 30;
./matrixMulCUBLAS H1=8192 W1=8192 W2=8192 Iter=1300 >> result_8K.log;
sleep 30;
./matrixMulCUBLAS H1=16384 W1=16384 W2=16384 Iter=140 >> result_16K.log;
sleep 30;

rm -rf TableVI_A100.log;
for filename in result_*;
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

rm -rf result_*;

./matrixMulCUBLAS H1=1536 W1=1024 W2=81930 Iter=4896 >> result_1536_1024_81930.log;
sleep 30;
./matrixMulCUBLAS H1=1536 W1=3048 W2=25600 Iter=7600 >> result_1536_3048_25600.log;
sleep 30;
./matrixMulCUBLAS H1=768 W1=1280 W2=122880 Iter=5300 >> result_768_1280_122880.log;
sleep 30;
./matrixMulCUBLAS H1=768 W1=1792 W2=81930  Iter=5500 >> result_768_1792_81930.log;
sleep 30;
./matrixMulCUBLAS H1=1536 W1=1792 W2=25600 Iter=8700 >> result_1536_1792_25600.log;

rm -rf TableVII_A100.log;
for filename in result_*;
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

rm -rf result_*;