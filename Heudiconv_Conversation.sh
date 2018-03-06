#!/bin/bash

set -e 

######Heudiconv Conversation######
#####Defining pathway
toplvl=/Users/franklinfeingold/Desktop/HeuDiConv_script
dcmdir=/Users/franklinfeingold/Desktop/HeuDiConv_script/Dicom
niidir=${toplvl}/Nifti

##Define dcmtk path
dcmtk=/Users/franklinfeingold/Desktop/dcmtk-3.6.3-install
####Initialize dcmodify
export DCMDICTPATH=${dcmtk}/usr/local/share/dcmtk/dicom.dic:${dcmtk}/usr/local/share/dcmtk/private.dic:${dcmtk}/usr/local/share/dcmtk/diconde.dic

####Initialize dcm2niix
##This path needs to be changed to where the dcm2niix folder is 
PATH="/Users/franklinfeingold/Desktop/dcm2niix_3-Jan-2018_mac:${PATH}"
export PATH

####Initialize heudiconv
docker pull nipy/heudiconv:latest

#Loop for running subjects in Dicom folder
for subj in 2475376 3893245; do 
echo "Processing ${subj}"

###!!!!Important to add to text, getting dcmtk link to download
######Anatomical Organization######
####Add Protocol Name to MPRAGE DICOMs
${dcmtk}/usr/local/bin/dcmodify -i "(0018,1030)=MPRAGE" ${dcmdir}/${subj}/anat/*.dcm

####Run HeuDiConv first pass through on MPRAGE
docker run --rm -it -v ${toplvl}:/base nipy/heudiconv:latest -d /base/Dicom/{subject}/{session}/*.dcm -o /base/Nifti/ -f /base/Nifti/code/convertall.py -s ${subj} -ss anat -c none

###Copy dicominfo out of .heudiconv folder
cp ${niidir}/.heudiconv/${subj}/info/dicominfo_ses-anat.tsv ${toplvl}

###Remove .heudiconv folder
rm -r ${niidir}/.heudiconv

###Evalulate the different columns of the dicominfo file to determine the heuristic.py organization rules before deleting
rm ${toplvl}/dicominfo_ses-anat.tsv

###Edit content time and content date 
#Content Time
${dcmtk}/usr/local/bin/dcmodify -m "(0008,0033)=202005" ${dcmdir}/${subj}/anat/*.dcm
#Content Date
${dcmtk}/usr/local/bin/dcmodify -m "(0008,0023)=110102" ${dcmdir}/${subj}/anat/*.dcm

####HeuDiConv converting and organizating using the heuristic.py file 
docker run --rm -it -v ${toplvl}:/base nipy/heudiconv:latest -d /base/Dicom/{subject}/{session}/*.dcm -o /base/Nifti/ -f /base/Nifti/code/heuristic.py -s ${subj} -ss anat -c dcm2niix -b

###Changing participant.tsv blanks to n/a
if [[ -e ${niidir}/participants.tsv ]]; then
	echo -e participant_id'\t'age'\t'sex'\t'group'\n'sub-2475376'\t'n/a'\t'n/a'\t'control'\n'sub-${subj}'\t'n/a'\t'n/a'\t'control > ${niidir}/participants.tsv 
else
echo -e participant_id'\t'age'\t'sex'\t'group'\n'sub-${subj}'\t'n/a'\t'n/a'\t'control > ${niidir}/participants.tsv 
fi

######Diffusion Organization######
####Determine which sessions have a DTI scan
if [[ -e ${dcmdir}/${subj}/session1/DTI_mx_137 && ! -e ${dcmdir}/${subj}/session2/DTI_mx_137 ]]; then
	sessions=session1
else
if [[ -e ${dcmdir}/${subj}/session2/DTI_mx_137 && ! -e ${dcmdir}/${subj}/session1/DTI_mx_137 ]]; then
	sessions=session2
else
	sessions="session1 session2"
fi
fi

####Add Protocol Name to Diffusion DICOMs
for ses in ${sessions}; do 
${dcmtk}/usr/local/bin/dcmodify -i "(0018,1030)=DTI_mx_137_${ses}" ${dcmdir}/${subj}/${ses}/DTI_mx_137/*.dcm
done

#####Run HeuDiConv first pass on Diffusion scans
for sess in ${sessions}; do 
docker run --rm -it -v ${toplvl}:/base nipy/heudiconv:latest -d /base/Dicom/{subject}/{session}/DTI_mx_137/*.dcm -o /base/Nifti/ -f /base/Nifti/code/convertall.py -s ${subj} -ss ${sess} -c none

###Copy dicominfo out of .heudiconv folder
cp ${niidir}/.heudiconv/${subj}/info/dicominfo_ses-${sess}.tsv ${toplvl}

###Remove .heudiconv folder before running heudiconv again
rm -r ${niidir}/.heudiconv
done

###Evalulate the different columns of the dicominfo file to determine the heuristic.py organization rules before deleting
rm ${toplvl}/dicominfo_ses-session*.tsv

###Link back to updated heuristic.py file in text
###Edit content time and content date for diffusion scans
for sesss in ${sessions}; do 
#Content Time
${dcmtk}/usr/local/bin/dcmodify -m "(0008,0033)=202005" ${dcmdir}/${subj}/${sesss}/DTI_mx_137/*.dcm
#Content Date
${dcmtk}/usr/local/bin/dcmodify -m "(0008,0023)=110102" ${dcmdir}/${subj}/${sesss}/DTI_mx_137/*.dcm
done

####HeuDiConv converting and organization of diffusion scans using the heuristic.py file
for sses in ${sessions}; do 
docker run --rm -it -v ${toplvl}:/base nipy/heudiconv:latest -d /base/Dicom/{subject}/{session}/DTI_mx_137/*.dcm -o /base/Nifti/ -f /base/Nifti/code/heuristic.py -s ${subj} -ss ${sses} -c dcm2niix -b

###Remove .heudiconv folder before running heudiconv again
rm -r ${niidir}/.heudiconv
done

######Functional Organization######
####Add Protocol Name to Functional scans
for direcs in TfMRI_breathHold_1400 TfMRI_eyeMovementCalibration_1400 TfMRI_eyeMovementCalibration_645 TfMRI_visualCheckerboard_1400 TfMRI_visualCheckerboard_645 session1 session2; do 
if [[ $direcs == "session1" || $direcs == "session2" ]]; then
	for rest in RfMRI_mx_645 RfMRI_mx_1400 RfMRI_std_2500; do 
${dcmtk}/usr/local/bin/dcmodify -i "(0018,1030)=${rest}_${direcs}" ${dcmdir}/${subj}/${direcs}/${rest}/*.dcm
done
else
${dcmtk}/usr/local/bin/dcmodify -i "(0018,1030)=${direcs}" ${dcmdir}/${subj}/${direcs}/*.dcm	
fi
done

####Run HeuDiConv first pass on Functional scans
for func in TfMRI_breathHold_1400 TfMRI_eyeMovementCalibration_1400 TfMRI_eyeMovementCalibration_645 TfMRI_visualCheckerboard_1400 TfMRI_visualCheckerboard_645 session1 session2; do  
if [[ $func == "session1" || $func == "session2" ]]; then
	for rest_func in RfMRI_mx_645 RfMRI_mx_1400 RfMRI_std_2500; do 
	docker run --rm -it -v ${toplvl}:/base nipy/heudiconv:latest -d /base/Dicom/{subject}/${func}/{session}/*.dcm -o /base/Nifti/ -f /base/Nifti/code/convertall.py -s ${subj} -ss ${rest_func} -c none

#Copy dicominfo out of .heudiconv folder
cp ${niidir}/.heudiconv/${subj}/info/dicominfo_ses-${rest_func}.tsv ${toplvl}/dicominfo_ses-${rest_func}_${func}.tsv

#Remove .heudiconv folder before running heudiconv again
rm -r ${niidir}/.heudiconv
done
else

docker run --rm -it -v ${toplvl}:/base nipy/heudiconv:latest -d /base/Dicom/{subject}/{session}/*.dcm -o /base/Nifti/ -f /base/Nifti/code/convertall.py -s ${subj} -ss ${func} -c none

#Copy dicominfo out of .heudiconv folder
cp ${niidir}/.heudiconv/${subj}/info/dicominfo_ses-${func}.tsv ${toplvl}

#Remove .heudiconv folder 
rm -r ${niidir}/.heudiconv
fi
done

###Evalulate the different columns of the dicominfo file to determine the heuristic.py organization rules before deleting. This command will delete them all. 
rm ${toplvl}/dicominfo_*.tsv  

###Edit content time and content date
for dirrs in TfMRI_breathHold_1400 TfMRI_eyeMovementCalibration_1400 TfMRI_eyeMovementCalibration_645 TfMRI_visualCheckerboard_1400 TfMRI_visualCheckerboard_645 session1 session2; do 
if [[ $dirrs == "session1" || $dirrs == "session2" ]]; then
	for restt in RfMRI_mx_645 RfMRI_mx_1400 RfMRI_std_2500; do 
#Content Time
${dcmtk}/usr/local/bin/dcmodify -m "(0008,0033)=202005" ${dcmdir}/${subj}/${dirrs}/${restt}/*.dcm
#Content Date
${dcmtk}/usr/local/bin/dcmodify -m "(0008,0023)=110102" ${dcmdir}/${subj}/${dirrs}/${restt}/*.dcm
done
else
#Content Time
${dcmtk}/usr/local/bin/dcmodify -m "(0008,0033)=202005" ${dcmdir}/${subj}/${dirrs}/*.dcm
#Content Date
${dcmtk}/usr/local/bin/dcmodify -m "(0008,0023)=110102" ${dcmdir}/${subj}/${dirrs}/*.dcm
fi
done

####HeuDiConv converting and organization of functional scans using the heuristic.py file 
for funcs in TfMRI_breathHold_1400 TfMRI_eyeMovementCalibration_1400 TfMRI_eyeMovementCalibration_645 TfMRI_visualCheckerboard_1400 TfMRI_visualCheckerboard_645 session1 session2; do 
if [[ $funcs == "session1" || $funcs == "session2" ]]; then
	for restt_func in RfMRI_mx_645 RfMRI_mx_1400 RfMRI_std_2500; do 

docker run --rm -it -v ${toplvl}:/base nipy/heudiconv:latest -d /base/Dicom/{subject}/${funcs}/{session}/*.dcm -o /base/Nifti/ -f /base/Nifti/code/heuristic.py -s ${subj} -ss ${restt_func} -c dcm2niix -b || true

rm -r ${niidir}/.heudiconv
done

else

docker run --rm -it -v ${toplvl}:/base nipy/heudiconv:latest -d /base/Dicom/{subject}/{session}/*.dcm -o /base/Nifti/ -f /base/Nifti/code/heuristic.py -s ${subj} -ss ${funcs} -c dcm2niix -b

rm -r ${niidir}/.heudiconv
fi
done

echo "${subj} Complete"
done

