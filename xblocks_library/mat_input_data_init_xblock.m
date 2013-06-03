function mat_input_data_init_xblock(blk, varargin)
defaults = {'var_name', 'var', ...
    'n_bits', 36, ...
    'bin_pt', 0, ...
    'quantization', 'Truncate', ...
    'overflow', 'Wrap', ...
    'arith_type', 'Signed  (2''s comp)', ...
    'numerical_type', 'Fixed-point', ...
};

var_name = get_var('var_name', 'defaults', defaults, varargin{:})
arith_type = get_var('arith_type', 'defaults', defaults, varargin{:})
n_bits = get_var('n_bits', 'defaults', defaults, varargin{:})
bin_pt = get_var('bin_pt', 'defaults', defaults, varargin{:});
quantization = get_var('quantization', 'defaults', defaults, varargin{:});
overflow = get_var('overflow', 'defaults', defaults, varargin{:});
numerical_type = get_var('numerical_type', 'defaults', defaults, varargin{:});

%% outports
out = xOutport(var_name);

%% diagram
from_workspace_output = xSignal();
xBlock( struct('source', 'simulink/Sources/From Workspace', 'name', 'from_workspace'), ...
    {'VariableName', var_name}, {}, {from_workspace_output});

% block: mux_buffer/mat_input_data_init_xblock/Gateway In4
xBlock(struct('source', 'Gateway In', 'name', 'gateway'), ...
    struct('n_bits', n_bits, ...
    'arith_type', arith_type, ...
    'gui_display_data_type', numerical_type, ...
    'bin_pt', bin_pt, ...
    'quantization', quantization, ...
    'overflow', overflow), ...
    {from_workspace_output}, ...
    {out});



end