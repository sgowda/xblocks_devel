function [x_sl] = slice_off_bottom(name, x, n_bits, varargin)

x_sl = xSignal();
xBlock(struct('source', 'Slice', 'name', name), ...
    struct('nbits', n_bits, 'mode', 'Lower Bit Location + Width'), ...
    {x}, {x_sl});