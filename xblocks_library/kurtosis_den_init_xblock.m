function kurtosis_den_init_xblock(blk, varargin)
defaults = {'acc_len', 14, 'bit_width', 64, 'abs_m_x_sq_dtype'};
acc_len = get_var('acc_len', 'defaults', defaults, varargin{:});
bit_width = get_var('bit_width', 'defaults', defaults, varargin{:});
abs_m_x_sq_dtype = get_var('abs_m_x_sq_dtype', 'defaults', defaults, varargin{:});
mean_abs_x_sq_dtype = get_var('abs_x_sq_mean_del_dtype', 'defaults', defaults, varargin{:});
logging = 0;
%% inports
mean_abs_x_sq = xInport('E[|X|^2]');
abs_m_x_sq = xInport('|m_x|^2');

%% outports
den = xOutport('E[|X-m_x|^2]^2');

%% diagram
%%% Begin
[sec_moment_unr, sec_moment_unr_dtype] = subtract('Sub', mean_abs_x_sq, abs_m_x_sq, 'latency', 4, 'type_a', mean_abs_x_sq_dtype, 'type_b', abs_m_x_sq_dtype);
[den_unr, den_unr_dtype] = mult_35x25('square', sec_moment_unr, sec_moment_unr, 'type_a', sec_moment_unr_dtype, 'type_b', sec_moment_unr_dtype);
[den_sig, den_dtype] = round_to_wordlength('round_den', den_unr, bit_width, den_unr_dtype, 'logging', logging);
%%% End
den.bind(den_sig)

end