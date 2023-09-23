classdef BinaryTarget < Target
    % *********************************************************************
    % *                            PROPERTIES                             *
    % *********************************************************************
    
    properties (SetAccess = immutable, GetAccess = public)
        bValue
        sTrueClassName
        sFalseClassName
    end
    
    % *********************************************************************
    % *                       SCALAR TARGET METHODS                       *
    % *********************************************************************
    methods
        function obj = BinaryTarget(bValue, sTargetName, sTargetSource, NameValueArgs)
            arguments
                % must be given
                bValue
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
            obj = obj@Target(sTargetName, sTargetSource,c1xNameValueArgs{:});
            
            obj.bValue = bValue;
            
        end
    end
    
    % GETTERS
    methods
        function bValue = GetValue(obj)
            bValue = obj.bValue;
        end
        function bTarget = GetTargetForPython(obj)
            bTarget = obj.GetValue();
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
        %         function voTiles = SelectPositiveTiles(voTiles)
        %         end
    end
    
    methods (Static)
        %         function [voTrainTiles, voTestTiles] = SplitTileVectorIntoTrainAndTestTiles...
        %                 (voTilesWithTargets, dMinPositive, dMinNegative)
        %         end
        %
        %         function ConvertScalarTargetsInTiles...
        %                 (oTilesWithTargets, NameValueArgs)
        %         end
        %
        %         function ConvertBinaryMaskTargetsInTiles...
        %                 (oTilesWithTargets, NameValueArgs)
        %         end
        

    end
end

