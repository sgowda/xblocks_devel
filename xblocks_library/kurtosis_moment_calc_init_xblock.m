function kurtosis_moment_calc_init_xblock(blk, varargin)
%% inports
sync = xInport('sync');
inport6 = xInport('Re{E[X]}');
inport3 = xInport('Im{E[X]}');
inport7 = xInport('Re{E[X^2]}');
inport4 = xInport('Im{E[X^2]}');
inport1 = xInport('E[|X|^2]');
inport2 = xInport('E[||X||^4]');
inport8 = xInport('Re{E[|X|^2X]}');
inport5 = xInport('Im{E[|X|^2X]}');

%% outports
sync_out = xOutport('sync_out');
outport2 = xOutport('E[|X-m_x|^4]');
outport1 = xOutport('E[|X-m_x|^2]^2');

%% diagram

% block: untitled/kurtosis_moment_calc_init_xblock/cross_product_del
cross_product_del_out1 = xSignal('cross_product_del_out1');
cross_product_del = xBlock(struct('source', 'Delay', 'name', 'cross_product_del'), ...
    struct('latency', 14), ...
    {inport1}, ...
    {cross_product_del_out1});

% block: untitled/kurtosis_moment_calc_init_xblock/kurtosis_cross_products
kurtosis_cross_products_out1 = xSignal('sync_out');
kurtosis_cross_products_out2 = xSignal('4E[|X|^2]|m_x|^2');
kurtosis_cross_products_out3 = xSignal('4|m_x|^4');
kurtosis_cross_products_out4 = xSignal('E[|X|^4]');
kurtosis_cross_products_out5 = xSignal('Re{2E[X^2*conj(m_x^2)]}');
kurtosis_cross_products_out6 = xSignal('Re{4E[X|X|^2*m_x]}');
kurtosis_cross_products_out7 = xSignal('|m_x|^2');
kurtosis_cross_products_out8 = xSignal('|m_x|^4');
subblockname(blk, 'kurtosis_cross_products')
kurtosis_cross_products_sub = xBlock(struct('source', @kurtosis_cross_products, 'name', 'kurtosis_cross_products'), ...
    {subblockname(blk, 'kurtosis_cross_products')}, ...
    {sync, inport6, inport3, inport7, inport4, inport1, inport2, inport8, inport5}, ...
    {kurtosis_cross_products_out1, kurtosis_cross_products_out2, kurtosis_cross_products_out3, kurtosis_cross_products_out4, kurtosis_cross_products_out5, kurtosis_cross_products_out6, kurtosis_cross_products_out7, kurtosis_cross_products_out8});

% block: untitled/kurtosis_moment_calc_init_xblock/kurtosis_den
kurtosis_den_sub = xBlock(struct('source', @kurtosis_den, 'name', 'kurtosis_den'), ...
    {}, ...
    {cross_product_del_out1, kurtosis_cross_products_out7}, ...
    {outport1});

% block: untitled/kurtosis_moment_calc_init_xblock/kurtosis_num
kurtosis_num_sub = xBlock(struct('source', @kurtosis_num, 'name', 'kurtosis_num'), ...
    {}, ...
    {kurtosis_cross_products_out1, kurtosis_cross_products_out2, kurtosis_cross_products_out3, kurtosis_cross_products_out4, kurtosis_cross_products_out5, kurtosis_cross_products_out6, kurtosis_cross_products_out8}, ...
    {sync_out, outport2});

end

function kurtosis_cross_products(blk, varargin)
%% inports
sync = xInport('sync');
m_x_re = xInport('Re{E[X]}');
m_x_im = xInport('Im{E[X]}');
inport7 = xInport('Re{E[X^2]}');
inport4 = xInport('Im{E[X^2]}');
inport1 = xInport('E[|X|^2]');
inport2 = xInport('E[||X||^4]');
inport8 = xInport('Re{E[|X|^2X]}');
inport5 = xInport('Im{E[|X|^2X]}');

%% outports
sync_out = xOutport('sync_out');
outport1 = xOutport('4E[|X|^2]|m_x|^2');
outport2 = xOutport('4|m_x|^4');
outport3 = xOutport('E[|X|^4]');
outport4 = xOutport('Re{2E[X^2*conj(m_x^2)]}');
outport5 = xOutport('Re{4E[X|X|^2*m_x]}');
outport7 = xOutport('|m_x|^2');
outport8 = xOutport('|m_x|^4');

%% Signals
square_cplx1_out1 = xSignal('square_cplx1_out1');
square_cplx1_out2 = xSignal('square_cplx1_out2');
square_real1_out1 = xSignal('square_real1_out1');
% Mult4_out1 = xSignal('Mult4_out1');
cmult_conj2_out1 = xSignal('cmult_conj2_out1');
cmult_conj1_out1 = xSignal('cmult_conj1_out1');

%% diagram
Convert_out1 = trunc_and_wrap('Convert', square_cplx1_out1, 25, 22);
Convert1_out1 = trunc_and_wrap('Convert1', square_cplx1_out2, 25, 22);
Scale4_out1 = scale('Scale4', square_real1_out1, 2);
outport2.bind(round_inf_and_saturate('Convert3', Scale4_out1, 94, 70, 'latency', 4));
outport8.bind(round_inf_and_saturate('Convert4', square_real1_out1, 94, 70, 'latency', 4));

m_x = ri_to_c('ri_to_c_mx', m_x_re, m_x_im);
abs_m_x_sq = modulus_sq('abs_mx_sq', m_x, 'bit_width', 25, 'bin_pt', 24);
abs_m_x_sq_rounded = trunc_and_wrap('Convert5', abs_m_x_sq, 25, 22);

del1_out1 = delay_srl('del1', inport1, 5);
% Mult4 = xBlock(struct('source', 'Mult', 'name', 'Mult4'), ...
%     struct('latency', 5), ...
%     {abs_m_x_sq_rounded, del1_out1}, ...
%     {Mult4_out1});
Mult4_out1 = mult('Mult4', abs_m_x_sq_rounded, del1_out1, 'latency', 5);
Scale_out1 = scale('Scale', cmult_conj2_out1, 2);
outport4.bind(scale('Scale1', cmult_conj1_out1, 1));
Scale3_out1 = scale('Scale3', Mult4_out1, 2);

delay_sq1_out1 = delay_srl('delay_sq1', inport7, 6);
delay_sq2_out1 = delay_srl('delay_sq2', inport4, 6);
outport1.bind(delay_srl('delay_sq3', Scale3_out1, 4));
outport5.bind(delay_srl('delay_sq5', Scale_out1, 6));
outport3.bind(delay_srl('delay_sq6', inport2, 14));
sync_out.bind(delay_srl('del_mult', sync, 14));
outport7.bind(delay_srl('del_mult1', abs_m_x_sq_rounded, 9));

cmult_conj1_sub = xBlock(struct('source', @cmult_behav_init_xblock2, 'name', 'cmult_conj1'), ...
    {[], 'n_bits_a', 35, 'bin_pt_a', 17, 'n_bits_b', 25, 'bin_pt_b', 22, 'conjugated', 1, ...
	'full_precision', 1, 'cplx_inputs', 0, 'mult_latency', 3, 'add_latency', 2, 'conv_latency', 0}, ...
    {delay_sq1_out1, delay_sq2_out1, Convert_out1, Convert1_out1}, ...
    {cmult_conj1_out1, []});

cmult_conj2_sub = xBlock(struct('source', @cmult_behav_init_xblock2, 'name', 'cmult_conj2'), ...
    {[], 'n_bits_a', 35, 'bin_pt_a', 16, 'n_bits_b', 25, 'bin_pt_b', 24, 'conjugated', 1, ...
	'full_precision', 1, 'cplx_inputs', 0, 'mult_latency', 6, 'add_latency', 2, 'conv_latency', 0}, ...
    {inport8, inport5, m_x_re, m_x_im}, ...
    {cmult_conj2_out1, []});

xBlock(struct('source', @cmult_behav_init_xblock2, 'name', 'square_cplx1'), ...
    {[], 'n_bits_a', 25, 'bin_pt_a', 24, 'n_bits_b', 25, 'bin_pt_b', 24, 'conjugated', 0, ...
	'full_precision', 1, 'cplx_inputs', 0, 'mult_latency', 3, 'add_latency', 2, 'conv_latency', 1}, ...
    {m_x_re, m_x_im, m_x_re, m_x_im}, ...
    {square_cplx1_out1, square_cplx1_out2});

square_real1_sub = xBlock(struct('source', @square_real_35x25, 'name', 'square_real1'), ...
    {[]}, ...
    {abs_m_x_sq_rounded}, ...
    {square_real1_out1});

end


function kurtosis_den()
acc_len = 2^14;
%% inports
sum_abs_x_sq = xInport('E[|X|^2]');
abs_m_x_sq = xInport('|m_x|^2');

%% outports
second_central_moment_squared = xOutport('E[|X-m_x|^2]^2');

%% diagram

% mean_abs_x_sq = xSignal();
mean_abs_x_sq = scale('scale', sum_abs_x_sq, -log2(acc_len));
%xBlock(struct('source', 'Scale', 'name', 'scale'), ...
%    {'scale_factor', -log2(acc_len)}, {sum_abs_x_sq}, {mean_abs_x_sq});

% block: untitled/kurtosis_moment_calc_init_xblock/kurtosis_den/AddSub
second_central_moment_unrounded = xSignal('xlsub3_AddSub_out1');
xlsub3_AddSub = xBlock(struct('source', 'AddSub', 'name', 'AddSub'), ...
    struct('mode', 'Subtraction', ...
    'latency', 4), ...
    {mean_abs_x_sq, abs_m_x_sq}, ...
    {second_central_moment_unrounded});

% block: untitled/kurtosis_moment_calc_init_xblock/kurtosis_den/square_real1
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



function kurtosis_num()
add_latency = 4;
acc_len = 14;

output_dtype = fi_dtype(1, 90, 68);
%% inports
xlsub3_sync = xInport('sync');
xlsub3_inport1 = xInport('4E[|X|^2]|m_x|^2');
xlsub3_inport2 = xInport('4|m_x|^4');
xlsub3_inport3 = xInport('E[|X|^4]');
xlsub3_inport4 = xInport('Re{2E[X^2*conj(m_x^2)]}');
xlsub3_inport5 = xInport('Re{4E[X|X|^2*m_x]}');
xlsub3_inport7 = xInport('|m_x|^4');

%% outports
xlsub3_sync_out = xOutport('sync_out');
fourth_central_moment_rounded = xOutport('E[|X-m_x|^4]');
fourth_central_moment = xSignal();

%% diagram

% block: untitled/kurtosis_moment_calc_init_xblock/kurtosis_num/AddSub
% xlsub3_AddSub_out1 = xSignal('xlsub3_AddSub_out1');
xlsub3_AddSub_out1 = subtract('AddSub', xlsub3_inport7, xlsub3_inport2, 'latency', add_latency, 'full_precision', 0, 'type_ab', output_dtype);
% xlsub3_AddSub = xBlock(struct('source', 'AddSub', 'name', 'AddSub'), ...
%     struct('mode', 'Subtraction', ...
%     'latency', add_latency, ...
%     'precision', 'User Defined', ...
%     'arith_type', 'Signed  (2''s comp)', ...
%     'n_bits', 90, ...
%     'bin_pt', 68), ...
%     {xlsub3_inport7, xlsub3_inport2}, ...
%     {xlsub3_AddSub_out1});

% block: untitled/kurtosis_moment_calc_init_xblock/kurtosis_num/AddSub1
% xlsub3_AddSub1_out1 = xSignal('xlsub3_AddSub1_out1');
xlsub3_AddSub1_out1 = subtract('AddSub1', xlsub3_inport4, xlsub3_inport5, 'latency', add_latency, 'full_precision', 0, 'type_ab', output_dtype);
% xlsub3_AddSub1 = xBlock(struct('source', 'AddSub', 'name', 'AddSub1'), ...
%     struct('mode', 'Subtraction', ...
%     'latency', add_latency, ...
%     'precision', 'User Defined', ...
%     'arith_type', 'Signed  (2''s comp)', ...
%     'n_bits', 90, ...
%     'bin_pt', 68, ...
%     'use_behavioral_HDL', 'on', ...
%     'hw_selection', 'DSP48', ...
%     'pipelined', 'on'), ...
%     {xlsub3_inport4, xlsub3_inport5}, ...
%     {xlsub3_AddSub1_out1});

% block: untitled/kurtosis_moment_calc_init_xblock/kurtosis_num/AddSub2
% xlsub3_delay_sq8_out1 = xSignal('xlsub3_delay_sq8_out1');
xlsub3_delay_sq8_out1 = delay_srl('delay_sq8', xlsub3_inport3, add_latency);
xlsub3_AddSub2_out1 = add('AddSub2', xlsub3_AddSub_out1, xlsub3_delay_sq8_out1, 'latency', add_latency, 'full_precision', 0, 'type_ab', output_dtype);
% xlsub3_AddSub2_out1 = xSignal('xlsub3_AddSub2_out1');
% xlsub3_AddSub2 = xBlock(struct('source', 'AddSub', 'name', 'AddSub2'), ...
%     struct('latency', add_latency, ...
%     'precision', 'User Defined', ...
%     'arith_type', 'Signed  (2''s comp)', ...
%     'n_bits', 90, ...
%     'bin_pt', 68), ...
%     {xlsub3_AddSub_out1, xlsub3_delay_sq8_out1}, ...
%     {xlsub3_AddSub2_out1});

% block: untitled/kurtosis_moment_calc_init_xblock/kurtosis_num/AddSub3
% xlsub3_AddSub4_out1 = xSignal('xlsub3_AddSub4_out1');
xlsub3_delay_sq1_out1 = delay_srl('delay_sq1', xlsub3_inport1, add_latency);
xlsub3_AddSub4_out1 = add('AddSub4', xlsub3_delay_sq1_out1, xlsub3_AddSub1_out1, 'latency', add_latency, 'full_precision', 0, 'type_ab', output_dtype);
fourth_central_moment = add('AddSub3', xlsub3_AddSub2_out1, xlsub3_AddSub4_out1, 'latency', add_latency', 'full_precision', 0, 'type_ab', output_dtype);
% 
% xlsub3_AddSub3 = xBlock(struct('source', 'AddSub', 'name', 'AddSub3'), ...
%     struct('latency', add_latency, ...
%     'precision', 'User Defined', ...
%     'arith_type', 'Signed  (2''s comp)', ...
%     'n_bits', 90, ...
%     'bin_pt', 68), ...
%     {xlsub3_AddSub2_out1, xlsub3_AddSub4_out1}, ...
%     {fourth_central_moment});

% Rescale output
fourth_central_moment_rounded.bind(scale('rescale_4th_moment', fourth_central_moment, -acc_len));

% block: untitled/kurtosis_moment_calc_init_xblock/kurtosis_num/AddSub4
% xlsub3_AddSub4 = xBlock(struct('source', 'AddSub', 'name', 'AddSub4'), ...
%     struct('latency', add_latency, ...
%     'precision', 'User Defined', ...
%     'arith_type', 'Signed  (2''s comp)', ...
%     'n_bits', 90, ...
%     'bin_pt', 68), ...
%     {xlsub3_delay_sq1_out1, xlsub3_AddSub1_out1}, ...
%     {xlsub3_AddSub4_out1});

xlsub3_sync_out.bind(delay_srl('sync_del', xlsub3_sync, 3*add_latency));
end

