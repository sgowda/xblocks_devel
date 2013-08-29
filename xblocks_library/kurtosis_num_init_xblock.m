function kurtosis_num_init_xblock(blk, varargin)
defaults = {'acc_len', 14, 'bit_width', 96, 'conv_latency', 1};
acc_len = get_var('acc_len', 'defaults', defaults, varargin{:});
bit_width = get_var('bit_width', 'defaults', defaults, varargin{:});
conv_latency = get_var('conv_latency', 'defaults', defaults, varargin{:});
a_dtype = get_var('a_dtype', 'defaults', defaults, varargin{:});
b_dtype = get_var('b_dtype', 'defaults', defaults, varargin{:});
c_dtype = get_var('c_dtype', 'defaults', defaults, varargin{:});
d_dtype = get_var('d_dtype', 'defaults', defaults, varargin{:});
e_dtype = get_var('e_dtype', 'defaults', defaults, varargin{:});
f_dtype = get_var('f_dtype', 'defaults', defaults, varargin{:});
h_dtype = get_var('h_dtype', 'defaults', defaults, varargin{:});

add_latency = 4;
logging = 0;
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
num = xOutport('E[|X-m_x|^4]');

%% diagram
sync_out_sig = delay_srl('sync_del', sync, 3*add_latency + conv_latency);

%%% Begin
% adder layer 1
[e_minus_f, e_minus_f_dtype] = subtract('sub_ef', e, f, 'latency', add_latency, 'full_precision', 1, 'type_a', e_dtype, 'type_b', f_dtype);
[c_minus_b, c_minus_b_dtype] = subtract('sub_cb', c, b, 'latency', add_latency, 'full_precision', 1, 'type_a', c_dtype, 'type_b', b_dtype);
[d_minus_h, d_minus_h_dtype] = subtract('sub_dh', d, h, 'latency', add_latency, 'full_precision', 1, 'type_a', d_dtype, 'type_b', h_dtype);
a_del = delay_srl('a_del', a, add_latency);

% adder layer 2
[a_plus_e_minus_f, a_plus_e_minus_f_dtype] = add('add_aef', e_minus_f, a_del, 'latency', add_latency, 'full_precision', 1, 'type_a', e_minus_f_dtype, 'type_b', a_dtype);
[d_plus_c_minus_b, d_plus_c_minus_b_dtype] = add('add_dcb', d_minus_h, c_minus_b, 'latency', add_latency, 'full_precision', 1, 'type_a', d_minus_h_dtype, 'type_b', c_minus_b_dtype);

[num_unr, num_unr_dtype] = add('add', a_plus_e_minus_f, d_plus_c_minus_b, 'latency', add_latency', 'full_precision', 1, 'type_a', a_plus_e_minus_f_dtype, 'type_b', d_plus_c_minus_b_dtype);
num_sig = round_to_wordlength('round_num', num_unr, bit_width, num_unr_dtype, 'logging', logging);
%%% End

% sync delay
num.bind(num_sig);
sync_out.bind(sync_out_sig);
end
