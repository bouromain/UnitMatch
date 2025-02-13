% 
% SaveDir = '\\znas.cortexlab.net\Lab\Share\UNITMATCHTABLES_ENNY_CELIAN_JULIE\FullAnimal_KSChanMap'; %H:\Ongoing\'%'H:\SfN_2022'; %%'E:\Data\ResultsOngoing' %
SaveDir = '\\znas.cortexlab.net\Lab\Share\UNITMATCHTABLES_ENNY_CELIAN_JULIE\FullAnimal_new'; %H:\Ongoing\'%'H:\SfN_2022'; %%'E:\Data\ResultsOngoing' %

FromDate = datetime("2024-03-08 09:00:00");
AssignUnitDate = datetime("2024-03-14 10:00:00");

UMFiles = cell(1,0); % Define your UMfolders here or use below:
groupvec = nan(1,0);
if ~exist('UMFiles') || isempty(UMFiles) % When using the example pipeline this may be useful:
    MiceOpt = dir(SaveDir);
    MiceOpt = arrayfun(@(X) X.name,MiceOpt,'Uni',0);
    MiceOpt(ismember(MiceOpt,{'.','..'})) = [];

    for midx = 1:numel(MiceOpt)
        fprintf('Reference %s...\n', MiceOpt{midx})
        % Identify all UM tables
        tmpfile = dir(fullfile(SaveDir, MiceOpt{midx},'*','*','UnitMatch', 'UnitMatch.mat'));
        if isempty(tmpfile)
            continue
        end
        for id = 1:length(tmpfile)
            if datetime(tmpfile(id).date) > FromDate % && any(cell2mat(cellfun(@(X) any(strfind(fullfile(tmpfile(id).folder,tmpfile(id).name),X)),UMFiles2Take,'Uni',0)))
                
                if datetime(tmpfile(id).date) < AssignUnitDate
                AssignUniqueID(fullfile(tmpfile(id).folder)) % REDO
                end
                % Check that these data are not too noisy
              

                %             FolderParts = strsplit(tmpfile(id).folder,filesep);
                %             idx = find(ismember(FolderParts,MiceOpt{midx}));
                UMFiles = cat(2,UMFiles,fullfile(tmpfile(id).folder,tmpfile(id).name));
                groupvec = cat(2,groupvec,midx);
            else
                keyboard
            end


        end
    end
    close all
end
% Info  = DataSetInfo(UMFiles)
% Info.RecSes
% nanmean(cat(1,Info.nGoodUnits{:})./cat(1,Info.nTotalUnits{:}).*100)
% nanstd(cat(1,Info.nGoodUnits{:})./cat(1,Info.nTotalUnits{:}).*100)
% 
% summaryMatchingPlots(UMFiles,{'UID1Liberal','UID1','UID1Conservative'},groupvec,1)
% summaryFunctionalPlots(UMFiles, 'Corr', groupvec)
% 
% %
% summaryFunctionalPlots_Part2(UMFiles, groupvec, 0)

%% Redo
if 1
    for midx = 1:length(UMFiles)

        load(UMFiles{midx})
        UMparam.SaveDir = strrep(UMparam.SaveDir,'\\znas.cortexlab.net\Lab\Share\UNITMATCHTABLES_ENNY_CELIAN_JULIE\FullAnimal_new','\\znas.cortexlab.net\Lab\Share\UNITMATCHTABLES_ENNY_CELIAN_JULIE\FullAnimal_KSChanMap')
        clusinfo = getClusinfo(UMparam.KSDir);

        for ksid = 1:numel(UMparam.KSDir)
            myClusFile = dir(fullfile(UMparam.KSDir{ksid}, 'channel_map.npy'));
            channelmaptmp = readNPY(fullfile(myClusFile(1).folder, myClusFile(1).name));

            myClusFile = dir(fullfile(UMparam.KSDir{ksid}, 'channel_positions.npy'));
            channelpostmp = readNPY(fullfile(myClusFile(1).folder, myClusFile(1).name));

            UMparam.AllChannelPos{ksid} = channelpostmp;
            if size(channelpostmp,1)~=384
                keyboard
            end
        end

        % Actual UnitMatch & Unique UnitID assignment
        [UniqueIDConversion, MatchTable, WaveformInfo, UMparam] = UnitMatch(clusinfo, UMparam);
        if UMparam.AssignUniqueID
            [UniqueIDConversion, MatchTable] = AssignUniqueID(UMparam.SaveDir);
        end

        % Evaluate (within unit ID cross-validation)
        EvaluatingUnitMatch(UMparam.SaveDir);

        % Function analysis
        ComputeFunctionalScores(UMparam.SaveDir,1)
        % Visualization
        PlotUnitsOnProbe(clusinfo,UMparam,UniqueIDConversion,WaveformInfo)

    end



end