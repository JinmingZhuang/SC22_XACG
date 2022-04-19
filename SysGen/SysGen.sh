if [ "$#" -eq 1 ] 
then
    input=../$1;
else
    input="../config_files/input.cfg";
fi

for ((n=1;n<=21;n++));
do
    read -r line
    if (( ${n} == 1 ))
    then
        IFS=':' read -ra Key <<< "$line";
        value_temp="${Key[1]}"; 
        unset IFS
        IFS=';' read -ra Value <<< "$value_temp";
        platform="${Value[0]}";
    elif (( ${n} == 14 ))
    then
        IFS=':' read -ra Key <<< "$line";
        value_temp="${Key[1]}"; 
        unset IFS
        IFS=';' read -ra Value <<< "$value_temp";
        data_type="${Value[0]}"; 
    elif (( ${n} == 15 ))
    then
        IFS=':' read -ra Key <<< "$line";
        value_temp="${Key[1]}"; 
        unset IFS
        IFS=';' read -ra Value <<< "$value_temp";
        x="${Value[0]}";
    elif (( ${n} == 16 ))
    then
        IFS=':' read -ra Key <<< "$line";
        value_temp="${Key[1]}"; 
        unset IFS
        IFS=';' read -ra Value <<< "$value_temp";
        y="${Value[0]}";
    elif (( ${n} == 17 ))
    then
        IFS=':' read -ra Key <<< "$line";
        value_temp="${Key[1]}"; 
        unset IFS
        IFS=';' read -ra Value <<< "$value_temp";
        z="${Value[0]}";
    elif (( ${n} == 18 ))
    then
        IFS=':' read -ra Key <<< "$line";
        value_temp="${Key[1]}"; 
        unset IFS
        IFS=';' read -ra Value <<< "$value_temp";
        l_buff="${Value[0]}";
    elif (( ${n} == 19 ))
    then
        IFS=':' read -ra Key <<< "$line";
        value_temp="${Key[1]}"; 
        unset IFS
        IFS=';' read -ra Value <<< "$value_temp";
        r_buff="${Value[0]}";
    elif (( ${n} == 20 ))
    then
        IFS=':' read -ra Key <<< "$line";
        value_temp="${Key[1]}"; 
        unset IFS
        IFS=';' read -ra Value <<< "$value_temp";
        o_buff="${Value[0]}";
    elif (( ${n} == 21 ))
    then
        IFS=':' read -ra Key <<< "$line";
        value_temp="${Key[1]}"; 
        unset IFS
        IFS=';' read -ra Value <<< "$value_temp";
        Auto_Compile="${Value[0]}";
    fi
done < "$input"

if (( ${l_buff} == 0 ))
then
    L_buffer="BRAM";
else
    L_buffer="URAM";
fi
if (( ${r_buff} == 0 ))
then
    R_buffer="BRAM";
else
    R_buffer="URAM";
fi
if (( ${o_buff} == 0 ))
then
    O_buffer="BRAM";
else
    O_buffer="URAM";
fi
file_name="${data_type}_${x}_${y}_${z}_${l_buff}_${r_buff}_${o_buff}_${platform}";

let enable=1;
for e in *_${platform};
do
    dir_name="$e";
    if [[ "$file_name" == "$dir_name" ]]
    then
        if [[ ${Auto_Compile} == 1 ]]
        then
            cd ./${file_name};
            ./run_sys.sh;
            cd ../;
        fi
        echo "
Project $file_name exsists and can be used in the later steps
        ";
        enable=0;
    fi
done

if (( ${enable} == 1 ))
then
mkdir ./${file_name};
mkdir ./${file_name}/host;
mkdir ./${file_name}/kernel;
cp -r ../IOGen/${data_type}_12_8_4_${platform}/conn.cfg ./${file_name};
cp -r ../IOGen/${data_type}_12_8_4_${platform}/Makefile ./${file_name};
cp -r ../IOGen/${data_type}_12_8_4_${platform}/aie ./${file_name};


if [[ "$platform" == "VCK5000" ]] || [[ "$platform" == "vck5000" ]]
then
    echo \
    "source with-sdaccel;
source /opt/tools/xilinx/Vitis/2021.2/settings64.sh;
source /opt/xilinx/xrt/setup.sh;


cp -r ../../IOGen/${data_type}_12_8_4_${platform}/libadf.a ./;
make all PLATFORM_NAME=xilinx_vck5000_gen3x16_xdma_1_202120_1 Frequency=250;">> ./${file_name}/run_sys.sh;
chmod +x ./${file_name}/run_sys.sh;

elif [[ "$platform" == "VCK190" ]] || [[ "$platform" == "vck190" ]]
then

    echo \
    "VIV_VER=2021.1 SDA_VER=2021.1 . with-sdaccel;
cp -r ../../IOGen/${data_type}_12_8_4_${platform}/libadf.a ./;
make build PLATFORM_NAME=xilinx_vck190_base_202110_1 Frequency=230;">> ./${file_name}/run_sys.sh;
chmod +x ./${file_name}/run_sys.sh;
else 
    echo "Specified platform currently is not supported. Please input VCK5000 or VCK190"
fi

z_name=${x}_${y}_${z};
if [[ "$z_name" == "4_4_2" ]]
then
    T_Z=640;
elif [[ "$z_name" == "4_8_1" ]]
then
    T_Z=200;
elif [[ "$z_name" == "2_5_3" ]]
then
    T_Z=640;
elif [[ "$z_name" == "2_7_2" ]]
then
    T_Z=640;
elif [[ "$z_name" == "4_7_1" ]]
then
    T_Z=200;
else
    T_Z=640;
fi


if [ ${data_type} == "int32" ]
then
echo \
"
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <fstream>
#include <time.h>
#include <omp.h>

// This is used for the PL Kernels
#include \"xrt.h\"
#include \"experimental/xrt_kernel.h\"

#define PACKET_NUM 4 
#define H1 32
#define W1 32
#define W2 32
#define A 12
#define B 8
#define C 4
#define X ${x}
#define Y ${y}
const int Z=${T_Z};
const int DATA_SIZE1=H1*W1;
const int DATA_SIZE2=W1*W2;
const int OUT_SIZE=H1*W2;


static std::vector<char> load_xclbin(xrtDeviceHandle device, const std::string& fnm) {
    if (fnm.empty()) throw std::runtime_error(\"No xclbin specified\");

    // load bit stream
    std::ifstream stream(fnm);
    stream.seekg(0, stream.end);
    size_t size = stream.tellg();
    stream.seekg(0, stream.beg);

    std::vector<char> header(size);
    stream.read(header.data(), size);

    auto top = reinterpret_cast<const axlf*>(header.data());
    if (xrtDeviceLoadXclbin(device, top)) throw std::runtime_error(\"Xclbin loading failed\");

    return header;
}


void mm_sw( uint32_t A1[X][Y][A][B][DATA_SIZE1], uint32_t B1[Z][Y][B][C][DATA_SIZE2], uint32_t C1[Z][X][A][C][OUT_SIZE]){

#pragma omp parallel
    {
        int tid = omp_get_thread_num();
        if( tid == 0 ){
            int nthreads = omp_get_num_threads();
            std::cout << \"Running OpenMP with \" << nthreads << \" threads...\n\";
        }
    }

    
    uint32_t sum = 0;
#pragma omp parallel for private(sum)
    for(int z=0;z<Z;z++){
        for (int c=0; c<C; c++){
            for (int w2=0; w2<W2; w2++){
                for (int x=0; x<X; x++){
                    for (int a=0; a<A; a++){
                        for (int h1=0; h1<H1; h1++){
                            sum=0;
                            for (int y=0; y<Y; y++){
                                for (int b=0; b < B; b++) {
                                    for (int w1=0; w1 <W1 ; w1++) {
                                        sum=sum+A1[x][y][a][b][w1+h1*W1]*B1[z][y][b][c][w1*W2+w2];
                                    }
                                }
                            }
                            C1[z][x][a][c][w2+h1*W2]=sum;
                        }
                    }
                }
            }
        }
    }

}

int main(int argc, char** argv) {
    //////////////////////////////////////////
    // Open xclbin
    //////////////////////////////////////////
    if(argc != 2) {
    std::cout << \"Usage: \" << argv[0] <<\" <xclbin>\" << std::endl;
    return EXIT_FAILURE;
    }
    char* xclbinFilename = argv[1];
    //////////////////////////////////////////
    // Open xclbin
    //////////////////////////////////////////
    auto dhdl = xrtDeviceOpen(1); // Open Device the local device
    if (dhdl == nullptr) throw std::runtime_error(\"No valid device handle found. Make sure using right xclOpen index.\");
    auto xclbin = load_xclbin(dhdl, xclbinFilename);
    auto top = reinterpret_cast<const axlf*>(xclbin.data());

    const int sizeIn1 = DATA_SIZE1*A*B*X*Y;
    const int sizeIn2 = DATA_SIZE2*B*C*Y*Z;
    const int sizeOut = OUT_SIZE*A*C*X*Z;

    uint32_t (*DataInput0)[Y][A][B][DATA_SIZE1] = new uint32_t[X][Y][A][B][DATA_SIZE1];
    uint32_t (*DataInput1)[Y][B][C][DATA_SIZE2] = new uint32_t[Z][Y][B][C][DATA_SIZE2];
    uint32_t (*golden)[X][A][C][OUT_SIZE] = new uint32_t[Z][X][A][C][OUT_SIZE];

    srand (time(0));
    for (int m = 0; m < X; m++) {
        for (int n = 0; n < Y; n++) {
            for (int k = 0; k < A; k++) {
                for (int j = 0; j < B; j++) {
                    for (int i = 0; i < DATA_SIZE1; i++) {
                        DataInput0[m][n][k][j][i] = rand();
                    }
                }
            }
        }
    }

    srand (time(0));
    for (int m = 0; m < Z; m++) {
        for (int n = 0; n < Y; n++) {
            for (int k = 0; k < B; k++) {
                for (int j = 0; j < C; j++) {
                    for (int i = 0; i < DATA_SIZE2; i++) {
                        DataInput1[m][n][k][j][i] = rand();
                    }
                }
            }
        }
    }
    
    //Allocate input mem
    xrtBufferHandle in_bohdl0 = xrtBOAlloc(dhdl, sizeIn1 * sizeof(uint32_t), 0, 0);
    auto in_bomapped0 = reinterpret_cast<uint32_t*>(xrtBOMap(in_bohdl0));


    xrtBufferHandle in_bohdl1 = xrtBOAlloc(dhdl, sizeIn2 * sizeof(uint32_t), 0, 0);
    auto in_bomapped1 = reinterpret_cast<uint32_t*>(xrtBOMap(in_bohdl1));

    for(int m=0;m<Y;m++){
        for(int k=0;k<B;k++){
            for(int p=0;p<W1;p++){
                for(int n=0;n<X;n++){
                    for(int j=0;j<A;j++){
                        for(int i=0;i<H1;i++){
                            in_bomapped0[i+j*H1+n*A*H1+p*X*A*H1+k*X*A*DATA_SIZE1+m*B*X*A*DATA_SIZE1]=DataInput0[n][m][j][k][i*W1+p];
                        }
                    }
                }
            }
        }
    }

    for(int z=0;z<Z;z++){
        for(int k=0;k<C;k++){
            for(int j=0;j<W2;j++){
                for(int n=0;n<Y;n++){
                    for(int i=0;i<B;i++){
                        for (int m=0;m<W1;m++){
                            in_bomapped1[m+i*W1+n*B*W1+j*Y*B*W1+k*DATA_SIZE2*B*Y+z*C*DATA_SIZE2*B*Y]=DataInput1[z][n][i][k][m*W2+j];
                        }
                    }
                }
            }
        }
    }
    

    // sync input memory
    xrtBOSync(in_bohdl0, XCL_BO_SYNC_BO_TO_DEVICE , sizeIn1* sizeof(uint32_t),0);
    xrtBOSync(in_bohdl1, XCL_BO_SYNC_BO_TO_DEVICE , sizeIn2* sizeof(uint32_t),0);
    
    //Allocate output buffer
    uint32_t *out_bomapped; 
    xrtBufferHandle out_bohdl; 

    out_bohdl = xrtBOAlloc(dhdl, sizeOut* sizeof(uint32_t), 0, 0);
    out_bomapped = reinterpret_cast<uint32_t*>(xrtBOMap(out_bohdl));
    


    //for (int i=0;i<iter;i++){
        //Open PL kernels handles
        std::cout << \"Kernel run\n\";
        xrtKernelHandle dma_khdl = xrtPLKernelOpen(dhdl, top->m_header.uuid, \"dma\");
        xrtRunHandle dma_rhdl;
        //profile aie mm 
        double kernel_time_in_sec = 0;
        std::chrono::duration<double> kernel_time(0);
        auto kernel_start = std::chrono::high_resolution_clock::now();
        const int iter=4000;
        for (int i=0;i<iter;i++){
        // start input kernels run handles
        dma_rhdl = xrtKernelRun(dma_khdl, in_bohdl0, in_bohdl1,out_bohdl,Z/${z},
                            nullptr, nullptr, nullptr, nullptr,
                            nullptr, nullptr, nullptr, nullptr,
                            nullptr, nullptr, nullptr, nullptr,
                            nullptr, nullptr, nullptr, nullptr,
                            nullptr, nullptr, nullptr, nullptr,
                            nullptr, nullptr, nullptr, nullptr,
                            nullptr, nullptr, nullptr, 
                            nullptr, nullptr, nullptr,
                            nullptr, nullptr, nullptr, 
                            nullptr, nullptr, nullptr,
                            nullptr, nullptr, nullptr, 
                            nullptr, nullptr, nullptr,
                            nullptr, nullptr, nullptr, 
                            nullptr, nullptr, nullptr,
                            nullptr, nullptr, nullptr, 
                            nullptr, nullptr, nullptr,
                            nullptr, nullptr, nullptr, 
                            nullptr, nullptr, nullptr,
                            nullptr, nullptr, nullptr, 
                            nullptr, nullptr, nullptr,
                            nullptr, nullptr, nullptr, 
                            nullptr, nullptr, nullptr,
                            nullptr, nullptr, nullptr, nullptr,
                            nullptr, nullptr, nullptr, nullptr,
                            nullptr, nullptr, nullptr, nullptr);



    
        //////////////////////////////////////////
        // wait for mm2s done
        //////////////////////////////////////////
        //Wait for kernel finish
        auto state = xrtRunWait(dma_rhdl);
        }
 
        auto kernel_end = std::chrono::high_resolution_clock::now();
        kernel_time = std::chrono::duration<double>(kernel_end - kernel_start);
        kernel_time_in_sec = kernel_time.count();
        double TOPS = H1 * 1.024 * 3.84 * X * Y * Z * 2 *iter* 1e-4 / kernel_time_in_sec;
        std::cout << std::endl;
        std::cout << std::endl;
        std::cout << \"Total execution time is: \"<< kernel_time_in_sec <<\"s, TOPS = \" << TOPS << \" GOPS/s\" << std::endl;
        std::cout << std::endl;
        std::cout << std::endl;
        // sync output memory

        xrtBOSync(out_bohdl, XCL_BO_SYNC_BO_FROM_DEVICE , sizeOut* sizeof(uint32_t),/*OFFSET=*/ 0);
        
    
        xrtRunClose(dma_rhdl);
        xrtKernelClose(dma_khdl);
    //}

    
    //////////////////////////////////////////
    // Comparing the execution data to the golden data
    //////////////////////////////////////////
    
    mm_sw(DataInput0, DataInput1, golden);
//
    int errorCount = 0;
    {   
        for(int z=0;z<Z;z++){
            for (int c=0; c<C; c++){
                for (int w2=0; w2<W2; w2++){
                    for (int x=0; x<X; x++){
                        for (int a=0; a<A; a++){
                            for (int h1=0; h1<H1; h1++){
                                if((uint32_t)(out_bomapped[h1+a*H1+x*H1*A+w2*X*A*H1+c*OUT_SIZE*A*X+z*C*OUT_SIZE*A*X]) != golden[z][x][a][c][h1*W2+w2]){
                                    printf(\"Error found out_bomapped[%d]!=golden[%d][%d][%d][%d][%d], %d!=%d \n\", h1+a*H1+x*H1*A+w2*X*A*H1+c*OUT_SIZE*A*X+z*C*OUT_SIZE*A*X,z,x,a,c,h1*W2+w2,out_bomapped[h1+a*H1+x*H1*A+w2*X*A*H1+c*OUT_SIZE*A*X+z*C*OUT_SIZE*A*X], golden[z][x][a][c][h1*W2+w2]);
                                    errorCount++;
                                }
                                //else{
                                //    printf(\"Correct found out_bomapped[%d]=golden[%d][%d][%d][%d][%d], %d=%d \n\", h1+a*H1+x*H1*A+w2*X*A*H1+c*OUT_SIZE*A*X+z*C*OUT_SIZE*A*X,z,x,a,c,h1*W2+w2,out_bomapped[h1+a*H1+x*H1*A+w2*X*A*H1+c*OUT_SIZE*A*X+z*C*OUT_SIZE*A*X], golden[z][x][a][c][h1*W2+w2]);
                                //}
                            }
                        }
                    }
                }
            }
        }
        if (errorCount)
            printf(\"Test failed with %d errors\n\", errorCount);
        else
            printf(\"TEST PASSED\n\");
    }

    delete[] DataInput0;
    delete[] DataInput1;
    delete[] golden;

    //////////////////////////////////////////
    // clean up XRT
    //////////////////////////////////////////

    std::cout << \"Releasing remaining XRT objects...\n\";
    
    xrtBOFree(out_bohdl);
    xrtBOFree(in_bohdl0);
    xrtBOFree(in_bohdl1);
    xrtDeviceClose(dhdl);

    return 0;
}
">> ./${file_name}/host/host.cpp;

    echo \
"
#include <stdint.h>
#include "'"packet_sender.hpp"'"

static const unsigned int tile0[10]={0, 1, 0, 2, 1, 0, 3, 2, 1, 0};
static const unsigned int tile2[6]={3, 2, 1, 3, 2, 3};
static const unsigned int packet_id0[10]={0, 0, 1, 0, 1, 2, 0, 1, 2, 3};
static const unsigned int packet_id2[6]={1, 2, 3, 2, 3, 3};


ap_uint<32> generateHeader(unsigned int pktType, unsigned int ID){
#pragma HLS inline
    ap_uint<32> header=0;
    header(4,0)=ID;
    header(11,5)=0;
    header(14,12)=pktType;
    header[15]=0;
    header(20,16)=-1;//source row
    header(27,21)=-1;//source column
    header(30,28)=0;
    header[31]=header(30,0).xor_reduce()?(ap_uint<1>)0:(ap_uint<1>)1;
    return header;
}


void loadA(ap_uint<AXI_WIDTH_512>* a_in, ap_uint<PLIO_WIDTH> a_buf[A*(B/PACKET_NUM)][X*Y][LEFT_SIZE*PACKET_NUM],bool enable){
#pragma HLS inline off
    if(enable){
        for(int m=0;m<Y;m++){
            for(int k=0;k<W1*B;k++){
                for(int n=0;n<X;n++){
                    for(int j=0;j<A;j++){
                        for(int i=0;i<(H1/A_PER_TRA);i++){
                            #pragma HLS PIPELINE II = 1
                            int pos=i+j*(H1/A_PER_TRA)+n*A*(H1/A_PER_TRA)+k*A*X*(H1/A_PER_TRA)+m*W1*B*X*A*(H1/A_PER_TRA);
                            ap_uint<AXI_WIDTH_512> temp=a_in[pos];
                            a_buf[j+A*(k/(W1*PACKET_NUM))][n*Y+m][i*4+(k%(W1*PACKET_NUM))*(H1/NUM_PER_TRA)]=temp(127,0);  // 4=512/128
                            a_buf[j+A*(k/(W1*PACKET_NUM))][n*Y+m][i*4+1+(k%(W1*PACKET_NUM))*(H1/NUM_PER_TRA)]=temp(255,128);
                            a_buf[j+A*(k/(W1*PACKET_NUM))][n*Y+m][i*4+2+(k%(W1*PACKET_NUM))*(H1/NUM_PER_TRA)]=temp(383,256);
                            a_buf[j+A*(k/(W1*PACKET_NUM))][n*Y+m][i*4+3+(k%(W1*PACKET_NUM))*(H1/NUM_PER_TRA)]=temp(511,384);
                        }
                    }
                }
            }
        }
    }
    
}

void loadB(ap_uint<AXI_WIDTH_512>* b_in, ap_uint<PLIO_WIDTH> b_buf[(B/PACKET_NUM)*C][Y*Z][RIGHT_SIZE*PACKET_NUM],bool enable, int rd){
#pragma HLS inline off
    if(enable){
        for(int z=0;z<Z;z++){
            for(int k=0;k<C;k++){
                for(int j=0;j<W2;j++){
                    for(int n=0;n<Y;n++){
                        for(int i=0;i<B;i++){
                            for (int m=0;m<(W1/A_PER_TRA);m++){
                                #pragma HLS PIPELINE II = 1
                                ap_uint<AXI_WIDTH_512> temp;
                                int pos=m+i*(W1/A_PER_TRA)+n*(W1/A_PER_TRA)*B+j*Y*(W1/A_PER_TRA)*B+k*Y*W2*(W1/A_PER_TRA)*B+z*W2*(W1/A_PER_TRA)*B*C*Y+rd*Z*W2*(W1/A_PER_TRA)*B*C*Y;
                                temp=b_in[pos];
                                b_buf[(i/PACKET_NUM)*C+k][n+z*Y][m*4+j*(W1/NUM_PER_TRA)+(i%PACKET_NUM)*RIGHT_SIZE]=temp(127,0);
                                b_buf[(i/PACKET_NUM)*C+k][n+z*Y][m*4+1+j*(W1/NUM_PER_TRA)+(i%PACKET_NUM)*RIGHT_SIZE]=temp(255,128);
                                b_buf[(i/PACKET_NUM)*C+k][n+z*Y][m*4+2+j*(W1/NUM_PER_TRA)+(i%PACKET_NUM)*RIGHT_SIZE]=temp(383,256);
                                b_buf[(i/PACKET_NUM)*C+k][n+z*Y][m*4+3+j*(W1/NUM_PER_TRA)+(i%PACKET_NUM)*RIGHT_SIZE]=temp(511,384);
                            }
                        }
                    }
                }
            }
        }
    }
}   

template<int NC>
void sendA(ap_uint<PLIO_WIDTH> a_buf[X*Y][LEFT_SIZE*PACKET_NUM],axis_stream& txA,bool enable){
#pragma HLS inline off
    if(enable){
        data_t1 data_temp[2][4];
        #pragma HLS ARRAY_PARTITION variable=data_temp complete dim=0
        axis_pkt tmp;
        data_t data;
        data_t da;
        for (int k = 0; k < X*PACKET_NUM*Y*Z; k++) {    
            unsigned int ID=0;
            int tile=0;
            if(k<10){
                ID=packet_id0[k];
                tile=tile0[k];
            }
            else if(k<(X*PACKET_NUM*Y*Z-6)){
                int cnt=k-10;
                ID=cnt%PACKET_NUM;
                tile=(4-(cnt%PACKET_NUM)+cnt/PACKET_NUM)%(X*Y);
            }
            else{
                int pos2=k-X*PACKET_NUM*Y*Z+6;
                ID=packet_id2[pos2];
                tile=tile2[pos2]+(X*Y-PACKET_NUM);
            }
            ap_uint<32> header=generateHeader(PKTTYPE,ID);
            int position=ID*LEFT_SIZE;
    
            data=a_buf[tile][position];
            data_temp[0][0]=data(31,0);
            data_temp[0][1]=data(63,32);
            data_temp[0][2]=data(95,64);
            data_temp[0][3]=data(127,96);
            da(31,0)   = header;
            da(63,32)  = data_temp[0][0];
            da(95,64)  = data_temp[0][1];
            da(127,96) = data_temp[0][2];
            tmp.data  =  da;
            tmp.keep  = -1;
            tmp.last  = 0;
            txA.write(tmp);
    
            for (int i = 1; i < LEFT_SIZE; i++){ 
            #pragma HLS PIPELINE II = 1
                int posa=ID*LEFT_SIZE+i;
    
                data=a_buf[tile][posa];
                data_temp[i%2][0]=data(31,0);
                data_temp[i%2][1]=data(63,32);
                data_temp[i%2][2]=data(95,64);
                data_temp[i%2][3]=data(127,96);
                da(31,0)   = data_temp[(i+1)%2][3];
                da(63,32)  = data_temp[i%2][0];
                da(95,64)  = data_temp[i%2][1];
                da(127,96) = data_temp[i%2][2];
                tmp.data   = da;
                tmp.keep   = -1;
                tmp.last   = 0;
    
                txA.write(tmp);
            }
    
            da(31,0)=data_temp[1][3];
            da(63,32)  = 0;
            da(95,64)  = 0;
            da(127,96) = 0;
            tmp.data  =  da; 
            tmp.keep  = 0x000f;
            tmp.last  = 1;
             
            txA.write(tmp);
        }
    }
    
}

template<int NC>
void sendB(ap_uint<PLIO_WIDTH> b_buf[Y*Z][RIGHT_SIZE*PACKET_NUM], bool enable,
           axis_stream& txB0, axis_stream& txB1, axis_stream& txB2,
           axis_stream& txB3, axis_stream& txB4, axis_stream& txB5){
#pragma HLS inline off
    if(enable){
        axis_pkt tmp;
        data_t1 data_temp[2][4];
        #pragma HLS ARRAY_PARTITION variable=data_temp complete dim=0
        data_t data;
        data_t da;
    
    
        for (int k = 0; k < PACKET_NUM*Y*X*Z; k++) {
            unsigned int ID=0;
            int tile=0;
    
            if(k<10){
                ID=packet_id0[k];
                tile=tile0[k];
            }
            else if(k<PACKET_NUM*Y*X*Z-6){
                int cnt=k-10;
                ID=cnt%PACKET_NUM;
                int pos1=cnt%(X*Y*PACKET_NUM);
                int incr;
                if(pos1<(X*Y-PACKET_NUM)*PACKET_NUM){
                    tile=(4-(pos1%PACKET_NUM)+(pos1/PACKET_NUM))%Y+(cnt/(X*Y*PACKET_NUM))*Y;
                }
                else{
                    incr=(pos1-(X*Y-PACKET_NUM)*PACKET_NUM)/4;
                    tile=4-pos1%PACKET_NUM+(cnt/(X*Y*PACKET_NUM))*Y+incr+(Y-PACKET_NUM);
                }
            }
            else{
                int pos2=k-PACKET_NUM*Y*X*Z+6;
                ID=packet_id2[pos2];
                tile=tile2[pos2]+(Y*Z-PACKET_NUM);
            }
    
            ap_uint<32> header=generateHeader(PKTTYPE,ID);
            int position=ID*RIGHT_SIZE;
    
            data=b_buf[tile][position];
            data_temp[0][0]=data(31,0);
            data_temp[0][1]=data(63,32);
            data_temp[0][2]=data(95,64);
            data_temp[0][3]=data(127,96);
            da(31,0)   = header;
            da(63,32)  = data_temp[0][0];
            da(95,64)  = data_temp[0][1];
            da(127,96) = data_temp[0][2];
            
            tmp.data  =  da;
            tmp.keep  =  -1;
            tmp.last  =  0;
        
            txB0.write(tmp);
            txB1.write(tmp);
            txB2.write(tmp);
            txB3.write(tmp);
            txB4.write(tmp);
            txB5.write(tmp);
            for (int i = 1; i < RIGHT_SIZE; i++){
            #pragma HLS PIPELINE II = 1
                int posb=ID*RIGHT_SIZE+i;   
    
                data=b_buf[tile][posb];
                data_temp[i%2][0]=data(31,0);
                data_temp[i%2][1]=data(63,32);
                data_temp[i%2][2]=data(95,64);
                data_temp[i%2][3]=data(127,96);
                da(31,0)   = data_temp[(i+1)%2][3];
                da(63,32)  = data_temp[i%2][0];
                da(95,64)  = data_temp[i%2][1];
                da(127,96) = data_temp[i%2][2];
                
                tmp.data   = da;
                tmp.keep   = -1;
                tmp.last   = 0;
                txB0.write(tmp);
                txB1.write(tmp);
                txB2.write(tmp);
                txB3.write(tmp);
                txB4.write(tmp);
                txB5.write(tmp);
            }
    
            da(31,0)   = data_temp[1][3];
            da(63,32)  = 0;
            da(95,64)  = 0;
            da(127,96) = 0;
            
    
            tmp.data =  da;
            tmp.keep  = 0x000f;
            tmp.last  = 1;
        
            txB0.write(tmp);
            txB1.write(tmp);
            txB2.write(tmp);
            txB3.write(tmp);
            txB4.write(tmp);
            txB5.write(tmp);
            
        }
    }
}

unsigned int getPacketId(ap_uint<32> header){
#pragma HLS inline
    ap_uint<32> ID=0;
    ID(4,0)=header(4,0);
    return ID;
}

template<int NC>
void reshapeC(ap_uint<PLIO_WIDTH> c_buf[X*Z][PACKET_NUM][OUT_SIZE],axis_stream& rxC, bool enable){   
#pragma HLS inline off
    if (enable){
        
        axis_pkt tmp; 
        int cnt[4];
        #pragma HLS ARRAY_PARTITION variable=cnt complete dim=0
        data_t1 data_temp[2][4];
        #pragma HLS ARRAY_PARTITION variable=data_temp complete dim=0
        for(int i=0;i<PACKET_NUM;i++){
        #pragma HLS unroll
            cnt[i]=0;
        }
        for(int z = 0; z < Z; z++){
            for(int x = 0; x < X; x++){
                for(int j=0;j<PACKET_NUM;j++){
                    for (int i = 0; i < OUT_SIZE; i++){
                    #pragma HLS PIPELINE II = 1
                        c_buf[x+z*X][j][i]=0; 
                    }
                }
            }
        }
        for(int z = 0; z < Z; z++){
            for(int x = 0; x < X; x++){
                for (int n = 0; n < Y; n++){
                    for(int j=0;j<PACKET_NUM;j++){
                        ap_uint<32> header;
                        tmp=rxC.read();
                        
                        header=tmp.data(31,0);
                        data_temp[0][1]=tmp.data(63,32);
                        data_temp[0][2]=tmp.data(95,64);
                        data_temp[0][3]=tmp.data(127,96);
                        
                        unsigned int ID=getPacketId(header);
    
                        unsigned int tile_x=cnt[ID]/Y;
                        cnt[ID]=cnt[ID]+1;
    
    
    
                        for(int i=0;i<OUT_SIZE;i++){
                        #pragma HLS PIPELINE II = 1
                            tmp=rxC.read();
            
                            data_temp[(i+1)%2][0]=tmp.data(31,0);
                            data_temp[(i+1)%2][1]=tmp.data(63,32);
                            data_temp[(i+1)%2][2]=tmp.data(95,64);
                            data_temp[(i+1)%2][3]=tmp.data(127,96);
        
                            c_buf[tile_x][ID][i](31,0)  = data_temp[i%2][1] + c_buf[tile_x][ID][i](31,0)  ;
                            c_buf[tile_x][ID][i](63,32) = data_temp[i%2][2] + c_buf[tile_x][ID][i](63,32) ;
                            c_buf[tile_x][ID][i](95,64) = data_temp[i%2][3] + c_buf[tile_x][ID][i](95,64) ;
                            c_buf[tile_x][ID][i](127,96)= data_temp[(i+1)%2][0] + c_buf[tile_x][ID][i](127,96);
                            
                        }
                    }
                }
            } 
        }
    }
    
}

void storeC(ap_uint<AXI_WIDTH_256>* c_out,ap_uint<PLIO_WIDTH> c_buf[A*C/PACKET_NUM][X*Z][PACKET_NUM][OUT_SIZE], bool enable, int rd){
#pragma HLS inline off
    if(enable){
        for(int z=0;z<Z;z++){
            for(int j=0;j<PACKET_NUM;j++){
                for(int i=0;i<W2;i++){
                    for(int x=0;x<X;x++){
                        for (int k = 0; k < A*C/PACKET_NUM; k++){
                            for (int n = 0; n < H1/C_PER_TRA; n++){
                            #pragma HLS PIPELINE II = 1
                                ap_uint<AXI_WIDTH_256> temp;
                                temp(127,0)=c_buf[k][x+z*X][j][n*2+i*(H1/NUM_PER_TRA)];
                                temp(255,128)=c_buf[k][x+z*X][j][n*2+1+i*(H1/NUM_PER_TRA)];
                                c_out[rd*Z*W2*(H1/C_PER_TRA)*A*C*X+z*W2*(H1/C_PER_TRA)*A*C*X+x*(A*C/PACKET_NUM)*(H1/C_PER_TRA)+n+k*(H1/C_PER_TRA)+i*X*(A*C/PACKET_NUM)*(H1/C_PER_TRA)+j*W2*(H1/C_PER_TRA)*X*(A*C/PACKET_NUM)]=temp;
                            }
                        }
                    }
                }
            }
        }
    }
}

void dma(ap_uint<AXI_WIDTH_512>* ina, ap_uint<AXI_WIDTH_512>* inb, ap_uint<AXI_WIDTH_256>* out0, const int num_tilez,
            axis_stream& txA_0,  axis_stream& txA_1,  axis_stream& txA_2,  axis_stream& txA_3,
            axis_stream& txA_4,  axis_stream& txA_5,  axis_stream& txA_6,  axis_stream& txA_7,
            axis_stream& txA_8,  axis_stream& txA_9,  axis_stream& txA_10, axis_stream& txA_11,
            axis_stream& txA_12, axis_stream& txA_13, axis_stream& txA_14, axis_stream& txA_15,
            axis_stream& txA_16, axis_stream& txA_17, axis_stream& txA_18, axis_stream& txA_19,
            axis_stream& txA_20, axis_stream& txA_21, axis_stream& txA_22, axis_stream& txA_23,
            axis_stream& txB_0_0,  axis_stream& txB_0_1,  axis_stream& txB_0_2,
            axis_stream& txB_0_3,  axis_stream& txB_0_4,  axis_stream& txB_0_5,
            axis_stream& txB_1_0,  axis_stream& txB_1_1,  axis_stream& txB_1_2,
            axis_stream& txB_1_3,  axis_stream& txB_1_4,  axis_stream& txB_1_5,
            axis_stream& txB_2_0,  axis_stream& txB_2_1,  axis_stream& txB_2_2,
            axis_stream& txB_2_3,  axis_stream& txB_2_4,  axis_stream& txB_2_5,
            axis_stream& txB_3_0,  axis_stream& txB_3_1,  axis_stream& txB_3_2,
            axis_stream& txB_3_3,  axis_stream& txB_3_4,  axis_stream& txB_3_5,
            axis_stream& txB_4_0,  axis_stream& txB_4_1,  axis_stream& txB_4_2,
            axis_stream& txB_4_3,  axis_stream& txB_4_4,  axis_stream& txB_4_5,
            axis_stream& txB_5_0,  axis_stream& txB_5_1,  axis_stream& txB_5_2,
            axis_stream& txB_5_3,  axis_stream& txB_5_4,  axis_stream& txB_5_5,
            axis_stream& txB_6_0,  axis_stream& txB_6_1,  axis_stream& txB_6_2,
            axis_stream& txB_6_3,  axis_stream& txB_6_4,  axis_stream& txB_6_5,
            axis_stream& txB_7_0,  axis_stream& txB_7_1,  axis_stream& txB_7_2,
            axis_stream& txB_7_3,  axis_stream& txB_7_4,  axis_stream& txB_7_5,
            axis_stream& rxC_0, axis_stream& rxC_1, axis_stream& rxC_2, axis_stream& rxC_3,
            axis_stream& rxC_4, axis_stream& rxC_5, axis_stream& rxC_6, axis_stream& rxC_7,
            axis_stream& rxC_8, axis_stream& rxC_9, axis_stream& rxC_10, axis_stream& rxC_11)
{
    #pragma HLS interface m_axi offset=slave bundle=gmem0 port=ina max_read_burst_length=64 num_read_outstanding=64
    #pragma HLS interface s_axilite bundle=control port=ina
    #pragma HLS interface m_axi offset=slave bundle=gmem1 port=inb max_read_burst_length=64 num_read_outstanding=64
    #pragma HLS interface s_axilite bundle=control port=inb
    #pragma HLS interface m_axi offset=slave bundle=gmem2 port=out0 max_write_burst_length=64 num_write_outstanding=64
    #pragma HLS interface s_axilite bundle=control port=out0
    #pragma HLS interface s_axilite bundle=control port=num_tilez
    #pragma HLS interface axis port=txA_0
    #pragma HLS interface axis port=txA_1
    #pragma HLS interface axis port=txA_2
    #pragma HLS interface axis port=txA_3
    #pragma HLS interface axis port=txA_4
    #pragma HLS interface axis port=txA_5
    #pragma HLS interface axis port=txA_6
    #pragma HLS interface axis port=txA_7
    #pragma HLS interface axis port=txA_8
    #pragma HLS interface axis port=txA_9
    #pragma HLS interface axis port=txA_10
    #pragma HLS interface axis port=txA_11
    #pragma HLS interface axis port=txA_12
    #pragma HLS interface axis port=txA_13
    #pragma HLS interface axis port=txA_14
    #pragma HLS interface axis port=txA_15
    #pragma HLS interface axis port=txA_16
    #pragma HLS interface axis port=txA_17
    #pragma HLS interface axis port=txA_18
    #pragma HLS interface axis port=txA_19
    #pragma HLS interface axis port=txA_20
    #pragma HLS interface axis port=txA_21
    #pragma HLS interface axis port=txA_22
    #pragma HLS interface axis port=txA_23
    #pragma HLS interface axis port=txB_0_0
    #pragma HLS interface axis port=txB_0_1
    #pragma HLS interface axis port=txB_0_2
    #pragma HLS interface axis port=txB_0_3
    #pragma HLS interface axis port=txB_0_4
    #pragma HLS interface axis port=txB_0_5
    #pragma HLS interface axis port=txB_1_0
    #pragma HLS interface axis port=txB_1_1
    #pragma HLS interface axis port=txB_1_2
    #pragma HLS interface axis port=txB_1_3
    #pragma HLS interface axis port=txB_1_4
    #pragma HLS interface axis port=txB_1_5
    #pragma HLS interface axis port=txB_2_0
    #pragma HLS interface axis port=txB_2_1
    #pragma HLS interface axis port=txB_2_2
    #pragma HLS interface axis port=txB_2_3
    #pragma HLS interface axis port=txB_2_4
    #pragma HLS interface axis port=txB_2_5
    #pragma HLS interface axis port=txB_3_0
    #pragma HLS interface axis port=txB_3_1
    #pragma HLS interface axis port=txB_3_2
    #pragma HLS interface axis port=txB_3_3
    #pragma HLS interface axis port=txB_3_4
    #pragma HLS interface axis port=txB_3_5
    #pragma HLS interface axis port=txB_4_0
    #pragma HLS interface axis port=txB_4_1
    #pragma HLS interface axis port=txB_4_2
    #pragma HLS interface axis port=txB_4_3
    #pragma HLS interface axis port=txB_4_4
    #pragma HLS interface axis port=txB_4_5
    #pragma HLS interface axis port=txB_5_0
    #pragma HLS interface axis port=txB_5_1
    #pragma HLS interface axis port=txB_5_2
    #pragma HLS interface axis port=txB_5_3
    #pragma HLS interface axis port=txB_5_4
    #pragma HLS interface axis port=txB_5_5
    #pragma HLS interface axis port=txB_6_0
    #pragma HLS interface axis port=txB_6_1
    #pragma HLS interface axis port=txB_6_2
    #pragma HLS interface axis port=txB_6_3
    #pragma HLS interface axis port=txB_6_4
    #pragma HLS interface axis port=txB_6_5
    #pragma HLS interface axis port=txB_7_0
    #pragma HLS interface axis port=txB_7_1
    #pragma HLS interface axis port=txB_7_2
    #pragma HLS interface axis port=txB_7_3
    #pragma HLS interface axis port=txB_7_4
    #pragma HLS interface axis port=txB_7_5
    #pragma HLS interface axis port=rxC_0
    #pragma HLS interface axis port=rxC_1
    #pragma HLS interface axis port=rxC_2
    #pragma HLS interface axis port=rxC_3
    #pragma HLS interface axis port=rxC_4
    #pragma HLS interface axis port=rxC_5
    #pragma HLS interface axis port=rxC_6
    #pragma HLS interface axis port=rxC_7
    #pragma HLS interface axis port=rxC_8
    #pragma HLS interface axis port=rxC_9
    #pragma HLS interface axis port=rxC_10
    #pragma HLS interface axis port=rxC_11
    #pragma HLS interface s_axilite bundle=control port=return
    
    ///////////////////////////   Bank0  /////////////////////////////
    //Y*A*B*4KB

    ap_uint<PLIO_WIDTH> buff0_A[A*(B/PACKET_NUM)][X*Y][LEFT_SIZE*PACKET_NUM];
    #pragma HLS bind_storage variable=buff0_A type=RAM_1P impl=${L_buffer}
    #pragma HLS ARRAY_PARTITION variable=buff0_A cyclic factor=4 dim=3
    #pragma HLS ARRAY_PARTITION variable=buff0_A complete dim=1

    //Y*Z*B*C*4KB
    ap_uint<PLIO_WIDTH> buff0_B[(B/PACKET_NUM)*C][Y*Z][RIGHT_SIZE*PACKET_NUM];
    #pragma HLS bind_storage variable=buff0_B type=RAM_1P impl=${R_buffer}
    #pragma HLS ARRAY_PARTITION variable=buff0_B cyclic factor=4 dim=3
    #pragma HLS ARRAY_PARTITION variable=buff0_B complete dim=1

    ap_uint<PLIO_WIDTH> buff1_B[(B/PACKET_NUM)*C][Y*Z][RIGHT_SIZE*PACKET_NUM];
    #pragma HLS bind_storage variable=buff1_B type=RAM_1P impl=${R_buffer}
    #pragma HLS ARRAY_PARTITION variable=buff1_B cyclic factor=4 dim=3
    #pragma HLS ARRAY_PARTITION variable=buff1_B complete dim=1

    //A*C*4KB
    ap_uint<PLIO_WIDTH> buff0_C0[A*C/PACKET_NUM][X*Z][PACKET_NUM][OUT_SIZE];
    #pragma HLS bind_storage variable=buff0_C0 type=RAM_2P impl=${O_buffer}
    #pragma HLS ARRAY_PARTITION variable=buff0_C0 complete dim=1

    ap_uint<PLIO_WIDTH> buff1_C0[A*C/PACKET_NUM][X*Z][PACKET_NUM][OUT_SIZE];
    #pragma HLS bind_storage variable=buff1_C0 type=RAM_2P impl=${O_buffer}
    #pragma HLS ARRAY_PARTITION variable=buff1_C0 complete dim=1


    loadA(ina,buff0_A,1); 
    for(int i=0;i<num_tilez+2;i++){
        if(i%2==0){
            loadB(inb,buff0_B,i<num_tilez,i);
            sendA<0>(buff0_A[0],txA_0,((i>0)&&(i<num_tilez+1)));
            sendA<1>(buff0_A[1],txA_1,((i>0)&&(i<num_tilez+1)));
            sendA<2>(buff0_A[2],txA_2,((i>0)&&(i<num_tilez+1)));
            sendA<3>(buff0_A[3],txA_3,((i>0)&&(i<num_tilez+1)));
            sendA<4>(buff0_A[4],txA_4,((i>0)&&(i<num_tilez+1)));
            sendA<5>(buff0_A[5],txA_5,((i>0)&&(i<num_tilez+1)));
            sendA<6>(buff0_A[6],txA_6,((i>0)&&(i<num_tilez+1)));
            sendA<7>(buff0_A[7],txA_7,((i>0)&&(i<num_tilez+1)));
            sendA<8>(buff0_A[8],txA_8,((i>0)&&(i<num_tilez+1)));
            sendA<9>(buff0_A[9],txA_9,((i>0)&&(i<num_tilez+1)));
            sendA<10>(buff0_A[10],txA_10,((i>0)&&(i<num_tilez+1)));
            sendA<11>(buff0_A[11],txA_11,((i>0)&&(i<num_tilez+1)));
            sendA<12>(buff0_A[12],txA_12,((i>0)&&(i<num_tilez+1)));
            sendA<13>(buff0_A[13],txA_13,((i>0)&&(i<num_tilez+1)));
            sendA<14>(buff0_A[14],txA_14,((i>0)&&(i<num_tilez+1)));
            sendA<15>(buff0_A[15],txA_15,((i>0)&&(i<num_tilez+1)));
            sendA<16>(buff0_A[16],txA_16,((i>0)&&(i<num_tilez+1)));
            sendA<17>(buff0_A[17],txA_17,((i>0)&&(i<num_tilez+1)));
            sendA<18>(buff0_A[18],txA_18,((i>0)&&(i<num_tilez+1)));
            sendA<19>(buff0_A[19],txA_19,((i>0)&&(i<num_tilez+1)));
            sendA<20>(buff0_A[20],txA_20,((i>0)&&(i<num_tilez+1)));
            sendA<21>(buff0_A[21],txA_21,((i>0)&&(i<num_tilez+1)));
            sendA<22>(buff0_A[22],txA_22,((i>0)&&(i<num_tilez+1)));
            sendA<23>(buff0_A[23],txA_23,((i>0)&&(i<num_tilez+1)));
            sendB<0>(buff1_B[0],((i>0)&&(i<num_tilez+1)),
                txB_0_0,  txB_0_1,  txB_0_2,
                txB_0_3,  txB_0_4,  txB_0_5);
            sendB<1>(buff1_B[1],((i>0)&&(i<num_tilez+1)),
                txB_1_0,  txB_1_1,  txB_1_2,
                txB_1_3,  txB_1_4,  txB_1_5);
            sendB<2>(buff1_B[2],((i>0)&&(i<num_tilez+1)),
                txB_2_0,  txB_2_1,  txB_2_2,
                txB_2_3,  txB_2_4,  txB_2_5);
            sendB<3>(buff1_B[3],((i>0)&&(i<num_tilez+1)),
                txB_3_0,  txB_3_1,  txB_3_2,
                txB_3_3,  txB_3_4,  txB_3_5);
            sendB<4>(buff1_B[4],((i>0)&&(i<num_tilez+1)),
                txB_4_0,  txB_4_1,  txB_4_2,
                txB_4_3,  txB_4_4,  txB_4_5);
            sendB<5>(buff1_B[5],((i>0)&&(i<num_tilez+1)),
                txB_5_0,  txB_5_1,  txB_5_2,
                txB_5_3,  txB_5_4,  txB_5_5);
            sendB<6>(buff1_B[6],((i>0)&&(i<num_tilez+1)),
                txB_6_0,  txB_6_1,  txB_6_2,
                txB_6_3,  txB_6_4,  txB_6_5);
            sendB<7>(buff1_B[7],((i>0)&&(i<num_tilez+1)),
                txB_7_0,  txB_7_1,  txB_7_2,
                txB_7_3,  txB_7_4,  txB_7_5);
            reshapeC<0>(buff0_C0[0],rxC_0,((i>0)&&(i<num_tilez+1)));
            reshapeC<1>(buff0_C0[1],rxC_1,((i>0)&&(i<num_tilez+1)));
            reshapeC<2>(buff0_C0[2],rxC_2,((i>0)&&(i<num_tilez+1)));
            reshapeC<3>(buff0_C0[3],rxC_3,((i>0)&&(i<num_tilez+1)));
            reshapeC<4>(buff0_C0[4],rxC_4,((i>0)&&(i<num_tilez+1)));
            reshapeC<5>(buff0_C0[5],rxC_5,((i>0)&&(i<num_tilez+1)));
            reshapeC<6>(buff0_C0[6],rxC_6,((i>0)&&(i<num_tilez+1)));
            reshapeC<7>(buff0_C0[7],rxC_7,((i>0)&&(i<num_tilez+1)));
            reshapeC<8>(buff0_C0[8],rxC_8,((i>0)&&(i<num_tilez+1)));
            reshapeC<9>(buff0_C0[9],rxC_9,((i>0)&&(i<num_tilez+1)));
            reshapeC<10>(buff0_C0[10],rxC_10,((i>0)&&(i<num_tilez+1)));
            reshapeC<11>(buff0_C0[11],rxC_11,((i>0)&&(i<num_tilez+1)));
            storeC(out0,buff1_C0,i>1,(i-2));
        }
        else{
            loadB(inb,buff1_B,i<num_tilez,i);
            sendA<0>(buff0_A[0],txA_0,((i>0)&&(i<num_tilez+1)));
            sendA<1>(buff0_A[1],txA_1,((i>0)&&(i<num_tilez+1)));
            sendA<2>(buff0_A[2],txA_2,((i>0)&&(i<num_tilez+1)));
            sendA<3>(buff0_A[3],txA_3,((i>0)&&(i<num_tilez+1)));
            sendA<4>(buff0_A[4],txA_4,((i>0)&&(i<num_tilez+1)));
            sendA<5>(buff0_A[5],txA_5,((i>0)&&(i<num_tilez+1)));
            sendA<6>(buff0_A[6],txA_6,((i>0)&&(i<num_tilez+1)));
            sendA<7>(buff0_A[7],txA_7,((i>0)&&(i<num_tilez+1)));
            sendA<8>(buff0_A[8],txA_8,((i>0)&&(i<num_tilez+1)));
            sendA<9>(buff0_A[9],txA_9,((i>0)&&(i<num_tilez+1)));
            sendA<10>(buff0_A[10],txA_10,((i>0)&&(i<num_tilez+1)));
            sendA<11>(buff0_A[11],txA_11,((i>0)&&(i<num_tilez+1)));
            sendA<12>(buff0_A[12],txA_12,((i>0)&&(i<num_tilez+1)));
            sendA<13>(buff0_A[13],txA_13,((i>0)&&(i<num_tilez+1)));
            sendA<14>(buff0_A[14],txA_14,((i>0)&&(i<num_tilez+1)));
            sendA<15>(buff0_A[15],txA_15,((i>0)&&(i<num_tilez+1)));
            sendA<16>(buff0_A[16],txA_16,((i>0)&&(i<num_tilez+1)));
            sendA<17>(buff0_A[17],txA_17,((i>0)&&(i<num_tilez+1)));
            sendA<18>(buff0_A[18],txA_18,((i>0)&&(i<num_tilez+1)));
            sendA<19>(buff0_A[19],txA_19,((i>0)&&(i<num_tilez+1)));
            sendA<20>(buff0_A[20],txA_20,((i>0)&&(i<num_tilez+1)));
            sendA<21>(buff0_A[21],txA_21,((i>0)&&(i<num_tilez+1)));
            sendA<22>(buff0_A[22],txA_22,((i>0)&&(i<num_tilez+1)));
            sendA<23>(buff0_A[23],txA_23,((i>0)&&(i<num_tilez+1)));
            sendB<0>(buff0_B[0],((i>0)&&(i<num_tilez+1)),
                txB_0_0,  txB_0_1,  txB_0_2,
                txB_0_3,  txB_0_4,  txB_0_5);
            sendB<1>(buff0_B[1],((i>0)&&(i<num_tilez+1)),
                txB_1_0,  txB_1_1,  txB_1_2,
                txB_1_3,  txB_1_4,  txB_1_5);
            sendB<2>(buff0_B[2],((i>0)&&(i<num_tilez+1)),
                txB_2_0,  txB_2_1,  txB_2_2,
                txB_2_3,  txB_2_4,  txB_2_5);
            sendB<3>(buff0_B[3],((i>0)&&(i<num_tilez+1)),
                txB_3_0,  txB_3_1,  txB_3_2,
                txB_3_3,  txB_3_4,  txB_3_5);
            sendB<4>(buff0_B[4],((i>0)&&(i<num_tilez+1)),
                txB_4_0,  txB_4_1,  txB_4_2,
                txB_4_3,  txB_4_4,  txB_4_5);
            sendB<5>(buff0_B[5],((i>0)&&(i<num_tilez+1)),
                txB_5_0,  txB_5_1,  txB_5_2,
                txB_5_3,  txB_5_4,  txB_5_5);
            sendB<6>(buff0_B[6],((i>0)&&(i<num_tilez+1)),
                txB_6_0,  txB_6_1,  txB_6_2,
                txB_6_3,  txB_6_4,  txB_6_5);
            sendB<7>(buff0_B[7],((i>0)&&(i<num_tilez+1)),
                txB_7_0,  txB_7_1,  txB_7_2,
                txB_7_3,  txB_7_4,  txB_7_5);
            reshapeC<0>(buff1_C0[0],rxC_0,((i>0)&&(i<num_tilez+1)));
            reshapeC<1>(buff1_C0[1],rxC_1,((i>0)&&(i<num_tilez+1)));
            reshapeC<2>(buff1_C0[2],rxC_2,((i>0)&&(i<num_tilez+1)));
            reshapeC<3>(buff1_C0[3],rxC_3,((i>0)&&(i<num_tilez+1)));
            reshapeC<4>(buff1_C0[4],rxC_4,((i>0)&&(i<num_tilez+1)));
            reshapeC<5>(buff1_C0[5],rxC_5,((i>0)&&(i<num_tilez+1)));
            reshapeC<6>(buff1_C0[6],rxC_6,((i>0)&&(i<num_tilez+1)));
            reshapeC<7>(buff1_C0[7],rxC_7,((i>0)&&(i<num_tilez+1)));
            reshapeC<8>(buff1_C0[8],rxC_8,((i>0)&&(i<num_tilez+1)));
            reshapeC<9>(buff1_C0[9],rxC_9,((i>0)&&(i<num_tilez+1)));
            reshapeC<10>(buff1_C0[10],rxC_10,((i>0)&&(i<num_tilez+1)));
            reshapeC<11>(buff1_C0[11],rxC_11,((i>0)&&(i<num_tilez+1)));
            storeC(out0,buff0_C0,i>1,(i-2));
        }
    }

}

">> ./${file_name}/kernel/dma.cpp;

    echo \
"
#ifndef _PACKET_SENDER_H_
#define _PACKET_SENDER_H_
#include <cstring>
#include <ap_int.h>
#include <hls_stream.h>
#include <ap_axi_sdata.h>

const int AXI_WIDTH_512=512;
const int AXI_WIDTH_256=256;
const int PLIO_WIDTH=128;
const int DATA_TYPE=32;
const int PKTTYPE=0; 
const int PACKET_NUM=4; 
const int H1=32;
const int W1=32;
const int W2=32;
const int A=12;
const int B=8;
const int C=4;
const int X=${x};
const int Y=${y};
const int Z=${z};
const int A_PER_TRA=AXI_WIDTH_512/DATA_TYPE;
const int C_PER_TRA=AXI_WIDTH_256/DATA_TYPE;
const int NUM_PER_TRA=PLIO_WIDTH/DATA_TYPE;
const int LEFT_SIZE=H1*W1/NUM_PER_TRA;
const int RIGHT_SIZE=W1*W2/NUM_PER_TRA;
const int OUT_SIZE=H1*W2/NUM_PER_TRA;   //256

const int PLIO_WIDTH1=32;
const int PAC_LENGTH=H1*W2*DATA_TYPE/PLIO_WIDTH1;  //1024

typedef ap_uint<PLIO_WIDTH> data_t;
typedef ap_uint<PLIO_WIDTH1> data_t1;
typedef ap_axiu<PLIO_WIDTH, 0, 0, 0> axis_pkt;
typedef hls::stream<axis_pkt> axis_stream;
    

data_t1 generateHeader(unsigned int pktType, unsigned int ID);

void dma(ap_uint<AXI_WIDTH_512>* ina, ap_uint<AXI_WIDTH_512>* inb, ap_uint<AXI_WIDTH_256>* out0, const int num_tilez,
            axis_stream& txA_0,  axis_stream& txA_1,  axis_stream& txA_2,  axis_stream& txA_3,
            axis_stream& txA_4,  axis_stream& txA_5,  axis_stream& txA_6,  axis_stream& txA_7,
            axis_stream& txA_8,  axis_stream& txA_9,  axis_stream& txA_10, axis_stream& txA_11,
            axis_stream& txA_12, axis_stream& txA_13, axis_stream& txA_14, axis_stream& txA_15,
            axis_stream& txA_16, axis_stream& txA_17, axis_stream& txA_18, axis_stream& txA_19,
            axis_stream& txA_20, axis_stream& txA_21, axis_stream& txA_22, axis_stream& txA_23,
            axis_stream& txB_0_0,  axis_stream& txB_0_1,  axis_stream& txB_0_2,
            axis_stream& txB_0_3,  axis_stream& txB_0_4,  axis_stream& txB_0_5,
            axis_stream& txB_1_0,  axis_stream& txB_1_1,  axis_stream& txB_1_2,
            axis_stream& txB_1_3,  axis_stream& txB_1_4,  axis_stream& txB_1_5,
            axis_stream& txB_2_0,  axis_stream& txB_2_1,  axis_stream& txB_2_2,
            axis_stream& txB_2_3,  axis_stream& txB_2_4,  axis_stream& txB_2_5,
            axis_stream& txB_3_0,  axis_stream& txB_3_1,  axis_stream& txB_3_2,
            axis_stream& txB_3_3,  axis_stream& txB_3_4,  axis_stream& txB_3_5,
            axis_stream& txB_4_0,  axis_stream& txB_4_1,  axis_stream& txB_4_2,
            axis_stream& txB_4_3,  axis_stream& txB_4_4,  axis_stream& txB_4_5,
            axis_stream& txB_5_0,  axis_stream& txB_5_1,  axis_stream& txB_5_2,
            axis_stream& txB_5_3,  axis_stream& txB_5_4,  axis_stream& txB_5_5,
            axis_stream& txB_6_0,  axis_stream& txB_6_1,  axis_stream& txB_6_2,
            axis_stream& txB_6_3,  axis_stream& txB_6_4,  axis_stream& txB_6_5,
            axis_stream& txB_7_0,  axis_stream& txB_7_1,  axis_stream& txB_7_2,
            axis_stream& txB_7_3,  axis_stream& txB_7_4,  axis_stream& txB_7_5,
            axis_stream& rxC_0, axis_stream& rxC_1, axis_stream& rxC_2, axis_stream& rxC_3,
            axis_stream& rxC_4, axis_stream& rxC_5, axis_stream& rxC_6, axis_stream& rxC_7,
            axis_stream& rxC_8, axis_stream& rxC_9, axis_stream& rxC_10, axis_stream& rxC_11);


void loadA(ap_uint<AXI_WIDTH_512>* a_in, ap_uint<PLIO_WIDTH> a_buf[A*(B/PACKET_NUM)][X*Y][LEFT_SIZE*PACKET_NUM],bool enable);

void loadB(ap_uint<AXI_WIDTH_512>* b_in, ap_uint<PLIO_WIDTH> b_buf[(B/PACKET_NUM)*C][Y*Z][RIGHT_SIZE*PACKET_NUM],bool enable, int rd);

template<int NC>
void sendA(ap_uint<PLIO_WIDTH> a_buf[X*Y][LEFT_SIZE*PACKET_NUM],axis_stream& txA,bool enable);

template<int NC>
void sendB(ap_uint<PLIO_WIDTH> b_buf[Y*Z][RIGHT_SIZE*PACKET_NUM], bool enable,
           axis_stream& txB0, axis_stream& txB1, axis_stream& txB2,
           axis_stream& txB3, axis_stream& txB4, axis_stream& txB5);

template<int NC>
void reshapeC(ap_uint<PLIO_WIDTH> c_buf[X*Z][PACKET_NUM][OUT_SIZE],axis_stream& rxC, bool enable);

void storeC(ap_uint<AXI_WIDTH_256>* c_out,ap_uint<PLIO_WIDTH> c_buf[A*C/PACKET_NUM][X*Z][PACKET_NUM][OUT_SIZE], bool enable, int rd);


unsigned int getPacketId(ap_uint<32> header);

#endif

">> ./${file_name}/kernel/packet_sender.hpp;

elif [ ${data_type} == "fp32" ]
then
echo \
"
#include <iostream>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <fstream>
#include <time.h>
#include <omp.h>

// This is used for the PL Kernels
#include "'"xrt.h"'"
#include "'"experimental/xrt_kernel.h"'"

static std::vector<char> load_xclbin(xrtDeviceHandle device, const std::string& fnm) {
    if (fnm.empty()) throw std::runtime_error("'"No xclbin specified"'");

    // load bit stream
    std::ifstream stream(fnm);
    stream.seekg(0, stream.end);
    size_t size = stream.tellg();
    stream.seekg(0, stream.beg);

    std::vector<char> header(size);
    stream.read(header.data(), size);

    auto top = reinterpret_cast<const axlf*>(header.data());
    if (xrtDeviceLoadXclbin(device, top)) throw std::runtime_error("'"Xclbin loading failed"'");

    return header;
}

#define PACKET_NUM 4 
#define H1 32
#define W1 32
#define W2 32
#define A 12
#define B 8
#define C 4
#define X ${x}
#define Y ${y}
const int Z=${T_Z};
const int DATA_SIZE1=H1*W1;
const int DATA_SIZE2=W1*W2;
const int OUT_SIZE=H1*W2;

void mm_sw( float A1[X][Y][A][B][DATA_SIZE1], float B1[Z][Y][B][C][DATA_SIZE2], float C1[Z][X][A][C][OUT_SIZE]){

#pragma omp parallel
    {
        int tid = omp_get_thread_num();
        if( tid == 0 ){
            int nthreads = omp_get_num_threads();
            std::cout << \"Running OpenMP with \" << nthreads << \" threads...\n\";
        }
    }

    
    float sum = 0;
#pragma omp parallel for private(sum)
    for(int z=0;z<Z;z++){
        for (int c=0; c<C; c++){
            for (int w2=0; w2<W2; w2++){
                for (int x=0; x<X; x++){
                    for (int a=0; a<A; a++){
                        for (int h1=0; h1<H1; h1++){
                            sum=0;
                            for (int y=0; y<Y; y++){
                                for (int b=0; b < B; b++) {
                                    for (int w1=0; w1 <W1 ; w1++) {
                                        sum=sum+A1[x][y][a][b][w1+h1*W1]*B1[z][y][b][c][w1*W2+w2];
                                    }
                                }
                            }
                            C1[z][x][a][c][w2+h1*W2]=sum;
                        }
                    }
                }
            }
        }
    }

}

int main(int argc, char** argv) {
    //////////////////////////////////////////
    // Open xclbin
    //////////////////////////////////////////
    if(argc != 2) {
    std::cout << "'"Usage: "'" << argv[0] <<"'" <xclbin>"'" << std::endl;
    return EXIT_FAILURE;
    }
    char* xclbinFilename = argv[1];
    //////////////////////////////////////////
    // Open xclbin
    //////////////////////////////////////////
    auto dhdl = xrtDeviceOpen(1); // Open Device the local device
    if (dhdl == nullptr) throw std::runtime_error("'"No valid device handle found. Make sure using right xclOpen index."'");
    auto xclbin = load_xclbin(dhdl, xclbinFilename);
    auto top = reinterpret_cast<const axlf*>(xclbin.data());

    //int iter;
    //std::cout << "'"Please input iteration number:"'"<< std::endl;
    //std::cin >> iter;

    const int sizeIn1 = DATA_SIZE1*A*B*X*Y;
    const int sizeIn2 = DATA_SIZE2*B*C*Y*Z;
    const int sizeOut = OUT_SIZE*A*C*X*Z;

    float (*DataInput0)[Y][A][B][DATA_SIZE1] = new float[X][Y][A][B][DATA_SIZE1];
    float (*DataInput1)[Y][B][C][DATA_SIZE2] = new float[Z][Y][B][C][DATA_SIZE2];
    float (*golden)[X][A][C][OUT_SIZE] = new float[Z][X][A][C][OUT_SIZE];

    srand (time(0));
    for (int m = 0; m < X; m++) {
        for (int n = 0; n < Y; n++) {
            for (int k = 0; k < A; k++) {
                for (int j = 0; j < B; j++) {
                    for (int i = 0; i < DATA_SIZE1; i++) {
                        DataInput0[m][n][k][j][i] = (rand()%5)*(float)1.0;
                    }
                }
            }
        }
    }

    srand (time(0));
    for (int m = 0; m < Z; m++) {
        for (int n = 0; n < Y; n++) {
            for (int k = 0; k < B; k++) {
                for (int j = 0; j < C; j++) {
                    for (int i = 0; i < DATA_SIZE2; i++) {
                        DataInput1[m][n][k][j][i] = (rand()%5)*(float)1.0;
                    }
                }
            }
        }
    }
    
    //Allocate input mem
    xrtBufferHandle in_bohdl0 = xrtBOAlloc(dhdl, sizeIn1 * sizeof(float), 0, 0);
    auto in_bomapped0 = (float*)(xrtBOMap(in_bohdl0));


    xrtBufferHandle in_bohdl1 = xrtBOAlloc(dhdl, sizeIn2 * sizeof(float), 0, 0);
    auto in_bomapped1 = (float*)(xrtBOMap(in_bohdl1));

    for(int m=0;m<Y;m++){
        for(int k=0;k<B;k++){
            for(int p=0;p<W1;p++){
                for(int n=0;n<X;n++){
                    for(int j=0;j<A;j++){
                        for(int i=0;i<H1;i++){
                            in_bomapped0[i+j*H1+n*A*H1+p*X*A*H1+k*X*A*DATA_SIZE1+m*B*X*A*DATA_SIZE1]=DataInput0[n][m][j][k][i*W1+p];
                        }
                    }
                }
            }
        }
    }

    for(int z=0;z<Z;z++){
        for(int k=0;k<C;k++){
            for(int j=0;j<W2;j++){
                for(int n=0;n<Y;n++){
                    for(int i=0;i<B;i++){
                        for (int m=0;m<W1;m++){
                            in_bomapped1[m+i*W1+n*B*W1+j*Y*B*W1+k*DATA_SIZE2*B*Y+z*C*DATA_SIZE2*B*Y]=DataInput1[z][n][i][k][m*W2+j];
                        }
                    }
                }
            }
        }
    }
    

    // sync input memory
    xrtBOSync(in_bohdl0, XCL_BO_SYNC_BO_TO_DEVICE , sizeIn1* sizeof(float),0);
    xrtBOSync(in_bohdl1, XCL_BO_SYNC_BO_TO_DEVICE , sizeIn2* sizeof(float),0);
    
    //Allocate output buffer
    xrtBufferHandle out_bohdl; 

    out_bohdl = xrtBOAlloc(dhdl, sizeOut* sizeof(float), 0, 0);
    auto out_bomapped = (float*)(xrtBOMap(out_bohdl));
    


    //for (int i=0;i<iter;i++){
        //Open PL kernels handles
        std::cout << "'"Kernel run\n"'";
        xrtKernelHandle dma_khdl = xrtPLKernelOpen(dhdl, top->m_header.uuid, "'"dma"'");
        xrtRunHandle dma_rhdl;
        //profile aie mm 
        double kernel_time_in_sec = 0;
        std::chrono::duration<double> kernel_time(0);
        auto kernel_start = std::chrono::high_resolution_clock::now();
        const int iter=4000;
        for (int i=0;i<iter;i++){
        // start input kernels run handles
        dma_rhdl = xrtKernelRun(dma_khdl, in_bohdl0, in_bohdl1,out_bohdl,Z/${z},
                            nullptr, nullptr, nullptr, nullptr,
                            nullptr, nullptr, nullptr, nullptr,
                            nullptr, nullptr, nullptr, nullptr,
                            nullptr, nullptr, nullptr, nullptr,
                            nullptr, nullptr, nullptr, nullptr,
                            nullptr, nullptr, nullptr, nullptr,
                            nullptr, nullptr, nullptr, 
                            nullptr, nullptr, nullptr,
                            nullptr, nullptr, nullptr, 
                            nullptr, nullptr, nullptr,
                            nullptr, nullptr, nullptr, 
                            nullptr, nullptr, nullptr,
                            nullptr, nullptr, nullptr, 
                            nullptr, nullptr, nullptr,
                            nullptr, nullptr, nullptr, 
                            nullptr, nullptr, nullptr,
                            nullptr, nullptr, nullptr, 
                            nullptr, nullptr, nullptr,
                            nullptr, nullptr, nullptr, 
                            nullptr, nullptr, nullptr,
                            nullptr, nullptr, nullptr, 
                            nullptr, nullptr, nullptr,
                            nullptr, nullptr, nullptr, nullptr,
                            nullptr, nullptr, nullptr, nullptr,
                            nullptr, nullptr, nullptr, nullptr);



    
        //////////////////////////////////////////
        // wait for mm2s done
        //////////////////////////////////////////
        //Wait for kernel finish
        auto state = xrtRunWait(dma_rhdl);
        }
 
        auto kernel_end = std::chrono::high_resolution_clock::now();
        kernel_time = std::chrono::duration<double>(kernel_end - kernel_start);
        kernel_time_in_sec = kernel_time.count();
        double TOPS = H1 * 1.024 * 3.84 * X * Y * Z * 2 *iter* 1e-4 / kernel_time_in_sec;
        std::cout << std::endl;
        std::cout << std::endl;
        std::cout << "'"Total execution time is: "'"<< kernel_time_in_sec <<"'"s, TOPS = "'" << TOPS << "'" GOPS/s"'" << std::endl;
        std::cout << std::endl;
        std::cout << std::endl;
        // sync output memory

        xrtBOSync(out_bohdl, XCL_BO_SYNC_BO_FROM_DEVICE , sizeOut* sizeof(float),/*OFFSET=*/ 0);
        
    
        xrtRunClose(dma_rhdl);
        xrtKernelClose(dma_khdl);
    //}

    
    ////////////////////////////////////////////
    //// Comparing the execution data to the golden data
    ////////////////////////////////////////////
    mm_sw(DataInput0, DataInput1, golden);

    int errorCount = 0;
    {   
        for(int z=0;z<Z;z++){
            for (int c=0; c<C; c++){
                for (int w2=0; w2<W2; w2++){
                    for (int x=0; x<X; x++){
                        for (int a=0; a<A; a++){
                            for (int h1=0; h1<H1; h1++){
                                if(abs((out_bomapped[h1+a*H1+x*H1*A+w2*X*A*H1+c*OUT_SIZE*A*X+z*C*OUT_SIZE*A*X])-golden[z][x][a][c][h1*W2+w2])>=1e-3){
                                    printf("'"Error found out_bomapped[%d]!=golden[%d][%d][%d][%d][%d], %f!=%f \n"'", h1+a*H1+x*H1*A+w2*X*A*H1+c*OUT_SIZE*A*X+z*C*OUT_SIZE*A*X,z,x,a,c,h1*W2+w2,out_bomapped[h1+a*H1+x*H1*A+w2*X*A*H1+c*OUT_SIZE*A*X+z*C*OUT_SIZE*A*X], golden[z][x][a][c][h1*W2+w2]);
                                    errorCount++;
                                }
                                //else{
                                //    printf("'"Correct found out_bomapped[%d]=golden[%d][%d][%d][%d][%d], %f=%f \n"'", h1+a*H1+x*H1*A+w2*X*A*H1+c*OUT_SIZE*A*X+z*C*OUT_SIZE*A*X,z,x,a,c,h1*W2+w2,out_bomapped[h1+a*H1+x*H1*A+w2*X*A*H1+c*OUT_SIZE*A*X+z*C*OUT_SIZE*A*X], golden[z][x][a][c][h1*W2+w2]);
                                //}
                            }
                        }
                    }
                }
            }
        }
        if (errorCount)
            printf("'"Test failed with %d errors\n"'", errorCount);
        else
            printf("'"TEST PASSED\n"'");
    }

    delete[] DataInput0;
    delete[] DataInput1;
    delete[] golden;

    //////////////////////////////////////////
    // clean up XRT
    //////////////////////////////////////////

    std::cout << "'"Releasing remaining XRT objects...\n"'";
    
    xrtBOFree(out_bohdl);
    xrtBOFree(in_bohdl0);
    xrtBOFree(in_bohdl1);
    xrtDeviceClose(dhdl);

    return 0;
}

">> ./${file_name}/host/host.cpp;

echo \
"#include <stdint.h>
#include "'"packet_sender.hpp"'"

static const unsigned int tile0[10]={0, 1, 0, 2, 1, 0, 3, 2, 1, 0};
static const unsigned int tile2[6]={3, 2, 1, 3, 2, 3};
static const unsigned int packet_id0[10]={0, 0, 1, 0, 1, 2, 0, 1, 2, 3};
static const unsigned int packet_id2[6]={1, 2, 3, 2, 3, 3};



ap_uint<32> generateHeader(unsigned int pktType, unsigned int ID){
#pragma HLS inline
    ap_uint<32> header=0;
    header(4,0)=ID;
    header(11,5)=0;
    header(14,12)=pktType;
    header[15]=0;
    header(20,16)=-1;//source row
    header(27,21)=-1;//source column
    header(30,28)=0;
    header[31]=header(30,0).xor_reduce()?(ap_uint<1>)0:(ap_uint<1>)1;
    return header;
}


void loadA(ap_uint<AXI_WIDTH_512>* a_in, ap_uint<PLIO_WIDTH> a_buf[A*(B/PACKET_NUM)][X*Y][LEFT_SIZE*PACKET_NUM],bool enable){
#pragma HLS inline off
    if(enable){
        for(int m=0;m<Y;m++){
            for(int k=0;k<W1*B;k++){
                for(int n=0;n<X;n++){
                    for(int j=0;j<A;j++){
                        for(int i=0;i<(H1/A_PER_TRA);i++){
                            #pragma HLS PIPELINE II = 1
                            int pos=i+j*(H1/A_PER_TRA)+n*A*(H1/A_PER_TRA)+k*A*X*(H1/A_PER_TRA)+m*W1*B*X*A*(H1/A_PER_TRA);
                            ap_uint<AXI_WIDTH_512> temp=a_in[pos];
                            a_buf[j+A*(k/(W1*PACKET_NUM))][n*Y+m][i*4+(k%(W1*PACKET_NUM))*(H1/NUM_PER_TRA)]=temp(127,0);  // 4=512/128
                            a_buf[j+A*(k/(W1*PACKET_NUM))][n*Y+m][i*4+1+(k%(W1*PACKET_NUM))*(H1/NUM_PER_TRA)]=temp(255,128);
                            a_buf[j+A*(k/(W1*PACKET_NUM))][n*Y+m][i*4+2+(k%(W1*PACKET_NUM))*(H1/NUM_PER_TRA)]=temp(383,256);
                            a_buf[j+A*(k/(W1*PACKET_NUM))][n*Y+m][i*4+3+(k%(W1*PACKET_NUM))*(H1/NUM_PER_TRA)]=temp(511,384);
                        }
                    }
                }
            }
        }
    }
    
}

void loadB(ap_uint<AXI_WIDTH_512>* b_in, ap_uint<PLIO_WIDTH> b_buf[(B/PACKET_NUM)*C][Y*Z][RIGHT_SIZE*PACKET_NUM],bool enable, int rd){
#pragma HLS inline off
    if(enable){
        for(int z=0;z<Z;z++){
            for(int k=0;k<C;k++){
                for(int j=0;j<W2;j++){
                    for(int n=0;n<Y;n++){
                        for(int i=0;i<B;i++){
                            for (int m=0;m<(W1/A_PER_TRA);m++){
                                #pragma HLS PIPELINE II = 1
                                ap_uint<AXI_WIDTH_512> temp;
                                int pos=m+i*(W1/A_PER_TRA)+n*(W1/A_PER_TRA)*B+j*Y*(W1/A_PER_TRA)*B+k*Y*W2*(W1/A_PER_TRA)*B+z*W2*(W1/A_PER_TRA)*B*C*Y+rd*Z*W2*(W1/A_PER_TRA)*B*C*Y;
                                temp=b_in[pos];
                                b_buf[(i/PACKET_NUM)*C+k][n+z*Y][m*4+j*(W1/NUM_PER_TRA)+(i%PACKET_NUM)*RIGHT_SIZE]=temp(127,0);
                                b_buf[(i/PACKET_NUM)*C+k][n+z*Y][m*4+1+j*(W1/NUM_PER_TRA)+(i%PACKET_NUM)*RIGHT_SIZE]=temp(255,128);
                                b_buf[(i/PACKET_NUM)*C+k][n+z*Y][m*4+2+j*(W1/NUM_PER_TRA)+(i%PACKET_NUM)*RIGHT_SIZE]=temp(383,256);
                                b_buf[(i/PACKET_NUM)*C+k][n+z*Y][m*4+3+j*(W1/NUM_PER_TRA)+(i%PACKET_NUM)*RIGHT_SIZE]=temp(511,384);
                            }
                        }
                    }
                }
            }
        }
    }
}   

template<int NC>
void sendA(ap_uint<PLIO_WIDTH> a_buf[X*Y][LEFT_SIZE*PACKET_NUM],axis_stream& txA,bool enable){
#pragma HLS inline off
    if(enable){
        data_t1 data_temp[2][4];
        #pragma HLS ARRAY_PARTITION variable=data_temp complete dim=0
        axis_pkt tmp;
        data_t data;
        data_t da;
        for (int k = 0; k < X*PACKET_NUM*Y*Z; k++) {    
            unsigned int ID=0;
            int tile=0;
            if(k<10){
                ID=packet_id0[k];
                tile=tile0[k];
            }
            else if(k<(X*PACKET_NUM*Y*Z-6)){
                int cnt=k-10;
                ID=cnt%PACKET_NUM;
                tile=(4-(cnt%PACKET_NUM)+cnt/PACKET_NUM)%(X*Y);
            }
            else{
                int pos2=k-X*PACKET_NUM*Y*Z+6;
                ID=packet_id2[pos2];
                tile=tile2[pos2]+(X*Y-PACKET_NUM);
            }
            ap_uint<32> header=generateHeader(PKTTYPE,ID);
            int position=ID*LEFT_SIZE;
    
            data=a_buf[tile][position];
            data_temp[0][0]=data(31,0);
            data_temp[0][1]=data(63,32);
            data_temp[0][2]=data(95,64);
            data_temp[0][3]=data(127,96);
            da(31,0)   = header;
            da(63,32)  = data_temp[0][0];
            da(95,64)  = data_temp[0][1];
            da(127,96) = data_temp[0][2];
            tmp.data  =  da;
            tmp.keep  = -1;
            tmp.last  = 0;
            txA.write(tmp);
    
            for (int i = 1; i < LEFT_SIZE; i++){ 
            #pragma HLS PIPELINE II = 1
                int posa=ID*LEFT_SIZE+i;
    
                data=a_buf[tile][posa];
                data_temp[i%2][0]=data(31,0);
                data_temp[i%2][1]=data(63,32);
                data_temp[i%2][2]=data(95,64);
                data_temp[i%2][3]=data(127,96);
                da(31,0)   = data_temp[(i+1)%2][3];
                da(63,32)  = data_temp[i%2][0];
                da(95,64)  = data_temp[i%2][1];
                da(127,96) = data_temp[i%2][2];
                tmp.data   = da;
                tmp.keep   = -1;
                tmp.last   = 0;
    
                txA.write(tmp);
            }
    
            da(31,0)=data_temp[1][3];
            da(63,32)  = 0;
            da(95,64)  = 0;
            da(127,96) = 0;
            tmp.data  =  da; 
            tmp.keep  = 0x000f;
            tmp.last  = 1;
             
            txA.write(tmp);
        }
    }
    
}

template<int NC>
void sendB(ap_uint<PLIO_WIDTH> b_buf[Y*Z][RIGHT_SIZE*PACKET_NUM], bool enable,
           axis_stream& txB0, axis_stream& txB1, axis_stream& txB2,
           axis_stream& txB3, axis_stream& txB4, axis_stream& txB5){
#pragma HLS inline off
    if(enable){
        axis_pkt tmp;
        data_t1 data_temp[2][4];
        #pragma HLS ARRAY_PARTITION variable=data_temp complete dim=0
        data_t data;
        data_t da;
    
    
        for (int k = 0; k < PACKET_NUM*Y*X*Z; k++) {
            unsigned int ID=0;
            int tile=0;
    
            if(k<10){
                ID=packet_id0[k];
                tile=tile0[k];
            }
            else if(k<PACKET_NUM*Y*X*Z-6){
                int cnt=k-10;
                ID=cnt%PACKET_NUM;
                int pos1=cnt%(X*Y*PACKET_NUM);
                int incr;
                if(pos1<(X*Y-PACKET_NUM)*PACKET_NUM){
                    tile=(4-(pos1%PACKET_NUM)+(pos1/PACKET_NUM))%Y+(cnt/(X*Y*PACKET_NUM))*Y;
                }
                else{
                    incr=(pos1-(X*Y-PACKET_NUM)*PACKET_NUM)/4;
                    tile=4-pos1%PACKET_NUM+(cnt/(X*Y*PACKET_NUM))*Y+incr+(Y-PACKET_NUM);
                }
            }
            else{
                int pos2=k-PACKET_NUM*Y*X*Z+6;
                ID=packet_id2[pos2];
                tile=tile2[pos2]+(Y*Z-PACKET_NUM);
            }
    
            ap_uint<32> header=generateHeader(PKTTYPE,ID);
            int position=ID*RIGHT_SIZE;
    
            data=b_buf[tile][position];
            data_temp[0][0]=data(31,0);
            data_temp[0][1]=data(63,32);
            data_temp[0][2]=data(95,64);
            data_temp[0][3]=data(127,96);
            da(31,0)   = header;
            da(63,32)  = data_temp[0][0];
            da(95,64)  = data_temp[0][1];
            da(127,96) = data_temp[0][2];
            
            tmp.data  =  da;
            tmp.keep  =  -1;
            tmp.last  =  0;
        
            txB0.write(tmp);
            txB1.write(tmp);
            txB2.write(tmp);
            txB3.write(tmp);
            txB4.write(tmp);
            txB5.write(tmp);
            for (int i = 1; i < RIGHT_SIZE; i++){
            #pragma HLS PIPELINE II = 1
                int posb=ID*RIGHT_SIZE+i;   
    
                data=b_buf[tile][posb];
                data_temp[i%2][0]=data(31,0);
                data_temp[i%2][1]=data(63,32);
                data_temp[i%2][2]=data(95,64);
                data_temp[i%2][3]=data(127,96);
                da(31,0)   = data_temp[(i+1)%2][3];
                da(63,32)  = data_temp[i%2][0];
                da(95,64)  = data_temp[i%2][1];
                da(127,96) = data_temp[i%2][2];
                
                tmp.data   = da;
                tmp.keep   = -1;
                tmp.last   = 0;
                txB0.write(tmp);
                txB1.write(tmp);
                txB2.write(tmp);
                txB3.write(tmp);
                txB4.write(tmp);
                txB5.write(tmp);
            }
    
            da(31,0)   = data_temp[1][3];
            da(63,32)  = 0;
            da(95,64)  = 0;
            da(127,96) = 0;
            
    
            tmp.data =  da;
            tmp.keep  = 0x000f;
            tmp.last  = 1;
        
            txB0.write(tmp);
            txB1.write(tmp);
            txB2.write(tmp);
            txB3.write(tmp);
            txB4.write(tmp);
            txB5.write(tmp);
            
        }
    }
}

unsigned int getPacketId(ap_uint<32> header){
#pragma HLS inline
    ap_uint<32> ID=0;
    ID(4,0)=header(4,0);
    return ID;
}



template<int NC>
void reshapeC(ap_uint<PLIO_WIDTH> c_buf[X*Z][PACKET_NUM][OUT_SIZE],axis_stream& rxC, bool enable){   
#pragma HLS inline off
    if (enable){
        
        axis_pkt tmp; 
        int cnt[4];
        #pragma HLS ARRAY_PARTITION variable=cnt complete dim=0
        float data_temp[2][4];
        #pragma HLS ARRAY_PARTITION variable=data_temp complete dim=0

        fp_int intfp0;
        fp_int intfp1;
        fp_int intfp2;
        fp_int intfp3;
    fp_int ifp_temp0;
    fp_int ifp_temp1;
        fp_int ifp_temp2;
        fp_int ifp_temp3;   
    for(int i=0;i<PACKET_NUM;i++){
        #pragma HLS unroll
            cnt[i]=0;
        }
        for(int z = 0; z < Z; z++){
            for(int x = 0; x < X; x++){
                for(int j=0;j<PACKET_NUM;j++){
                    for (int i = 0; i < OUT_SIZE; i++){
                    #pragma HLS PIPELINE II = 1
                        c_buf[x+z*X][j][i]=0; 
                    }
                }
            }
        }
        for(int z = 0; z < Z; z++){
            for(int x = 0; x < X; x++){
                for (int n = 0; n < Y; n++){
                    for(int j=0;j<PACKET_NUM;j++){
                        ap_uint<32> header;
                        tmp=rxC.read();
                        
                        header=tmp.data(31,0);
                        
                        ifp_temp1.uintval=tmp.data(63,32);
                        ifp_temp2.uintval=tmp.data(95,64);
                        ifp_temp3.uintval=tmp.data(127,96);
            
            
                        data_temp[0][1]=ifp_temp1.data_cbuff;
                        data_temp[0][2]=ifp_temp2.data_cbuff;
                        data_temp[0][3]=ifp_temp3.data_cbuff;
                        
                        unsigned int ID=getPacketId(header);
    
                        unsigned int tile_x=cnt[ID]/Y;
                        cnt[ID]=cnt[ID]+1;
    
    
    
                        for(int i=0;i<OUT_SIZE;i++){
                        #pragma HLS PIPELINE II = 1
                            tmp=rxC.read();
                            

                            ifp_temp0.uintval=tmp.data(31,0);
                            ifp_temp1.uintval=tmp.data(63,32);
                            ifp_temp2.uintval=tmp.data(95,64);
                            ifp_temp3.uintval=tmp.data(127,96);

                            data_temp[(i+1)%2][0]=ifp_temp0.data_cbuff;
                            data_temp[(i+1)%2][1]=ifp_temp1.data_cbuff;
                            data_temp[(i+1)%2][2]=ifp_temp2.data_cbuff;
                            data_temp[(i+1)%2][3]=ifp_temp3.data_cbuff;
                            
                            intfp0.uintval=c_buf[tile_x][ID][i](31,0);
                            intfp1.uintval=c_buf[tile_x][ID][i](63,32);
                            intfp2.uintval=c_buf[tile_x][ID][i](95,64);
                            intfp3.uintval=c_buf[tile_x][ID][i](127,96);

                            intfp0.data_cbuff = data_temp[i%2][1] + intfp0.data_cbuff ;
                            intfp1.data_cbuff = data_temp[i%2][2] + intfp1.data_cbuff ;
                            intfp2.data_cbuff = data_temp[i%2][3] + intfp2.data_cbuff ;
                            intfp3.data_cbuff = data_temp[(i+1)%2][0] + intfp3.data_cbuff;

                            c_buf[tile_x][ID][i](31,0)   =  intfp0.uintval;  
                            c_buf[tile_x][ID][i](63,32)  =  intfp1.uintval;
                            c_buf[tile_x][ID][i](95,64)  =  intfp2.uintval;
                            c_buf[tile_x][ID][i](127,96) =  intfp3.uintval;
                            
                        }
                    }
                }
            } 
        }
    }
    
}

void storeC(ap_uint<AXI_WIDTH_256>* c_out,ap_uint<PLIO_WIDTH> c_buf[A*C/PACKET_NUM][X*Z][PACKET_NUM][OUT_SIZE], bool enable, int rd){
#pragma HLS inline off
    if(enable){
        for(int z=0;z<Z;z++){
            for(int j=0;j<PACKET_NUM;j++){
                for(int i=0;i<W2;i++){
                    for(int x=0;x<X;x++){
                        for (int k = 0; k < A*C/PACKET_NUM; k++){
                            for (int n = 0; n < H1/C_PER_TRA; n++){
                            #pragma HLS PIPELINE II = 1
                                ap_uint<AXI_WIDTH_256> temp;
                                temp(127,0)=c_buf[k][x+z*X][j][n*2+i*(H1/NUM_PER_TRA)];
                                temp(255,128)=c_buf[k][x+z*X][j][n*2+1+i*(H1/NUM_PER_TRA)];
                                c_out[rd*Z*W2*(H1/C_PER_TRA)*A*C*X+z*W2*(H1/C_PER_TRA)*A*C*X+x*(A*C/PACKET_NUM)*(H1/C_PER_TRA)+n+k*(H1/C_PER_TRA)+i*X*(A*C/PACKET_NUM)*(H1/C_PER_TRA)+j*W2*(H1/C_PER_TRA)*X*(A*C/PACKET_NUM)]=temp;
                            }
                        }
                    }
                }
            }
        }
    }
}

void dma(ap_uint<AXI_WIDTH_512>* ina, ap_uint<AXI_WIDTH_512>* inb, ap_uint<AXI_WIDTH_256>* out0, const int num_tilez,
            axis_stream& txA_0,  axis_stream& txA_1,  axis_stream& txA_2,  axis_stream& txA_3,
            axis_stream& txA_4,  axis_stream& txA_5,  axis_stream& txA_6,  axis_stream& txA_7,
            axis_stream& txA_8,  axis_stream& txA_9,  axis_stream& txA_10, axis_stream& txA_11,
            axis_stream& txA_12, axis_stream& txA_13, axis_stream& txA_14, axis_stream& txA_15,
            axis_stream& txA_16, axis_stream& txA_17, axis_stream& txA_18, axis_stream& txA_19,
            axis_stream& txA_20, axis_stream& txA_21, axis_stream& txA_22, axis_stream& txA_23,
            axis_stream& txB_0_0,  axis_stream& txB_0_1,  axis_stream& txB_0_2,
            axis_stream& txB_0_3,  axis_stream& txB_0_4,  axis_stream& txB_0_5,
            axis_stream& txB_1_0,  axis_stream& txB_1_1,  axis_stream& txB_1_2,
            axis_stream& txB_1_3,  axis_stream& txB_1_4,  axis_stream& txB_1_5,
            axis_stream& txB_2_0,  axis_stream& txB_2_1,  axis_stream& txB_2_2,
            axis_stream& txB_2_3,  axis_stream& txB_2_4,  axis_stream& txB_2_5,
            axis_stream& txB_3_0,  axis_stream& txB_3_1,  axis_stream& txB_3_2,
            axis_stream& txB_3_3,  axis_stream& txB_3_4,  axis_stream& txB_3_5,
            axis_stream& txB_4_0,  axis_stream& txB_4_1,  axis_stream& txB_4_2,
            axis_stream& txB_4_3,  axis_stream& txB_4_4,  axis_stream& txB_4_5,
            axis_stream& txB_5_0,  axis_stream& txB_5_1,  axis_stream& txB_5_2,
            axis_stream& txB_5_3,  axis_stream& txB_5_4,  axis_stream& txB_5_5,
            axis_stream& txB_6_0,  axis_stream& txB_6_1,  axis_stream& txB_6_2,
            axis_stream& txB_6_3,  axis_stream& txB_6_4,  axis_stream& txB_6_5,
            axis_stream& txB_7_0,  axis_stream& txB_7_1,  axis_stream& txB_7_2,
            axis_stream& txB_7_3,  axis_stream& txB_7_4,  axis_stream& txB_7_5,
            axis_stream& rxC_0, axis_stream& rxC_1, axis_stream& rxC_2, axis_stream& rxC_3,
            axis_stream& rxC_4, axis_stream& rxC_5, axis_stream& rxC_6, axis_stream& rxC_7,
            axis_stream& rxC_8, axis_stream& rxC_9, axis_stream& rxC_10, axis_stream& rxC_11)
{
    #pragma HLS interface m_axi offset=slave bundle=gmem0 port=ina max_read_burst_length=64 num_read_outstanding=64
    #pragma HLS interface s_axilite bundle=control port=ina
    #pragma HLS interface m_axi offset=slave bundle=gmem1 port=inb max_read_burst_length=64 num_read_outstanding=64
    #pragma HLS interface s_axilite bundle=control port=inb
    #pragma HLS interface m_axi offset=slave bundle=gmem2 port=out0 max_write_burst_length=64 num_write_outstanding=64
    #pragma HLS interface s_axilite bundle=control port=out0
    #pragma HLS interface s_axilite bundle=control port=num_tilez
    #pragma HLS interface axis port=txA_0
    #pragma HLS interface axis port=txA_1
    #pragma HLS interface axis port=txA_2
    #pragma HLS interface axis port=txA_3
    #pragma HLS interface axis port=txA_4
    #pragma HLS interface axis port=txA_5
    #pragma HLS interface axis port=txA_6
    #pragma HLS interface axis port=txA_7
    #pragma HLS interface axis port=txA_8
    #pragma HLS interface axis port=txA_9
    #pragma HLS interface axis port=txA_10
    #pragma HLS interface axis port=txA_11
    #pragma HLS interface axis port=txA_12
    #pragma HLS interface axis port=txA_13
    #pragma HLS interface axis port=txA_14
    #pragma HLS interface axis port=txA_15
    #pragma HLS interface axis port=txA_16
    #pragma HLS interface axis port=txA_17
    #pragma HLS interface axis port=txA_18
    #pragma HLS interface axis port=txA_19
    #pragma HLS interface axis port=txA_20
    #pragma HLS interface axis port=txA_21
    #pragma HLS interface axis port=txA_22
    #pragma HLS interface axis port=txA_23
    #pragma HLS interface axis port=txB_0_0
    #pragma HLS interface axis port=txB_0_1
    #pragma HLS interface axis port=txB_0_2
    #pragma HLS interface axis port=txB_0_3
    #pragma HLS interface axis port=txB_0_4
    #pragma HLS interface axis port=txB_0_5
    #pragma HLS interface axis port=txB_1_0
    #pragma HLS interface axis port=txB_1_1
    #pragma HLS interface axis port=txB_1_2
    #pragma HLS interface axis port=txB_1_3
    #pragma HLS interface axis port=txB_1_4
    #pragma HLS interface axis port=txB_1_5
    #pragma HLS interface axis port=txB_2_0
    #pragma HLS interface axis port=txB_2_1
    #pragma HLS interface axis port=txB_2_2
    #pragma HLS interface axis port=txB_2_3
    #pragma HLS interface axis port=txB_2_4
    #pragma HLS interface axis port=txB_2_5
    #pragma HLS interface axis port=txB_3_0
    #pragma HLS interface axis port=txB_3_1
    #pragma HLS interface axis port=txB_3_2
    #pragma HLS interface axis port=txB_3_3
    #pragma HLS interface axis port=txB_3_4
    #pragma HLS interface axis port=txB_3_5
    #pragma HLS interface axis port=txB_4_0
    #pragma HLS interface axis port=txB_4_1
    #pragma HLS interface axis port=txB_4_2
    #pragma HLS interface axis port=txB_4_3
    #pragma HLS interface axis port=txB_4_4
    #pragma HLS interface axis port=txB_4_5
    #pragma HLS interface axis port=txB_5_0
    #pragma HLS interface axis port=txB_5_1
    #pragma HLS interface axis port=txB_5_2
    #pragma HLS interface axis port=txB_5_3
    #pragma HLS interface axis port=txB_5_4
    #pragma HLS interface axis port=txB_5_5
    #pragma HLS interface axis port=txB_6_0
    #pragma HLS interface axis port=txB_6_1
    #pragma HLS interface axis port=txB_6_2
    #pragma HLS interface axis port=txB_6_3
    #pragma HLS interface axis port=txB_6_4
    #pragma HLS interface axis port=txB_6_5
    #pragma HLS interface axis port=txB_7_0
    #pragma HLS interface axis port=txB_7_1
    #pragma HLS interface axis port=txB_7_2
    #pragma HLS interface axis port=txB_7_3
    #pragma HLS interface axis port=txB_7_4
    #pragma HLS interface axis port=txB_7_5
    #pragma HLS interface axis port=rxC_0
    #pragma HLS interface axis port=rxC_1
    #pragma HLS interface axis port=rxC_2
    #pragma HLS interface axis port=rxC_3
    #pragma HLS interface axis port=rxC_4
    #pragma HLS interface axis port=rxC_5
    #pragma HLS interface axis port=rxC_6
    #pragma HLS interface axis port=rxC_7
    #pragma HLS interface axis port=rxC_8
    #pragma HLS interface axis port=rxC_9
    #pragma HLS interface axis port=rxC_10
    #pragma HLS interface axis port=rxC_11
    #pragma HLS interface s_axilite bundle=control port=return
    
    ///////////////////////////   Bank0  /////////////////////////////
    //Y*A*B*4KB

    ap_uint<PLIO_WIDTH> buff0_A[A*(B/PACKET_NUM)][X*Y][LEFT_SIZE*PACKET_NUM];
    #pragma HLS bind_storage variable=buff0_A type=RAM_1P impl=${L_buffer}
    #pragma HLS ARRAY_PARTITION variable=buff0_A cyclic factor=4 dim=3
    #pragma HLS ARRAY_PARTITION variable=buff0_A complete dim=1

    //Y*Z*B*C*4KB
    ap_uint<PLIO_WIDTH> buff0_B[(B/PACKET_NUM)*C][Y*Z][RIGHT_SIZE*PACKET_NUM];
    #pragma HLS bind_storage variable=buff0_B type=RAM_1P impl=${R_buffer}
    #pragma HLS ARRAY_PARTITION variable=buff0_B cyclic factor=4 dim=3
    #pragma HLS ARRAY_PARTITION variable=buff0_B complete dim=1

    ap_uint<PLIO_WIDTH> buff1_B[(B/PACKET_NUM)*C][Y*Z][RIGHT_SIZE*PACKET_NUM];
    #pragma HLS bind_storage variable=buff1_B type=RAM_1P impl=${R_buffer}
    #pragma HLS ARRAY_PARTITION variable=buff1_B cyclic factor=4 dim=3
    #pragma HLS ARRAY_PARTITION variable=buff1_B complete dim=1


    
    //A*C*4KB
    ap_uint<PLIO_WIDTH> buff0_C0[A*C/PACKET_NUM][X*Z][PACKET_NUM][OUT_SIZE];
    #pragma HLS bind_storage variable=buff0_C0 type=RAM_2P impl=${O_buffer}
    #pragma HLS ARRAY_PARTITION variable=buff0_C0 complete dim=1

    ap_uint<PLIO_WIDTH> buff1_C0[A*C/PACKET_NUM][X*Z][PACKET_NUM][OUT_SIZE];
    #pragma HLS bind_storage variable=buff1_C0 type=RAM_2P impl=${O_buffer}
    #pragma HLS ARRAY_PARTITION variable=buff1_C0 complete dim=1


    loadA(ina,buff0_A,1); 
    for(int i=0;i<num_tilez+2;i++){
        if(i%2==0){
            loadB(inb,buff0_B,i<num_tilez,i);
            sendA<0>(buff0_A[0],txA_0,((i>0)&&(i<num_tilez+1)));
            sendA<1>(buff0_A[1],txA_1,((i>0)&&(i<num_tilez+1)));
            sendA<2>(buff0_A[2],txA_2,((i>0)&&(i<num_tilez+1)));
            sendA<3>(buff0_A[3],txA_3,((i>0)&&(i<num_tilez+1)));
            sendA<4>(buff0_A[4],txA_4,((i>0)&&(i<num_tilez+1)));
            sendA<5>(buff0_A[5],txA_5,((i>0)&&(i<num_tilez+1)));
            sendA<6>(buff0_A[6],txA_6,((i>0)&&(i<num_tilez+1)));
            sendA<7>(buff0_A[7],txA_7,((i>0)&&(i<num_tilez+1)));
            sendA<8>(buff0_A[8],txA_8,((i>0)&&(i<num_tilez+1)));
            sendA<9>(buff0_A[9],txA_9,((i>0)&&(i<num_tilez+1)));
            sendA<10>(buff0_A[10],txA_10,((i>0)&&(i<num_tilez+1)));
            sendA<11>(buff0_A[11],txA_11,((i>0)&&(i<num_tilez+1)));
            sendA<12>(buff0_A[12],txA_12,((i>0)&&(i<num_tilez+1)));
            sendA<13>(buff0_A[13],txA_13,((i>0)&&(i<num_tilez+1)));
            sendA<14>(buff0_A[14],txA_14,((i>0)&&(i<num_tilez+1)));
            sendA<15>(buff0_A[15],txA_15,((i>0)&&(i<num_tilez+1)));
            sendA<16>(buff0_A[16],txA_16,((i>0)&&(i<num_tilez+1)));
            sendA<17>(buff0_A[17],txA_17,((i>0)&&(i<num_tilez+1)));
            sendA<18>(buff0_A[18],txA_18,((i>0)&&(i<num_tilez+1)));
            sendA<19>(buff0_A[19],txA_19,((i>0)&&(i<num_tilez+1)));
            sendA<20>(buff0_A[20],txA_20,((i>0)&&(i<num_tilez+1)));
            sendA<21>(buff0_A[21],txA_21,((i>0)&&(i<num_tilez+1)));
            sendA<22>(buff0_A[22],txA_22,((i>0)&&(i<num_tilez+1)));
            sendA<23>(buff0_A[23],txA_23,((i>0)&&(i<num_tilez+1)));
            sendB<0>(buff1_B[0],((i>0)&&(i<num_tilez+1)),
                txB_0_0,  txB_0_1,  txB_0_2,
                txB_0_3,  txB_0_4,  txB_0_5);
            sendB<1>(buff1_B[1],((i>0)&&(i<num_tilez+1)),
                txB_1_0,  txB_1_1,  txB_1_2,
                txB_1_3,  txB_1_4,  txB_1_5);
            sendB<2>(buff1_B[2],((i>0)&&(i<num_tilez+1)),
                txB_2_0,  txB_2_1,  txB_2_2,
                txB_2_3,  txB_2_4,  txB_2_5);
            sendB<3>(buff1_B[3],((i>0)&&(i<num_tilez+1)),
                txB_3_0,  txB_3_1,  txB_3_2,
                txB_3_3,  txB_3_4,  txB_3_5);
            sendB<4>(buff1_B[4],((i>0)&&(i<num_tilez+1)),
                txB_4_0,  txB_4_1,  txB_4_2,
                txB_4_3,  txB_4_4,  txB_4_5);
            sendB<5>(buff1_B[5],((i>0)&&(i<num_tilez+1)),
                txB_5_0,  txB_5_1,  txB_5_2,
                txB_5_3,  txB_5_4,  txB_5_5);
            sendB<6>(buff1_B[6],((i>0)&&(i<num_tilez+1)),
                txB_6_0,  txB_6_1,  txB_6_2,
                txB_6_3,  txB_6_4,  txB_6_5);
            sendB<7>(buff1_B[7],((i>0)&&(i<num_tilez+1)),
                txB_7_0,  txB_7_1,  txB_7_2,
                txB_7_3,  txB_7_4,  txB_7_5);
            reshapeC<0>(buff0_C0[0],rxC_0,((i>0)&&(i<num_tilez+1)));
            reshapeC<1>(buff0_C0[1],rxC_1,((i>0)&&(i<num_tilez+1)));
            reshapeC<2>(buff0_C0[2],rxC_2,((i>0)&&(i<num_tilez+1)));
            reshapeC<3>(buff0_C0[3],rxC_3,((i>0)&&(i<num_tilez+1)));
            reshapeC<4>(buff0_C0[4],rxC_4,((i>0)&&(i<num_tilez+1)));
            reshapeC<5>(buff0_C0[5],rxC_5,((i>0)&&(i<num_tilez+1)));
            reshapeC<6>(buff0_C0[6],rxC_6,((i>0)&&(i<num_tilez+1)));
            reshapeC<7>(buff0_C0[7],rxC_7,((i>0)&&(i<num_tilez+1)));
            reshapeC<8>(buff0_C0[8],rxC_8,((i>0)&&(i<num_tilez+1)));
            reshapeC<9>(buff0_C0[9],rxC_9,((i>0)&&(i<num_tilez+1)));
            reshapeC<10>(buff0_C0[10],rxC_10,((i>0)&&(i<num_tilez+1)));
            reshapeC<11>(buff0_C0[11],rxC_11,((i>0)&&(i<num_tilez+1)));
            storeC(out0,buff1_C0,i>1,(i-2));
        }
        else{
            loadB(inb,buff1_B,i<num_tilez,i);
            sendA<0>(buff0_A[0],txA_0,((i>0)&&(i<num_tilez+1)));
            sendA<1>(buff0_A[1],txA_1,((i>0)&&(i<num_tilez+1)));
            sendA<2>(buff0_A[2],txA_2,((i>0)&&(i<num_tilez+1)));
            sendA<3>(buff0_A[3],txA_3,((i>0)&&(i<num_tilez+1)));
            sendA<4>(buff0_A[4],txA_4,((i>0)&&(i<num_tilez+1)));
            sendA<5>(buff0_A[5],txA_5,((i>0)&&(i<num_tilez+1)));
            sendA<6>(buff0_A[6],txA_6,((i>0)&&(i<num_tilez+1)));
            sendA<7>(buff0_A[7],txA_7,((i>0)&&(i<num_tilez+1)));
            sendA<8>(buff0_A[8],txA_8,((i>0)&&(i<num_tilez+1)));
            sendA<9>(buff0_A[9],txA_9,((i>0)&&(i<num_tilez+1)));
            sendA<10>(buff0_A[10],txA_10,((i>0)&&(i<num_tilez+1)));
            sendA<11>(buff0_A[11],txA_11,((i>0)&&(i<num_tilez+1)));
            sendA<12>(buff0_A[12],txA_12,((i>0)&&(i<num_tilez+1)));
            sendA<13>(buff0_A[13],txA_13,((i>0)&&(i<num_tilez+1)));
            sendA<14>(buff0_A[14],txA_14,((i>0)&&(i<num_tilez+1)));
            sendA<15>(buff0_A[15],txA_15,((i>0)&&(i<num_tilez+1)));
            sendA<16>(buff0_A[16],txA_16,((i>0)&&(i<num_tilez+1)));
            sendA<17>(buff0_A[17],txA_17,((i>0)&&(i<num_tilez+1)));
            sendA<18>(buff0_A[18],txA_18,((i>0)&&(i<num_tilez+1)));
            sendA<19>(buff0_A[19],txA_19,((i>0)&&(i<num_tilez+1)));
            sendA<20>(buff0_A[20],txA_20,((i>0)&&(i<num_tilez+1)));
            sendA<21>(buff0_A[21],txA_21,((i>0)&&(i<num_tilez+1)));
            sendA<22>(buff0_A[22],txA_22,((i>0)&&(i<num_tilez+1)));
            sendA<23>(buff0_A[23],txA_23,((i>0)&&(i<num_tilez+1)));
            sendB<0>(buff0_B[0],((i>0)&&(i<num_tilez+1)),
                txB_0_0,  txB_0_1,  txB_0_2,
                txB_0_3,  txB_0_4,  txB_0_5);
            sendB<1>(buff0_B[1],((i>0)&&(i<num_tilez+1)),
                txB_1_0,  txB_1_1,  txB_1_2,
                txB_1_3,  txB_1_4,  txB_1_5);
            sendB<2>(buff0_B[2],((i>0)&&(i<num_tilez+1)),
                txB_2_0,  txB_2_1,  txB_2_2,
                txB_2_3,  txB_2_4,  txB_2_5);
            sendB<3>(buff0_B[3],((i>0)&&(i<num_tilez+1)),
                txB_3_0,  txB_3_1,  txB_3_2,
                txB_3_3,  txB_3_4,  txB_3_5);
            sendB<4>(buff0_B[4],((i>0)&&(i<num_tilez+1)),
                txB_4_0,  txB_4_1,  txB_4_2,
                txB_4_3,  txB_4_4,  txB_4_5);
            sendB<5>(buff0_B[5],((i>0)&&(i<num_tilez+1)),
                txB_5_0,  txB_5_1,  txB_5_2,
                txB_5_3,  txB_5_4,  txB_5_5);
            sendB<6>(buff0_B[6],((i>0)&&(i<num_tilez+1)),
                txB_6_0,  txB_6_1,  txB_6_2,
                txB_6_3,  txB_6_4,  txB_6_5);
            sendB<7>(buff0_B[7],((i>0)&&(i<num_tilez+1)),
                txB_7_0,  txB_7_1,  txB_7_2,
                txB_7_3,  txB_7_4,  txB_7_5);
            reshapeC<0>(buff1_C0[0],rxC_0,((i>0)&&(i<num_tilez+1)));
            reshapeC<1>(buff1_C0[1],rxC_1,((i>0)&&(i<num_tilez+1)));
            reshapeC<2>(buff1_C0[2],rxC_2,((i>0)&&(i<num_tilez+1)));
            reshapeC<3>(buff1_C0[3],rxC_3,((i>0)&&(i<num_tilez+1)));
            reshapeC<4>(buff1_C0[4],rxC_4,((i>0)&&(i<num_tilez+1)));
            reshapeC<5>(buff1_C0[5],rxC_5,((i>0)&&(i<num_tilez+1)));
            reshapeC<6>(buff1_C0[6],rxC_6,((i>0)&&(i<num_tilez+1)));
            reshapeC<7>(buff1_C0[7],rxC_7,((i>0)&&(i<num_tilez+1)));
            reshapeC<8>(buff1_C0[8],rxC_8,((i>0)&&(i<num_tilez+1)));
            reshapeC<9>(buff1_C0[9],rxC_9,((i>0)&&(i<num_tilez+1)));
            reshapeC<10>(buff1_C0[10],rxC_10,((i>0)&&(i<num_tilez+1)));
            reshapeC<11>(buff1_C0[11],rxC_11,((i>0)&&(i<num_tilez+1)));
            storeC(out0,buff0_C0,i>1,(i-2));
        }
    }

}
">> ./${file_name}/kernel/dma.cpp;

echo \
"
#ifndef _PACKET_SENDER_H_
#define _PACKET_SENDER_H_
#include <cstring>
#include <ap_int.h>
#include <hls_stream.h>
#include <ap_axi_sdata.h>

const int AXI_WIDTH_512=512;
const int AXI_WIDTH_256=256;
const int PLIO_WIDTH=128;
const int DATA_TYPE=32;
const int PKTTYPE=0; 
const int PACKET_NUM=4; 
const int H1=32;
const int W1=32;
const int W2=32;
const int A=12;
const int B=8;
const int C=4;
const int X=${x};
const int Y=${y};
const int Z=${z};
const int A_PER_TRA=AXI_WIDTH_512/DATA_TYPE;
const int C_PER_TRA=AXI_WIDTH_256/DATA_TYPE;
const int NUM_PER_TRA=PLIO_WIDTH/DATA_TYPE;
const int LEFT_SIZE=H1*W1/NUM_PER_TRA;
const int RIGHT_SIZE=W1*W2/NUM_PER_TRA;
const int OUT_SIZE=H1*W2/NUM_PER_TRA;   //256

const int PLIO_WIDTH1=32;
const int PAC_LENGTH=H1*W2*DATA_TYPE/PLIO_WIDTH1;  //1024

typedef ap_uint<PLIO_WIDTH> data_t;
typedef ap_uint<PLIO_WIDTH1> data_t1;
typedef ap_axiu<PLIO_WIDTH, 0, 0, 0> axis_pkt;
typedef hls::stream<axis_pkt> axis_stream;


typedef union{
    float data_cbuff;
    unsigned int uintval;
} fp_int;
ap_uint<32> generateHeader(unsigned int pktType, unsigned int ID);

void dma(ap_uint<AXI_WIDTH_512>* ina, ap_uint<AXI_WIDTH_512>* inb, ap_uint<AXI_WIDTH_256>* out0, const int num_tilez,
            axis_stream& txA_0,  axis_stream& txA_1,  axis_stream& txA_2,  axis_stream& txA_3,
            axis_stream& txA_4,  axis_stream& txA_5,  axis_stream& txA_6,  axis_stream& txA_7,
            axis_stream& txA_8,  axis_stream& txA_9,  axis_stream& txA_10, axis_stream& txA_11,
            axis_stream& txA_12, axis_stream& txA_13, axis_stream& txA_14, axis_stream& txA_15,
            axis_stream& txA_16, axis_stream& txA_17, axis_stream& txA_18, axis_stream& txA_19,
            axis_stream& txA_20, axis_stream& txA_21, axis_stream& txA_22, axis_stream& txA_23,
            axis_stream& txB_0_0,  axis_stream& txB_0_1,  axis_stream& txB_0_2,
            axis_stream& txB_0_3,  axis_stream& txB_0_4,  axis_stream& txB_0_5,
            axis_stream& txB_1_0,  axis_stream& txB_1_1,  axis_stream& txB_1_2,
            axis_stream& txB_1_3,  axis_stream& txB_1_4,  axis_stream& txB_1_5,
            axis_stream& txB_2_0,  axis_stream& txB_2_1,  axis_stream& txB_2_2,
            axis_stream& txB_2_3,  axis_stream& txB_2_4,  axis_stream& txB_2_5,
            axis_stream& txB_3_0,  axis_stream& txB_3_1,  axis_stream& txB_3_2,
            axis_stream& txB_3_3,  axis_stream& txB_3_4,  axis_stream& txB_3_5,
            axis_stream& txB_4_0,  axis_stream& txB_4_1,  axis_stream& txB_4_2,
            axis_stream& txB_4_3,  axis_stream& txB_4_4,  axis_stream& txB_4_5,
            axis_stream& txB_5_0,  axis_stream& txB_5_1,  axis_stream& txB_5_2,
            axis_stream& txB_5_3,  axis_stream& txB_5_4,  axis_stream& txB_5_5,
            axis_stream& txB_6_0,  axis_stream& txB_6_1,  axis_stream& txB_6_2,
            axis_stream& txB_6_3,  axis_stream& txB_6_4,  axis_stream& txB_6_5,
            axis_stream& txB_7_0,  axis_stream& txB_7_1,  axis_stream& txB_7_2,
            axis_stream& txB_7_3,  axis_stream& txB_7_4,  axis_stream& txB_7_5,
            axis_stream& rxC_0, axis_stream& rxC_1, axis_stream& rxC_2, axis_stream& rxC_3,
            axis_stream& rxC_4, axis_stream& rxC_5, axis_stream& rxC_6, axis_stream& rxC_7,
            axis_stream& rxC_8, axis_stream& rxC_9, axis_stream& rxC_10, axis_stream& rxC_11);


void loadA(ap_uint<AXI_WIDTH_512>* a_in, ap_uint<PLIO_WIDTH> a_buf[A*(B/PACKET_NUM)][X*Y][LEFT_SIZE*PACKET_NUM],bool enable);

void loadB(ap_uint<AXI_WIDTH_512>* b_in, ap_uint<PLIO_WIDTH> b_buf[(B/PACKET_NUM)*C][Y*Z][RIGHT_SIZE*PACKET_NUM],bool enable, int rd);

template<int NC>
void sendA(ap_uint<PLIO_WIDTH> a_buf[X*Y][LEFT_SIZE*PACKET_NUM],axis_stream& txA,bool enable);

template<int NC>
void sendB(ap_uint<PLIO_WIDTH> b_buf[Y*Z][RIGHT_SIZE*PACKET_NUM], bool enable,
           axis_stream& txB0, axis_stream& txB1, axis_stream& txB2,
           axis_stream& txB3, axis_stream& txB4, axis_stream& txB5);

template<int NC>
void reshapeC(ap_uint<PLIO_WIDTH> c_buf[X*Z][PACKET_NUM][OUT_SIZE],axis_stream& rxC, bool enable);

void storeC(ap_uint<AXI_WIDTH_256>* c_out,ap_uint<PLIO_WIDTH> c_buf[A*C/PACKET_NUM][X*Z][PACKET_NUM][OUT_SIZE], bool enable, int rd);


unsigned int getPacketId(ap_uint<32> header);

#endif

">> ./${file_name}/kernel/packet_sender.hpp;
fi

if [[ ${Auto_Compile} == 1 ]]
then
    cd ./${file_name};
    ./run_sys.sh;
    cd ../;
fi

echo "
Project $file_name created successfully!
        ";
fi