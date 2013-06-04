function [] = add_to_workspace(sys, var_name, varargin)
    config.source = str2func('mat_output_data_init_xblock');
    config.depend = {'mat_output_data_init_xblock.m'};
    config.toplevel = sprintf('%s/%s', sys, var_name);
    xBlock(config, {config.toplevel, 'var_name', var_name, varargin{:}});   
    set_param(config.toplevel, 'ShowName', 'off')
end