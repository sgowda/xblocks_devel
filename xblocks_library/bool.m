function [x_rounded] = bool(name, x, varargin)
% cast number to boolean
% [x_rounded] = bool(name, x, n_bits, bin_pt, varargin)

defaults = {'latency', 0};
latency = get_var('latency', 'defaults', defaults, varargin{:});

x_rounded = xSignal();
config.source = 'Convert';
config.name = name;
xlsub3_Convert = xBlock(config, ...
    struct('arith_type', 'Boolean', 'Position', [400, 329, 445, 371]), ...
    {x}, ...
    {x_rounded});
