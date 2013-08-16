function [x_reinterp] = reinterpret(name, x, dtype, varargin)
defaults = {'force_arith_type', 1, 'force_bin_pt', 1};
force_arith_type = get_var('force_arith_type', 'defaults', defaults, varargin{:});
force_bin_pt = get_var('force_bin_pt', 'defaults', defaults, varargin{:});

if force_bin_pt == 1
    force_bin_pt = 'on';
else
    force_bin_pt = 'off';
end

if force_arith_type == 1
    force_arith_type = 'on';
else
    force_arith_type = 'off';
end

if dtype.Signed == 1
    arith_type = 'Signed  (2''s comp)';
else
    arith_type = 'Unsigned';
end

config.name = name;
config.source = 'Reinterpret';
x_reinterp = xSignal();
xBlock(config, {'force_arith_type', force_arith_type, 'arith_type', arith_type, ...
    'force_bin_pt', force_bin_pt, 'bin_pt', dtype.FractionLength}, {x}, {x_reinterp});