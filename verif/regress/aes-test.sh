# Set RISCV_CC for compilation
export RISCV=/home/laura/riscv
export DV_SIMULATORS=veri-testharness

# Install tools
source ./verif/regress/install-verilator.sh
source ./verif/regress/install-spike.sh

# Install test suites
source ./verif/regress/install-riscv-compliance.sh
source ./verif/regress/install-riscv-tests.sh
source ./verif/regress/install-riscv-arch-test.sh

# Setup sim environment
source ./verif/sim/setup-env.sh

# Extra options for DV
export DV_OPTS="$DV_OPTS --issrun_opts=+debug_disable=1+UVM_VERBOSITY=UVM_NONE"

# Set gcc options
export CC_OPTS="-static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -g ../tests/custom/common/syscalls.c ../tests/custom/common/crt.S -I../tests/custom/env -I../tests/custom/common"
export TRACE_FAST=1

# Move to the simulation directory
cd verif/sim/
# make -C ../.. clean
# make clean_all

# Run AES test
# python3 cva6.py --asm_tests /home/laura/cva6/verif/tests/custom/aes/aes.S --iss_yaml cva6.yaml --target cv64a6_imafdc_sv39 --iss=$DV_SIMULATORS --gcc_opts="$CC_OPTS -T ../tests/custom/common/test.ld" $DV_OPTS


# TEST
# python3 cva6.py --asm_tests /home/laura/cva6/verif/tests/custom/aes/aes_nist.S --iss_yaml cva6.yaml --target cv64a6_imafdc_sv39 --iss=$DV_SIMULATORS --gcc_opts="$CC_OPTS -T ../tests/custom/common/test.ld" $DV_OPTS
# python3 cva6.py --asm_tests /home/laura/cva6/verif/tests/custom/aes/aes_zero.S --iss_yaml cva6.yaml --target cv64a6_imafdc_sv39 --iss=$DV_SIMULATORS --gcc_opts="$CC_OPTS -T ../tests/custom/common/test.ld" $DV_OPTS
# python3 cva6.py --asm_tests /home/laura/cva6/verif/tests/custom/aes/aes_data_test.S --iss_yaml cva6.yaml --target cv64a6_imafdc_sv39 --iss=$DV_SIMULATORS --gcc_opts="$CC_OPTS -T ../tests/custom/common/test.ld" $DV_OPTS
# python3 cva6.py --asm_tests /home/laura/cva6/verif/tests/custom/aes/aes_repeat.S --iss_yaml cva6.yaml --target cv64a6_imafdc_sv39 --iss=$DV_SIMULATORS --gcc_opts="$CC_OPTS -T ../tests/custom/common/test.ld" $DV_OPTS
python3 cva6.py --asm_tests /home/laura/cva6/verif/tests/custom/aes/aes_round_test.S --iss_yaml cva6.yaml --target cv64a6_imafdc_sv39 --iss=$DV_SIMULATORS --gcc_opts="$CC_OPTS -T ../tests/custom/common/test.ld" $DV_OPTS



# Move back
cd -