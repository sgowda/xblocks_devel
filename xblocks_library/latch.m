function [x_latch] = latch(name, x)

x_latch = xSignal();
xBlock(struct('source', 'Register', 'name', name), {'en', 'on'}, {x, x}, {x_latch});