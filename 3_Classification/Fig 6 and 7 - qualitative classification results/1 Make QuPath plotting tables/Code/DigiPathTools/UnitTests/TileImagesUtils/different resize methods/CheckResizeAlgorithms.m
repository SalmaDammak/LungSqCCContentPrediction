% 224x224
dOrigSize = 224;
sDir = "E:\Users\sdammak\Repos\DigiPathTools\UnitTests\TileImagesUtils\different resize methods\";
m3iOriginalImage = imread(sDir + "0orig.png");

vsMethods = ["nearest", "bilinear", "bicubic", "box", "triangle", "cubic", "lanczos2", "lanczos3"];
vdFactors = [1.5, 0.5, 0.75];

for iMethodIdx = 1:length(vsMethods)
    for iFactorIdx = 1:length(vdFactors)
        
        sMethod = vsMethods(iMethodIdx);
        dFactor = vdFactors(iFactorIdx);
        dNewSize = dFactor * dOrigSize;
        sFactor = string(dFactor);
        
        m3iImage = imresize(m3iOriginalImage, [dNewSize, dNewSize], 'method', sMethod);
        sImagePath = sDir + "x" + sFactor + "_" + sMethod + ".png"; 
        imwrite(m3iImage, sImagePath);
    end
end