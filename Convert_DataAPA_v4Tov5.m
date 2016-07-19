% Script qui permet de convertir les données APA calculées à partir de
% Test_APA_v4 pour être lisible avec Calc_APA_v5

% Modifie le nom des champs dans la structure *ResAPA.Trial

% Se placer dans le dossier des données sources
% cd('D:\09_PSP_MARCHE\MAT\APA_nomenclature_ex');
cd('M:\nomenclature_ok\PARKGAME_S4_MORGE03');

file_to_load = 'PARKGAME_S4_MORGE03_NA_R_ResAPA';

% chargement du fichier
eval(['load ' file_to_load ';']);
eval(['curr_APA = ' file_to_load ';']);

% renommage des champs
f = fields(curr_APA.Trial);
v = struct2cell(curr_APA.Trial);

switch file_to_load(1:min(strfind(file_to_load,'_'))-1) % Protocol Name
    case 'PSPMARCHE'
        curr_APA.Trial = rmfield(curr_APA.Trial, 't_1step'); % suppression de t_1step
        f{strmatch('APAy',f,'exact')} = 'APA_antpost';
        f{strmatch('APAy_lateral',f,'exact')} = 'APA_lateral';
        f{strmatch('t_execution ',f,'exact')} = 't_swing1';
        f{strmatch('V_exec',f,'exact')} = 'V_swing1';
    case 'PARKGAME' % ok pour MORGE03 au minimum
        f{strmatch('t_step1 ',f,'exact')} = 't_swing1';
        f{strmatch('t_step2 ',f,'exact')} = 't_swing2';
        f{strmatch('V_step1',f,'exact')} = 'V_swing1';
end

curr_APA = rmfield(curr_APA, 'Trial');
curr_APA.Trial = cell2struct(v,f);
clear f v;

% réaffection de la variable
eval(['clear ' file_to_load ';']);
eval([file_to_load '= curr_APA;']);

% enregistrement de *_ResAPA
% Se placer dans le dossier de destination
% cd('D:\09_PSP_MARCHE\MAT\APA');
eval(['save ' file_to_load ' ' file_to_load ';']);


