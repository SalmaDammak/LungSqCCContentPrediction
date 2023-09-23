# Lung Squamous Cell Carcinoma (SqCC) Content Prediction

To skip directly to the model instructions, go [here](placeholder-link).

Whenever a folder contains "Experiment.m", it is an experiment folder that must be run as following. In MATLAB, change directory to the folder of interest and type Experiment.Run() in the command prompt then hit Enter. The results will be produced in a time-stamped copy of the folder.
For this to work, the paths in datapath.txt should have the exact path to the correct directory/file on your computer.

## 1. Images
Steps:
- Download list of slides in <a>/1_Images/ListOfSlidesBySet.csv<a> from the [GDC](https://portal.gdc.cancer.gov/).
- Import all slides into QuPath 0.3.2.
- In QuPath click "View > Show Grid", then go to "View > Set Grid Spacing" and set spacing to 1,260 for both, and click "Use microns"
- Create contours in QuPath at 12.5 tp 20x with the brush tool, naming the classes with the exact spelling in quotes:
	- 'Central': draw two 1260 x 1260 squares in the central region of the tumour
	- 'Peripheral': draw two 1260 x 1260 squares in the peripheral region of the tumour
	- 'Central Non-Viable Tumour': contour non-viable tumour within the central squares
	- 'Central Viable Tumour': contour viable tumour within the central squares
	- 'Peripheral Non-Viable Tumour': contour non-viable tumour within the peripheral squares
	- 'Peripheral Viable Tumour': contour viable tumour within the peripheral squares
	- 'Non-Cancer Non-Tumour': contour area outside the tumour at low mgnification
- Run (</1_Images/0p2520_Foci.groovy>) and (</1_Images/0p2520_NCNT.groovy>) by copying the code in them into "QuPath > Automate > Show script editor" to obtain tiles and their labelmaps
- A label of 0 in the resultant labelmaps is an "unknown" label. Remove tiles with this label using (</1_Images/1 Remove tiles with unkown label>).
- Make tile objects using (</1_Images/2 Make tile objects>)
- Split patients for the experiments using (</1_Images/3 Split patients>)

The code to generate Tables 1 and 2 is also in the (</1_Images>) folder.
Note that Table 1 requires exporting the LUSC dataset clinical information from [cBioPortal](https://www.cbioportal.org/) and the [GDC](https://portal.gdc.cancer.gov/).

## 2. Regression
- "/2_Regression/1 Collect tile tables for python"

### Trained model
The model is currently stored [here](https://uwoca-my.sharepoint.com/:u:/g/personal/sdammak_uwo_ca/EaUAWC6ClFhDodxLFLlEhiEBTD-prS0cUuDmy9woDCGBnA?e=1ic20a).
To load the model, download and unzip the "Model" folder, set ```model_path``` to where the Model file is and run the following in python:
```
import tensorflow as tf
model = tf.keras.models.load_model(model_path, custom_objects=None,compile=True)
```


## 3. Classification


## 4. WSI (fully contoured single WSI demonstration)



## 5. Figures and tables