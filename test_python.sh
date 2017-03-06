#!/bin/bash

# test the python interface, see if everything works

# get to the test directory
cd /root/znn-release/python

# test affinity training patch, network initialization, network with even field of view
python3 train.py -c ../testsuit/affinity/config.cfg -d single -k yes
# test boundary map training, patch matching, network initialization
python3 train.py -c ../testsuit/boundary/config.cfg -d single -k yes
# second check to test the network loading
python3 train.py -c ../testsuit/boundary/config.cfg -d single -k yes
# check the double precision
# compile the core with double precision
cd core; make double -j 4
# return to `python`
cd ..
python3 train.py -c ../testsuit/boundary/config.cfg -d double -k yes
# test forward pass
python3 forward.py -c ../testsuit/forward/config.cfg
# return to root directory
cd ..