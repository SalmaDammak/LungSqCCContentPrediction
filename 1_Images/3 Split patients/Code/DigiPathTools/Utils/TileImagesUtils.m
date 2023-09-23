classdef TileImagesUtils
    %TileImagesUtils
    %
    % A collection of uttilities to manage the tile images that are output
    % by QuPath onto the drive. This anything from pre-processing their labelmap,
    % to rearranging the images in a different folder structure.
    
    % Author: Salma Dammak
    % Created: Jun 22, 2022
    % Last update: July 18, 2022
    
    
    % *********************************************************************   ORDERING: 1 Abstract        X.1 Public       X.X.1 Not Constant
    % *                            PROPERTIES                             *             2 Not Abstract -> X.2 Protected -> X.X.2 Constant
    % *********************************************************************                               X.3 Private
    
    properties (Access = public, Constant = true)
        sMaskCode = "-mask";
        chMaskRegexp = 'TCGA*-mask.png';
    end
    
    % *********************************************************************
    % *                          PUBLIC METHODS                           *
    % *********************************************************************
    
    methods (Access = public, Static = true)
        
        function RemoveTilesWithNoLabelmapInDir(chTileAndLabelmapDir) % TO: update to look for masked images, and remove everything else, likely quicker
            %RemoveTileWithNoLabelmapInDir(chTileAndLabelmapDir)
            %
            % DESCRIPTION:
            %   I made this because QuPath 1 would output all the tiles,
            %   with or without a labelmap, and I needed to remove the tiles
            %   outside the ROI (as inidicated by having a labelmap to free up
            %   drive space.
            %
            %   IMPORTANT: this function
            %   Assumes tiles and labelmaps are in the same folder
            %   Does not account for duplicate labelmaps
            %
            % INPUT ARGUMENTS:
            %  chTileAndLabelmapDir: directory where the labelmaps and tiles were
            %   dumped by QuPath
            %  bQuPath1 : flag to use naming convetion of QuPath 1. Use if
            %   the image was tiled using QuPath 1
            %
            % OUTPUTS ARGUMENTS:
            %  none. The output is a modification of the input directory.
            
            % Author: Salma Dammak
            % Last modified: Jun 22, 2022
            
            arguments
                chTileAndLabelmapDir (1,:) char {mustBeText,...
                    MyValidationUtils.MustBeExistingDir,...
                    MyValidationUtils.MustBeDirPath,...
                    MyValidationUtils.MustBeNonEmptyDir}
            end
            oQuPathUtils = QuPathUtils();
            
            % Get all tile paths
            stTilePaths = dir([chTileAndLabelmapDir, char(oQuPathUtils.sImageRegexp)]);
            if isempty(stTilePaths)
                error('TileImagesUtils:EmptyDir',...
                    ['The target directory does not have any images with a names following this expression: ',char(oQuPathUtils.sImageRegexp)])
            end
            
            % Get all labelmap paths
            stLabelmapPaths = dir([chTileAndLabelmapDir, char(oQuPathUtils.sLabelmapRegexp)]);
            if isempty(stLabelmapPaths)
                error('TileImagesUtils:EmptyDir',...
                    ['The target directory does not have any images with a names following this expression: ',char(oQuPathUtils.sLabelmapRegexp)])
            end
            
            dNumberOftilesRemoved = 0;
            
            % Go through all tile paths
            for i = 1 : length(stTilePaths)
                
                % Derive the labelmap path from the tile path
                chCurrentTileName = stTilePaths(i).name;
                chLabelmapName = strrep(chCurrentTileName, '.png', [char(oQuPathUtils.sLabelmapCode),'.png']);
                
                % If tile path with -labels does not exists in labelmap paths, remove from dir
                % Otherwise, skip it
                if ~any(contains({stLabelmapPaths(:).name}, chLabelmapName))
                    delete([stTilePaths(i).folder, '\', stTilePaths(i).name])
                    dNumberOftilesRemoved = dNumberOftilesRemoved + 1;
                end
            end
            
            dNumTiles = length(stTilePaths);
            disp("The original number of tiles is " + num2str(dNumTiles)+...
                ". The number of tiles removed is " + num2str(dNumberOftilesRemoved) + ...
                " (" + num2str((dNumberOftilesRemoved/dNumTiles)*100)+ "% of the original number).")
        end
        
        function [c1chPathsOfLabelmapsWithBadLabels, c1chSlidesWithBadLabels] = ...
                VerifyLabelmapsForBadROILabels(chTileAndLabelmapDir, vdAcceptableROILabels)
            %[c1chPathsOfLabelmapsWithBadROILabels, c1chSlidesWithBadLabels] = ...
            %   VerifyLabelmapsForBadLabels(chTileAndLabelmapDir, v1dAcceptableLabels)
            %
            % DESCRIPTION:
            %   This function checks if any labelmaps have values in them that
            %   are outside the list specified by the user.
            %   I made this because I had labelmaps come out with unexpected
            %   ROI label values, which was because the person who did the
            %   contours named the ROI labels in QuPath using a different
            %   spelling for some cases, and QuPath outputs labelmaps for
            %   mismatching ROI labels with a number not listed in the
            %   extraction scipt. This was in QuPath 1.
            %
            %   IMPORTANT: this function
            %   Assumes tiles and labelmaps are in the same folder
            %   Does not account for duplicate labelmaps
            %
            % INPUT ARGUMENTS:
            %  chTileAndLabelmapDir: directory where the labelmaps and tiles were
            %   dumped by QuPath
            %  vdAcceptableLabels: a row vector with the ROI label values that
            %   were assigned to ROI labels in the groovy script that was used
            %   to tile the image
            %  bQuPath1 : flag to use naming convetion of QuPath 1. Use if
            %   the image was tiled using QuPath 1
            %
            % OUTPUTS ARGUMENTS:
            %  c1chPathsOfLabelmapsWithBadLabels: a list of labelmap paths
            %   for inspection
            %  c1chSlidesWithBadLabels: a list of the slides the labelmaps came
            %   from for inspection
            
            % Author: Salma Dammak
            % Last modified: Jun 22, 2022
            
            arguments
                chTileAndLabelmapDir (1,:) char {mustBeText,...
                    MyValidationUtils.MustBeExistingDir,...
                    MyValidationUtils.MustBeDirPath,...
                    MyValidationUtils.MustBeNonEmptyDir}
                vdAcceptableROILabels (1,:) double
            end
            
            oQuPathUtils = QuPathUtils();
            
            % Get all labelmap paths
            stLabelmapPaths = dir([chTileAndLabelmapDir, char(oQuPathUtils.sLabelmapRegexp)]);
            
            if isempty(stLabelmapPaths)
                error('TileImagesUtils:EmptyDir',...
                    ['The target directory does not have any images with a names following this regular expression: ', char(oQuPathUtils.sLabelmapRegexp)])
            end
            
            c1chPathsOfLabelmapsWithBadLabels = {};
            c1chSlidesWithBadLabels = {};
            dBadLabelmapListIndex = 1;
            
            for i = 1 : length(stLabelmapPaths)
                
                chLabelmapPath = [chTileAndLabelmapDir, stLabelmapPaths(i).name];
                try
                    m2iLabelmap = imread(chLabelmapPath);
                catch oMe
                    disp(oMe)
                end
                viLabelmapLabels = unique(m2iLabelmap);
                
                if any(~ismember(viLabelmapLabels,vdAcceptableROILabels))
                    c1chPathsOfLabelmapsWithBadLabels{dBadLabelmapListIndex} = chLabelmapPath;
                    c1chSlidesWithBadLabels(dBadLabelmapListIndex) = regexpi(chLabelmapPath,'(TCGA-\w\w-\w\w\w\w)','match');
                    dBadLabelmapListIndex = dBadLabelmapListIndex + 1;
                    warning("A labelmap with one or more values outside the prespecifed ROI labelmap labels was encountered. "+...
                        "The labelmap path is: " + newline + chLabelmapPath + newline + "The value(s) encountered: "+...
                        strjoin(string(viLabelmapLabels(~ismember(viLabelmapLabels,vdAcceptableROILabels)))));
                    
                end
                
            end
            c1chSlidesWithBadLabels = unique(c1chSlidesWithBadLabels);
            close all
            close all hidden
            
            dNumTiles = length(stLabelmapPaths);
            dNumberOftilesRemoved = length(c1chSlidesWithBadLabels);
            disp("The original number of tiles is " + num2str(dNumTiles)+...
                ". The number of tiles removed is " + num2str(dNumberOftilesRemoved) + ...
                " (" + num2str((dNumberOftilesRemoved/dNumTiles)*100)+ "% of the original number).")
            
        end
        
        function RemoveTilesWithThisROILabel(chTileAndLabelmapDir, dROILabel, NameValueArgs)
            %RemoveTilesWithThisROILabel(chTileAndLabelmapDir, dROILabel)
            %RemoveTilesWithThisROILabel(chTileAndLabelmapDir, dROILabel,'bRemoveForAnyAmountOfLabel',true)
            %RemoveTilesWithThisROILabel(chTileAndLabelmapDir, dROILabel,'bQuPath1', true)
            %
            % DESCRIPTION:
            %   This function removes tiles and labelmaps that have a certain unwanted
            %   ROI label. This is especially useful when wanting to eliminate
            %   labelmaps that have background pixels in them. The function has
            %   two modes of functioning, the default is to remove the
            %   tiles and labelmaps that are entirely from the unwanted ROI
            %   (e.g. fully background). The other way to use it to remove
            %   tiles and labelmaps that have ANY of the unwanted ROI.
            %
            %   IMPORTANT: this function
            %   Assumes tiles and labelmaps are in the same folder
            %   It also does not account for duplicate labelmaps
            %
            % INPUT ARGUMENTS:
            %  chTileAndLabelmapDir: directory where the labelmaps and tiles were
            %   dumped by QuPath
            %  dROILabel: the ROI labelvalues that was assigned to the unwanted
            %   labeles in the groovy script that was used to tile the image
            %  bRemoveForAnyAmountOfROILabel: flag for removing tiles and labelmaps
            %   with any amount of the unwanted ROI labelas opposed to being
            %   fully of that label
            %  bQuPath1 : flag to use naming convetion of QuPath 1. Use if
            %   the image was tiled using QuPath 1
            
            % Author: Salma Dammak
            % Last modified: Jul 09, 2022
            arguments
                chTileAndLabelmapDir (1,:) char {mustBeText,...
                    MyValidationUtils.MustBeExistingDir,...
                    MyValidationUtils.MustBeDirPath,...
                    MyValidationUtils.MustBeNonEmptyDir}
                dROILabel (1,1) double
                NameValueArgs.bRemoveForAnyAmountOfROILabel= false
            end
            oQuPathUtils = QuPathUtils();
            
            % Get all labelmap paths
            stLabelmapPaths = dir([chTileAndLabelmapDir, char(oQuPathUtils.sLabelmapRegexp)]);
            
            if isempty(stLabelmapPaths)
                error('TileImagesUtils:EmptyDir',...
                    ['The target directory does not have any images with a names following this expression: ', char(oQuPathUtils.sLabelmapRegexp)])
            end
            
            dNumTiles = length(stLabelmapPaths);            
            dNumberOftilesRemoved = 0;
            
            % Go through all paths
            for i = 1 : length(stLabelmapPaths)
                
                % Get the labelmap and image path
                chLabelmapPath = [chTileAndLabelmapDir, stLabelmapPaths(i).name];
                chTilePath = strrep(chLabelmapPath, char(oQuPathUtils.sLabelmapCode), '');
                
                % Read the labelmap and get its unique labels
                m2iLabelmap = imread(chLabelmapPath);
                viLabelmapLabels = unique(m2iLabelmap);
                
                if length(viLabelmapLabels) == 1 ....
                        && viLabelmapLabels == dROILabel
                    % Delete the labelmap and corresponding image if they are
                    % fully that label
                    delete(chLabelmapPath)
                    delete(chTilePath)
                    dNumberOftilesRemoved = dNumberOftilesRemoved + 1;
                    
                elseif NameValueArgs.bRemoveForAnyAmountOfROILabel...
                        && any(m2iLabelmap(:) == dROILabel)
                    % Delete labelmap and its image with ANY of the label
                    delete(chLabelmapPath)
                    delete(chTilePath)
                    dNumberOftilesRemoved = dNumberOftilesRemoved + 1;
                end
            end
            disp("The original number of tiles is " + num2str(dNumTiles)+...
                ". The number of tiles removed is " + num2str(dNumberOftilesRemoved) + ...
                " (" + num2str((dNumberOftilesRemoved/dNumTiles)*100)+ "% of the original number).")
        end
        
        function MakeMasksFromLabelmaps(...
                chTileAndLabelmapDir, vdLabelmapLabels, vbLabelmapLabelIsForeground,...
                xForegroundROILabel, xBackgroundROILabel, NameValueArgs)
            %MakeMasksFromLabelmaps(vdLabelmapLabels,...
            %   vdLabelmapLabels, vbLabelmapLabelIsForeground)
            %MakeMasksFromLabelmaps(vdLabelmapLabels,...
            %   vdLabelmapLabels, vbLabelmapLabelIsForeground,...
            %   iForegroundLabel, iBackgroundLabel)
            %MakeMasksFromLabelmaps(vdLabelmapLabels,...
            %   vdROILabels, vbLabelmapLabelIsForeground,...
            %   iForegroundLabel, iBackgroundLabel, 'bQuPath1', true)
            % E.g.
            %   MakeMasksFromLabelmaps('D:\users\sdammak\tiles\',...
            %   [1,2,3,4,5,7], [1,1,1,0,0,0], 1, 0, 'bQuPath1', true)
            %
            % DESCRIPTION:
            %   This function transforms labelmaps with multiple labels into
            %   masks with foreground and background.
            %
            %   IMPORTANT: this function
            %   Assumes tiles and masks are in the same folder
            %   It also does not account for duplicate masks
            %
            % INPUT ARGUMENTS:
            %  vdLabelmapLabels: directory where the masks and tiles were
            %   dumped by QuPath
            %  vdLabelmapLabels: a row vector with the ROI labels values
            %   that were assigned to labels in the groovy script that was used
            %   to tile the image
            %  vbLabelmapLabelIsForeground : a row vector corresponding to the
            %   ROILabels by position to indicate which are
            %   foreground.
            %  xForegroundLabel: In the output mask, the forground mask
            %   ROI label becomes this value. Default is true.
            %  xBackgroundLabel: In the output mask, the background RPO
            %   labels label becomes this value. Default is false.
            %  bQuPath1: flag to use naming convetion of QuPath 1. Use if
            %   the image was tiled using QuPath 1
            
            % Author: Salma Dammak
            % Last modified: Jul 09, 2022
            
            arguments
                chTileAndLabelmapDir (1,:) char {mustBeText,...
                    MyValidationUtils.MustBeExistingDir,...
                    MyValidationUtils.MustBeDirPath,...
                    MyValidationUtils.MustBeNonEmptyDir}
                vdLabelmapLabels (1,:) double
                vbLabelmapLabelIsForeground (1,:) logical
                xForegroundROILabel(1,1) = true
                xBackgroundROILabel(1,1) = false
                NameValueArgs.bQuPath1 = false
            end
            
            oQuPathUtils = QuPathUtils();
            
            if length(vdLabelmapLabels) ~= length(vbLabelmapLabelIsForeground)
                error('The length of the labelmap labels vector must equal that of the vector indicating which are foreground.')
            end
            
            % Get all labelmap paths
            stMaskPaths = dir([chTileAndLabelmapDir, char(oQuPathUtils.sLabelmapRegexp)]);
            
            if isempty(stMaskPaths)
                error('TileImagesUtils:EmptyDir',...
                    ['The target directory does not have any images with a names following this expression: ', char(oQuPathUtils.sLabelmapRegexp)])
            end
            
            % Loop through all the labelmaps
            for i = 1 : length(stMaskPaths)
                
                % Track progress
                dPercentDone = (i*100)/length(stMaskPaths);
                
                if rem(dPercentDone,1) == 0
                    disp(string(dPercentDone) + "% done!");
                end
                
                % Read the labelmap and get its class labels
                chLabelmapPath = [chTileAndLabelmapDir, stMaskPaths(i).name];
                m2iLabelmap = imread(chLabelmapPath);
                viCurrentMaskLabels = unique(m2iLabelmap);
                
                % Verify that the labelmap does not contain any values outside
                % the vdROILabels provided. A value not within the
                % list could mean an error in classifying or an error in
                % the class names in the extraction code. Either way, this
                % code can't handle it because it doesn't know whether it
                % shoudl be background or foreground.
                if any(~ismember(viCurrentMaskLabels,vdLabelmapLabels))
                    error("A labelmap with one or more values outside the prespecifed labelmap ROI labels was encountered. "+...
                        "The labelmap path is: " + newline + chLabelmapPath + newline + "The value(s) encountered: "+...
                        viCurrentMaskLabels(~ismember(viCurrentMaskLabels,vdLabelmapLabels)));
                else
                    
                    % Create an empty mask of the right size
                    m2bMask = false(size(m2iLabelmap));
                    
                    % Loop through the list of ROI labels the user
                    % provided and trnsform them in the new mask to their
                    % new values
                    for iROILabel= 1:length(vdLabelmapLabels)
                        % If the ROI label is foreground give it foreground label,
                        % otherwise it'll remain as background
                        if vbLabelmapLabelIsForeground(iROILabel)
                            m2bMask(m2iLabelmap == vdLabelmapLabels(iROILabel)) = true;
                            
                        elseif ~vbLabelmapLabelIsForeground(iROILabel)
                            continue
                            
                        else
                            error("vbLabelmapLabelIsForeground is not set a value of true or false. "...
                                + newline + "Image: " + string(chLabelmapPath) + newline + "Value: " +...
                                string(vbLabelmapLabelIsForeground(iROILabel)) + ".")
                        end
                    end
                    
                    % if the users entered a forground/background ROI labeland
                    % it's not the default true and false (respectively),
                    % edit the mask to use the right labels
                    if xForegroundROILabel&& ~xBackgroundROILabel
                        m2xMask = m2bMask;
                    else
                        
                        % Create a mask that's the right type
                        if ~strcmp(class(xForegroundROILabel), class(xForegroundROILabel))
                            error("The forground and backgroudn ROI labelspecified must be of the same class.")
                        end
                        
                        m2xMask = cast(m2bMask, class(xForegroundROILabel));
                        m2xMask(m2bMask) = xForegroundROILabel;
                        m2xMask(~m2bMask) = xBackgroundROILabel;
                        
                    end
                    
                    % Use mask instead of "label"/"labelled" to denote masks
                    % instead of labelmaps
                    chMaskPath = strrep(chLabelmapPath, char(oQuPathUtils.sLabelmapCode), char(TileImagesUtils.sMaskCode));
                    
                    % Write mask
                    imwrite(m2xMask, chMaskPath)
                end
            end
        end
        
        function vsClearSlides = MoveTilesAndLabelmapsOfClearSlide(chTileAndLabelmapDir, chTileAndLabelmapOutputDir, NameValueArgs)
            %vsClearSlides = MoveTilesAndLabelmapsOfClearSlide(chSlideTilesDir, chRemovedSlideTileDir, 'dMaxPercentClearAllowed',0.5);
            
            arguments
                chTileAndLabelmapDir (1,:) char {mustBeText,...
                    MyValidationUtils.MustBeExistingDir,...
                    MyValidationUtils.MustBeDirPath,...
                    MyValidationUtils.MustBeNonEmptyDir}
                chTileAndLabelmapOutputDir(1,:) char {mustBeText,...
                    MyValidationUtils.MustBeExistingDir,...
                    MyValidationUtils.MustBeDirPath}
                NameValueArgs.dMaxPercentClearAllowed (1,1) double {mustBePositive,...
                    mustBeInRange(NameValueArgs.dMaxPercentClearAllowed,0,1,'inclusive')}
            end
            % Get all tile paths
            stTilePaths = dir([chTileAndLabelmapDir, char(QuPathUtils.sImageRegexp)]);
            
            % Make sure there are tiles found
            if isempty(stTilePaths)
                error(['The target directory does not have any images with a names following this expression: ',char(QuPathUtils.sImageRegexp)])
            end
            
            bClearSlideImages = false(1, length(stTilePaths));
            dNumTiles = length(stTilePaths);
            disp("The original number of tiles is " + num2str(dNumTiles));
            dNumberOftilesRemoved = 0;
            
            % Loop through tiles and labelmaps
            for iTileIdx = 1:length(stTilePaths)
                
                % Derive the labelmap path from the tile path
                chTilePath = [chTileAndLabelmapDir, stTilePaths(iTileIdx).name];
                
                m3iImage = imread(chTilePath);
                
                % Blur to reduce noise on blank slide appearing as foreground
                m3iBlurredImage = imgaussfilt(m3iImage,4);
                
                % Binarize, 1 = blank slide, 0 = tissue
                dThresh = 200/255; % determined emperically
                m3bBinaryImage = imbinarize(m3iBlurredImage, dThresh);
                
                % Flatten to allow for viewing
                m2bFlat = sum(m3bBinaryImage,3);
                
                % When a pixel in flat equals three, it means that all RGB layers
                % indicated that the slide is blank there
                m2bFlat = m2bFlat == 3;
                
                % 1 is all clear slide, 0 all non-clear slide
                dPercentClear = sum(m2bFlat,'all')/(length(m2bFlat)*width(m2bFlat));
                
                
                if  dPercentClear > NameValueArgs.dMaxPercentClearAllowed
                    
                    % copy tile and its labelmap
                    copyfile(chTilePath, chTileAndLabelmapOutputDir);                    
                    
                    chLabelmapPath = strrep(chTilePath, '.png',[char(QuPathUtils.sLabelmapCode),'.png']);
                    copyfile(chLabelmapPath, chTileAndLabelmapOutputDir);
                    
                    % delete tile and its labelmap from the original
                    % directory
%                     delete(chTilePath)
%                     delete(chLabelmapPath)
%                                         
                    bClearSlideImages(iTileIdx) = true;
                    dNumberOftilesRemoved = dNumberOftilesRemoved + 1;
                end
                
                
            end
            
            sTileNames = string({stTilePaths.name});
            vsClearSlides = sTileNames(bClearSlideImages);
            
            disp("The number of tiles removed is " + num2str(dNumberOftilesRemoved));
            disp("This is %" + num2str((dNumberOftilesRemoved/dNumTiles)*100)+ " of the original number of tiles.")
        end
        
        function c1chBadTilesAndLabelmaps = ResizeTilesAndLabelmaps(chTileAndLabelmapDir, dSideLength_Pixels, NameValueArgs)
            arguments
                chTileAndLabelmapDir (1,:) char {mustBeText,...
                    MyValidationUtils.MustBeExistingDir,...
                    MyValidationUtils.MustBeDirPath,...
                    MyValidationUtils.MustBeNonEmptyDir}
                dSideLength_Pixels (1,1) {mustBePositive,...
                    mustBeInteger, mustBeNonNan}
                
                NameValueArgs.chOutputDir (1,:) char {mustBeText,...
                    MyValidationUtils.MustBeExistingDir,...
                    MyValidationUtils.MustBeDirPath} = chTileAndLabelmapDir
                NameValueArgs.chImresizeInterpolationMethodForImage...
                    (1,:) char {mustBeText} = 'bilinear' %bilinear is best for upsampling, nearest is best for downsampling
                NameValueArgs.chImresizeInterpolationMethodForLabelmaps...
                    (1,:) char {mustBeText} = 'nearest' %nearest is the only acceptable option for a labelmap
                NameValueArgs.bAllTilesLikeFirstTile (1,1) logical = true
            end
            
            % Get all tile paths
            stTilePaths = dir([chTileAndLabelmapDir, char(QuPathUtils.sImageRegexp)]);
            
            % Make sure there are tiles found
            if isempty(stTilePaths)
                error(['The target directory does not have any images with a names following this expression: ',char(QuPathUtils.sImageRegexp)])
            end
            
            fig = figure('Visible', 'off'); % This supresses the colourmap figure from popping up
            oColormap = colormap(QuPathUtils.m2dNewCancerColourMap);
            
            c1chBadTilesAndLabelmaps = {};
            % Loop through tiles and labelmaps
            for iTileIdx = 1:length(stTilePaths)
                
                % Derive the labelmap path from the tile path
                chCurrentTileName = stTilePaths(iTileIdx).name;
                chExtentsion = MyGeneralUtils.GetFileExtension(chCurrentTileName);
                chLabelmapName = strrep(chCurrentTileName, ['.', chExtentsion],...
                    [char(QuPathUtils.sLabelmapCode),'.', chExtentsion]);
                
                % Read image
                try
                    m3iTile = imread([chTileAndLabelmapDir, chCurrentTileName]);
                catch
                    disp("sth")
                end
                
                m3iLabelmap = imread([chTileAndLabelmapDir, chLabelmapName]);
                
                
                % Get image sizes and make sure they fit constraints
                vdTileSize = size(m3iTile);
                vdLabelmapSize = size(m3iLabelmap);
                
                % Tile and labelmap must have the same height and width as
                % each other
                if any(vdTileSize(1:2) ~= vdLabelmapSize(1:2))
                    warning("This tile and its labelmap have different sizes: " + string(chCurrentTileName));
                    c1chBadTilesAndLabelmaps = [c1chBadTilesAndLabelmaps; chCurrentTileName];
                    continue
                end
                
                % Tiles and labelmaps must be square
                if vdTileSize(1) ~= vdTileSize(2)
                    warning("This tile is not square: " + string(chCurrentTileName));
                    c1chBadTilesAndLabelmaps = [c1chBadTilesAndLabelmaps; chCurrentTileName];
                    continue
                end
                
                if NameValueArgs.bAllTilesLikeFirstTile
                    % Show on first iteration only
                    bRunOnThisIteration = iTileIdx == 1;
                    if bRunOnThisIteration
                        warning("Treating all tiles as having the same dimensions as the first tile.");
                    end
                    
                else
                    bRunOnThisIteration = true;
                end
                
                if bRunOnThisIteration
                    % Display whether sizing up or down
                    sTileSideLength = num2str(vdTileSize(1));
                    sRequestedTileSideLength = num2str(dSideLength_Pixels);
                    if vdTileSize(1) < dSideLength_Pixels
                        disp("Sizing up from " + sTileSideLength + "x" + sTileSideLength +...
                            " pixels to " + sRequestedTileSideLength + "x" + sRequestedTileSideLength + " pixels.")
                        
                    elseif vdTileSize(1) > dSideLength_Pixels
                        disp("Sizing down from " + sTileSideLength + "x" + sTileSideLength +...
                            " pixels to " + sRequestedTileSideLength + "x" + sRequestedTileSideLength + " pixels.")
                        
                    elseif vdTileSize(1) == dSideLength_Pixels
                        disp("The requested side length already equals the requested side length.")
                        
                        if NameValueArgs.bAllTilesLikeFirstTile
                            % Stop looping through tiles if all are the
                            % same size and that is the same size as
                            % requested
                            break
                        else
                            continue
                        end
                    end
                end
                
                % Resize
                m3iResizedTile = imresize(m3iTile, [dSideLength_Pixels, dSideLength_Pixels],...
                    'method', NameValueArgs.chImresizeInterpolationMethodForImage);
                
                m3iResizedLabelmap = imresize(m3iLabelmap, [dSideLength_Pixels, dSideLength_Pixels],...
                    'method', NameValueArgs.chImresizeInterpolationMethodForLabelmaps);
                
                % Change file names to indicate that a resize was done
                chResizeFactor = num2str(vdTileSize(1)/dSideLength_Pixels, '%5f');
                chOutputTileFilename = insertAfter(chCurrentTileName, QuPathUtils.sStartOfTileInfoForStrfind, ['d=',chResizeFactor,',']);
                
                % Change the height & width (ca do it in one go because
                % they're the same)
                c1chOrigWidthInfo = regexp(chCurrentTileName, char(QuPathUtils.sWidthRegexpForToken),'tokens','once');
                chOutputTileFilename = strrep(chOutputTileFilename, c1chOrigWidthInfo{:}, char(sRequestedTileSideLength));
                
                % Save
                chOutputiTilePath = [NameValueArgs.chOutputDir,chOutputTileFilename];
                chOutputLabelmapPath = strrep(chOutputiTilePath, ['.', chExtentsion],...
                    [char(QuPathUtils.sLabelmapCode),'.', chExtentsion]);
                imwrite(m3iResizedTile, chOutputiTilePath)
                delete([chTileAndLabelmapDir, chCurrentTileName])
                imwrite(m3iResizedLabelmap, oColormap, chOutputLabelmapPath)
                delete([chTileAndLabelmapDir, chLabelmapName])
            end
        end
        
        function PrepareTilesAndMasksForColabNotebook(chTileAndMaskInputDir, chTileAndMaskOutputDir)
            %PrepareTilesAndMasksForColabNotebook(chTileAndMaskInputDir, chTileAndMaskOutputDir)
            %
            % DESCRIPTION:
            %   I made this to be able to structure the images and
            %   masks that come out of the QuPath script in a way that
            %   Colab can use in a SEGMENTATION experiment
            %
            %   IMPORTANT: this function
            %   Assumes tiles and masks are in the same folder
            %   and does not account for duplicate masks.
            %
            % INPUT ARGUMENTS:
            %  chTileAndMaskInputDir: directory where the masks and tiles were
            %   dumped by QuPath
            %  chTileAndMaskOutputDir: directory that will be loaded to
            %   Colab.
            %
            % OUTPUTS ARGUMENTS:
            %  none. The output is in a sifferent directory.
            
            % Author: Salma Dammak
            % Last modified: Jul 18, 2022
            arguments
                chTileAndMaskInputDir (1,:) char {mustBeText,...
                    MyValidationUtils.MustBeExistingDir,...
                    MyValidationUtils.MustBeDirPath,...
                    MyValidationUtils.MustBeNonEmptyDir}
                chTileAndMaskOutputDir (1,:) char {mustBeText,...
                    MyValidationUtils.MustBeExistingDir,...
                    MyValidationUtils.MustBeDirPath,...
                    MyValidationUtils.MustBeNonEmptyDir}
            end
            
            % Get all label paths
            stMaskPaths = dir([chTileAndMaskInputDir, TileImagesUtils.chMaskRegexp]);
            
            mkdir(chTileAndMaskOutputDir)
            mkdir([chTileAndMaskOutputDir,'\labels'])
            mkdir([chTileAndMaskOutputDir,'\images'])
            
            vsRealNameToNumberMapping = [];
            
            for i = 1 : length(stMaskPaths)
                
                chMaskSourcePath = [chTileAndMaskInputDir,'\' stMaskPaths(i).name];
                chTileSourcePath = strrep(chMaskSourcePath,['-',TileImagesUtils.chMaskCode],'');
                
                % Rename using sequential numbers
                chMaskDestinationPath = [chTileAndMaskOutputDir,'\labels\',num2str(i),'.png'];
                chTileDestinationPath = [chTileAndMaskOutputDir,'\images\',num2str(i),'.png'];
                
                copyfile(chMaskSourcePath, chMaskDestinationPath)
                copyfile(chTileSourcePath, chTileDestinationPath)
                
                vsRealNameToNumberMapping = [string(vsRealNameToNumberMapping);string([num2str(i),'-',stMaskPaths(i).name])];
            end
            
            save('RealNameToNumberMapping.mat','vsRealNameToNumberMapping')
        end
    end
end

