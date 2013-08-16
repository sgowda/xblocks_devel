function [abs_x_sq] = modulus_sq(name, x, varargin)
% [abs_x_sq] = modulus_sq(name, x, varargin)

defaults = {'bit_width', 18, 'bin_pt', 17, 'add_latency', 2, 'mult_latency', 3};
bit_width = get_var('bit_width', 'defaults', defaults, varargin{:});
bin_pt = get_var('bin_pt', 'defaults', defaults, varargin{:});
add_latency = get_var('add_latency', 'defaults', defaults, varargin{:});
mult_latency = get_var('mult_latency', 'defaults', defaults, varargin{:});

config.source = @power_behav_init_xblock;
config.name = name;
abs_x_sq = xSignal();
xBlock(config, {[], 'bit_width', bit_width, 'bin_pt', bin_pt, ...
    'add_latency', add_latency, 'mult_latency', mult_latency}, ...
    {x}, {abs_x_sq});

end