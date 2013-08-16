function [x_scaled, x_scaled_dtype] = scale(name, x, scale_factor, varargin)
defaults = {'type_x', fi_dtype(1, 18, 17)};
type_x = get_var('type_x', 'defaults', defaults, varargin{:});
x_scaled_dtype = fi_dtype(type_x.Signed, type_x.WordLength, type_x.FractionLength - scale_factor);

x_scaled = xSignal();
config.source = 'Scale';
config.name = name;
xBlock(config, {'scale_factor', scale_factor, 'Position', [420, 264, 455, 296]}, {x}, {x_scaled});
