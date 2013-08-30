clc; clear; close all

mdl_name = 
eval(mdl_name); % open design

%% Re-draw blocks

%% Generate simulation inputs
T_sim = 100;

%% Simulate
start_sim(mdl_name, T_sim);

%% Verify
