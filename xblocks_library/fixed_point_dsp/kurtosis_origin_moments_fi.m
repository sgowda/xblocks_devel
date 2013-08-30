function [x_re_fi, x_im_fi, x_sq_re, x_sq_im, abs_x_sq, abs_x_4th, x_3rd_re, x_3rd_im, origin_moment_error] = kurtosis_origin_moments_fi(x_in, varargin)
type_x_default = fi_dtype(1, 18, 17);
defaults = {'type_x', type_x_default};
type_x = get_var('type_x', 'defaults', defaults, varargin{:});
bit_width = type_x.WordLength;
bin_pt = type_x.FractionLength;
%-- Calculate origin_moments: 5 reg multipliers, 1 large multiplier, and 2 adders

%%% BEGIN
double_type_x = type_x^2 + type_x^2;
triple_type_x = type_x * double_type_x;
quad_type_x = double_type_x^2;

latency_mult_25x18 = 3;
latency_mult_35x25 = 5;
latency_add48 = 2;
[x_re_fi, x_im_fi] = c_to_ri_fi('x_ri', x_in, bit_width, bin_pt);
[x_re_sq, x_re_sq_dtype] = mult_fi('mult1', x_re_fi, x_re_fi, 'type_a', type_x, 'type_b', type_x, 'latency', latency_mult_25x18);
[x_im_sq, x_im_sq_dtype] = mult_fi('mult2', x_im_fi, x_im_fi, 'type_a', type_x, 'type_b', type_x, 'latency', latency_mult_25x18);

[abs_x_sq_sig, abs_x_sq_dtype] = add_fi('add1', x_re_sq, x_im_sq, 'type_a', x_re_sq_dtype, 'type_b', x_im_sq_dtype, 'latency', latency_add48);
[abs_x_4th_sig, abs_x_4th_dtype] = mult_fi('mult3', abs_x_sq_sig, abs_x_sq_sig, 'type_a', abs_x_sq_dtype, 'type_b', abs_x_sq_dtype, 'latency', latency_mult_35x25);

[x_sq_re_sig, x_sq_re_dtype] = subtract_fi('add2', x_re_sq, x_im_sq, 'type_a', x_re_sq_dtype, 'type_b', x_im_sq_dtype, 'latency', latency_add48);
[x_sq_im_unscaled, x_sq_im_unscaled_dtype] = mult_fi('mult4', x_re_fi, x_im_fi, 'type_a', type_x, 'type_b', type_x, 'latency', latency_mult_25x18);
[x_sq_im_sig, x_sq_im_dtype] = scale_fi('', x_sq_im_unscaled, 1, 'type_x', x_sq_im_unscaled_dtype, 'latency', 0);
x_sq_im_sig = trunc_and_wrap_fi('', x_sq_im_sig, double_type_x.WordLength, double_type_x.FractionLength);

x_re_fi_del = delay_srl_fi('', x_re_fi, latency_mult_25x18 + latency_add48);
x_im_fi_del = delay_srl_fi('', x_im_fi, latency_mult_25x18 + latency_add48);

[x_3rd_re_sig, x_3rd_re_dtype] = mult_fi('mult5', x_re_fi_del, abs_x_sq_sig, 'type_a', type_x, 'type_b', abs_x_sq_dtype, 'latency', latency_mult_35x25);
[x_3rd_im_sig, x_3rd_im_dtype] = mult_fi('mult6', x_im_fi_del, abs_x_sq_sig, 'type_a', type_x, 'type_b', abs_x_sq_dtype, 'latency', latency_mult_35x25);

total_latency = latency_mult_25x18 + latency_add48 + latency_mult_35x25;
x_re_fi = delay_srl_fi('', x_re_fi, total_latency);
x_im_fi = delay_srl_fi('', x_im_fi, total_latency);
x_sq_re_sig = delay_srl_fi('', x_sq_re_sig, total_latency - (latency_mult_25x18 + latency_add48));
x_sq_im_sig = delay_srl_fi('', x_sq_im_sig, total_latency - (latency_mult_25x18));
abs_x_sq_sig = delay_srl_fi('', abs_x_sq_sig, total_latency - (latency_mult_25x18 + latency_add48));
%%% END

x_sq_re = x_sq_re_sig;
x_sq_im = x_sq_im_sig;
abs_x_sq = abs_x_sq_sig;
abs_x_4th = abs_x_4th_sig;
x_3rd_re = x_3rd_re_sig;
x_3rd_im = x_3rd_im_sig;

x_re_fl = double(x_re_fi);
x_im_fl = double(x_im_fi);
[x_re_fl, x_im_fl, x_sq_re_fl, x_sq_im_fl, abs_x_sq_fl, abs_x_4th_fl, ...
    x_3rd_re_fl, x_3rd_im_fl] = kurtosis_origin_moments_float(x_re_fl, x_im_fl);

origin_moment_error.x_sq_re = max(max(abs(x_sq_re_fl - double(x_sq_re))));
origin_moment_error.x_sq_im = max(max(abs(x_sq_im_fl - double(x_sq_im))));
origin_moment_error.x_3rd_re = max(max(abs(x_3rd_re_fl - double(x_3rd_re))));
origin_moment_error.x_3rd_im = max(max(abs(x_3rd_im_fl - double(x_3rd_im))));
origin_moment_error.abs_x_sq = max(max(abs(abs_x_sq_fl - double(abs_x_sq))));
origin_moment_error.abs_x_4th = max(max(abs(abs_x_4th_fl - double(abs_x_4th))));

end
