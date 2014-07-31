#!/bin/bash

free -b | grep Mem | awk '{print $2}'
