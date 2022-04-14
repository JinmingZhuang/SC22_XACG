i=32;
k=32;
j=32;

total_line=${i}*${j}*2+1;

for ((n=0;n<total_line;n++));
do
	read -r line
	if (( ${n} % 2 == 1 )) && (( ${n} != (total_line-2) )) || (( ${n} == (total_line-1) ))
	then
		IFS=' ' read -ra Key <<< "$line";
		echo "${Key[0]}">> "aiesimulator_output/data/trans_output.txt";
	fi
done < "aiesimulator_output/data/output.txt";
