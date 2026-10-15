Macro "Open Delete Files Tool Dbox" (Args)
	RunDbox("Delete Files Tool", Args)
endmacro

dBox "Delete Files Tool" (Args) center, center, 92, 17 Title: "Delete Files Tool" Help: "test" toolbox

    close do
        return()
    enditem

    init do
        static action_list, action_index

        action_list = {"Lite", "Medium"}

        EnableItem("Model Output Profile")
        METDir = Args.[MET Directory]
    enditem

    Edit Text 1, 1, 15 Prompt: "Choose Scenario Folder" Variable: scen_dir
    Button after, same, 8, 1 Prompt: "Browse"
    Help: "Browse and select the reference scenario folder." do
        on error, escape goto skip1
        scen_dir = ChooseDirectory("Choose Full Scenario Folder", {"Initial Directory": METDir})
        skip1:
        on error default
    enditem

    // Select files to be deleted
    Popdown Menu "Model Output Profile" 1, 3, 15 Prompt: "Model Output Profile" 
        List: action_list Variable: action_index do
        if action_index = 1 then typehelp = "Only Network, SE data, TAZ, and summaries will be retained."
		else typehelp = "In addition to Network, SE data, TAZ, trip generation, summaries and other files necessary for running tools will also be retained."
    enditem 


    Button After, Same, 12, 1 Prompt: "Delete Files" do
        RunMacro("Delete Folder and Files", scen_dir, action_index)
        ShowMessage("A slim verison of Model output has been created.")
	return(1)
    enditem

    Radio List "Help" 30,.75,43,12 Prompt: "Help"

	// Help text boxes
	Text" " 30.5,2,40,10 Variable:typehelp

    Button 30, 15.5, 12 Prompt: "Quit" do
        Return()
    enditem

    Button 9,15.5,12 Prompt: "Help" do
        ShowMessage(
        "This tool creates two slimmed-down versions of the model output folder by removing unnecessary files." +
         "Doing such helps reduce scenario folder size by approximately 60-65 GB.\n\n"
     )
    enditem
enddbox

Macro "Delete Folder and Files" (scen_dir, action_index)
    //scen_dir = Args.scen_dir
    dir_list = null
    
    if action_index = 1 then do
        //set path
        AutoSkims_dir = scen_dir + "\\AutoSkims"
        HwyAssnHOT_dir = scen_dir + "\\HwyAssn\\HOT"
        Report_dir = scen_dir + "\\Report"

        //Output_dir = scen_dir + "\\Report\\Output"
        Skims_dir = scen_dir + "\\Skims"
        TD_dir = scen_dir + "\\TD"

        TG_dir = scen_dir + "\\TG" //TG folder will be deleted for Lite version, but retained for Medium version
        TOD2_dir = scen_dir + "\\TOD2"
        TourModeSplit_dir = scen_dir + "\\TourModeSplit"

        TranAssn_dir = scen_dir + "\\TranAssn"
        TripTables_dir = scen_dir + "\\TripTables"

        
        // {folder, {sub-folders and files to keep in that folder}}
        dir_list = {
            { AutoSkims_dir, {"SPMAT_auto.mtx", "SPMAT_free.mtx"}},
            {HwyAssnHOT_dir,   {"Assn_AMPEAKhot.bin", "Assn_AMPEAKhot.dcb", "Assn_Middayhot.bin", "Assn_Middayhot.dcb", "Assn_PMPEAKhot.bin", "Assn_PMPEAKhot.dcb", "Assn_Nighthot.bin", "Assn_Nighthot.dcb", "Tot_Assn_HOT.bin", "Tot_Assn_HOT.dcb"}},
            {Report_dir,   {"maps", "Output", "validation", "AttractionsByCo.csv", "AvgTripLength.csv", "DC_output.csv", "MS_Statistics.csv", "OD_Statistics.csv", "ODtime_distr.csv", "ProductionsByCo.csv", "runstats_dwnldCOATFUN.csv", 
                            "runstats_dwnldVOL.csv", "RunStats_HwyAssn.csv", "runstats_VMTAQ.csv", "runstats_VMTCnty.csv", "ScreenLineSummary.csv", "StopsByCo_AP.csv", "StopsByCo_PA.csv", "StopsDistr.csv", "TF_NUM.csv", "TF_NumByCounty.csv", 
                            "TOD1_output.csv", "Transit_RunStats.csv", "VolGroupStats.csv"}},
            //{Output_dir,     {}},
            {Skims_dir,     {"TThwy_Free.mtx", "TThwy_Peak.mtx", "TTTran_Free.mtx", "TTTran_Peak.mtx"}},
            {TD_dir,       {}},
            {TG_dir,       {}},
            {TOD2_dir,          {"ODHwyVeh_AMPeak.mtx", "ODHwyVeh_AMPeakhot.mtx", "ODHwyVeh_Midday.mtx", "ODHwyVeh_Middayhot.mtx", "ODHwyVeh_PMPeak.mtx", "ODHwyVeh_PMPeakhot.mtx", "ODHwyVeh_Night.mtx", "ODHwyVeh_Nighthot.mtx"}},
            {TourModeSplit_dir, {}},
            {TranAssn_dir,      {"Transit Assign Drive.MTX", "Transit Assign DropOff.MTX", "Transit Assign Walk.MTX"}},
            {TripTables_dir,    {}}
        }
    end
    else do
        //set path
        AutoSkims_dir = scen_dir + "\\AutoSkims"
        HwyAssnHOT_dir = scen_dir + "\\HwyAssn\\HOT"
        Report_dir = scen_dir + "\\Report"

        //Output_dir = scen_dir + "\\Report\\Output"
        Skims_dir = scen_dir + "\\Skims"
        TD_dir = scen_dir + "\\TD"

        //TG_dir = scen_dir + "\\TG" //TG folder will be deleted for Lite version, but retained for Medium version
        TOD2_dir = scen_dir + "\\TOD2"
        TourModeSplit_dir = scen_dir + "\\TourModeSplit"

        TranAssn_dir = scen_dir + "\\TranAssn"
        TripTables_dir = scen_dir + "\\TripTables"

        // {folder, {sub-folders and files to keep in that folder}}
        dir_list = {
            {AutoSkims_dir, {"SPMAT_auto.mtx", "SPMAT_free.mtx"}},
            {HwyAssnHOT_dir,   {"Assn_AMPEAKhot.bin", "Assn_AMPEAKhot.dcb", "Assn_Middayhot.bin", "Assn_Middayhot.dcb", "Assn_PMPEAKhot.bin", "Assn_PMPEAKhot.dcb", "Assn_Nighthot.bin", "Assn_Nighthot.dcb", "Tot_Assn_HOT.bin", "Tot_Assn_HOT.dcb"}},
            {Report_dir,   {"maps", "Output", "validation", "AttractionsByCo.csv", "AvgTripLength.csv", "DC_output.csv", "MS_Statistics.csv", "OD_Statistics.csv", "ODtime_distr.csv", "ProductionsByCo.csv", "runstats_dwnldCOATFUN.csv", 
                            "runstats_dwnldVOL.csv", "RunStats_HwyAssn.csv", "runstats_VMTAQ.csv", "runstats_VMTCnty.csv", "ScreenLineSummary.csv", "StopsByCo_AP.csv", "StopsByCo_PA.csv", "StopsDistr.csv", "TF_NUM.csv", "TF_NumByCounty.csv", 
                            "TOD1_output.csv", "Transit_RunStats.csv", "VolGroupStats.csv"}},
            //{Output_dir,     {}},
            {Skims_dir,     {"TThwy_Free.mtx", "TThwy_Peak.mtx", "TTTran_Free.mtx", "TTTran_Peak.mtx"}},
            {TD_dir,       {}},
            //{TG_dir,       {}},
            {TOD2_dir,          {"ODHwyVeh_AMPeak.mtx", "ODHwyVeh_AMPeakhot.mtx", "ODHwyVeh_Midday.mtx", "ODHwyVeh_Middayhot.mtx", "ODHwyVeh_PMPeak.mtx", "ODHwyVeh_PMPeakhot.mtx", "ODHwyVeh_Night.mtx", "ODHwyVeh_Nighthot.mtx"}},
            {TourModeSplit_dir, {}},
            {TranAssn_dir,      {"Transit Assign Drive.MTX", "Transit Assign DropOff.MTX", "Transit Assign Walk.MTX"}},
            {TripTables_dir,    {}}
        }
    end

    // Delete files
    for item in dir_list do
        dir_delete = item[1]
        keep_list = item[2]

        // skip folders that don't exist
        if GetDirectoryInfo(dir_delete, "Folder") <> null then do

            // delete every file except those in keep_list
            files = GetDirectoryInfo(dir_delete + "\\*", "File")
            for file in files do
                fname = file[1]
                keep = 0
                for k in keep_list do
                    if Lower(k) = Lower(fname) then keep = 1
                end
                if keep = 0 then DeleteFile(dir_delete + "\\" + fname)
            end

            // delete all subfolders except those in keep_list
            sub_folders = GetDirectoryInfo(dir_delete + "\\*.*", "Folder")
            if sub_folders <> null then do
                for sub_folder in sub_folders do
                    sname = sub_folder[1]
                    keep = 0
                    for k in keep_list do
                        if Lower(k) = Lower(sname) then keep = 1
                    end
                    if keep = 0 then do
                        sub_folder_path = dir_delete + "\\" + sname + "\\"
                        dir = CreateObject("CC.Directory", sub_folder_path)
                        dir.Delete()
                    end
                end
            end

            // remove the folder only if nothing was kept in it
            if GetDirectoryInfo(dir_delete + "\\*", "All") = null then RemoveDirectory(dir_delete)
        end
    end

endmacro