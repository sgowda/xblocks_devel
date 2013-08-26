function [] = addsub_96bit_dsp48e_init_xblock(blk, varargin)
% Configure
defaults = {'bit_width_a', 60, 'bin_pt_a', 44, 'bit_width_b', 60, 'bin_pt_b', 22, 'mode', 'Addition'};
bit_width_a = get_var('bit_width_a', 'defaults', defaults, varargin{:});
bin_pt_a = get_var('bin_pt_a', 'defaults', defaults, varargin{:});
bit_width_b = get_var('bit_width_b', 'defaults', defaults, varargin{:});
bin_pt_b = get_var('bin_pt_b', 'defaults', defaults, varargin{:});
mode = get_var('mode', 'defaults', defaults, varargin{:});

%% Inports
a = xInport('a');
b = xInport('b');

%% Outports
if strcmp(mode, 'Addition')
    out = xOutport('a+b');
    alumode_str = '0000';
elseif strcmp(mode, 'Subtraction')
    out = xOutport('a-b');
    alumode_str = '0011';
else
    error('Unknown mode:%s', mode)
end

a_dtype = fi_dtype(1, bit_width_a, bin_pt_a);
b_dtype = fi_dtype(1, bit_width_b, bin_pt_b);
ab_dtype = a_dtype + b_dtype;

if ab_dtype.WordLength > 96
    error('Summand is too large for 96-bit adder!')
end

%% Diagram

[opmode0, alumode0, carryin0, carryinsel0] = dsp48e_ctrl('ctrl0', '0110011', alumode_str, '0', '000');
[opmode1, alumode1, carryin1, carryinsel1] = dsp48e_ctrl('ctrl1', '0110011', alumode_str, '0', '010');

%-- input preprocessing
% extend to 96 bits
a_ext = trunc_and_wrap('a_ext', a, 96, bin_pt_a);
b_ext = trunc_and_wrap('b_ext', b, 96, bin_pt_a);

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
sum_96bit = reinterpret('sum_reinterp', sum_int, ab_dtype);
sum_sig = trunc_and_wrap('sum_trunc', sum_96bit, ab_dtype.WordLength, ab_dtype.FractionLength);

out.bind(sum_sig);

end
