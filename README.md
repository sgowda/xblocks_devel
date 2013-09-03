xblocks_devel
=============
This library contains scripting functions for building fixed-point DSP 
for Xilinx FPGAs using the XSG (Xilinx System Generator) tool, associated 
functional implementations of those blocks using MATLAB's fixed-point libraries,
and testing infrastructure for verification that the blocks work.

Configuring MATLAB & Simulink
=============================
Add the following lines (or similar) to your MATLAB startup.m file:

```code
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
```
where xblocks_lib_path should change depending on where you've checked out
the repository. An example file appears in
```code xblocks_library/startup.m```

To speed block drawing and avoid pointless scolling, Simulink provides 
a way to customize the ordering of the blocks and various other features
of the library browser.  To make all the relevant libraries appear in a useful
order,
```code
ln -s $HOME/lib/xblocks_library/sl_customization.m $HOME/Documents/MATLAB/sl_customization.m
```

Creating new blocks
===================
All blocks in this library are created with the xBlocks scripting functions 
(see https://casper.berkeley.edu/wiki/XBlock_Scripting) for an overview of how these scripting
functions can be used to draw blocks.  This has certain advantages and disadvantages over the
standard simulink drawing methods.  Primarily, the tradeoff is that drawing takes a bit longer 
than the standard CASPER library methods of block-drawing, as there is some redundancy, 
but after this cost is paid, your block becomes library version independent.  In addition, because
the library blocks are now fully text-based, they can actually be version controlled. The value of this
tradeoff is debatable and ultimately comes down to personal preference. 

To aid in the creation of new blocks, the functions disp_params.m and get_mask_config.m have
been added to ```code xblocks_library/scripting/```.  These functions display print the current
parameters of a block (in the case of the second function, just the Mask parameters).  These can be
useful because while scripting blocks, it can be quite annoying to determine the parameter *names* that
need to be set as there is no master-list of parameter names. 

Block generator functions
=========================
The xBlock interface, while purely text, can be a bit clunky. To combat this, as well as improve the
compactness of the block definitions, this library includes a set of functions that we are calling 
'block generator functions'.  The idea here is that 

Testing infrastructure
======================
Testbenches for this library are handled primarily through MATLAB functional 
validation. Simulation data is generated by MATLAB, transferred to the Simulink model
for simulation, and the results are dumped back to MATLAB for validation. The 
(poorly named) simulink_xsg_bridge library contains a set of blocks that transfer MATLAB
variables, both real and complex, to their respective Xilinx-compatible data types, 
as well as a set of blocks to transfer data from Simulink to MATLAB data types. 

All test cases are stored in subdirectories of 
```code
addpath(fullfile(homedir, xblocks_lib_path, 'Testing'))
```

New testbenches should be created by:

1. ```code mkdir testing/blktype/subblkname; cd testing/blktype/subblkname``` where 'blktype'  is a categorization for the block (e.g. fft, vacc, binary_signal, etc.) and subblkname is the name of the actual block being tested, i.e. the init script would be named <subblkname>_init_xblock.m

2. Call the function create_tb.m, which should be on the path if startup.m was properly set.  This will create 2 files, a testbench script file and a simulnk model file. 

3. From the Simulink library browser, pull appropriate blocks from the 'MATLAB data xfer' library, which has been configured to be the browser name  for the simulink_xsg_bridge library file if you followed the step for the sl_customization.m file above.
