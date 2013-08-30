function [mask_data] = get_mask_config(blk)

mask_data = [get_param(blk, 'MaskNames'), get_param(blk, 'MaskValues'), ...
    get_param(blk, 'MaskStyles')];