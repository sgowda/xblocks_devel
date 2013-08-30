function [x_rounded] = trunc_and_wrap_fi(name, x, n_bits, bin_pt, varargin)
defaults = {'logging', 1};
logging = get_var('logging', 'defaults', defaults, varargin{:});

quantizer = fixed.Quantizer('WordLength', n_bits, ...
    'FractionLength', bin_pt, ...
    'RoundingMethod', 'Floor', 'OverflowAction', 'wrap');

x_rounded = quantize(quantizer, x);
if logging
    orig_bitwidth = x.WordLength;
    new_bitwidth = x_rounded.WordLength;
    log_rounding(name, orig_bitwidth, new_bitwidth, double(x_rounded) - double(x));
end

end
