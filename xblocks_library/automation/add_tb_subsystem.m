function [] = add_tb_subsystem(sys, blkname, input_args, output_args)
if ~iscell(input_args) || ~iscell(output_args)
    error('input_args and output_args must be a cell array of strings!')
end

% pull an empty subsystem block from the library
test_block = subblockname(sys, blkname);
reuse_block(sys, blkname, 'simulink/Ports & Subsystems/Subsystem')
%add_block('simulink/Ports & Subsystems/Subsystem', test_block);

% Delete the default input ports, if they exist (only in later versions of simulink)
try
    delete_block(subblockname(test_block, 'In1'));
    delete_block(subblockname(test_block, 'Out1'));
catch
end

% Add specified input and output ports
for k=1:length(input_args)
    reuse_block(test_block, input_args{k}, 'simulink/Ports & Subsystems/In1');
    %add_block('simulink/Ports & Subsystems/In1', subblockname(test_block, input_args{k}));
end

for k=1:length(output_args)
    reuse_block(test_block, output_args{k}, 'simulink/Ports & Subsystems/Out1');
    %reuse_block('simulink/Ports & Subsystems/In1', subblockname(test_block, output_args{k}));
end
    
end
