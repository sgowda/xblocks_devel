function kurtosis_cross_products_init_xblock(blk, varargin)
defaults = {'acc_len', 14, 'total_latency', 25, 'type_x', fi_dtype(1,18,17)};
acc_len = get_var('acc_len', 'defaults', defaults, varargin{:});
type_x = get_var('type_x', 'defaults', defaults, varargin{:});
total_latency = get_var('total_latency', 'defaults', defaults, varargin{:});
% [m_x_dtype, x_sq_dtype, x_3_dtype, x_4th_type] = kurtosis_acc_rounding_types(type_x, acc_len);
% [m_x_dtype, x_sq_dtype, x_3_dtype, x_4th_dtype] = kurtosis_mean_types(type_x, acc_len);
logging = 0; % HACK
%% inports
sync = xInport('sync');
x_mean_re = xInport('Re{E[X]}');
x_mean_im = xInport('Im{E[X]}');
x_sq_mean_re = xInport('Re{E[X^2]}');
x_sq_mean_im = xInport('Im{E[X^2]}');
abs_x_sq_mean = xInport('E[|X|^2]');
abs_x_4th_mean = xInport('E[||X||^4]');
x_3rd_mean_re = xInport('Re{E[|X|^2X]}');
x_3rd_mean_im = xInport('Im{E[|X|^2X]}');

%% outports
sync_out = xOutport('sync_out');
d = xOutport('d');
f = xOutport('f');
a = xOutport('a');
c = xOutport('c');
b = xOutport('b');
g = xOutport('|m_x|^2');
e = xOutport('e');
h = xOutport('|E[(x-mx)^2]|^2');

%% diagram
%%% Begin
mult_latency_35x25 = 4;
mult_latency_42x35 = 6;
add_latency_96bit = 3;
add_latency_48bit = 2;
conv_latency_96bit = 3;
conv_latency_48bit = 3;


round_in1_latency = conv_latency_48bit;
round_in2_latency = conv_latency_48bit;


round_in6_latency = conv_latency_96bit;
round_in7_latency = conv_latency_96bit;
mult1_latency = mult_latency_35x25;
mult2_latency = mult_latency_35x25;
add1_latency = add_latency_48bit;
mult3_latency = mult_latency_35x25;
round1_latency = conv_latency_48bit;

mult4_latency = mult_latency_35x25;
mult5_latency = mult_latency_35x25;
add3_latency = add_latency_96bit;
mult6_latency = mult_latency_35x25;
mult7_latency = mult_latency_35x25;
add4_latency = add_latency_96bit;
add2_latency = add_latency_48bit;
conv_25bit_latency = conv_latency_96bit;
conv_35bit_latency = conv_latency_96bit;
mult8_latency = mult_latency_35x25;
round3_latency = conv_latency_96bit;

mult11_latency = mult_latency_35x25;
round4_latency = conv_latency_96bit;

cplx_sub_latency = add_latency_48bit;
mult9_latency = mult_latency_42x35;
mult10_latency = mult_latency_42x35;
add5_latency = add_latency_96bit;

%-- special latencies (matching required)
round_in5_latency = round3_latency + add1_latency + mult1_latency + round_in1_latency;
round2_latency = conv_latency_48bit + add1_latency;
round5_latency = conv_latency_96bit + add1_latency;
round_in3_latency = conv_latency_48bit + mult_latency_35x25 + add_latency_48bit + conv_latency_48bit;
round_in4_latency = round_in3_latency;

a_total_del = 0;
b_total_del = add4_latency + mult6_latency + round_in1_latency;
c_total_del = add3_latency + round_in3_latency + mult_latency_35x25;
d_total_del = mult11_latency + round_in5_latency;
e_total_del = round_in2_latency + mult8_latency + conv_25bit_latency + add2_latency + mult1_latency;
f_total_del = e_total_del;
g_total_del = round_in1_latency + add2_latency + mult1_latency;
h_total_del = add5_latency + mult9_latency + cplx_sub_latency + round_in3_latency;
% total_latency = max([a_total_del, b_total_del, c_total_del, d_total_del, e_total_del, f_total_del, g_total_del, h_total_del]);

[m_x_dtype, x_sq_dtype, x_3rd_dtype, x_4th_dtype] = kurtosis_mean_types(type_x, acc_len);

[x_mean_re, x_mean_re_dtype]         = round_to_wordlength('round_in1', x_mean_re, 25, m_x_dtype, 'logging', logging, 'latency', round_in1_latency);
[x_mean_im, x_mean_im_dtype]         = round_to_wordlength('round_in2', x_mean_im, 25, m_x_dtype, 'logging', logging, 'latency', round_in2_latency);
[x_sq_mean_re, x_sq_mean_re_dtype ]  = round_to_wordlength('round_in3', x_sq_mean_re, 35, x_sq_dtype, 'logging', logging, 'latency', round_in3_latency);
[x_sq_mean_im, x_sq_mean_im_dtype ]  = round_to_wordlength('round_in4', x_sq_mean_im, 35, x_sq_dtype, 'logging', logging, 'latency', round_in4_latency);
[abs_x_sq_mean, abs_x_sq_mean_dtype] = round_to_wordlength('round_in5', abs_x_sq_mean, 35, x_sq_dtype, 'logging', logging, 'latency', round_in5_latency);
[x_3rd_mean_re, x_3rd_mean_re_dtype] = round_to_wordlength('round_in6', x_3rd_mean_re, 35, x_3rd_dtype, 'logging', logging, 'latency', round_in6_latency);
[x_3rd_mean_im, x_3rd_mean_im_dtype] = round_to_wordlength('round_in7', x_3rd_mean_im, 35, x_3rd_dtype, 'logging', logging, 'latency', round_in7_latency);

[x_mean_re_sq, x_mean_re_sq_dtype] = mult('mult1', x_mean_re, x_mean_re, 'latency', mult1_latency, 'type_a', m_x_dtype, 'type_b', m_x_dtype);
[x_mean_im_sq, x_mean_im_sq_dtype] = mult('mult2', x_mean_im, x_mean_im, 'latency', mult2_latency, 'type_a', m_x_dtype, 'type_b', m_x_dtype);
[mx_sq_re, mx_sq_re_dtype] = subtract('add1', x_mean_re_sq, x_mean_im_sq, 'latency', add1_latency, 'type_a', x_mean_re_sq_dtype, 'type_b', x_mean_im_sq_dtype);
[mx_re_times_mx_im, mx_re_times_mx_im_dtype] = mult('mult3', x_mean_re, x_mean_im, 'latency', mult3_latency, 'type_a', m_x_dtype, 'type_b', m_x_dtype);
[mx_sq_im, mx_sq_im_dtype] = scale('scale_mx_sq', mx_re_times_mx_im, 1, 'type_x', mx_re_times_mx_im_dtype);

[mx_sq_re_rounded, mx_sq_re_rounded_dtype] = round_to_wordlength('round1', mx_sq_re, 25, mx_sq_re_dtype, 'logging', logging, 'latency', round1_latency);
[mx_sq_im_rounded, mx_sq_im_rounded_dtype] = round_to_wordlength('round2', mx_sq_im, 25, mx_sq_im_dtype, 'logging', logging, 'latency', round2_latency);

[alpha, alpha_dtype] = mult('mult4', x_sq_mean_re, mx_sq_re_rounded, 'latency', mult4_latency, 'type_a', x_sq_dtype, 'type_b', mx_sq_re_rounded_dtype);
[beta, beta_dtype] = mult('mult5', x_sq_mean_im, mx_sq_im_rounded, 'latency', mult5_latency, 'type_a', x_sq_dtype, 'type_b', mx_sq_im_rounded_dtype);
[c_unscaled, c_unscaled_dtype] = add('add3', alpha, beta, 'latency', add3_latency, 'type_a', alpha_dtype, 'type_b', beta_dtype);
[c_sig, c_dtype] = scale('Scale1', c_unscaled, 1, 'type_x', c_unscaled_dtype);

[gamma, gamma_dtype] = mult('mult6', x_3rd_mean_re, x_mean_re, 'latency', mult6_latency, 'type_a', x_3rd_dtype, 'type_b', m_x_dtype);
[delta, delta_dtype] = mult('mult7', x_3rd_mean_im, x_mean_im, 'latency', mult7_latency, 'type_a', x_3rd_dtype, 'type_b', m_x_dtype);
[b_unscaled, b_unscaled_dtype] = add('add4', gamma, delta, 'latency', add4_latency, 'type_a', gamma_dtype, 'type_b', delta_dtype);
[b_sig, b_dtype] = scale('Scale', b_unscaled, 2, 'type_x', b_unscaled_dtype);

[abs_m_x_sq, abs_m_x_sq_dtype] = add('add2', x_mean_re_sq, x_mean_im_sq, 'latency', add2_latency, 'type_a', x_mean_re_sq_dtype, 'type_b', x_mean_im_sq_dtype);
[abs_m_x_sq_25bit, abs_m_x_sq_25bit_dtype] = round_to_wordlength('conv_25bit', abs_m_x_sq, 25, abs_m_x_sq_dtype, 'latency', conv_25bit_latency, 'logging', logging);
[abs_m_x_sq_35bit, abs_m_x_sq_35bit_dtype] = round_to_wordlength('conv_35bit', abs_m_x_sq, 35, abs_m_x_sq_dtype, 'latency', conv_35bit_latency, 'logging', logging);
[e_sig, e_dtype] = mult('mult8', abs_m_x_sq_25bit, abs_m_x_sq_35bit, 'latency', mult8_latency, 'type_a', abs_m_x_sq_25bit_dtype, 'type_b', abs_m_x_sq_35bit_dtype);
[f_sig, f_dtype] = scale('Scale4', e_sig, 2, 'type_x', e_dtype);

[abs_m_x_sq_rounded, abs_m_x_sq_rounded_dtype] = round_to_wordlength('round3', abs_m_x_sq, 25, abs_m_x_sq_dtype, 'latency', round3_latency, 'logging', logging); 
% abs_x_sq_mean_del = delay_srl('del1', abs_x_sq_mean, abs_x_sq_mean_input_latency);
[d_unscaled, d_unscaled_dtype] = mult('mult11',  abs_m_x_sq_rounded, abs_x_sq_mean, 'latency', mult11_latency, 'type_b', x_sq_dtype, 'type_a', abs_m_x_sq_rounded_dtype);
[d_sig, d_dtype] = scale('Scale3', d_unscaled, 2, 'type_x', d_unscaled_dtype);

% third term in complex kurtosis
[mx_sq_re_rounded_mb, mx_sq_re_rounded_mb_dtype] = round_to_wordlength('round4', mx_sq_re, 35, mx_sq_re_dtype, 'latency', round4_latency, 'logging', logging);
[mx_sq_im_rounded_mb, mx_sq_im_rounded_mb_dtype] = round_to_wordlength('round5', mx_sq_im, 35, mx_sq_im_dtype, 'latency', round5_latency, 'logging', logging);
[abs_mean_x_re, abs_mean_x_im, abs_mean_x_dtype] = cplx_sub('cplx_sub', {x_sq_mean_re, x_sq_mean_im}, ...
    {mx_sq_re_rounded_mb, mx_sq_im_rounded_mb}, 'latency', cplx_sub_latency, 'full_precision', 1, 'type_a', x_sq_mean_re_dtype, 'type_b', mx_sq_im_rounded_mb_dtype);
[abs_mean_x_re_sq, abs_mean_x_re_sq_dtype] = mult('mult9', abs_mean_x_re, abs_mean_x_re, 'latency', mult9_latency, 'type_a', abs_mean_x_dtype, 'type_b', abs_mean_x_dtype);
[abs_mean_x_im_sq, abs_mean_x_im_sq_dtype] = mult('mult10', abs_mean_x_im, abs_mean_x_im, 'latency', mult10_latency, 'type_a', abs_mean_x_dtype, 'type_b', abs_mean_x_dtype);
[h_sig, h_dtype] = add('add5', abs_mean_x_re_sq, abs_mean_x_im_sq, 'latency', add5_latency, 'type_a', abs_mean_x_re_sq_dtype, 'type_b', abs_mean_x_im_sq_dtype);

a_sig = delay_srl('a_del', abs_x_4th_mean, total_latency);
b_sig = delay_srl('b_del', b_sig, total_latency - b_total_del);
c_sig = delay_srl('c_del', c_sig, total_latency - c_total_del);
d_sig = delay_srl('d_del', d_sig, total_latency - d_total_del);
e_sig = delay_srl('e_del', e_sig, total_latency - e_total_del);
f_sig = delay_srl('f_del', f_sig, total_latency - f_total_del);
g_sig = delay_srl('g_del', abs_m_x_sq, total_latency - g_total_del);
h_sig = delay_srl('h_del', h_sig, total_latency - h_total_del);
%%% End
%% Output port binding
sync_out.bind(delay_srl('sync_del', sync, total_latency));
a.bind(a_sig);
b.bind(b_sig);
c.bind(c_sig);
d.bind(d_sig);
e.bind(e_sig);
f.bind(f_sig);
g.bind(g_sig);
h.bind(h_sig);
end
