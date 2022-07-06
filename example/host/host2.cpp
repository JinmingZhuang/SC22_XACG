/**
* Copyright (C) 2019-2021 Xilinx, Inc
*
* Licensed under the Apache License, Version 2.0 (the "License"). You may
* not use this file except in compliance with the License. A copy of the
* License is located at
*
*     http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
* WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
* License for the specific language governing permissions and limitations
* under the License.
*/

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <fstream>
#include <time.h>
#include <vector>
#include <math.h>
#include <omp.h>

// This is used for the PL Kernels
#include "xrt.h"
#include "experimental/xrt_kernel.h"
using namespace std;
static std::vector<char> load_xclbin(xrtDeviceHandle device, const std::string& fnm) {
    if (fnm.empty()) throw std::runtime_error("No xclbin specified");

    // load bit stream
    std::ifstream stream(fnm);
    stream.seekg(0, stream.end);
    size_t size = stream.tellg();
    stream.seekg(0, stream.beg);

    std::vector<char> header(size);
    stream.read(header.data(), size);

    auto top = reinterpret_cast<const axlf*>(header.data());
    if (xrtDeviceLoadXclbin(device, top)) throw std::runtime_error("Xclbin loading failed");

    return header;
}

const int PACKET_NUM=4; 
const int H1=32;
const int W1=32;
const int W2=32;
const int A=6;
const int B=4;
const int C=16;
const int X=8;
const int Y=1;
const int Z=2;

const int W2_2=32;
const int C1=16;
const int Z1=2;



const int DATA_SIZE1=H1*W1;
const int DATA_SIZE2=W1*W2;
const int OUT_SIZE=H1*W2;
const int DATA_SIZE3=W2*W2_2;
const int OUT_SIZE1=H1*W2_2;


int main(int argc, char** argv) {
    //////////////////////////////////////////
    // Open xclbin
    //////////////////////////////////////////
    if(argc != 2) {
    std::cout << "Usage: " << argv[0] <<" <xclbin>" << std::endl;
    return EXIT_FAILURE;
    }
    char* xclbinFilename = argv[1];
    //////////////////////////////////////////
    // Open xclbin
    //////////////////////////////////////////
    auto dhdl = xrtDeviceOpen(0); // Open Device the local device
    if (dhdl == nullptr) throw std::runtime_error("No valid device handle found. Make sure using right xclOpen index.");
    auto xclbin = load_xclbin(dhdl, xclbinFilename);
    auto top = reinterpret_cast<const axlf*>(xclbin.data());

    int TX,TY,TZ,TX1,TY1,TZ1;
    

    TX=1;
    TY=1;
    TZ=1;


    TX1=1;
    TY1=8;
    TZ1=1;
    int Lar_X=X*TX;
    int Lar_Y=Y*TY;
    int Lar_Z=Z*TZ;

    int Lar_X1=X*TX1;
    int Lar_Y1=Y*TY1;
    int Lar_Z1=Z1*TZ1;

    int sizeIn1 = DATA_SIZE1*A*B*Lar_X*Lar_Y;
    int sizeIn2 = DATA_SIZE2*B*C*Lar_Y*Lar_Z;
    int sizeOut = OUT_SIZE*A*C*Lar_X*Lar_Z;

    int sizeIn3 = DATA_SIZE3*C*C1*Lar_Z*Lar_Z1;

    int sizeOut1 = OUT_SIZE1*A*C1*Lar_X*Lar_Z1;

    
    vector<vector<vector<vector<vector<float>>>>> DataInput0(Lar_X, vector<vector<vector<vector<float>>>>(Lar_Y, vector<vector<vector<float>>>(A,vector<vector<float>>(B,vector<float>(DATA_SIZE1, 1)))));
    vector<vector<vector<vector<vector<float>>>>> DataInput1(Lar_Y, vector<vector<vector<vector<float>>>>(Lar_Z, vector<vector<vector<float>>>(B,vector<vector<float>>(C,vector<float>(DATA_SIZE2, 1)))));
    
    vector<vector<vector<vector<vector<float>>>>> golden(Lar_X, vector<vector<vector<vector<float>>>>(Lar_Z, vector<vector<vector<float>>>(A,vector<vector<float>>(C,vector<float>(OUT_SIZE, 1)))));

    vector<vector<vector<vector<vector<float>>>>> DataInput2(Lar_Z, vector<vector<vector<vector<float>>>>(Lar_Z1, vector<vector<vector<float>>>(C,vector<vector<float>>(C1,vector<float>(DATA_SIZE3, 1)))));
    vector<vector<vector<vector<vector<float>>>>> golden1(Lar_X, vector<vector<vector<vector<float>>>>(Lar_Z1, vector<vector<vector<float>>>(A,vector<vector<float>>(C1,vector<float>(OUT_SIZE1, 1)))));

    srand (time(0));
    for (int m = 0; m < Lar_X; m++) {
        for (int n = 0; n < Lar_Y; n++) {
            for (int k = 0; k < A; k++) {
                for (int j = 0; j < B; j++) {
                    for (int i = 0; i < DATA_SIZE1; i++) {
                        DataInput0[m][n][k][j][i] = (float)(rand()%5);
                    }
                }
            }
        }
    }

    srand (time(0));
    for (int m = 0; m < Lar_Y; m++) {
        for (int n = 0; n < Lar_Z; n++) {
            for (int k = 0; k < B; k++) {
                for (int j = 0; j < C; j++) {
                    for (int i = 0; i < DATA_SIZE2; i++) {
                        DataInput1[m][n][k][j][i] = (float)(rand()%5); //(rand()%5)*
                    }
                }
            }
        }
    }

    srand (time(0));
    for (int m = 0; m < Lar_Z; m++) {
        for (int n = 0; n < Lar_Z1; n++) {
            for (int k = 0; k < C; k++) {
                for (int j = 0; j < C1; j++) {
                    for (int i = 0; i < DATA_SIZE3; i++) {
                        DataInput2[m][n][k][j][i] = (float)(rand()%5); //(rand()%5)*
                    }
                }
            }
        }
    }
    
    //Allocate input mem
    xrtBufferHandle in_bohdl0 = xrtBOAlloc(dhdl, sizeIn1 * sizeof(float), 0, 0);
    auto in_bomapped0 = reinterpret_cast<float*>(xrtBOMap(in_bohdl0));


    xrtBufferHandle in_bohdl1 = xrtBOAlloc(dhdl, sizeIn2 * sizeof(float), 0, 0);
    auto in_bomapped1 = reinterpret_cast<float*>(xrtBOMap(in_bohdl1));

    xrtBufferHandle in_bohdl2 = xrtBOAlloc(dhdl, sizeIn3 * sizeof(float), 0, 0);
    auto in_bomapped2 = reinterpret_cast<float*>(xrtBOMap(in_bohdl2));
    
    for(int q=0;q<TX;q++){
        for(int m=0;m<Lar_Y;m++){
            for(int k=0;k<B;k++){
                for(int p=0;p<W1;p++){
                    for(int n=0;n<X;n++){
                        for(int j=0;j<A;j++){
                            for(int i=0;i<H1;i++){
                                in_bomapped0[i+j*H1+n*A*H1+p*X*A*H1+k*X*A*DATA_SIZE1+m*B*X*A*DATA_SIZE1+q*Lar_Y*B*X*A*DATA_SIZE1]=DataInput0[n+q*X][m][j][k][i*W1+p];
                            }
                        }
                    }
                }
            }
        }
    }

    for(int q=0;q<TZ;q++){
        for(int p=0;p<TY;p++){
            for(int z=0;z<Z;z++){
                for(int k=0;k<C;k++){
                    for(int j=0;j<W2;j++){
                        for(int n=0;n<Y;n++){
                            for(int i=0;i<B;i++){
                                for (int m=0;m<W1;m++){
                                    in_bomapped1[m+i*W1+n*B*W1+j*Y*B*W1+k*DATA_SIZE2*B*Y+z*C*DATA_SIZE2*B*Y+p*Z*C*DATA_SIZE2*B*Y+q*Z*C*DATA_SIZE2*B*Y*TY]=DataInput1[n+p*Y][z+q*Z][i][k][m*W2+j];
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    for(int q=0;q<TZ1;q++){
        for(int p=0;p<TZ;p++){
            for(int z=0;z<Z1;z++){
                for(int k=0;k<C1;k++){
                    for(int j=0;j<W2_2;j++){
                        for(int n=0;n<Z;n++){
                            for(int i=0;i<C;i++){
                                for (int m=0;m<W2;m++){
                                    in_bomapped2[m+i*W2+n*C*W2+j*Z*C*W2+k*DATA_SIZE3*C*Z+z*C1*DATA_SIZE3*C*Z+p*Z1*C1*DATA_SIZE3*C*Z+q*Z1*C1*DATA_SIZE3*C*Z*TZ]=DataInput2[n+p*Z][z+q*Z1][i][k][m*W2_2+j];
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    

    // sync input memory
    xrtBOSync(in_bohdl0, XCL_BO_SYNC_BO_TO_DEVICE , sizeIn1* sizeof(float),0);
    xrtBOSync(in_bohdl1, XCL_BO_SYNC_BO_TO_DEVICE , sizeIn2* sizeof(float),0);
    xrtBOSync(in_bohdl2, XCL_BO_SYNC_BO_TO_DEVICE , sizeIn3* sizeof(float),0);
    
    //Allocate output buffer
    float *out_bomapped; 
    xrtBufferHandle out_bohdl; 

    out_bohdl = xrtBOAlloc(dhdl, sizeOut* sizeof(float), 0, 0);
    out_bomapped = reinterpret_cast<float*>(xrtBOMap(out_bohdl));

    float *out_bomapped1; 
    xrtBufferHandle out_bohdl1; 

    out_bohdl1 = xrtBOAlloc(dhdl, sizeOut1* sizeof(float), 0, 0);
    out_bomapped1 = reinterpret_cast<float*>(xrtBOMap(out_bohdl1));
    


    //for (int i=0;i<iter;i++){
        //Open PL kernels handles
        std::cout << "Kernel run\n";
        xrtKernelHandle dma_khdl = xrtPLKernelOpen(dhdl, top->m_header.uuid, "dma");
        xrtRunHandle dma_rhdl;
        //profile aie mm 
        double kernel_time_in_sec = 0;
        std::chrono::duration<double> kernel_time(0);
        auto kernel_start = std::chrono::high_resolution_clock::now();
        const int iter=1;
        for (int i=0;i<iter;i++){
        // start input kernels run handles
        dma_rhdl = xrtKernelRun(dma_khdl, in_bohdl0, in_bohdl1,out_bohdl,TX,TY,TZ,
                            nullptr, nullptr, nullptr, nullptr,
                            nullptr, nullptr, nullptr, nullptr,
                            nullptr, nullptr, nullptr, nullptr,
                            nullptr, nullptr, nullptr, nullptr,
                            nullptr, nullptr, nullptr, nullptr,
                            nullptr, nullptr, nullptr, nullptr,
                            nullptr, nullptr, nullptr, nullptr,
                            nullptr, nullptr, nullptr, nullptr,
                            nullptr, nullptr, nullptr, nullptr,
                            nullptr, nullptr, nullptr, nullptr,
                            nullptr, nullptr, nullptr, nullptr,
                            nullptr, nullptr, nullptr, nullptr,
                            nullptr, nullptr, nullptr, nullptr,
                            nullptr, nullptr, nullptr, nullptr,
                            nullptr, nullptr, nullptr, nullptr,
                            nullptr, nullptr, nullptr, nullptr,
                            nullptr, nullptr, nullptr, nullptr,
                            nullptr, nullptr, nullptr, nullptr,
                            nullptr, nullptr, nullptr, nullptr,
                            nullptr, nullptr, nullptr, nullptr);



    
        //////////////////////////////////////////
        // wait for mm2s done
        //////////////////////////////////////////
        //Wait for kernel finish
        auto state = xrtRunWait(dma_rhdl);

        std::cout << "Kernel1 run\n";
        dma_rhdl = xrtKernelRun(dma_khdl, out_bohdl, in_bohdl2,out_bohdl1,TX1,TY1,TZ1,
                            nullptr, nullptr, nullptr, nullptr,
                            nullptr, nullptr, nullptr, nullptr,
                            nullptr, nullptr, nullptr, nullptr,
                            nullptr, nullptr, nullptr, nullptr,
                            nullptr, nullptr, nullptr, nullptr,
                            nullptr, nullptr, nullptr, nullptr,
                            nullptr, nullptr, nullptr, nullptr,
                            nullptr, nullptr, nullptr, nullptr,
                            nullptr, nullptr, nullptr, nullptr,
                            nullptr, nullptr, nullptr, nullptr,
                            nullptr, nullptr, nullptr, nullptr,
                            nullptr, nullptr, nullptr, nullptr,
                            nullptr, nullptr, nullptr, nullptr,
                            nullptr, nullptr, nullptr, nullptr,
                            nullptr, nullptr, nullptr, nullptr,
                            nullptr, nullptr, nullptr, nullptr,
                            nullptr, nullptr, nullptr, nullptr,
                            nullptr, nullptr, nullptr, nullptr,
                            nullptr, nullptr, nullptr, nullptr,
                            nullptr, nullptr, nullptr, nullptr);

        //////////////////////////////////////////
        // wait for mm2s done
        //////////////////////////////////////////
        //Wait for kernel finish
        state = xrtRunWait(dma_rhdl);
        }
 
        auto kernel_end = std::chrono::high_resolution_clock::now();
        kernel_time = std::chrono::duration<double>(kernel_end - kernel_start);
        kernel_time_in_sec = kernel_time.count();
        double TOPS = ((double)(1536 * 128) * (double) (1024 * 2 *iter* 1e-9)+(double)(1536 * 1024) * (double) (1024 * 2 *iter* 1e-9)) / kernel_time_in_sec;
        std::cout << std::endl;
        std::cout << std::endl;
        std::cout << "Total execution time is: "<< kernel_time_in_sec <<"s, TOPS = " << TOPS << " GOPS/s" << std::endl;
        std::cout << std::endl;
        std::cout << std::endl;
        // sync output memory

        xrtBOSync(out_bohdl, XCL_BO_SYNC_BO_FROM_DEVICE , sizeOut* sizeof(float),/*OFFSET=*/ 0);
        xrtBOSync(out_bohdl1, XCL_BO_SYNC_BO_FROM_DEVICE , sizeOut* sizeof(float),/*OFFSET=*/ 0);
        
    
        xrtRunClose(dma_rhdl);
        xrtKernelClose(dma_khdl);
    //}

    
    ////////////////////////////////////////////
    //// Comparing the execution data to the golden data
    ////////////////////////////////////////////

    
    for(int z=0;z<Lar_Z;z++){
        for (int x=0; x<Lar_X; x++){
            for (int a=0; a<A; a++){
                for (int c=0; c<C; c++){
                    for (int o=0; o<OUT_SIZE; o++){
                        golden[z][x][a][c][o]=0;
                        golden1[z][x][a][c][o]=0;
                    }
                }
            }
        }
    }

    
    {

    #pragma omp parallel
        {
            int tid = omp_get_thread_num();
            if( tid == 0 ){
                int nthreads = omp_get_num_threads();
                std::cout << "Running OpenMP with " << nthreads << " threads...\n";
            }
        }
    
        
        float sum = 0;
    #pragma omp parallel for private(sum)
        for(int z=0;z<Lar_Z;z++){
            for (int c=0; c<C; c++){
                for (int w2=0; w2<W2; w2++){
                    for (int x=0; x<Lar_X; x++){
                        for (int a=0; a<A; a++){
                            for (int h1=0; h1<H1; h1++){
                                sum=0;
                                for (int y=0; y<Lar_Y; y++){
                                    for (int b=0; b < B; b++) {
                                        for (int w1=0; w1 <W1 ; w1++) {
                                            sum=sum+DataInput0[x][y][a][b][w1+h1*W1]*DataInput1[y][z][b][c][w1*W2+w2];
                                        }
                                    }
                                }
                                golden[x][z][a][c][w2+h1*W2]=sum;
                            }
                        }
                    }
                }
            }
        }
    
    

    float sum1 = 0;
    #pragma omp parallel for private(sum1)
        for(int z1=0;z1<Lar_Z1;z1++){
            for (int c1=0; c1<C1; c1++){
                for (int w2_2=0; w2_2<W2_2; w2_2++){
                    for (int x=0; x<Lar_X; x++){
                        for (int a=0; a<A; a++){
                            for (int h1=0; h1<H1; h1++){
                                sum1=0;
                                for (int z=0; z<Lar_Z; z++){
                                    for (int c=0; c< C; c++) {
                                        for (int w2=0; w2 <W2 ; w2++) {
                                            sum1=sum1+golden[x][z][a][c][w2+h1*W2]*DataInput2[z][z1][c][c1][w2*W2_2+w2_2];
                                        }
                                    }
                                }
                                golden1[x][z1][a][c1][w2_2+h1*W2_2]=sum1;
                            }
                        }
                    }
                }
            }
        }
    
    }

    int errorCount = 0;
    {   
        for(int p=0;p<TX;p++){
            for(int z=0;z<Lar_Z;z++){
                for (int c=0; c<C; c++){
                    for (int w2=0; w2<W2; w2++){
                        for (int x=0; x<X; x++){
                            for (int a=0; a<A; a++){
                                for (int h1=0; h1<H1; h1++){
                                    if(abs((float)(out_bomapped[h1+a*H1+x*H1*A+w2*X*A*H1+c*OUT_SIZE*A*X+z*C*OUT_SIZE*A*X+p*Lar_Z*C*OUT_SIZE*A*X])-golden[x+p*X][z][a][c][h1*W2+w2])>=1e-3){
                                        printf("Error found out_bomapped[%d]!=golden[%d][%d][%d][%d][%d], %f!=%f \n", h1+a*H1+x*H1*A+w2*X*A*H1+c*OUT_SIZE*A*X+z*C*OUT_SIZE*A*X+p*Lar_Z*C*OUT_SIZE*A*X,z,x+p*X,a,c,h1*W2+w2,(float)out_bomapped[h1+a*H1+x*H1*A+w2*X*A*H1+c*OUT_SIZE*A*X+z*C*OUT_SIZE*A*X+p*Lar_Z*C*OUT_SIZE*A*X], golden[x+p*X][z][a][c][h1*W2+w2]);
                                        errorCount++;
                                    }
                                    if(abs((float)(out_bomapped1[h1+a*H1+x*H1*A+w2*X*A*H1+c*OUT_SIZE*A*X+z*C*OUT_SIZE*A*X+p*Lar_Z*C*OUT_SIZE*A*X])-golden1[x+p*X][z][a][c][h1*W2+w2])>=1e-3){
                                        printf("Error found out_bomapped1[%d]!=golden1[%d][%d][%d][%d][%d], %f!=%f \n", h1+a*H1+x*H1*A+w2*X*A*H1+c*OUT_SIZE*A*X+z*C*OUT_SIZE*A*X+p*Lar_Z*C*OUT_SIZE*A*X,z,x+p*X,a,c,h1*W2+w2,(float)out_bomapped1[h1+a*H1+x*H1*A+w2*X*A*H1+c*OUT_SIZE*A*X+z*C*OUT_SIZE*A*X+p*Lar_Z*C*OUT_SIZE*A*X], golden1[x+p*X][z][a][c][h1*W2+w2]);
                                        errorCount++;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        if (errorCount)
            printf("Test failed with %d errors\n", errorCount);
        else
            printf("TEST PASSED\n");
    }
    

    //////////////////////////////////////////
    // clean up XRT
    //////////////////////////////////////////

    std::cout << "Releasing remaining XRT objects...\n";
    
    xrtBOFree(out_bohdl);
    xrtBOFree(in_bohdl0);
    xrtBOFree(in_bohdl1);
    xrtDeviceClose(dhdl);
    return 0;
}
