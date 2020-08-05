ORKA_HPC_CCACHE_ENABLE="${ORKA_HPC_CCACHE_ENABLE:-"true"}"
if [ "$ORKA_HPC_CCACHE_ENABLE" = "true" ]; then
   echo Hook ccache into system
   export PATH="$ORKA_HPC_CCACHE_SYMLINK_DIR:$PATH"
fi
