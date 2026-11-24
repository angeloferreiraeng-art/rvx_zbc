set -e
echo $PWD
export STAGING_PATH="$PWD/garbage"
export OUTPUT_PATH="$PWD/output2"

rm -rf "$STAGING_PATH"/*|| true
rm -rf "$OUTPUT_PATH"/*|| true


cd garbage

module load fusioncompiler
fc_shell -f ../physical/main.tcl
echo "FINISHED PHYSICAL SYNTHESIS"


