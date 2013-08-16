function [a_neq_b] = neq_comp(name, a, b, varargin)
% [a_eq_b] = neq_comp(name, a, b, varargin)
defaults = {'latency', 0};
latency = get_var('latency', 'defaults', defaults, varargin{:});

a_neq_b = xSignal();
config.name = name;
config.source = 'Relational';
xBlock(config, {'mode', 'a!=b', 'latency', latency}, {a, b}, {a_neq_b});
