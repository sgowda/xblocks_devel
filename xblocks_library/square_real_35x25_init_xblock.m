function square_real_35x25_init_xblock(blk, varargin)
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