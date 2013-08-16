function [x_delay] = delay_srl(name, x, latency)
% [x_delay] = delay_srl(name, x, latency)

x_delay = xSignal();
config.source = 'Delay';
config.name = name;
xBlock(config, {'latency', latency, 'Position', [420, 264, 455, 296]}, {x}, {x_delay});
