function [val] = const(name, fl_val, dtype, varargin)
% function [val] = const(name, fl_val, dtype, varargin)

config.source = 'Constant';
config.name = name;
val = xSignal();

if dtype.Signed == 1
	arith_type = 'Signed (2''s comp)';
else
    arith_type = 'Unsigned';
end    

xBlock(config, ...
    {'const', fl_val, 'arith_type', arith_type, 'n_bits', ...
        n_bits(dtype), 'bin_pt', bin_pt(dtype), 'explicit_period', 'on'}, ...
    {}, {val});
