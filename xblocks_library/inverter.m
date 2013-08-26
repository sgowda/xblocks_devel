function [x_inv] = inverter(name, x, varargin)
defaults = {'latency', 0};
latency = get_var('latency', 'defaults', defaults, varargin{:});

config.source = 'Inverter';
config.name = name;
x_inv = xSignal();
xBlock(config, {'latency', latency}, {x}, {x_inv});
