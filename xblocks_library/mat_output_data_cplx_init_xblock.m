function mat_output_data_cplx_init_xblock(varargin)

defaults = {'var_name', 'data', 'n_bits', 18, 'bin_pt', 17, 'SaveFormat', 'Array'};
var_name = get_var('var_name', 'defaults', defaults, varargin{:});
n_bits = get_var('n_bits', 'defaults', defaults, varargin{:});
bin_pt = get_var('bin_pt', 'defaults', defaults, varargin{:});
SaveFormat = get_var('SaveFormat', 'defaults', defaults, varargin{:});

%% inports
In1 = xInport(var_name);

%% outports
out = xOutport('_o');
out.bind(In1);
%% diagram

% block: fft_biplex_core/mat_output_data_cplx_init_xblock/c_to_ri
real = xSignal('c_to_ri_out1');
imag = xSignal('c_to_ri_out2');
c_to_ri = xBlock(struct('source', 'c_to_ri_init_xblock', 'name', 'c_to_ri'), ...
                        {[], n_bits, bin_pt}, ...
                        {In1}, ...
                        {real, imag});
                    
real_simulink = xSignal();
xBlock(struct('source', 'Gateway Out', 'name', 'real_gateway'), ...
    struct('inherit_from_input', 'on', 'hdl_port', 'off'), ...
    {real}, {real_simulink});

imag_simulink = xSignal();
xBlock(struct('source', 'Gateway Out', 'name', 'imag_gateway'), ...
    struct('inherit_from_input', 'on', 'hdl_port', 'off'), ...
    {imag}, {imag_simulink});

cplx = xSignal('cplx');
simulink_ri_to_c = 'simulink/Math Operations/Real-Imag to Complex';
xBlock(struct('source', simulink_ri_to_c, 'name', 'ri_to_c'), ...
    {}, {real_simulink, imag_simulink}, {cplx});

% to_workspace_input = xSignal();
xBlock( struct('source', 'simulink/Sinks/To Workspace', 'name', 'workspace_output'), ...
    {'VariableName', var_name, 'SaveFormat', SaveFormat}, {cplx}, {});

end

