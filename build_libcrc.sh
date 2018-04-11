#!/bin/bash
set -e
git submodule update External/src/libcrc
cd External/src/libcrc
make
cp -v lib/libcrc.a ../../$(uname -s)/lib
cp -v include/checksum.h ../../$(uname -s)/include

