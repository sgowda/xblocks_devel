function [x_re, x_im] = c_to_ri(name, x, bit_width, bin_pt)
% [x_re, x_im] = c_to_ri(name, x, bit_width, bin_pt)
config.source = @c_to_ri_init_xblock;
config.name = name;
x_re = xSignal();
x_im = xSignal();
xBlock(config, {[], bit_width, bin_pt}, {x}, {x_re, x_im});

end