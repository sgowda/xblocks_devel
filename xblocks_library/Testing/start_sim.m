function [] = start_sim(mdl_name, T_sim)
    set_param(mdl_name, 'StopTime', num2str(T_sim - 1));
    sim(mdl_name)