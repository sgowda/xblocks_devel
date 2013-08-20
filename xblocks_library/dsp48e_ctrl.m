function [opmode_sig, alumode_sig, carryin_sig, carryinsel_sig] = ...
    dsp48e_ctrl(name, opmode, alumode, carryin, carryinsel)

opmode_sig = xSignal();
alumode_sig = xSignal();
carryin_sig = xSignal();
carryinsel_sig = xSignal();

config.source = @dsp48e_ctrl_init_xblock;
config.name = name;
xBlock(config, {[], 'opmode', opmode, 'alumode', alumode, 'carryin', carryin, ...
    'carryinsel', carryinsel, 'consolidate_ports', 0}, {}, ...
    {opmode_sig, alumode_sig, carryin_sig, carryinsel_sig});
