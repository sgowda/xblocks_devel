%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                             %
%   Center for Astronomy Signal Processing and Electronics Research           %
%   http://casper.berkeley.edu                                                %
%   Copyright (C) 2011 Hong Chen                                              %
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
function delay_bram_init_xblock(blk, varargin)
defaults = { 'n_inputs', 1, ...
    'bram_latency', 4, ...
    'count_using_dsp48', 0};

%'latency', 7, ...  % having default values that change functionality is
%dangerous

n_inputs = get_var('n_inputs', 'defaults', defaults, varargin{:});
latency = get_var('latency', 'defaults', defaults, varargin{:});
bram_latency = get_var('bram_latency', 'defaults', defaults, varargin{:});
count_using_dsp48 = get_var('count_using_dsp48', 'defaults', defaults, varargin{:});

if (latency <= bram_latency)
    errordlg('delay value must be greater than BRAM Latency');
end

bit_width = max(ceil(log2(latency)), 2);
if strcmp(count_using_dsp48, 'on'),
    count_using_dsp48_im='DSP48';
else
    count_using_dsp48_im='Fabric';
end

%% inports
din = xblock_new_inputs('din', n_inputs, 1);

%% outports
dout = xblock_new_outputs('dout', n_inputs, 1);

%% diagram
we = bool_one('we');

%-- instantiate counter
if latency > (bram_latency + 1)
    addr = xSignal;
    if(bit_width<9)
        Counter = xBlock(struct('source', 'Counter', 'name', 'Counter'), ...
            struct('cnt_type', 'Count Limited', ...
            'cnt_to', latency - bram_latency - 1, ...
            'n_bits', bit_width, ...
            'use_rpm', count_using_dsp48, ...
            'implementation', count_using_dsp48_im), ...
            {}, ...
            {addr});
    else
        Counter = xBlock(struct('source', 'monroe_library/counter_limited_fast', 'name', 'Counter_fast'), ...
            struct(...
            'count_to', latency - bram_latency - 1, ...
            'bit_width', bit_width, ...
            'register_output', 0, ...
            'cheap_counter', 0), ...
            {}, ...
            {addr});
    end
else % latency == bram_latency + 1, since any less latency throws an error
    warning('Using BRAM with constant address, switch to register!')
    addr = const('Constant1', 0, fi_dtype(0, bit_width, 0));
end

bram_config.source = 'Single Port RAM';
bram_params = struct('depth', 2^bit_width, 'initVector', 0, 'write_mode', 'Read Before Write', ...
    'latency', bram_latency);
    
for k = 1:n_inputs
    bram_config.name = ['bram', num2str(k)];
    xBlock(bram_config, bram_params, {addr, din{k,1}, we}, dout(k,1));
end

end

