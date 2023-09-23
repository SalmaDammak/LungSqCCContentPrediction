/**
 * This script exports tiles of the same actual size (in microns) regardless of scan resolution. 
 * This typically means that the output images will have a variable size (in pixels) if thir resolutions vary. 
 * 
 * This script in particular tries to match the tissue size in microns for a tile that's 224 x 224 (VGG16 input size)
 * coming from a scan that has a resolution of 0.2520 (the mode of the TCGA lung project scans). 
 * 
 * Created based on this export script:
 * https://qupath.readthedocs.io/en/latest/docs/advanced/exporting_images.html?highlight=export#tile-exporter
 * Salma Dammak, 26 March 2022
 */
 
//**************************************** INPUT PARAMETERS********************************************************** 
// Uncomment to specify the tile side length based on a target resolution and tile size in pixels
//double modeTileSideLength_pixel = 224
//double modeScanResolution_micronsPerPixel = 0.2520
//double targetTileSideLengthSize_microns = modeTileSideLength_pixel * modeScanResolution_micronsPerPixel

// uncomment to just specify a specific tile side length
double targetTileSideLengthSize_microns = 350           
//*******************************************************************************************************************

import qupath.lib.images.servers.LabeledImageServer
def imageData = getCurrentImageData()

// Calculate tile side length in pixels
double resolution_micronsPerPixel = imageData.getServer().getPixelCalibration().getAveragedPixelSize()
double dRequiredTileSideLength_pixels = targetTileSideLengthSize_microns / resolution_micronsPerPixel
int    iRequiredTileSideLength_pixels = Math.round(dRequiredTileSideLength_pixels);

// Create output folder
def name = GeneralTools.getNameWithoutExtension(imageData.getServer().getMetadata().getName())
String folderName = "TileSideLengthOf_" + targetTileSideLengthSize_microns.toString() + "_microns"
def pathOutput = buildFilePath(PROJECT_BASE_DIR, folderName, name)
mkdirs(pathOutput)

// Create an ImageServer where the pixels are derived from annotations
def labelServer = new LabeledImageServer.Builder(imageData)
    .backgroundLabel(0, ColorTools.WHITE)     // Specify background label (usually 0 or 255)
    .downsample(1)                            // Choose server resolution; this should match the resolution at which tiles are exported. 1 = full resolution
    .addLabel('Tumor', 1)                     // Choose output labels (first one goes on the bottom in case of overalp!)
    .addLabel('Stroma', 2)  
    .multichannelOutput(false)                // If true, each label is a different channel (required for multiclass probability)
    .build()

// Create an exporter that requests corresponding tiles from the original & labeled image servers
new TileExporter(imageData)
    .downsample(1)                              // Define export resolution
    .imageExtension('.png')                     // Define file extension for original pixels (often .tif, .jpg, '.png' or '.ome.tif')
    .tileSize(iRequiredTileSideLength_pixels)   // Define size of each tile, in pixels
    .labeledServer(labelServer)                 // Define the labeled image server to use (i.e. the one we just built)
    .annotatedTilesOnly(true)                   // If true, only export tiles if there is a (labeled) annotation present
    .overlap(0)                                 // Define overlap, in pixel units at the export resolution
    .writeTiles(pathOutput)                     // Write tiles to the specified directory

// Save pixel side length for slide
def calibration = getCurrentServer().getPixelCalibration()

// in text format
def file = new File(buildFilePath(PROJECT_BASE_DIR, folderName, name, 'calibration.txt'))
file.text = calibration.pixelWidth + ", " + calibration.pixelHeight

// in JSON format
def map = [
  "name": getProjectEntry().getImageName(),
  "pixel_width": calibration.pixelWidth,
  "pixel_height": calibration.pixelHeight,
  "targetTileSideLengthSize_microns": targetTileSideLengthSize_microns,
  "dRequiredTileSideLength_pixels": dRequiredTileSideLength_pixels,
  "iRequiredTileSideLength_pixels": iRequiredTileSideLength_pixels
]


def gson = GsonTools.getInstance(true)

def JSONfile = new File(buildFilePath(PROJECT_BASE_DIR, folderName, name, 'calibration.json'))
JSONfile.text = gson.toJson(map)

print 'Done!'