-----------------------------------------------------------------------------
# run_vcs.sh - compile & run the standalone multiplier AXI TB under VCS
#-----------------------------------------------------------------------------
set -e

module load verdi vcs

set SEED   = 1
set DUMP   = 1

mkdir -p "./simv_out"
cd "./simv_out"

vcs \
  -full64 \
  -sverilog \
  -timescale=1ns/1ps \
  -debug_access+all \
  -Mdir=csrc \
  -o simv \
  $(find ../source -name "*.v" -o -name "*.vh") \
  ../tb_top_pad.v \
  -l compile.log

./simv \
  +ntb_random_seed=${SEED} \
  ${DUMP:++dump} \
  -l sim.log

echo
echo "================= SUMMARY ================="
grep -E "TESTS RUN|ERRORS|TEST (PASSED|FAILED)|CHECK FAIL|WATCHDOG" sim.log || true
echo "==========================================="

if grep -q "TEST FAILED" sim.log; then
  echo "!!! FAILED !!!"
  exit 1
fi
echo "PASSED"
