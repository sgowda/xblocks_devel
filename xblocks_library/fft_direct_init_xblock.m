%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                             %
%   Center for Astronomy Signal Processing and Electronics Research           %
%   http://casper.berkeley.edu                                                %      
%   Copyright (C) 2011 Suraj Gowda, Hong Chen, Terry Filiba, Aaron Parsons    %
%                                                                             %
%   This program is free software; you can redistribute it and/or modify      %
%   it under the terms of the GNU General Public License as published by      %
%   the Free Software Foundation; either version 2 of the License, or         %
%   (at your option) any later version.                                       %
%                                                                             %
%   This program is distributed in the hope that it will be useful,           %
%   but WITHOUT ANY WARRANTY; without even the implied warranty of            %
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the             %
%   GNU General Public License for more details.                              %
%                                                                             %
%   You should have received a copy of the GNU General Public License along   %
%   with this program; if not, write to the Free Software Foundation, Inc.,   %
%   51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.               %
%                                                                             %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function fft_direct_init_xblock(blk, varargin)

% defaults = {};
% Set default vararg values.
defaults = { ...
    'FFTSize', 2,  ...
    'input_bit_width', 18, ...
    'coeff_bit_width', 18, ...
    'map_tail', 1, ...
    'LargerFFTSize', 7, ...
    'StartStage', 6, ...
    'add_latency', 2, ...
    'mult_latency', 3, ...
    'bram_latency', 2, ...
    'conv_latency', 1, ...
    'quantization', 'Round  (unbiased: +/- Inf)', ...
    'overflow', 'Saturate', ...
    'arch', 'Virtex5', ...
    'opt_target', 'multipliers', ...
    'coeffs_bit_limit', 8,  ...
    'specify_mult', 'on', ...
    'mult_spec', [1,1], ...
    'hardcode_shifts', 'off', ...
    'shift_schedule', [1], ...
    'dsp48_adders', 'on', ...
    'bit_growth_chart', [0 0], ...
};


% Retrieve values from mask fields.
FFTSize = get_var('FFTSize', 'defaults', defaults, varargin{:});
input_bit_width = get_var('input_bit_width', 'defaults', defaults, varargin{:});
input_bin_pt = input_bit_width - 1;
coeff_bit_width = get_var('coeff_bit_width', 'defaults', defaults, varargin{:});
coeff_bin_pt = coeff_bit_width - 1;
map_tail = get_var('map_tail', 'defaults', defaults, varargin{:});
LargerFFTSize = get_var('LargerFFTSize', 'defaults', defaults, varargin{:});
StartStage = get_var('StartStage', 'defaults', defaults, varargin{:});
add_latency = get_var('add_latency', 'defaults', defaults, varargin{:});
mult_latency = get_var('mult_latency', 'defaults', defaults, varargin{:});
bram_latency = get_var('bram_latency', 'defaults', defaults, varargin{:});
conv_latency = get_var('conv_latency', 'defaults', defaults, varargin{:});
quantization = get_var('quantization', 'defaults', defaults, varargin{:});
overflow = get_var('overflow', 'defaults', defaults, varargin{:});
arch = get_var('arch', 'defaults', defaults, varargin{:});
opt_target = get_var('opt_target', 'defaults', defaults, varargin{:});
coeffs_bit_limit = get_var('coeffs_bit_limit', 'defaults', defaults, varargin{:});
specify_mult = get_var('specify_mult', 'defaults', defaults, varargin{:});
mult_spec = get_var('mult_spec', 'defaults', defaults, varargin{:});
hardcode_shifts = get_var('hardcode_shifts', 'defaults', defaults, varargin{:});
shift_schedule = get_var('shift_schedule', 'defaults', defaults, varargin{:});
dsp48_adders = get_var('dsp48_adders', 'defaults', defaults, varargin{:});
biplex = get_var('biplex', 'defaults', defaults, varargin{:});
bit_growth_chart = get_var('bit_growth_chart', 'defaults', defaults, varargin{:});

if (strcmp(specify_mult, 'on') && (length(mult_spec) ~= FFTSize)),
    disp('fft_direct_init.m: Multiplier use specification for stages does not match FFT size');
    error('fft_direct_init.m: Multiplier use specification for stages does not match FFT size');
end

if FFTSize < 1
    error('Minimum fft size is 2 (radix size)')
end

% for bit growth FFT
bit_growth_chart =[reshape(bit_growth_chart, 1, []) zeros(1,FFTSize)];
bit_growth_chart

%% Declare Ports
sync = xInport('sync');
shift = xInport('shift');

sync_out = xOutport('sync_out');

n_inputs = 2^FFTSize;
stream_fft_size = 2^(StartStage - 1);


data_inports = {};
data_outports = {};
for k=0:2^FFTSize-1,
	data_inports{k+1} = xInport(['din_' num2str(k)]);
	data_outports{k+1} = xOutport(['dout_' num2str(k)]);
end

of = xOutport('of');
of_outports = {};

% Draw phase rotation block
redundancy = 2^(LargerFFTSize - FFTSize);
num_coeffs = redundancy;
if ((num_coeffs * coeff_bit_width * 2) > 2^coeffs_bit_limit),
    coeffs_bram = 'on';
    use_bram = 1;
else
    coeffs_bram = 'off';
    use_bram = 0;
end

if map_tail
    direct_form_inputs = xblock_new_bus(n_inputs, 1);
    fft_sync = xSignal();
    xBlock(struct('name', 'phase_rotation', 'source', 'phase_mult_init_xblock'), ...
        {subblockname(blk, 'phase_rotation'), 'n_inputs', n_inputs, ...
        'n_cols', stream_fft_size, 'read_latency', bram_latency, 'use_bram', use_bram, ...
        'input_bit_width', input_bit_width, 'input_bin_pt', input_bin_pt, ...
        'coeff_bit_width', coeff_bit_width, 'coeff_bin_pt', coeff_bin_pt}, ...
        {sync, data_inports{1:n_inputs}}, {fft_sync, direct_form_inputs{:}});
else
    fft_sync = sync;
    direct_form_inputs = data_inports{1:n_inputs};
end

% Add nodes
node_inputs = cell(FFTSize+1, n_inputs);
node_outputs = cell(FFTSize+1, n_inputs);

bf_shifts = {};
for stage=0:FFTSize,
%     for i=0:2^FFTSize-1,
%         node_name = ['node',num2str(stage),'_',num2str(i)];
%         pos = [300*stage+90 100*i+100 300*stage+120 100*i+130];
%         
%         node_in = xSignal;
%         node_out = xSignal;
%         if stage == 0
% 			xBlock( struct('source', 'Delay', 'name', node_name), struct('latency', 0, 'Position', pos), ...
% 					{direct_form_inputs{i+1}}, {node_out});        	
%         elseif stage == FFTSize
% 			xBlock( struct('source', 'Delay', 'name', node_name), struct('latency', 0, 'Position', pos), ...
% 					{node_in}, {data_outports{bit_reverse(i, FFTSize)+1}});
%         else
% 			xBlock( struct('source', 'Delay', 'name', node_name), struct('latency', 0, 'Position', pos), ...
% 					{node_in}, {node_out});
% 		end
%         node_inputs{stage+1, i+1} = node_in;
%         node_outputs{stage+1, i+1} = node_out;
%     end
% 
	% slice off shift bits for each butterfly 
    if (stage ~= FFTSize),
    	stage_shift = xSignal;
        shift_slice_name = ['slice',num2str(stage)];
        pos = [300*stage+90 70 300*stage+120 85];
        xBlock( struct('source', 'Slice', 'name', shift_slice_name), ...
        		struct('Position', pos, 'mode', 'Lower Bit Location + Width', 'nbits', 1, ...
					   'bit0', stage, 'boolean_output', 'on'), {shift}, {stage_shift});
		bf_shifts{stage+1} = stage_shift;
    end
end

% node_inputs = cell(n_inputs, FFTSize+1);
% node_inputs{:,1} = direct_form_inputs;

% initialize bf_syncs
bf_syncs = xblock_new_bus(n_inputs, FFTSize+1);
for k=1:n_inputs
    bf_syncs{k, 1} = fft_sync;
end


stage_of_out = {};



% Add butterflies
node_outputs = direct_form_inputs;
for stage=1:FFTSize,
    use_hdl = 'on';
    use_embedded = 'off';
    if strcmp(specify_mult, 'on'),
        if (mult_spec(stage) == 2),
            use_hdl = 'on';
            use_embedded = 'off';
        elseif (mult_spec(stage) == 1),
            use_hdl = 'off';
            use_embedded = 'on';
        else
            use_hdl = 'off';
            use_embedded = 'off';
        end
    end

    if (strcmp(hardcode_shifts, 'on') && (shift_schedule(stage) == 1)),
        downshift = 'on';
    else
        downshift = 'off';
    end

	stage_of_outputs = {};
    
    bf_input_pairs = cornerturn(1:n_inputs, stage);
    node_outputs_temp = xblock_new_bus(n_inputs, 1);

    for i=0:n_inputs/2-1,
        bf_name = sprintf('butterfly%d_%d', stage, i)
%         if strcmp(map_tail, 'off'), % Implement a normal FFT
%             coeffs = [ floor(i/2^(FFTSize-stage)) ];
%             actual_fft_size = FFTSize;
%             num_coeffs = 1;
%         else % Implement the tail end of a larger FFT
%             
%             coeffs = [];
%             for r=0:redundancy-1,
%                 n = bit_reverse(r, LargerFFTSize - FFTSize);
%                 coeffs = [coeffs, floor((i+n*2^(FFTSize-1))/2^(LargerFFTSize-(StartStage+stage-1)))];
%             end
%             actual_fft_size = LargerFFTSize;
%             num_coeffs = redundancy;
%         end
        
        bf_pos = [300*(stage-1)+220, 200*i+100, 300*(stage-1)+300, 200*i+175];
%         node_one_num = 2^(FFTSize-stage+1)*floor(i/2^(FFTSize-stage)) + mod(i, 2^(FFTSize-stage))
%         node_two_num = node_one_num+2^(FFTSize-stage)
        
        
        % butterfly constant coefficient
        bf_coef = xSignal();
        coef_ind = floor(i/2^(FFTSize-stage));
        xBlock(struct('name', sprintf('%s_coef', bf_name), 'source', 'complex_constant_init_xblock'), ...
            {subblockname(blk, sprintf('%s_coef', bf_name)), 'bit_width', coeff_bit_width, ...
             'bin_pt', coeff_bin_pt, 'value', exp(-1j*2*pi*coef_ind)}, {}, {bf_coef});
        
        % cell array of butterfly output signals
        input_pair = bf_input_pairs(:,i+1);
        bf_inputs = { node_outputs{input_pair(1), 1}, node_outputs{input_pair(2), 1}, ...
            bf_coef, bf_syncs{i+1, stage}, bf_shifts{stage} };
        
        % cell array of butterfly input signals
        of_out = xSignal();
        bf_outputs = {node_outputs_temp{2*i+1,1}, node_outputs_temp{2*i+2,1}, ...
        	of_out, bf_syncs{i+1, stage+1} };        

%         bf_inputs = {}; bf_outputs = {};
        fprintf('%s\n', bf_name);
        xBlock( struct('source', str2func('fft_butterfly_init_xblock'), 'name', bf_name), ...
            {[blk,'/',bf_name], 'biplex', 'off', ...
            'twiddle_type', 'twiddle_general_4mult', ...
            'coeff_bit_width', coeff_bit_width, ...
            'input_bit_width', input_bit_width, ...
            'downshift', downshift, ...
            'bram_latency', bram_latency, ...
            'add_latency', add_latency, ...
            'mult_latency', mult_latency, ...
            'conv_latency', conv_latency, ...
            'quantization', quantization, ...
            'overflow', overflow, ...
            'arch', arch, ...
            'opt_target', opt_target, ...
            'use_hdl', use_hdl, ...
            'use_embedded', use_embedded, ...
            'hardcode_shifts', hardcode_shifts, ...
            'dsp48_adders', dsp48_adders, ...
            'bit_growth', bit_growth_chart(stage), 'Position', bf_pos}, ...
            bf_inputs, bf_outputs );

		stage_of_outputs{i+1} = of_out;
    end
	coeff_bit_width = coeff_bit_width + bit_growth_chart(stage);
	input_bit_width = input_bit_width + bit_growth_chart(stage);


	%add overflow logic
    %FFTSize == 1 implies 1 input or block which generates an error
    if (FFTSize ~= 1),
        of_out = xSignal;
        pos = [300*stage+90 100*(2^FFTSize)+100+(stage*15) 300*stage+120 120+100*(2^FFTSize)+(FFTSize*5)+(stage*15)];
        xBlock( struct('name', ['of_', num2str(stage)], 'source', 'Logical'), ...
                {'Position', pos, 'logical_function', 'OR', 'inputs', 2^(FFTSize-1), 'latency', 1}, ...
                stage_of_outputs, {of_out});
        stage_of_out{stage} = of_out;
    end
    node_outputs = node_outputs_temp;
end


if (FFTSize ~= 1), %FFTSize == 1 implies 1 input 'or' block, which generates an error
    pos = [300*FFTSize+150 100*(2^FFTSize)+100 300*FFTSize+180 100*(2^FFTSize)+115+(FFTSize*10)];
    xBlock( struct('name', 'of_or', 'source', 'Logical'), ...
			{'Position', pos, ...
			'logical_function', 'OR', ...
			'inputs', FFTSize, ...
			'latency', 0}, stage_of_out, {of});
else
    of.bind(of_out);
end

% Connect sync_out
sync_out.bind( bf_syncs{FFTSize+1, 1} );

output_inds = bit_rev(0:n_inputs-1, FFTSize);
for k=0:n_inputs-1
    data_outports{k+1}.bind(node_outputs{output_inds(k+1)+1, 1});
end

% if ~isempty(blk) && ~strcmp(blk(1),'/')
%     clean_blocks(blk);
%     fmtstr = sprintf('%s\nstages [%s] of %d\n[%d,%d]\n%s\n%s\n%s', arch, num2str([StartStage:1:StartStage+FFTSize-1]), ...
%         actual_fft_size,  input_bit_width, coeff_bit_width, quantization, overflow,num2str(bit_growth_chart,'%d '));
%     set_param(blk, 'AttributesFormatString', fmtstr);
% end

end
