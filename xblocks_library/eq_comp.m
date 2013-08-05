function [a_eq_b] = eq_comp(name, a, b, varargin)
defaults = {'latency', 0};
latency = get_var('latency', 'defaults', defaults, varargin{:});

a_eq_b = xSignal();
config.name = name;
config.source = 'Relational';
xBlock(config, {'mode', 'a==b', 'latency', latency}, {a, b}, {a_eq_b});
