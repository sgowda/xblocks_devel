function [x_scaled] = scale(name, x, scale_factor)

x_scaled = xSignal();
config.source = 'Scale';
config.name = name;
xBlock(config, {'scale_factor', scale_factor}, {x}, {x_scaled});