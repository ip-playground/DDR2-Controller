/*
 *******************************************************************************
 *  Filename    :   define.v
 *
 *  Author      :   caosy      <1960552705@qq.com>
 * 
 *  Version     :   1.0.0
 *
 *  Created     :   3/20/2023
 *
 *******************************************************************************
 */

`define BA_BITS                3

//x16
`define ADDR_BITS               14 // Address Bits
`define ROW_BITS                14 // Number of Address bits
`define COL_BITS                10 // Number of Column bits
`define DM_BITS                 1 // Number of Data Mask bits
`define DQ_BITS                 8 // Number of Data bits
`define DQS_BITS                1 // Number of Dqs bits
`define TRRD                    750 // tRRD   Active bank a to Active bank b command time

//init模块
`define     tCK                 5               
`define     INIT_DELAY_300US    300000 
`define     INIT_DELAY_500NS    500
`define     tRPA                15              
`define     tMRD                2               //单位tCK
`define     tRFC                130           //原本应该是127.5，为了方便整除改为130
// `define     DEFAULT_ADDR        13'b0_0000_0000_0000
// `define     PRE_ALL_ADDR        13'b0_0100_0000_0000


//ref模块
`define     tREFI               7800


//Active
`define     tRCD                15      //12.5
`define     tRRD                7.5
`define     tRC                 55
`define     tFAW                35

//Write
`define     CL                  3       //速率400                  
`define     BL                  4