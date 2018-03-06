import os
def create_key(template, outtype=('nii.gz',), annotation_classes=None):
    if template is None or not template:
        raise ValueError('Template must be a valid format string')
    return template, outtype, annotation_classes
def infotodict(seqinfo):
    """Heuristic evaluator for determining which runs belong where
    allowed template fields - follow python string module:
    item: index within category
    subject: participant id
    seqitem: run number during scanning
    subindex: sub index within group
    """
    t1w = create_key('sub-{subject}/ses-1/anat/sub-{subject}_ses-1_T1w')
    dti1 = create_key('sub-{subject}/ses-1/dwi/sub-{subject}_ses-1_dwi')
    dti2 = create_key('sub-{subject}/ses-2/dwi/sub-{subject}_ses-2_dwi')
    breathhold1400 = create_key('sub-{subject}/ses-1/func/sub-{subject}_ses-1_task-breathhold_acq-TR1400_bold')
    eye645 = create_key('sub-{subject}/ses-1/func/sub-{subject}_ses-1_task-eyemovement_acq-TR645_bold')
    eye1400 = create_key('sub-{subject}/ses-1/func/sub-{subject}_ses-1_task-eyemovement_acq-TR1400_bold')
    checker645 = create_key('sub-{subject}/ses-1/func/sub-{subject}_ses-1_task-Checkerboard_acq-TR645_bold')
    checker1400 = create_key('sub-{subject}/ses-1/func/sub-{subject}_ses-1_task-Checkerboard_acq-TR1400_bold')
    rest1_645 = create_key('sub-{subject}/ses-1/func/sub-{subject}_ses-1_task-rest_acq-TR645_bold')
    rest1_1400 = create_key('sub-{subject}/ses-1/func/sub-{subject}_ses-1_task-rest_acq-TR1400_bold')
    rest1_2500 = create_key('sub-{subject}/ses-1/func/sub-{subject}_ses-1_task-rest_acq-TR2500_bold')
    rest2_645 = create_key('sub-{subject}/ses-2/func/sub-{subject}_ses-2_task-rest_acq-TR645_bold')
    rest2_1400 = create_key('sub-{subject}/ses-2/func/sub-{subject}_ses-2_task-rest_acq-TR1400_bold')
    rest2_2500 = create_key('sub-{subject}/ses-2/func/sub-{subject}_ses-2_task-rest_acq-TR2500_bold')

    info = {t1w: [], dti1: [], dti2: [],  breathhold1400: [], eye645: [], eye1400: [], checker645: [], checker1400: [], rest1_645: [], rest1_1400: [], rest1_2500: [], rest2_645: [], rest2_1400: [], rest2_2500: []}
    
    for idx, s in enumerate(seqinfo):
        if (s.dim3 == 192) and (s.dim4 == 1) and ('MPRAGE' in s.protocol_name):
            info[t1w] = [s.series_id]
        if (s.dim3 == 64) and (s.dim4 == 137) and ('DTI_mx_137_session1' in s.protocol_name):
            info[dti1] = [s.series_id]
        if (s.dim3 == 64) and (s.dim4 == 137) and ('DTI_mx_137_session2' in s.protocol_name):
            info[dti2] = [s.series_id]
        if (s.TR == 0.645) and ('TfMRI_eyeMovementCalibration_645' in s.protocol_name):
            info[eye645] = [s.series_id]
        if (s.TR == 1.4) and ('TfMRI_eyeMovementCalibration_1400' in s.protocol_name):
            info[eye1400] = [s.series_id]
        if (s.TR == 0.645) and ('TfMRI_visualCheckerboard_645' in s.protocol_name):
            info[checker645] = [s.series_id]
        if (s.TR == 1.4) and ('TfMRI_visualCheckerboard_1400' in s.protocol_name):
            info[checker1400] = [s.series_id]
        if (s.TR == 1.4) and ('TfMRI_breathHold_1400' in s.protocol_name):
            info[breathhold1400] = [s.series_id]
        if (s.TR == 0.645) and ('RfMRI_mx_645_session1' in s.protocol_name):
            info[rest1_645] = [s.series_id]
        if (s.TR == 0.645) and ('RfMRI_mx_645_session2' in s.protocol_name):
            info[rest2_645] = [s.series_id]
        if (s.TR == 1.4) and ('RfMRI_mx_1400_session1' in s.protocol_name):
            info[rest1_1400] = [s.series_id]
        if (s.TR == 1.4) and ('RfMRI_mx_1400_session2' in s.protocol_name):
            info[rest2_1400] = [s.series_id]
        if (s.TR == 2.5) and ('RfMRI_std_2500_session1' in s.protocol_name):
            info[rest1_2500] = [s.series_id]
        if (s.TR == 2.5) and ('RfMRI_std_2500_session2' in s.protocol_name):
            info[rest2_2500] = [s.series_id]
    return info





