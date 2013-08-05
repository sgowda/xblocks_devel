function [a_ge_b] = ge_comp(name, a, b, varargin)
defaults = {'latency', 0};
latency = get_var('latency', 'defaults', defaults, varargin{:});

a_ge_b = xSignal();
config.name = name;
config.source = 'Relational';
xBlock(config, {'mode', 'a>=b', 'latency', latency}, {a, b}, {a_ge_b});
