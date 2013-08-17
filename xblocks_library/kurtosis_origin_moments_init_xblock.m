function [] = kurtosis_origin_moments_init_xblock(blk, varargin)
%% Config
defaults = {};
bit_width = 18;
bin_pt = 17;

% Latencies
total_latency = 10;
mod_sq_latency = 5;
cplx_sq_latency = 6;

%% Inports
sync_in = xInport('sync_in');
x_in = xInport('x_in');

%% Outports
sync_out = xOutport('sync_out');
x_out = xOutport('x');
x_sq = xOutport('x^2');
abs_x_sq = xOutport('|x|^2');
abs_x_4th = xOutport('|x|^4');
x_3rd = xOutport('x|x|^2');

%% Diagram
sync_out.bind(delay_srl('sync_delay', sync_in, total_latency));

x_out.bind(delay_srl('x_delay', x_in, total_latency));

% x^2
x_sq_adv = xSignal();
cplx_sq = xBlock(struct('source', @cmult_behav_init_xblock2, 'name', 'cplx_sq'), ...
    {[], 'n_bits_a', bit_width, 'bin_pt_a', bin_pt, 'n_bits_b', bit_width, 'bin_pt_b', bin_pt, 'conjugated', 0, ...
	'full_precision', 1, 'cplx_inputs', 1, 'mult_latency', 3, 'add_latency', 2, 'conv_latency', 1}, ...
    {x_in, x_in}, ...
    {x_sq_adv});
x_sq.bind(delay_srl('x_sq_del', x_sq_adv, total_latency - cplx_sq_latency));

% power
abs_x_sq_adv = modulus_sq('abs_x_sq', x_in);
abs_x_sq.bind(delay_srl('abs_x_sq_del', abs_x_sq_adv, total_latency - mod_sq_latency));

% power squared
abs_x_4th.bind(mult('square_real', abs_x_sq_adv, abs_x_sq_adv, 'latency', total_latency-mod_sq_latency));

[x_re, x_im] = c_to_ri('c_to_ri_xin', x_in, bit_width, bin_pt);
x_re_del = delay_srl('x_re_del', x_re, mod_sq_latency);
x_im_del = delay_srl('x_im_del', x_im, mod_sq_latency);
x_3rd_re = mult('third_power_re', x_re_del, abs_x_sq_adv, 'latency', total_latency-mod_sq_latency);
x_3rd_im = mult('third_power_im', x_im_del, abs_x_sq_adv, 'latency', total_latency-mod_sq_latency);
x_3rd.bind(ri_to_c('ri_to_c_x_3rd', x_3rd_re, x_3rd_im));
