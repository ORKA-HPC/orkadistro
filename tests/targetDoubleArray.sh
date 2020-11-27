#!/usr/bin/env bash

target_dir="$PWD/../orkaevolution/Z_completeFlowTests/targetDoubleArray"

curr="$PWD"
orkadistrobase="$PWD/.."
orkaevo="${orkadistrobase}/orkaevolution/orkaEvolution"
xomp_common="${orkadistrobase}/orkaevolution/orka_xomp_common"
orka_hw="${orkadistrobase}/fpgainfrastructure/hw"
orka_gd="${orkadistrobase}/fpgainfrastructure/sw/OrkaGenericDriver/src"


# read cmd args
build_bitstream=0
upload_bitstream=0
rebuild_gd=0
build_host_binary=0
run_host_binary=0
if [[ "$*" =~ "b" ]]; then build_bitstream=1; fi
if [[ "$*" =~ "u" ]]; then upload_bitstream=1; fi
if [[ "$*" =~ "h" ]]; then build_host_binary=1; rebuild_gd=1; fi
if [[ "$*" =~ "r" ]]; then run_host_binary=1; fi
echo "build_bitstream=$build_bitstream"
echo "upload_bitstream=$upload_bitstream"
echo "rebuild_gd=$rebuild_gd"
echo "build_host_binary=$build_host_binary"
echo "run_host_binary=$run_host_binary"


# build bitstream
if [[ $build_bitstream -ne 0 ]]; then
    cd $target_dir
    ORKA=$orkaevo make -f driver.mk fpgaHardware.bit
    cd $curr
fi


# upload bitstream
if [[ $upload_bitstream -ne 0 ]]; then
    ${orka_hw}/xilinx/configure_fpga ${target_dir}/bitstream.bit
    ${orka_hw}/pci_rescan
    ls -l /dev/xdma*
fi


# rebuild GD and orka_xomp_common
if [[ $rebuild_gd -ne 0 ]]; then
    cd ${orka_gd}
    make
    cd $xomp_common
    make
    cp llp_impl_ap2.so llp_impl_tpc.so
    cd $curr
fi


# build host binary
if [[ $build_host_binary -ne 0 ]]; then
    cd $target_dir
    ORKA=$orkaevo make -f driver.mk hostBinary
    cd $curr
fi


# run host binary
if [[ $run_host_binary -ne 0 ]]; then
    cd $target_dir
    LD_LIBRARY_PATH=$xomp_common ./hostBinary
    cd $curr
fi

cd "$curr"
