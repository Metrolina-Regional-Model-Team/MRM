Macro "Open Delete Files Tool Dbox" (Args)
	RunDbox("Delete Files Tool", Args)
endmacro

dBox "Delete Files Tool" (Args) center, center, 90, 17 Title: "Delete Files Tool" Help: "test" toolbox

    close do
        return()
    enditem

    init do
        static action_list, action_index

        action_list = {"Lite", "Medium"}

        EnableItem("Model Output Profile")
    enditem

    // Select files to be deleted
    Popdown Menu "Model Output Profile" 2, 2, 24, 8 Prompt: "Model Output Profile" 
        List: action_list Variable: action_index do
        if action_index = 1 then typehelp = "Only Network, SE data, TAZ, and summaries will be retained."
		else typehelp = "In addition to Network, SE data, TAZ, and summaries, other files necessary for running tools will also be retained."
    enditem 


    Button 6, 4 Prompt: "Delete Files" do
        RunMacro("Delete Folder and Files", Args, action_index)
        ShowMessage("A slim verison of output folder has been created.")
	return(1)
    enditem

    Radio List "Help" 28,.75,43,12 Prompt: "Help"

	// Help text boxes
	Text" " 30.5,2,40,10 Variable:typehelp

    Button 30, 15.5, 12 Prompt: "Quit" do
        Return()
    enditem

    Button 9,15.5,12 Prompt: "Help" do
        ShowMessage(
        "This tool is used to create a slim version of output folder by deleting unnecessary files. You can choose to" +
         "either deleting probability and logsum matrices only or everything except network, SE, TAZ, and summary folder" +
         "Doing such helps reduce scenario folder size by 40-80 GB. Note that after running this tool, other utility" +
         "tools may no longer work. Please run desired utility tools first and then delete unnecessary files.\n\n"
     )
    enditem
enddbox

Macro "Delete Folder and Files" (Args, action_index)
    scen_dir = Args.[Scenario Folder]
    dir_deletelist = null
    
    if action_index = 1 then do
        //set path
        resident_mode_dir = scen_dir + "\\output\\resident\\mode"
        resident_mode_logsum_dir = resident_mode_dir + "\\logsums"
        resident_mode_prob_dir = resident_mode_dir + "\\probabilities"

        resident_dc_dir = scen_dir + "\\output\\resident\\dc"
        resident_dc_logsum_dir = resident_dc_dir + "\\logsums"
        resident_dc_prob_dir = resident_dc_dir + "\\probabilities"

        univ_mode_dir = scen_dir + "\\output\\university\\mode"
        univ_mode_logsum_dir = univ_mode_dir + "\\logsums"
        univ_mode_prob_dir = univ_mode_dir + "\\probabilities"

        nhb_dc_prob_dir = scen_dir + "\\output\\resident\\nhb\\dc\\probabilities"
        
        // {folder, {files to keep in that folder}}
        dir_deletelist = {
            {resident_mode_logsum_dir, {"file1.mtx", "file2.mtx"}},
            {resident_mode_prob_dir,   {"file3.mtx"}},
            {resident_dc_logsum_dir,   {}},
            {resident_dc_prob_dir,     {}},
            {univ_mode_logsum_dir,     {}},
            {univ_mode_prob_dir,       {}},
            {nhb_dc_prob_dir,          {"file4.bin", "file4.dcb"}}
        }
    end
    else do
        //set path
        folder_a = scen_dir + "\\output\\folderA"
        folder_b = scen_dir + "\\output\\folderB"
        folder_c = scen_dir + "\\output\\folderC"

        // {folder, {files to keep in that folder}}
        dir_deletelist = {
            {folder_a, {"file5.mtx"}},
            {folder_b, {"file6.csv", "file7.csv"}},
            {folder_c, {}}
        }
    end

    // Delete files
    for item in dir_deletelist do
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

            // delete all subfolders
            sub_folders = GetDirectoryInfo(dir_delete + "\\*.*", "Folder")
            if sub_folders <> null then do
                for sub_folder in sub_folders do
                    sub_folder_path = dir_delete + "\\" + sub_folder[1] + "\\"
                    dir = CreateObject("CC.Directory", sub_folder_path)
                    dir.Delete()
                end
            end

            // remove the folder only if nothing was kept in it
            if GetDirectoryInfo(dir_delete + "\\*", "All") = null then RemoveDirectory(dir_delete)
        end
    end

endmacro


Macro "Delete Files" (dir)
    files = GetDirectoryInfo(dir + "/*", "File")
        
    for i = 1 to files.length do
        file = files[i][1]
        filepath = dir + "/" + file
        DeleteFile(filepath)
    end
    if GetDirectoryInfo(dir + "\\*.*", "Folder") = null then RemoveDirectory(dir)
endmacro