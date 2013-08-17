function [] = phase_mult_init_xblock(blk, varargin)

defaults = {'n_inputs', 4, 'biplex_fft_length', 32, 'read_latency', 2, 'use_bram', 1, ...
    'input_bit_width', 18, 'input_bin_pt', 17, 'coeff_bit_width', 18, 'coeff_bin_pt', 17, ...
    'mult_latency', 3, 'add_latency', 2, 'conv_latency', 1, 'quantization', 'Truncate', ...
    'overflow', 'Wrap'};

n_inputs = get_var('n_inputs', 'defaults', defaults, varargin{:});
biplex_fft_length = get_var('biplex_fft_length', 'defaults', defaults, varargin{:});
read_latency = get_var('read_latency', 'defaults', defaults, varargin{:});
mult_latency = get_var('mult_latency', 'defaults', defaults, varargin{:});
add_latency = get_var('add_latency', 'defaults', defaults, varargin{:});
conv_latency = get_var('conv_latency', 'defaults', defaults, varargin{:});
use_bram = get_var('use_bram', 'defaults', defaults, varargin{:});
coeff_bit_width = get_var('coeff_bit_width', 'defaults', defaults, varargin{:});
coeff_bin_pt = get_var('coeff_bin_pt', 'defaults', defaults, varargin{:});
input_bit_width = get_var('input_bit_width', 'defaults', defaults, varargin{:});
input_bin_pt = get_var('input_bin_pt', 'defaults', defaults, varargin{:});
quantization = get_var('quantization', 'defaults', defaults, varargin{:});
overflow = get_var('overflow', 'defaults', defaults, varargin{:});

cmult_latency = mult_latency + add_latency + conv_latency; % TODO fixed latency for DSP48E implementation

sync = xInport('sync');
sync_out = xOutport('sync_out');

for k=1:n_inputs
    din_name = sprintf('din%d', k);
    fprintf('%s\n', din_name);
    din = xInport(din_name);
    coeffs = xSignal('coeffs');
    phase_coeffs = exp(-1j*2*pi/(n_inputs*biplex_fft_length)*(0:biplex_fft_length-1)*(k-1));
    coeff_blkname = sprintf('phase%d_coeffs', k);
    xBlock(struct('name', coeff_blkname, 'source', str2func('coeff_gen_init_xblock')), ...
        {sprintf('%s/%s', blk, coeff_blkname), phase_coeffs, coeff_bit_width, 0, read_latency, 'on'}, {sync}, {coeffs});

    %---- delay data inputs by 'read_latency'
    din_del = xSignal();
    xBlock(struct('source', 'Delay', 'name', sprintf('%s_read_del', din_name)), ...
        {'latency', read_latency}, {din}, {din_del}); 
    
    % multipliers
    dout_name = sprintf('dout%d', k);
    dout = xOutport(dout_name);
    xBlock(struct('source', 'cmult_behav_init_xblock', 'name', sprintf('cmult_%d', k)), ...
        {sprintf('%s/cmult_%d', blk, k), 'n_bits_a', input_bit_width, 'bin_pt_a', input_bin_pt, 'n_bits_b', coeff_bit_width, 'bin_pt_b', coeff_bin_pt, 'conjugated', 0, ...
            'full_precision', 0, 'n_bits_c', input_bit_width, 'bin_pt_c', input_bin_pt, 'quantization', quantization, 'overflow', overflow, 'cplx_inputs', 1}, ...
        {din_del, coeffs}, {dout});  
    
%     defaults = {'n_bits_a', 18, 'bin_pt_a', 17, 'n_bits_b', 18, 'bin_pt_b', 17, 'conjugated', 0, ...
% 	'full_precision', 1, 'n_bits_c', 18, 'bin_pt_c', 17, 'quantization', 'Truncate', 'overflow', 'Wrap', ...
%     'cplx_inputs', 0, 'mult_latency', 3, 'add_latency', 2, 'conv_latency', 1};
    
    
end

% TODO sync delay
sync_latency = read_latency + cmult_latency;

xBlock(struct('source', 'Delay', 'name', 'sync_del'), ...
    {'latency', sync_latency}, {sync}, {sync_out});

end