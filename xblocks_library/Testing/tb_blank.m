clc; clear; close all

mdl_name = 
eval(mdl_name); % open design

%% Re-draw blocks

%% Generate simulation inputs
T_sim = 100;

%% Simulate
% Set simulation time
set_param(mdl_name, 'StopTime', num2str(T_sim-1));

% Run simulation
sim(mdl_name)

%% Verify
