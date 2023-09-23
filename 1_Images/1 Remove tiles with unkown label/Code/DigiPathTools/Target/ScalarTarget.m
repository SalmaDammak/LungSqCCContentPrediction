classdef ScalarTarget < Target
    % *********************************************************************
    % *                            PROPERTIES                             *
    % *********************************************************************
    
    properties (SetAccess = immutable, GetAccess = public)
        dValue
%         dTheoreticalMin = inf;
%         dTheoreticalMax = inf;
    end
    
    % *********************************************************************
    % *                       SCALAR TARGET METHODS                       *
    % *********************************************************************
    methods
        function obj = ScalarTarget(dValue, sTargetName, sTargetSource, NameValueArgs)
                arguments
                % must be given
                dValue 
                sTargetName                
                sTargetSource
                
                % At least one ID must be given
                NameValueArgs.sCentreID
                NameValueArgs.sPatientID
                NameValueArgs.sSlideID
                NameValueArgs.sTileID
                
                % Optional
                NameValueArgs.sTargetDescription
                NameValueArgs.sTrueClassName
                NameValueArgs.sFalseClassName
            end
            
            c1xNameValueArgs = MyGeneralUtils.ConvertNameValueArgsStructToCell(NameValueArgs);
            obj = obj@Target(sTargetName, sTargetSource, c1xNameValueArgs{:});
            
            obj.dValue = dValue;
        end
    end
    
    methods
        function oBinaryTarget = ConvertToBinaryTarget(obj, NameValueArgs)
            arguments
                obj
                NameValueArgs.dPositiveIsMoreThanThreshold
            end
            
            if isfield(NameValueArgs, 'dPositiveIsMoreThanThreshold')
                bValue = obj.GetValue() > NameValueArgs.dPositiveIsMoreThanThreshold;
            end

            c1xObjInfo = MyGeneralUtils.ConvertObjToCellArray(obj,'vsPropertiesToIgnore', ["sTargetName", "sTargetSource", "dValue"]);            
            oBinaryTarget = BinaryTarget(bValue, obj.sTargetName, obj.sTargetSource, c1xObjInfo{:});    
        end
    end
    
    methods
        function dValue = GetValue(obj)
            dValue = obj.dValue;
        end
        function dValue = GetTargetForPython(obj)
            dValue = obj.GetValue();
        end
    end
    
    % *********************************************************************
    % *                       TARGET VECTOR METHODS                       *
    % *********************************************************************
    methods (Static)

    end
    
    % *********************************************************************
    % *                   TARGET-SPECIFIC TILE METHODS                    *
    % *********************************************************************
    methods (Static)
        function voTiles = ConvertTilesScalarTargetsToBinaryScalarTargets(voTiles, NameValueArgs)
            arguments
                voTiles
                NameValueArgs.dPositiveIsMoreThanThreshold
            end
            for iTile = 1:length(voTiles)
                c1xNameValueArgs = MyGeneralUtils.ConvertNameValueArgsStructToCell(NameValueArgs);
                voTiles(iTile).oTarget = voTiles(iTile).oTarget.ConvertToBinaryTarget(c1xNameValueArgs{:});
            end
        end
    end
    
end

