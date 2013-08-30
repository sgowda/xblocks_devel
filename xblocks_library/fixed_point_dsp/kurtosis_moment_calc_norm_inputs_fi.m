function [num, den, abs_x_sq_mean] = kurtosis_moment_calc_norm_inputs_fi(x_mean_re, x_mean_im, x_sq_mean_re, x_sq_mean_im, abs_x_sq_mean, abs_x_4th_mean, x_3rd_mean_re, x_3rd_mean_im, varargin)
defaults = {'type_x', fi_dtype(1, 18, 17), 'acc_len', 14, 'logging', 1};
type_x = get_var('type_x', 'defaults', defaults, varargin{:});
acc_len = get_var('acc_len', 'defaults', defaults, varargin{:});
logging = get_var('logging', 'defaults', defaults, varargin{:});
[m_x_type, x_sq_type, x_3rd_type, x_4th_type] = kurtosis_mean_types(type_x, acc_len);

bit_width_power = 32;
bit_width_num = 96;
bit_width_den = 96;

rounding_latency = 1;
add_latency_96bit = 4;
cross_product_latency = 15;
adder_tree_latency = add_latency_96bit * 3 + rounding_latency;
abs_x_sq_mean_del = delay_srl_fi('cross_product_del', abs_x_sq_mean, cross_product_latency);

% cross-products
[d, f, a, c, b, abs_mx_sq, e, h] = kurtosis_cross_products_fi(x_mean_re, x_mean_im, x_sq_mean_re, x_sq_mean_im, abs_x_sq_mean, abs_x_4th_mean, x_3rd_mean_re, x_3rd_mean_im, 'total_latency', cross_product_latency, 'type_x', type_x, 'acc_len', acc_len);

abs_x_sq_mean = round_to_wordlength_fi('round_power', abs_x_sq_mean_del, bit_width_power, x_sq_type, 'latency', adder_tree_latency);

% cross-product data types
[a_dtype, b_dtype, c_dtype, d_dtype, e_dtype, f_dtype, abs_m_x_sq_dtype, abs_mean_x_sq_dtype] = ...
    kurtosis_cross_products_fi(m_x_type, m_x_type, ...
    x_sq_type, x_sq_type, x_sq_type, x_4th_type, x_3rd_type, x_3rd_type, 'logging', 0);

% denominator
den = kurtosis_den_fi(abs_x_sq_mean_del, abs_mx_sq, 'bit_width', bit_width_den, 'abs_m_x_sq_dtype', abs_m_x_sq_dtype, 'abs_x_sq_mean_del_dtype', x_sq_type, 'logging', logging);

% numerator
num = kurtosis_num_fi(d, f, a, c, b, e, h, 'bit_width', bit_width_num, 'a_dtype', a_dtype, ...
    'b_dtype', b_dtype, 'c_dtype', c_dtype, 'd_dtype', d_dtype, ...
    'e_dtype', e_dtype, 'f_dtype', f_dtype, 'h_dtype', abs_mean_x_sq_dtype, 'logging', logging);
    
end