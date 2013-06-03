function [] = add_from_workspace(sys, var_name, varargin)
    config.source = str2func('mat_input_data_init_xblock');
    config.depend = {'mat_input_data_init_xblock.m'};
    config.toplevel = sprintf('%s/%s', sys, var_name);
    xBlock(config, {config.toplevel, 'var_name', var_name, varargin{:}});   
end