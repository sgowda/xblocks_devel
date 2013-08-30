function [ab, ab_dtype] = mult_35x25_fi(name, a, b, varargin)
% [ab] = mult(name, a, b, varargin)

type_a_default = fi_dtype(1, 18, 17);
type_b_default = fi_dtype(1, 18, 17);
type_ab_default = fi_dtype(1, 36, 34);
defaults = {'mult_latency', 5, 'conv_latency', 3, 'type_a', type_a_default, 'type_b', type_b_default, ...
    'full_precision', 1, 'type_ab', type_ab_default, ...
    'quantization', 'Truncate', 'overflow', 'Wrap'};

mult_latency = get_var('mult_latency', 'defaults', defaults, varargin{:});
conv_latency = get_var('conv_latency', 'defaults', defaults, varargin{:});
type_a = get_var('type_a', 'defaults', defaults, varargin{:});
type_b = get_var('type_b', 'defaults', defaults, varargin{:});
full_precision = get_var('full_precision', 'defaults', defaults, varargin{:});
type_ab = get_var('type_ab', 'defaults', defaults, varargin{:});
quantization = get_var('quantization', 'defaults', defaults, varargin{:});
overflow = get_var('overflow', 'defaults', defaults, varargin{:});

[a_35bit, a_35bit_dtype] = round_to_wordlength_fi(sprintf('%s_conv_35bit', name), a, 35, type_a, 'latency', conv_latency);
[b_25bit, b_25bit_dtype] = round_to_wordlength_fi(sprintf('%s_conv_25bit', name), b, 25, type_b, 'latency', conv_latency);
[ab, ab_dtype] = mult_fi(name, a_35bit, b_25bit, 'type_a', a_35bit_dtype, 'type_b', b_25bit_dtype, 'latency', mult_latency, 'full_precision', full_precision, 'type_ab', type_ab, 'quantization', quantization, 'overflow', overflow);