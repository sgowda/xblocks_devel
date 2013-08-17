function [] = kurtosis_data_serializer_init_xblock(blk, varargin)
%% Configuration
defaults = {'n_inputs', 8, 'bit_width', 96, 'bin_pt', 68};
n_inputs = get_var('n_inputs', 'defaults', defaults, varargin{:});
bit_width = get_var('bit_width', 'defaults', defaults, varargin{:});
bin_pt = get_var('bin_pt', 'defaults', defaults, varargin{:});

%% Inports
load = xInport('load');
din = xblock_new_inputs('din', n_inputs, 1);

%% Outports
addr = xOutport('addr');
ser_data = xOutport('ser_data');
valid = xOutport('valid');

%% Diagram
shift = xSignal('shift');
sout = xSignal('sout');
addr_adv = xSignal();

% concatenate parallel inputs
pin = xCram(din(:,1)', 'pin_concat');

% instantiate pulse extender
xBlock(struct('name', 'pulse_ext', 'source', @pulse_ext_init_xblock), ...
    {[], 'pulse_len', n_inputs}, {load}, {shift});
valid.bind(shift)

% Parallel to serial converter
xBlock(struct('name', 'par_to_ser', 'source', 'casper_library_flow_control/parallel_to_serial_converter'), ...
    {'pin_width', bit_width*n_inputs, 'sout_width', bit_width}, ...
    {pin, load, shift}, {sout});

ser_data.bind(reinterpret('reinterp', sout, fi_dtype(1, bit_width, bin_pt)));

% addr counter
xBlock(struct('source', 'Counter', 'name', 'addr_counter'), ...
    {'rst', 'on', 'n_bits', ceil(log2(n_inputs))+1, 'bin_pt', 0}, {load}, {addr_adv});

addr.bind(delay_srl('addr_del', addr_adv, 1));
end