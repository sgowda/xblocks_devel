function [] = kurtosis_origin_moments_init_xblock(blk, varargin)
%% Config
defaults = {'bit_width', 18, 'bin_pt', 17};
bit_width = get_var('bit_width', 'defaults', defaults, varargin{:});
bin_pt = get_var('bin_pt', 'defaults', defaults, varargin{:});

% Latencies
total_latency = 10;
mod_sq_latency = 5;
cplx_sq_latency = 6;

type_x = fi_dtype(1, bit_width, bin_pt);

%% Inports
sync_in = xInport('sync_in');
x_in = xInport('x_in');

%% Outports
sync_out = xOutport('sync_out');
x_re = xOutport('x_re');
x_im = xOutport('x_im');
x_sq_re = xOutport('x_sq_re');
x_sq_im = xOutport('x_sq_im');
abs_x_sq = xOutport('|x|^2');
abs_x_4th = xOutport('|x|^4');
x_3rd_re = xOutport('x_3rd_re');
x_3rd_im = xOutport('x_3rd_im');

%% Diagram

type_x = fi_dtype(1, bit_width, bin_pt);
%%% BEGIN
double_type_x = type_x^2 + type_x^2;
triple_type_x = type_x * double_type_x;
quad_type_x = double_type_x^2;

latency_mult_25x18 = 3;
latency_mult_35x25 = 5;
latency_add48 = 2;
[x_re_fi, x_im_fi] = c_to_ri('x_ri', x_in, bit_width, bin_pt);
[x_re_sq, x_re_sq_dtype] = mult('mult1', x_re_fi, x_re_fi, 'type_a', type_x, 'type_b', type_x, 'latency', latency_mult_25x18);
[x_im_sq, x_im_sq_dtype] = mult('mult2', x_im_fi, x_im_fi, 'type_a', type_x, 'type_b', type_x, 'latency', latency_mult_25x18);

[abs_x_sq_sig, abs_x_sq_dtype] = add('add1', x_re_sq, x_im_sq, 'type_a', x_re_sq_dtype, 'type_b', x_im_sq_dtype, 'latency', latency_add48);
[abs_x_4th_sig, abs_x_4th_dtype] = mult('mult3', abs_x_sq_sig, abs_x_sq_sig, 'type_a', abs_x_sq_dtype, 'type_b', abs_x_sq_dtype, 'latency', latency_mult_35x25);

[x_sq_re_sig, x_sq_re_dtype] = subtract('add2', x_re_sq, x_im_sq, 'type_a', x_re_sq_dtype, 'type_b', x_im_sq_dtype, 'latency', latency_add48);
[x_sq_im_unscaled, x_sq_im_unscaled_dtype] = mult('mult4', x_re_fi, x_im_fi, 'type_a', type_x, 'type_b', type_x, 'latency', latency_mult_25x18);
[x_sq_im_sig, x_sq_im_dtype] = scale('', x_sq_im_unscaled, 1, 'type_x', x_sq_im_unscaled_dtype, 'latency', 0);
x_sq_im_sig = trunc_and_wrap('', x_sq_im_sig, double_type_x.WordLength, double_type_x.FractionLength);

x_re_fi_del = delay_srl('', x_re_fi, latency_mult_25x18 + latency_add48);
x_im_fi_del = delay_srl('', x_im_fi, latency_mult_25x18 + latency_add48);

[x_3rd_re_sig, x_3rd_re_dtype] = mult('mult5', x_re_fi_del, abs_x_sq_sig, 'type_a', type_x, 'type_b', abs_x_sq_dtype, 'latency', latency_mult_35x25);
[x_3rd_im_sig, x_3rd_im_dtype] = mult('mult6', x_im_fi_del, abs_x_sq_sig, 'type_a', type_x, 'type_b', abs_x_sq_dtype, 'latency', latency_mult_35x25);

total_latency = latency_mult_25x18 + latency_add48 + latency_mult_35x25;
x_re_fi = delay_srl('', x_re_fi, total_latency);
x_im_fi = delay_srl('', x_im_fi, total_latency);
x_sq_re_sig = delay_srl('', x_sq_re_sig, total_latency - (latency_mult_25x18 + latency_add48));
x_sq_im_sig = delay_srl('', x_sq_im_sig, total_latency - (latency_mult_25x18));
abs_x_sq_sig = delay_srl('', abs_x_sq_sig, total_latency - (latency_mult_25x18 + latency_add48));
%%% END

sync_out.bind(delay_srl('', sync_in, total_latency));
x_re.bind(x_re_fi);
x_im.bind(x_im_fi);
x_sq_re.bind(x_sq_re_sig);
x_sq_im.bind(x_sq_im_sig);
abs_x_sq.bind(abs_x_sq_sig);
abs_x_4th.bind(abs_x_4th_sig);
x_3rd_re.bind(x_3rd_re_sig);
x_3rd_im.bind(x_3rd_im_sig);

% sync_out.bind(delay_srl('sync_delay', sync_in, total_latency));
% x_out.bind(delay_srl('x_delay', x_in, total_latency));

% x^2
% x_sq_adv = xSignal();
% cplx_sq = xBlock(struct('source', @cmult_behav_init_xblock, 'name', 'cplx_sq'), ...
%     {[], 'n_bits_a', bit_width, 'bin_pt_a', bin_pt, 'n_bits_b', bit_width, 'bin_pt_b', bin_pt, 'conjugated', 0, ...
% 	'full_precision', 1, 'cplx_inputs', 1, 'mult_latency', 3, 'add_latency', 2, 'conv_latency', 1}, ...
%     {x_in, x_in}, ...
%     {x_sq_adv});
% x_sq.bind(delay_srl('x_sq_del', x_sq_adv, total_latency - cplx_sq_latency));
% 
% % power
% abs_x_sq_adv = modulus_sq('abs_x_sq', x_in);
% abs_x_sq.bind(delay_srl('abs_x_sq_del', abs_x_sq_adv, total_latency - mod_sq_latency));
% 
% % power squared
% abs_x_4th.bind(mult('square_real', abs_x_sq_adv, abs_x_sq_adv, 'latency', total_latency-mod_sq_latency));
% 
% [x_re, x_im] = c_to_ri('c_to_ri_xin', x_in, bit_width, bin_pt);
% x_re_del = delay_srl('x_re_del', x_re, mod_sq_latency);
% x_im_del = delay_srl('x_im_del', x_im, mod_sq_latency);
% x_3rd_re = mult('third_power_re', x_re_del, abs_x_sq_adv, 'latency', total_latency-mod_sq_latency);
% x_3rd_im = mult('third_power_im', x_im_del, abs_x_sq_adv, 'latency', total_latency-mod_sq_latency);
% x_3rd.bind(ri_to_c('ri_to_c_x_3rd', x_3rd_re, x_3rd_im));
