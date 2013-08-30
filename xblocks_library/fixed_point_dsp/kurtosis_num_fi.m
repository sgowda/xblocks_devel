function num = kurtosis_num_fi(d, f, a, c, b, e, h, varargin)
defaults = {'bit_width', 96, 'conv_latency', 1, 'logging', 1};
bit_width = get_var('bit_width', 'defaults', defaults, varargin{:});
conv_latency = get_var('conv_latency', 'defaults', defaults, varargin{:});
logging = get_var('logging', 'defaults', defaults, varargin{:});
a_dtype = get_var('a_dtype', 'defaults', defaults, varargin{:});
b_dtype = get_var('b_dtype', 'defaults', defaults, varargin{:});
c_dtype = get_var('c_dtype', 'defaults', defaults, varargin{:});
d_dtype = get_var('d_dtype', 'defaults', defaults, varargin{:});
e_dtype = get_var('e_dtype', 'defaults', defaults, varargin{:});
f_dtype = get_var('f_dtype', 'defaults', defaults, varargin{:});
h_dtype = get_var('h_dtype', 'defaults', defaults, varargin{:});

add_latency = 4;

%%% Begin
% adder layer 1
[e_minus_f, e_minus_f_dtype] = subtract_fi('sub_ef', e, f, 'latency', add_latency, 'full_precision', 1, 'type_a', e_dtype, 'type_b', f_dtype);
[c_minus_b, c_minus_b_dtype] = subtract_fi('sub_cb', c, b, 'latency', add_latency, 'full_precision', 1, 'type_a', c_dtype, 'type_b', b_dtype);
[d_minus_h, d_minus_h_dtype] = subtract_fi('sub_dh', d, h, 'latency', add_latency, 'full_precision', 1, 'type_a', d_dtype, 'type_b', h_dtype);
a_del = delay_srl_fi('a_del', a, add_latency);

% adder layer 2
[a_plus_e_minus_f, a_plus_e_minus_f_dtype] = add_fi('add_aef', e_minus_f, a_del, 'latency', add_latency, 'full_precision', 1, 'type_a', e_minus_f_dtype, 'type_b', a_dtype);
[d_plus_c_minus_b, d_plus_c_minus_b_dtype] = add_fi('add_dcb', d_minus_h, c_minus_b, 'latency', add_latency, 'full_precision', 1, 'type_a', d_minus_h_dtype, 'type_b', c_minus_b_dtype);

[num_unr, num_unr_dtype] = add_fi('add', a_plus_e_minus_f, d_plus_c_minus_b, 'latency', add_latency', 'full_precision', 1, 'type_a', a_plus_e_minus_f_dtype, 'type_b', d_plus_c_minus_b_dtype);
num_sig = round_to_wordlength_fi('round_num', num_unr, bit_width, num_unr_dtype, 'logging', logging);
%%% End

num = num_sig;

end