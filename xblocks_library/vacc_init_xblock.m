function vacc_init_xblock(blk, varargin)
% TODO: reg retiming
defaults = { ...
    'veclen', 5, ...
    'n_inputs', 1, ...
    'max_accum', 5, ...
    'arith_type', 0, ...
    'in_bit_width', 18, ...
    'in_bin_pt', 17, ...
    'register_din', 0, ...
    'add_latency', 2, ...
    'bram_latency', 2, ...
    'mux_latency', 0, ...
    'use_dsp48', 1, ...
    'serialize_output_streams', 0, ...
    };

veclen = get_var('veclen', 'defaults', defaults, varargin{:});
n_inputs = get_var('n_inputs', 'defaults', defaults, varargin{:});
max_accum = get_var('max_accum', 'defaults', defaults, varargin{:});
arith_type = get_var('arith_type', 'defaults', defaults, varargin{:});
in_bit_width = get_var('in_bit_width', 'defaults', defaults, varargin{:});
in_bin_pt = get_var('in_bin_pt', 'defaults', defaults, varargin{:});
register_din = get_var('register_din', 'defaults', defaults, varargin{:});
add_latency = get_var('add_latency', 'defaults', defaults, varargin{:});
bram_latency = get_var('bram_latency', 'defaults', defaults, varargin{:});
mux_latency = get_var('mux_latency', 'defaults', defaults, varargin{:});
use_dsp48 = get_var('use_dsp48', 'defaults', defaults, varargin{:});
serialize_output_streams = get_var('serialize_output_streams', 'defaults', defaults, varargin{:});
mux_serializing_latency = 10;
% out_bit_width = get_var('out_bit_width', 'defaults', defaults, varargin{:});
% out_bin_pt = get_var('out_bin_pt', 'defaults', defaults, varargin{:});

out_bin_pt = in_bin_pt;
out_bit_width = in_bit_width + max_accum;

if n_inputs == 1
    serialize_output_streams = 0;
end

% if use_dsp48,
%     
%     mux_latency = 0;
% end

if veclen < 0,
    errordlg('Vector Accumulator: Vector Length must be >= 2^0')
end

actual_veclen = 2^veclen;

if register_din,
    reg_retiming = 'on';
else
    reg_retiming = 'off';
end

% Add latency is fixed for dsp48 implementation mode
if use_dsp48 && out_bit_width < 48
    add_latency = 2;
    mux_latency = 0;
    warning('vacc_init_xblock: using DSP48, so ignoring mux latency');
elseif use_dsp48 && out_bit_width < 96
    add_latency = 3;	
    mux_latency = 0;    
    warning('vacc_init_xblock: using DSP48, so ignoring mux latency');
elseif use_dsp48
    error('bit width too large for currently-implemented DSP48E adders')
end
%% inports
sync = xInport('sync');
acc_len = xInport('acc_len');
din = xblock_new_inputs('din', n_inputs, 1);

%% outports
if serialize_output_streams
    vacc_dout = xblock_new_bus(n_inputs, 1);
    valid = xOutport('valid');
    dout = xOutport('dout');
    stream_idx = xOutport('stream_idx');
    word_idx = xOutport('word_idx');
else
    valid = xOutport('valid');
    dout = xblock_new_outputs('dout', n_inputs, 1);
end

%% diagram
%--- Reset logic
ValidCompare_out1 = xSignal;
SyncCompare_out1 = xSignal;
Slice_out1 = xSignal;
Counter_out1 = xSignal;
SliceLow_out1 = xSignal;

zero = const('Zero', 0, fi_dtype(0, max_accum, 0));
din_del = xblock_new_bus(n_inputs, 1);
xblock_delay(din, din_del', 'din', mux_latency+1, 'Register');
end_of_frame = and_gate('AND', ValidCompare_out1, SyncCompare_out1);
acc_en = neq_comp('AccEnCompare', Slice_out1, zero, 'latency', 1);
counter_rst = or_gate('OR', sync, end_of_frame);

Counter = xBlock(struct('source', 'Counter', 'name', 'Counter'), ...
    struct('n_bits', max_accum + veclen, 'rst', 'on', 'use_rpm', 'on'), ...
    {counter_rst}, {Counter_out1});

Slice = xBlock(struct('source', 'Slice', 'name', 'Slice'), ...
    struct('nbits', max_accum, 'mode', 'Upper Bit Location + Width'), ...
    {Counter_out1}, {Slice_out1});

if veclen > 0
    SliceLow = xBlock(struct('source', 'Slice', 'name', 'SliceLow'), ...
        struct('nbits', veclen, 'mode', 'Lower Bit Location + Width'), ...
        {Counter_out1}, {SliceLow_out1});

    sync_const = const('SyncConst', actual_veclen-2, fi_dtype(0, veclen, 0));
    SyncCompare_out1.bind(eq_comp('SyncCompare', SliceLow_out1, sync_const, 'latency', 1));
    ValidCompare_out1.bind(eq_comp('ValidCompare', acc_len, Slice_out1, 'latency', 1));
    valid_latency = add_latency+mux_latency;
else
    SyncCompare_out1.bind(bool_one('end_of_vec'));
    ValidCompare_out1.bind(eq_comp('ValidCompare', acc_len, Slice_out1, 'latency', 0));
    valid_latency = add_latency+mux_latency+1;
end

%%% TODO: pass down mux_latency properly
vacc_core_config.source = str2func('vacc_core_init_xblock');
vacc_core_config.name = 'vacc_core';
vacc_core_params = {'veclen', actual_veclen, 'n_inputs', n_inputs, 'arith_type', arith_type, ...
    'bit_width_out', out_bit_width, 'bin_pt_out', out_bin_pt, ...
    'add_latency', add_latency, 'bram_latency', bram_latency, ...
    'mux_latency', 0, 'bin_pt_in', in_bin_pt, ...
    'use_dsp48', use_dsp48 };

%--- Instantiate vector accumulator cores and serialization buffers
acc_valid = delay_srl('ValidDelay', ValidCompare_out1, valid_latency);
if serialize_output_streams
    % instantiate vacc cores
    xBlock(vacc_core_config, vacc_core_params, {acc_en, din_del{:}}, vacc_dout );
    
    if valid_latency == 0
        error('Serialization not implemented when add_latency+mux_latency = 0')
    end
    acc_sync = delay_srl('SyncDelay', ValidCompare_out1, valid_latency-1);
    counter_rst = posedge('ser_rst', acc_sync);
    
    log2_n_inputs = ceil(log2(n_inputs));
    counter_bit_width = veclen + log2_n_inputs;
    addr_count = xSignal();
    xBlock(struct('source', 'Counter', 'name', 'ser_word_counter'), ...
        {'n_bits', counter_bit_width, 'rst', 'on'}, ...
        {counter_rst}, {addr_count});
    
    % slice bits for mux selector and addr
    if veclen == 0
        bram_addr = const('zero', 0, fi_dtype(0, 32, 0));
        mux_sel = addr_count;
        mux_sel = delay_srl('read_latency1', mux_sel, bram_latency);
    else
        count_slices = slice_partition('ser_counter_sl', addr_count, [veclen, log2_n_inputs]);
        bram_addr = count_slices{1};
        mux_sel = count_slices{2};
        mux_sel = delay_srl('read_latency1', mux_sel, bram_latency);
    end
    
    % valid signal
    sync_out = delay_srl('read_latency2', counter_rst, mux_serializing_latency + bram_latency - 1); % minus 1 is for the edge detector latency
    xBlock(struct('source', @pulse_ext_init_xblock, 'name', 'valid_gen'), ...
        {[], 'pulse_len', 2^veclen*n_inputs}, {sync_out}, {valid});

    % instatiate buffers
    bram_outputs = xblock_new_bus(n_inputs, 1);
    if veclen == 0
        % use register with enable
        for k=1:n_inputs
            xBlock(struct('source', 'Register', 'name', sprintf('mem%d', k)), ...
                {'en', 'on'}, {vacc_dout{k}, acc_valid}, {bram_outputs{k}});
        end
    else
        config.source = 'Single Port RAM';
        for k=1:n_inputs
            config.name = sprintf('mem%d', k);
            xBlock(config, {'depth', 2^veclen, 'latency', bram_latency}, ...
                {bram_addr, vacc_dout{k}, acc_valid}, {bram_outputs{k}});
        end
    end
    
    bram_sel = mux_select('mux', mux_sel, bram_outputs, 'latency', mux_serializing_latency);
    dout.bind(bram_sel);
    stream_idx.bind(delay_srl('del1', mux_sel, mux_serializing_latency));
    word_idx.bind(delay_srl('del2', bram_addr, mux_serializing_latency + bram_latency));
else
    xBlock(vacc_core_config, vacc_core_params, {acc_en, din_del{:}}, {dout{:,1}} );
    valid.bind(acc_valid)
end


%--set block format string
if ~isempty(blk) && ~strcmp(blk(1), '/')
    % Delete all unconnected blocks.
    clean_blocks(blk);

    % Set attribute format string (block annotation).
    fmtstr = sprintf('vector_length=2^%d, inputs=%d\nmax_accumulations=2^%d', veclen, n_inputs, max_accum);
    set_param(blk, 'AttributesFormatString', fmtstr);
end