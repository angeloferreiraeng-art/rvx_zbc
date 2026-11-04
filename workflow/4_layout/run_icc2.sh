#!/bin/bash
set -euo pipefail

ROOT_DIR=$(dirname "$(readlink -f "$0")")

rm -rf "$ROOT_DIR/.tmp"
rm -rf "$ROOT_DIR/../out_data/reports/pnr"/*
rm -rf "$ROOT_DIR/../out_data/post_layout"/*

TMP_DIR="$ROOT_DIR/.tmp"
SCRIPTS_DIR="$ROOT_DIR/scripts"

export ROOT_DIR

mkdir -p "$TMP_DIR"

#module load icc2
module load fusioncompiler
echo ">> Running Layout ..."
cd "$TMP_DIR"
#icc2_shell -f "$SCRIPTS_DIR/icc2_top.tcl" 2>&1 | tee -i icc2.log

#fc_shell -f new_scripts/main.tcl 
#exit

fc_shell -f "$SCRIPTS_DIR/icc2_top.tcl" 2>&1 | tee -i fusion.log
echo ">> Done!"
