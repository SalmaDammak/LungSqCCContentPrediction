import java.io.BufferedReader;
import java.io.FileReader;
import qupath.lib.objects.PathAnnotationObject;
import qupath.lib.roi.RectangleROI;

// delete annotations from previous run
selectObjectsByClassification("Predicted_Tumor");
clearSelectedObjects();
selectObjectsByClassification("Predicted_Stroma");
clearSelectedObjects();

def imageData = getCurrentImageData();
def imageName = imageData.getServer().getMetadata().getName();
def file = new File(buildFilePath(PROJECT_BASE_DIR, "predictionTables" ,imageName[0..-5]+".csv"))
print file
print file

def csvReader = new BufferedReader(new FileReader(file))

//t sizePixels = 1000
row = csvReader.readLine()

while ((row = csvReader.readLine()) != null) {
    def rowContent = row.split(",")
    
    // read the tile information from the CSV
    double x_location = rowContent[1] as double;
    double y_location = rowContent[2] as double;
    double height = rowContent[3] as double;
    double width = rowContent[4] as double;
    
    boolean vdTP = rowContent[8] as double == 1;
    boolean vdFP = rowContent[9] as double == 1;
    boolean vdTN = rowContent[10] as double == 1;
    boolean vdFN = rowContent[11] as double == 1;
    
    def roi = new RectangleROI(x_location,y_location,width,height);
       
    def annotation = new PathAnnotationObject();

    if (vdTP){  
        annotation = new PathAnnotationObject(roi, PathClassFactory.getPathClass("TruePositive",ColorTools.GREEN));
    } else if (vdFP){
        annotation = new PathAnnotationObject(roi, PathClassFactory.getPathClass("FalsePositive",ColorTools.BLACK));
    } else if (vdTN){
        annotation = new PathAnnotationObject(roi, PathClassFactory.getPathClass("TrueNegative",ColorTools.CYAN));
    } else if (vdFN){
        annotation = new PathAnnotationObject(roi, PathClassFactory.getPathClass("FalseNegative",ColorTools.MAGENTA));
    }
    imageData.getHierarchy().addPathObject(annotation);
}
// merge annotations
/*
selectObjectsByClassification("TruePositive");
mergeSelectedAnnotations();

selectObjectsByClassification("FalsePositive");
mergeSelectedAnnotations();

selectObjectsByClassification("TrueNegative");
mergeSelectedAnnotations();

selectObjectsByClassification("FalseNegative");
mergeSelectedAnnotations();

//selectObjectsByClassification("Predicted_Stroma", "Other");
//intersectSelectedAnnotations(); //https://forum.image.sc/t/intersecting-annotations-from-script/42889/3
*/
print('Done!')
