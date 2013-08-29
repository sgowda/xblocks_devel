function mat_output_data_init_xblock(blk, varargin)
defaults = {'var_name', 'var', ...
    'SaveFormat', 'Array', ...
};

var_name = get_var('var_name', 'defaults', defaults, varargin{:});
SaveFormat = get_var('SaveFormat', 'defaults', defaults, varargin{:});


%% inports
input = xInport(var_name);

%% outports
output = xOutport('_o');
output.bind(input);

%% diagram
to_workspace_input = xSignal();
xBlock( struct('source', 'simulink/Sinks/To Workspace', 'name', 'workspace_input'), ...
    {'VariableName', var_name, 'SaveFormat', SaveFormat, 'FixptAsFi', 'on'}, {to_workspace_input}, {});

xSignal('Gateway_Out_out1');
xBlock(struct('source', 'Gateway Out', 'name', 'gateway'), ...
    struct('inherit_from_input', 'on', ...
    'hdl_port', 'off'), ...
    {input}, ...
    {to_workspace_input});

end