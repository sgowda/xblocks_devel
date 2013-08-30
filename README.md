xblocks_devel
=============
This library contains scripting functions for building fixed-point DSP 
for Xilinx FPGAs using the XSG (Xilinx System Generator) tool, associated 
functional implementations of those blocks using MATLAB's fixed-point libraries,
and testing infrastructure for verification that the blocks work.

Configuring MATLAB
==================
Add the following lines (or similar) to your MATLAB startup.m file:

homedir = getenv('HOME');
xblocks_lib_path = 'lib/xblocks_devel/xblocks_library';
addpath(fullfile(homedir, xblocks_lib_path))
addpath(fullfile(homedir, xblocks_lib_path, 'Testing'))
addpath(fullfile(homedir, xblocks_lib_path, 'Testing/util'))
addpath(fullfile(homedir, xblocks_lib_path, 'matlab_data_xfer'))
addpath(fullfile(homedir, xblocks_lib_path, 'dsp48e_util_lib'))
addpath(fullfile(homedir, xblocks_lib_path, 'fixed_point_dsp'))
addpath(fullfile(homedir, xblocks_lib_path, 'scripting'))
addpath(fullfile(homedir, xblocks_lib_path, 'automation'))
addpath(fullfile(homedir, xblocks_lib_path, 'gen_test_signals'))

where xblocks_lib_path should change depending on where 
