classdef QuPathUtils
    
    properties (Constant = true)
        sCurrentQuPathVersion = "0.3.2";
        
        % Regular expressions for search using "token"
        % % e.g., regexp(sFilename, QuPathUtils.sResizeRegexpForToken,'tokens','once')
        sResizeRegexpForToken = ".*d=(.*),x=.*";
        sXLocationRegexpForToken = ".*x=(\d*),.*";
        sYLocationRegexpForToken = ".*y=(\d*),.*";
        sWidthRegexpForToken = ".*w=(\d*),.*";
        sHeightRegexpForToken = ".*h=(\d*).*";
        
        % Regular expressions for file search in directory
        sImageRegexp = "*].*";
        sLabelmapCode = "-labelled";
        sLabelmapRegexp = "*]-labelled.*";
        
        sStartOfTileInfoForStrfind = "[";
        
        % Colourmap
        m2dCancerContourMap = ...
            [255 ,255 , 255;...% 0 - white > "background"
            23   ,137 ,187;... % 1 - teal > "central"
            200  ,255 ,200;... % 2 - pale green > "peripheral"
            90   ,69  ,40; ... % 3 - brown > "central,  non-viable"
            25   ,94  ,131;... % 4 - dark blue > "central, viable"
            153  ,51  ,255; ... % 5 - medium purple > "peripheral, non-viable"
            204  ,204 ,255;  ... % 6 - light purple  > "peripheral,  viable"
            75   ,0   ,205]/255;% 7 - dark and blueish purple> "non-tumour non-cancer"
        m2dNewCancerColourMap =...
            [0  ,0   ,0;...% 0 - black > "background"
            131 ,223 ,255;... % 1 - light blue > "central"
            200 ,255 ,200;...  % 2 - pale green > "peripheral"
            0   ,111 ,255; ... % 3 - medium blue > "central,  non-viable"
            25  ,94  ,131;... % 4 - dark blue > "central, viable"
            61  ,202 ,0; ... % 5 - medium green > "peripheral, non-viable"
            0   ,91  ,51;  ... % 6 - dark green > "peripheral,  viable"
            255 ,139 ,244]/255;% 7 - pink > "non-tumour non-cancer"
        
    end
    
    methods (Static = true, Access = public)
        function [dXOrigin, dYOrigin, dWidth, dHeight, dResizeFactor] =...
                GetTileCoordinatesFromName(sTileFilepath)
            % Note that filepath or filename are both okay here
            
            % Get filename
            vsFileparts = split(sTileFilepath, filesep);
            sFilename = vsFileparts(end);
            
            % Get location and size information
            dXOrigin = double(regexp(sFilename, QuPathUtils.sXLocationRegexpForToken, 'tokens','once'));
            dYOrigin = double(regexp(sFilename, QuPathUtils.sYLocationRegexpForToken, 'tokens','once'));
            dWidth = double(regexp(sFilename, QuPathUtils.sWidthRegexpForToken, 'tokens','once'));
            dHeight = double(regexp(sFilename, QuPathUtils.sHeightRegexpForToken, 'tokens','once'));
            
            % If there is a downsample factor, get it
            dResizeFactor = double(regexp(sFilename, QuPathUtils.sResizeRegexpForToken, 'tokens','once'));
            if isempty(dResizeFactor)
                dResizeFactor = 1;
                % warning("No resize factor was found so a factor of 1 was assumed.")
            end
        end
        
        function [vdXOrigin, vdYOrigin, vdWidth, vdHeight] = ...
                GetTileCoordinatesFromNames(vsTileFilepaths)
            
            vdXOrigin = nan(length(vsTileFilepaths),1);
            vdYOrigin = nan(length(vsTileFilepaths),1);
            vdWidth = nan(length(vsTileFilepaths),1);
            vdHeight = nan(length(vsTileFilepaths),1);
            
            for iTile = 1:length(vsTileFilepaths)
                sTilePath = vsTileFilepaths(iTile);
                [vdXOrigin(iTile), vdYOrigin(iTile), vdWidth(iTile), vdHeight(iTile)] =...
                    GetTileCoordinatesFromName(sTilePath);
            end
            
            if (any(isnan(vdXOrigin)) || any(isnan(vdYOrigin)))...
                    || (any(isnan(vdWidth)) || any(isnan(vdHeight)))
                error("There are nans in the list.")
            end
            
        end
        
        function sSlideName = GetSlideNameFromTileFilepath(sTileFilePath)
            % Get filename
            vsFileparts = split(sTileFilePath, filesep);
            sFilename = vsFileparts(end);
            
            dEndIdx = strfind(sFilename, QuPathUtils.sStartOfTileInfoForStrfind);
            dEndIdx = dEndIdx - 2; % to adjust to an added space
            
            % Can't index elements in a string (it's 1x1) so I need to make
            % it a char
            chFileName = char(sFilename);
            sSlideName = string(chFileName(1:dEndIdx));
        end
        
        function c1tPredictiontables = PreparePredictionTablesForPlotting(...
                vsTileFilenames, vdPredictions, sCSVOutputDir, NameValueArgs)
            % vsSlideNames | x_location | y_location | width | height |
            % vdConfidences| prediction | vbTruth | TP | FP | TN | FN
            %
            % Makes one CSV per slide and can be given tiles from multiple
            % slides
            %
            %QuPathUtils.PreparePredictionTablesForPlotting(...
            %   vsFilenamesFromMATLAB,  double(vsiConfidences)>0.5, Experiment.GetResultsDirectory(),...
            %   'vdConfidences', double(vsiConfidences),...
            %   'vbTruth', viTruth', 'bAddFalseAndTrueNegativeAndPositiveColumns', true);
            
            arguments
                vsTileFilenames
                vdPredictions
                sCSVOutputDir
                NameValueArgs.vdConfidences
                NameValueArgs.vbTruth
                NameValueArgs.bAddFalseAndTrueNegativeAndPositiveColumns
            end
            
            dNumTiles = length(vsTileFilenames);
            
            % Intialize each column
            vsSlideNames = strings(dNumTiles,1);
            vdXLocations = nan(dNumTiles,1);
            vdYLocations = nan(dNumTiles,1);
            vdHeight = nan(dNumTiles,1);
            vdWidth = nan(dNumTiles,1);
            
            % Collect information
            for iTileIdx = 1:dNumTiles
                
                % Get slide name
                vsSlideNames(iTileIdx) = QuPathUtils.GetSlideNameFromTileFilepath(vsTileFilenames(iTileIdx));
                
                % Get location and size information
                [vdXLocations(iTileIdx), vdYLocations(iTileIdx), dWidth, dHeight] = ...
                    QuPathUtils.GetTileCoordinatesFromName(vsTileFilenames(iTileIdx));
                
                vdHeight(iTileIdx) = dWidth;
                vdWidth(iTileIdx) = dHeight;
            end
            
            
            tPredictionTable = table(vsSlideNames, vdXLocations, vdYLocations, vdHeight, vdWidth, vdPredictions);
            
            if  isfield(NameValueArgs, 'vdConfidences')
                vdConfidenceOfPositive_Percent = NameValueArgs.vdConfidences * 100;
                tPredictionTable = addvars(tPredictionTable, vdConfidenceOfPositive_Percent,...
                    'NewVariableNames','vdConfidences');
            end
            
            if  isfield(NameValueArgs, 'vbTruth')
                tPredictionTable = addvars(tPredictionTable, NameValueArgs.vbTruth,...
                    'NewVariableNames','vbTruth');
            end
            
            if isfield(NameValueArgs, 'bAddFalseAndTrueNegativeAndPositiveColumns') && NameValueArgs.bAddFalseAndTrueNegativeAndPositiveColumns
                
                if ~isfield(NameValueArgs, 'vbTruth')
                    error(" You must give the groundtruth as a NameValueArg to caluclate the false and true positive and negative columns.")
                end
                
                % Add true positive, false positive, true negative, and false
                % negative columns
                vdTP = false(dNumTiles, 1);
                vdFP = false(dNumTiles, 1);
                vdTN = false(dNumTiles, 1);
                vdFN = false(dNumTiles, 1);
                
                for iTile = 1:dNumTiles
                    % Predicted positive and is actually positive, i.e. TP
                    if vdPredictions(iTile) == true && NameValueArgs.vbTruth(iTile) == true
                        vdTP(iTile) = true;
                        
                        % Predicted positive and is actually negative, i.e. FP
                    elseif vdPredictions(iTile) == true && NameValueArgs.vbTruth(iTile) == false
                        vdFP(iTile) = true;
                        
                        % Predicted negative and is actually negative, i.e. TN
                    elseif vdPredictions(iTile) == false && NameValueArgs.vbTruth(iTile) == false
                        vdTN(iTile) = true;
                        
                        % Predicted negative and is actually positive, i.e. FN
                    elseif vdPredictions(iTile) == false && NameValueArgs.vbTruth(iTile) == true
                        vdFN(iTile) = true;
                    end
                end
                
                tFalseAndTrueNegativeAndPositiveColumns = table(vdTP, vdFP, vdTN, vdFN);
                tPredictionTable = [tPredictionTable, tFalseAndTrueNegativeAndPositiveColumns];
            end
            
            % Now create and write a csv for each slide
            vsUniqueSlides = unique(tPredictionTable.vsSlideNames);
            c1tPredictiontables = cell(length(vsUniqueSlides), 1);
            
            for iSlideIdx = 1:length(vsUniqueSlides)
                sUnqiueSlideName = vsUniqueSlides(iSlideIdx);
                vbRowsOfSlide = tPredictionTable.vsSlideNames == sUnqiueSlideName;
                
                % Create table and rename columns used by QuPath to match
                % the Groovy script.
                tPredictionTableForSlide = tPredictionTable(vbRowsOfSlide, :);
                tPredictionTableForSlide = renamevars(tPredictionTableForSlide,...
                    ["vdXLocations", "vdYLocations", "vdHeight", "vdWidth", "vdPredictions"],...
                    ["x_location", "y_location", "height", "width", "prediction"]);
                writetable(tPredictionTableForSlide,...
                    fullfile(sCSVOutputDir, sUnqiueSlideName + ".csv"), 'FileType', 'text', 'delimiter',',');
                c1tPredictiontables{iSlideIdx} = tPredictionTableForSlide;
            end
        end
                
        function VerifyThatWSIsHaveContours(c1chRequestedWSIs, chContourDir)
            % e.g., paths
            % c1chRequestedWSIs = 'D:\Users\sdammak\Experiments\LUSCCancerCells\SlidesToContour\All The Slides That Should have Contours.mat';
            % chContourDir = 'D:\Users\sdammak\Data\LUSC\Original\Segmentations\CancerMC\Curated';
            
            stContourPaths = dir([chContourDir,'\*.qpdata']);
            c1chContoured = {stContourPaths.name}';
            
            % Make vector finding the position of the contoured samples in the requested list
            dFoundIndices = nan(length(c1chContoured),1);
            
            for iContouredSample = 1:length(c1chContoured)
                
                c1chIndexInRequested = strfind(c1chRequestedWSIs, c1chContoured{iContouredSample});
                dIndexInRequested = find(not(cellfun('isempty',c1chIndexInRequested)));
                if isempty(dIndexInRequested)
                    error('A slide that was not requested was contoured!')
                end
                
                dFoundIndices(iContouredSample) = dIndexInRequested;
            end
            dCleanIndices = dFoundIndices(~isnan(dFoundIndices));
            c1chRequestedAndCompleted = c1chRequestedWSIs(dCleanIndices);
            c1chRequestedWSIs(dCleanIndices) = [];
            
            disp(['These slides were not in the Contoured folder:', newline, c1chRequestedWSIs{:}])
        end
        
        function vsEquivalentDeconvolvedTilePaths = GetDeconvolvedTileEquivalentPathForSamePatient(...
                vsOriginalSourceTilePaths, vsDeconvolvedTilePaths)
            
            % TO DO: CHECK THAT THE PATIENT IS THE SAME
            
            % Get all original tile locations
            [vdXOrigin, vdYOrigin, vdWidth, vdHeight] = QuPathUtils.GetTileCoordinatesFromNames(vsOriginalSourceTilePaths);
            
            % Get provided deconvolved tile locations
            [vdDecXOrigin, vdDecYOrigin, vdDecWidth, vdDecHeight] = QuPathUtils.GetTileCoordinatesFromNames(vsDeconvolvedTilePaths);
            
            vsEquivalentDeconvolvedTilePaths = strings(length(vsOriginalSourceTilePaths), 1);
            for iOrigTile = 1:length(vsOriginalSourceTilePaths)
                
                vbMatchingX = vdXOrigin(iOrigTile) == vdDecXOrigin;
                vbMatchingY = vdYOrigin(iOrigTile) == vdDecYOrigin;
                vbMatchingBoth = and(vbMatchingX, vbMatchingY);
                
                % error if not found
                if ~any(vbMatchingBoth)
                    error('No match found')
                end
                
                sMatchingTile = vsOriginalSourceTilePaths(vbMatchingBoth);
                vsEquivalentDeconvolvedTilePaths(iOrigTile) = sMatchingTile;                
                
                % Make sure height and width are also the same
                if vdWidth(iOrigTile) ~= vdDecWidth(vbMatchingBoth)
                    error('Width does not match')
                end
                
                if vdHeight(iOrigTile) ~= vdDecHeight(vbMatchingBoth)
                    error('Height does not match')
                end
                
            end
            
            
%             % Get list of images
%             stDeconvolvedTiles = dir(sDeconvolvedTileBaseDir + "\" + QuPathUtils.sImageRegexp);
%             vsDeconvolvedTilePaths = string({stDeconvolvedTiles.name}');
%                                    
            % Get all deconvolved tile locations
            
%             % Get tile location on slide
%             [dXOrigin, dYOrigin, dWidth, dHeight, dResizeFactor] =...
%                 GetTileCoordinatesFromName(sOriginalSourceTilePath);
            
           
            
        end
    end
end

