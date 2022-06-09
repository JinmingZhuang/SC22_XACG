./matrixMulCUBLAS H1=1024 W1=1024 W2=1024 Iter=2000 >> 1_result_1K;


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