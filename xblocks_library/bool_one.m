function [x] = bool_one(name)

x = xSignal();
xBlock(struct('source', 'Constant', 'name', name), {'const', 1, ...
    'arith_type', 'Boolean', 'explicit_period', 'on', 'period', 1}, {}, {x});
