TOP_NAME := tb_wr_aref

RTL_FLIST := -f ../filelist/rtl.f \

TB_FLIST :=  -f ../filelist/tb.f \

SIM_TOOL     := vcs
SIM_OPTIONS  := -full64 -debug_acc+all +v2k -sverilog  \
				-kdb \
 				+error+500 \
                +notimingcheck \
				+nospecify \
				+delay_mode_distributed \
                +vcs+flush+all \
                +lint=TFIPC-L \
				+incdir+../rtl \

WAVE_TOOL := verdi

WAVE_FILE := ${TOP_NAME}.fsdb


comp :	
	${SIM_TOOL} ${SIM_OPTIONS} ${TB_FLIST} ${RTL_FLIST} -top ${TOP_NAME} -l compile.log

sim:
	./simv -l run.log 

wave:
	${WAVE_TOOL} $(TB_FLIST) $(RTL_FLIST) -ssf ${WAVE_FILE} -nologo  

.PHONY : clean
clean :
	rm -rf csrc simv.daidir simv ucli.key vcdplus.vpd DVEfiles INCA_libs asic_top.fsdb* *.log verdi_config_file novas.rc verdiLog
