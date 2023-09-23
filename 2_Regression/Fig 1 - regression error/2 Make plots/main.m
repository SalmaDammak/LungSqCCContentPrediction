%% Load data
load(Experiment.GetDataPath('Results'),'vdTruth','vdConfidences')

%% Get metrics
chTitle = 'TissueTiles';

% Regression metric
dMAE = mae(vdTruth, vdConfidences);
vdDiff = vdTruth - vdConfidences;
disp("Mean ABSOLUTE error is " + num2str(dMAE*100, '%2.f') + "%, with standard deviation of "...
    + num2str(std(vdDiff)*100, '%2.f') + "%")

% Do normality test and report appropriate metric
[bIsNormal, dPValue] = kstest(vdDiff);
if bIsNormal
    disp("ks normality p: "+ num2str(dPValue, '%2.5f') +". Mean error: " + num2str(100*mean(vdDiff),'%2.f') + "%, std dev: " + num2str(100*std(vdDiff),'%2.f')+ "%")
else
    disp("Median error: " + num2str(100*median(vdDiff),'%2.f') + "%, iqr: " + num2str(100*iqr(vdDiff),'%2.f')+ "%")
end

% Error plot
vdDifference = 100*(vdTruth - vdConfidences);
histogram(vdDifference, 'FaceColor',[192, 192, 192]/255)
fontsize(11,'points')
fontname('calibri')

grid on

xlabel(['Difference between actual ', newline, 'and predicted cancer content (%)'])
ylabel('Number of tiles')
set(gca,'TickDir','out')

savefig([Experiment.GetResultsDirectory(), '\ErrorHistogram_', chTitle,'.fig'])
saveas(gcf, [Experiment.GetResultsDirectory(), '\ErrorHistogram_', chTitle,'.svg']);
print([Experiment.GetResultsDirectory(), '\ErrorHistogram_', chTitle,'.tiff'], '-dtiffn')
close(gcf)
