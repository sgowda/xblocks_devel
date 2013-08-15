function kurtosis_moment_calc_init_xblock(blk, varargin)
defaults = {'acc_len', 14, 'type_x', fi_dtype(1, 18, 17)};
acc_len = get_var('acc_len', 'defaults', defaults, varargin{:});
type_x = get_var('type_x', 'defaults', defaults, varargin{:});
[m_x_type, x_sq_type, x_3rd_type, x_4th_type] = acc_rounding_types(type_x, acc_len);
bit_width_power = 32;

%% inports
sync = xInport('sync');
channel_in = xInport('channel_in');
m_x_re = xInport('Re{E[X]}');
m_x_im = xInport('Im{E[X]}');
X_sq_acc_re = xInport('Re{E[X^2]}');
X_sq_acc_im = xInport('Im{E[X^2]}');
abs_X_sq_acc = xInport('E[|X|^2]');
abs_X_4th_acc = xInport('E[||X||^4]');
X_3rd_acc_re = xInport('Re{E[|X|^2X]}');
X_3rd_acc_im = xInport('Im{E[|X|^2X]}');

%% outports
sync_out = xOutport('sync_out');
channel_out = xOutport('channel');
num = xOutport('num');
den = xOutport('den');
abs_X_sq_mean = xOutport('power');

%% diagram
add_latency_96bit = 4;
cross_product_latency = 15;
adder_tree_latency = add_latency_96bit * 3;
abs_X_sq_acc_del = delay_srl('cross_product_del', abs_X_sq_acc, cross_product_latency);

% TODO
abs_X_sq_acc_del2 = round_to_wordlength('adder_tree_del', abs_X_sq_acc_del, bit_width_power, x_sq_type);
% abs_X_sq_acc_del2 = round_inf_and_saturate('adder_tree_del', abs_X_sq_acc_del, ...
%     32, 19, 'latency', adder_tree_latency);
abs_X_sq_mean.bind(scale('scale', abs_X_sq_acc_del2, -acc_len)); % TODO fix this!
cross_prod_sync_out = xSignal('sync_out');
d = xSignal();
f = xSignal();
a = xSignal();
c = xSignal();
b = xSignal();
abs_mx_sq = xSignal();
e = xSignal();
h = xSignal();

kurtosis_cross_products_sub = xBlock(struct('source', @kurtosis_cross_products, 'name', 'kurtosis_cross_products'), ...
    {subblockname(blk, 'kurtosis_cross_products'), 'acc_len', acc_len, 'total_latency', cross_product_latency, 'type_x', type_x}, ...
    {sync, m_x_re, m_x_im, X_sq_acc_re, X_sq_acc_im, abs_X_sq_acc, abs_X_4th_acc, X_3rd_acc_re, X_3rd_acc_im}, ...
    {cross_prod_sync_out, d, f, a, c, b, abs_mx_sq, e, h});

kurtosis_den_sub = xBlock(struct('source', @kurtosis_den, 'name', 'kurtosis_den'), ...
    {[], 'acc_len', acc_len}, {abs_X_sq_acc_del, abs_mx_sq}, {den});

kurtosis_num_sub = xBlock(struct('source', @kurtosis_num, 'name', 'kurtosis_num'), ...
    {[], 'acc_len', acc_len}, {cross_prod_sync_out, d, f, a, c, b, e, h}, {sync_out, num});

channel_out.bind(delay_srl('channel_del', channel_in, adder_tree_latency + cross_product_latency));

end

function kurtosis_cross_products(blk, varargin)
defaults = {'acc_len', 14, 'total_latency', 15, 'type_x', fi_dtype(1,18,17)};
acc_len = get_var('acc_len', 'defaults', defaults, varargin{:});
type_x = get_var('type_x', 'defaults', defaults, varargin{:});
bit_width = 17;
total_latency = get_var('total_latency', 'defaults', defaults, varargin{:});
[m_x_dtype, x_sq_dtype, x_3_dtype, x_4th_type] = acc_rounding_types(type_x, acc_len);

%% inports
sync = xInport('sync');
m_x_re = xInport('Re{E[X]}');
m_x_im = xInport('Im{E[X]}');
X_sq_acc_re = xInport('Re{E[X^2]}');
X_sq_acc_im = xInport('Im{E[X^2]}');
abs_X_sq_acc = xInport('E[|X|^2]');
abs_X_4th_acc = xInport('E[||X||^4]');
X_3rd_acc_re = xInport('Re{E[|X|^2X]}');
X_3rd_acc_im = xInport('Im{E[|X|^2X]}');

%% outports
sync_out = xOutport('sync_out');
d = xOutport('4E[|X|^2]|m_x|^2');
f = xOutport('4|m_x|^4');
a = xOutport('E[|X|^4]');
c = xOutport('Re{2E[X^2*conj(m_x^2)]}');
b = xOutport('Re{4E[X|X|^2*m_x]}');
abs_mx_sq = xOutport('|m_x|^2');
e = xOutport('|m_x|^4');
abs_mean_x_sq = xOutport('|E[(x-mx)^2]|^2');

%% diagram
sync_out.bind(delay_srl('del_mult', sync, total_latency));

[m_x_re_sq, m_x_re_sq_dtype] = mult('mult1', m_x_re, m_x_re, 'latency', 3, 'type_a', m_x_dtype, 'type_b', m_x_dtype);
[m_x_im_sq, m_x_im_sq_dtype] = mult('mult2', m_x_im, m_x_im, 'latency', 3, 'type_a', m_x_dtype, 'type_b', m_x_dtype);
[mx_sq_re, mx_sq_re_dtype] = subtract('add1', m_x_re_sq, m_x_im_sq, 'latency', 2, 'type_a', m_x_re_sq_dtype, 'type_b', m_x_im_sq_dtype);
[mx_re_times_mx_im, mx_re_times_mx_im_dtype] = mult('mult3', m_x_re, m_x_im, 'latency', 5, 'type_a', m_x_dtype, 'type_b', m_x_dtype);
[mx_sq_im, mx_sq_im_dtype] = scale('scale_mx_sq', mx_re_times_mx_im, 1, 'type_x', mx_re_times_mx_im_dtype);

[mx_sq_re_rounded, mx_sq_re_rounded_dtype] = round_to_wordlength('Convert', mx_sq_re, 25, mx_sq_re_dtype);
% mx_sq_re_rounded = round_inf_and_saturate('Convert', mx_sq_re, 25, 22, 'latency', 1);
[mx_sq_im_rounded, mx_sq_im_rounded_dtype] = round_to_wordlength('Convert1', mx_sq_im, 25, mx_sq_im_dtype);
% mx_sq_im_rounded = round_inf_and_saturate('Convert1', mx_sq_im, 25, 22, 'latency', 1);

X_sq_acc_re_del = delay_srl('delay_sq1', X_sq_acc_re, 6);
X_sq_acc_im_del = delay_srl('delay_sq2', X_sq_acc_im, 6);
[alpha, alpha_dtype] = mult('mult4', X_sq_acc_re_del, mx_sq_re_rounded, 'latency', 3, 'type_a', x_sq_dtype, 'type_b', mx_sq_re_rounded_dtype);
[beta, beta_dtype] = mult('mult5', X_sq_acc_im_del, mx_sq_im_rounded, 'latency', 3, 'type_a', x_sq_dtype, 'type_b', mx_sq_im_rounded_dtype);
[c_unscaled, c_unscaled_dtype] = add('add3', alpha, beta, 'latency', 2, 'type_a', alpha_dtype, 'type_b', beta_dtype);

[gamma, gamma_dtype] = mult('mult6', X_3rd_acc_re, m_x_re, 'latency', 6, 'type_a', x_3_dtype, 'type_b', m_x_dtype);
[delta, delta_dtype] = mult('mult7', X_3rd_acc_im, m_x_im, 'latency', 6, 'type_a', x_3_dtype, 'type_b', m_x_dtype);
[b_unscaled, b_unscaled_dtype] = add('add4', gamma, delta, 'latency', 2, 'type_a', gamma_dtype, 'type_b', delta_dtype);

[abs_m_x_sq, abs_m_x_sq_dtype] = add('add2', m_x_re_sq, m_x_im_sq, 'latency', 2, 'type_a', m_x_re_sq_dtype, 'type_b', m_x_im_sq_dtype);
[abs_m_x_sq_25bit, abs_m_x_sq_25bit_dtype] = round_to_wordlength('conv_25bit', abs_m_x_sq, 25, abs_m_x_sq_dtype, 'latency', 3);
[abs_m_x_sq_35bit, abs_m_x_sq_35bit_dtype] = round_to_wordlength('conv_35bit', abs_m_x_sq, 35, abs_m_x_sq_dtype, 'latency', 3);
% n_int_bits = 5;
% abs_m_x_sq_25bit = round_inf_and_saturate('conv_25bit', abs_m_x_sq, ...
%     25, 25 - n_int_bits, 'latency', 3);
% abs_m_x_sq_35bit = round_inf_and_saturate('convert_35bit', abs_m_x_sq, ...
%     35, 35 - n_int_bits, 'latency', 3);
[e_adv, e_dtype] = mult('mult8', abs_m_x_sq_25bit, abs_m_x_sq_35bit, 'latency', 5, 'type_a', abs_m_x_sq_25bit_dtype, 'type_b', abs_m_x_sq_35bit_dtype);

% calc fourth moment terms
a.bind(delay_srl('m4_del', abs_X_4th_acc, total_latency));

[b_adv, b_dtype] = scale('Scale', b_unscaled, 2, 'type_x', b_unscaled_dtype);
b.bind(delay_srl('delay_b', b_adv, 7));

[c_adv, c_dtype] = scale('Scale1', c_unscaled, 1, 'type_x', c_unscaled_dtype);
c.bind(delay_srl('c_del', c_adv, 4));

% TODO nonzero latency!
[abs_m_x_sq_rounded, abs_m_x_sq_rounded_dtype] = round_to_wordlength('Convert5', abs_m_x_sq, 25, abs_m_x_sq_dtype); 
%round_inf_and_saturate('Convert5', abs_m_x_sq, 25, 22, 'latency', 0);
abs_X_sq_acc_del = delay_srl('del1', abs_X_sq_acc, 5);
[d_unscaled, d_unscaled_dtype] = mult('Mult4',  abs_X_sq_acc_del, abs_m_x_sq_rounded, 'latency', 5, 'type_a', x_sq_dtype, 'type_b', abs_m_x_sq_rounded_dtype);
[d_adv, d_dtype] = scale('Scale3', d_unscaled, 2, 'type_x', d_unscaled_dtype);
d.bind(delay_srl('delay_sq3', d_adv, 5));

e.bind(delay_srl('del_e', e_adv, 2));

[f_adv, f_dtype] = scale('Scale4', e_adv, 2, 'type_x', e_dtype);
f.bind(delay_srl('del_f', f_adv, 2));

% third term in complex kurtosis
add_latency = 2;
mx_sq_re_del = delay_srl('del2', mx_sq_re, 1);
mx_sq_im_del = delay_srl('del3', mx_sq_im, 1);
[mx_sq_re_rounded_mb, mx_sq_re_rounded_mb_dtype] = round_to_wordlength('conv_mx_sq_re', mx_sq_re_del, 35, mx_sq_re_dtype, 'latency', 0);
[mx_sq_im_rounded_mb, mx_sq_im_rounded_mb_dtype] = round_to_wordlength('conv_mx_sq_im', mx_sq_im_del, 35, mx_sq_im_dtype, 'latency', 0);
% mx_sq_re_rounded_mb = round_inf_and_saturate('Convert_mx_sq_re', mx_sq_re_del, 34, 31, 'latency', 0);
% mx_sq_im_rounded_mb = round_inf_and_saturate('Convert_mx_sq_im', mx_sq_im_del, 34, 31, 'latency', 0);
[X_sq_mean_re, X_sq_mean_re_dtype] = scale('scale_m2_re', X_sq_acc_re_del, -acc_len, 'type_x', x_sq_dtype);
[X_sq_mean_im, X_sq_mean_im_dtype] = scale('scale_m2_im', X_sq_acc_im_del, -acc_len, 'type_x', x_sq_dtype);
[abs_mean_x_re, abs_mean_x_im, abs_mean_x_dtype] = cplx_sub('cplx_sub', {X_sq_mean_re, X_sq_mean_im}, ...
    {mx_sq_re_rounded_mb, mx_sq_im_rounded_mb}, 'latency', add_latency, 'full_precision', 1, 'type_a', X_sq_mean_re_dtype, 'type_b', mx_sq_im_rounded_mb_dtype);

% mean-squared for denominator
[abs_mean_x_re_sq, abs_mean_x_re_sq_dtype] = mult('mult9', abs_mean_x_re, abs_mean_x_re, 'latency', 4, 'type_a', abs_mean_x_dtype, 'type_b', abs_mean_x_dtype);
[abs_mean_x_im_sq, abs_mean_x_im_sq_dtype] = mult('mult10', abs_mean_x_im, abs_mean_x_im, 'latency', 4, 'type_a', abs_mean_x_dtype, 'type_b', abs_mean_x_dtype);
[abs_mean_x_sq_sig, abs_mean_x_sq_type] = add('add5', abs_mean_x_re_sq, abs_mean_x_im_sq, 'latency', 3, 'type_a', abs_mean_x_re_sq_dtype, 'type_b', abs_mean_x_im_sq_dtype);

abs_mean_x_sq.bind(abs_mean_x_sq_sig);
abs_mx_sq.bind(delay_srl('del_absmx_sq', abs_m_x_sq, total_latency-5));
end


function kurtosis_den(blk, varargin)
defaults = {'acc_len', 14};
acc_len = get_var('acc_len', 'defaults', defaults, varargin{:});

%% inports
sum_abs_x_sq = xInport('E[|X|^2]');
abs_m_x_sq = xInport('|m_x|^2');

%% outports
second_central_moment_squared = xOutport('E[|X-m_x|^2]^2');

%% diagram
mean_abs_x_sq = scale('scale', sum_abs_x_sq, -acc_len);
second_central_moment_unrounded = subtract('Sub', mean_abs_x_sq, abs_m_x_sq, 'latency', 4);

square_real_35x25_sub = xBlock(struct('source', @square_real_35x25, 'name', 'square_real1'), ...
    {[]}, ...
    {second_central_moment_unrounded}, ...
    {second_central_moment_squared});

end

function square_real_35x25(blk, varargin)
defaults = {'n_int_bits', 5, 'conv_latency', 3, 'mult_latency', 5};
n_int_bits = get_var('n_int_bits', 'defaults', defaults, varargin{:});
conv_latency = get_var('conv_latency', 'defaults', defaults, varargin{:});
mult_latency = get_var('mult_latency', 'defaults', defaults, varargin{:});

%% inports
a = xInport('a');

%% outports
a_sq = xOutport('a^2');

%% diagram
a_35bit = round_inf_and_saturate('convert_35bit', a, 35, 35 - n_int_bits, 'latency', conv_latency);
a_25bit = round_inf_and_saturate('convert_25bit', a, 25, 25 - n_int_bits, 'latency', conv_latency);
a_sq.bind(mult('Mult', a_35bit, a_25bit, 'latency', mult_latency));
end

function kurtosis_num(blk, varargin)
defaults = {'acc_len', 14};
acc_len = get_var('acc_len', 'defaults', defaults, varargin{:});
add_latency = 4;
output_dtype = fi_dtype(1, 90, 68);

%% inports
sync = xInport('sync');
d = xInport('4E[|X|^2]|m_x|^2');
f = xInport('4|m_x|^4');
a = xInport('E[|X|^4]');
c = xInport('Re{2E[X^2*conj(m_x^2)]}');
b = xInport('Re{4E[X|X|^2*m_x]}');
e = xInport('|m_x|^4');
h = xInport('|E[(x-mx)^2]|^2');

%% outports
sync_out = xOutport('sync_out');
fourth_central_moment_rounded = xOutport('E[|X-m_x|^4]');

%% diagram
% scale factors
a_round = trunc_and_wrap('trunc_a', a, 89, 65);
a_scale = scale('scale_a', a_round, -acc_len);
b_scale = scale('scale_b', b, -acc_len);
c_scale = scale('scale_c', c, -acc_len);
d_scale = scale('scale_d', d, -acc_len);

% adder layer 1
e_minus_f = subtract('sub_ef', e, f, 'latency', add_latency, 'full_precision', 1, 'type_ab', output_dtype);
c_minus_b = subtract('sub_cb', c_scale, b_scale, 'latency', add_latency, 'full_precision', 1, 'type_ab', output_dtype);
a_del = delay_srl('a_del', a_scale, add_latency);

d_minus_h = subtract('sub_dh', d_scale, h, 'latency', add_latency, 'full_precision', 1, 'type_ab', output_dtype);%delay_srl('d_del', d, add_latency);

% adder layer 2
a_plus_e_minus_f = add('add_aef', e_minus_f, a_del, 'latency', add_latency, 'full_precision', 1, 'type_ab', output_dtype);
d_plus_c_minus_b = add('add_dcb', d_minus_h, c_minus_b, 'latency', add_latency, 'full_precision', 1, 'type_ab', output_dtype);

fourth_central_moment_rounded.bind(add('add', a_plus_e_minus_f, d_plus_c_minus_b, 'latency', add_latency', 'full_precision', 1, 'type_ab', output_dtype));

% Rescale output
% fourth_central_moment_rounded.bind(scale('rescale_4th_moment', fourth_central_moment, -acc_len));

% sync delay
sync_out.bind(delay_srl('sync_del', sync, 3*add_latency));
end
