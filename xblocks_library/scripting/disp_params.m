function [] = disp_params(blk)
% Display ALL parameters of a Simulink block (useful for mask scripting
% when you're trying to find the name of a parameter to set)

params = fields(get_param(blk, 'ObjectParameters'));

for k=1:length(params)
    param = params{k};
    fprintf('%s\n', param);
    disp(get_param(blk, param));
    fprintf('\n');
end
