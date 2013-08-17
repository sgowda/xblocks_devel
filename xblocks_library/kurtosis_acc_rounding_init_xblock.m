function kurtosis_acc_rounding_init_xblock(blk, varargin)
defaults = {'acc_len', 14, 'type_x', fi_dtype(1, 18, 17), 'conv_latency', 5};
acc_len = get_var('acc_len', 'defaults', defaults, varargin{:});
type_x = get_var('type_x', 'defaults', defaults, varargin{:});
conv_latency = get_var('conv_latency', 'defaults', defaults, varargin{:});

% % Rounding
% single_type_x = type_x;
% double_type_x = type_x^2 + type_x^2;
% triple_type_x = type_x^3;
% quad_type_x = double_type_x^2;
% 
% single_type_x_acc = fi_dtype(1, single_type_x.WordLength+acc_len, single_type_x.FractionLength+acc_len);
% double_type_x_acc = fi_dtype(1, double_type_x.WordLength+acc_len, double_type_x.FractionLength);
% triple_type_x_acc = fi_dtype(1, triple_type_x.WordLength+acc_len, triple_type_x.FractionLength);
% quad_type_x_acc = fi_dtype(1, quad_type_x.WordLength+acc_len, quad_type_x.FractionLength);
% 
% single_type_x_acc_rounded   = fi_dtype(1, 25, 25-(type_x.WordLength - type_x.FractionLength)); % mean needs no more integer bits than the original representation
% double_type_x_acc_rounded   = fi_dtype(1, 35, 35-(double_type_x_acc.WordLength - double_type_x_acc.FractionLength));
% triple_type_x_acc_rounded   = fi_dtype(1, 35, 35-(triple_type_x_acc.WordLength - triple_type_x_acc.FractionLength));
% quad_type_x_acc_rounded     = quad_type_x_acc;

[m_x_type_unr, x_sq_type_unr, x_3rd_type_unr, x_4th_type_unr] = acc_types(type_x, acc_len);
[m_x_type, x_sq_type, x_3rd_type, x_4th_type] = acc_rounding_types(type_x, acc_len);


%% inports
sync = xInport('sync');
x_acc_re = xInport('x_acc_re');
x_acc_im = xInport('x_acc_im');
X_sq_acc_re = xInport('X_sq_acc_re');
X_sq_acc_im = xInport('X_sq_acc_im');
abs_X_sq_acc = xInport('abs_X_sq_acc');
abs_X_4th_acc = xInport('abs_X_4th_acc');
X_3rd_acc_re = xInport('X_3rd_acc_re');
X_3rd_acc_im = xInport('X_3rd_acc_im');

%% outports
sync_out = xOutport('sync_out');
m_x_re_rounded = xOutport('m_x_re_rounded');
m_x_im_rounded = xOutport('m_x_im_rounded');
X_sq_acc_re_rounded = xOutport('X_sq_acc_re_rounded');
X_sq_acc_im_rounded = xOutport('X_sq_acc_im_rounded');
abs_X_sq_acc_rounded = xOutport('abs_X_sq_acc_rounded');
abs_X_4th_rounded = xOutport('abs_X_4th_rounded');
X_3rd_acc_re_rounded = xOutport('X_3rd_acc_re_rounded');
X_3rd_acc_im_rounded = xOutport('X_3rd_acc_im_rounded');

%% diagram
m_x_re = scale('scale_mx_re', x_acc_re, -acc_len);
m_x_im = scale('scale_mx_im', x_acc_im, -acc_len);

bit_sl_out1 = trunc_and_wrap('bit_sl', m_x_re, m_x_type_unr.WordLength, m_x_type_unr.FractionLength);
bit_sl1_out1 = trunc_and_wrap('bit_sl1', m_x_im, m_x_type_unr.WordLength, m_x_type_unr.FractionLength);
bit_sl2_out1 = trunc_and_wrap('bit_sl2', X_sq_acc_re,  x_sq_type_unr.WordLength, x_sq_type_unr.FractionLength);
bit_sl3_out1 = trunc_and_wrap('bit_sl3', X_sq_acc_im,  x_sq_type_unr.WordLength, x_sq_type_unr.FractionLength);
bit_sl4_out1 = trunc_and_wrap('bit_sl4', abs_X_sq_acc, x_sq_type_unr.WordLength, x_sq_type_unr.FractionLength);
bit_sl5_out1 = trunc_and_wrap('bit_sl5', abs_X_4th_acc, x_4th_type_unr.WordLength, x_4th_type_unr.FractionLength);
bit_sl6_out1 = trunc_and_wrap('bit_sl6', X_3rd_acc_re, x_3rd_type_unr.WordLength, x_3rd_type_unr.FractionLength);
bit_sl7_out1 = trunc_and_wrap('bit_sl7', X_3rd_acc_im, x_3rd_type_unr.WordLength, x_3rd_type_unr.FractionLength);

m_x_re_rounded.bind(round_inf_and_saturate('Convert5', bit_sl_out1,  m_x_type.WordLength, m_x_type.FractionLength, 'latency', conv_latency));
m_x_im_rounded.bind(round_inf_and_saturate('Convert6', bit_sl1_out1, m_x_type.WordLength, m_x_type.FractionLength, 'latency', conv_latency));
X_sq_acc_re_rounded.bind(round_inf_and_saturate('Convert7', bit_sl2_out1,  x_sq_type.WordLength, x_sq_type.FractionLength, 'latency', conv_latency));
X_sq_acc_im_rounded.bind(round_inf_and_saturate('Convert8', bit_sl3_out1,  x_sq_type.WordLength, x_sq_type.FractionLength, 'latency', conv_latency));
abs_X_sq_acc_rounded.bind(round_inf_and_saturate('Convert9', bit_sl4_out1, x_sq_type.WordLength, x_sq_type.FractionLength, 'latency', conv_latency));
abs_X_4th_rounded.bind(round_inf_and_saturate('Convert12', bit_sl5_out1,    x_4th_type.WordLength, x_4th_type.FractionLength, 'latency', conv_latency));
X_3rd_acc_re_rounded.bind(round_inf_and_saturate('Convert10', bit_sl6_out1, x_3rd_type.WordLength, x_3rd_type.FractionLength, 'latency', conv_latency));
X_3rd_acc_im_rounded.bind(round_inf_and_saturate('Convert11', bit_sl7_out1, x_3rd_type.WordLength, x_3rd_type.FractionLength, 'latency', conv_latency));

sync_out.bind(delay_srl('cast_delay', sync, conv_latency));
end
