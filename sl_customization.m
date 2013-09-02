function sl_customization(cm)
    % List of supported Operating Systems for ESLIN
    supportedOSList = {'PCWIN','GLNX86','GLNXA64','PCWIN64'};       

    % Didn't use strmatch due to speed and strcmpi because we the case
    % should match exactly.
    issupportedOS = any(strcmp(computer,supportedOSList));

    if (issupportedOS)
        cm.addSigScopeMgrViewerLibrary('lfiviewerlib');
    end
    
    cm.LibraryBrowserCustomizer.applyOrder( {'simulink', -5, 'xbs_r4', -4, 'casper_library', -3, 'xps_library', -2, 'simulink_xsg_bridge', -1} );
end
