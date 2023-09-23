classdef BinaryMaskTarget < Target
    % *********************************************************************
    % *                            PROPERTIES                             *
    % *********************************************************************
    
    properties (SetAccess = immutable, GetAccess = public)
        sTrueClassName
        sFalseClassName
    end
    
    % *********************************************************************
    % *                       SCALAR TARGET METHODS                       *
    % *********************************************************************
    methods
        function obj = BinaryMaskTarget(sMaskFilepath, sTargetName, NameValueArgs)
            %obj = BinaryMaskTarget(sMaskPath, 'sTargetName', 'CancerNoCancerMasks')
           arguments
               sMaskFilepath
               sTargetName
               NameValueArgs.sCentreID
               NameValueArgs.sPatientID
               NameValueArgs.sSlideID
               NameValueArgs.sTileID
               NameValueArgs.bFromTCGA
               NameValueArgs.sTargetDescription
           end
            
           % Use the mask path as the target source
           sTargetSource = sMaskFilepath;
           
           % If this is from the TCGA, use TCGA tools to automatically
           % assign IDs
           if isfield(NameValueArgs,'bFromTCGA') && NameValueArgs.bFromTCGA
               
               % Deconstruct the filename for the IDs
               sTileFilepath = strrep(sMaskFilepath, TileImagesUtils.sMaskCode, "");
               [NameValueArgs.sCentreID, NameValueArgs.sPatientID, NameValueArgs.sSlideID, NameValueArgs.sTileID] =...
                   TCGAUtils.GetIDsFromTileFilepaths(sTileFilepath);
           end
           
           c1xNameValueArgs = MyGeneralUtils.ConvertNameValueArgsStructToCell(NameValueArgs,'vsFieldsToIgnore','bFromTCGA');
           obj = obj@Target(sTargetName, sTargetSource, c1xNameValueArgs{:});
           
        end
        
        function oPercentCoverageTarget = ConvertToPercentCoverageTarget(obj)

            m3bMask = imread(obj.GetMaskPath());
            dPercentCoverage = (sum(m3bMask(:)))/numel(m3bMask);

            c1xObjInfo = MyGeneralUtils.ConvertObjToCellArray(obj, 'vsPropertiesToIgnore',...
                ["sTargetName", "sTargetSource","sTrueClassName","sFalseClassName"]);
            oPercentCoverageTarget = ScalarTarget(dPercentCoverage, obj.sTargetName, obj.sTargetSource, c1xObjInfo{:});                        
        end

    end
    
    % GETTERS
    methods
        function chMaskPath = GetMaskPath(obj)
            chMaskPath = obj.sTargetSource();
        end
        function chTarget = GetTargetForPython(obj)
            chTarget = obj.GetMaskPath();
        end
    end
    
    % *********************************************************************
    % *                       TARGET VECTOR METHODS                       *
    % *********************************************************************
    
    % *********************************************************************
    % *                   TARGET-SPECIFIC TILE METHODS                    *
    % *********************************************************************
    
   methods (Static)
       function voTiles = MakeTilesWithMaskTargetsFromDir(sTileAndMaskDir, sTargetName,NameValueArgs)
           arguments
               sTileAndMaskDir string
               sTargetName
               NameValueArgs.bFromTCGA
               NameValueArgs.sTargetDescription
               NameValueArgs.sTargetSource
               NameValueArgs.sPartialFileDirectory
           end
            
           % Get list of masks in dir
           stMasksInDir = dir(sTileAndMaskDir + "*" + TileImagesUtils.sMaskCode + "*");
           if isempty(stMasksInDir)
               error("BinaryMaskTarget:EmptyDir",...
                   "The target directory does not have any images with a names following this expression: " + TileImagesUtils.sMaskCode)
           end
           
           % Maks vector of tiles
           c1oTiles = cell(length(stMasksInDir), 1);
           
           for iMask = 1:length(stMasksInDir)
               
               % Make target
               chMaskFilepath = sTileAndMaskDir + stMasksInDir(iMask).name;
               c1xNameValueArgs = MyGeneralUtils.ConvertNameValueArgsStructToCell(NameValueArgs, 'vsFieldsToIgnore',"sPartialFileDirectory");
               oMask = BinaryMaskTarget(chMaskFilepath, sTargetName, c1xNameValueArgs{:});

               % Make TileWithTarget object, passing in target
               chTileFilepath = strrep(chMaskFilepath, TileImagesUtils.sMaskCode, '');
               try
               if isfield(NameValueArgs,'bFromTCGA') && NameValueArgs.bFromTCGA
                   c1oTiles{iMask} = TileWithTarget(chTileFilepath, oMask, 'bFromTCGA', NameValueArgs.bFromTCGA);
               else
                   c1oTiles{iMask} = TileWithTarget(chTileFilepath, oMask);
               end
               catch oMessage
                   if strcmp(oMessage.identifier, 'MATLAB:validators:mustBeFile')
                       warning("Tile not found for mask, so object not created for this mask" + oMask.GetMaskPath())
                       continue
                   else
                       rethrow(oMessage)
                   end
               end
               
               % Save every 10,000 masks if a partial progress directory was given
               if rem(iMask, 10000) == 0 && ~isempty(NameValueArgs.sPartialFileDirectory)
                   save(NameValueArgs.sPartialFileDirectory + "\Workspace_PartialTiles.mat")
               end               
               
           end
           % Remove empty cell (this happens if a mask was skipped because
           % its corresponding tile was not found)
           c1oTiles(cellfun(@isempty,c1oTiles)) = [];
           voTiles = CellArrayUtils.CellArrayOfObjects2MatrixOfObjects(c1oTiles);
       end
       
       function voTiles = ConvertTilesBinaryMaskTargetsToPercentCoverageTargets(voTiles)

           for iTile = 1:length(voTiles)
               voTiles(iTile).oTarget = voTiles(iTile).oTarget.ConvertToPercentCoverageTarget();
           end
       end
   end
end

