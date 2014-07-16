#!/bin/bash

uname -m|grep 64 > /dev/null && echo $? # return 0 if true

