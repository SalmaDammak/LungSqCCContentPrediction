# Lung Squamous Cell Carcinoma (SqCC) Content Prediction 
[[Link to publication]](https://www.sciencedirect.com/science/article/pii/S0010482524015749)

To skip directly to the model instructions, go [here](https://github.com/SalmaDammak/LungSqCCContentPrediction#trained-model).

Whenever a folder contains Experiment.m, it is an "experiment folder" that must be run as following. In MATLAB, change directory to the folder of interest and type ```Experiment.Run()``` in the command prompt then hit Enter. The results will be produced in a time-stamped copy of the folder.
For this to work, the paths in datapath.txt should have the exact path to the correct directory/file on your computer.

## 1. Images
- Download [list of slides](</1_Images/ListOfSlidesBySet.csv>) from the [GDC](https://portal.gdc.cancer.gov/).
- Create a QuPath 0.3.2. project and import all slides into it.
- In QuPath click "View > Show Grid", then go to "View > Set Grid Spacing" and set spacing to 1,260 for both, and click "Use microns".
- Create contours in QuPath at 12.5 tp 20x with the brush tool, naming the classes with the exact spelling in quotes:
	- **'Central'**: draw two 1260 x 1260 squares in the central region of the tumour,
	- **'Peripheral'**: draw two 1260 x 1260 squares in the peripheral region of the tumour,
	- **'Central Non-Viable Tumour'**: contour non-viable tumour within the central squares,
	- **'Central Viable Tumour'**: contour viable tumour within the central squares,
	- **'Peripheral Non-Viable Tumour'**: contour non-viable tumour within the peripheral squares,
	- **'Peripheral Viable Tumour'**: contour viable tumour within the peripheral squares, and
	- **'Non-Cancer Non-Tumour'**: contour area outside the tumour at low mgnification.
- Run [this script](</1_Images/0p2520_Foci.groovy>) and [this one](</1_Images/0p2520_NCNT.groovy>) by copying the code in them into "QuPath > Automate > Show script editor" to obtain tiles and their labelmaps.
- A label of 0 in the resultant labelmaps is an "unknown" label. Remove tiles with this label using [this experiment folder](</1_Images/1 Remove tiles with unkown label>).
- Make tile objects using [this experiment folder](</1_Images/2 Make tile objects>).
- Split patients for the experiments using [this experiment folder](</1_Images/3 Split patients>).
- The code to generate Tables 1 and 2 is also in the [1_Images](</1_Images>) folder. Note that Table 1 requires exporting the LUSC dataset clinical information from [cBioPortal](https://www.cbioportal.org/) and the [GDC](https://portal.gdc.cancer.gov/).

## 2. Regression
- Create csv files for each slide, grouped in dataset folders using [this experiment folder](</2_Regression/1 Collect tile tables for python>).
- Run the optional but recommended quality control step double checking that the datasets do no contain any centres in common using [this experiment folder](</2_Regression/2 Quality control step - dataset check>).
- Train the model and validate it using [this experiment folder](</2_Regression/3 Train and validate>).
	- the .yml file to build the virtual environment is [here](</2_Regression/keras_env.yml>). In the miniconda3 command prompt use ```conda env create -f environment.yml --name keras_env``` to build the same virtual environment I used.
- Test the model on the regions of interest using [this experiment folder](</2_Regression/4 Test on foci>). Note that this will include clear tiles, giving an optimistic result. This is not what we reported in the paper, and instead reported the results after removing clear slides by first using [this experiment folder](</2_Regression/Fig 1 - regression error/1 Remove clear tiles>) then [this one (Fig 3)](</2_Regression/Fig 1 - regression error/2 Make plots>).
- For per centre results, use [this experiment folder (Fig 4)](</2_Regression/Fig 2 - regression error by center/1 Make plots>).

### Trained model
The model is currently stored [here](https://drive.google.com/file/d/1NBerw3yvLAQmXWghtfP4M087Yun7CB9B/view?usp=drive_link).
To load the model, download and unzip the "Model" folder, set ```model_path``` to where the Model file is and run the following in python:
```
import tensorflow as tf
model = tf.keras.models.load_model(model_path, custom_objects=None,compile=True)
```

## 3. Classification
- Get the classification AUCs for different thresholds and the associated ROC using [this experiment folder (Fig 5)](</3_Classification/Fig 5 - ROCs and AUCs>).
- To the qualitative results do the following:
	- Run [this experiment folder](</3_Classification/Fig 6 and 7 - qualitative classification results/1 Make QuPath plotting tables>) to get the list of tiles predicted as true/false positive/negative. This will be in the form of .csv files that will be in the results folder.
	- Make a "predictionTables" in the QuPath project folder and copy the .csv files into it.
	- Run [this script](</3_Classification/Fig 6 and 7 - qualitative classification results/MakePredFN_FP.groovy>) from within the QuPath script editor.
	- Note that this was also tested for QuPath 0.4.0 and 0.4.3 and it works for both.

## 4. WSI (fully contoured single WSI demonstration)
- Prepare slide:
	- Download slide indicated [here](</4_WSI/SlideName.txt>) from [GDC](https://portal.gdc.cancer.gov/).
	- Import into a QuPath project.
	- Contour cancer in the whole slide and label as **'Cancer'** in QuPath.
	- Export tiles and their labelmaps using [this script](</4_WSI/ExportAllTile.groovy>) in the QuPath editor.
- Make labelmaps into binary masks using [this experiment folder](</4_WSI/1 Make binary masks from labelmaps>).
- Create .csv tables of tiles for python using [this experiment folder](</4_WSI/12 Make tile objects and tables>).
- Make .csv tables that only contain non-clear slide tiles using [this experiment folder](</4_WSI/3 Find non-clear slide tiles>).
- Classify the non-clear tiles using [this experiment folder](</4_WSI/4 Classify>).
- For qualitiave results:
	- Make tile prediction tables to plot back into QuPath using [this experiment folder](</4_WSI/5 Make QuPath plotting tables FN FP tables>).
	- Follow the steps listed in [Classification](https://github.com/SalmaDammak/LungSqCCContentPrediction#3-classification).


