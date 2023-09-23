chSlideTilesDir = Experiment.GetDataPath('SlideDir');
c1chPathParts = strsplit(chSlideTilesDir,'\');
chSlideName = c1chPathParts{end-1};

% Create mask targets
voTilesWithMaskTargets = BinaryMaskTarget.MakeTilesWithMaskTargetsFromDir...
    (string(chSlideTilesDir), "CancerNoCancerMasks", 'sPartialFileDirectory',string(Experiment.GetResultsDirectory()),'bFromTCGA', true);
save(fullfile(Experiment.GetResultsDirectory(), 'TilesWithMaskTargets.mat'), 'voTilesWithMaskTargets','-v7.3')

% Create scalar targets
voTilesWithScalarTargets = BinaryMaskTarget.ConvertTilesBinaryMaskTargetsToPercentCoverageTargets(voTilesWithMaskTargets);
save(fullfile(Experiment.GetResultsDirectory(), 'TilesWithScalarTargets.mat'), 'voTilesWithScalarTargets','-v7.3')

% Make into table
tData = TileWithTarget.ConvertToTableForPython(voTilesWithScalarTargets);
save(fullfile(Experiment.GetResultsDirectory,'TilesWithScalarTargetsTable.mat'),'tData','-v7.3');

% Make into csv file for python use later
writetable(tData,...
    fullfile(Experiment.GetResultsDirectory, 'TilesWithScalarTargetsTable.csv'), 'FileType', 'text', 'delimiter',',');

% Create summary stats
dNumTiles = length(voTilesWithScalarTargets);
[sCentreIDs, sPatientIDs, sSlideIDs] = TCGAUtils.GetIDsFromTileFilepaths(string(chSlideName), 'bSlideNamesNotTilesGiven', true);

save(fullfile(Experiment.GetResultsDirectory,'Summary.mat'),'dNumTiles', 'sCentreIDs', 'sPatientIDs', 'sSlideIDs','-v7.3');
disp("Num tiles: " + num2str(dNumTiles))
