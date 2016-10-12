function [lfp_out] = Poly5ToGBMOV_LFP_RealGait_Add(lfp_var, filename)

%GBMOVSTRUCT_ADDPOLY5 Add the content of a Poly5 file to an existing LFP
% GBMOV structure, in case of several recording files for a single subject
% and condition
%   03/09/2014 Jean-Eudes Le Douget, CENIR


%% parameters for the trial

% time pre and post trigger for trial identification
timePreTrigger = 3;
timePostTrigger = 5;

%% load the components of the poly5 file : header and sampled recordings
[hdr data_temp] = tms_read_to_edf_struct(filename);
% test the number of channels
if size(data_temp,1)~=7
    error(['Number of channels in ' filename ' is not equal to 7']);
end

%% affect params for output structure
subjectCode = hdr.patientID;
subjectNumber = str2double(subjectCode(end-1:end));
parseRecord = strsplit(hdr.recordID,'_');
if any(strcmpi('ON',parseRecord))
    medCondition = 'ON';
elseif any(strcmpi('OFF',parseRecord))
    medCondition = 'OFF';
else
    button = questdlg('No medical condition found in header. Do you know it ?','Medical Condition', 'OFF','ON', 'Unknown', 'OFF');
    medCondition = button;
end
if any(strcmpi('S',parseRecord))
    speedCondition = 'S';
elseif any(strcmpi('R',parseRecord))
    speedCondition = 'R';
else
    button = questdlg('No speed condition found in header. Do you know it ?','Speed Condition', 'S','R', 'Unknown', 'S');
    speedCondition = button;
end
tag = {'C_01D', 'C_12D', 'C_23D', 'C_01G', 'C_12G', 'C_23G'};
units = {'uV', 'uV', 'uV', 'uV', 'uV', 'uV'};
fech = hdr.fs;
protocole = 'GBMOV';
session = 'POSTOP';
type = 'LFP';
fileNameOut = [protocole '_' session '_' subjectCode  '_' medCondition '_' speedCondition '_' type];

%% check for consistency of the added file
if ~strcmp(subjectCode, lfp_var.Infos.SubjectCode)
    error('Subject names differ');
end
if subjectNumber ~= lfp_var.Infos.SubjectNumber
    error('Subject numbers differ');
end
if ~strcmp(medCondition, lfp_var.Infos.MedCondition)
    error('Medical conditions differ');
end
if ~strcmp(speedCondition, lfp_var.Infos.SpeedCondition)
    error('Speed conditions differ');
end
if fech ~= lfp_var.Trial(1).Raw.Fech
    error('Sampling frequencies differ');
end

%% signal
nTrialsBefore = length(lfp_var.Trial);
temp_trigg = find(data_temp(1,:)~=2);
trig=temp_trigg(1);
for ii = 2:length(temp_trigg)
    if temp_trigg(ii)~=temp_trigg(ii-1)+1
        trig(end+1) = temp_trigg(ii);
    end
end

trial(length(trig)).Raw = [];
for ii=1:length(trig)
    data = data_temp(2:7,max(1,trig(ii)-timePreTrigger*fech):min(trig(ii)+timePostTrigger*fech,length(data_temp)));
    time = 1/fech *(- min(trig(ii),timePreTrigger*fech) + (0:length(data)-1));
    trialNum = nTrialsBefore + ii;
    trialName = [protocole '_' session '_' subjectCode  '_' medCondition '_' speedCondition '_' num2str(trialNum,'%02d')];
    description{1} = 'Signal LFP. Real gait.';
    trial(ii).Raw = Signal_LFP(data, fech, 'Tag', tag, 'Units', units, 'Time', time, 'TrialName', trialName, 'TrialNum', trialNum, 'Description', description);
    trial(ii).PreProcessed = trial(ii).Raw.PreProcessingLFP;
end

removedTrials = lfp_var.RemovedTrials;

history = lfp_var.History;
history{end+1,1} = date;
history{end,2} = ['Add file ' filename ' to the structure'];

%% create output structure
lfp_out = lfp_var;
lfp_out.Trial = [lfp_var.Trial trial]; % concatenate trials
lfp_out.History = history;
lfp_out.RemovedTrials = removedTrials;

end

