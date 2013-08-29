function kurtosis_acc_rounding_init_xblock(blk, varargin)
defaults = {'acc_len', 14, 'type_x', fi_dtype(1, 18, 17), 'conv_latency', 5};
acc_len = get_var('acc_len', 'defaults', defaults, varargin{:});

type_x = get_var('type_x', 'defaults', defaults, varargin{:});
conv_latency = get_var('conv_latency', 'defaults', defaults, varargin{:});
% bit_sel_latency = 1;
% [m_x_type_unr, x_sq_type_unr, x_3rd_type_unr, x_4th_type_unr] = kurtosis_acc_types(type_x, acc_len);
[m_x_type, x_sq_type, x_3rd_type, x_4th_type] = kurtosis_mean_types(type_x, acc_len);

%% inports
sync = xInport('sync');
x_mean_re = xInport('x_mean_re');
x_mean_im = xInport('x_mean_im');
x_sq_mean_re = xInport('x_sq_mean_re');
x_sq_mean_im = xInport('x_sq_mean_im');
abs_x_sq_mean = xInport('abs_x_sq_mean');
abs_x_4th_mean = xInport('abs_x_4th_mean');
x_3rd_mean_re = xInport('x_3rd_mean_re');
x_3rd_mean_im = xInport('x_3rd_mean_im');

%% outports
sync_out = xOutport('sync_out');
m_x_re_rounded = xOutport('m_x_re_rounded');
m_x_im_rounded = xOutport('m_x_im_rounded');
x_sq_mean_re_rounded = xOutport('x_sq_mean_re_rounded');
x_sq_mean_im_rounded = xOutport('x_sq_mean_im_rounded');
abs_x_sq_mean_rounded = xOutport('abs_x_sq_mean_rounded');
abs_x_4th_mean_rounded = xOutport('abs_x_4th_rounded');
x_3rd_mean_re_rounded = xOutport('x_3rd_mean_re_rounded');
x_3rd_mean_im_rounded = xOutport('x_3rd_mean_im_rounded');

%% diagram
m_x_re_rounded.bind(round_to_wordlength('', x_mean_re, 25, m_x_type));
m_x_im_rounded.bind(round_to_wordlength('', x_mean_im, 25, m_x_type));
x_sq_mean_re_rounded.bind(round_to_wordlength('', x_sq_mean_re, 35, x_sq_type));
x_sq_mean_im_rounded.bind(round_to_wordlength('', x_sq_mean_im, 35, x_sq_type));
x_3rd_mean_re_rounded.bind(round_to_wordlength('', x_3rd_mean_re, 35, x_3rd_type));
x_3rd_mean_im_rounded.bind(round_to_wordlength('', x_3rd_mean_im, 35, x_3rd_type));
abs_x_sq_mean_rounded.bind(round_to_wordlength('', abs_x_sq_mean, 35, x_sq_type));
abs_x_4th_mean_rounded.bind(round_to_wordlength('', abs_x_4th_mean, 35, x_4th_type));

% m_x_re = scale('scale_mx_re', x_acc_re, -acc_len);
% m_x_im = scale('scale_mx_im', x_acc_im, -acc_len);
% 
% bit_sl_out1 = trunc_and_wrap('bit_sl', m_x_re, m_x_type_unr.WordLength, m_x_type_unr.FractionLength, 'latency', bit_sel_latency);
% bit_sl1_out1 = trunc_and_wrap('bit_sl1', m_x_im, m_x_type_unr.WordLength, m_x_type_unr.FractionLength, 'latency', bit_sel_latency);
% bit_sl2_out1 = trunc_and_wrap('bit_sl2', x_sq_acc_re,  x_sq_type_unr.WordLength, x_sq_type_unr.FractionLength, 'latency', bit_sel_latency);
% bit_sl3_out1 = trunc_and_wrap('bit_sl3', x_sq_acc_im,  x_sq_type_unr.WordLength, x_sq_type_unr.FractionLength, 'latency', bit_sel_latency);
% bit_sl4_out1 = trunc_and_wrap('bit_sl4', abs_x_sq_acc, x_sq_type_unr.WordLength, x_sq_type_unr.FractionLength, 'latency', bit_sel_latency);
% bit_sl5_out1 = trunc_and_wrap('bit_sl5', abs_x_4th_acc, x_4th_type_unr.WordLength, x_4th_type_unr.FractionLength, 'latency', bit_sel_latency);
% bit_sl6_out1 = trunc_and_wrap('bit_sl6', x_3rd_acc_re, x_3rd_type_unr.WordLength, x_3rd_type_unr.FractionLength, 'latency', bit_sel_latency);
% bit_sl7_out1 = trunc_and_wrap('bit_sl7', x_3rd_acc_im, x_3rd_type_unr.WordLength, x_3rd_type_unr.FractionLength, 'latency', bit_sel_latency);

%m_x_re_rounded.bind(round_inf_and_saturate('Convert5', bit_sl_out1,  m_x_type.WordLength, m_x_type.FractionLength, 'latency', conv_latency));
%m_x_im_rounded.bind(round_inf_and_saturate('Convert6', bit_sl1_out1, m_x_type.WordLength, m_x_type.FractionLength, 'latency', conv_latency));
%x_sq_acc_re_rounded.bind(round_inf_and_saturate('Convert7', bit_sl2_out1,  x_sq_type.WordLength, x_sq_type.FractionLength, 'latency', conv_latency));
%x_sq_acc_im_rounded.bind(round_inf_and_saturate('Convert8', bit_sl3_out1,  x_sq_type.WordLength, x_sq_type.FractionLength, 'latency', conv_latency));
%abs_x_sq_acc_rounded.bind(round_inf_and_saturate('Convert9', bit_sl4_out1, x_sq_type.WordLength, x_sq_type.FractionLength, 'latency', conv_latency));
%abs_x_4th_rounded.bind(round_inf_and_saturate('Convert12', bit_sl5_out1,    x_4th_type.WordLength, x_4th_type.FractionLength, 'latency', conv_latency));
%x_3rd_acc_re_rounded.bind(round_inf_and_saturate('Convert10', bit_sl6_out1, x_3rd_type.WordLength, x_3rd_type.FractionLength, 'latency', conv_latency));
%x_3rd_acc_im_rounded.bind(round_inf_and_saturate('Convert11', bit_sl7_out1, x_3rd_type.WordLength, x_3rd_type.FractionLength, 'latency', conv_latency));

sync_out.bind(delay_srl('cast_delay', sync, conv_latency));
end
