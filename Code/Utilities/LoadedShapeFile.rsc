/*
The purpose of this tool to is allow supply side changes to be evaluated
quickly without affecting the demand (OD matrix).
*/
Macro "Open Loaded Shape File Dbox" (Args)
	RunDbox("LoadedShapeFile", Args)
endmacro
dBox "LoadedShapeFile" (Args) center, center, 50, 8 Title: "Loaded Shapefile" Help: "test" toolbox

  init do
    static hwynet_dir, sl_query, assn_dir
    METDir = Args.[MET Directory]
  enditem

  close do
    return()
  enditem

  Edit Text 15, 1, 15 Prompt: "Highway Network:" Variable: hwynet_dir
  Button after, same, 5, 1 Prompt: "..." do
    on error, escape goto skip1
    hwynet_dir = ChooseDirectory("Choose Highway Network Folder", {"Initial Directory": METDir})
    skip1:
    on error default
  enditem

  Edit Text 15, after, 15 Prompt: "Assignment Output:" Variable: assn_dir
  Button after, same, 5, 1 Prompt: "..." do
    on error, escape goto skip1
    assn_dir = ChooseDirectory("Choose Assignment Output Folder", {"Initial Directory": METDir})
    skip1:
    on error default
  enditem

  Button 12, 6.5 Prompt: "Run" do
    mr = CreateObject("Model.Runtime")
    Args = mr.GetValues()
    opts.hwynet_dir = hwynet_dir
    opts.assn_dir = assn_dir
    RunMacro("Loaded Shape File", opts)
    ShowMessage("Loaded Shape File Created")
  enditem
  Button 20, same Prompt: "Quit" do
    Return()
  enditem
  Button 28, same Prompt: "Help" do
    ShowMessage(
      "This tool lets you evaluate a roadway project quickly by " +
      "borrowing demand info from a fully-converged scenario."
    )
  enditem
enddbox

/*

*/

Macro "Loaded Shape File" (MacroOpts)

    hwynet_dir = MacroOpts.hwynet_dir
    assn_dir = MacroOpts.assn_dir
    
    
    mr = CreateObject("Model.Runtime")
    Args = mr.GetValues()
    RunMacro("Copy Files for Loaded Shape File", MacroOpts)
    hwy_dbd = hwynet_dir + "\\RegNet_copy.dbd"

    RunMacro("Join Table To Layer", hwy_dbd, "ID", assn_dir + "\\Tot_Assn_HOT.bin", "ID")
    hwy_tbl = CreateObject("Table", {FileName: hwy_dbd, LayerType: "line"})

    //To add description to the fields, use the ChangeField method. The Description is what will be displayed in the ArcGIS attribute table.
    //hwy_tbl.ChangeField({FieldName: "ID", Description: "Unique ID for each link in the network"})

    a_fields = {
    {FieldName: "TOT_TRUCK", Description: "=TOT_MTK+TOT_HTK; Round to nearest tenth"},
    {FieldName: "TRUCK_PCT", Description: "=TOT_TRUCK/VOL_POST*100, Round to 0 decimals"},
    {FieldName: "SPD_FR_AB", Description: "=Length/TTFreeAB*60; Round to 0 decimals"},
    {FieldName: "SPD_FR_BA", Description: "=Length/TTFreeBA*60; Round to 0 decimals"},
    {FieldName: "SPD_PK_AB", Description: "=Length/TTPkAssnAB*60; Round to 0 decimals"},
    {FieldName: "SPD_PK_BA", Description: "=Length/TTPkAssnBA*60; Round to 0 decimals"},
    {FieldName: "AM_SPD_AB", Description: "=Length/MinRawAMAB*60; Round to 0 decimals"},
    {FieldName: "AM_SPD_BA", Description: "=Length/MinRawAMBA*60; Round to 0 decimals"},
    {FieldName: "PM_SPD_AB", Description: "=Length/MinRawPMAB*60; Round to 0 decimals"},
    {FieldName: "PM_SPD_BA", Description: "=Length/MinRawPMBA*60; Round to 0 decimals"},
    {FieldName: "MI_SPD_AB", Description: "=Length/MinRawMIAB*60; Round to 0 decimals"},
    {FieldName: "MI_SPD_BA", Description: "=Length/MinRawMIBA*60; Round to 0 decimals"},
    {FieldName: "NT_SPD_AB", Description: "=Length/MinRawNTAB*60; Round to 0 decimals"},
    {FieldName: "NT_SPD_BA", Description: "=Length/MinRawNTBA*60; Round to 0 decimals"}
    }

    hwy_tbl.AddFields({Fields: a_fields})
    hwy_tbl.TOT_TRUCK = Round(hwy_tbl.TOT_MTK + hwy_tbl.TOT_HTK, 1)
    hwy_tbl.TRUCK_PCT = Round(hwy_tbl.TOT_TRUCK / hwy_tbl.VOL_POST * 100, 0)
    hwy_tbl.SPD_FR_AB = Round(hwy_tbl.Length / hwy_tbl.TTFreeAB * 60, 0)
    hwy_tbl.SPD_FR_BA = Round(hwy_tbl.Length / hwy_tbl.TTFreeBA * 60, 0)
    hwy_tbl.SPD_PK_AB = Round(hwy_tbl.Length / hwy_tbl.TTPkAssnAB * 60, 0)
    hwy_tbl.SPD_PK_BA = Round(hwy_tbl.Length / hwy_tbl.TTPkAssnBA * 60, 0)
    hwy_tbl.AM_SPD_AB = Round(hwy_tbl.Length / hwy_tbl.MinRawAMAB * 60, 0)
    hwy_tbl.AM_SPD_BA = Round(hwy_tbl.Length / hwy_tbl.MinRawAMBA * 60, 0)
    hwy_tbl.PM_SPD_AB = Round(hwy_tbl.Length / hwy_tbl.MinRawPMAB * 60, 0)
    hwy_tbl.PM_SPD_BA = Round(hwy_tbl.Length / hwy_tbl.MinRawPMBA * 60, 0)
    hwy_tbl.MI_SPD_AB = Round(hwy_tbl.Length / hwy_tbl.MinRawMIAB * 60, 0)
    hwy_tbl.MI_SPD_BA = Round(hwy_tbl.Length / hwy_tbl.MinRawMIBA * 60, 0)
    hwy_tbl.NT_SPD_AB = Round(hwy_tbl.Length / hwy_tbl.MinRawNTAB * 60, 0)
    hwy_tbl.NT_SPD_BA = Round(hwy_tbl.Length / hwy_tbl.MinRawNTBA * 60, 0)

    hwy_tbl.DropFields({FieldNames: {"RegNet.Dir",	"RegNet.Length",	"fedfuncl",	"AQ_2008NA",	"SpdLimRun",	"parking",	
    "Pedactivity",	"Developden",	"Drivewayden",	"landuse",	"A_LeftLns",	"A_ThruLns",	"A_RightLns",	"A_Control",	
    "A_Prohibit",	"B_LeftLns",	"B_ThruLns",	"B_RightLns",	"B_control",	"B_prohibit",	"alpha",	"beta",	"CNTAAWT19",	
    "CNTAAWT20",	"CNTAAWT21",	"CNTAAWT22",	"CNTAAWT23",	"CALIB15",	"CALIB18",	"MTK15",	"MTK18",	"HTK15",	"HTK18",	
    "StationID",	"TMCcode_ab",	"TMCcode_ba",	"TT_RTE",	"TT_KEY_AB",	"TT_KEY_BA",	"locclass1",	"locclass2",	"reverselane",	
    "reversetime",	"SPfreeAB",	"SPfreeBA",	"SPpeakAB",	"SPpeakBA",	"TTPeakAB",	"TTPeakBA",	"TTLinkFrAB",	"TTLinkFrBA",	
    "TTLinkPkAB",	"TTLinkPkBA",	"IntDelFr_A",	"IntDelFr_B",	"IntDelPk_A",	"IntDelPk_B",	"TTPkEstAB",	"TTPkEstBA",	"TTPkPrevAB",	
    "TTPkPrevBA",	"TTPkLocAB",	"TTPkLocBA",	"TTPkXprAB",	"TTPkXprBA",	"TTPkNStAB",	"TTPkNStBA",	"TTPkSkSAB",	"TTPkSkSBA",	
    "TTFrLocAB",	"TTFrLocBA",	"TTFrXprAB",	"TTFrXprBA",	"TTFrNStAB",	"TTFrNStBA",	"TTFrSkSAB",	"TTFrSkSBA",	"PkLocLUAB",	
    "PkLocLUBA",	"PkXprLUAB",	"PkXprLUBA",	"TTwalkAB",	"TTwalkBA",	"TTbikeAB",	"TTbikeBA",	"ImpPkAB",	"ImpPkBA",	"ImpFreeAB",	
    "ImpFreeBA",	"OppFunclA",	"OppFunclB",	"TollAB",	"TollBA",	"HOTAB",	"HOTBA",	"Mode",	"BRT_Flag",	"Level",	"TOLL_PRJID",	
    "HOT_PRJID",	"projnum1",	"DIR_prj1",	"funcl_prj1",	"fedfuncl_prj1",	"fedfunc_AQ_prj1",	"lnsAB_prj1",	"lnsBA_prj1",	
    "factypprj1",	"SpdLmtprj1",	"SpLRunprj1",	"Park_prj1",	"Ped_prj1",	"Devden_prj1",	"Drwyden_prj1",	"Acntl_prj1",	"Aprhb_prj1",	
    "Aleft_prj1",	"Athru_prj1",	"Arite_prj1",	"Bcntl_prj1",	"Bprhb_prj1",	"Bleft_prj1",	"Bthru_prj1",	"Brite_prj1",	"projnum2",	
    "dir_prj2",	"funcl_prj2",	"fedfuncl_prj2",	"fedfunc_AQ_prj2",	"lnsAB_prj2",	"lnsBA_prj2",	"factypprj2",	"SpdLmtprj2",	
    "SpLRunprj2",	"Park_prj2",	"Ped_prj2",	"Devden_prj2",	"Drwyden_prj2",	"Acntl_prj2",	"Aprhb_prj2",	"Aleft_prj2",	"Athru_prj2",	
    "Arite_prj2",	"Bcntl_prj2",	"Bprhb_prj2",	"Bleft_prj2",	"Bthru_prj2",	"Brite_prj2",	"projnum3",	"dir_prj3",	"funcl_prj3",	
    "fedfuncl_prj3",	"fedfunc_AQ_prj3",	"lnsAB_prj3",	"lnsBA_prj3",	"factypprj3",	"SpdLmtprj3",	"SpLRunprj3",	"Park_prj3",	
    "Ped_prj3",	"Devden_prj3",	"Drwyden_prj3",	"Acntl_prj3",	"Aprhb_prj3",	"Aleft_prj3",	"Athru_prj3",	"Arite_prj3",	"Bcntl_prj3",	
    "Bprhb_prj3",	"Bleft_prj3",	"Bthru_prj3",	"Brite_prj3",	"TTWtdWlkAB",	"TTWtdWlkBA",	"TTHOTAB",	"TTHOTBA",	"ImpHOTAB",	
    "ImpHOTBA",	"TTHOTPrevAM1AB",	"TTHOTPrevAM1BA",	"TTHOTPrevAM2AB",	"TTHOTPrevAM2BA",	"TTHOTPrevAM3AB",	"TTHOTPrevAM3BA",	
    "TTHOTPrevAM4AB",	"TTHOTPrevAM4BA",	"TTHOTPrevAM5AB",	"TTHOTPrevAM5BA",	"TTHOTPrevPM1AB",	"TTHOTPrevPM1BA",	"TTHOTPrevPM2AB",	
    "TTHOTPrevPM2BA",	"TTHOTPrevPM3AB",	"TTHOTPrevPM3BA",	"TTHOTPrevPM4AB",	"TTHOTPrevPM4BA",	"TTHOTPrevPM5AB",	"TTHOTPrevPM5BA",	
    "TTHOTPrevMD1AB",	"TTHOTPrevMD1BA",	"TTHOTPrevMD2AB",	"TTHOTPrevMD2BA",	"TTHOTPrevMD3AB",	"TTHOTPrevMD3BA",	"TTHOTPrevMD4AB",	
    "TTHOTPrevMD4BA",	"TTHOTPrevMD5AB",	"TTHOTPrevMD5BA",	"TTHOTPrevNI1AB",	"TTHOTPrevNI1BA",	"TTHOTPrevNI2AB",	"TTHOTPrevNI2BA",	
    "TTHOTPrevNI3AB",	"TTHOTPrevNI3BA",	"TTHOTPrevNI4AB",	"TTHOTPrevNI4BA",	"TTHOTPrevNI5AB",	"TTHOTPrevNI5BA",	"slave.Length",	
    "slave.Dir",	"fedfunc_AQ",	"Co_fedfunc",	"A_CrossStr",	"B_CrossStr",	"areatp",	"CALIB",	"MTK",	"HTK",	"Scrln",	"STCNTY",	
    "cap1hrAB",	"cap1hrBA",	"TTfreeAB",	"TTfreeBA",	"TTPkAssnAB",	"TTPkAssnBA",	"CNTFLAG",	"Fun2",	"CntyAF",	"VMTLen",	"AM2.tid",	
    "MinRawAMAB",	"MinRawAMBA",	"minAMAB",	"minAMBA",	"FresovAMAB",	"FresovAMBA",	"HOTsovAMAB",	"HOTsovAMBA",	"Frepl2AMAB",	
    "Frepl2AMBA",	"HOTpl2AMAB",	"HOTpl2AMBA",	"Frepl3AMAB",	"Frepl3AMBA",	"HOTpl3AMAB",	"HOTpl3AMBA",	"FrecomAMAB",	"FrecomAMBA",	
    "HOTcomAMAB",	"HOTcomAMBA",	"mtkAMAB",	"mtkAMBA",	"htkAMAB",	"htkAMBA",	"sovAM",	"pool2AM",	"pool3AM",	"comAM",	
    "mtkAM",	"htkAM",	"VMTAMAB",	"VMTAMBA",	"VHTAMAB",	"VHTAMBA",	"vcAMAB",	"vcAMBA",	"PM2.tid",	"MinRawPMAB",	"MinRawPMBA",	
    "minPMAB",	"minPMBA",	"FresovPMAB",	"FresovPMBA",	"HOTsovPMAB",	"HOTsovPMBA",	"Frepl2PMAB",	"Frepl2PMBA",	"HOTpl2PMAB",	
    "HOTpl2PMBA",	"Frepl3PMAB",	"Frepl3PMBA",	"HOTpl3PMAB",	"HOTpl3PMBA",	"FrecomPMAB",	"FrecomPMBA",	"HOTcomPMAB",	"HOTcomPMBA",	
    "mtkPMAB",	"mtkPMBA",	"htkPMAB",	"htkPMBA",	"sovPM",	"pool2PM",	"pool3PM",	"comPM",	"mtkPM",	"htkPM",	"VMTPMAB",	
    "VMTPMBA",	"VHTPMAB",	"VHTPMBA",	"vcPMAB",	"vcPMBA",	"MI2.tid",	"MinRawMIAB",	"MinRawMIBA",	"minMIAB",	"minMIBA",	
    "FresovMIAB",	"FresovMIBA",	"HOTsovMIAB",	"HOTsovMIBA",	"Frepl2MIAB",	"Frepl2MIBA",	"HOTpl2MIAB",	"HOTpl2MIBA",	"Frepl3MIAB",	
    "Frepl3MIBA",	"HOTpl3MIAB",	"HOTpl3MIBA",	"FrecomMIAB",	"FrecomMIBA",	"HOTcomMIAB",	"HOTcomMIBA",	"mtkMIAB",	"mtkMIBA",	
    "htkMIAB",	"htkMIBA",	"sovMI",	"pool2MI",	"pool3MI",	"comMI",	"mtkMI",	"htkMI",	"VMTMIAB",	"VMTMIBA",	"VHTMIAB",	
    "VHTMIBA",	"vcMIAB",	"vcMIBA",	"NT2.tid",	"MinRawNTAB",	"MinRawNTBA",	"minNTAB",	"minNTBA",	"FresovNTAB",	"FresovNTBA",	
    "HOTsovNTAB",	"HOTsovNTBA",	"Frepl2NTAB",	"Frepl2NTBA",	"HOTpl2NTAB",	"HOTpl2NTBA",	"Frepl3NTAB",	"Frepl3NTBA",	"HOTpl3NTAB",	
    "HOTpl3NTBA",	"FrecomNTAB",	"FrecomNTBA",	"HOTcomNTAB",	"HOTcomNTBA",	"mtkNTAB",	"mtkNTBA",	"htkNTAB",	"htkNTBA",	"sovNT",	
    "pool2NT",	"pool3NT",	"comNT",	"mtkNT",	"htkNT",	"VMTNTAB",	"VMTNTBA",	"VHTNTAB",	"VHTNTBA",	"vcNTAB",	"vcNTBA",	
    "TOT_SOV",	"TOT_POOL2",	"TOT_POOL3",	"TOT_COM",	"TOT_MTK",	"TOT_HTK",	"CNTMCSQ",	"MTKMCSQ",	"HTKMCSQ"}})


    //Creating a report directory to store the loaded shape file and metadata
    report_dir = hwynet_dir + "\\Report\\LoadedShapeFile"
  
    if GetDirectoryInfo(report_dir, "All") = null then
      CreateDirectory(report_dir)

    /*Writing Metadata to CSV file for Loaded Shape File*/

    str = GetTableStructure("RegNet")
    f = OpenFile(report_dir + "\\2045_Loaded_HwyNet_Metadata.csv", "w")
    WriteLine(f, "Field,Description")
    //WriteLine(f, "Field,Type,Width,Precision,Description")

    for i = 1 to str.length do
      field = str[i]
      name = field[1]
      //type = field[2]
     //width = field[3]
      //prec = field[4]
      desc = if field[8] <> null then Substitute(field[8], ",", ";", ) else ""
      //WriteLine(f, name + "," + type + "," + String(width) + "," + String(prec) + "," + desc)
      WriteLine(f, name + "," + desc)
    end
    CloseFile(f)

    /*Exporting Loaded Shape File to Shapefile for ArcGIS*/

    field_list = GetFields("RegNet", "All")
    ExportArcViewShape("RegNet", report_dir + "\\2045_Loaded_HwyNet.shp", {{"Fields", field_list[1]}})
    hwy_tbl = null
    DeleteDatabase(hwy_dbd)
endmacro

/*

*/

Macro "Copy Files for Loaded Shape File" (MacroOpts)

    hwynet_dir = MacroOpts.hwynet_dir
    
    //Following lines are commented out because the loaded shape file tool does not require copying of assignment files. The tool only requires the highway network to be copied to a new location for processing.
    /*assn_dir = MacroOpts.assn_dir
    from_dir = assn_dir
    to_dir = assn_dir*/
    //from_file = from_dir + "\\Tot_Assn_HOT.bin"
    //to_file  = hwynet_dir + "\\Tot_Assn_HOT.bin"

    //from_file = "C:\\MRM\\Metrolina\\Official_2045\\HwyAssn\\HOT\\Tot_Assn_HOT.bin"
    //to_file = "C:\\MRM\\Metrolina\\Official_2045\\HwyAssn\\HOT\\Tot_Assn_HOT_copy.bin"
    /*from_file = assn_dir + "\\Tot_Assn_HOT.bin"
    to_file = assn_dir + "\\Tot_Assn_HOT_copy.bin"
    CopyFile(from_file, to_file)
    CopyFile(
      Substitute(from_file , ".bin", ".dcb", 1), 
      Substitute(to_file, ".bin", ".dcb", 1))*/

    CopyDatabase(hwynet_dir + "\\RegNet.dbd", hwynet_dir + "\\RegNet_copy.dbd")
endmacro

