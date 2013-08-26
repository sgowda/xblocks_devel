function pulse_ext_init_xblock(blk, varargin)
%% Config
defaults = {'pulse_len', 8};
pulse_len = get_var('pulse_len', 'defaults', defaults, varargin{:});

n_bits = ceil(log2(pulse_len)) + 1;

%% inports
sync = xInport('sync');

%% outports
pulse = xOutport('pulse');

%% diagram
count_less_than_max = xSignal();
count_greater_than_1 = xSignal();
count_less_than_pulse_len = xSignal();
count = xSignal();

% comparison constants
pulse_len = const('Constant10', pulse_len, fi_dtype(0, n_bits, 0));
counter_max = const('Constant8', 2^n_bits-1, fi_dtype(0, n_bits, 0));
one = const('Constant9', 1, fi_dtype(0, n_bits, 0));

% counter enable
sync_latch = latch('sync_latch', sync);
en = or_gate('or', sync, count_less_than_max);
count_en = and_gate('and1', sync_latch, en);

% counter
xBlock(struct('source', 'Counter', 'name', 'Counter'), ...
    struct('n_bits', n_bits, 'rst', 'on', 'en', 'on'), ...
    {sync, count_en}, {count});

% comparators
count_less_than_max.bind(lt_comp('Relational', count, counter_max, 'latency', 0));
count_less_than_pulse_len.bind(le_comp('Relational1', count, pulse_len, 'latency', 0));
count_greater_than_1.bind(ge_comp('Relational2', count, one, 'latency', 0));

% output
pulse.bind(and_gate('and', count_greater_than_1, count_less_than_pulse_len));
end