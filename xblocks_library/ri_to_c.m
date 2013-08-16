function [x] = ri_to_c(name, x_re, x_im)

config.source = @ri_to_c_init_xblock;
config.name = name;
x = xSignal();
xBlock(config, {[]}, {x_re, x_im}, {x});

end