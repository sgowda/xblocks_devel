function [x_rounded, x_rounded_dtype] = round_to_wordlength(name, x, n_bits, type_x, varargin)
% Rounding to infinity with saturation
% [x_rounded, x_rounded_dtype] = round_to_wordlength(name, x, n_bits, varargin)
defaults = {'latency', 1};
latency = get_var('latency', 'defaults', defaults, varargin{:});

x_rounded = xSignal();
config.source = 'Convert';
config.name = name;

% calculate binary point from
n_int_bits = type_x.WordLength - type_x.FractionLength;
bin_pt = n_bits - n_int_bits;
x_rounded_dtype = fi_dtype(type_x.Signed, n_bits, bin_pt);
xlsub3_Convert = xBlock(config, ...
    struct('n_bits', n_bits, 'bin_pt', bin_pt, 'quantization', 'Round  (unbiased: +/- Inf)', ...
        'overflow', 'Saturate', 'latency', latency, 'Position', [400, 329, 445, 371]), ...
    {x}, ...
    {x_rounded});
