function power_behav_init_xblock(BitWidth, add_latency, mult_latency)
%% inports
c = xInport('c');

%% outports
power = xOutport('power');

%% diagram

% block: single_pol/spect_power/power/c_to_ri
c_to_ri_out1 = xSignal;
c_to_ri_out2 = xSignal;
c_to_ri = xBlock(struct('source', 'casper_library_misc/c_to_ri', 'name', 'c_to_ri'), ...
                        struct('n_bits', BitWidth, ...
                               'bin_pt', BitWidth-1), ...
                        {c}, ...
                        {c_to_ri_out1, c_to_ri_out2});

% block: single_pol/spect_power/power/imag_square
imag_square_out1 = xSignal;
imag_square = xBlock(struct('source', 'Mult', 'name', 'imag_square'), ...
                            struct('latency', mult_latency, ...
                                   'placement_style', 'Rectangular shape'), ...
                            {c_to_ri_out2, c_to_ri_out2}, ...
                            {imag_square_out1});

% block: single_pol/spect_power/power/power_adder
real_square_out1 = xSignal;
power_adder = xBlock(struct('source', 'AddSub', 'name', 'power_adder'), ...
                            struct('latency', add_latency, ...
                                   'precision', 'Full', ...
                                   'use_behavioral_HDL', 'on', ...
                                   'use_rpm', 'on'), ...
                            {real_square_out1, imag_square_out1}, ...
                            {power});

% block: single_pol/spect_power/power/real_square
real_square = xBlock(struct('source', 'Mult', 'name', 'real_square'), ...
                            struct('latency', mult_latency), ...
                            {c_to_ri_out1, c_to_ri_out1}, ...
                            {real_square_out1});



end

