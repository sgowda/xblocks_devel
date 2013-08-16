function dsp48e_ctrl_init_xblock(blk, varargin)
defaults = {'opmode', '0000000', ...
    'alumode', '0000', ...
    'carryin', '0', ...
    'carryinsel', '000', ...
    'consolidate_ports', 1};

opmode = get_var('opmode', 'defaults', defaults, varargin{:});
alumode = get_var('alumode', 'defaults', defaults, varargin{:});
carryin = get_var('carryin', 'defaults', defaults, varargin{:});
carryinsel = get_var('carryinsel', 'defaults', defaults, varargin{:});
consolidate_ports = get_var('consolidate_ports', 'defaults', defaults, varargin{:});

%% Error checking for input types
if ~strcmp(class(opmode), 'char')
    error(sprintf('opmode is the wrong type: %s', class(opmode)))
end

if ~strcmp(class(alumode), 'char')
    error(sprintf('alumode is the wrong type: %s', class(alumode)))
end

if ~strcmp(class(carryin), 'char')
    error(sprintf('carryin is the wrong type: %s', class(carryin)))
end

if ~strcmp(class(carryinsel), 'char')
    error(sprintf('carryinsel is the wrong type: %s', class(carryinsel)))
end

% Check bitwidths
if ~(length(opmode) == 7)
    error(sprintf('opmode is the wrong length: %d', length(opmode)))
end

if ~(length(alumode) == 4)
    error(sprintf('alumode is the wrong length: %d', length(alumode)))
end

if ~(length(carryin) == 1)
    error(sprintf('carryin is the wrong length: %d', length(carryin)))
end

if ~(length(carryinsel) == 3)
    error(sprintf('carryinsel is the wrong length: %d', length(carryinsel)))
end


%% diagram

% block: butterfly/apbw/dsp48e_ctrl_init_xblock/Concat
if consolidate_ports
    carryinsel0_out1 = xSignal('carryinsel0');
    carryin0_out1 = xSignal('carryin0');
    alumode0_out1 = xSignal('alumode0');
    opmode0_out1 = xSignal('opmode0');
    
    Out1 = xOutport('dsp48e_op');
    Concat = xBlock(struct('source', 'Concat', 'name', 'Concat'), ...
                           struct('num_inputs', 4), ...
                           {carryinsel0_out1, carryin0_out1, alumode0_out1, opmode0_out1}, ...
                           {Out1});
                       
else
    opmode0_out1 = xOutport('opmode');
    alumode0_out1 = xOutport('alumode');
    carryin0_out1 = xOutport('carryin');
    carryinsel0_out1 = xOutport('carryinsel');
end

% block: butterfly/apbw/dsp48e_ctrl_init_xblock/alumode0
alumode0 = xBlock(struct('source', 'Constant', 'name', 'alumode0'), ...
                         struct('const', bin2dec(alumode), ...
                                'arith_type', 'Unsigned', ...
                                'n_bits', 4, ...
                                'bin_pt', 0), ...
                         {}, ...
                         {alumode0_out1});

% block: butterfly/apbw/dsp48e_ctrl_init_xblock/carryin0
carryin0 = xBlock(struct('source', 'Constant', 'name', 'carryin0'), ...
                         struct('const', bin2dec(carryin), ...
                                'arith_type', 'Unsigned', ...
                                'n_bits', 1, ...
                                'bin_pt', 0), ...
                         {}, ...
                         {carryin0_out1});

% block: butterfly/apbw/dsp48e_ctrl_init_xblock/carryinsel0
carryinsel0 = xBlock(struct('source', 'Constant', 'name', 'carryinsel0'), ...
                            struct('const', bin2dec(carryinsel), ...
                                   'arith_type', 'Unsigned', ...
                                   'n_bits', 3, ...
                                   'bin_pt', 0), ...
                            {}, ...
                            {carryinsel0_out1});

% block: butterfly/apbw/dsp48e_ctrl_init_xblock/opmode0
opmode0 = xBlock(struct('source', 'Constant', 'name', 'opmode0'), ...
                        struct('const', bin2dec(opmode), ...
                               'arith_type', 'Unsigned', ...
                               'n_bits', 7, ...
                               'bin_pt', 0), ...
                        {}, ...
                        {opmode0_out1});

end
