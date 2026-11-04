#!/bin/sh
ROOT_DIR=$(dirname "$(readlink -f "$0")")

echo ">> Cleaning ..."

rm -rf "$ROOT_DIR/.tmp"
rm -rf "$ROOT_DIR/../out_data/reports/pnr"/*
rm -rf "$ROOT_DIR/../out_data/post_layout"/*

echo ">> Done!"
