% Get patient Ids
load(Experiment.GetDataPath('AllIds'),'stSlideNamesBySet');
vsAllSlideNames = [stSlideNamesBySet.Train; stSlideNamesBySet.Val; stSlideNamesBySet.Test];
[~, vsPatientIDs] = TCGAUtils.GetIDsFromTileFilepaths(vsAllSlideNames,'bSlideNamesNotTilesGiven', true);
vsPatientIDs = unique(vsPatientIDs);

%% Get clinical info
%tClinicalInfo = readtable(Experiment.GetDataPath('ClinicalInfoCBP'), 'FileType', 'delimitedtext','Delimiter','\t');
tClinicalInfo = readtable(Experiment.GetDataPath('ClinicalInfo'), 'FileType', 'delimitedtext','Delimiter','\t');
%tClinicalInfo.PatientID = string(tClinicalInfo.PatientID);
tClinicalInfo.case_submitter_id = string(tClinicalInfo.case_submitter_id);

%% Decide on column to copy
vsVarsOfInterest = ["case_submitter_id", "age_at_index", "ethnicity", "gender", "race",...
    "ajcc_pathologic_stage", "ajcc_pathologic_m", "ajcc_pathologic_n", "ajcc_pathologic_t",...
    "primary_diagnosis","prior_treatment","site_of_resection_or_biopsy","tissue_or_organ_of_origin"];

%% Find patient rows
vdPatientRowInClinical = nan(1, length(vsPatientIDs));
for iPatientIdx = 1:length(vsPatientIDs)
    sCurrentPatientId = vsPatientIDs(iPatientIdx);

    % For some reason each patient has two rows. This issue is from the GDC
    % and I can't find the reason for it, so I'm just gonna check that the
    % rows for the variables I'm interested in ar eequal
    vdPatientRows = find(tClinicalInfo.case_submitter_id == sCurrentPatientId);
    tPatientTable = tClinicalInfo(vdPatientRows,vsVarsOfInterest);

    % Convert to a comparabale array
    c1chRow1 = table2cell(tPatientTable(1,:));
    c1chRow2 = table2cell(tPatientTable(2,:));

    vsRow1 = cellfun(@(c) string(c), c1chRow1);
    vsRow2 = cellfun(@(c) string(c), c1chRow2);

    % Check if rows are identical
    if any(vsRow1 ~= vsRow2)

        % missing ~= mising make sure the inequality isn't coming from
        % that (i.e. check that they're both missing, and if that's not
        % the case error)
        if ismissing(vsRow1(vsRow1 ~= vsRow2)) && ismissing(vsRow2(vsRow1 ~= vsRow2))
            dPatientRow = vdPatientRows(1);
        else
            error("Some columns are not equal and are not just missing")
        end
    else
        dPatientRow = vdPatientRows(1);
    end

    vdPatientRowInClinical(iPatientIdx) = dPatientRow;
end

tPatientClinicalInfoClean = tClinicalInfo(vdPatientRowInClinical, vsVarsOfInterest);
tPatientAllClinicalInfo = tClinicalInfo(vdPatientRowInClinical, :);
tClinicalInfoClean = tClinicalInfo(:, vsVarsOfInterest);

save([Experiment.GetResultsDirectory(), '\ClinicalInfoTables.mat'],...
    "tPatientAllClinicalInfo", "tPatientClinicalInfoClean", "tClinicalInfoClean", "tClinicalInfo")
writetable(tPatientClinicalInfoClean, [Experiment.GetResultsDirectory(), '\StudyPatientInfoClean.xlsx'])
writetable(tPatientAllClinicalInfo, [Experiment.GetResultsDirectory(), '\StudyPatientInfoAll.xlsx'])
writetable(tClinicalInfoClean, [Experiment.GetResultsDirectory(), '\TCGALUSCPatientInfoClean.xlsx'])
writetable(tClinicalInfo, [Experiment.GetResultsDirectory(), '\TCGALUSCPatientInfoAll.xlsx'])

