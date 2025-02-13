%% DEMO UNIT MATCH 
% This is a demo using the FigShareData on 10.6084/m9.figshare.24305758

%% READ ME
% UnitMatch contains a script (i.e. ExtractAndSaveAverageWaveform.m) to extract average waveforms from raw SpikeGLX data. 
% If you do not use SpikeGLX, you have multiple options:
% 1. Convert your data to SpikeGLX format (e.g. Use OpenEphys?)
% 2. Use Bombcell frist, the extracted waveforms with the defaults for UnitMatch, raw waveforms will be stored in the KS folder
% 3. Extract the waveforms yourself. 
% Either one of the options above should result in 'KiloSortPaths' containing a subfolder called 'RawWaveforms'. There
% should be a NPY file for every cluster with the dimensions of
% UMparam.spikeWidth X nRecordingChannels X 2 (1 for each half of a
% recording). This should contain the average waveform (recommended of at
% least 500 spikes) for every recording channel for every half of a
% recording for that cluster.

%% User input: 
clear % UMparam should be remade from scratch!
UMparam.SaveDir = '\\znas.cortexlab.net\Lab\Share\UNITMATCHTABLES_ENNY_CELIAN_JULIE\Learning_Striatum_new\JF067\pyKS\Output'; % Recommended to use end this path with \Probe0\IMRO_1\ if more probes/IMRO tables were used or \AllProbes\AllIMRO\ otherwise
UMparam.KSDir = {'\\znas.cortexlab.net\Lab\Share\UNITMATCHTABLES_ENNY_CELIAN_JULIE\Learning_Striatum_new\JF067\pyKS\2022-01-26\pyKS',...
    '\\znas.cortexlab.net\Lab\Share\UNITMATCHTABLES_ENNY_CELIAN_JULIE\Learning_Striatum_new\JF067\pyKS\2022-01-28\pyKS',...
    '\\znas.cortexlab.net\Lab\Share\UNITMATCHTABLES_ENNY_CELIAN_JULIE\Learning_Striatum_new\JF067\pyKS\2022-01-30\pyKS'};  % This is a cell array with a path, in the path there should be a subfolder called 'RawWaveforms'. 
UMparam.tmpdatafolder = 'D:\tmpdata\'
GithubDir = 'C:\Users\EnnyB\Documents\GitHub'; % Github directory

% UMparam.RawDataPaths = {'H:\MatchingUnits\Tmp\AL032_2019-11-21_stripe192-natIm_g0_t0.imec0.ap.bin','H:\MatchingUnits\Tmp\AL032_2019-11-22_stripe192-natIm_g0_t0.imec0.ap.bin'} % OPTIONAL, it can also be read in from params.py file (if dat-path properly points at the raw OpenEphys/SpikeGLX file)
% N.B. if you want to use the functional score evaluation of UnitMatch, 'KSDir' should also contain typical 'Kilosort output', (e.g. spike times etc.)

%% N.B. the following user input can also be automatically extracted and prepared/cleaned up using UMparam = ExtractKilosortData(KiloSortPaths, UMparam) for Kilosorted data of SpikeGLX recorded data (see next section);
% UMparam.RawDataPaths = {'\\path\to\firstrecording','\\path\to\secondrecording','\\path\to\nthrecording'};  % This is a cell array with info on where to find the decompressed recording (.cbin files) --> Necessary when you want UnitMatch to do waveform extraction
% UMparam.AllDecompPaths = {'\\path\to\firstrecording','\\path\to\secondrecording','\\path\to\nthrecording'};  % This is a cell array with info on where to find the decompressed recording (.bin files) --> Necessary when you want UnitMatch to do waveform extraction
% UMparam.AllChannelPos = {[RecordingSites_Recording1],[RecordingSites_Recording2]}; % These are coordinates of every recording channel on the probe (e.g. nRecordingChannels x 2)
% clusinfo = struct; % Note, this can be kilosort input, 
% - clusinfo (this is a struct that contains per unit the following information):
% * cluster_id (e.g. kilosort output clus_id)
% * Good_ID: ones for units that should be included in the analysis
% * RecSesID: Recording Session ID
% * Probe: Which probe (if just 1, ones of numel cluster_id)
% * Depth: depth on probe (optional)
% * Shank: Which shank (optional)
% * Coordinates: Typically 3D Allen Common Coordinate framework coordinates per unit (optional)


% N.B. clusinfo can also be automatically extracted using clusinfo =
% getClusinfo

% Required (for using UnitMatch):
addpath(genpath(fullfile(GithubDir,'spikes')))% Should work with normal spikes toolbox, but I use the forked version in https://github.com/EnnyvanBeest/spikes
addpath(genpath(fullfile(GithubDir,'npy-matlab'))) % https://github.com/kwikteam/npy-matlab
addpath(genpath(fullfile(GithubDir,'mtscomp'))) % https://github.com/int-brain-lab/mtscomp

% Advised (quality metrics for unit selection):
addpath(genpath(fullfile(GithubDir,'bombcell'))) % DOI: 10.5281/zenodo.8172822, https://github.com/Julie-Fabre/bombcell 
% UNITMATCH - Move to top of paths 
addpath(genpath(fullfile(GithubDir,'UnitMatch'))) % Make sure to have this one fresh in the path (so run this last)


%% Add paths and subpaths - this will only work when running script in sequence, otherwise just manually add all UnitMatch subfolders
mfilePath = mfilename('fullpath');
if contains(mfilePath,'LiveEditorEvaluationHelper')
    mfilePath = matlab.desktop.editor.getActiveFilename;
end
Components = strsplit(mfilePath,filesep);
addpath(genpath(fullfile(Components{1:end-1})));

%% Optional (for Kilosort + SpikeGLX users) --- see ExampleAnalysisPipelines for more detail!
UMparam = ExtractKilosortData(UMparam.KSDir, UMparam); % Extract KS data and do some noise removal, optionally decompresses cbin to bin data and uses BOMBCELL quality metric to define good single units
clusinfo = getClusinfo(UMparam.KSDir); % prepare clusinfo struct

%% Load default parameters
UMparam = DefaultParametersUnitMatch(UMparam);

%% UnitMatch algorithm:
[UniqueIDConversion, MatchTable, WaveformInfo, UMparam] = UnitMatch(clusinfo, UMparam);
if UMparam.AssignUniqueID
   [UniqueIDConversion, MatchTable] = AssignUniqueID(UMparam.SaveDir);
end

%%% N.B. From here it is all evaluation, you don't need this to use UnitMatch
%%% results in your further analysis
%% Visualization
PlotUnitsOnProbe(clusinfo,UMparam,UniqueIDConversion,WaveformInfo)

%% Automatic evaluation:
EvaluatingUnitMatch(UMparam.SaveDir); % Within session cross-validation
ComputeFunctionalScores(UMparam.SaveDir,1) % Only works when having access to Kilosort output (e.g. spike times etc.) 

%% Curation:
if UMparam.MakePlotsOfPairs
    DrawPairsUnitMatch(UMparam.SaveDir);
    if UMparam.GUI
        FigureFlick(UMparam.SaveDir)
        pause
    end
end

%% Further evaluation - only works in combination with Bombcell
QualityMetricsROCs(UMparam.SaveDir); % Only works in combination with BOMBCELL (and is added to path!!)
