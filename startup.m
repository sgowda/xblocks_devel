
homedir = getenv('HOME');
xblocks_lib_path = 'lib/xblocks_devel/xblocks_library';
addpath(fullfile(homedir, 'lib/mlib_devel/casper_library'))
addpath(fullfile(homedir, 'lib/mlib_devel/xps_library'))
addpath(fullfile(homedir, xblocks_lib_path))
addpath(fullfile(homedir, xblocks_lib_path, 'Testing'))
addpath(fullfile(homedir, xblocks_lib_path, 'Testing/util'))
addpath(fullfile(homedir, xblocks_lib_path, 'matlab_data_xfer'))
addpath(fullfile(homedir, xblocks_lib_path, 'dsp48e_util_lib'))
addpath(fullfile(homedir, xblocks_lib_path, 'fixed_point_dsp'))
addpath(fullfile(homedir, xblocks_lib_path, 'scripting'))
addpath(fullfile(homedir, xblocks_lib_path, 'automation'))
addpath(fullfile(homedir, xblocks_lib_path, 'gen_test_signals'))

cd /nas/users/sgowda/designs/
