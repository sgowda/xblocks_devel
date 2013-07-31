function [x_delay] = delay_srl(name, x, latency)

x_delay = xSignal();
config.source = 'Delay';
config.name = name;
xBlock(config, {'latency', latency}, {x}, {x_delay});
