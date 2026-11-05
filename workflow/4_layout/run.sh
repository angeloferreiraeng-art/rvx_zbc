#!/bin/bash
set -euo pipefail

ROOT_DIR=$(dirname "$(readlink -f "$0")")

WORKING_DIR=$PWD
rm $WORKING_DIR/*.svf
#rm -rf "$ROOT_DIR/.tmp"
#rm -rf "$ROOT_DIR/../out_data/reports/pnr"/*
#rm -rf "$ROOT_DIR/../out_data/post_layout"/*

module load fusioncompiler

fc_shell -f new_scripts/main.tcl 

