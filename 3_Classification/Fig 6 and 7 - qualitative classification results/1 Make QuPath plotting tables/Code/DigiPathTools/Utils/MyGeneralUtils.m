classdef MyGeneralUtils
    
    methods (Static = true, Access = public)
        
        function bIndexOfMatches = contains_exact(c1chCellArrayToSearch, chCharacterArrayToFind)
            % A function that looks for the exact string/characters array in a cell array
            % contains({'test','testy'}, 'test') returns [1,1]
            % contains_exact({'test','testy'}, 'test') returns [1,0]
            %TODO: move to a more appropriate class
            
            bIndexOfMatches = false(size(c1chCellArrayToSearch,1), size(c1chCellArrayToSearch,2));
            for i = 1:size(c1chCellArrayToSearch,1)
                for j = 1:size(c1chCellArrayToSearch,2)
                    if strcmp(c1chCellArrayToSearch{i,j}, chCharacterArrayToFind)
                        bIndexOfMatches(i,j) = true;
                    end
                end
            end
        end
        
        function DeleteFilesWithRegexp(chRegularExpression)
            stFileInfo = dir(chRegularExpression);
            
            for i = 1:length(stFileInfo)
                delete([stFileInfo(i).folder,'\', stFileInfo(i).name])
            end
            
        end
        
        function tData = ConvertVectorOfObjectsToTable(voVectorOfObjects)
            arguments
                voVectorOfObjects
            end
            
            vsPropertyNames = string(properties(voVectorOfObjects(1)));
            dNumColumns = length(vsPropertyNames);
            dNumRows = length(voVectorOfObjects);
            c2dTable = cell(dNumRows, dNumColumns);
            
            for iRow = 1:dNumRows
                for iCol = 1:dNumColumns
                    sProperty = vsPropertyNames(iCol);                    
                    c2dTable{iRow, iCol} = voVectorOfObjects(iRow).(sProperty);
                end
            end
            
            tData = cell2table(c2dTable,'VariableNames', vsPropertyNames);

        end
        
        function c1xObj = ConvertObjToCellArray(oAnObject, NameValueArgs)
            arguments
                oAnObject
                NameValueArgs.vsPropertiesToIgnore
            end
            
            vsPropertyNames = string(properties(oAnObject));
            
            if isfield(NameValueArgs, 'vsPropertiesToIgnore')
                vdIdx = [];
                for iPropertyIdx = 1:length(NameValueArgs.vsPropertiesToIgnore)
                    sProperty = NameValueArgs.vsPropertiesToIgnore(iPropertyIdx);
                    dIdx = find(ismember(vsPropertyNames, sProperty));
                    vdIdx = [vdIdx, dIdx];
                end
                vsPropertyNames(vdIdx) = [];
            end
            
            dNumColumns = length(vsPropertyNames);            
            c1xObj = cell(1, dNumColumns*2);
            
            iPropertyIdx = 0;
            iValueIdx = 0;
            for iCol = 1:dNumColumns*2               
                
                if ~rem(iCol,2) == 0
                    iPropertyIdx = iPropertyIdx + 1;
                    sProperty = vsPropertyNames(iPropertyIdx);
                    c1xObj{iCol} = char(vsPropertyNames(iPropertyIdx));
                else
                    iValueIdx = iValueIdx + 1;
                    c1xObj{iCol} = oAnObject.(sProperty);
                end
                
            end

        end
        
        function c1xNameValueArgs = ConvertNameValueArgsStructToCell(stNameValueArgsToConvert, NameValueArgs)
            arguments
                stNameValueArgsToConvert
                NameValueArgs.vsFieldsToIgnore string
            end
            
            
            vsFields = string(fields(stNameValueArgsToConvert));
            c1xValues = struct2cell(stNameValueArgsToConvert);
            if isfield(NameValueArgs, 'vsFieldsToIgnore')
                vdFieldsToRemoveIndices = [];
                for iFieldIdx = 1:length(NameValueArgs.vsFieldsToIgnore)
                    sField = NameValueArgs.vsFieldsToIgnore(iFieldIdx);
                    dIdx = find(ismember(vsFields, sField));
                    vdFieldsToRemoveIndices = [vdFieldsToRemoveIndices, dIdx];
                end
                vsFields(vdFieldsToRemoveIndices) = [];
                c1xValues(vdFieldsToRemoveIndices) = [];
            end
            
                        
            c1xNameValueArgs = cell(length(vsFields)*2,1);
            iFieldIdx = 0;
            iValueIdx = 0;
            for iFinalArrayIdx = 1:length(c1xNameValueArgs)
                
                if ~rem(iFinalArrayIdx,2) == 0
                    iFieldIdx = iFieldIdx + 1;
                    c1xNameValueArgs{iFinalArrayIdx} = vsFields{iFieldIdx};
                else
                    iValueIdx = iValueIdx + 1;
                    c1xNameValueArgs{iFinalArrayIdx} = c1xValues{iValueIdx};
                end
            end
            
        end
        
        function chExtentsion = GetFileExtension(chFilePath)
            c1chExtentsion = regexp(chFilePath, '.*\.([a-zA-Z]+)', 'tokens','once');
            chExtentsion = c1chExtentsion{:};
        end
        
        function [dAUC, dAccuracy, dTrueNegativeRate, dTruePositiveRate, dPPV, tExcelFileMetrics, dThreshold]=...
                CalculateAllTheMetrics(viTruth, vdConfidences, iPositiveLabel)
            
            dAUC = ErrorMetricsCalculator.CalculateAUC(viTruth, vdConfidences, iPositiveLabel);
            disp("AUC: " + num2str(dAUC,'%.2f'))
            
            dThreshold = ErrorMetricsCalculator.CalculateOptimalThreshold(...
                {"upperleft","MCR","matlab"}, viTruth, vdConfidences, iPositiveLabel);
            
            dMisclassificationRate = ErrorMetricsCalculator.CalculateMisclassificationRate(...
                viTruth, vdConfidences, iPositiveLabel,dThreshold);
            dAccuracy = 1 - dMisclassificationRate;
            disp("accuracy is: " + num2str(round(100*(1-dMisclassificationRate)))+ "%")
            
            dTrueNegativeRate = ErrorMetricsCalculator.CalculateTrueNegativeRate(...
                viTruth, vdConfidences, iPositiveLabel,dThreshold);
            disp("TNR is: " + num2str(round(100*(dTrueNegativeRate)))+ "%")
            
            dTruePositiveRate = ErrorMetricsCalculator.CalculateTruePositiveRate(...
                viTruth, vdConfidences, iPositiveLabel,dThreshold);
            disp("TPR is: " + num2str(round(100*(dTruePositiveRate))) + "%")            
           
            dPPV = ErrorMetricsCalculator.CaluclatePositivePredictiveValue(...
                viTruth, vdConfidences, iPositiveLabel, dThreshold);
            disp("PPV is: " + num2str(round(100*(dPPV))) + "%")    
            
            tExcelFileMetrics = table(dAUC, dThreshold, dAccuracy, dTrueNegativeRate, dTruePositiveRate);
        end   
        
        function [dAUC, dAccuracy, dTrueNegativeRate, dTruePositiveRate, dPPV, tExcelFileMetrics]=...
                CalculateAllTheMetricsGivenThreshold(viTruth, vdConfidences, iPositiveLabel, dThreshold)
            
            dAUC = ErrorMetricsCalculator.CalculateAUC(viTruth, vdConfidences, iPositiveLabel);
            disp("AUC: " + num2str(dAUC,'%.2f'))
                        
            dMisclassificationRate = ErrorMetricsCalculator.CalculateMisclassificationRate(...
                viTruth, vdConfidences, iPositiveLabel,dThreshold);
            dAccuracy = 1 - dMisclassificationRate;
            disp("accuracy is: " + num2str(round(100*(1-dMisclassificationRate)))+ "%")
            
            dTrueNegativeRate = ErrorMetricsCalculator.CalculateTrueNegativeRate(...
                viTruth, vdConfidences, iPositiveLabel,dThreshold);
            disp("TNR is: " + num2str(round(100*(dTrueNegativeRate)))+ "%")
            
            dTruePositiveRate = ErrorMetricsCalculator.CalculateTruePositiveRate(...
                viTruth, vdConfidences, iPositiveLabel,dThreshold);
            disp("TPR is: " + num2str(round(100*(dTruePositiveRate))) + "%")            
           
            dPPV = ErrorMetricsCalculator.CaluclatePositivePredictiveValue(...
                viTruth, vdConfidences, iPositiveLabel, dThreshold);
            disp("PPV is: " + num2str(round(100*(dPPV))) + "%")    
            
            tExcelFileMetrics = table(dAUC, dThreshold, dAccuracy, dTrueNegativeRate, dTruePositiveRate);
        end 
       
        function DispLoopProgress(dIdx, dLoopLength)
            
            dPercent = round(100*dIdx/dLoopLength);
            disp(num2str(dPercent, '%2.f') + "%")
            
        end
    end
end