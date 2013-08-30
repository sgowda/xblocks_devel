function [] = add_sysgen_token(mdl_name, varargin)
    defaults = {'Position', [20, 16, 70, 66]};
    Position = get_var('Position', 'defaults', defaults, varargin{:});
    reuse_block(mdl_name, ' System Generator', 'xbsBasic_r4/ System Generator', 'Position', Position)