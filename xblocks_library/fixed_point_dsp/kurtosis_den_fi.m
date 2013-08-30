function [den] = kurtosis_den_fi(mean_abs_x_sq, abs_m_x_sq, varargin)
defaults = {'bit_width', 64, 'abs_m_x_sq_dtype', 'logging', 1};
bit_width = get_var('bit_width', 'defaults', defaults, varargin{:});
abs_m_x_sq_dtype = get_var('abs_m_x_sq_dtype', 'defaults', defaults, varargin{:});
mean_abs_x_sq_dtype = get_var('abs_x_sq_mean_del_dtype', 'defaults', defaults, varargin{:});
logging = get_var('logging', 'defaults', defaults, varargin{:});

%%% Begin
[sec_moment_unr, sec_moment_unr_dtype] = subtract_fi('Sub', mean_abs_x_sq, abs_m_x_sq, 'latency', 4, 'type_a', mean_abs_x_sq_dtype, 'type_b', abs_m_x_sq_dtype);
[den_unr, den_unr_dtype] = mult_35x25_fi('square', sec_moment_unr, sec_moment_unr, 'type_a', sec_moment_unr_dtype, 'type_b', sec_moment_unr_dtype);
[den_sig, den_dtype] = round_to_wordlength_fi('round_den', den_unr, bit_width, den_unr_dtype, 'logging', logging);
%%% End

den = den_sig;

end