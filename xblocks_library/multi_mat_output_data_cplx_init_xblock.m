function [] = multi_mat_output_data_cplx_init_xblock(blk, varargin)
defaults = {'n_inputs', 1, 'var_name', 'data', 'n_bits', 18, 'bin_pt', 17, 'SaveFormat', 'Array'};
n_inputs = get_var('n_inputs', 'defaults', defaults, varargin{:});
var_name = get_var('var_name', 'defaults', defaults, varargin{:});
n_bits = get_var('n_bits', 'defaults', defaults, varargin{:});
bin_pt = get_var('bin_pt', 'defaults', defaults, varargin{:});
SaveFormat = get_var('SaveFormat', 'defaults', defaults, varargin{:});

for k=1:n_inputs
    din_k = xInport(sprintf('%s%d', var_name, k));
    dout_k = xOutport(sprintf('o%d', k));
    xBlock(struct('name', sprintf('to_workspace_cplx_%d', k), 'source', @mat_output_data_cplx_init_xblock), ...
        {subblockname(blk, sprintf('to_workspace_cplx_%d', k)), 'var_name', sprintf('%s%d', var_name, k), 'n_bits', n_bits, 'bin_pt', bin_pt}, ...
        {din_k}, {dout_k});
end

end