for i in ../*_VCK190;
do
	filename='build_dir.hw.xilinx_vck190_base_202110_1/reports/link/imp/impl_1_kernel_util_routed.rpt'
	let n=1;
	while read line; do
		if (( ${n} == 26 ))
		then
			my_str=$line;
			echo "${i}:${my_str}";
		fi
		let n=${n}+1;
	done < ./${i}/$filename
done