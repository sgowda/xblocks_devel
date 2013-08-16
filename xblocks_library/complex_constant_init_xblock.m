function [] = complex_constant_init_xblock(blk, varargin)

defaults = {'arith_type', 'Signed (2''s comp)', 'bit_width', 18, 'bin_pt', 17, 'value', 1+0j};
arith_type = get_var('arith_type', 'defaults', defaults, varargin{:});
bit_width = get_var('bit_width', 'defaults', defaults, varargin{:});
bin_pt = get_var('bin_pt', 'defaults', defaults, varargin{:});
const_value = get_var('value', 'defaults', defaults, varargin{:});

out = xOutport('out');

real_sig = xSignal();
imag_sig = xSignal();

imag_value = imag(const_value);
real_value = real(const_value);
 
xBlock(struct('name', 'imag_const', 'source', 'Constant'), ...
    {'const', imag_value, 'arith_type', arith_type, 'n_bits', bit_width, ...
     'bin_pt', bin_pt}, {}, {imag_sig});

xBlock(struct('name', 'real_const', 'source', 'Constant'), ...
    {'const', real_value, 'arith_type', arith_type, 'n_bits', bit_width, ...
     'bin_pt', bin_pt}, {}, {real_sig});

 
xBlock(struct('name', 'ri_to_c', 'source', 'ri_to_c_init_xblock'), ...
    {}, {real_sig, imag_sig}, {out});

end