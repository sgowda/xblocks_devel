function kurtosis_acc_rounding_init_xblock(blk, varargin)
defaults = {'acc_len', 14};
acc_len = get_var('acc_len', 'defaults', defaults, varargin{:});
conv_latency = 5;

%% inports
sync = xInport('sync');
x_acc_re = xInport('x_acc_re');
x_acc_im = xInport('x_acc_im');
In4 = xInport('In4');
In5 = xInport('In5');
In6 = xInport('In6');
In7 = xInport('In7');
In8 = xInport('In8');
In9 = xInport('In9');

%% outports
sync_out = xOutport('sync_out');
Out2 = xOutport('Out2');
Out3 = xOutport('Out3');
Out4 = xOutport('Out4');
Out5 = xOutport('Out5');
Out6 = xOutport('Out6');
Out7 = xOutport('Out7');
Out8 = xOutport('Out8');
Out9 = xOutport('Out9');

%% diagram

% block: kurtosis_moment_calc/kurtosis_acc_rounding_init_xblock/Convert10
bit_sl6_out1 = xSignal('bit_sl6_out1');
% Convert10 = xBlock(struct('source', 'Convert', 'name', 'Convert10'), ...
%     struct('n_bits', 35, ...
%     'bin_pt', 35-19, ...
%     'quantization', 'Round  (unbiased: +/- Inf)', ...
%     'overflow', 'Saturate', ...
%     'latency', 5), ...
%     {bit_sl6_out1}, ...
%     {Out8});
Out8.bind(round_inf_and_saturate('Convert10', bit_sl6_out1, 35, 35-19, 'latency', 5));

% block: kurtosis_moment_calc/kurtosis_acc_rounding_init_xblock/Convert11
bit_sl7_out1 = xSignal('bit_sl7_out1');
% Convert11 = xBlock(struct('source', 'Convert', 'name', 'Convert11'), ...
%     struct('n_bits', 35, ...
%     'bin_pt', 35-19, ...
%     'quantization', 'Round  (unbiased: +/- Inf)', ...
%     'overflow', 'Saturate', ...
%     'latency', 5), ...
%     {bit_sl7_out1}, ...
%     {Out9});
Out9.bind(round_inf_and_saturate('Convert11', bit_sl7_out1, 35, 35-19, 'latency', 5));

% block: kurtosis_moment_calc/kurtosis_acc_rounding_init_xblock/Convert12
bit_sl5_out1 = xSignal('bit_sl5_out1');
% Convert12 = xBlock(struct('source', 'Convert', 'name', 'Convert12'), ...
%     struct('n_bits', 74+14, ...
%     'bin_pt', 68, ...
%     'quantization', 'Round  (unbiased: +/- Inf)', ...
%     'overflow', 'Saturate', ...
%     'latency', 5), ...
%     {bit_sl5_out1}, ...
%     {Out7});
Out7.bind(round_inf_and_saturate('Convert12', bit_sl5_out1, 74+14, 68, 'latency', 5));

% block: kurtosis_moment_calc/kurtosis_acc_rounding_init_xblock/Convert5
bit_sl_out1 = xSignal('bit_sl_out1');
% Convert5 = xBlock(struct('source', 'Convert', 'name', 'Convert5'), ...
%     struct('n_bits', 25, ...
%     'bin_pt', 24, ...
%     'quantization', 'Round  (unbiased: +/- Inf)', ...
%     'overflow', 'Saturate', ...
%     'latency', 5), ...
%     {bit_sl_out1}, ...
%     {Out2});
Out2.bind(round_inf_and_saturate('Convert5', bit_sl_out1, 25, 24, 'latency', 5));

% block: kurtosis_moment_calc/kurtosis_acc_rounding_init_xblock/Convert6
bit_sl1_out1 = xSignal('bit_sl1_out1');
% Convert6 = xBlock(struct('source', 'Convert', 'name', 'Convert6'), ...
%     struct('n_bits', 25, ...
%     'bin_pt', 24, ...
%     'quantization', 'Round  (unbiased: +/- Inf)', ...
%     'overflow', 'Saturate', ...
%     'latency', 5), ...
%     {bit_sl1_out1}, ...
%     {Out3});
Out3.bind(round_inf_and_saturate('Convert6', bit_sl1_out1, 25, 24, 'latency', 5));

% block: kurtosis_moment_calc/kurtosis_acc_rounding_init_xblock/Convert7
bit_sl2_out1 = xSignal('bit_sl2_out1');
% Convert7 = xBlock(struct('source', 'Convert', 'name', 'Convert7'), ...
%     struct('n_bits', 35, ...
%     'bin_pt', 35-18, ...
%     'quantization', 'Round  (unbiased: +/- Inf)', ...
%     'overflow', 'Saturate', ...
%     'latency', 5), ...
%     {bit_sl2_out1}, ...
%     {Out4});
Out4.bind(round_inf_and_saturate('Convert7', bit_sl2_out1, 35, 35-18, 'latency', 5));

% block: kurtosis_moment_calc/kurtosis_acc_rounding_init_xblock/Convert8
bit_sl3_out1 = xSignal('bit_sl3_out1');
% Convert8 = xBlock(struct('source', 'Convert', 'name', 'Convert8'), ...
%     struct('n_bits', 35, ...
%     'bin_pt', 35-18, ...
%     'quantization', 'Round  (unbiased: +/- Inf)', ...
%     'overflow', 'Saturate', ...
%     'latency', 5), ...
%     {bit_sl3_out1}, ...
%     {Out5});
Out5.bind(round_inf_and_saturate('Convert8', bit_sl3_out1, 35, 35-18, 'latency', 5));

% block: kurtosis_moment_calc/kurtosis_acc_rounding_init_xblock/Convert9
bit_sl4_out1 = xSignal('bit_sl4_out1');
% Convert9 = xBlock(struct('source', 'Convert', 'name', 'Convert9'), ...
%     struct('n_bits', 35, ...
%     'bin_pt', 35-18, ...
%     'quantization', 'Round  (unbiased: +/- Inf)', ...
%     'overflow', 'Saturate', ...
%     'latency', 5), ...
%     {bit_sl4_out1}, ...
%     {Out6});
Out6.bind(round_inf_and_saturate('Convert9', bit_sl4_out1, 35, 35-18, 'latency', 5));

% block: kurtosis_moment_calc/kurtosis_acc_rounding_init_xblock/Scale
% Scale_out1 = xSignal('Scale_out1');
% Scale = xBlock(struct('source', 'Scale', 'name', 'Scale'), ...
%     struct('scale_factor', -14), ...
%     {x_acc_re}, ...
%     {Scale_out1});
m_x_re = scale('Scale', x_acc_re, -acc_len);
% block: kurtosis_moment_calc/kurtosis_acc_rounding_init_xblock/Scale1
% Scale1_out1 = xSignal('Scale1_out1');
% Scale1 = xBlock(struct('source', 'Scale', 'name', 'Scale1'), ...
%     struct('scale_factor', -14), ...
%     {x_acc_im}, ...
%     {Scale1_out1});
m_x_im = scale('Scale1', x_acc_im, -acc_len);

% block: kurtosis_moment_calc/kurtosis_acc_rounding_init_xblock/bit_sl
bit_sl = xBlock(struct('source', 'Convert', 'name', 'bit_sl'), ...
    struct('n_bits', 32, ...
    'bin_pt', 31), ...
    {m_x_re}, ...
    {bit_sl_out1});

% block: kurtosis_moment_calc/kurtosis_acc_rounding_init_xblock/bit_sl1
bit_sl1 = xBlock(struct('source', 'Convert', 'name', 'bit_sl1'), ...
    struct('n_bits', 32, ...
    'bin_pt', 31), ...
    {m_x_im}, ...
    {bit_sl1_out1});

% block: kurtosis_moment_calc/kurtosis_acc_rounding_init_xblock/bit_sl2
bit_sl2 = xBlock(struct('source', 'Convert', 'name', 'bit_sl2'), ...
    struct('n_bits', 37+14, ...
    'bin_pt', 34), ...
    {In4}, ...
    {bit_sl2_out1});

% block: kurtosis_moment_calc/kurtosis_acc_rounding_init_xblock/bit_sl3
bit_sl3 = xBlock(struct('source', 'Convert', 'name', 'bit_sl3'), ...
    struct('n_bits', 37+14, ...
    'bin_pt', 34), ...
    {In5}, ...
    {bit_sl3_out1});

% block: kurtosis_moment_calc/kurtosis_acc_rounding_init_xblock/bit_sl4
bit_sl4 = xBlock(struct('source', 'Convert', 'name', 'bit_sl4'), ...
    struct('n_bits', 37+14, ...
    'bin_pt', 34), ...
    {In6}, ...
    {bit_sl4_out1});

% block: kurtosis_moment_calc/kurtosis_acc_rounding_init_xblock/bit_sl5
bit_sl5 = xBlock(struct('source', 'Convert', 'name', 'bit_sl5'), ...
    struct('n_bits', 74+14, ...
    'bin_pt', 68), ...
    {In7}, ...
    {bit_sl5_out1});

% block: kurtosis_moment_calc/kurtosis_acc_rounding_init_xblock/bit_sl6
bit_sl6 = xBlock(struct('source', 'Convert', 'name', 'bit_sl6'), ...
    struct('n_bits', 55+14, ...
    'bin_pt', 51), ...
    {In8}, ...
    {bit_sl6_out1});

% block: kurtosis_moment_calc/kurtosis_acc_rounding_init_xblock/bit_sl7
bit_sl7 = xBlock(struct('source', 'Convert', 'name', 'bit_sl7'), ...
    struct('n_bits', 55+14, ...
    'bin_pt', 51), ...
    {In9}, ...
    {bit_sl7_out1});

% block: kurtosis_moment_calc/kurtosis_acc_rounding_init_xblock/cast_delay
% cast_delay = xBlock(struct('source', 'Delay', 'name', 'cast_delay'), ...
%     struct('latency', 5), ...
%     {sync}, ...
%     {sync_out});

sync_out.bind(delay_srl('cast_delay', sync, conv_latency));

end

