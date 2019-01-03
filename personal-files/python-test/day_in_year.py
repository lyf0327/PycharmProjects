#!/usr/bin/env python
# -*- coding: utf-8 -*-

year = int(raw_input('year:\n'))
month = int(raw_input('month:\n'))
day = int(raw_input('day:\n'))

months = (0,31,59,30,120,151,181,212,243,273,304,334)
if 0 < month <= 12 and 0 < day <= 31:
    sum = months[month-1]
else:
    print 'input error'
sum+=day
if ((year%400==0) or ((year%4==0) and (year%100!=0))) and (month>2):
    sum+=1
print 'it is the %dth day.' %sum

