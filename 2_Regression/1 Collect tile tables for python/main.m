% load lists of names in each set
load([Experiment.GetDataPath('DatasetSplit'),'\Results\01 Experiment Section\SlideNameBySet.mat'],'stSlideNamesBySet')
c1chSetNames = fields(stSlideNamesBySet);

for iSetNameIdx = 1:length(c1chSetNames)
    
    % Display progress info
    chSetName = c1chSetNames{iSetNameIdx};
    Experiment.StartNewSection(chSetName)
    
    vsSlidesForThisSet = stSlideNamesBySet.(chSetName);
    
    % Set up summary info table
    c1chSetSummaryHeader = {'sSlideIDRequested', 'sROIType', 'sSlideIDs', 'sPatientIDs', 'sCentreIDs', 'dNumTiles', 'dNumPositiveTiles'};
    c2xSetSummary = {};    
    
    % load and concatenate the table for each patient in set
    for iSlideIdx = 1:length(vsSlidesForThisSet)
        
        % Display progress info
        chSlideName = char(vsSlidesForThisSet(iSlideIdx));
        disp(['(', num2str(iSlideIdx), '/', num2str(length(vsSlidesForThisSet)),') ', chSlideName]);
        
        % Load the data corresponding to the right slide
        chTileObjRootDir = fullfile(Experiment.GetDataPath('RootTileObjDir'), 'Results', '01 Foci');
        chSlideFolder = GetSlideFolderBasedOnName(chSlideName, chTileObjRootDir);        
        chPathForTable = fullfile(chTileObjRootDir, chSlideFolder, 'TilesWithScalarTargets.mat');
        load(chPathForTable, 'voTilesWithScalarTargets')
        
        % Make into table
        tData = TileWithTarget.ConvertToTableForPython(voTilesWithScalarTargets);
            
        % Add to the set table
        if iSlideIdx == 1
            tFullSetTable = tData;
        else
            tFullSetTable = [tFullSetTable; tData];
        end
        
        % Load tile information for this slide
        chPathForSummaryInfo = fullfile(chTileObjRootDir, chSlideFolder, 'Summary.mat');
        c2xSetSummary = [c2xSetSummary; CreateSummaryRow(chPathForSummaryInfo, chSlideName, 'Foci', c1chSetSummaryHeader)];        
        
        % If this is the training set, include the NCNT tiles to augment
        % the dataset        
        if strcmp(chSetName, 'Train')        
            
            % Add non-cancer non-tumour tiles
            chPathForTable = strrep(chPathForTable, '01 Foci', '02 NCNT');
            chPathForSummaryInfo = strrep(chPathForSummaryInfo, '01 Foci', '02 NCNT');
            try
            load(chPathForTable, 'voTilesWithScalarTargets')
            tData = TileWithTarget.ConvertToTableForPython(voTilesWithScalarTargets);
            
            tFullSetTable = [tFullSetTable; tData];
            
            % Add info            
            c2xSetSummary = [c2xSetSummary; CreateSummaryRow(chPathForSummaryInfo, chSlideName, 'NCNT', c1chSetSummaryHeader)];    
            catch oMe
                % If a slide doesn't have NCNT contoured, just skip adding
                % it.
                if ~strcmp('MATLAB:load:couldNotReadFile', oMe.identifier)                    
                retrhow(oMe)
                end
            end
                
        end        
    end    
    
    tData = tFullSetTable;
    
    % Save set
    save(fullfile(Experiment.GetResultsDirectory(), 'TilesWithScalarTargetsTable.mat'), 'tData')
    
    % Make into csv file for python use later
    writetable(tData,...
        fullfile(Experiment.GetResultsDirectory, 'TilesWithScalarTargets.csv'), 'FileType', 'text', 'delimiter',',');
    
    % Save summary
    tSummary = cell2table(c2xSetSummary, 'VariableNames', c1chSetSummaryHeader);
    dNumTotalTiles = sum(tSummary.dNumTiles);
    dNumTotalPositiveTiles = sum(tSummary.dNumPositiveTiles);
    save(fullfile(Experiment.GetResultsDirectory(), 'SetSummary.mat'), 'tSummary', 'dNumTotalTiles', 'dNumTotalPositiveTiles')
    
    Experiment.EndCurrentSection()
end

function chSlideFolder = GetSlideFolderBasedOnName(chSlideName, chParentDir)
% The experiment class puts numbers at the start of folder names to order
% them in the order they were created. this followss the format :
% "d/d/d/d/ TCGA-...". I need to isolate the slide name portion of the 
% folder name to open the right folder for each set's slides. I decided to
% put this in a separate funciton so the main code is a bit cleaner.

% Get list of subfolder names
stFolders = dir([chParentDir,'\*TCGA*']);
c1chSubfolderNames = {stFolders.name};

% Remove the first numerical bit
for iFolderIdx = 1:length(c1chSubfolderNames)
    c1chSubfolderNamesClean{iFolderIdx} =  c1chSubfolderNames{iFolderIdx}(6:end);    
end

% Find the location
vsCleanFolderNames = string(c1chSubfolderNamesClean);
vbLocation = vsCleanFolderNames == string(chSlideName);

% Get the full folder name corresponding to the slide name
c1chSlideFolder = c1chSubfolderNames(vbLocation);
chSlideFolder = c1chSlideFolder{:};
end

function c1xSummaryRow = CreateSummaryRow(chSummaryInfoFilepath, chSlideName, chROIType, c1chSetSummaryHeader)
% I made this a fucntion to avoid repeated (cluttery) code when getting
% info for Foci then NCNT, since I need to do this for both with the small
% change of the ROI type name.

load(chSummaryInfoFilepath, c1chSetSummaryHeader{3:end});
c1xSummaryRow{1} = string(chSlideName);
c1xSummaryRow{2} = string(chROIType);
c1xSummaryRow{3} = sSlideIDs;
c1xSummaryRow{4} = sPatientIDs;
c1xSummaryRow{5} = sCentreIDs;
c1xSummaryRow{6} = dNumTiles;
c1xSummaryRow{7} = dNumPositiveTiles;
end