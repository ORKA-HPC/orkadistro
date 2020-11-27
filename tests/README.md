Scripts contain everything you need to run one example.
Source them with any combination of the following options as arguments:

    - b: build bitstream
    - h: build host binary (rebuilds GD and orka_xomp_common as well)
    - u: upload bitstream to fpga and perform pci rescan
    - r: run host binary

You may add spaces or dashes ('-') between options but they are not necessary.

Examples:
`. targetDoubleArray.sh bh`     (build bitstream and host binary)
`. targetDoubleArray.sh u`      (upload bitstream) 
`. targetDoubleArray.sh r`      (run host binary)
`. targetDoubleArray.sh rhub`   (do all of the above)
`. targetDoubleArray.sh -h ru -b`

Please make sure you have vivado in your path and the correct license server set:
export XILINXD_LICENSE_FILE=27000@lm-xilinx.rrz.uni-koeln.de
export XILINXD_LICENSE_FILE=2100@scotty.e-technik.uni-erlangen.de


Running the host binary inside the docker container doesn't work (yet?).
