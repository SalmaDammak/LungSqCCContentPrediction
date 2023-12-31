classdef TileWithTarget < Tile
    %TileWithTraget
    %
    % Tile with a target is a class representing a sub-image of a whole 
    % slide image (WSI) called a tile (or patch), INHERITING from Tile, but
    % which also CONTAINS a target object. The key role of this class is to
    % link each tile object with a target object and to get targets with
    % respect to their tiles.     
    
    % Created by: Salma Dammak
    % Created: Aug 08, 2022
    % *********************************************************************
    % *                            PROPERTIES                             *
    % *********************************************************************
    
    properties
        oTarget
    end
    
    % *********************************************************************
    % *                        SCALAR TILE METHODS                        *
    % *********************************************************************
    
    % CONSTRUCTOR
    methods
        
        function obj = TileWithTarget(sTileFilepath, oTarget, NameValueArgs)
            arguments
                sTileFilepath (1,1) string {mustBeFile, MyValidationUtils.MustBeA2DImageFilepath}
                oTarget (1,1) Target
                NameValueArgs.bFromTCGA (1,1) logical
            end
            c1xNameValueArgs = MyGeneralUtils.ConvertNameValueArgsStructToCell(NameValueArgs);
            obj = obj@Tile(sTileFilepath, c1xNameValueArgs{:});
            obj.oTarget = oTarget;
        end
        
    end
    
    % *********************************************************************
    % *                        TILE VECTOR METHODS                        *
    % *********************************************************************
   
    methods (Static)
    function voTiles = MakeTilesWithSameTarget(chTileDir,oTarget, NameValueArgs)
        %TileWithTarget.MakeTilesWithSameTarget(chTileDir,oTarget,'chFilterByMaskDir', chMaskDir, 'dPercentMinInMask', 1)
        arguments
            chTileDir (1,:) char {mustBeText,...
                    MyValidationUtils.MustBeExistingDir,...
                    MyValidationUtils.MustBeNonEmptyDir}
            oTarget
            NameValueArgs.chFilterByMaskDir
            NameValueArgs.dPercentMinInMask (1,:) double...
                {mustBeInRange(NameValueArgs.dPercentMinInMask,0,1)}
        end
        
        % Get list of tiles in dir
        stTiles = dir(chTileDir + "\" + QuPathUtils.sImageRegexp);
        
        % Pre-allocate cell array
        c1oTiles = cell(length(stTiles), 1);
        
        % Loop through tiles
        for iTileIdx = 1:length(c1oTiles)
            
            %MyGeneralUtils.DispLoopProgress(iTileIdx, length(c1oTiles))
            
            % Get full tile path
            sTileName = string(stTiles(iTileIdx).name);
            sTilePath = string(chTileDir) + "\" + sTileName;
            
            % If chFilterByMask isn't empty
            if any(contains(fields(NameValueArgs), 'chFilterByMaskDir'))
            
                % Get mask path
                sExtentsion = string(MyGeneralUtils.GetFileExtension(sTileName));
                sMaskFileName = strrep(sTileName,...
                    "." + sExtentsion, TileImagesUtils.sMaskCode + "." + sExtentsion);
                sMaskPath = string(chTileDir) + "\" + sMaskFileName;
                                
                % Read mask
                try
                m2bMask = imread(sMaskPath);
                catch oME
                    if strcmp(oME.identifier, 'MATLAB:imagesci:imread:fileDoesNotExist')
                        warning("Tile does not have mask and therefore skipped:" + newline + sTileName)
                        continue
                    end
                end
                dPercentPositive = sum(m2bMask(:))/numel(m2bMask);
                
                % If < min in mask, skip tile
                if dPercentPositive < NameValueArgs.dPercentMinInMask                
                    continue
                end
            end
            
            % Make tile object with given object
            c1oTiles{iTileIdx} = TileWithTarget(sTilePath, oTarget, 'bFromTCGA', true);
            
        end
        
        % Clear empty cells
        c1bEmptyCells = cellfun(@isempty, c1oTiles, 'UniformOutput', false);
        c1oTiles = c1oTiles(~[c1bEmptyCells{:}]);
        
        voTiles = CellArrayUtils.CellArrayOfObjects2MatrixOfObjects(c1oTiles);        
    end
    
    % GETTERS
    
        function voTargets = GetTargets(voTiles)
            arguments
                voTiles (:,1) TileWithTarget {mustBeVector}
            end
            % Pre-allocate to manage memory as these arrays are often very
            % large. It is easier to set this up as a cell array then
            % convert it to a vector of objects in MATLAB, that's why I'm
            % using that instead of tile.empty(length(voTiles), 0). The
            % latter needs to be filled backwards.
            c1oTargets = cell(length(voTiles), 1);
            
            for iTile = 1:length(voTiles)
                c1oTargets{iTile} = voTiles(iTile).oTarget.GetTargetForPython();
            end
            
            % Thsi method is from BOLT, written by David DeVries
            voTargets = CellArrayUtils.CellArrayOfObjects2MatrixOfObjects(c1oTargets);
        end
    end
    
    
    % FOR PYTHON
    methods (Static)
        
        function tData = ConvertToTableForPython(voTiles)
            arguments
                voTiles (:,1) TileWithTarget {mustBeVector}
            end
            %tData = TileWithTarget.ConvertToTableForPython(voTiles)
            %
            % Keras imageDataGenerator requires a list of filepaths in one
            % column, with the target in another column. This method
            % prepares that.
            
            % Pre-allocate to manage memory as these arrays are often very
            % large
            c1sPaths = cell(length(voTiles),1);
            c1xLabels = cell(length(voTiles),1);
            
            % Get tile info and target info in the same loop. I chose not 
            % to use TileWIthTragets.GetTargetsForPython() and 
            % Tile.GetTilePaths() to avoid any chance that the tiles and
            % their targets get decoupled.
            for iTile = 1:length(voTiles)
                c1sPaths{iTile} = voTiles(iTile).GetTileFilepath();
                c1xLabels{iTile} = voTiles(iTile).oTarget.GetTargetForPython();
            end           
            
            tData = table(c1sPaths, c1xLabels);
        end
        
    end
    
end

