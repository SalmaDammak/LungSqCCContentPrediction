load(Experiment.GetDataPath('Results'),'vdTruth','vdConfidences', 'c1chPaths')

vdThresholds = 0.25:0.25:1;
c1chLegend = {};
vdAUC = nan(length(vdThresholds),1);
vdROCThreshold = nan(length(vdThresholds),1);
vdSensitivity = nan(length(vdThresholds),1);
vdSpecificity = nan(length(vdThresholds),1);
c1chLineStyles = {'-',':','--','-.'};

for iCancerThresholdIx = 1:length(vdThresholds)    
    dCancerThreshold = vdThresholds(iCancerThresholdIx);
    
    % Get truth
    viTruth = int32(vdTruth >= dCancerThreshold);
    
    % Get curve points
    [vdX,vdY,vdROCThresholdsForPlotting,dAUC] = perfcurve(viTruth,vdConfidences,1);        
    
    % Plot
    plot(vdX, vdY, 'LineWidth', 1, 'Color', 'k', 'LineStyle', c1chLineStyles{iCancerThresholdIx});
    
    % Create legend entry.
    % Add space so AUCs is aligned, since 100% has one more digit than
    % the rest
    chLegeneEntry = ['Threshold: ', num2str(100*dCancerThreshold, '%2.f'),...
        '%, AUC: ', num2str(dAUC, '%1.2f')];
    if dCancerThreshold ~= 1
        chLegeneEntry = insertAfter(chLegeneEntry, 'Threshold: ','  ');
    end
    c1chLegend = [c1chLegend, {chLegeneEntry}];
    hold on
    
    % Calculate metrics
    iPositiveLabel = int32(1);    
    dROCThreshold = ErrorMetricsCalculator.CalculateOptimalThreshold({"upperleft","MCR","matlab"}, viTruth, vdConfidences, iPositiveLabel);
    dTruePositiveRate = ErrorMetricsCalculator.CalculateTruePositiveRate(viTruth, vdConfidences, iPositiveLabel,dROCThreshold);
    dTrueNegativeRate = ErrorMetricsCalculator.CalculateTrueNegativeRate(viTruth, vdConfidences, iPositiveLabel,dROCThreshold);
    
    % Save metrics
    vdAUC(iCancerThresholdIx) = dAUC;
    vdROCThreshold(iCancerThresholdIx) = dROCThreshold;    
    vdSensitivity(iCancerThresholdIx) = dTruePositiveRate;
    vdSpecificity(iCancerThresholdIx) = dTrueNegativeRate;

    % Find threshold index and plot point
    % dIndexForPlot = vdROCThresholdsForPlotting == dROCThreshold;
    % hold('on');
    % plot(vdX(dIndexForPlot), vdY(dIndexForPlot), 'Marker', '+', 'MarkerSize', 8, 'Color', [0 0 0], 'LineWidth', 1.5);
end

vdThresholds = vdThresholds';
tMetrics = table(vdThresholds, vdSensitivity, vdSpecificity, vdROCThreshold);
save([Experiment.GetResultsDirectory(), '\Metrics.mat'], 'tMetrics')

% Plot random chance line
hold('on');
plot([0 1],[0 1], 'Color', [211, 211, 211]/255, 'LineWidth', 1);

% Set up the font
fontsize(11,'points')
fontname('calibri')

% Fix background and plot shape
grid('on');
axis('equal');

c1chLegend = [c1chLegend, {'Random chance line'}];
legend(c1chLegend, 'Location', 'southeast')

% Label and fix axes
xlim([0,1]);
ylim([0,1]);

xticks(0:0.1:1);
yticks(0:0.1:1);

vsYTickLabels = arrayfun(@(a) num2str(a*100, '%2.f') + "%", yticks);
yticklabels(vsYTickLabels)
xticklabels(vsYTickLabels)
xtickangle(90)

xlabel('False Positive Rate');
ylabel('True Positive Rate');

% Add titles
title("ROC curves for different cancer content" + newline + "thresholds used for the positive label");

% Save
savefig([Experiment.GetResultsDirectory(), '\ROCs.fig'])
saveas(gcf, [Experiment.GetResultsDirectory(), '\ROCs.svg']);
print([Experiment.GetResultsDirectory(), '\ROCs.tiff'], '-dtiffn')
close(gcf)