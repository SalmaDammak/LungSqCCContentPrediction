%% Load data
load(Experiment.GetDataPath('Results'),'vdTruth','vdConfidences', 'c1chPaths')

vdDiff = vdTruth - vdConfidences;
[vsIDs, vsPatientIds] = TCGAUtils.GetIDsFromTileFilepaths(c1chPaths);

% get number of patients per center
c1chPatientIds = convertStringsToChars(unique(vsPatientIds));
c1chCenterIdsFromPatientIds = cellfun(@(c) c(6:7), c1chPatientIds, 'UniformOutput',false);

[c1chUniqueCentersFromPatientIds, ~, vdIndices] = unique(c1chCenterIdsFromPatientIds);
vdNumPatientPerCenter = nan(length(c1chUniqueCentersFromPatientIds), 1);
for iCenterIdx = 1:length(c1chUniqueCentersFromPatientIds)
    vdNumPatientPerCenter(iCenterIdx) = sum(vdIndices == iCenterIdx);
end

tPatientPerCenter = table(c1chUniqueCentersFromPatientIds, vdNumPatientPerCenter);
% % 
%% Make plots
[vsUniqueIds, ~, vdIdIndex] = unique(vsIDs);
chIdName = 'Center';

% Get Medians to sort boxes by them
vdMedians = nan(length(vsUniqueIds),1);
for iUniqueIdIndex = 1:length(vsUniqueIds)
    vdMedians(iUniqueIdIndex) = median(vdDiff(vdIdIndex == iUniqueIdIndex));
end
[vdSortedMedians, vdMedianSortingIdx] = sort(vdMedians,'ascend');

figure
boxplot(vdDiff, string(vdIdIndex),...
    'GroupOrder',string(vdMedianSortingIdx),...
    'BoxStyle','filled',...
    'MedianStyle', 'line',...
    'Colors', [130,130,130]/255,...
    'Jitter', 0,...
    'Symbol', '.k',...
    'OutlierSize',3)

% Get the number of patient per center and tack them onto the center name
tPatientPerCenter = tPatientPerCenter(vdMedianSortingIdx, :);
vsxLabels = vsUniqueIds(vdMedianSortingIdx);
vsxLabels = arrayfun(@(a,b) "" + a + " (" + num2str(b) + ")", vsxLabels, tPatientPerCenter.vdNumPatientPerCenter);
xticklabels(vsxLabels)
xtickangle(90)
ylim([-1.5, 1.5])

% Set up the font
fontsize(11,'points')
fontname('calibri')

% Label the axes
vsYTickLabels = arrayfun(@(a) num2str(a*100, '%2.f') + "%", yticks);
yticklabels(vsYTickLabels)

ylabel(['Difference between actual ', newline, 'and predicted cancer content (%)'])
xlabel([chIdName, ' ID in the TCGA' , newline ,'(number of slides from center)'])

% Set up the grid and ticks
grid on
set(gca,'TickDir','out')


% Save the figure
savefig([Experiment.GetResultsDirectory(), '\Error.fig'])
saveas(gcf, [Experiment.GetResultsDirectory(), '\Error.svg']);
print([Experiment.GetResultsDirectory(), '\Error.tiff'], '-dtiffn')
close(gcf)

% Save the caluclated results
vsOrderedIds = vsUniqueIds(vdMedianSortingIdx);
save([Experiment.GetResultsDirectory(), '\', chIdName,'Order.mat'], 'vsOrderedIds','vdSortedMedians');
save([Experiment.GetResultsDirectory(), '\', chIdName,'DifferenceAndGroup.mat'], 'vdDiff','vdIdIndex','vsUniqueIds');
