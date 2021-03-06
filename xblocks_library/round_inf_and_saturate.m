function [x_rounded] = round_inf_and_saturate(name, x, n_bits, bin_pt, varargin)
% Rounding to infinity with saturation
% [x_rounded] = round_inf_and_saturate(name, x, n_bits, bin_pt, varargin)
defaults = {'latency', 1};
latency = get_var('latency', 'defaults', defaults, varargin{:});

x_rounded = xSignal();
config.source = 'Convert';
config.name = name;
xlsub3_Convert = xBlock(config, ...
    struct('n_bits', n_bits, 'bin_pt', bin_pt, 'quantization', 'Round  (unbiased: +/- Inf)', ...
        'overflow', 'Saturate', 'latency', latency, 'Position', [400, 329, 445, 371]), ...
    {x}, ...
    {x_rounded});
