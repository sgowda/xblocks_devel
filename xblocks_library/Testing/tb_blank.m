clc; clear; close all

mdl_name = 
eval(mdl_name); % open design

%% Re-draw blocks

%% Generate simulation inputs
T_sim = 100;

%% Simulate
set_param(mdl_name, 'StopTime', num2str(T_sim - 1));
sim(mdl_name)

%% Verify
