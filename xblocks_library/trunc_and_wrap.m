function [x_rounded] = trunc_and_wrap(name, x, n_bits, bin_pt, varargin)
% Truncation rounding with wrapping
% x_rounded] = trunc_and_wrap(name, x, n_bits, bin_pt, varargin)% 
defaults = {'latency', 0};
latency = get_var('latency', 'defaults', defaults, varargin{:});

x_rounded = xSignal();
config.source = 'Convert';
config.name = name;
xlsub3_Convert = xBlock(config, ...
    struct('n_bits', n_bits, 'bin_pt', bin_pt, 'quantization', 'Truncate', 'overflow', 'Wrap', 'latency', latency), ...
    {x}, ...
    {x_rounded});