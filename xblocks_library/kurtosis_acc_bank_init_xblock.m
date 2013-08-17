function [] = kurtosis_acc_bank_init_xblock(blk, varargin)
%% Config
defaults = {'bit_width', 18, 'bin_pt', 17, 'acc_len', 2^14};
bit_width = get_var('bit_width', 'defaults', defaults, varargin{:});
bin_pt = get_var('bin_pt', 'defaults', defaults, varargin{:});
acc_len = get_var('acc_len', 'defaults', defaults, varargin{:});

%% Inports
sync = xInport('sync');
x = xInport('x');
x_sq = xInport('x^2');
abs_x_sq = xInport('|x|^2');
abs_x_4th = xInport('|x|^4');
x_cube = xInport('x|x|^2');

%% Outports
sync_out = xOutport('sync_out');
x_re_acc = xOutport('Re{E[x]}');
x_im_acc = xOutport('Im{E[x]}');
x_sq_re_acc = xOutport('Re{E[x^2]}');
x_sq_im_acc = xOutport('Im{E[x^2]}');
abs_x_sq_acc = xOutport('E[|x|^2]');
abs_x_4th_acc = xOutport('E[|x|^4]');
x_cube_re_acc = xOutport('Re{E[x|x|^2]}');
x_cube_im_acc = xOutport('Im{E[x|x|^2]}');

%% Diagram

% Reset logic for the accmulators
acc_rst = xSignal('acc_rst');
xBlock(struct('name', 'acc_rst', 'source', @acc_rst_init_xblock), ...
    {subblockname(blk, 'acc_rst'), 'acc_len', acc_len}, {sync}, {acc_rst, sync_out});

% E[x] accumulator
xBlock(struct('name', 'x_acc', 'source', @cplx_acc_96bit_dsp48e_init_xblock), ...
    {[blk, '/x_acc'], 'bit_width', bit_width, 'bin_pt', bin_pt}, {acc_rst, x}, {x_re_acc, x_im_acc});

% E[x^2] accumulator
xBlock(struct('name', 'x_sq_acc', 'source', @cplx_acc_96bit_dsp48e_init_xblock), ...
    {[blk, '/x_acc'], 'bit_width', bit_width*2+1, 'bin_pt', bin_pt*2}, {acc_rst, x_sq}, {x_sq_re_acc, x_sq_im_acc});

% E[x|x|^2] accmulator
xBlock(struct('name', 'x_cube_acc', 'source', @cplx_acc_96bit_dsp48e_init_xblock), ...
    {[blk, '/x_acc'], 'bit_width', bit_width*3+1, 'bin_pt', bin_pt*3}, {acc_rst, x_cube}, {x_cube_re_acc, x_cube_im_acc});

% E[|x|^2] accmulator
xBlock(struct('name', 'abs_x_sq_acc', 'source', @acc_96bit_dsp48e_init_xblock), ...
    {[blk, '/x_acc'], 'bit_width', bit_width*2+1, 'bin_pt', bin_pt*2}, {acc_rst, abs_x_sq}, {abs_x_sq_acc});

% E[|x|^2] accmulator
xBlock(struct('name', 'abs_x_4th_acc', 'source', @acc_96bit_dsp48e_init_xblock), ...
    {[blk, '/x_acc'], 'bit_width', (bit_width*2+1)*2, 'bin_pt', bin_pt*4}, {acc_rst, abs_x_4th}, {abs_x_4th_acc});