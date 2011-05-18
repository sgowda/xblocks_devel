function fft_stage_n_init_xblock(varargin)
defaults = { ...
    'FFTSize', 3, ...
    'FFTStage', 1, ...
    'input_bit_width', 18, ...
    'coeff_bit_width', 18, ...
    'coeffs_bram', 'off', ...
    'delays_bram', 'off', ...
    'quantization', 'Round  (unbiased: +/- Inf)', ...
    'overflow', 'Saturate', ...
    'add_latency', 2, ...
    'mult_latency', 3, ...
    'bram_latency', 2, ...
    'conv_latency', 1, ...
    'arch', 'Virtex5', ...
    'opt_target', 'logic', ...
    'use_hdl', 'off', ...
    'use_embedded', 'on', ...
    'hardcode_shifts', 'off', ...
    'downshift', 'off', ...
    'dsp48_adders', 'on', ...
};

% Retrieve values from mask fields.
FFTSize = get_var('FFTSize', 'defaults', defaults, varargin{:});
FFTStage = get_var('FFTStage', 'defaults', defaults, varargin{:});
input_bit_width = get_var('input_bit_width', 'defaults', defaults, varargin{:});
coeff_bit_width = get_var('coeff_bit_width', 'defaults', defaults, varargin{:});
coeffs_bram = get_var('coeffs_bram', 'defaults', defaults, varargin{:});
delays_bram = get_var('delays_bram', 'defaults', defaults, varargin{:});
quantization = get_var('quantization', 'defaults', defaults, varargin{:});
overflow = get_var('overflow', 'defaults', defaults, varargin{:});
add_latency = get_var('add_latency', 'defaults', defaults, varargin{:});
mult_latency = get_var('mult_latency', 'defaults', defaults, varargin{:});
bram_latency = get_var('bram_latency', 'defaults', defaults, varargin{:});
conv_latency = get_var('conv_latency', 'defaults', defaults, varargin{:});
arch = get_var('arch', 'defaults', defaults, varargin{:});
opt_target = get_var('opt_target', 'defaults', defaults, varargin{:});
use_hdl = get_var('use_hdl', 'defaults', defaults, varargin{:});
use_embedded = get_var('use_embedded', 'defaults', defaults, varargin{:});
hardcode_shifts = get_var('hardcode_shifts', 'defaults', defaults, varargin{:});
downshift = get_var('downshift', 'defaults', defaults, varargin{:});
dsp48_adders = get_var('dsp48_adders', 'defaults', defaults, varargin{:});

%% inports
in1 = xInport('in1');
in2 = xInport('in2');
of_in = xInport('of_in');
sync = xInport('sync');
shift = xInport('shift');

%% outports
out1 = xOutport('out1');
out2 = xOutport('out2');
of = xOutport('of');
sync_out = xOutport('sync_out');

%% diagram



%flag error and over-ride if trying to use BRAMs but delay is less than BRAM latency
if (2^(FFTSize-FFTStage) < bram_latency)
    if strcmp(delays_bram,'on')
        disp('fft_stage_n_init: using BRAMs for delays but BRAM latency larger than delay! Forcing use of distributed RAM.');
    end
    delays_bram = 'off';
end





if(FFTStage == 1 ),
    Coeffs = 0;
else
    Coeffs = 0:2^(FFTStage-1)-1;
end
StepPeriod = FFTSize-FFTStage;

% block: untitled2/fft_stage_n_init_xblock/Counter
Counter_out1 = xSignal;
Counter = xBlock(struct('source', 'Counter', 'name', 'Counter'), ...
                        struct('n_bits', FFTSize-FFTStage+1, ...
                               'rst', 'on', ...
                               'explicit_period', 'off', ...
                               'use_rpm', 'off'), ...
                        {sync}, ...
                        {Counter_out1});

% block: untitled2/fft_stage_n_init_xblock/Delay
Delay_out1 = xSignal;
Delay = xBlock(struct('source', 'Delay', 'name', 'Delay'), ...
                      [], ...
                      {sync}, ...
                      {Delay_out1});

% block: untitled2/fft_stage_n_init_xblock/Logical1
butterfly_direct_out3 = xSignal;
Logical1 = xBlock(struct('source', 'Logical', 'name', 'Logical1'), ...
                         struct('logical_function', 'OR', ...
                                'latency', 1, ...
                                'n_bits', 8, ...
                                'bin_pt', 2), ...
                         {butterfly_direct_out3, of_in}, ...
                         {of});

% block: untitled2/fft_stage_n_init_xblock/Mux
Slice1_out1 = xSignal;
delay_f_out1 = xSignal;
Mux_out1 = xSignal;
Mux = xBlock(struct('source', 'Mux', 'name', 'Mux'), ...
                    struct('latency', 1, ...
                           'arith_type', 'Signed  (2''s comp)', ...
                           'n_bits', 8, ...
                           'bin_pt', 2), ...
                    {Slice1_out1, delay_f_out1, in1}, ...
                    {Mux_out1});

% block: untitled2/fft_stage_n_init_xblock/Mux1
Mux1_out1 = xSignal;
Mux1 = xBlock(struct('source', 'Mux', 'name', 'Mux1'), ...
                     struct('latency', 1, ...
                            'arith_type', 'Signed  (2''s comp)', ...
                            'n_bits', 8, ...
                            'bin_pt', 2), ...
                     {Slice1_out1, in1, delay_f_out1}, ...
                     {Mux1_out1});

% block: untitled2/fft_stage_n_init_xblock/Slice
Slice_out1 = xSignal;
Slice = xBlock(struct('source', 'Slice', 'name', 'Slice'), ...
                      struct('boolean_output', 'on', ...
                             'mode', 'Lower Bit Location + Width', ...
                             'bit1', -(FFTStage - 1), ...
                             'bit0', FFTStage - 1), ...
                      {shift}, ...
                      {Slice_out1});

% block: untitled2/fft_stage_n_init_xblock/Slice1
Slice1 = xBlock(struct('source', 'Slice', 'name', 'Slice1'), ...
                       [], ...
                       {Counter_out1}, ...
                       {Slice1_out1});

% block: untitled2/fft_stage_n_init_xblock/butterfly_direct
delay_b_out1 = xSignal;
sync_delay_out1 = xSignal;
butterfly_direct_sub = xBlock(struct('source', str2func('fft_butterfly_init_xblock'), 'name', 'butterfly_direct'), ...
                                 { 'biplex', 'on', ...
								  'Coeffs', (Coeffs), ...
								  'StepPeriod', (StepPeriod), ...
								  'FFTSize', (FFTSize), ...
								  'input_bit_width', (input_bit_width), ...
								  'coeff_bit_width', (coeff_bit_width), ...
								  'add_latency', (add_latency), ...
								  'mult_latency', (mult_latency), ...
								  'bram_latency', (bram_latency), ...
								  'coeffs_bram', (coeffs_bram), ...
								  'conv_latency', (conv_latency), ...
								  'quantization', (quantization), ...
								  'overflow', (overflow), ...
								  'arch', (arch), ...
								  'opt_target', (opt_target), ...
								  'use_hdl', (use_hdl), ...
								  'use_embedded', (use_embedded), ...
								  'hardcode_shifts', (hardcode_shifts), ...
								  'downshift', (downshift), ...
								  'dsp48_adders', (dsp48_adders) }, ...
                                 {delay_b_out1, Mux_out1, sync_delay_out1, Slice_out1}, ...
                                 {out1, out2, butterfly_direct_out3, sync_out});

% block: untitled2/fft_stage_n_init_xblock/sync_delay
sync_delay_sub = xBlock(struct('source', str2func('sync_delay_init_xblock'), 'name', 'sync_delay'), ...
                           {2^(FFTSize - FFTStage)}, ...
                           {Delay_out1}, ...
                           {sync_delay_out1});
                           
                           
                           
% Implement delays normally or in BRAM
% TODO: use the "combined" delay block
if strcmp(delays_bram, 'on')
	% instantiate delay_b
	delay_b_sub = xBlock(struct('source', str2func('delay_bram_init_xblock'), 'name', 'delay_b'), ...
							{2^(FFTSize-FFTStage), bram_latency, 'off'},...
							{Mux1_out1}, ...
							{delay_b_out1});
	
	% instantiate delay_f
	delay_f_sub = xBlock(struct('source', str2func('delay_bram_init_xblock'), 'name', 'delay_f'), ...
							{2^(FFTSize-FFTStage), bram_latency, 'off'}, ...
							{in2}, ...
							{delay_f_out1});
else 	
	% instantiate delay_b
	delay_b_sub = xBlock(struct('source', 'Delay', 'name', 'delay_b'), ...
							{'latency', 2^(FFTSize-FFTStage)}, ...
							{Mux1_out1}, ...
							{delay_b_out1});
	
	% instantiate delay_f
	delay_f_sub = xBlock(struct('source', 'Delay', 'name', 'delay_f'), ...
							{'latency', 2^(FFTSize-FFTStage)}, ...
							{in2}, ...
							{delay_f_out1});
end                           

end

