#!/usr/bin/env bash

# Build from the main source file (ski.asm)
# Example To Run: ./build_and_run.sh ski
# Make sure you have in your system PATH the following directories
# ~/Gameboy/rgdbs
# ~/Gameboy/vgb


# rgbgfx (PNG‐to‐Game Boy graphics converter)

compile=$1

echo "Compile [$1]"

# rgbasm (assembler)
rgbasm -o$compile.obj $compile.asm
if [ $? -ne 0 ]; then
    echo "Problem in rgbam"
    exit 1
fi 

mv $compile.obj bin

cd bin

# rgblink (linker)
rgblink -m$compile.map -n$compile.sym -o$compile.gb $compile.obj
if [ $? -ne 0 ]; then
    echo "Problem in rgblink"
    exit 1
fi 

# rgbfix (checksum/header fixer)
rgbfix -p0 -v $compile.gb
if [ $? -ne 0 ]; then
    echo "Problem in rgbfix"
    exit 1
fi 

rm $compile.map $compile.sym $compile.obj

vba $compile.gb &

echo Complete!
exit 0