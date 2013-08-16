function [a_or_b] = or_gate(name, a, b, varargin)
% [a_or_b] = or_gate(name, a, b, varargin)

config.source = 'Logical';
config.name = name;
a_or_b = xSignal();
xBlock(config, {'logical_function', 'OR', 'Position', [460, 92, 490, 123]}, ...
    {a, b}, {a_or_b});
