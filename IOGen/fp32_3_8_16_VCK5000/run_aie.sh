source with-sdaccel;
source /opt/tools/xilinx/Vitis/2021.2/settings64.sh;
source /opt/xilinx/xrt/setup.sh;


make aie PLATFORM_NAME=xilinx_vck5000_gen3x16_xdma_1_202120_1;
