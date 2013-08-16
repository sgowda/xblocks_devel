function [a_and_b] = and_gate(name, a, b, varargin)
% [a_and_b] = and_gate(name, a, b, varargin)

config.source = 'Logical';
config.name = name;
a_and_b = xSignal();
xBlock(config, {'logical_function', 'AND', 'Position', [460, 92, 490, 123]}, ...
    {a, b}, {a_and_b});
