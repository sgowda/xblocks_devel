function xblock_obj = cplx_acc_96bit_dsp48e_init_xblock(blk, varargin)
defaults = {'bit_width', 18, 'bin_pt', 17};
bin_pt = get_var('bin_pt', 'defaults', defaults, varargin{:});
bit_width = get_var('bit_width', 'defaults', defaults, varargin{:});

%% inports
sync = xInport('sync');
x = xInport('x');

%% outports
x_re_acc = xOutport('x_re_acc');
x_im_acc = xOutport('x_im_acc');

%% diagram

x_re = xSignal('x_re');
x_im = xSignal('x_im');

% complex to real splitter
xBlock(struct('name', 'c_to_ri', 'source', str2func('c_to_ri_init_xblock')), ...
    {[blk, '/c_to_ri'], bit_width, bin_pt}, {x}, {x_re, x_im});

% real accumulator
xBlock(struct('name', 're_acc', 'source', str2func('acc_96bit_dsp48e_init_xblock')), ...
    {[blk, '/re_acc'], 'bin_pt', bin_pt}, {sync, x_re}, {x_re_acc});

% imag accumulator
xBlock(struct('name', 'im_acc', 'source', str2func('acc_96bit_dsp48e_init_xblock')), ...
    {[blk, '/im_acc'], 'bin_pt', bin_pt}, {sync, x_im}, {x_im_acc});

end