#!/usr/bin/python
# -*- coding:UTF-8 -*-
for n in range(100,999):
    x = n / 100
    y = n / 10 % 10
    z = n % 10
    if n == x ** 3 +y ** 3 +z ** 3:
        print n