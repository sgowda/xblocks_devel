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
Mult4_out1 = xSignal('Mult4_out1');
cmult_conj2_out1 = xSignal('cmult_conj2_out1');
cmult_conj1_out1 = xSignal('cmult_conj1_out1');

%% diagram
Convert_out1 = trunc_and_wrap('Convert', square_cplx1_out1, 25, 22);
Convert1_out1 = trunc_and_wrap('Convert1', square_cplx1_out2, 25, 22);
Scale4_out1 = scale('Scale4', square_real1_out1, 2);
%Scale4_out1_rounded = 
outport2.bind(round_inf_and_saturate('Convert3', Scale4_out1, 94, 70, 'latency', 4));
%outport2.bind(Scale4_out1_rounded)

% block: untitled/kurtosis_moment_calc_init_xblock/kurtosis_cross_products/Convert4
outport8.bind(round_inf_and_saturate('Convert4', square_real1_out1, 94, 70, 'latency', 4));
%outport8.bind(square_real1_out1_rounded)

m_x = ri_to_c('ri_to_c_mx', m_x_re, m_x_im);
abs_m_x_sq = modulus_sq('abs_mx_sq', m_x, 'bit_width', 25, 'bin_pt', 24);
abs_m_x_sq_rounded = trunc_and_wrap('Convert5', abs_m_x_sq, 25, 22);

% block: untitled/kurtosis_moment_calc_init_xblock/kurtosis_cross_products/Mult4
del1_out1 = delay_srl('del1', inport1, 5);
Mult4 = xBlock(struct('source', 'Mult', 'name', 'Mult4'), ...
    struct('latency', 5), ...
    {abs_m_x_sq_rounded, del1_out1}, ...
    {Mult4_out1});

% block: untitled/kurtosis_moment_calc_init_xblock/kurtosis_cross_products/Scale
Scale_out1 = scale('Scale', cmult_conj2_out1, 2);

% block: untitled/kurtosis_moment_calc_init_xblock/kurtosis_cross_products/Scale1
outport4.bind(scale('Scale1', cmult_conj1_out1, 1));

% block: untitled/kurtosis_moment_calc_init_xblock/kurtosis_cross_products/Scale3
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

square_real1_sub = xBlock(struct('source', @xlsub3_square_real1, 'name', 'square_real1'), ...
    {}, ...
    {abs_m_x_sq_rounded}, ...
    {square_real1_out1});

end


function kurtosis_den()
acc_len = 2^14;
%% inports
sum_abs_x_sq = xInport('E[|X|^2]');
abs_m_x_sq = xInport('|m_x|^2');

%% outports
second_central_moment = xOutport('E[|X-m_x|^2]^2');

%% diagram

mean_abs_x_sq = xSignal();
xBlock(struct('source', 'Scale', 'name', 'scale'), ...
    {'scale_factor', -log2(acc_len)}, {sum_abs_x_sq}, {mean_abs_x_sq});

% block: untitled/kurtosis_moment_calc_init_xblock/kurtosis_den/AddSub
second_central_moment_unrounded = xSignal('xlsub3_AddSub_out1');
xlsub3_AddSub = xBlock(struct('source', 'AddSub', 'name', 'AddSub'), ...
    struct('mode', 'Subtraction', ...
    'latency', 4), ...
    {mean_abs_x_sq, abs_m_x_sq}, ...
    {second_central_moment_unrounded});

% block: untitled/kurtosis_moment_calc_init_xblock/kurtosis_den/square_real1
xlsub3_square_real1_sub = xBlock(struct('source', @xlsub3_square_real1, 'name', 'square_real1'), ...
    {}, ...
    {second_central_moment_unrounded}, ...
    {second_central_moment});

end

function xlsub3_square_real1()
n_int_bits = 5;

%% inports
xlsub4_a = xInport('a');

%% outports
xlsub4_outport1 = xOutport('a^2');

%% diagram

% block: untitled/kurtosis_moment_calc_init_xblock/kurtosis_den/square_real1/Convert
xlsub4_Convert_out1 = xSignal('xlsub4_Convert_out1');
xlsub4_Convert = xBlock(struct('source', 'Convert', 'name', 'Convert'), ...
    struct('n_bits', 35, ...
    'bin_pt', 35 - n_int_bits, ...
    'quantization', 'Round  (unbiased: +/- Inf)', ...
    'overflow', 'Saturate', ...
    'latency', 3), ...
    {xlsub4_a}, ...
    {xlsub4_Convert_out1});

% block: untitled/kurtosis_moment_calc_init_xblock/kurtosis_den/square_real1/Convert1
xlsub4_Convert1_out1 = xSignal('xlsub4_Convert1_out1');
xlsub4_Convert1 = xBlock(struct('source', 'Convert', 'name', 'Convert1'), ...
    struct('n_bits', 25, ...
    'bin_pt', 25 - n_int_bits, ...
    'quantization', 'Round  (unbiased: +/- Inf)', ...
    'overflow', 'Saturate', ...
    'latency', 3), ...
    {xlsub4_a}, ...
    {xlsub4_Convert1_out1});

% block: untitled/kurtosis_moment_calc_init_xblock/kurtosis_den/square_real1/Mult
xlsub4_Mult = xBlock(struct('source', 'Mult', 'name', 'Mult'), ...
    struct('latency', 5), ...
    {xlsub4_Convert_out1, xlsub4_Convert1_out1}, ...
    {xlsub4_outport1});



end



function kurtosis_num()
add_latency = 4;
acc_len = 14;


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
xlsub3_AddSub_out1 = xSignal('xlsub3_AddSub_out1');
xlsub3_AddSub = xBlock(struct('source', 'AddSub', 'name', 'AddSub'), ...
    struct('mode', 'Subtraction', ...
    'latency', add_latency, ...
    'precision', 'User Defined', ...
    'arith_type', 'Signed  (2''s comp)', ...
    'n_bits', 90, ...
    'bin_pt', 68), ...
    {xlsub3_inport7, xlsub3_inport2}, ...
    {xlsub3_AddSub_out1});

% block: untitled/kurtosis_moment_calc_init_xblock/kurtosis_num/AddSub1
xlsub3_AddSub1_out1 = xSignal('xlsub3_AddSub1_out1');
xlsub3_AddSub1 = xBlock(struct('source', 'AddSub', 'name', 'AddSub1'), ...
    struct('mode', 'Subtraction', ...
    'latency', add_latency, ...
    'precision', 'User Defined', ...
    'arith_type', 'Signed  (2''s comp)', ...
    'n_bits', 90, ...
    'bin_pt', 68, ...
    'use_behavioral_HDL', 'on', ...
    'hw_selection', 'DSP48', ...
    'pipelined', 'on'), ...
    {xlsub3_inport4, xlsub3_inport5}, ...
    {xlsub3_AddSub1_out1});

% block: untitled/kurtosis_moment_calc_init_xblock/kurtosis_num/AddSub2
% xlsub3_delay_sq8_out1 = xSignal('xlsub3_delay_sq8_out1');
xlsub3_delay_sq8_out1 = delay_srl('delay_sq8', xlsub3_inport3, add_latency);
xlsub3_AddSub2_out1 = xSignal('xlsub3_AddSub2_out1');
xlsub3_AddSub2 = xBlock(struct('source', 'AddSub', 'name', 'AddSub2'), ...
    struct('latency', add_latency, ...
    'precision', 'User Defined', ...
    'arith_type', 'Signed  (2''s comp)', ...
    'n_bits', 90, ...
    'bin_pt', 68), ...
    {xlsub3_AddSub_out1, xlsub3_delay_sq8_out1}, ...
    {xlsub3_AddSub2_out1});

% block: untitled/kurtosis_moment_calc_init_xblock/kurtosis_num/AddSub3
xlsub3_AddSub4_out1 = xSignal('xlsub3_AddSub4_out1');
xlsub3_AddSub3 = xBlock(struct('source', 'AddSub', 'name', 'AddSub3'), ...
    struct('latency', add_latency, ...
    'precision', 'User Defined', ...
    'arith_type', 'Signed  (2''s comp)', ...
    'n_bits', 90, ...
    'bin_pt', 68), ...
    {xlsub3_AddSub2_out1, xlsub3_AddSub4_out1}, ...
    {fourth_central_moment});

% Rescale output
fourth_central_moment_rounded.bind(scale('rescale_4th_moment', fourth_central_moment, -acc_len));

xlsub3_delay_sq1_out1 = delay_srl('delay_sq1', xlsub3_inport1, add_latency);

% block: untitled/kurtosis_moment_calc_init_xblock/kurtosis_num/AddSub4
xlsub3_AddSub4 = xBlock(struct('source', 'AddSub', 'name', 'AddSub4'), ...
    struct('latency', add_latency, ...
    'precision', 'User Defined', ...
    'arith_type', 'Signed  (2''s comp)', ...
    'n_bits', 90, ...
    'bin_pt', 68), ...
    {xlsub3_delay_sq1_out1, xlsub3_AddSub1_out1}, ...
    {xlsub3_AddSub4_out1});

xlsub3_sync_out.bind(delay_srl('sync_del', xlsub3_sync, 3*add_latency));
end

