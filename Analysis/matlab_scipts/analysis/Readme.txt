> MALTAB Script 'Computation_abs_min_RS_interval.m': Compute the minimal distance between R-peak and sound stimuli
INPUT: 
- Need recording an file (*.bdf)

OUTPUT
-  Excel file with one sheet for individual values and one sheet with the summary values per files (mean, std, median, 1.4826*mad). Data were cleaned by removing R-peak overdetection (shorter than 453 ms).

> MALTAB Script 'Computation_interstimulus_interval.m': Compute the interstimulus interval = distance between a sound and next sound in ms
INPUT: 
- Need recording an file (*.bdf)

OUTPUT
-  Excel file with one sheet for individual values and one sheet with the summary values per files (mean, std, median, 1.4826*mad). Data were cleaned by removing R-peak overdetection (shorter than 453 ms).


> MALTAB Script 'Find_ECG_Rpeaks.m': Determine the R-peak position and write it in a marker file + Record a separate file for the ECG signal
INPUT:  
- Need recording an file (*.bdf) 
	-> The first ECG channel must be on the electrodes EXG1 and EXG2. During the recording, the operator has to ensure that the R-peak signal EXG1-EXG2 is positive. 
	-> The second ECG channel must be on the electrodes EXG3 and EXG4. During the recording, the operator has to ensure that the R-peak signal EXG3-EXG4 is positive.
- Specify if the ecg detection must be performed on the ecg1 (EXG1-EXG2) or ecg2 (EXG3-EXG4). Warning: In the case of a CAS experiment recording, this is always the first option. 
- Specify manually the Internal threshold which must be used in the LIBROW script for R-peak detection. Default value is 4. Decrease this value only in cas of an error message during the proccessing.
- Specify if you want to create a separate file with only the ECG signal in it. 

OUTPUT
- marker file '*.mrk'(* is replace by the input bdf file name) which contain the originals triggers of the '*.bdf' + marker 1 = R-peak position detected by the LIBROW script
- If you specify 'yes' to the final question, a '*ECGonly.eph' file (* is replace by the input bdf file name) which contain only the ECG signal mean centred to shift the 0 position (more easy to read).  
- If you specify 'yes' to the final question, a '*ECGonly.eph.mrk' file (* is replace by the input bdf file name) which is the same marker as the fist output but readable in Cartool for the second file. 


> MALTAB Script 'Generate_ECG_and_HEP_mrk.m': Script to modify the marker files in order to tag the position of a real R-peak detected by the Librow algorithm (used for the HEP analysis).
INPUT: 
- Need recording an file (*.bdf)

OUTPUT
- marker file '*.mrk'(* is replace by the input bdf file name) which contain the originals triggers in the '*.bdf' + marker R-peak position detected by the LIBROW script with the specification defined below: 
 HEP analysis decision
 10 - R-peak on sounds in synch condition
 11 - R-peak on omission in synch condition
 12 - R-peak closest to sound in asynch condition (min 500ms after last sound trigger of previous stim)
 13 - R-peak closest to omission in asynch condition (min 500ms after last sound trigger of previous stim)
 1- R-peak which is not associate to a stim
 
 For the detection in asynch, the R-peak must at leat 500ms after the previous stim (sound or omission).
 No limitation for after the stim (decision to avoid a possible effect the previous sound). 
 If two R-peak have exactely the same distance from the stim, choose the one after it.
- If you specify 'yes' to the final question, a '*ECG.eph' file (* is replace by the input bdf file name) which contain only the ECG signal mean centred to shift the 0 position (more easy to read).  
- If you specify 'yes' to the final question, a '*ECG.eph.mrk' file (* is replace by the input bdf file name) which is the same marker as the fist output but readable in Cartool for the second file.


> MALTAB Script 'Look_for_interbeat_valuesV2.m': look at the heart interbeat (RR distance).
INPUT: 
- Need recording an file (*.bdf)

OUTPUT
-  Excel file with one sheet with the mean of RR distance around the omission (-1, 0, 1, ..., 10) for each participant. Data were cleaned by removing R-peak overdetection (shorter than 453 ms).


> MALTAB Script 'Computation_interstimulus_interval.m': Compute the interstimulus interval = distance between a sound and next sound in ms
INPUT: 
- Need recording an file (*.bdf)

OUTPUT
-  Excel file with one sheet for individual values and one sheet with the summary values per files (mean, std, median, 1.4826*mad). Data were cleaned by removing R-peak overdetection (shorter than 453 ms).


Michaël Mouthon - michael.mouthon@unifr.ch 