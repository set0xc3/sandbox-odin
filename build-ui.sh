#!/bin/sh

mkdir -p bin

odin build ui -out:bin/ui.bin -o:none -build-mode:exe -collection:my=ui -collection:shared=shared -debug -show-timings
