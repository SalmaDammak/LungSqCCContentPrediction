classdef TCGAUtils
    %TCGAUtilities
    %
    % This is collection of utilities that help with getting information
    % from files named in the TCGA convention, parsing TCGA documents,
    % or selecting subsets of TCGA slides from a pool of slides.
    
    % Primary Author: Salma Dammak
    % Created: Jun 22, 2022
    
    
    % *********************************************************************   ORDERING: 1 Abstract        X.1 Public       X.X.1 Not Constant
    % *                            PROPERTIES                             *             2 Not Abstract -> X.2 Protected -> X.X.2 Constant
    % *********************************************************************                               X.3 Private
    
    properties (Access = public, Constant = true)
        
        % In the SampleName: TCGA-AA-BBBB-CCC-DDD-EEEE-FF
        % TCGA-AA-BBBB is the patient ID, and AA is the tissue sample source ("centre"). The reminaing bit doesn't
        % follow documented convention as informed by CDG help desk. Helpful links:
        % https://docs.gdc.cancer.gov/Encyclopedia/pages/TCGA_Barcode/
        % https://gdc.cancer.gov/resources-tcga-users/tcga-code-tables
        
        chSampleIDExpression = 'TCGA-\w\w-\w\w\w\w-[a-zA-Z0-9.\-]+';
        chPatientIDExpression = 'TCGA-\w\w-\w\w\w\w';
        chTSSExpression = 'TCGA-\w\w'
        
        % Regular expressions for search using "token"
        % e.g., regexp(sFilename, sCentreIDRegexpForToken,'tokens','once')
        sCentreIDRegexpForToken = "TCGA-(\w\w)-.*";
        sPatientIDRegexpForToken = "TCGA-(\w\w-\w\w\w\w).*";
        sSlideIDRegexpForToken = "(TCGA-\w\w-\w\w\w\w-.*)\s*";
        sTileIDRegexpForToken = "TCGA-(\w\w-\w\w\w\w-.*]).*";
    end
    
    
    % *********************************************************************   ORDERING: 1 Abstract     -> X.1 Not Static
    % *                          PUBLIC METHODS                           *             2 Not Abstract    X.2 Static
    % *********************************************************************
    
    methods (Static = true, Access = public)
        function [vsCentreIDs, vsPatientIDs, vsSlideIDs, vsTileIDs, vsFilenames] = GetIDsFromTileFilepaths(vsTileFilepaths, NameValueArgs)
            %[vsCentreIDs, vsPatientIDs, vsSlideIDs, vsTileIDs, vsFilenames] = TCGAUtils.GetIDsFromTileFilepaths(vsTileFilepaths)
            arguments
                vsTileFilepaths
                NameValueArgs.bSlideNamesNotTilesGiven = false
            end
            % Note that filepaths or filenames are both okay here
            
            % Initialize all outputs
            dNumPaths = length(vsTileFilepaths);
            vsCentreIDs = strings(dNumPaths,1);
            vsPatientIDs = strings(dNumPaths,1);
            vsSlideIDs = strings(dNumPaths,1);
            vsTileIDs = strings(dNumPaths,1);
            vsFilenames = strings(dNumPaths,1);
            
            for iTileFilepathIdx = 1:dNumPaths
                sTileFilepath = vsTileFilepaths(iTileFilepathIdx);
                
                % Parse filename for IDs. Break apart the filename from the
                % path first as all regular expressions are based on the
                % filename not the full path
                vsFileparts = split(sTileFilepath, filesep);
                sFilename = vsFileparts(end);
                vsFilenames(iTileFilepathIdx) = sFilename;
                vsCentreIDs(iTileFilepathIdx) = regexp(sFilename, TCGAUtils.sCentreIDRegexpForToken, 'tokens','once');
                vsPatientIDs(iTileFilepathIdx) = regexp(sFilename, TCGAUtils.sPatientIDRegexpForToken, 'tokens','once');                
                vsSlideIDs(iTileFilepathIdx) = regexp(sFilename, TCGAUtils.sSlideIDRegexpForToken, 'tokens','once');    
                if ~NameValueArgs.bSlideNamesNotTilesGiven
                vsTileIDs(iTileFilepathIdx) = regexp(sFilename, TCGAUtils.sTileIDRegexpForToken, 'tokens','once');
                end
            end
            
        end        
        function [msAllInfo, vsFileNames, vsTSS, vsPatientIds] = GetTSSInfoForTCGASlidesInDir(chDatasetDirectory)
            % This function allows me to pull out the information on the TCGA-LUSC slides that I want to
            % diversify whenever I want a subsample from the dataset
            
            stWholeSlidePaths = dir([chDatasetDirectory,'\TCGA-*.svs']);
            
            dNumSlides = length(stWholeSlidePaths);
            
            vsTSS = strings(dNumSlides, 1);
            vsPatientIds = strings(dNumSlides, 1);
            vsFileNames = strings(dNumSlides, 1);
            
            
            for i = 1:dNumSlides
                
                chFileName = stWholeSlidePaths(i).name;
                vsFileNames(i) = string(chFileName);
                
                vsAllElements = split(string(chFileName),'-');
                
                vsTSS(i) = vsAllElements(2);
                vsPatientIds(i) = join([vsAllElements(2),"-",vsAllElements(3)],'');
            end
            
            msAllInfo =  [vsFileNames, vsTSS, vsPatientIds];
            
        end
        function [vsChosenFileNames, vsChosenIDs, vsChosenTSS] = GetSubsetOfTCGASlides(dNumRequiredSlides, chDatasetDirectory, vsBlackListedSlidesSVS)
            % This function obtains a subset slides from the TCGA LUSC data set using the following rules:
            %   1. maximize uniqueness. If dNumSlides < than the number of Tissue Source Sites (TSS),
            %      make sure that there are no duplicated TSSs in the output list. If a patient has more than
            %      one slide, get a slide from another patient instead.
            %   2. in case there are multiple options, choose randomly
            
            % Pre-allocate output containers
            vsChosenFileNames = strings(dNumRequiredSlides, 1);
            vsChosenIDs = strings(dNumRequiredSlides, 1);
            vsChosenTSS = strings(dNumRequiredSlides, 1);
            
            % Get slide info
            if ischar(chDatasetDirectory)
                [~,vsFilenames, vsCentreIDs, vsPatientIDs] = TCGAUtils.GetSampleSourceInfoForATCGADataset(chDatasetDirectory);
            elseif isstring(chDatasetDirectory) % QUICK N DIRTY FIX TO INPUT A VECTOR OF STRINGS OF NAMES INSTEAD OF A DIR
                [~, ~,~, ~,vsPatientIDs, vsCentreIDs] = TCGAUtils.GetSlideInformationFromSlideNames(chDatasetDirectory);
                vsFilenames = chDatasetDirectory;
            end
            
            % Remove any blacklisted slides
            if ~isempty(vsBlackListedSlidesSVS)
                bBlackListedSlideIndicesInFullList = false(length(vsFilenames), 1);
                
                % Go through every blacklisted slide
                for i = 1:length(vsBlackListedSlidesSVS)
                    
                    % Make sure it has the right extension
                    chSlideName = char(vsBlackListedSlidesSVS(i));
                    
                    if ~strcmp('.svs',chSlideName(end-3:end))
                        error("The blacklisted slidenames must end in .svs");
                    end
                    
                    % Find it in the full list
                    dBlackListedSlideIdx = find(strcmp(vsBlackListedSlidesSVS(i), vsFilenames));
                    
                    % Add it to the removal list
                    if ~isempty(dBlackListedSlideIdx)
                        bBlackListedSlideIndicesInFullList(dBlackListedSlideIdx) = true;
                    else
                        warning("Slide " + vsBlackListedSlidesSVS(i) + newline + " was not found. "+...
                            "It was not used to eliminate any slides from the target directory.")
                    end
                end
                
                vsFilenames(bBlackListedSlideIndicesInFullList) = [];
                vsCentreIDs(bBlackListedSlideIndicesInFullList) = [];
                vsPatientIDs(bBlackListedSlideIndicesInFullList) = [];
            end
            
            % Error if the number of requested slides exceeds what's available
            if dNumRequiredSlides > length(vsFilenames)
                error("GetSubsetOfTCGASlides:BadRequest","The number of slides requested "...
                    + "is more than those available. The number of slides requested is " + num2str(dNumRequiredSlides)...
                    + ". The number available is " + num2str(length(vsFilenames)) + ". " ...
                    + "Maybe you blacklisted too many slides.");
            end
            
            % Group slides IDs by TSS ID
            vsUniqueTSS = unique(vsCentreIDs);
            dNumUniqueTSS = length(vsUniqueTSS);
            
            c1vsValidGroupedSlides = cell(dNumUniqueTSS,2);
            for k = 1:dNumUniqueTSS
                sUniqueTSS = vsUniqueTSS(k);
                vbIDIndexToGroup = (vsCentreIDs == sUniqueTSS);
                c1vsValidGroupedSlides{k,1} = vsPatientIDs(vbIDIndexToGroup);
                c1vsValidGroupedSlides{k,2} = vsFilenames(vbIDIndexToGroup);
            end
            
            % Set counters to keep adding until we have the required number
            dNumSlidesLeftToGet = dNumRequiredSlides;
            dNextEmptyIndex = 1;
            
            while dNumSlidesLeftToGet > 0
                
                % Use a vector as a counter for the slide picking loop. This vector looks different based on
                % whether have more TSSs than required slides. Also this vector only applies to non-empty sites
                % so we don't get stuck in a loop forever.
                vdNonEmptyTSS = find(~cellfun(@isempty, c1vsValidGroupedSlides(:,1)));
                dNumUniqueNonEmptyTSS = length(vdNonEmptyTSS);
                
                % If the number of slides left to choose is more than or equal to the number of non-empty source
                % sites, get a slide from every non-empty TSS.
                if dNumSlidesLeftToGet >= dNumUniqueNonEmptyTSS
                    vdTSSsToUse = vdNonEmptyTSS;
                    
                    % If there are less slides left to get than TSSs pick a subset of them at random
                elseif dNumSlidesLeftToGet < dNumUniqueNonEmptyTSS
                    vdRandomCenterPicker = randperm(dNumUniqueNonEmptyTSS, dNumSlidesLeftToGet);
                    vdTSSsToUse = vdNonEmptyTSS(vdRandomCenterPicker);
                end
                
                
                % Pick one from each TSS as specified by our vector, avoiding slides from the same patient if possible
                for i = 1:length(vdTSSsToUse)
                    
                    dUniqueCenterIdx = vdTSSsToUse(i);
                    dNumAvailableAtThisTSS = size(c1vsValidGroupedSlides{dUniqueCenterIdx,1},1);
                    
                    if ~isempty(c1vsValidGroupedSlides{dUniqueCenterIdx,1}) % This allows for skipping sites that have no samples left
                        bSkipThisTSS = false;
                        
                        % Randomly pick a sample within that TSS and get its corresponding ID
                        dIdx = randperm(dNumAvailableAtThisTSS, 1);
                        sChosenID = c1vsValidGroupedSlides{dUniqueCenterIdx,1}(dIdx);
                        
                        % If it's possible to avoid slides from the same patient do so. This is only possible
                        % if the number of required slides is less than the number of unique patients.
                        if dNumRequiredSlides <= length(unique(vsPatientIDs)) %>"num unique patient IDs"
                            
                            % If the site has just one patient and we already have a slide from that patient,
                            % skip this site and empty it to make it invalid
                            % if the loop goes through again. This is okay, because we had already checked that
                            % we're requesting a number of slides that's less than the unique patient, so what this
                            % will do is move the loop to other sites that might have more unique patients.
                            if ( length( unique(c1vsValidGroupedSlides{dUniqueCenterIdx,1}) ) <= 1 )...
                                    && (~isempty(find(vsChosenIDs == sChosenID, 1)))
                                % Empty the site
                                c1vsValidGroupedSlides{dUniqueCenterIdx,1} = strings(0);
                                c1vsValidGroupedSlides{dUniqueCenterIdx,2} = strings(0);
                                bSkipThisTSS = true;
                            end
                            
                            
                            % Now that we know we have more than one patient at this TSS, keep trying to get
                            % a different one if we already have this patient's ID. Delete any discarded IDs to
                            % minimize the pool to look in.
                            while ~isempty(find(vsChosenIDs == sChosenID, 1))...
                                    && (~isempty(c1vsValidGroupedSlides{dUniqueCenterIdx,1}))
                                
                                % Delete "discarded" IDs and filenames
                                c1vsValidGroupedSlides{dUniqueCenterIdx,1}(dIdx) = [];
                                c1vsValidGroupedSlides{dUniqueCenterIdx,2}(dIdx) = [];
                                dNumAvailableAtThisTSS = dNumAvailableAtThisTSS -1;
                                
                                if ~isempty(c1vsValidGroupedSlides{dUniqueCenterIdx,1})
                                    dIdx = randperm(dNumAvailableAtThisTSS, 1);
                                    sChosenID = c1vsValidGroupedSlides{dUniqueCenterIdx,1}(dIdx);
                                else
                                    bSkipThisTSS = true;
                                end
                                
                            end
                        end
                        
                        if ~bSkipThisTSS
                            % Add in the chosen slides
                            vsChosenIDs(dNextEmptyIndex) = sChosenID;
                            vsChosenFileNames(dNextEmptyIndex) = c1vsValidGroupedSlides{dUniqueCenterIdx,2}(dIdx);
                            vsChosenTSS (dNextEmptyIndex) = vsUniqueTSS(dUniqueCenterIdx);
                            
                            % Update the counters
                            dNextEmptyIndex = dNextEmptyIndex + 1;
                            dNumSlidesLeftToGet = dNumSlidesLeftToGet - 1;
                            
                            % Delete these IDs from the valid pool
                            c1vsValidGroupedSlides{dUniqueCenterIdx,1}(dIdx) = []; % Delete ID that was already used
                            c1vsValidGroupedSlides{dUniqueCenterIdx,2}(dIdx) = []; % Delete filename that was already used
                        end
                        
                    end
                    
                end
                
            end
            
        end
        
    end
    
    methods (Static)
        function [vbTrainSlideIndices, vbTestSlideIndices] = PerformRandomTwoWaySplit(vsSlideNames,dFractionGroupsInTraining, NameValueArgs)
            arguments
                vsSlideNames
                dFractionGroupsInTraining
                NameValueArgs.bByCentreID (1,1) logical = false % i.e., TSS ID
                NameValueArgs.bByPatientID (1,1) logical = false
                NameValueArgs.bBySlideID (1,1) logical = false
            end
            %###################### TO DO ##############################
            % - check that there are enough groups for a split (e.g.
            %    more than one center or one patient given)
            %###########################################################
            [vsCentreIDs, vsPatientIDs, vsSlideIDs] = TCGAUtils.GetIDsFromTileFilepaths(vsSlideNames, 'bSlideNamesNotTilesGiven', true);
            
            % Get group IDs based on what is used for splitting
            if NameValueArgs.bByPatientID
                vsGroupIDs = vsPatientIDs;
                chGroupName = 'bByPatientID';
            elseif NameValueArgs.bByCentreID
                vsGroupIDs = vsCentreIDs;
                chGroupName = 'bByCentreID';
            elseif NameValueArgs.bBySlideIDs
                vsGroupIDs = vsSlideIDs;
                chGroupName = 'bBySlideID';
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
            vbTrainSlideIndices = TCGAUtils.FindSlidesWithTheseIDs(vsSlideNames, vsTrainGroups, chGroupName, true);
            vbTestSlideIndices = ~vbTrainSlideIndices;
        end
        
        function vbIndices = FindSlidesWithTheseIDs(vsSlideNames, vsIDs, NameValueArgs)
            arguments
                vsSlideNames
                vsIDs
                NameValueArgs.bByCentreID (1,1) logical = false
                NameValueArgs.bByPatientID (1,1) logical = false
                NameValueArgs.bBySlideID (1,1) logical = false
            end
            
            [vsCentreIDs, vsPatientIDs, vsSlideIDs] = TCGAUtils.GetIDsFromTileFilepaths(vsSlideNames, 'bSlideNamesNotTilesGiven', true);
            
            % Get group IDs based on what is used for splitting
            if NameValueArgs.bByPatientID
                vsGroupIDs = vsPatientIDs;
            elseif NameValueArgs.bByCentreID
                vsGroupIDs = vsCentreIDs;
            elseif NameValueArgs.bBySlideIDs
                vsGroupIDs = vsSlideIDs;
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
    
end