/*
The purpose of this tool to is allow supply side changes to be evaluated
quickly without affecting the demand (OD matrix).
*/
Macro "Open Fixed OD Dbox" (Args)
	RunDbox("FixedOD", Args)
endmacro
dBox "FixedOD" (Args) center, center, 50, 8 Title: "Fixed OD Assignment" Help: "test" toolbox

  init do
    static ref_scen_dir, curr_scen
    METDir = Args.[MET Directory]
    curr_scen = Args.[Scenario]
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
  
  //This line shows current scenario name that is selected in the TC
  Text 15, 3, 15 Prompt: "Analysis Scenario:" Variable: curr_scen

  Button 12, 5 Prompt: "Run" do
    mr = CreateObject("Model.Runtime")
    Args = mr.GetValues()
    opts.ref_scen_dir = ref_scen_dir
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
    mr = CreateObject("Model.Runtime")
    Args = mr.GetValues()
    if ref_scen_dir != Args.[Run Directory] then do
    RunMacro("Copy Files for Fixed OD", Args, ref_scen_dir)
    end
    ret = mr.RunStep("Initial Processing", {Silent: "true"})
    if !ret then Throw("Fixed OD: 'Initial Processing' failed")
    ret = mr.RunStep("HOT", {Silent: "true"})
    if !ret then Throw("Fixed OD: 'HOT' failed")
endmacro

/*

*/

Macro "Copy Files for Fixed OD" (Args, ref_scen_dir)

    from_dir = ref_scen_dir
    to_dir = Args.[Run Directory]
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
endmacro

