% Calcul des variables caractérisant les signaux EMG : pour GBMOV (M3), PSPMARCHE, (PARKGAME : TODO) 
% Infos sorties :
% TIMING (pour toutes les sessions)
%   - Timing des début et fin des bouffées pour 4 phases : APA/EXE/DA/Step2:
%       * en absolu (Abs)
%       * en relatif par rapport à la durée de la phase (Rel)
% AMPLITUDE (pour comparaison conditions au sein d'une même session)
%   - Aire sous la courbe (RMS)

% Inputs :
% Nom_patient_EMG.mat (issu du Traitement_EMG_v2.m)
% Nom_patient_TrialParams.mat
% Nom_patient_ResAPA.mat

% Outputs :
% - Result_All.mat (structure)
% - *.csv (fichier csv avec une ligne par essai)
%       Architecture globale de Result_All.mat :
%           Result_All(i_patient,i_session,i_speed).Trial(i_trial).ExploitVar.T.Abs.Start(i_EMG,i_ph)
%                                                                                  .Stop
%           Result_All(i_patient,i_session,i_speed).Trial(i_trial).ExploitVar.T.Rel.Start
%                                                                                  .Stop
%           Result_All(i_patient,i_session,i_speed).Trial(i_trial).ExploitVar.RMS    -> Valeur de la RMS
%      // Avec i_EMG : 1 a 4 pour {'SOLSwing','TASwing','SOLStance','TAStance'} dans cet ordre

% INFO : pas de stockage d'info en Segment par sujet

clearvars, clc,

Protocol = char(inputdlg('Quel protocole ?','Protocole',1,{'GBMOV'}));
FootOff = char(inputdlg('Quel nom pour Foot Off ? (TO ou FO1)','FootOff',1,{'FO1'}));

switch Protocol
    case 'GBMOV'
        % patients avec Revoir les nb essais :'ALLGE21','ARDSY20','CORDA09','DESPI05','REBSY04','RECGE02'
        % EMG non exploitables : 'FRELI10',
        % Pb sur certains canaux : CALVI17
        % pas de fichiers EMG.mat : SALJE29 CORDA09
        % Pb nomenclature num EMG NaN : DESPI05
        % Tags_patients={'REBSY04','RECGE02','ARDSY20','CLANI11','SOUJO07','VANPA23','DESMA26','BAUMA18',,'LECCL16','MARDI12','MERPH19','RAYTH21','ABBGI01','ROUDO14','ROYES03'};
        Tags_patients = {'ABBGI01','RECGE02','REBSY04','SOUJO07','HUMCL08','CORDA09','CLANI11','MARDI12','ROUDO14','LECCL16','BAUMA18','MERPH19','ALLGE21','RAYTH22'};
        Tags_med={'OFF','ON'};
        Tags_speed={'S','R'};
        Tags_session = {'M3STIM1','M3STIM2'};
        dir_mat = uigetdir(cd,'Sélectionner le dossier contenant les fichiers sources : *_EMG, *_TrialParams, *_ResAPA'); % Répertoire où sont placés les .mat (*_EMG, *_TrialParams, *_ResAPA)
        dir_results = uigetdir(cd,'Sélectionner le dossier de destination du fichier de résultats'); % pour fichier de résultats
    case 'PSPMARCHE'
        warning('Variable à ajouter pour vérifier correspondances num trials APA et EMG + à sortir et stocker');
        Tags_patients = {'01T01TV01','02T02PT02','03T03TM03','04P01AS04','05P02GF05','06P03MM06','07T04TJ07',...
            '08P04DP08','09P05IM09','10T05BC10','11P06BG11','12P07GH13','13P08TA15','14P09RF16','15P10NL17',...
            '16P12CG18','17T06BM19','18P11DA20','19P13BO21','20T07SM22','21P14LB24','22T08SA25','23T09PL26',...
            '24P15LS27','25P16CM28','26P17RA29','27T10BL30','28P18MF31','29T11BM32'};
        % Patients avec données EMG : [1:12 14:20 22:25 27:29]
        % Num pour CTL : [1:3 7 10 17 20 22 23 27 29]
        % Num pour ANT : [5 6 8 9 12 15 16 18 24] %  21 et 26 EMG Nok
        % Num pour MET : [4 11 14 19 25 28] % 13 EMG Nok
        Tags_med={'NA'};
        Tags_speed={'S','R'};
        Tags_session = {'GAIT'};
        dir_mat = 'D:\09_PSPMARCHE\MAT\'; % Répertoire où sont placés les .mat (*_EMG, *_TrialParams, *_ResAPA)
        dir_results = 'D:\09_PSPMARCHE\Matlab\ResEMG';
        case 'PARKGAME'
            error('TO DO for Protocol PARKGAME')
end

% Def des différents labels utiles
Evts_lbls = {'TR','T0','HO',FootOff,'FC1','FO2','FC2'};
COL_evts = {'k--','r-','k-','b-','m-','g-','c-'};
Ph_lbls = {'APA','Step1','DA','Step2'};
% Def des limites des phases (correspondance phase et numéro d'évènement)
Evts_bound =[2 4;4 5;5 6;6 7]; % dépend des phases;

for i_session = 1
    cd([dir_mat '\' Tags_session{i_session}]);
    for i_patient = 1:numel(Tags_patients)
        for i_med = 1
            for i_speed = 1:2
                clearvars -except Protocol dir_mat dir_results Tags_patients Tags_med Tags_speed Tags_session Evts_bound i_patient i_session i_med i_speed Result_All
                file = [Protocol '_' Tags_session{i_session} '_' Tags_patients{i_patient} '_' Tags_med{i_med} '_' Tags_speed{i_speed}];
                
                eval(['load ' file '_EMG;']);
                eval(['load ' file '_TrialParams;']);
                eval(['load ' file '_ResAPA;']);
                
                eval(['curr_EMG = ' file '_EMG;']);
                eval(['curr_APA = ' file '_TrialParams;']);
                eval(['curr_APA_Foot = ' file '_ResAPA;']);
                
                Fs = curr_EMG.Trial(1).RAW.Fech;
                
                % Check des essais correspondants entre _EMG et _TrialParams
                Tr_EMG = [];
                for i_trialtemp=1:size(curr_EMG.Trial,2)
                    Tr_EMG = [Tr_EMG, curr_EMG.Trial(i_trialtemp).RAW.TrialNum];
                end
                Tr_APA = [curr_APA.Trial(:).TrialNum];
                switch numel(Tr_EMG) == numel(Tr_APA) % on s'assure qu'on a bien le mm nb d'essais
                    case 1
                        switch nnz(Tr_EMG == Tr_APA) == numel(Tr_APA) % on s'assure que les num d'essais concordent
                            case 0
                                error('Num d''essais non concordants entre APA et EMG');
                        end
                    case 0
                        % on supprime les essais EMG pour lesquels pas de trials APA % pour l'instant, vérifier que pour
                        % certains cas (ceux écrits) sinon à vérifier manuellement
                        if numel(Tr_EMG) < numel(Tr_APA)
                            [verif_trials,idx_trials_to_delete] = setdiff(Tr_APA,Tr_EMG);
                            curr_APA.Trial(idx_trials_to_delete) = [];
                            Tr_APA = Tr_EMG;
                        elseif numel(Tr_EMG) > numel(Tr_APA)
                            [verif_trials,idx_trials_to_delete] = setdiff(Tr_EMG,Tr_APA);
                            curr_EMG.Trial(idx_trials_to_delete) = [];
                            Tr_EMG_temp = [];
                            for i_trialtemp=1:size(curr_EMG.Trial,2)
                                Tr_EMG_temp = [Tr_EMG_temp, curr_EMG.Trial(i_trialtemp).RAW.TrialNum];
                            end
                            clear Tr_EMG, Tr_EMG = Tr_EMG_temp;
                        end
                        
%                         if (strcmp(file,'GBMOV_PREOP_CLANI11_ON_S') == 1 || strcmp(file,'GBMOV_PREOP_CLANI11_ON_R') == 1 || strcmp(file,'GBMOV_PREOP_RECGE02_OFF_S') == 1 || strcmp(file,'GBMOV_PREOP_RECGE02_OFF_R') == 1 ...
%                                 || strcmp(file,'GBMOV_PREOP_CJ24_OFF_R') == 1) || strcmp(file,'GBMOV_M3STIM1_LECCL16_OFF_S')
%                         else
%                             if nnz(verif_trials ~= idx_trials_to_delete')
%                                 disp('vérifier indice/trials');
%                                 pause,
%                             end
%                         end
                        
                end
                
                switch strcmp([curr_EMG.Trial(1).RAW.Tag{:}],'RTARSOLLTALSOL')
                    case 0
                        error('Ordre des tags EMG ne correspond pas à RTA/RSOL/LTA/SOL');
                end
                
                EMG_lbls = {'SOLSwing','TASwing','SOLStance','TAStance'};
                
                for i_trial = 1:numel(Tr_APA)
                    % on vérifie que le num APA correspond au num EMG
                    switch Tr_APA(i_trial) == Tr_EMG(i_trial)
                        case 0
                            error('Num EMG différent Num Trial APA');
                    end
                    
                    clear timing_evts_frame
                    timing_evts_frame = floor(Fs*curr_APA.Trial(i_trial).EventsTime); % pour travailler en frames et non en s
                    
                    % on calcule les EMG filtré/rectifié sur l'ensemble des voies et tout l'enregistrement
                    clear temp_filt temp_lowpass temp_ok
                    temp_filt = curr_EMG.Trial(i_trial).RAW.BandPassFilter(30,300,6);
                    temp_filt.Data = abs(temp_filt.Data);
                    temp_lowpass = temp_filt.LowPassFilter(50,2);
                    
                    temp_ok = temp_lowpass.Data.*curr_EMG.Trial(i_trial).Activite.Data;
                    
                    for i_EMG = 1:4 % correspond à SOLswing TAswing SOLstance TAstance
                        switch curr_APA_Foot.Trial(i_trial).Cote % curr_APA.Trial(i_trial).StartingFoot
                            case 'Left'
                                EMGorder = [4 3 2 1];
                            case 'Right'
                                EMGorder = [2 1 4 3];
                        end
                        i_EMGtemp = EMGorder(i_EMG); % correspond aux EMG enregistrés "réels" : RTA RSOL LTA LSOL
                        for i_ph = 1:4 % 1:T0->TO 2:TO->FC1
                             clear phase_frames temp_start temp_stop temp_rms
                            %
                            % on définit le début et la fin de chaque phase en variable pour alléger le code ensuite
                            phase_frames = timing_evts_frame(Evts_bound(i_ph,1)):timing_evts_frame(Evts_bound(i_ph,2));
                            
                            % on détermine les timings de start & stop pour chaque phase
                            temp_start = phase_frames(1) + find(curr_EMG.Trial(i_trial).Activite.Data(i_EMGtemp,phase_frames),1,'first')-1; % en frames, par rapport au début de l'enregistrement
                            temp_stop  = phase_frames(1) + find(curr_EMG.Trial(i_trial).Activite.Data(i_EMGtemp,phase_frames),1,'last')-1;
                            
                            if isempty(find(curr_EMG.Trial(i_trial).Activite.Data(i_EMGtemp,phase_frames),1,'first'));
                                temp_start = NaN;
                            end
                            if isempty(find(curr_EMG.Trial(i_trial).Activite.Data(i_EMGtemp,phase_frames),1,'last'));
                                temp_stop = NaN;
                            end
                            
                            % on calcul la rms pour la voie et la phase considérée
                            temp_rms = rms(temp_ok(i_EMGtemp,phase_frames));
                         
                            % on stocke les infos dans session_curr
%                             warning('Result_All non calculé : En commentaires');
                            Result_All(i_patient,i_session,i_speed).Trial(i_trial).ExploitVar.T.Abs.Start(i_EMG,i_ph) = temp_start-phase_frames(1);
                            Result_All(i_patient,i_session,i_speed).Trial(i_trial).ExploitVar.T.Abs.Stop(i_EMG,i_ph)  =  temp_stop-phase_frames(1);
                             
                            Result_All(i_patient,i_session,i_speed).Trial(i_trial).ExploitVar.T.Rel.Start(i_EMG,i_ph) = 100 * (temp_start-phase_frames(1))/(phase_frames(end)-phase_frames(1));
                            Result_All(i_patient,i_session,i_speed).Trial(i_trial).ExploitVar.T.Rel.Stop(i_EMG,i_ph) = 100 * (temp_stop-phase_frames(1))/(phase_frames(end)-phase_frames(1));
                            
                            Result_All(i_patient,i_session,i_speed).Trial(i_trial).ExploitVar.RMS(i_EMG,i_ph) = temp_rms;
                            Result_All(i_patient,i_session,i_speed).Trial(i_trial).TrialNum = Tr_EMG(i_trial);
                        end
%                         on trace les signaux pour vérif
%                                                 threshold = max(temp_ok(i_EMGtemp,:));
%                                                 figure(2), hold on,
%                                                     subplot(4,1,i_EMG), hold on,
%                                                     plot(curr_EMG.Trial(i_trial).RAW.Time,temp_ok(i_EMGtemp,:));
%                                                     plot(curr_EMG.Trial(i_trial).RAW.Time,curr_EMG.Trial(i_trial).Activite.Data(i_EMGtemp,:).*threshold);
%                                                     plot([curr_APA.Trial(i_trial).EventsTime(2)  curr_APA.Trial(i_trial).EventsTime(2)],[0 threshold],'r--'); % T0
%                                                     plot([curr_APA.Trial(i_trial).EventsTime(4)  curr_APA.Trial(i_trial).EventsTime(4)],[0 threshold],'r--'); % TO
%                                                     plot([curr_APA.Trial(i_trial).EventsTime(5)  curr_APA.Trial(i_trial).EventsTime(5)],[0 threshold],'r--'); % HO
%                                                     axis([0 curr_APA.Trial(i_trial).EventsTime(6) -Inf Inf]);
%                                                 title(['Patient ' num2str(i_patient) ' ' Tags_med{i_med} ' ' Tags_speed{i_speed} ' Trial ' num2str(i_trial)]);
                        % on trace les signaux en % relatif de phase
%                                                   threshold = max(temp_ok(i_EMGtemp,:));
%                                                 figure(2), hold on,
%                                                     subplot(4,2,i_EMG*2-1), hold on,
%                                                     plot(0:100/(timing_evts_frame(4)-timing_evts_frame(2)):100,temp_ok(i_EMGtemp,timing_evts_frame(2):timing_evts_frame(4)),'k');
%                                                     plot(0:100/(timing_evts_frame(4)-timing_evts_frame(2)):100,curr_EMG.Trial(i_trial).Activite.Data(i_EMGtemp,timing_evts_frame(2):timing_evts_frame(4)).*threshold,'k');
%                                                     xlabel('APA'), ylabel(EMG_lbls{i_EMG});
%                                                     subplot(4,2,i_EMG*2), hold on,
%                                                     plot(0:100/(timing_evts_frame(5)-timing_evts_frame(4)):100,temp_ok(i_EMGtemp,timing_evts_frame(4):timing_evts_frame(5)),'k');
%                                                     plot(0:100/(timing_evts_frame(5)-timing_evts_frame(4)):100,curr_EMG.Trial(i_trial).Activite.Data(i_EMGtemp,timing_evts_frame(4):timing_evts_frame(5)).*threshold,'k');
%                                                     xlabel('EXE'),
%                                on sélectionne un seul EMG
%                                                 figure(11), hold on,
%                                                 if i_EMG == 4
%                                                     subplot(1,2,1), hold on,
%                                                     plot(0:100/(timing_evts_frame(4)-timing_evts_frame(2)):100,temp_ok(i_EMGtemp,timing_evts_frame(2):timing_evts_frame(4)),'b');
% %                                                     plot(0:100/(timing_evts_frame(4)-timing_evts_frame(2)):100,curr_EMG.Trial(i_trial).Activite.Data(i_EMGtemp,timing_evts_frame(2):timing_evts_frame(4)).*threshold,'b');
%                                                     xlabel('APA'), ylabel(EMG_lbls{i_EMG});
%                                                     subplot(1,2,2), hold on,
%                                                     plot(0:100/(timing_evts_frame(5)-timing_evts_frame(4)):100,temp_ok(i_EMGtemp,timing_evts_frame(4):timing_evts_frame(5)),'b');
% %                                                     plot(0:100/(timing_evts_frame(5)-timing_evts_frame(4)):100,curr_EMG.Trial(i_trial).Activite.Data(i_EMGtemp,timing_evts_frame(4):timing_evts_frame(5)).*threshold,'b');
%                                                     xlabel('EXE'),
%                                                 end
                    end
                    %                    mtit([Tags_patients{i_patient} ' ' Tags_med{i_med} ' ' Tags_speed{i_speed}]);
                    %                 close;
                end
            end
        end
        disp([Tags_patients{i_patient} ' Process OK']);
    end
end
cd(dir_results);
save Result_All Result_All;
% warning('Resultats non sauvegardés');


%% Création du dataset
outputCSV = char(inputdlg('Quel nom pour le csv de résultats ?','Enrgmt CSV'));
varLbls = {'Subject','Session','MedCondition','SpeedCondition','Trial',...
    'SOLSwingAPAStart','SOLSwingAPADuration','SOLSwingAPARMS',...
    'SOLSwingEXEStart','SOLSwingEXEDuration','SOLSwingEXERMS',...
    'SOLSwingDAStart','SOLSwingDADuration','SOLSwingDARMS',...
    'SOLSwingStep2Start','SOLSwingStep2Duration','SOLSwingStep2RMS',...
    'TASwingAPAStart','TASwingAPADuration','TASwingAPARMS',...
    'TASwingEXEStart','TASwingEXEDuration','TASwingEXERMS',...
    'TASwingDAStart','TASwingDADuration','TASwingDARMS',...
    'TASwingStep2Start','TASwingStep2Duration','TASwingStep2RMS',...
    'SOLStanceAPAStart','SOLStanceAPADuration','SOLStanceAPARMS',...
    'SOLStanceEXEStart','SOLStanceEXEDuration','SOLStanceEXERMS',...
    'SOLStanceDAStart','SOLStanceDADuration','SOLStanceDARMS',...
    'SOLStanceStep2Start','SOLStanceStep2Duration','SOLStanceStep2RMS',...
    'TAStanceAPAStart','TAStanceAPADuration','TAStanceAPARMS',...
    'TAStanceEXEStart','TAStanceEXEDuration','TAStanceEXERMS',...
    'TAStanceDAStart','TAStanceDADuration','TAStanceDARMS',...
    'TAStanceStep2Start','TAStanceStep2Duration','TAStanceStep2RMS'};
mat = NaN(1,53);
DS = dataset;
i_speed = 1;
cnt = 1;
for i_patient = 1:numel(Tags_patients)
    for i_session = 1:2
        for i_trial = 1:numel(Result_All(i_patient,i_session,i_speed).Trial)
            DS(cnt,1) = dataset(Tags_patients(i_patient));
            DS(cnt,2) = dataset(Tags_session(i_session));
            DS(cnt,3) = dataset({'NA'});
            DS(cnt,4) = dataset({'S'});
            switch Result_All(i_patient,i_session,i_speed).Trial(i_trial).TrialNum < 10
                case 1
                    temp_trial = {['0' num2str(Result_All(i_patient,i_session,i_speed).Trial(i_trial).TrialNum)]};
                    DS(cnt,5) = dataset(temp_trial);
                case 0
                    DS(cnt,5) = dataset(num2cell(Result_All(i_patient,i_session,i_speed).Trial(i_trial).TrialNum));
            end
            for i_EMG = 1:4
                for i_ph = 1:4
            DS(cnt,12*i_EMG+3*i_ph-9) = mat2dataset(Result_All(i_patient,i_session,i_speed).Trial(i_trial).ExploitVar.T.Rel.Start(i_EMG,i_ph));
            DS(cnt,12*i_EMG+3*i_ph-8) = mat2dataset(Result_All(i_patient,i_session,i_speed).Trial(i_trial).ExploitVar.T.Rel.Stop(i_EMG,i_ph)-Result_All(i_patient,i_session,i_speed).Trial(i_trial).ExploitVar.T.Rel.Start(i_EMG,i_ph));
            DS(cnt,12*i_EMG+3*i_ph-7) = mat2dataset(Result_All(i_patient,i_session,i_speed).Trial(i_trial).ExploitVar.RMS(i_EMG,i_ph));
                end
            end
            cnt = cnt+1;
        end
    end
end
DS.Properties.VarNames = varLbls;    
cd(dir_results);
export(DS,'File',[outputCSV '.csv'],'Delimiter',';');
