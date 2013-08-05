function [a_lt_b] = lt_comp(name, a, b, varargin)
defaults = {'latency', 0};
latency = get_var('latency', 'defaults', defaults, varargin{:});

a_lt_b = xSignal();
config.name = name;
config.source = 'Relational';
xBlock(config, {'mode', 'a<b', 'latency', latency}, {a, b}, {a_lt_b});
