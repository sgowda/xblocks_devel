function acc_dsp48e_init_xblock(blk, varargin)
%% config
defaults = {'bin_pt', 17, 'input_bit_width', 18, 'max_accum', 5};
bin_pt = get_var('bin_pt', 'defaults', defaults, varargin{:});
input_bit_width = get_var('input_bit_width', 'defaults', defaults, varargin{:});
max_accum = get_var('max_accum', 'defaults', defaults, varargin{:});

if max_accum + input_bit_width <= 48
    use_48bit = 1;
elseif max_accum + input_bit_width <= 96
    use_96bit = 1;
else
    error('Maximum bit width is too large!')
end

%% inports
x = xInport('x');
en = xInport('en');

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
    rst_opmode = const('rst_opmode', 12, fi_dtype(0, 7, 0));
    opmode = mux_select('mux', en, {rst_opmode, acc_opmode});

    xBlock(struct('source', 'DSP48E', 'name', 'DSP48E_0'), ...
        struct('use_creg', 'on'), ...
        {a_input, b_input, x_int_sign_ext, opmode, alumode, carryin, carryinsel}, ...
        {sum_x_int});

    % Cast output 
    sum_x_sig = reinterpret('int_to_fixed', sum_x_int, fi_dtype(1, 48, bin_pt));
    sum_x.bind(sum_x_sig)
elseif use_96bit
    NotImplementedError();    
end

end