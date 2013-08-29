function acc_dsp48e_init_xblock(blk, varargin)
%% config
defaults = {'bin_pt', 17, 'input_bit_width', 18, 'max_accum', 5};
bin_pt = get_var('bin_pt', 'defaults', defaults, varargin{:});
input_bit_width = get_var('input_bit_width', 'defaults', defaults, varargin{:});
max_accum = get_var('max_accum', 'defaults', defaults, varargin{:});

if max_accum + input_bit_width <= 48
    use_48bit = 1;
    use_96bit = 0;
elseif max_accum + input_bit_width <= 96
    use_48bit = 0;
    use_96bit = 1;
else
    error('Maximum bit width is too large!')
end

sum_dtype = fi_dtype(1, max_accum + input_bit_width, bin_pt);
%% inports
en = xInport('en');
x = xInport('x');

%% outports
sum_x = xOutport('sum_x');

%% diagram
if use_48bit
    a_input = xSignal();
    b_input = xSignal();
    sum_x_int = xSignal();

    zero = const('zero', 0, fi_dtype(1, 48, 0));
    xBlock(struct('source', @dsp48e_AB_splitter_init_xblock, 'name', 'AB_splitter0'), ...
        {}, {zero}, {a_input, b_input});

    % sign-extend the input
    x_sign_ext = trunc_and_wrap('sign_ext', x, 48, bin_pt);
    x_int_sign_ext = reinterp_int('reinterp', x_sign_ext);                        

    % configure select lines for internal muxes
    [acc_opmode, alumode, carryin, carryinsel] = dsp48e_ctrl('ctrl0', '0101100', '0000', '0', '000');
    rst_opmode = const('rst_opmode', bin2dec('0001100'), fi_dtype(0, 7, 0));
    opmode = mux_select('mux', en, {rst_opmode, acc_opmode});

    xBlock(struct('source', 'DSP48E', 'name', 'DSP48E_0'), ...
        struct('use_creg', 'on'), ...
        {a_input, b_input, x_int_sign_ext, opmode, alumode, carryin, carryinsel}, ...
        {sum_x_int});

    % Cast output 
    sum_x_sig = reinterpret('int_to_fixed', sum_x_int, fi_dtype(1, 48, bin_pt));
    sum_x_sig = trunc_and_wrap('sum_trunc', sum_x_sig, sum_dtype.WordLength, sum_dtype.FractionLength);
    sum_x.bind(sum_x_sig)
elseif use_96bit
    % switch AB input to 0
    [add_opmode0, alumode0, carryin0, carryinsel0] = dsp48e_ctrl('ctrl0', '0101100', '0000', '0', '000');
    [add_opmode1, alumode1, carryin1, carryinsel1] = dsp48e_ctrl('ctrl1', '0101100', '0000', '0', '010');
    rst_opmode0 = const('rst_optmode0', bin2dec('0001100'), fi_dtype(0, 7, 0));
    rst_opmode1 = const('rst_optmode1', bin2dec('0001100'), fi_dtype(0, 7, 0));
    opmode0 = mux_select('sel_op0', en, {rst_opmode0, add_opmode0});
    opmode1 = mux_select('sel_op1', en, {rst_opmode1, add_opmode1}, 'latency', 1);

    %-- input preprocessing
    % extend to 96 bits
    a_ext = trunc_and_wrap('a_ext', x, 96, bin_pt);
    b_ext = const('zero', 0, fi_dtype(1, 96, 0)); %trunc_and_wrap('b_ext', b, 96, bin_pt_a);

    % split summands into 48-bit segments
    a_bus = slice_partition('sl_a', a_ext, [48, 48]);
    b_bus = slice_partition('sl_b', b_ext, [18, 30, 18, 30]);

    % 'a' input goes into dsp48e.c port, 'b' input goes into AB port
    b0 = reinterp_int('int0', b_bus{1});
    a0 = reinterp_int('int2', b_bus{2});
    b1 = reinterp_int('int3', b_bus{3});
    a1 = reinterp_int('int4', b_bus{4});

    c0 = reinterp_int('int5', a_bus{1});
    c1 = reinterp_int('int6', delay_srl('del1', a_bus{2}, 1));

    sum_msb = xSignal();
    sum_lsb = xSignal();
    lsb_carryout = xSignal();

    % Draw DSP48E slices
    config.source = 'DSP48E';
    config.name = 'DSP48E_0';
    xBlock(config, {'use_creg', 'on', 'pipeline_a', 1, 'pipeline_b', 1, 'use_carrycascout', 'on'}, ...
        {a0, b0, c0, opmode0, alumode0, carryin0, carryinsel0}, {sum_lsb, lsb_carryout});

    config.name = 'DSP48E_1';
    xBlock(config, {'use_creg', 'on', 'pipeline_a', 2, 'pipeline_b', 2, 'use_carrycascin', 'on'}, ...
        {a1, b1, c1, opmode1, alumode1, carryin1, carryinsel1, lsb_carryout}, {sum_msb});

    % post-process output
    % delay to match higher msb latency due to carry chain
    sum_lsb = delay_srl('del2', sum_lsb, 1);
    sum_msb_uint = reinterp_uint('uint0', sum_msb);
    sum_lsb_uint = reinterp_uint('uint1', sum_lsb);
    sum_int = concatenate('sum_concat', {sum_msb_uint, sum_lsb_uint});
    sum_96bit = reinterpret('sum_reinterp', sum_int, sum_dtype);
    sum_sig = trunc_and_wrap('sum_trunc', sum_96bit, sum_dtype.WordLength, sum_dtype.FractionLength);    
    
    sum_x.bind(sum_sig)
end

end







