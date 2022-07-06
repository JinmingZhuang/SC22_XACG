
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
const int A=6;
const int B=4;
const int C=16;
const int X=8;
const int Y=1;
const int Z=2;
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
            axis_stream& rxC_20, axis_stream& rxC_21, axis_stream& rxC_22, axis_stream& rxC_23);


void loadA(ap_uint<AXI_WIDTH_512>* a_in, ap_uint<PLIO_WIDTH> a_buf[A*(B/PACKET_NUM)][X*Y][LEFT_SIZE*PACKET_NUM],bool enable,const int rd);

void loadB(ap_uint<AXI_WIDTH_512>* b_in, ap_uint<PLIO_WIDTH> b_buf[(B/PACKET_NUM)*C][Y*Z][RIGHT_SIZE*PACKET_NUM],bool enable, const int rd);

template<int NC>
void sendA(ap_uint<PLIO_WIDTH> a_buf[X*Y][LEFT_SIZE*PACKET_NUM],axis_stream& txA0, axis_stream& txA1,axis_stream& txA2,axis_stream& txA3, bool enable);

template<int NC>
void sendB(ap_uint<PLIO_WIDTH> b_buf[Y*Z][RIGHT_SIZE*PACKET_NUM], axis_stream& txB0, axis_stream& txB1, bool enable);

template<int NC>
void reshapeC(ap_uint<PLIO_WIDTH> c_buf[X*Z][PACKET_NUM][OUT_SIZE],axis_stream& rxC, bool enable);

void storeC(ap_uint<AXI_WIDTH_256>* c_out,ap_uint<PLIO_WIDTH> c_buf[A*C/PACKET_NUM][X*Z][PACKET_NUM][OUT_SIZE], bool enable, const int rd);


unsigned int getPacketId(ap_uint<32> header);

#endif


