classdef (Abstract)Target
%classdef Target
    % *********************************************************************
    % *                            PROPERTIES                             *
    % *********************************************************************
    
    % IDENTIFIERS
    properties (SetAccess = immutable, GetAccess = public)
        % At least one of these muct be provided
        sCentreID = "not given";
        sPatientID = "not given";
        sSlideID = "not given";
        sTileID = "not given";
    end
    
    properties (SetAccess = immutable, GetAccess = public)
        sTargetName
        sTargetDescription = ""
        sTargetSource
    end
    
    % *********************************************************************
    % *                       SCALAR TARGET METHODS                       *
    % *********************************************************************
    methods  
        function obj = Target(sTargetName, sTargetSource, NameValueArgs)
            arguments
                sTargetName
                sTargetSource                
                
                % At least one ID must be given
                NameValueArgs.sCentreID
                NameValueArgs.sPatientID
                NameValueArgs.sSlideID
                NameValueArgs.sTileID
                
                % Optional
                NameValueArgs.sTargetDescription
            end
            
            obj.sTargetName = sTargetName;
            obj.sTargetSource = sTargetSource;
            
            if isfield(NameValueArgs, 'sTargetDescription')
                obj.sTargetDescription = NameValueArgs.sTargetDescription;
            end
            
            % Make sure at least one ID is given
            c1chIDsGiven = fields(NameValueArgs);
            if ~isfield(NameValueArgs, 'sCentreID') && ~isfield(NameValueArgs, 'sPatientID')...
                    && ~isfield(NameValueArgs, 'sSlideID') && ~isfield(NameValueArgs, 'sTileID')
                error("You must give at least one ID (input as a NameValueArg:"+ newline +...
                    "e.g., Target(sTargetName, sTargetDescription, sTargetSource, 'sCentreID', '43')");
            end
            
            for iFieldIdx = 1:length(c1chIDsGiven)
                chCurrentField = c1chIDsGiven{iFieldIdx};
                if isfield(NameValueArgs, chCurrentField)
                    obj.(chCurrentField) = NameValueArgs.(chCurrentField);
                end
            end
            
            
        end
    end
    methods (Abstract)
%          chTarget = GetTargetForPython(obj)
        
    end
    
    % *********************************************************************
    % *                       TARGET VECTOR METHODS                       *
    % *********************************************************************
    methods (Static)

    end
    
    methods (Abstract)
    end
end

