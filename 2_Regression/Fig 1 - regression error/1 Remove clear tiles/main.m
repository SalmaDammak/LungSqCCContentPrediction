% Load data
load(Experiment.GetDataPath('Results'),'vsiConfidences','c1xData','vsFilenamesFromMATLAB')
c1chPaths = c1xData(2:end,1);
c1dTruth = c1xData(2:end,2);
vdTruth = double(vertcat(c1dTruth{:}));
vdConfidences = double(vsiConfidences);

% Keep only tissue tiles
load(Experiment.GetDataPath('TestClearAndTissueTiles'), 'tTissueTiles')
vbKeepTiles = false(length(c1chPaths), 1);
for iTileIdx = 1:length(c1chPaths)
    chTile = c1chPaths{iTileIdx};

    if sum(contains(tTissueTiles.c1sPaths, chTile)) == 1
        vbKeepTiles(iTileIdx) = true;
    end
end

c1chPaths(~vbKeepTiles) = [];
vdTruth(~vbKeepTiles) = [];
vdConfidences(~vbKeepTiles) = [];

save([Experiment.GetResultsDirectory(),'\TissueTiles.mat'], 'c1chPaths', 'vdTruth', 'vdConfidences')
