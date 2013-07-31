function [ab] = subtract(name, a, b, varargin)

type_a_default = fi_dtype(1, 18, 17);
type_b_default = fi_dtype(1, 18, 17);
type_ab_default = fi_dtype(1, 36, 34);
defaults = {'latency', 3, 'type_a', type_a_default, 'type_b', type_b_default, ...
    'full_precision', 1, 'type_ab', type_ab_default, ...
    'quantization', 'Truncate', 'overflow', 'Wrap'};

latency = get_var('latency', 'defaults', defaults, varargin{:});
type_a = get_var('type_a', 'defaults', defaults, varargin{:});
type_b = get_var('type_b', 'defaults', defaults, varargin{:});
full_precision = get_var('full_precision', 'defaults', defaults, varargin{:});
type_ab = get_var('type_ab', 'defaults', defaults, varargin{:});
quantization = get_var('quantization', 'defaults', defaults, varargin{:});
overflow = get_var('overflow', 'defaults', defaults, varargin{:});

% derived parameters
if full_precision == 0
    precision = 'User Defined';
else
    precision = 'Full';
end

if (type_a.Signed || type_b.Signed)
    arith_type = 'Signed';
else
    arith_type = 'Unsigned';
end

mode = 'Subtraction';

% block instantiation
config.source = 'AddSub';
config.name = name;
ab = xSignal();
xBlock(config, {'mode', mode, 'latency', latency, 'precision', precision, 'arith_type', arith_type, ...
    'n_bits', type_ab.WordLength, 'bin_pt', type_ab.FractionLength, ...
    'quantization', quantization, 'overflow', overflow}, ...
    {a, b}, {ab});
