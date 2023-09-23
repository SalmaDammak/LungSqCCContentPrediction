classdef QuPathUtils
    
    properties (Constant = true)
        sCurrentQuPathVersion = "0.3.2";
        
        % Regular expressions for search using "token"
        % % e.g., regexp(sFilename, QuPathUtils.sResizeRegexpForToken,'tokens','once')
        sResizeRegexpForToken = ".*d=(\d*),.*";
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
            dXOrigin = regexp(sFilename, QuPathUtils.sXLocationRegexpForToken, 'tokens','once');
            dYOrigin = regexp(sFilename, QuPathUtils.sYLocationRegexpForToken, 'tokens','once');
            dWidth = regexp(sFilename, QuPathUtils.sWidthRegexpForToken, 'tokens','once');
            dHeight = regexp(sFilename, QuPathUtils.sHeightRegexpForToken, 'tokens','once');
            
            % If there is a downsample factor, get it
            dResizeFactor = regexp(sFilename, QuPathUtils.sResizeRegexpForToken, 'tokens','once');
            if isempty(dResizeFactor)
                dResizeFactor = 1;
                % warning("No resize factor was found so a factor of 1 was assumed.")
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
        
        function vsSkippedNonSquareTiles = PreparePredictionTablesForPlotting(vsTileFilenames, vdConfidences, vdPredictions, vbTruth, sCSVOutputDir)
            % vsSlideNames | x_location | y_location | width | height | vdConfidences| prediction | vbTruth
            
            dNumTiles = length(vsTileFilenames);
            
            % Intialize each column
            vsSlideNames = strings(dNumTiles,1);
            vdXLocations = nan(dNumTiles,1);
            vdYLocations = nan(dNumTiles,1);
            vdSideLengths = nan(dNumTiles,1);
            vbNonSquareTiles = false(dNumTiles,1);
            
            % Collect information
            for iTileIdx = 1:dNumTiles
                
                % Get slide name
                vsSlideNames(iTileIdx) = QuPathUtils.GetSlideNameFromTileFilepath(vsTileFilenames(iTileIdx));
                
                % Get location and size information
                [vdXLocations(iTileIdx), vdYLocations(iTileIdx), dWidth, dHeight] = ...
                    QuPathUtils.GetTileCoordinatesFromName(vsTileFilenames(iTileIdx));
                
                % Make sure height and width (i.e."sideLength") are equal
                if dWidth ~= dHeight
                    warning("This is not a square tile.")
                    vbNonSquareTiles(iTileIdx) = true;
                end
                vdSideLengths(iTileIdx) = dWidth;
            end
            
            vdConfidenceOfPositive_Percent = vdConfidences*100;
            
            tPredictionTable = table(vsSlideNames, vdXLocations, vdYLocations,...
                vdSideLengths, vdConfidenceOfPositive_Percent, vdPredictions, vbTruth);
            
            % Remove non-square tiles
            vsSkippedNonSquareTiles = tPredictionTable.vsSlideNames(vbNonSquareTiles);
            tPredictionTable = tPredictionTable(~vbNonSquareTiles, :);
            
            % Now create and write a csv for each slide
            vsUniqueSlides = unique(tPredictionTable.vsSlideNames);
            
            for iSlideIdx = 1:length(vsUniqueSlides)
                sUnqiueSlideName = vsUniqueSlides(iSlideIdx);
                vbRowsOfSlide = tPredictionTable.vsSlideNames == sUnqiueSlideName;
                
                % Create table and rename columns used by QuPath to match 
                % the Groovy script.
                tPredictionTableForSlide = tPredictionTable(vbRowsOfSlide, :);
                tPredictionTableForSlide = renamevars(tPredictionTableForSlide,...
                ["vdXLocations", "vdYLocations", "vdSideLengths", "vdPredictions"],...
                ["x_location", "y_location", "sideLength", "prediction"]);
                writetable(tPredictionTableForSlide,...
                    fullfile(sCSVOutputDir, sUnqiueSlideName + ".csv"), 'FileType', 'text', 'delimiter',',');                
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
        
        
    end
end

