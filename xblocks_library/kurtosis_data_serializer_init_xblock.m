function [] = kurtosis_data_serializer_init_xblock(blk, varargin)
%% Configuration
defaults = {'n_inputs', 8, 'bit_width', 96, 'bin_pt', 68};
n_inputs = get_var('n_inputs', 'defaults', defaults, varargin{:});
bit_width = get_var('bit_width', 'defaults', defaults, varargin{:});
bin_pt = get_var('bin_pt', 'defaults', defaults, varargin{:});

%% Inports
load = xInport('load');
din = xblock_new_inputs('din', 8,1);

%% Outports
addr = xOutport('addr');
ser_data = xOutport('ser_data');
valid = xOutport('valid');

%% Diagram
shift = xSignal('shift');
sout = xSignal('sout');

% concatenate parallel inputs
pin = xCram(din(:,1)', 'pin_concat');

% instantiate pulse extender
xBlock(struct('name', 'pulse_ext', 'source', @pulse_ext), ...
    {[], 'pulse_len', n_inputs}, {load}, {shift});
valid.bind(shift)

% Parallel to serial converter
xBlock(struct('name', 'par_to_ser', 'source', 'casper_library_flow_control/parallel_to_serial_converter'), ...
    {'pin_width', bit_width*n_inputs, 'sout_width', bit_width}, ...
    {pin, load, shift}, {sout});

ser_data.bind(reinterpret('reinterp', sout, fi_dtype(1, bit_width, bin_pt)));

% addr counter
xBlock(struct('source', 'Counter', 'name', 'addr_counter'), ...
    {'rst', 'on', 'n_bits', 4, 'bin_pt', 0}, {load}, {addr});
end

function pulse_ext(blk, varargin)
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

% block: kurtosis_detector_serialization/pulse_ext/Relational
% Relational = xBlock(struct('source', 'Relational', 'name', 'Relational'), ...
%     struct('mode', 'a<b'), ...
%     {Counter_out1, Constant8_out1}, ...
%     {Relational_out1});

% block: kurtosis_detector_serialization/pulse_ext/Relational1
% Relational1 = xBlock(struct('source', 'Relational', 'name', 'Relational1'), ...
%     struct('mode', 'a<=b'), ...
%     {Counter_out1, Constant10_out1}, ...
%     {Relational1_out1});
Relational1_out1.bind(le_comp('Relational1', Counter_out1, Constant10_out1, 'latency', 0));

% block: kurtosis_detector_serialization/pulse_ext/Relational2
% Relational2 = xBlock(struct('source', 'Relational', 'name', 'Relational2'), ...
%     struct('mode', 'a>=b'), ...
%     {Counter_out1, Constant9_out1}, ...
%     {Relational2_out1});
Relational2_out1.bind(ge_comp('Relational2', Counter_out1, Constant9_out1, 'latency', 0));
end
