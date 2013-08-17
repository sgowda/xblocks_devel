function pulse_ext_init_xblock(blk, varargin)
%% Config
defaults = {'pulse_len', 8};
pulse_len = get_var('pulse_len', 'defaults', defaults, varargin{:});

n_bits = ceil(log2(pulse_len)) + 1;

%% inports
ld = xInport('ld');

%% outports
shift = xOutport('shift');

%% diagram
Relational2_out1 = xSignal('Relational2_out1');
Relational1_out1 = xSignal('Relational1_out1');
Relational_out1 = xSignal('Relational_out1');

Constant10_out1 = const('Constant10', pulse_len, fi_dtype(0, n_bits, 0));
Constant8_out1 = const('Constant8', 2^n_bits-1, fi_dtype(0, n_bits, 0));
Constant9_out1 = const('Constant9', 1, fi_dtype(0, n_bits, 0));

Logical1_out1 = or_gate('or', ld, Relational_out1);

Counter_out1 = xSignal('Counter_out1');
Counter = xBlock(struct('source', 'Counter', 'name', 'Counter'), ...
    struct('n_bits', 4, ...
    'rst', 'on', ...
    'en', 'on'), ...
    {ld, Logical1_out1}, ...
    {Counter_out1});

shift.bind(and_gate('and', Relational2_out1, Relational1_out1));
Relational_out1.bind(lt_comp('Relational', Counter_out1, Constant8_out1, 'latency', 0));
Relational1_out1.bind(le_comp('Relational1', Counter_out1, Constant10_out1, 'latency', 0));
Relational2_out1.bind(ge_comp('Relational2', Counter_out1, Constant9_out1, 'latency', 0));
end