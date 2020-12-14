#!/usr/bin/env bash

target_dir_postfix="orkaevolution/Z_completeFlowTests/targetDoubleArray"

orkadistro_base_host="$PWD/../"
orkadistro_base_docker="/home/build/"
target_dir_host="${orkadistro_base_host}${target_dir_postfix}"
target_dir_docker="${orkadistro_base_docker}${target_dir_postfix}"
orkaevo_docker="${orkadistro_base_docker}/orkaevolution/orkaEvolution"
xomp_common_host="${orkadistro_base_host}/orkaevolution/orka_xomp_common"
xomp_common_docker="${orkadistro_base_docker}/orkaevolution/orka_xomp_common"
orka_hw_host="${orkadistro_base_host}/fpgainfrastructure/hw"
orka_gd_docker="${orkadistro_base_docker}/fpgainfrastructure/sw/OrkaGenericDriver/src"


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
    (cd $orkadistro_base_host &&
        ./run_docker.sh -r --exec-non-interactive \
        "cd $target_dir_docker &&
        ORKA=$orkaevo_docker make -f driver.mk fpgaHardware.bit")
fi


# upload bitstream
if [[ $upload_bitstream -ne 0 ]]; then
    ${orka_hw_host}/xilinx/configure_fpga ${target_dir_host}/bitstream.bit
    ${orka_hw_host}/pci_rescan
    ls -l /dev/xdma*
fi


# rebuild GD and orka_xomp_common
if [[ $rebuild_gd -ne 0 ]]; then
    (cd $orkadistro_base_host &&
        ./run_docker.sh -r --exec-non-interactive \
            "cd $orka_gd_docker &&
            make ;
            cd $xomp_common_docker &&
            make llp_impl_ap2.so ;
            cp llp_impl_ap2.so llp_impl_tpc.so")
fi


# build host binary
if [[ $build_host_binary -ne 0 ]]; then
    (cd $orkadistro_base_host &&
        ./run_docker.sh -r --exec-non-interactive \
            "cd $target_dir_docker &&
            ORKA=$orkaevo_docker make -f driver.mk hostBinary")
fi


# run host binary
if [[ $run_host_binary -ne 0 ]]; then
    (cd $target_dir_host &&
        LD_LIBRARY_PATH=$xomp_common_host ./hostBinary)
fi
