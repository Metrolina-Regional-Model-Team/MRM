/*

*/

// Create tour directory
Macro "Create Tour Dir" (Args)
    
    pbar = CreateObject("G30 Progress Bar", "Creating Directory", True, )

    run_dir = Args.[Run Directory]
    mrm_dir = Args.[MRM Directory]
    year = Args.[Run Year]
    keepgoing = "Yes"
    
    modeltype = "Tour"
    CreateDirectory = 1
  
    if keepgoing = "Yes" then RunMacro("CreateDir", Args)
    if keepgoing = "Yes" then RunMacro("GetTAZ", Args)
    if keepgoing = "Yes" then RunMacro("GetLU", Args)
    if keepgoing = "Yes" 
        then do
            
            AppendtoReportFile(1, "Create Directory: " + DirUser + ",  " + datentime)
            AppendtoReportFile(1, " ") 
            AppendtoLogFile(1, "Create Tour Directory: " + DirUser + ",  " + datentime)
            AppendtoLogFile(1, " ") 
            AppendtoLogFile(1, "Create Tour Directory messages")
            for i = 1 to Messages.length do
                AppendtoLogFile(2, Messages[i])
            end
            AppendtoLogFile(2, " ")				
            
        end

    quitcreatedirtourbutton:
    ShowMessage("Tour Directory Created.")

endmacro

// **************************  Macros section of DBox *******************************
//
//	GetDir - Get file name of run directory 
//	GetArguments - Read arguments file or initialize 
//	SetArguments - Save arguments to file file 
//	CheckArguments - Last check called by run model buttons
//	GetMRM - Get file name of MRM directory
//		GetMRMDefault - Get MRM default from \TransCad dir
//	GetYear - Get year of run
//	CreateDir - Create run directory
//	GetTAZ - get TAZ file - copy to \\Metrolina if nec.
//	GetLU - get land use file
//	SetSignals

//	CheckDirFiles - check MRM, Year, TAZ, LU files - set signals 
//  CreateRunDirectory - Create run directory and fill.   If necessary - create \Metrolina also
//*************************************************************************************************



// *************************************Create Directory ************************************		

Macro "CreateDir" (Args)
// Creates run directory and subdirectories, fills files from MRM

    MRMUser = Args.[MRM Directory]
    METUser = Args.[MET Directory]
    DirUser = Args.[Run Directory]
    YearUser = Args.[Run Year]

    METFiles =
        {
            {"\\MS_Control_Template", 
            {"ALTNAME_HBW_PEAK.bat", "ALTNAME_HBW_OFFPEAK.bat", "ALTNAME_HBW_PEAK.ctl", "ALTNAME_HBW_OFFPEAK.ctl",
            "ALTNAME_HBO_PEAK.bat", "ALTNAME_HBO_OFFPEAK.bat", "ALTNAME_HBO_PEAK.ctl", "ALTNAME_HBO_OFFPEAK.ctl",
            "ALTNAME_NHB_PEAK.bat", "ALTNAME_NHB_OFFPEAK.bat", "ALTNAME_NHB_PEAK.ctl", "ALTNAME_NHB_OFFPEAK.ctl",
            "ALTNAME_HBU_PEAK.bat", "ALTNAME_HBU_OFFPEAK.bat", "ALTNAME_HBU_PEAK.ctl", "ALTNAME_HBU_OFFPEAK.ctl",
            "Mode_Choice_Script.txt", "Segment_Map.txt", "Segment_Map.txt.def",
            "TAZ_ATYPE_TRANSIT_FLAGS.dbf", "TAZ_ATYPE.asc.def"}},
 
            {"\\MS_Control_Template", 
            {"HBW_PEAK_Bias.txt", "HBW_PEAK_Bias.txt.def", "HBW_PEAK_Constant.txt", "HBW_PEAK_Constant.txt.def",
            "HBW_OFFPEAK_Bias.txt", "HBW_OFFPEAK_Bias.txt.def", "HBW_OFFPEAK_Constant.txt", "HBW_OFFPEAK_Constant.txt.def",
            "HBO_PEAK_Bias.txt", "HBO_PEAK_Bias.txt.def", "HBO_PEAK_Constant.txt", "HBO_PEAK_Constant.txt.def",
            "HBO_OFFPEAK_Bias.txt", "HBO_OFFPEAK_Bias.txt.def", "HBO_OFFPEAK_Constant.txt", "HBO_OFFPEAK_Constant.txt.def",
            "NHB_PEAK_Bias.txt", "NHB_PEAK_Bias.txt.def", "NHB_PEAK_Constant.txt", "NHB_PEAK_Constant.txt.def",
            "NHB_OFFPEAK_Bias.txt", "NHB_OFFPEAK_Bias.txt.def", "NHB_OFFPEAK_Constant.txt", "NHB_OFFPEAK_Constant.txt.def",
            "HBU_PEAK_Bias.txt", "HBU_PEAK_Bias.txt.def", "HBU_PEAK_Constant.txt", "HBU_PEAK_Constant.txt.def",
            "HBU_OFFPEAK_Bias.txt", "HBU_OFFPEAK_Bias.txt.def", "HBU_OFFPEAK_Constant.txt", "HBU_OFFPEAK_Constant.txt.def",
            "modes.dbf", "modexfer.dbf"}},


        {"\\TAZ", 
            {"TAZNeighbors_pct.asc", "TAZNeighbors_pct.dct", "Parking_Cost_Base06.dbf", "PUMAequiv.prn"}},

        {"\\Pgm",
            {"CaliperMTXF.dll","CaliperMTXF.lib","capspd.exe","SHW32.DLL",
            "tdmet_mtx.exe", "tgmet2015_171013.exe"}},

        {"\\Pgm\\ModeChoice",  
            {"Add_Shadow_Price.exe","CALIBMS.exe","Caliperb.dll","CaliperMTX.dll","CaliperMTXF.dll","CaliperMTXF.lib",
            "DFORMD.DLL","Drv2PNR2Attr.exe","ExportUBMatrix.exe","HA312W32.dll","KNR_Loc_CAT.exe","SHW32.DLL", "ModeChoice.exe",
            "UPD_DA_Dist_Time_Costv1.exe","UPD_DA_Dist_Time_Costv2.exe"}},

        {"\\Pgm\\CapspdFactors", 
            {"capspd_guideway.asc", "capspd_guideway.dct", "CapSpd_lookup.csv", "CapSpd_lookup.dcc"}},
         
        {"\\Pgm\\FrictionFactors",  
            {"ffcom.bin", "ffcom.dcb", "ffmtk.bin", "ffmtk.dcb",  "ffhtk.bin", "ffhtk.dcb",  
            "ffeic.bin", "ffeic.dcb", "ffeim.bin", "ffeim.dcb", "ffeih.bin", "ffeih.dcb",
            "ffiec.bin", "ffiec.dcb", "ffiem.bin", "ffiem.dcb", "ffieh.bin", "ffieh.dcb"}},

        {"\\ExtSta", 
            {"thrubase_auto.asc", "thrubase_auto.dct", "thrubase_com.asc", "thrubase_com.dct",
            "thrubase_mtk.asc",  "thrubase_mtk.dct",  "thrubase_htk.asc", "thrubase_htk.dct",
            "bvthru.asc", "bvthru.dct", "extstavol.asc", "extstavol.dct"}},

        {"",
            {"ATFUN_ID.dbf", "COATFUN_ID.dbf", "County_ATFun.bin","County_ATFun.dcb","County_ATFunID.bin", 
            "County_ATFunID.dcb", "FUNAQ_ID.dbf", "ScreenlineID.bin", "ScreenlineID.dcb", "STCNTY_ID.dbf", 
            "trnpnlty.bin", "trnpnlty.dcb", "HOT_Table.hot"}}
        }

    for i = 1 to METFiles.length do	
        MRMSubDir = METFiles[i][1]
        METSubDir = MRMSubDir
     
        // Check files - if MET created, all the files should be listed here 
        for j = 1 to METFiles[i][2].length do
            MRMdatestamp = null
            METdatestamp = null
            MRMInfo = GetFileInfo(MRMUser + MRMSubDir + "\\" + METFiles[i][2][j])
            if MRMInfo = null then Throw("CreateDir Warning! MRM! " + MRMUser + MRMSubDir + "\\" +  METFiles[i][2][j] + " not found")
                // then Message = Message + {"CreateDir Warning! MRM! " + MRMUser + MRMSubDir + "\\" +  METFiles[i][2][j] + " not found"}
            MRMdatestamp = MRMInfo[7] + " " + MRMInfo[8]

            if GetDirectoryInfo(METUser + METSubDir, "All") = null then CreateDirectory(METUser + METSubDir)

            METInfo = GetFileInfo(METUser + METSubDir + "\\" + METFiles[i][2][j])
            if METInfo = null
                then METMissing = METMissing + {"copy " + MRMUser + MRMSubDir + "\\" +  METFiles[i][2][j] + " " +  METUser + METSubDir +  "\\" +  METFiles[i][2][j]}
                else do
                    METdatestamp = METInfo[7] + " " + METInfo[8]
                    if MRMdatestamp = null 
                        then do
                            Throw("CreateDir Warning! " + METFiles[i][2][j] + " not found in either MRM or MET, Run Will Bomb if file needed!")
                            // METSignalStatus = 2
                            // Message = Message + {"CreateDir Warning! " + METFiles[i][2][j] + " not found in either MRM or MET, Run Will Bomb if file needed!"}
                        end
                    // else if MRMdatestamp <> METdatestamp
                            // then do
                    else do
                        METMissing = METMissing + {"copy " + MRMUser + MRMSubDir + "\\" +  METFiles[i][2][j] + " " +  METUser + METSubDir +  "\\" +  METFiles[i][2][j]}
                        // Message = Message + {"CreateDir Warning! " + MRMSubDir  + "\\" + METFiles[i][2][j] + " datestamp: " + MRMdatestamp + " replaced MET file - datestamp: " + METdatestamp}
                    end
                end // else METInfo <> null
        end  // for j
        skipsubdir:
    end // for i

//		showarray(METMissing)
    if METMissing = null then goto endMET

    //Add MET files - loaded with subdir into METMissing array in step above

    batchname  = METUser + "\\copy_file.bat"
    exist = GetFileInfo(batchname)
    if (exist <> null) then DeleteFile(batchname)
    batchhandle = OpenFile(batchname, "w")
    for i = 1 to METMissing.length do
        WriteLine(batchhandle, METMissing[i])
    end // for i
    CloseFile(batchhandle)

    status = RunProgram(batchname, )

    if (status <> 0) 
        then do
            Throw("CreateDir WARNING! Error in batch copy from MRM to \\Metrolina, status=" +i2s(status))
            
        end
        else DeleteFile(batchname)
    endMET:
    // ****************Create Run Directory ***************************************************

    //Make sure year exists in MRM
    MRMInfo = GetDirectoryInfo(MRMUser + "\\" + YearUser, "Directory")
    if MRMInfo = null then do
        Throw("CreateDir ERROR! Year: " + YearUser + " does not exist in MRM: " + MRMUser)
        
    end
    if GetDirectoryInfo(DirUser, "All") = null then CreateDirectory(DirUser)

    LandUseStatus = 1

    RunDirSubDir = 
        {"\\AutoSkims", "\\Ext", "\\HwyAssn", "\\LandUse", "\\Report", "\\Skims", "\\TD", "\\TG", "\\TOD2",
            "\\TourModeSplit",
            "\\TranAssn", "\\TripTables", "\\HwyAssn\\HOT",
            "\\TranAssn\\PPrmW", "\\TranAssn\\PPrmD", "\\TranAssn\\PPrmDrop", "\\TranAssn\\OPPrmW", "\\TranAssn\\OPPrmD",
            "\\TranAssn\\OPPrmDrop", "\\TranAssn\\PBusW", "\\TranAssn\\PBusD", "\\TranAssn\\PBusDrop", "\\TranAssn\\OPBusW", 
            "\\TranAssn\\OPBusD", "\\TranAssn\\OPBusDrop"}	

    for i = 1 to RunDirSubDir.length do
        if GetDirectoryInfo(DirUser + RunDirSubDir[i], "All") = null then CreateDirectory(DirUser + RunDirSubDir[i])
    end
            
    //Copy files	
    batchname  = DirUser + "\\copy_file.bat"
    exist = GetFileInfo(batchname)
    if (exist <> null) then DeleteFile(batchname)
    batchhandle = OpenFile(batchname, "w")

    // Copy route system
    MRMpath = MRMUser + "\\" + YearUser + "\\"
    dm = CreateObject("DataManager")
    dm.AddDataSource("rts", {FileName: MRMpath + "transys.rts", DataType: "RS"})
    route_file = DirUser + "\\" + "transys.rts"
    dm.CopyRouteSystem("rts", {TargetRS: route_file})
    
    //net_file = Args.[Offpeak Hwy Name]
    /*net_file = Args.[Hwy Name]
    {, , netname, } = SplitPath(net_file)
    ModifyRouteSystem(route_file, {{"Geography", net_file, netname},{"Link ID", "ID"}})
    */
    // need to add year onto extsta vol files	

    YearTwo = Right(YearUser,2)
    rundir_files = 
			{"station_database.dbf", "Track_ID.dbf", "transit_corridor_id.dbf", "transys.rtg", "transys.rts",
             "transysL.bin", "transysL.BXU", "transysL.DCB",  "transysR.BXU", "transysR.DCB", "transysR.bin", 
             "transysS.bin", "transysS.BXU", "transysS.cdd", "transysS.cdk", "transysS.dbd", "transysS.DCB", "transysS.dsc",		
			 "transysS.dsk","transysS.grp", "transysS.lok", "transysS.pnk", "transysS.r0"}
    rundir_files = rundir_files + {"Ext\\extstavol" + YearTwo + ".asc"} + {"Ext\\extstavol" + YearTwo + ".dct"}  

    //Standard runyear files
    MRMpath = MRMUser + "\\" + YearUser + "\\"
    for i = 1 to rundir_files.length do	
        MRMInfo = GetFileInfo(MRMpath + rundir_files[i])
        if MRMInfo <> null
            then WriteLine(batchhandle, "copy " + MRMpath + rundir_files[i] + " " + DirUser + "\\" + rundir_files[i])
            else do
                Throw("MRM file: " + YearUser + "\\" + rundir_files[i] + " not found - not copied")
                
            end
    end 
    
        MRMpath = MRMUser + "\\TG\\"
        MRMInfo = GetDirectoryInfo(MRMpath + "*.*", "File")
        if MRMInfo <> null 
            then do
                for i = 1 to MRMInfo.length do
                    WriteLine(batchhandle, "copy " + MRMpath + MRMInfo[i][1] + " " + DirUser + "\\TG\\" + MRMInfo[i][1])
                end
            end
            else do
                Throw(MRMpath + " files missing, not copied")
                // Message = Message + {MRMPath + " files missing, not copied"}
                // DirSignalStatus = 2
            end
    // end

    // HOT
    hotassn_dcb =
        {"Assn_template.dcb"}
    MRMpath = MRMUser + "\\HOT\\"
    for i = 1 to hotassn_dcb.length do	
        MRMInfo = GetFileInfo(MRMpath + hotassn_dcb[i])
        if MRMInfo <> null
            then WriteLine(batchhandle, "copy " + MRMpath + hotassn_dcb[i] + " " + DirUser + "\\HwyAssn\\HOT\\" + hotassn_dcb[i])
            else do
                Throw("MRM\\HOT dcb: " + hotassn_dcb[i] + " not found - not copied")
                // Message = Message + {"MRM\\HOT dcb: " + hotassn_dcb[i] + " not found - not copied"}
                // DirSignalStatus = 2
            end
    end // for i

    // TourModeSplit
    MRMpath = MRMUser + "\\TourModeSplit\\"
    MRMInfo = GetDirectoryInfo(MRMpath + "*.*", "File")
    if MRMInfo <> null 
        then do
            for i = 1 to MRMInfo.length do
                WriteLine(batchhandle, "copy " + MRMpath + MRMInfo[i][1] + " " + DirUser + "\\TourModeSplit\\" + MRMInfo[i][1])
            end
        end	
        else do
            Throw(MRMPath + " files missing, not copied")
        end

    //Everything in landuse subdirectory
    MRMpath = MRMUser + "\\" + YearUser + "\\LandUse\\"
    MRMInfo = GetDirectoryInfo(MRMpath + "*.*", "File")
    if MRMInfo <> null 
        then do
            for i = 1 to MRMInfo.length do
                WriteLine(batchhandle, "copy " + MRMpath + MRMInfo[i][1] + " " + DirUser + "\\LandUse\\" + MRMInfo[i][1])
            end
        end	
        else do
            Throw(MRMPath + " files missing, not copied")
          
        end

    // end of copy batch
    CloseFile(batchhandle)
    status = RunProgram(batchname, )
    if (status <> 0) 
        then do
            Throw("Error in batch copy from MRM to " + YearUser)
           
        end
        else DeleteFile(batchname)

    
endmacro // Macro CreateDir

Macro "GetTAZ" (Args)
// Macro to identify TAZ file, copy from MRM if necessary
    keepgoing = "Yes"
    TAZSignalStatus = 3
    on error goto notaz

    MRMUser = Args.[MRM Directory]
    METUser = Args.[MET Directory]
    TAZArgs = Args.[MRM TAZ File]
    TAZUser = Args.[TAZ File]

    CopyDataBase(TAZArgs, TAZUser)
    
    // Create/check TAZ template matrix and tazid files (1-good,2-warn,3-bad return)

    TAZrtn = RunMacro("Matrix_template", TAZUser)
    Message = Message + TAZrtn[2]
    TAZSignalStatus = TAZrtn[1]
    if TAZrtn[1] = 1 then goto notaz 
    
    tazpath = SplitPath(TAZUser)
    TAZID = OpenTable("TAZID", "FFA", {MRMUser + "\\TAZ\\" + tazpath[3] + "_TAZID.asc",})
    SetView(TAZID)
    selinttaz = "Select * where TAZ < 12000"
    selexttaz = "Select * where TAZ >= 12000"
    NumIntTAZ = Selectbyquery("inttaz", "Several", selinttaz,)
    NumExtTAZ = Selectbyquery("exttaz", "Several", selexttaz,)
    NumTAZ = NumIntTAZ + NumExtTAZ
    Message = Message + {"TAZ file " + tazpath[3] + ": Internal TAZ="+i2s(NumIntTAZ)+" External TAZ="+i2s(NumExtTAZ)+" Total TAZ="+i2s(NumTAZ)}			
    CloseView(TAZID)
    
    goto quitGetTAZ

    notaz:
    TAZSignalStatus = 1
    Message = Message + {"error= " + GetLastError()}
    PlaySound(sysdir + "\\media\\Windows Critical Stop.wav", "null")
    keepgoing = "No"	
    goto quitGetTAZ

    quitGetTAZ:
    on error, escape default
    
endmacro  //Macro GetTAZ	

Macro "GetLU" (Args)
// Macro to identify LU file 
    keepgoing = "Yes"
    LUSignalStatus = 3
    checkLUTAZ = "False"

    LUArgs = Args.[LandUse File]
    LUUser = LUArgs
    TAZArgs = Args.[TAZ File]
    TAZUser = TAZArgs

    checkLUrtn = RunMacro("checkLU", LUUser, TAZUser)
    Message = Message + checkLUrtn[2]
    if checkLUrtn[1] = 0 then goto noLU

    goto quitGetLU
    
    noLU:
    TAZSignalStatus = 1
    PlaySound(sysdir + "\\media\\Windows Critical Stop.wav", "null")
    keepgoing = "No"	
    goto quitGetLU
    
    quitGetLU:
    on error, escape default
endmacro //Macro GetLU

Macro "SetSignals"
    //Set Signals
    for i = 1 to 3 do
        if i = DirSignalStatus  then ShowItem(DirSignals[i])
                                else HideItem(DirSignals[i])
        if i = MRMSignalStatus  then ShowItem(MRMSignals[i])
                                else HideItem(MRMSignals[i])
        if i = YearSignalStatus then ShowItem(YearSignals[i])
                                else HideItem(YearSignals[i])
        if i = TAZSignalStatus  then ShowItem(TAZSignals[i])
                                else HideItem(TAZSignals[i])
        if i = LUSignalStatus   then ShowItem(LUSignals[i])
                                else HideItem(LUSignals[i])
    end							
endmacro  //Macro SetSignals