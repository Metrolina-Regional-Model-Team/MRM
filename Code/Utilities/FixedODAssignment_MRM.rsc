/*
The purpose of this tool to is allow supply side changes to be evaluated
quickly without affecting the demand (OD matrix).
*/
Macro "Open Fixed OD Dbox" (Args)
	RunDbox("FixedOD", Args)
endmacro
dBox "FixedOD" (Args) center, center, 50, 8 Title: "Fixed OD Assignment" Help: "test" toolbox

  init do
    //ShowMessage("Run Directory = " + Args.[Run Directory]) //added for testing
    //ShowMessage("MRM Directory = " + Args.[MRM Directory]) //added for testing
    //ShowMessage("MasterHwyFile = " + Args.MasterHwyFile) //added for testing
    static ref_scen_dir, curr_scen
    //Args.[MET Directory] = { "Type":"Folder" , "Value":"%Base Folder%\\Metrolina", "Description":"Directory that holds all scenario folders" }
    METDir = Args.[MET Directory]
    curr_scen = Args.[Run Year]
  enditem

  close do
    return()
  enditem

  Edit Text 16.5, 1, 20 Prompt: "Reference Scenario:" Variable: ref_scen_dir
  Button after, same, 8, 1 Prompt: "Browse"
  Help: "Browse and select the reference scenario folder." do
    on error, escape goto skip1
    ref_scen_dir = ChooseDirectory("Choose Full Scenario Folder", {"Initial Directory": METDir})
    skip1:
    on error default
  enditem

  //This line shows the text "(current scenario)"
  //Text 15, after, 15 Prompt: "New Scenario:" Variable: "(current scenario)"
  
  //This line shows current scenario name that is selected in the TC
  Text 15, 3, 15 Prompt: "Analysis Scenario:" Variable: curr_scen
  
  /*Edit Text same, after, 15 Prompt: "Select Link Query:" Variable: sl_query
  Button after, same, 5, 1 Prompt: "..." do
    on error, escape goto skip2
    sl_query = ChooseFile({{"Query (*.qry)", "*.qry"}}, "Choose Select Link Query", {"Initial Directory": METDir})
    skip2:
    on error default
  enditem
  Text after, same, 10 Variable: "(optional)"*/

  Button 12, 5 Prompt: "Run" do
    mr = CreateObject("Model.Runtime")
    Args = mr.GetValues()
    //ShowMessage("After GetValues:") //added for testing
    //ShowMessage("Run Directory = " + Args.[Run Directory]) //added for testing
    //ShowMessage("MasterHwyFile = " + Args.MasterHwyFile) //added for testing
    /*if ref_scen_dir = Args.[Run Directory] then do
        Throw("The full scenario and current scenario cannot be the same")
        return()
    end*/
    opts.ref_scen_dir = ref_scen_dir
    /*opts.sl_query = sl_query*/
    RunMacro("Fixed OD Assignment", opts)
    ShowMessage("Fixed OD Assignment Complete")
  enditem
  Button 20, same Prompt: "Quit" do
    Return()
  enditem
  Button 28, same Prompt: "Help" do
    ShowMessage(
      "This tool lets you evaluate an alternative roadway network by " +
      "borrowing demand info from a fully-converged scenario."
    )
  enditem
enddbox

/*

*/

Macro "Fixed OD Assignment" (MacroOpts)

    ref_scen_dir = MacroOpts.ref_scen_dir
    /*sl_query = MacroOpts.sl_query*/

    mr = CreateObject("Model.Runtime")
    Args = mr.GetValues()
    if ref_scen_dir != Args.[Run Directory] then do
    RunMacro("Copy Files for Fixed OD", Args, ref_scen_dir)
    end
    //ShowMessage("Fixed OD Run Dir = " + Args.[Run Directory]) //added for testing
    //ShowMessage("Fixed OD MRM Dir = " + Args.[MRM Directory]) //added for testing
    //ShowMessage("Fixed OD masterhwyfile = " + Args.MasterHwyFile) //added for testing
    //Args.[Log File] = "C:\\MRM\\Output\\2025\\tdm-TransCAD-Log.xml"
    //Args.[Report File] = "C:\\MRM\\Output\\2025\\Output\\2025\\tdm-Run-Report.xml"
    ret = mr.RunStep("Initial Processing", {Silent: "true"})
    //ret = RunMacro("Initial Processing", Args, {Silent: "true"})
    if !ret then Throw("Fixed OD: 'Initial Processing' failed")
    /*ret = mr.RunStep("Network Calculators", {Silent: "true"})
    if !ret then Throw("Fixed OD: 'Network Calculators' failed")*/
    ret = mr.RunStep("HOT", {Silent: "true"})
    if !ret then Throw("Fixed OD: 'HOT' failed")
    //ret = mr.RunStep("Peak Highway Assignment", {Silent: "true"})
    //if !ret then Throw("Fixed OD: 'Peak Highway Assignment' failed")
    

    // Run assignments
    /*Args.sl_query = sl_query
    periods = Args.periods
    for period in periods do
        RunMacro("HwyAssn_MMA_TCv7", Args, {period: period})
    end*/

    /*Args.sl_query = sl_query*/
    //RunMacro("Peak Highway Assignment", Args)
    //RunMacro("Convergence", Args)
    //RunMacro("Post Feedback", Args)
    //RunMacro("HOT", Args)

    // Run summary macros of interest
    /*RunMacro("Load Link Layer", Args)
    RunMacro("Calculate Daily Fields", Args)
    RunMacro("Create Count Difference Map", Args)
    RunMacro("Count PRMSEs", Args)
    RunMacro("VOC Maps", Args)
    RunMacro("Speed Maps", Args)
    RunMacro("Summarize Links", Args)
    RunMacro("VMT_Delay Summary", Args)*/
endmacro

/*

*/

Macro "Copy Files for Fixed OD" (Args, ref_scen_dir)

    from_dir = ref_scen_dir
    to_dir = Args.[Run Directory]
    /*from_dir = "C:\\MRM\\Metrolina\\Official_2045"
    to_dir = "C:\\MRM\\Metrolina\\Official_2025"*/
    periods = {"AMPeak", "Midday", "PMPeak", "Night"}
    for period in periods do
      from_file = from_dir + "\\TOD2\\ODHwyVeh_" + period + ".mtx"
      to_file   = to_dir   + "\\TOD2\\ODHwyVeh_" + period + ".mtx"
      CopyFile(from_file, to_file)

      from_file_1 = from_dir + "\\HwyAssn\\Assn_" + period + ".bin"
      to_file_1  = to_dir   + "\\HwyAssn\\Assn_" + period + ".bin"
      CopyFile(from_file_1, to_file_1)
      CopyFile(
        Substitute(from_file_1 , ".bin", ".dcb", 1), 
        Substitute(to_file_1, ".bin", ".dcb", 1)
      )
    end



    //periods = Args.periods
    /*periods = {
      "AMPeak",
      "Midday",
      "PMPeak",
      "Night"
    }*/
    /*periods = Args.periods

    newCodes = {
        AM: "AMPeak",
        PM: "PMPeak",
        MD: "Midday",
        NT: "Night"
    }

    for period in periods do
        assnPeriod = newCodes.(period)

        from_file = from_dir + "\\TOD2\\ODHwyVeh_" + assnPeriod + ".mtx"
        to_file   = to_dir   + "\\TOD2\\ODHwyVeh_" + assnPeriod + ".mtx"
    end*/
    /*newCodes = {AM: 'AMPeak', PM: 'PMPeak', MD: 'Midday', NT: 'Night'}
    assnPeriod = newCodes.(period)
    // OD matrices
    from_od_dir = from_dir + "\\tod2"
    to_od_dir = to_dir + "\\tod2"
    for period in periods do
        from_file = from_od_dir + "\\ODHwyVeh_" + assnPeriod + ".mtx"
        to_file = to_od_dir + "\\ODHwyVeh_" + assnPeriod + ".mtx"
        CopyFile(from_file, to_file)
    end*/
endmacro

