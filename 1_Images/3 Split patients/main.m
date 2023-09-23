% Get slide names
sRootDir = string(Experiment.GetDataPath('RootTileDir'));
stRootTileSubDirs = dir(sRootDir + "\TCGA*");
vsSlideNames = string({stRootTileSubDirs.name});

% Prepare struct to hold slide names
vsSetNames = ["Train", "Val", "Test"];
stSlideNamesBySet = struct("Train", strings(0), "Val", strings(0), "Test", strings(0));

% Split into trainVal and test
dFractionGroupsInTrainVal = 1/2;
[vbTrainValSlideIndices, vbTestSlideIndices] = TCGAUtils.PerformRandomTwoWaySplit(vsSlideNames,dFractionGroupsInTrainVal, 'bByCentreID', true);
vsTrainValSlides = vsSlideNames(vbTrainValSlideIndices);
stSlideNamesBySet.Test = vsSlideNames(vbTestSlideIndices)';

% Split into train and val
dFractionGroupsInTrain = 1/2;
[vbTrainSlideIndices, vbValSlideIndices] = TCGAUtils.PerformRandomTwoWaySplit(vsTrainValSlides,dFractionGroupsInTrain, 'bByCentreID', true);
stSlideNamesBySet.Train = vsTrainValSlides(vbTrainSlideIndices)';
stSlideNamesBySet.Val = vsTrainValSlides(vbValSlideIndices)';

save([Experiment.GetResultsDirectory(), '\SlideNameBySet.mat'], 'stSlideNamesBySet')
