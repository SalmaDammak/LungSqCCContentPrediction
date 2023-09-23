classdef Tile
    %Tile
    %
    % Tile is a class representing a sub-image of a whole slide image
    % (WSI) called a tile (or patch). It allows for organizing meta
    % information about the tile and how it relates to the WSI, plus it
    % allows for methods to manage a collection of tiles in the form of a
    % vector of tiles.
    
    % Created by: Salma Dammak
    % Created: Aug 08, 2022
    
    % *********************************************************************
    % *                            PROPERTIES                             *
    % *********************************************************************
    
    % IDENTIFIERS
    properties (SetAccess = immutable, GetAccess = public)
        sCentreID
        sPatientID
        sSlideID
        sTileID
    end
    
    % IMAGE PROPERTIES
    properties
        sTileFilepath
        sFilename
        sImageExtension
        sChannels = "RGB(default)"
        sStain = "H&E(default)"
    end
    
    % SIZE
    properties (SetAccess = immutable, GetAccess = public)
        dResizeFactor
        dWidth_Pixels
        dHeight_Pixels
    end
    
    % LOCATION
    properties (SetAccess = immutable, GetAccess = public)
        dTileUpperRightCornerLocationInSourceSlideX_Pixels
        dTileUpperRightCornerLocationInSourceSlideY_Pixels
    end
    
    % *********************************************************************
    % *                        SCALAR TILE METHODS                        *
    % *********************************************************************
    
    % CONSTRUCTOR
    methods
        function obj = Tile(sTileFilepath, NameValueArgs)
            arguments
                sTileFilepath
                NameValueArgs.sCentreID
                NameValueArgs.sPatientID
                NameValueArgs.sSlideID
                NameValueArgs.sTileID
                NameValueArgs.sStain
                NameValueArgs.sChannels
                NameValueArgs.bFromTCGA
            end
            
            % IDENTIFIERS
            obj.sTileFilepath = sTileFilepath;
            vsFileparts = split(sTileFilepath, filesep);
            obj.sFilename = vsFileparts(end);
            
            if isfield(NameValueArgs,'bFromTCGA') && NameValueArgs.bFromTCGA
                
                % Get the info from the filename
                [obj.sCentreID, obj.sPatientID, obj.sSlideID, obj.sTileID] = TCGAUtils.GetIDsFromTileFilepaths(sTileFilepath);
            else
                obj.sCentreID = NameValueArgs.sCentreID;
                obj.sPatientID = NameValueArgs.sPatientID;
                obj.sSlideID = NameValueArgs.sSlideID;
                obj.sTileID = NameValueArgs.sTileID;
            end
            
            % IMAGE PROPERTIES
            obj.sImageExtension = regexp(obj.sFilename, '.*\.([a-zA-Z]+)', 'tokens','once');
            if isfield(NameValueArgs,'sChannels') % default in properties
                obj.sChannels = NameValueArgs.sChannels;
            end
            if isfield(NameValueArgs,'sStain') % default in properties
                obj.sStain = NameValueArgs.sStain;
            end
            
            % LOCATION AND SIZE
            [dXOrigin, dYOrigin, dWidth, dHeight, dResizeFactorValue] = QuPathUtils.GetTileCoordinatesFromName(sTileFilepath);
            obj.dTileUpperRightCornerLocationInSourceSlideX_Pixels = dXOrigin;
            obj.dTileUpperRightCornerLocationInSourceSlideY_Pixels = dYOrigin;
            obj.dWidth_Pixels =  dWidth;
            obj.dHeight_Pixels = dHeight;
            obj.dResizeFactor = dResizeFactorValue;
        end
        
    end
    
    % GETTERS
    methods
        
        function sCentreID = GetCentreID(obj)            
            sCentreID = obj.sCentreID;
        end
        
        function sPatientID = GetPatientID(obj)
            sPatientID = obj.sPatientID;
        end
        
        function sSlideID = GetSlideID(obj)
            sSlideID = obj.sSlideID;
        end
        
        function sFileTilepath = GetTileFilepath(obj)
            sFileTilepath = obj.sTileFilepath;
        end    
    end

    
    % *********************************************************************
    % *                        TILE VECTOR METHODS                        *
    % *********************************************************************
    
    % GETTERS
    methods (Static)
        
        function vsCentreIDs = GetCentreIDs(voTiles)
            vsCentreIDs = strings(length(voTiles), 1);
            for iTile = 1:length(voTiles)
                vsCentreIDs(iTile) = voTiles(iTile).GetCentreID();
            end
        end
        
        function vsPatientIDs = GetPatientIDs(voTiles)
            vsPatientIDs = strings(length(voTiles), 1);
            for iTile = 1:length(voTiles)
                vsPatientIDs(iTile) = voTiles(iTile).GetPatientID();
            end
        end
        
        function vsSlideIDs = GetSlideIDs(voTiles)
            vsSlideIDs = strings(length(voTiles), 1);
            for iTile = 1:length(voTiles)
                vsSlideIDs(iTile) = voTiles(iTile).GetSlideID();
            end
        end
    end
    
    % SPECIAL FINDERS/SELCTORS
    methods (Static)
        
        function vbIndices = FindTilesWithTheseIDs(voTiles, vsIDs, NameValueArgs)
            arguments
                voTiles
                vsIDs
                NameValueArgs.bByCentreIDs (1,1) logical = false
                NameValueArgs.bByPatientIDs (1,1) logical = false
                NameValueArgs.bBySlideIDs (1,1) logical = false
            end
            
            % Get group IDs based on what is used
            if NameValueArgs.bByPatientIDs
                vsGroupIDs = Tile.GetPatientIDs(voTiles);
            elseif NameValueArgs.bByCentreIDs
                vsGroupIDs = Tile.GetCentreIDs(voTiles);
            elseif NameValueArgs.bBySlideIDs
                vsGroupIDs = Tile.GetSlideIDs(voTiles);
            end
            
            % Loop through the IDs to see which elements match it
            vbIndices = false(length(vsGroupIDs),1);
            for iID = 1:length(vsIDs)
                sCurrentID = vsIDs(iID);
                vbCurrentIDIndices = vsGroupIDs == sCurrentID;
                
                % This operation turns the current ID indices to true in
                % the overall "selector" vector
                vbIndices = or(vbIndices, vbCurrentIDIndices);
            end
            
        end
    end
    
    % DATA SPLIT METHODS
    methods (Static)
        
        function [vbTrainTileIndices, vbTestTileIndices] = PerformRandomTwoWaySplit(...
                voTiles, dFractionGroupsInTraining, NameValueArgs)
            arguments
                voTiles
                dFractionGroupsInTraining
                NameValueArgs.bByCentreID (1,1) logical = false
                NameValueArgs.bByPatientID (1,1) logical = false
                NameValueArgs.bBySlideIDs (1,1) logical = false
            end
            
            % Get group IDs based on what is used for splitting
            if NameValueArgs.bByPatientID
                vsGroupIDs = Tile.GetPatientIDs(voTiles);
                chGroupName = 'bByPatientIDs';
            elseif NameValueArgs.bByCentreID
                vsGroupIDs = Tile.GetCentreIDs(voTiles);
                chGroupName = 'bByCentreIDs';
            elseif NameValueArgs.bBySlideIDs
                vsGroupIDs = Tile.GetSlieIDs(voTiles);
                chGroupName = 'bBySlideIDs';
            end
            
            vsUniqueGroupIDs = unique(vsGroupIDs);
            dNumGroups = length(vsUniqueGroupIDs);
            
            % Get whole number of groups for training from fraction
            dNumTrainGroups = round(dNumGroups * dFractionGroupsInTraining);
            
            % Randomly select which groups will go in training.
            dMaxRandomNumber = dNumGroups;
            dNumRandomNumbers = dNumTrainGroups;
            vdTrainGroupIndices = randperm(dMaxRandomNumber, dNumRandomNumbers);
            vsTrainGroups = vsUniqueGroupIDs(vdTrainGroupIndices);
            
            % Find the corresponding tiles
            vbTrainTileIndices = Tile.FindTilesWithTheseIDs(voTiles, vsTrainGroups, chGroupName, true);
            vbTestTileIndices = ~vbTrainTileIndices;
        end    
        
    end  
 end

