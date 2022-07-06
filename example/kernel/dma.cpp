#include <stdint.h>
#include "packet_sender.hpp"

static const unsigned int tile0[10]={0,1,0,2,1,0,3,2,1,0};
static const unsigned int tile2[6]={3, 2, 1, 3, 2, 3};
static const unsigned int tileB[16]={1, 0, 0, 0, 1, 1, 0, 0, 1, 1, 1, 0, 1, 1, 1, 1};
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


void loadA(ap_uint<AXI_WIDTH_512>* a_in, ap_uint<PLIO_WIDTH> a_buf[A*(B/PACKET_NUM)][X*Y][LEFT_SIZE*PACKET_NUM],bool enable,const int rd){
#pragma HLS inline off
    if(enable){
        for(int m=0;m<Y;m++){
            for(int k=0;k<W1*B;k++){
                for(int n=0;n<X;n++){
                    for(int j=0;j<A;j++){
                        for(int i=0;i<(H1/A_PER_TRA);i++){
                            #pragma HLS PIPELINE II = 1
                            int pos=i+j*(H1/A_PER_TRA)+n*A*(H1/A_PER_TRA)+k*(A*X)*(H1/A_PER_TRA)+m*W1*B*X*A*(H1/A_PER_TRA)+rd*Y*W1*B*X*A*(H1/A_PER_TRA);
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

void loadB(ap_uint<AXI_WIDTH_512>* b_in, ap_uint<PLIO_WIDTH> b_buf[(B/PACKET_NUM)*C][Y*Z][RIGHT_SIZE*PACKET_NUM],bool enable, const int rd){
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
void sendA(ap_uint<PLIO_WIDTH> a_buf[X*Y][LEFT_SIZE*PACKET_NUM],axis_stream& txA0, axis_stream& txA1,axis_stream& txA2,axis_stream& txA3, bool enable){
#pragma HLS inline off
    if(enable){
        float data_temp[2][4];
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
            txA0.write(tmp);
            txA1.write(tmp);
            txA2.write(tmp);
            txA3.write(tmp);
    
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
    
                txA0.write(tmp);
                txA1.write(tmp);
                txA2.write(tmp);
                txA3.write(tmp);
            }
    
            da(31,0)=data_temp[1][3];
            da(63,32)  = 0;
            da(95,64)  = 0;
            da(127,96) = 0;
            tmp.data  =  da; 
            tmp.keep  = 0x000f;
            tmp.last  = 1;
             
            txA0.write(tmp);
            txA1.write(tmp);
            txA2.write(tmp);
            txA3.write(tmp);
        }
    }
    
}

template<int NC>
void sendB(ap_uint<PLIO_WIDTH> b_buf[Y*Z][RIGHT_SIZE*PACKET_NUM], axis_stream& txB0, axis_stream& txB1, bool enable){
#pragma HLS inline off
    if(enable){
        axis_pkt tmp;
        float data_temp[2][4];
        #pragma HLS ARRAY_PARTITION variable=data_temp complete dim=0
        data_t data;
        data_t da;
    
    
        for (int k = 0; k < PACKET_NUM*Y*X*Z; k++) {
            unsigned int ID=0;
            int tile=0;
    
            if(k<10){
                ID=packet_id0[k];
                tile=0;
            }
            else if(k<PACKET_NUM*Y*X*Z-6){
                int cnt=k-10;
                ID=cnt%PACKET_NUM;

                if(cnt<16){
                    tile=0;
                }
                else if(cnt<32){
                    int pos=cnt-16;
                    tile=tileB[pos];
                }
                else{
                    tile=1;
                }
            }
            else{
                int pos2=k-PACKET_NUM*Y*X*Z+6;
                ID=packet_id2[pos2];
                tile=1;
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

void storeC(ap_uint<AXI_WIDTH_256>* c_out,ap_uint<PLIO_WIDTH> c_buf[A*C/PACKET_NUM][X*Z][PACKET_NUM][OUT_SIZE], bool enable, const int rd){
#pragma HLS inline off
    if(enable){
        for(int z=0;z<Z;z++){
            for(int j=0;j<C;j++){
                for(int i=0;i<W2;i++){
                    for(int x=0;x<X;x++){
                        for (int k = 0; k < A; k++){
                            for (int n = 0; n < H1/C_PER_TRA; n++){
                            #pragma HLS PIPELINE II = 1
                                ap_uint<AXI_WIDTH_256> temp;
                                temp(127,0)=c_buf[k*(C/PACKET_NUM)+(j/PACKET_NUM)][x+z*X][j%PACKET_NUM][n*2+i*(H1/NUM_PER_TRA)];
                                temp(255,128)=c_buf[k*(C/PACKET_NUM)+(j/PACKET_NUM)][x+z*X][j%PACKET_NUM][n*2+1+i*(H1/NUM_PER_TRA)];
                                int pos=n+k*(H1/C_PER_TRA)+x*A*(H1/C_PER_TRA)+i*X*A*(H1/C_PER_TRA)+j*W2*(H1/C_PER_TRA)*X*A+z*W2*(H1/C_PER_TRA)*A*C*X+rd*Z*W2*(H1/C_PER_TRA)*A*C*X;
                                c_out[pos]=temp;
                            }
                        }
                    }
                }
            }
        }
        for(int x = 0; x < X*Z; x++){
            for(int j=0;j<PACKET_NUM;j++){
                for (int i = 0; i < OUT_SIZE; i++){
                    #pragma HLS PIPELINE II = 1
                    for(int a = 0; a < (A*C/PACKET_NUM); a++){
                        c_buf[a][x][j][i]=0; 
                    }
                }
            }
        }
    }
}

void dma(ap_uint<AXI_WIDTH_512>* ina, ap_uint<AXI_WIDTH_512>* inb, ap_uint<AXI_WIDTH_256>* out0, const int TX, const int TY, const int TZ,
            axis_stream& txA_0,  axis_stream& txA_1,  axis_stream& txA_2,  axis_stream& txA_3,
            axis_stream& txA_4,  axis_stream& txA_5,  axis_stream& txA_6,  axis_stream& txA_7,
            axis_stream& txA_8,  axis_stream& txA_9,  axis_stream& txA_10, axis_stream& txA_11,
            axis_stream& txA_12, axis_stream& txA_13, axis_stream& txA_14, axis_stream& txA_15,
            axis_stream& txA_16, axis_stream& txA_17, axis_stream& txA_18, axis_stream& txA_19,
            axis_stream& txA_20, axis_stream& txA_21, axis_stream& txA_22, axis_stream& txA_23,
            axis_stream& txB_0,  axis_stream& txB_1,  axis_stream& txB_2,  axis_stream& txB_3,
            axis_stream& txB_4,  axis_stream& txB_5,  axis_stream& txB_6,  axis_stream& txB_7,
            axis_stream& txB_8,  axis_stream& txB_9,  axis_stream& txB_10, axis_stream& txB_11,
            axis_stream& txB_12, axis_stream& txB_13, axis_stream& txB_14, axis_stream& txB_15,
            axis_stream& txB_16, axis_stream& txB_17, axis_stream& txB_18, axis_stream& txB_19,
            axis_stream& txB_20, axis_stream& txB_21, axis_stream& txB_22, axis_stream& txB_23,
            axis_stream& txB_24, axis_stream& txB_25, axis_stream& txB_26, axis_stream& txB_27,
            axis_stream& txB_28, axis_stream& txB_29, axis_stream& txB_30, axis_stream& txB_31,
            axis_stream& rxC_0, axis_stream& rxC_1, axis_stream& rxC_2, axis_stream& rxC_3,
            axis_stream& rxC_4, axis_stream& rxC_5, axis_stream& rxC_6, axis_stream& rxC_7,
            axis_stream& rxC_8, axis_stream& rxC_9, axis_stream& rxC_10, axis_stream& rxC_11,
            axis_stream& rxC_12, axis_stream& rxC_13, axis_stream& rxC_14, axis_stream& rxC_15,
            axis_stream& rxC_16, axis_stream& rxC_17, axis_stream& rxC_18, axis_stream& rxC_19,
            axis_stream& rxC_20, axis_stream& rxC_21, axis_stream& rxC_22, axis_stream& rxC_23)
{
    #pragma HLS interface m_axi offset=slave bundle=gmem0 port=ina max_read_burst_length=64 num_read_outstanding=64
    #pragma HLS interface s_axilite bundle=control port=ina
    #pragma HLS interface m_axi offset=slave bundle=gmem1 port=inb max_read_burst_length=64 num_read_outstanding=64
    #pragma HLS interface s_axilite bundle=control port=inb
    #pragma HLS interface m_axi offset=slave bundle=gmem2 port=out0 max_write_burst_length=64 num_write_outstanding=64
    #pragma HLS interface s_axilite bundle=control port=out0
    #pragma HLS interface s_axilite bundle=control port=TX
    #pragma HLS interface s_axilite bundle=control port=TY
    #pragma HLS interface s_axilite bundle=control port=TZ
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
    #pragma HLS interface axis port=txB_0
    #pragma HLS interface axis port=txB_1
    #pragma HLS interface axis port=txB_2
    #pragma HLS interface axis port=txB_3
    #pragma HLS interface axis port=txB_4
    #pragma HLS interface axis port=txB_5
    #pragma HLS interface axis port=txB_6
    #pragma HLS interface axis port=txB_7
    #pragma HLS interface axis port=txB_8
    #pragma HLS interface axis port=txB_9
    #pragma HLS interface axis port=txB_10
    #pragma HLS interface axis port=txB_11
    #pragma HLS interface axis port=txB_12
    #pragma HLS interface axis port=txB_13
    #pragma HLS interface axis port=txB_14
    #pragma HLS interface axis port=txB_15
    #pragma HLS interface axis port=txB_16
    #pragma HLS interface axis port=txB_17
    #pragma HLS interface axis port=txB_18
    #pragma HLS interface axis port=txB_19
    #pragma HLS interface axis port=txB_20
    #pragma HLS interface axis port=txB_21
    #pragma HLS interface axis port=txB_22
    #pragma HLS interface axis port=txB_23
    #pragma HLS interface axis port=txB_24
    #pragma HLS interface axis port=txB_25
    #pragma HLS interface axis port=txB_26
    #pragma HLS interface axis port=txB_27
    #pragma HLS interface axis port=txB_28
    #pragma HLS interface axis port=txB_29
    #pragma HLS interface axis port=txB_30
    #pragma HLS interface axis port=txB_31
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
    #pragma HLS interface axis port=rxC_12
    #pragma HLS interface axis port=rxC_13
    #pragma HLS interface axis port=rxC_14
    #pragma HLS interface axis port=rxC_15
    #pragma HLS interface axis port=rxC_16
    #pragma HLS interface axis port=rxC_17
    #pragma HLS interface axis port=rxC_18
    #pragma HLS interface axis port=rxC_19
    #pragma HLS interface axis port=rxC_20
    #pragma HLS interface axis port=rxC_21
    #pragma HLS interface axis port=rxC_22
    #pragma HLS interface axis port=rxC_23
    #pragma HLS interface s_axilite bundle=control port=return
    
    ///////////////////////////   Bank0  /////////////////////////////
    //Y*A*B*4KB

    ap_uint<PLIO_WIDTH> buff0_A[A*(B/PACKET_NUM)][X*Y][LEFT_SIZE*PACKET_NUM];
    #pragma HLS bind_storage variable=buff0_A type=RAM_1P impl=BRAM
    #pragma HLS ARRAY_PARTITION variable=buff0_A cyclic factor=4 dim=3
    #pragma HLS ARRAY_PARTITION variable=buff0_A complete dim=1

    ap_uint<PLIO_WIDTH> buff1_A[A*(B/PACKET_NUM)][X*Y][LEFT_SIZE*PACKET_NUM];
    #pragma HLS bind_storage variable=buff1_A type=RAM_1P impl=BRAM
    #pragma HLS ARRAY_PARTITION variable=buff1_A cyclic factor=4 dim=3
    #pragma HLS ARRAY_PARTITION variable=buff1_A complete dim=1

    //Y*Z*B*C*4KB
    ap_uint<PLIO_WIDTH> buff0_B[(B/PACKET_NUM)*C][Y*Z][RIGHT_SIZE*PACKET_NUM];
    #pragma HLS bind_storage variable=buff0_B type=RAM_1P impl=BRAM
    #pragma HLS ARRAY_PARTITION variable=buff0_B cyclic factor=4 dim=3
    #pragma HLS ARRAY_PARTITION variable=buff0_B complete dim=1

    ap_uint<PLIO_WIDTH> buff1_B[(B/PACKET_NUM)*C][Y*Z][RIGHT_SIZE*PACKET_NUM];
    #pragma HLS bind_storage variable=buff1_B type=RAM_1P impl=BRAM
    #pragma HLS ARRAY_PARTITION variable=buff1_B cyclic factor=4 dim=3
    #pragma HLS ARRAY_PARTITION variable=buff1_B complete dim=1

    //A*C*4KB
    ap_uint<PLIO_WIDTH> buff0_C[A*C/PACKET_NUM][X*Z][PACKET_NUM][OUT_SIZE];
    #pragma HLS bind_storage variable=buff0_C type=RAM_2P impl=URAM
    #pragma HLS ARRAY_PARTITION variable=buff0_C complete dim=1

    ap_uint<PLIO_WIDTH> buff1_C[A*C/PACKET_NUM][X*Z][PACKET_NUM][OUT_SIZE];
    #pragma HLS bind_storage variable=buff1_C type=RAM_2P impl=URAM
    #pragma HLS ARRAY_PARTITION variable=buff1_C complete dim=1


    const int Total_rd=TX*TY*TZ;
    for(int x = 0; x < X*Z; x++){
        for(int j=0;j<PACKET_NUM;j++){
            for (int i = 0; i < OUT_SIZE; i++){
                #pragma HLS PIPELINE II = 1
                for(int a = 0; a < (A*C/PACKET_NUM); a++){
                    buff0_C[a][x][j][i]=0; 
                    buff1_C[a][x][j][i]=0;
                }
            }
        }
    }

    for (int rd=0; rd<Total_rd+2;rd++){
        int c_flg=0,s_flg=0;
        int rd_L=0,rd_R=0,rd_O=0;
        rd_L=(rd%TY)+(rd/(TY*TZ))*TY;
        rd_R=rd%(TY*TZ);
        
        if(rd>0){
            c_flg=((rd-1)/TY)%2;
        }
        if(rd>1){
            s_flg=(rd-2)%TY;
            rd_O=(rd-2)/TY;
        }
        if(rd%2==0&&c_flg==0){
            loadA(ina,buff0_A,rd<Total_rd,rd_L);
            loadB(inb,buff0_B,rd<Total_rd,rd_R);
            sendA<0>(buff1_A[0],txA_0,txA_1,txA_2,txA_3,rd>0&&rd<Total_rd+1);
            sendA<1>(buff1_A[1],txA_4,txA_5,txA_6,txA_7,rd>0&&rd<Total_rd+1);
            sendA<2>(buff1_A[2],txA_8,txA_9,txA_10,txA_11,rd>0&&rd<Total_rd+1);
            sendA<3>(buff1_A[3],txA_12,txA_13,txA_14,txA_15,rd>0&&rd<Total_rd+1);
            sendA<4>(buff1_A[4],txA_16,txA_17,txA_18,txA_19,rd>0&&rd<Total_rd+1);
            sendA<5>(buff1_A[5],txA_20,txA_21,txA_22,txA_23,rd>0&&rd<Total_rd+1);

            sendB<0>(buff1_B[0],txB_0,txB_1,rd>0&&rd<Total_rd+1);
            sendB<1>(buff1_B[1],txB_2,txB_3,rd>0&&rd<Total_rd+1);
            sendB<2>(buff1_B[2],txB_4,txB_5,rd>0&&rd<Total_rd+1);
            sendB<3>(buff1_B[3],txB_6,txB_7,rd>0&&rd<Total_rd+1);
            sendB<4>(buff1_B[4],txB_8,txB_9,rd>0&&rd<Total_rd+1);
            sendB<5>(buff1_B[5],txB_10,txB_11,rd>0&&rd<Total_rd+1);
            sendB<6>(buff1_B[6],txB_12,txB_13,rd>0&&rd<Total_rd+1);
            sendB<7>(buff1_B[7],txB_14,txB_15,rd>0&&rd<Total_rd+1);
            sendB<8>(buff1_B[8],txB_16,txB_17,rd>0&&rd<Total_rd+1);
            sendB<9>(buff1_B[9],txB_18,txB_19,rd>0&&rd<Total_rd+1);
            sendB<10>(buff1_B[10],txB_20,txB_21,rd>0&&rd<Total_rd+1);
            sendB<11>(buff1_B[11],txB_22,txB_23,rd>0&&rd<Total_rd+1);
            sendB<12>(buff1_B[12],txB_24,txB_25,rd>0&&rd<Total_rd+1);
            sendB<13>(buff1_B[13],txB_26,txB_27,rd>0&&rd<Total_rd+1);
            sendB<14>(buff1_B[14],txB_28,txB_29,rd>0&&rd<Total_rd+1);
            sendB<15>(buff1_B[15],txB_30,txB_31,rd>0&&rd<Total_rd+1);
            
            reshapeC<0>(buff0_C[0],rxC_0,rd>0&&rd<Total_rd+1);
            reshapeC<1>(buff0_C[1],rxC_1,rd>0&&rd<Total_rd+1);
            reshapeC<2>(buff0_C[2],rxC_2,rd>0&&rd<Total_rd+1);
            reshapeC<3>(buff0_C[3],rxC_3,rd>0&&rd<Total_rd+1);
            reshapeC<4>(buff0_C[4],rxC_4,rd>0&&rd<Total_rd+1);
            reshapeC<5>(buff0_C[5],rxC_5,rd>0&&rd<Total_rd+1);
            reshapeC<6>(buff0_C[6],rxC_6,rd>0&&rd<Total_rd+1);
            reshapeC<7>(buff0_C[7],rxC_7,rd>0&&rd<Total_rd+1);
            reshapeC<8>(buff0_C[8],rxC_8,rd>0&&rd<Total_rd+1);
            reshapeC<9>(buff0_C[9],rxC_9,rd>0&&rd<Total_rd+1);
            reshapeC<10>(buff0_C[10],rxC_10,rd>0&&rd<Total_rd+1);
            reshapeC<11>(buff0_C[11],rxC_11,rd>0&&rd<Total_rd+1);
            reshapeC<12>(buff0_C[12],rxC_12,rd>0&&rd<Total_rd+1);
            reshapeC<13>(buff0_C[13],rxC_13,rd>0&&rd<Total_rd+1);
            reshapeC<14>(buff0_C[14],rxC_14,rd>0&&rd<Total_rd+1);
            reshapeC<15>(buff0_C[15],rxC_15,rd>0&&rd<Total_rd+1);
            reshapeC<16>(buff0_C[16],rxC_16,rd>0&&rd<Total_rd+1);
            reshapeC<17>(buff0_C[17],rxC_17,rd>0&&rd<Total_rd+1);
            reshapeC<18>(buff0_C[18],rxC_18,rd>0&&rd<Total_rd+1);
            reshapeC<19>(buff0_C[19],rxC_19,rd>0&&rd<Total_rd+1);
            reshapeC<20>(buff0_C[20],rxC_20,rd>0&&rd<Total_rd+1);
            reshapeC<21>(buff0_C[21],rxC_21,rd>0&&rd<Total_rd+1);
            reshapeC<22>(buff0_C[22],rxC_22,rd>0&&rd<Total_rd+1);
            reshapeC<23>(buff0_C[23],rxC_23,rd>0&&rd<Total_rd+1);
            storeC(out0,buff1_C,rd>TY&&s_flg==(TY-1),rd_O);
        }
        else if(rd%2==1&&c_flg==0){
            loadA(ina,buff1_A,rd<Total_rd,rd_L);
            loadB(inb,buff1_B,rd<Total_rd,rd_R);
            sendA<0>(buff0_A[0],txA_0,txA_1,txA_2,txA_3,rd>0&&rd<Total_rd+1);
            sendA<1>(buff0_A[1],txA_4,txA_5,txA_6,txA_7,rd>0&&rd<Total_rd+1);
            sendA<2>(buff0_A[2],txA_8,txA_9,txA_10,txA_11,rd>0&&rd<Total_rd+1);
            sendA<3>(buff0_A[3],txA_12,txA_13,txA_14,txA_15,rd>0&&rd<Total_rd+1);
            sendA<4>(buff0_A[4],txA_16,txA_17,txA_18,txA_19,rd>0&&rd<Total_rd+1);
            sendA<5>(buff0_A[5],txA_20,txA_21,txA_22,txA_23,rd>0&&rd<Total_rd+1);
            sendB<0>(buff0_B[0],txB_0,txB_1,rd>0&&rd<Total_rd+1);
            sendB<1>(buff0_B[1],txB_2,txB_3,rd>0&&rd<Total_rd+1);
            sendB<2>(buff0_B[2],txB_4,txB_5,rd>0&&rd<Total_rd+1);
            sendB<3>(buff0_B[3],txB_6,txB_7,rd>0&&rd<Total_rd+1);
            sendB<4>(buff0_B[4],txB_8,txB_9,rd>0&&rd<Total_rd+1);
            sendB<5>(buff0_B[5],txB_10,txB_11,rd>0&&rd<Total_rd+1);
            sendB<6>(buff0_B[6],txB_12,txB_13,rd>0&&rd<Total_rd+1);
            sendB<7>(buff0_B[7],txB_14,txB_15,rd>0&&rd<Total_rd+1);
            sendB<8>(buff0_B[8],txB_16,txB_17,rd>0&&rd<Total_rd+1);
            sendB<9>(buff0_B[9],txB_18,txB_19,rd>0&&rd<Total_rd+1);
            sendB<10>(buff0_B[10],txB_20,txB_21,rd>0&&rd<Total_rd+1);
            sendB<11>(buff0_B[11],txB_22,txB_23,rd>0&&rd<Total_rd+1);
            sendB<12>(buff0_B[12],txB_24,txB_25,rd>0&&rd<Total_rd+1);
            sendB<13>(buff0_B[13],txB_26,txB_27,rd>0&&rd<Total_rd+1);
            sendB<14>(buff0_B[14],txB_28,txB_29,rd>0&&rd<Total_rd+1);
            sendB<15>(buff0_B[15],txB_30,txB_31,rd>0&&rd<Total_rd+1);
            reshapeC<0>(buff0_C[0],rxC_0,rd>0&&rd<Total_rd+1);
            reshapeC<1>(buff0_C[1],rxC_1,rd>0&&rd<Total_rd+1);
            reshapeC<2>(buff0_C[2],rxC_2,rd>0&&rd<Total_rd+1);
            reshapeC<3>(buff0_C[3],rxC_3,rd>0&&rd<Total_rd+1);
            reshapeC<4>(buff0_C[4],rxC_4,rd>0&&rd<Total_rd+1);
            reshapeC<5>(buff0_C[5],rxC_5,rd>0&&rd<Total_rd+1);
            reshapeC<6>(buff0_C[6],rxC_6,rd>0&&rd<Total_rd+1);
            reshapeC<7>(buff0_C[7],rxC_7,rd>0&&rd<Total_rd+1);
            reshapeC<8>(buff0_C[8],rxC_8,rd>0&&rd<Total_rd+1);
            reshapeC<9>(buff0_C[9],rxC_9,rd>0&&rd<Total_rd+1);
            reshapeC<10>(buff0_C[10],rxC_10,rd>0&&rd<Total_rd+1);
            reshapeC<11>(buff0_C[11],rxC_11,rd>0&&rd<Total_rd+1);
            reshapeC<12>(buff0_C[12],rxC_12,rd>0&&rd<Total_rd+1);
            reshapeC<13>(buff0_C[13],rxC_13,rd>0&&rd<Total_rd+1);
            reshapeC<14>(buff0_C[14],rxC_14,rd>0&&rd<Total_rd+1);
            reshapeC<15>(buff0_C[15],rxC_15,rd>0&&rd<Total_rd+1);
            reshapeC<16>(buff0_C[16],rxC_16,rd>0&&rd<Total_rd+1);
            reshapeC<17>(buff0_C[17],rxC_17,rd>0&&rd<Total_rd+1);
            reshapeC<18>(buff0_C[18],rxC_18,rd>0&&rd<Total_rd+1);
            reshapeC<19>(buff0_C[19],rxC_19,rd>0&&rd<Total_rd+1);
            reshapeC<20>(buff0_C[20],rxC_20,rd>0&&rd<Total_rd+1);
            reshapeC<21>(buff0_C[21],rxC_21,rd>0&&rd<Total_rd+1);
            reshapeC<22>(buff0_C[22],rxC_22,rd>0&&rd<Total_rd+1);
            reshapeC<23>(buff0_C[23],rxC_23,rd>0&&rd<Total_rd+1);
            storeC(out0,buff1_C,rd>TY&&s_flg==(TY-1),rd_O);
        }
        else if(rd%2==0&&c_flg==1){
            loadA(ina,buff0_A,rd<Total_rd,rd_L);
            loadB(inb,buff0_B,rd<Total_rd,rd_R);
            sendA<0>(buff1_A[0],txA_0,txA_1,txA_2,txA_3,rd>0&&rd<Total_rd+1);
            sendA<1>(buff1_A[1],txA_4,txA_5,txA_6,txA_7,rd>0&&rd<Total_rd+1);
            sendA<2>(buff1_A[2],txA_8,txA_9,txA_10,txA_11,rd>0&&rd<Total_rd+1);
            sendA<3>(buff1_A[3],txA_12,txA_13,txA_14,txA_15,rd>0&&rd<Total_rd+1);
            sendA<4>(buff1_A[4],txA_16,txA_17,txA_18,txA_19,rd>0&&rd<Total_rd+1);
            sendA<5>(buff1_A[5],txA_20,txA_21,txA_22,txA_23,rd>0&&rd<Total_rd+1);
            sendB<0>(buff1_B[0],txB_0,txB_1,rd>0&&rd<Total_rd+1);
            sendB<1>(buff1_B[1],txB_2,txB_3,rd>0&&rd<Total_rd+1);
            sendB<2>(buff1_B[2],txB_4,txB_5,rd>0&&rd<Total_rd+1);
            sendB<3>(buff1_B[3],txB_6,txB_7,rd>0&&rd<Total_rd+1);
            sendB<4>(buff1_B[4],txB_8,txB_9,rd>0&&rd<Total_rd+1);
            sendB<5>(buff1_B[5],txB_10,txB_11,rd>0&&rd<Total_rd+1);
            sendB<6>(buff1_B[6],txB_12,txB_13,rd>0&&rd<Total_rd+1);
            sendB<7>(buff1_B[7],txB_14,txB_15,rd>0&&rd<Total_rd+1);
            sendB<8>(buff1_B[8],txB_16,txB_17,rd>0&&rd<Total_rd+1);
            sendB<9>(buff1_B[9],txB_18,txB_19,rd>0&&rd<Total_rd+1);
            sendB<10>(buff1_B[10],txB_20,txB_21,rd>0&&rd<Total_rd+1);
            sendB<11>(buff1_B[11],txB_22,txB_23,rd>0&&rd<Total_rd+1);
            sendB<12>(buff1_B[12],txB_24,txB_25,rd>0&&rd<Total_rd+1);
            sendB<13>(buff1_B[13],txB_26,txB_27,rd>0&&rd<Total_rd+1);
            sendB<14>(buff1_B[14],txB_28,txB_29,rd>0&&rd<Total_rd+1);
            sendB<15>(buff1_B[15],txB_30,txB_31,rd>0&&rd<Total_rd+1);
            reshapeC<0>(buff1_C[0],rxC_0,rd>0&&rd<Total_rd+1);
            reshapeC<1>(buff1_C[1],rxC_1,rd>0&&rd<Total_rd+1);
            reshapeC<2>(buff1_C[2],rxC_2,rd>0&&rd<Total_rd+1);
            reshapeC<3>(buff1_C[3],rxC_3,rd>0&&rd<Total_rd+1);
            reshapeC<4>(buff1_C[4],rxC_4,rd>0&&rd<Total_rd+1);
            reshapeC<5>(buff1_C[5],rxC_5,rd>0&&rd<Total_rd+1);
            reshapeC<6>(buff1_C[6],rxC_6,rd>0&&rd<Total_rd+1);
            reshapeC<7>(buff1_C[7],rxC_7,rd>0&&rd<Total_rd+1);
            reshapeC<8>(buff1_C[8],rxC_8,rd>0&&rd<Total_rd+1);
            reshapeC<9>(buff1_C[9],rxC_9,rd>0&&rd<Total_rd+1);
            reshapeC<10>(buff1_C[10],rxC_10,rd>0&&rd<Total_rd+1);
            reshapeC<11>(buff1_C[11],rxC_11,rd>0&&rd<Total_rd+1);
            reshapeC<12>(buff1_C[12],rxC_12,rd>0&&rd<Total_rd+1);
            reshapeC<13>(buff1_C[13],rxC_13,rd>0&&rd<Total_rd+1);
            reshapeC<14>(buff1_C[14],rxC_14,rd>0&&rd<Total_rd+1);
            reshapeC<15>(buff1_C[15],rxC_15,rd>0&&rd<Total_rd+1);
            reshapeC<16>(buff1_C[16],rxC_16,rd>0&&rd<Total_rd+1);
            reshapeC<17>(buff1_C[17],rxC_17,rd>0&&rd<Total_rd+1);
            reshapeC<18>(buff1_C[18],rxC_18,rd>0&&rd<Total_rd+1);
            reshapeC<19>(buff1_C[19],rxC_19,rd>0&&rd<Total_rd+1);
            reshapeC<20>(buff1_C[20],rxC_20,rd>0&&rd<Total_rd+1);
            reshapeC<21>(buff1_C[21],rxC_21,rd>0&&rd<Total_rd+1);
            reshapeC<22>(buff1_C[22],rxC_22,rd>0&&rd<Total_rd+1);
            reshapeC<23>(buff1_C[23],rxC_23,rd>0&&rd<Total_rd+1);
            storeC(out0,buff0_C,rd>TY&&s_flg==(TY-1),rd_O);
        }
        else { //if(rd%2==1&&c_flg==1)
            loadA(ina,buff1_A,rd<Total_rd,rd_L);
            loadB(inb,buff1_B,rd<Total_rd,rd_R);
            sendA<0>(buff0_A[0],txA_0,txA_1,txA_2,txA_3,rd>0&&rd<Total_rd+1);
            sendA<1>(buff0_A[1],txA_4,txA_5,txA_6,txA_7,rd>0&&rd<Total_rd+1);
            sendA<2>(buff0_A[2],txA_8,txA_9,txA_10,txA_11,rd>0&&rd<Total_rd+1);
            sendA<3>(buff0_A[3],txA_12,txA_13,txA_14,txA_15,rd>0&&rd<Total_rd+1);
            sendA<4>(buff0_A[4],txA_16,txA_17,txA_18,txA_19,rd>0&&rd<Total_rd+1);
            sendA<5>(buff0_A[5],txA_20,txA_21,txA_22,txA_23,rd>0&&rd<Total_rd+1);
            sendB<0>(buff0_B[0],txB_0,txB_1,rd>0&&rd<Total_rd+1);
            sendB<1>(buff0_B[1],txB_2,txB_3,rd>0&&rd<Total_rd+1);
            sendB<2>(buff0_B[2],txB_4,txB_5,rd>0&&rd<Total_rd+1);
            sendB<3>(buff0_B[3],txB_6,txB_7,rd>0&&rd<Total_rd+1);
            sendB<4>(buff0_B[4],txB_8,txB_9,rd>0&&rd<Total_rd+1);
            sendB<5>(buff0_B[5],txB_10,txB_11,rd>0&&rd<Total_rd+1);
            sendB<6>(buff0_B[6],txB_12,txB_13,rd>0&&rd<Total_rd+1);
            sendB<7>(buff0_B[7],txB_14,txB_15,rd>0&&rd<Total_rd+1);
            sendB<8>(buff0_B[8],txB_16,txB_17,rd>0&&rd<Total_rd+1);
            sendB<9>(buff0_B[9],txB_18,txB_19,rd>0&&rd<Total_rd+1);
            sendB<10>(buff0_B[10],txB_20,txB_21,rd>0&&rd<Total_rd+1);
            sendB<11>(buff0_B[11],txB_22,txB_23,rd>0&&rd<Total_rd+1);
            sendB<12>(buff0_B[12],txB_24,txB_25,rd>0&&rd<Total_rd+1);
            sendB<13>(buff0_B[13],txB_26,txB_27,rd>0&&rd<Total_rd+1);
            sendB<14>(buff0_B[14],txB_28,txB_29,rd>0&&rd<Total_rd+1);
            sendB<15>(buff0_B[15],txB_30,txB_31,rd>0&&rd<Total_rd+1);
            reshapeC<0>(buff1_C[0],rxC_0,rd>0&&rd<Total_rd+1);
            reshapeC<1>(buff1_C[1],rxC_1,rd>0&&rd<Total_rd+1);
            reshapeC<2>(buff1_C[2],rxC_2,rd>0&&rd<Total_rd+1);
            reshapeC<3>(buff1_C[3],rxC_3,rd>0&&rd<Total_rd+1);
            reshapeC<4>(buff1_C[4],rxC_4,rd>0&&rd<Total_rd+1);
            reshapeC<5>(buff1_C[5],rxC_5,rd>0&&rd<Total_rd+1);
            reshapeC<6>(buff1_C[6],rxC_6,rd>0&&rd<Total_rd+1);
            reshapeC<7>(buff1_C[7],rxC_7,rd>0&&rd<Total_rd+1);
            reshapeC<8>(buff1_C[8],rxC_8,rd>0&&rd<Total_rd+1);
            reshapeC<9>(buff1_C[9],rxC_9,rd>0&&rd<Total_rd+1);
            reshapeC<10>(buff1_C[10],rxC_10,rd>0&&rd<Total_rd+1);
            reshapeC<11>(buff1_C[11],rxC_11,rd>0&&rd<Total_rd+1);
            reshapeC<12>(buff1_C[12],rxC_12,rd>0&&rd<Total_rd+1);
            reshapeC<13>(buff1_C[13],rxC_13,rd>0&&rd<Total_rd+1);
            reshapeC<14>(buff1_C[14],rxC_14,rd>0&&rd<Total_rd+1);
            reshapeC<15>(buff1_C[15],rxC_15,rd>0&&rd<Total_rd+1);
            reshapeC<16>(buff1_C[16],rxC_16,rd>0&&rd<Total_rd+1);
            reshapeC<17>(buff1_C[17],rxC_17,rd>0&&rd<Total_rd+1);
            reshapeC<18>(buff1_C[18],rxC_18,rd>0&&rd<Total_rd+1);
            reshapeC<19>(buff1_C[19],rxC_19,rd>0&&rd<Total_rd+1);
            reshapeC<20>(buff1_C[20],rxC_20,rd>0&&rd<Total_rd+1);
            reshapeC<21>(buff1_C[21],rxC_21,rd>0&&rd<Total_rd+1);
            reshapeC<22>(buff1_C[22],rxC_22,rd>0&&rd<Total_rd+1);
            reshapeC<23>(buff1_C[23],rxC_23,rd>0&&rd<Total_rd+1);
            storeC(out0,buff0_C,rd>TY&&s_flg==(TY-1),rd_O);
        }
    }

}

