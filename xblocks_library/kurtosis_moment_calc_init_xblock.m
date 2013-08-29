function kurtosis_moment_calc_init_xblock(blk, varargin)
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
defaults = {'acc_len', 14, 'type_x', fi_dtype(1, 18, 17)};
acc_len = get_var('acc_len', 'defaults', defaults, varargin{:});
type_x = get_var('type_x', 'defaults', defaults, varargin{:});

bit_width_power = 32;
bit_width_num = 96;
bit_width_den = 64;

[m_x_type, x_sq_type, x_3rd_type, x_4th_type] = kurtosis_mean_types(type_x, acc_len);

% cross-product data types
[a_dtype, b_dtype, c_dtype, d_dtype, e_dtype, f_dtype, abs_m_x_sq_dtype, abs_mean_x_sq_dtype] = ...
    kurtosis_cross_product_dtypes(m_x_type, m_x_type, ...
    x_sq_type, x_sq_type, x_sq_type, x_4th_type, x_3rd_type, x_3rd_type, 'acc_len', acc_len);


rounding_latency = 1;
add_latency_96bit = 4;
cross_product_latency = 25;
adder_tree_latency = add_latency_96bit * 3 + rounding_latency;
abs_X_sq_acc_del = delay_srl('cross_product_del', abs_X_sq_acc, cross_product_latency);

abs_X_sq_acc_del2 = round_to_wordlength('adder_tree_del', abs_X_sq_acc_del, bit_width_power, x_sq_type, 'latency', adder_tree_latency);
abs_X_sq_mean.bind(abs_X_sq_acc_del2); 
% abs_X_sq_mean.bind(scale('scale', abs_X_sq_acc_del2, -acc_len)); 
cross_prod_sync_out = xSignal();
d = xSignal();
f = xSignal();
a = xSignal();
c = xSignal();
b = xSignal();
abs_mx_sq = xSignal();
e = xSignal();
h = xSignal();

% cross-products
xBlock(struct('source', @kurtosis_cross_products_init_xblock, 'name', 'kurtosis_cross_products'), ...
    {subblockname(blk, 'kurtosis_cross_products'), 'acc_len', acc_len, 'total_latency', cross_product_latency, 'type_x', type_x}, ...
    {sync, m_x_re, m_x_im, X_sq_acc_re, X_sq_acc_im, abs_X_sq_acc, abs_X_4th_acc, X_3rd_acc_re, X_3rd_acc_im}, ...
    {cross_prod_sync_out, d, f, a, c, b, abs_mx_sq, e, h});

% denominator
logging = 0;
xBlock(struct('source', @kurtosis_den_init_xblock, 'name', 'kurtosis_den'), ...
    {[], 'acc_len', acc_len, 'bit_width', bit_width_den, 'abs_m_x_sq_dtype', abs_m_x_sq_dtype, 'abs_x_sq_mean_del_dtype', x_sq_type}, {abs_X_sq_acc_del, abs_mx_sq}, {den});

% numerator
xBlock(struct('source', @kurtosis_num_init_xblock, 'name', 'kurtosis_num'), ...
    {[], 'acc_len', acc_len, 'bit_width', bit_width_num, 'a_dtype', a_dtype, ...
        'b_dtype', b_dtype, 'c_dtype', c_dtype, 'd_dtype', d_dtype, ...
        'e_dtype', e_dtype, 'f_dtype', f_dtype, 'h_dtype', abs_mean_x_sq_dtype}, ...
    {cross_prod_sync_out, d, f, a, c, b, e, h}, {sync_out, num});

channel_out.bind(delay_srl('channel_del', channel_in, adder_tree_latency + cross_product_latency));

end