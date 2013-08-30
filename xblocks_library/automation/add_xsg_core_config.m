function [] = add_xsg_core_config(mdl_name, varargin)
    defaults = {'Position', [62, 26, 108, 69]};
    Position = get_var('Position', 'defaults', defaults, varargin{:});
    reuse_block(mdl_name, 'XSG core config', 'xps_library/XSG core config', 'Position', Position)