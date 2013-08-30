function [] = create_tb(sys, blkname, input_args, output_args)
% create_tb(sys, blkname, input_args, output_args)
%     Create empty testbench & simulink model for block 

new_tb_name = ['tb_', sys, '.m'];
blank_tb_name = which('tb_blank');
copyfile(blank_tb_name, new_tb_name);

if ~iscell(input_args) || ~iscell(output_args)
    error('input_args and output_args must be a cell array of strings!')
end

% force-close the system if it is open
close_system(sys, 0)

% create the system
new_system(sys)

% Add system generator block
add_sysgen_token(sys)

% Draw empty test block with correct ports
add_tb_subsystem(sys, blkname, input_args, output_args)

% save the model
save_system(sys)

% open the model
open_system(sys)

end
