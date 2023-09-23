
chTileAndLabelmapDir = Experiment.GetDataPath('RootTileDir');

% Transform masks into foreground and background
vdLabelmapLabels = [0, 1];
vbLabelmapLabelIsForeground = logical([0, 1]);
xForegroundROILabel = uint8(1);
xBackgroundROILabel = uint8(0);

TileImagesUtils.MakeMasksFromLabelmaps(chTileAndLabelmapDir, vdLabelmapLabels,...
    vbLabelmapLabelIsForeground, xForegroundROILabel, xBackgroundROILabel);