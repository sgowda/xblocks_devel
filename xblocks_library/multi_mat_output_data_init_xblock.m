function multi_mat_output_data_init_xblock(blk, varargin)
defaults = {'var_name', 'var', ...
    'n_inputs', 1, ...
};

var_name = get_var('var_name', 'defaults', defaults, varargin{:});
n_inputs = get_var('n_inputs', 'defaults', defaults, varargin{:});


%% diagram

for k=1:n_inputs
    var_name_k = sprintf('%s%d', var_name, k);
    blk_name_k = sprintf('to_workspace_%d', k);
    din_k = xInport(var_name_k);
    dout_k = xOutport(sprintf('_o%d', k));
    xBlock(struct('name', blk_name_k, 'source', @mat_output_data_init_xblock), ...
        {subblockname(blk, blk_name_k), 'var_name', var_name_k}, ...
        {din_k}, {dout_k});
end