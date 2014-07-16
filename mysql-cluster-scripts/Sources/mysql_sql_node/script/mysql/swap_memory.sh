#!/bin/bash

free -b | grep Swap | awk '{print $2}'
