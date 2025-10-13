MALTAB Script 'ECG_R_peak_detection_Compute_Variance_LABVIEW_version_V2.mat': Prepare the required files for the CAS experiment based on the HEP recording (R-peak detection threshold, experimental sucession) + Determine R-peak position to use in the HEP processing
INPUT: 
- Specify path of the recording file (*.bdf) of the HEP experiment (perform systematicaly before the CAS task). There is serveral requirements: 
	-> The first ECG channel must be on the electrodes EXG1 and EXG2. During the recording, the operator has to ensure that the R-peak signal EXG1-EXG2 is positive. 
	-> The second ECG channel must be on the electrodes EXG3 and EXG4. During the recording, the operator has to ensure that the R-peak signal EXG3-EXG4 is positive.
	-> The file contain the tiggers 5 (start heart block), 11 (middle of the recording), 12 (end of recording). These triggers will be used to split the recording in two part (first half learning phase, second half training phase). 
- Enter the participant code which will be used for name the output file
- A dialog box ask you if you want to save the marker file of the estimated position after training of the algo on the second half of the signal. This is not mandatory but only a quality check
In addition, to be exectuded, the folder 'functions_needed' must be in the same path than the script.
At the beginning of the code, you can change the number of stimulation expected for each CAS block (variable nbstim)

OUTPUT: In the same folder as the input '*.bdf' file, you will find these files:
- 'logfile_*.txt' (* will be replace by the subject code you have choosen in second input): This file contain :
 line2 -> the custom threshold to detect an R-peak. This value is used to detect R-peak in real time by the LABVIEW program "ActiView_InteroceptionProject_Task3.exe".
 line3 -> the custom scaling compute during the training part of this script
 line4 -> What is the best ECG channel between ECG1 or ECG2 based on R-peak amplitude
 line 6-8 -> Mean Heart beat rate
 line 9 -> internal threshold used for R-peak detection in the LIBROW script
- 'CardioSynchExperimental_*.txt' (* will be replace by the subject code you have choosen in second input)
This file define the experimental sucession for each trial. It will be loaded by the LABVIEW program "ActiView_InteroceptionProject_Task3.exe"
The 4 first coloums are the randomize experimental succesion for the 4 blocks (20% nosound/80% sound). 
The 2 last columns are the randomise inter R-peak interval of the participant used in the Asynch condition. 
- the Cartool marker file '*.mrk' (* is replace by the input bdf file name) which will permit the processing of the HEP data: 
	1: R-peak during heart beat block
	2: R-peak during sound block
	3: R-peak during Inter-stimulus rest period 
	4: R-peak during all other period (questions, evaluation, instruction)
- the Cartool marker file '*_qualityCheckDetectionPart2.mrk' (* is replace by the input bdf file name). Generated only if you respond 'Yes' for the third input. 
Permit to check the performance of realtime R-peak detection with best threshold. 
	1: R-peak detect by LIBROW script (ideal position)
	2: R-peak detect by the realtime detection (simulation during learning phase). 

DETAILS DESCRIPTION OF SCRIPT FUNCTIONNING 
Element are presented in order of execution
1. Load the '*.bdf' file thank to the function open_bdf write by Dr. Michael De Pretto
2. Extract the two ECG channels (ecg1, ecg2)
3. Detect the R-peak using the LIBROW script (http://www.librow.com/articles/article-13) from Sergey Chernenko on ecg1 and ecg2.
4. Determine which is the best ecg channel
	a.compute the mean amplitude of R-peak detected for ecg1 and ecg2
	b. keep the ecg channel with the biggest mean amplitude (R-peak more easey to detect)
5. Writing the position of R-peak of the best ecg channel into a Cartool marker file ('*.mrk'). The used function 'WriteMRK_HEPtask.m' is specific to the HEP recording (marker different if heart or sound block). 
Note: The first and last R-peak detected are systematically removed to avoid problem during averaging of EPOCHS. 
6. Generate file for the experimental sucession for the 4 CAS blocks ('logfile_*.txt' and 'CardioSynchExperimental_*.txt').
Note: the function 'experimentalConditionsRandomization.mat' provide binary vector where it not allow to have two consecutive position with a 0 value.
The value 1 is interpreat as a trial with sound (80%) and 0 is a trial whitout sound (20%). 
7. Learning phase: To detect R-peak in realtime, we follow the method proposed in the Pfeiffer & De Lucia paper (https://doi.org/10.1038/s41598-017-13861-8). Function 'computeRpeakVariance.m'
	a. the variance of the 50ms before each R-peak are compute for the first half of the ecg signal. 
	b. the mean of these variance are used as initial threshold for R-peak detection in realtime
8. Training phase: To optimize the thresholld, the script adpote a machine learning strategy with the second half of the ecg signal. Function 'trainingThresholdRpeak.mat'
	a. MALTAB will simulate a realtime detection by looping over all the 50ms interval of the ecg signal. It will compute the variance for each of them and set a R-peak when it reatch the threshold. To avoid overdetection, there is a cooldown period of 200ms where no R-peak can be set after a detection.
	b. The previous step is reapeat 8 time with 30%,40%,50%,60%,70%,80%,90%,100% of the initial threshold. 
	c. The mean distance between previous estimated R-peak postion and accurate R-peak position determine by LIBROW script (offline) is computed. 
	d. The optimal threshold/parameter is set to the solution with the smallest mean in previous point. 
9. Writing of the resulting threshold into the 'logfile_*.txt' file. 


Michaël Mouthon - michael.mouthon@unifr.ch 