function square_init_xblock( blk, varargin )

defaults = { ...
	'bitwidth', 18, ...
	'add_latency', 2, ...
	'mult_latency', 3, ...
	'impl_mode', 'dsp48e', ...
	'n_inputs', 4, ...
};
bitwidth = get_var('bitwidth', 'defaults', defaults, varargin{:});
add_latency = get_var('add_latency', 'defaults', defaults, varargin{:});
mult_latency = get_var('mult_latency', 'defaults', defaults, varargin{:});
impl_mode = get_var('impl_mode', 'defaults', defaults, varargin{:});
n_inputs = get_var('n_inputs', 'defaults', defaults, varargin{:});

% Square N real numbers

sync_in = xInport('sync_in');
sync_out = xOutport('sync_out');
data_inports = {};
data_outports = {};
for k = 0:n_inputs-1
   data_inports{k+1} = xInport(['din_', num2str(k)]);
   data_outports{k+1} = xOutport(['dout_', num2str(k)]);
end

sync_delay = 0;
if strcmp(impl_mode, 'dsp48e')
    sync_delay = 4;
    warning('square_init_xblock: sync_delay forced to 4 in dsp48e impl')
    for k=1:n_inputs
        square_dsp48e_config.source = str2func('square_dsp48e_init_xblock');
        square_dsp48e_config.name = ['square', num2str(k)];
        square_block_k = xBlock( square_dsp48e_config, ...
            {bitwidth}, ...
            {data_inports{k} }, ...
            {data_outports{k}});
    end   
elseif strcmp(impl_mode, 'behavioral')
    NotImplementedError
    sync_delay = add_latency + mult_latency;    
    for k=1:n_inputs
        square_config.source = str2func('square_behav_init_xblock');
        square_config.name = ['square', num2str(k)];
        square_block_k = xBlock( square_config, ...
            {bitwidth, add_latency, mult_latency}, ...
            {data_inports{k} }, ...
            {data_outports{k}});        
    end    
end
sync_delay_block = xBlock( struct('source', 'Delay', 'name', 'sync_delay'), ...
    struct('latency', sync_delay), ...
    {sync_in}, ...
    {sync_out});

end
