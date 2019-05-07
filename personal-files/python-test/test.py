#!/usr/bin/python
# -*- coding:UTF-8 -*-
from sys import argv
script, filename = argv
txt=open(filename)
print txt.read()
file_again=raw_input("> ")
txg_again=open(file_again)
print txg_again.read()
txt.close()
txg_again.close()