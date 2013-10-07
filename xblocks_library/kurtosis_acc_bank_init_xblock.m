function [] = kurtosis_acc_bank_init_xblock(blk, varargin)
%% Config
defaults = {'bit_width', 18, 'bin_pt', 17, 'acc_len', 2^14, 'n_inputs', 1};
bit_width = get_var('bit_width', 'defaults', defaults, varargin{:});
bin_pt = get_var('bin_pt', 'defaults', defaults, varargin{:});
acc_len = get_var('acc_len', 'defaults', defaults, varargin{:});
n_inputs = get_var('n_inputs', 'defaults', defaults, varargin{:});

%% Inports
sync = xInport('sync');
if n_inputs > 1
    for k = 1:n_inputs
        x_re{k} = xInport(sprintf('x_re_%d', k));
        x_im{k} = xInport(sprintf('x_im_%d', k));
        x_sq_re{k} = xInport(sprintf('x_sq_re_%d', k));
        x_sq_im{k} = xInport(sprintf('x_sq_im_%d', k));
        abs_x_sq{k} = xInport(sprintf('abs_x_sq_%d', k));
        abs_x_4th{k} = xInport(sprintf('abs_x_4_%d', k));
        x_3rd_re{k} = xInport(sprintf('x_3rd_re_%d', k));
        x_3rd_im{k} = xInport(sprintf('x_3rd_im_%d', k));    
    end
else
    x_re = xInport('x_re');
    x_im = xInport('x_im');
    x_sq_re = xInport('x_sq_re');
    x_sq_im = xInport('x_sq_im');
    abs_x_sq = xInport('|x|^2');
    abs_x_4th = xInport('|x|^4');
    x_3rd_re = xInport('x_3rd_re');
    x_3rd_im = xInport('x_3rd_im');
end

%% Outports
sync_out       = xOutport('sync_out');
x_re_mean      = xOutport('Re{E[x]}');
x_im_mean      = xOutport('Im{E[x]}');
x_sq_re_mean   = xOutport('Re{E[x^2]}');
x_sq_im_mean   = xOutport('Im{E[x^2]}');
abs_x_sq_mean  = xOutport('E[|x|^2]');
abs_x_4th_mean = xOutport('E[|x|^4]');
x_3rd_re_mean  = xOutport('Re{E[x|x|^2]}');
x_3rd_im_mean  = xOutport('Im{E[x|x|^2]}');
channel        = xOutport('channel');


%% Diagram
x_re_acc      = xSignal();
x_im_acc      = xSignal();
x_sq_re_acc   = xSignal();
x_sq_im_acc   = xSignal();
abs_x_sq_acc  = xSignal();
abs_x_4th_acc = xSignal();
x_3rd_re_acc  = xSignal();
x_3rd_im_acc  = xSignal();

type_x = fi_dtype(1, bit_width, bin_pt);
double_type_x = type_x^2 + type_x^2;
triple_type_x = type_x * double_type_x;
quad_type_x = double_type_x^2;

single_vacc_params = {'veclen', 0, 'n_inputs', n_inputs, 'max_accum', log2(acc_len), 'arith_type', 1, 'in_bit_width', type_x.WordLength, 'in_bin_pt', type_x.FractionLength, 'use_dsp48', 1, 'serialize_output_streams', 1};
double_vacc_params = {'veclen', 0, 'n_inputs', n_inputs, 'max_accum', log2(acc_len), 'arith_type', 1, 'in_bit_width', double_type_x.WordLength, 'in_bin_pt', double_type_x.FractionLength, 'use_dsp48', 1, 'serialize_output_streams', 1};
triple_vacc_params = {'veclen', 0, 'n_inputs', n_inputs, 'max_accum', log2(acc_len), 'arith_type', 1, 'in_bit_width', triple_type_x.WordLength, 'in_bin_pt', triple_type_x.FractionLength, 'use_dsp48', 1, 'serialize_output_streams', 1};
quad_vacc_params = {'veclen', 0, 'n_inputs', n_inputs, 'max_accum', log2(acc_len), 'arith_type', 1, 'in_bit_width', quad_type_x.WordLength, 'in_bin_pt', quad_type_x.FractionLength, 'use_dsp48', 1, 'serialize_output_streams', 1};

acc_len_sig = const('acc_len', acc_len-1, fi_dtype(0,32,0));

channel_0 = xSignal();
x_re_acc_0 = xSignal();
x_im_acc_0 = xSignal();
x_sq_re_acc_0 = xSignal();
x_sq_im_acc_0 = xSignal();
abs_x_sq_acc_0 = xSignal();
sync_out_48bit = xSignal();

% E[x] accumulator
xBlock(struct('name', 'x_re_acc', 'source', @vacc_init_xblock), {[blk, '/x_re_acc'], single_vacc_params{:}}, {sync, acc_len_sig, x_re{:}}, {sync_out_48bit, x_re_acc_0, channel_0});
xBlock(struct('name', 'x_im_acc', 'source', @vacc_init_xblock), {[blk, '/x_im_acc'], single_vacc_params{:}}, {sync, acc_len_sig, x_im{:}}, {[], x_im_acc_0});

% E[x^2] accumulator
xBlock(struct('name', 'x_sq_re_acc', 'source', @vacc_init_xblock), {[blk, '/x_sq_re_acc'], double_vacc_params{:}}, {sync, acc_len_sig, x_sq_re{:}}, {[], x_sq_re_acc_0});
xBlock(struct('name', 'x_sq_im_acc', 'source', @vacc_init_xblock), {[blk, '/x_sq_im_acc'], double_vacc_params{:}}, {sync, acc_len_sig, x_sq_im{:}}, {[], x_sq_im_acc_0});

% E[x|x|^2] accmulator
xBlock(struct('name', 'x_3rd_re_acc', 'source', @vacc_init_xblock), {[blk, '/x_3rd_re_acc'], triple_vacc_params{:}}, {sync, acc_len_sig, x_3rd_re{:}}, {[], x_3rd_re_acc});
xBlock(struct('name', 'x_3rd_im_acc', 'source', @vacc_init_xblock), {[blk, '/x_3rd_im_acc'], triple_vacc_params{:}}, {sync, acc_len_sig, x_3rd_im{:}}, {[], x_3rd_im_acc});

% E[|x|^2] accmulator
xBlock(struct('name', 'abs_x_sq_acc', 'source', @vacc_init_xblock), {[blk, '/abs_x_sq_acc'], double_vacc_params{:}}, {sync, acc_len_sig, abs_x_sq{:}}, {[], abs_x_sq_acc_0});

% E[|x|^4] accmulator
xBlock(struct('name', 'abs_x_4th_acc', 'source', @vacc_init_xblock), {[blk, '/abs_x_4th_acc'], quad_vacc_params{:}}, {sync, acc_len_sig, abs_x_4th{:}}, {[], abs_x_4th_acc});

% match latencies between 96-bit accumulators and 48-bit
sync_out.bind(delay_srl('', sync_out_48bit, 1));
channel.bind(delay_srl('', channel_0, 1));

x_re_acc     = delay_srl('', x_re_acc_0, 1);
x_im_acc     = delay_srl('', x_im_acc_0, 1);
x_sq_re_acc  = delay_srl('', x_sq_re_acc_0, 1);
x_sq_im_acc  = delay_srl('', x_sq_im_acc_0, 1);
abs_x_sq_acc = delay_srl('', abs_x_sq_acc_0, 1);

% calculate means
x_re_mean.bind(scale('', x_re_acc     , -log2(acc_len)));
x_im_mean.bind(scale('', x_im_acc     , -log2(acc_len))); 
x_sq_re_mean.bind(scale('', x_sq_re_acc  , -log2(acc_len))); 
x_sq_im_mean.bind(scale('', x_sq_im_acc  , -log2(acc_len))); 
abs_x_sq_mean.bind(scale('', abs_x_sq_acc , -log2(acc_len))); 
abs_x_4th_mean.bind(scale('', abs_x_4th_acc, -log2(acc_len))); 
x_3rd_re_mean.bind(scale('', x_3rd_re_acc , -log2(acc_len))); 
x_3rd_im_mean.bind(scale('', x_3rd_im_acc , -log2(acc_len))); 


%%%%% old

% Reset logic for the accmulators
% acc_rst = xSignal('acc_rst');
% xBlock(struct('name', 'acc_rst', 'source', @acc_rst_init_xblock), ...
%     {subblockname(blk, 'acc_rst'), 'acc_len', acc_len}, {sync}, {acc_rst, sync_out});

% xBlock(struct('name', 'x_acc', 'source', @cplx_acc_96bit_dsp48e_init_xblock), ...
%     {[blk, '/x_acc'], 'bit_width', bit_width, 'bin_pt', bin_pt}, {acc_rst, x}, {x_re_acc, x_im_acc});
% 
% % E[x^2] accumulator
% xBlock(struct('name', 'x_sq_acc', 'source', @cplx_acc_96bit_dsp48e_init_xblock), ...
%     {[blk, '/x_acc'], 'bit_width', bit_width*2+1, 'bin_pt', bin_pt*2}, {acc_rst, x_sq}, {x_sq_re_acc, x_sq_im_acc});
% 
% % E[x|x|^2] accmulator
% xBlock(struct('name', 'x_cube_acc', 'source', @cplx_acc_96bit_dsp48e_init_xblock), ...
%     {[blk, '/x_acc'], 'bit_width', bit_width*3+1, 'bin_pt', bin_pt*3}, {acc_rst, x_cube}, {x_cube_re_acc, x_cube_im_acc});
% 
% % E[|x|^2] accmulator
% xBlock(struct('name', 'abs_x_sq_acc', 'source', @acc_96bit_dsp48e_init_xblock), ...
%     {[blk, '/x_acc'], 'bit_width', bit_width*2+1, 'bin_pt', bin_pt*2}, {acc_rst, abs_x_sq}, {abs_x_sq_acc});
% 
% % E[|x|^2] accmulator
% xBlock(struct('name', 'abs_x_4th_acc', 'source', @acc_96bit_dsp48e_init_xblock), ...
%     {[blk, '/x_acc'], 'bit_width', (bit_width*2+1)*2, 'bin_pt', bin_pt*4}, {acc_rst, abs_x_4th}, {abs_x_4th_acc});
