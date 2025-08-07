Macro "Update_Drive_Skims_Mtx" (time_period,transit_mode, access_mode, Args)

    shared route_file, routename, net_file, link_lyr, node_lyr


    // LogFile = Args.[Log File]
    // SetLogFileName(LogFile)

    METDir = Args.[MET Directory]
    Dir = Args.[Run Directory]

    msg = null
    UpdateDriveSkimOK = 1
    datentime = GetDateandTime()
    AppendToLogFile(2, "Enter Update_Drive_Skim_Mtx: " + datentime)

// --- Copy Matrices from the Template Directory

    OM = OpenMatrix(METDir + "\\TAZ\\matrix_template.mtx", "True")
    mc1 = CreateMatrixCurrency(OM, "Table", "Rows", "Columns", )
    on error default

    if time_period = "AM" or time_period ="PM" then period = "peak"
    else
    period = "offpeak"
    
    updmtx=Dir+"\\Skims\\"+period+transit_mode+"_DADist.MTX"

    CopyMatrixStructure({mc1}, {{"File Name", updmtx},
        {"Label", "UpdateDriveAccess"},
        {"File Based", "Yes"},
        {"Tables", {"Cost", "Drive Length", "Park Node", "Actual Drive Time", "PNR 2 Dest Length", "In-Veh Time", "OP Time", "OP Cost"}},
        {"Operation", "Union"},{"Compression",0}})

    output_matrix = updmtx

    if (period="peak") then do
        modesplit_matrix = Dir + "\\skims\\PK_DRVTRAN_SKIMS.mtx"
        
        if (transit_mode="premium") then do
            input_matrix = Dir + "\\skims\\TR_SKIM_PPRMD.mtx"
            park_matrix=Dir + "\\skims\\TR_PARK_pprmd.mtx"
        end

        if (transit_mode="bus") then do
            input_matrix = Dir + "\\skims\\TR_SKIM_PBUSD.mtx"
            park_matrix=Dir + "\\skims\\TR_PARK_pbusd.mtx"
        end
    end
    
    if (period= "offpeak") then do
        modesplit_matrix = Dir + "\\skims\\OFFPK_DRVTRAN_SKIMS.mtx"
        if (transit_mode="premium") then do
            input_matrix = Dir + "\\skims\\TR_SKIM_OPPRMD.mtx"
            park_matrix=Dir + "\\skims\\TR_PARK_opprmd.mtx"
        end
        if (transit_mode="bus") then do
            input_matrix = Dir + "\\skims\\TR_SKIM_OPBUSD.mtx"
            park_matrix=Dir + "\\skims\\TR_PARK_opbusd.mtx"
        end
    end

    // pre 2016 versions
//   if (transit_mode="premium2") then do
//  input_matrix = Dir + "\\skims\\TR_SKIM_PPRM2D.mtx"
//  park_matrix=Dir + "\\skims\\TR_PARK_pprm2d.mtx"
// end
//   if (transit_mode="premium3") then do
//  input_matrix = Dir + "\\skims\\TR_SKIM_PPRM3D.mtx"
//  park_matrix=Dir + "\\skims\\TR_PARK_pprm3d.mtx"
//        modesplit_matrix = Dir + "\\skims\\PK_DRVTRAN_SKIMS3.mtx"
//   end
//   if (transit_mode="premium2") then do
//  input_matrix = Dir + "\\skims\\TR_SKIM_OPPRM2D.mtx"
//  park_matrix=Dir + "\\skims\\TR_PARK_opprm2d.mtx"
//   end
//   if (transit_mode="premium3") then do
//  input_matrix = Dir + "\\skims\\TR_SKIM_OPPRM3D.mtx"
//  park_matrix=Dir + "\\skims\\TR_PARK_opprm3d.mtx"
//      modesplit_matrix = Dir + "\\skims\\OFFPK_DRVTRAN_SKIMS3.mtx"
//   end

    Opts = null

     Opts.Input.[Target Currency] = { output_matrix, "Cost", "Rows", "Columns"}
     Opts.Input.[Source Currencies] = {{input_matrix, "Fare", "RCIndex", "RCIndex"}}
     Opts.Global.[Missing Option].[Force Missing] = "Yes"

     ret_value = RunMacro("TCB Run Operation", 1, "Merge Matrices", Opts) 
    if !ret_value then goto badmerge

Opts = null

     Opts.Input.[Target Currency] = {output_matrix, "Park Node", "Rows", "Columns"}
     Opts.Input.[Source Currencies] = {{park_matrix, "Parking Nodes", "RCIndex", "RCIndex"}}
     Opts.Global.[Missing Option].[Force Missing] = "Yes"

     ret_value = RunMacro("TCB Run Operation", 2, "Merge Matrices", Opts) 
    if !ret_value then goto badmerge


/////////////////////////////////////////////////////////////////////////////////////////////////////
// Write the control file and batch file

//    exist = GetFileInfo(METDir + "\\pgm\\ModeChoice\\UPD_DA_Dist_Time_Costv2.exe")
//    if (exist = null) then goto nofortran
    
//    ctlname = Dir + "\\skims\\Test.ctl"
//    exist = GetFileInfo(ctlname)
//    if (exist <> null) then DeleteFile(ctlname)
 
// replace backslash "\" in ctl file filenames with forward slash "/" - Manish had a 
//  different method - but it won't work with longer file names , not sure why it needs it either, but it seems to. JWM - 11/2015

    // dirparse = parsestring(Dir, "\\")
    // DirSlash = dirparse[1]
    // for i = 2 to dirparse.length do
    //     DirSlash = DirSlash + "//" + dirparse[i]
    // end
    DirSlash = Dir
  
 
//  ctl = OpenFile(ctlname, "w")
     odmtx = DirSlash + "//Skims//"+period+transit_mode+"_DADist.MTX"
//  WriteLine(ctl, DirSlash + "//Skims//"+time_period+transit_mode+"_DADist.MTX")
    if (period = "peak") then do
        if (transit_mode="premium") then do
               opmtx = DirSlash + "//Skims//skim_pnr_peak_prm.mtx"
               pdmtx = DirSlash + "//Skims//skim_pnr2dest_peak_prm.mtx"
//          WriteLine(ctl, DirSlash + "//Skims//skim_pnr_peak_prm.mtx")
//          WriteLine(ctl, DirSlash + "//Skims//skim_pnr2dest_peak_prm.mtx")
        end

        if (transit_mode="bus") then do
               opmtx = DirSlash + "//Skims//skim_pnr_peak_bus.mtx"
               pdmtx = DirSlash + "//Skims//skim_pnr2dest_peak_bus.mtx"

//          WriteLine(ctl, DirSlash + "//Skims//skim_pnr_peak_bus.mtx")
//          WriteLine(ctl, DirSlash + "//Skims//skim_pnr2dest_peak_bus.mtx")
        end

        //      loc2=substring(Location[2],2,StringLength(Location[2])-2)
        //      if (transit_mode="premium2") then do
        //          WriteLine(ctl, Location[1]+"//"+loc2+"//"+Location[3]+"//Skims//skim_pnr_peak_prm2.mtx")
        //          WriteLine(ctl, Location[1]+"//"+loc2+"//"+Location[3]+"//Skims//skim_pnr2dest_peak_prm2.mtx")
        //      end
        //      if (transit_mode="premium3") then do
        //          WriteLine(ctl, Location[1]+"//"+loc2+"//"+Location[3]+"//Skims//skim_pnr_peak_prm2.mtx")
        //          WriteLine(ctl, Location[1]+"//"+loc2+"//"+Location[3]+"//Skims//skim_pnr2dest_peak_prm2.mtx")
        //      end

    end  // time_period = peak
    
    else if (period="offpeak") then do
        if (transit_mode="premium") then do
               opmtx = DirSlash + "//Skims//skim_pnr_offpeak_prm.mtx"
               pdmtx = DirSlash + "//Skims//skim_pnr2dest_offpeak_prm.mtx"
          
//          WriteLine(ctl, DirSlash + "//Skims//skim_pnr_offpeak_prm.mtx")
//          WriteLine(ctl, DirSlash + "//Skims//skim_pnr2dest_offpeak_prm.mtx")
        end

        if (transit_mode="bus") then do
               opmtx = DirSlash + "//Skims//skim_pnr_offpeak_bus.mtx"
               pdmtx = DirSlash + "//Skims//skim_pnr2dest_offpeak_bus.mtx"
          
//          WriteLine(ctl, DirSlash + "//Skims//skim_pnr_offpeak_bus.mtx")
//          WriteLine(ctl, DirSlash + "//Skims//skim_pnr2dest_offpeak_bus.mtx")
        end

        //      if (transit_mode="premium2") then do
        //          WriteLine(ctl, Location[1]+"//"+loc2+"//"+Location[3]+"//Skims//skim_pnr_offpeak_prm2.mtx")
        //          WriteLine(ctl, Location[1]+"//"+loc2+"//"+Location[3]+"//Skims//skim_pnr2dest_offpeak_prm2.mtx")
        //      end
        //      if (transit_mode="premium3") then do
        //          WriteLine(ctl, Location[1]+"//"+loc2+"//"+Location[3]+"//Skims//skim_pnr_offpeak_prm2.mtx")
        //          WriteLine(ctl, Location[1]+"//"+loc2+"//"+Location[3]+"//Skims//skim_pnr2dest_offpeak_prm2.mtx")
        //      end

    end  // time_period = offpeak

     RunMacro("RunDADist2", odmtx, opmtx, pdmtx)
//  CloseFile(ctl)

//  batchname= Dir + "\\skims\\update_cost_dist.bat"
  
//  exist = GetFileInfo(batchname)
//  if (exist <> null) then DeleteFile(batchname)
//      bat = OpenFile(batchname, "w")

//  WriteLine(bat, METDir + "\\pgm\\ModeChoice\\UPD_DA_Dist_Time_Costv2.exe " + ctlname)
//  CloseFile(bat)

//  FortInfo = GetFileInfo(METDir + "\\Pgm\\ModeChoice\\UPD_DA_Dist_Time_Costv2.exe")
//  TimeStamp = FortInfo[7] + " " + FortInfo[8]
//  AppendToLogFile(2, "Update_Drive_Skims call to fortran: pgm=\\ModeChoice\\UPD_DA_Dist_Time_Costv2.exe, timestamp: " + TimeStamp)

    // Run Fortran program UPD_DA_Dist_Time_Costv2
//  status = RunProgram(batchname,{{"Maximize", "True"}})
//  if (status <> 0) then goto badfortran
     
    input_matrix = updmtx
    if (transit_mode="premium") then do

        // Nullify paths with PNR to Destination distance less then 2.0 miles
    Opts = null

     Opts.Input.[Target Currency] = { updmtx, "In-Veh Time", "Rows", "Columns"}
     Opts.Input.[Source Currencies] = {{modesplit_matrix, "IVTT - Prem Drive", "Rows", "Columns"}}
     Opts.Global.[Missing Option].[Force Missing] = "Yes"

     ret_value = RunMacro("TCB Run Operation", 3, "Merge Matrices", Opts) 
    if !ret_value then goto badmerge
     
     Opts=null

     Opts = {{"Input",    {{"Matrix Currency",   {updmtx,
                                                  "In-Veh Time",
                                                  "Rows",
                                                  "Columns"}}}},
             {"Global",   {{"Method",            11},
                           {"Cell Range",        2},
               {"Matrix K",          {1,
                          1}},
                           {"Expression Text",   "if [PNR 2 Dest Length] > 2.0 then [In-Veh Time] else null"},
                           {"Force Missing",     "Yes"}}}}

     ret_value = RunMacro("TCB Run Operation", 4, "Fill Matrices", Opts)
    if !ret_value then goto badfill
     Opts = null

     Opts.Input.[Target Currency] = { modesplit_matrix, "IVTT - Prem Drive", "Rows", "Columns"}
     Opts.Input.[Source Currencies] = {{input_matrix, "In-Veh Time", "Rows", "Columns"}}
     Opts.Global.[Missing Option].[Force Missing] = "Yes"

     ret_value = RunMacro("TCB Run Operation", 5, "Merge Matrices", Opts) 
    if !ret_value then goto badmerge

////////

// Subtract PNR cost equivalent minutes from origin to parking time. The parking cost in $ is already added to the cost table.
     Opts = null

     Opts.Input.[Target Currency] = { updmtx, "OP Time", "Rows", "Columns"}
     Opts.Input.[Source Currencies] = {{modesplit_matrix, "Drive Access Time - Prem Drive", "Rows", "Columns"}}
     Opts.Global.[Missing Option].[Force Missing] = "Yes"

     ret_value = RunMacro("TCB Run Operation", 6, "Merge Matrices", Opts) 
    if !ret_value then goto badmerge

     Opts=null
     if(period="peak") then exp_txt="[OP Time]-([OP Cost]*0.05)"
     if(period="offpeak") then exp_txt="[OP Time]-([OP Cost]*0.05/2.58)"

     Opts = {{"Input",    {{"Matrix Currency",   {updmtx,
                                                  "OP Time",
                                                  "Rows",
                                                  "Columns"}}}},
             {"Global",   {{"Method",            11},
                           {"Cell Range",        2},
               {"Matrix K",          {1,
                          1}},
                           {"Expression Text",   exp_txt},
                           {"Force Missing",     "Yes"}}}}

     ret_value = RunMacro("TCB Run Operation", 7, "Fill Matrices", Opts)
    if !ret_value then goto badfill


     Opts = null

     Opts.Input.[Target Currency] = { modesplit_matrix, "Drive Access Time - Prem Drive", "Rows", "Columns"}
     Opts.Input.[Source Currencies] = {{input_matrix, "OP Time", "Rows", "Columns"}}
     Opts.Global.[Missing Option].[Force Missing] = "Yes"

     ret_value = RunMacro("TCB Run Operation", 8, "Merge Matrices", Opts) 
    if !ret_value then goto badmerge

////////
     Opts = null

     Opts.Input.[Target Currency] = { modesplit_matrix, "Cost - Prem Drive", "Rows", "Columns"}
     Opts.Input.[Source Currencies] = {{input_matrix, "Cost", "Rows", "Columns"}}
     Opts.Global.[Missing Option].[Force Missing] = "Yes"

     ret_value = RunMacro("TCB Run Operation", 9, "Merge Matrices", Opts) 
    if !ret_value then goto badmerge

     Opts = null

     Opts.Input.[Target Currency] = { modesplit_matrix, "Drive Access Distance - Prem Drive", "Rows", "Columns"}
     Opts.Input.[Source Currencies] = {{input_matrix, "Drive Length", "Rows", "Columns"}}
     Opts.Global.[Missing Option].[Force Missing] = "Yes"

     ret_value = RunMacro("TCB Run Operation", 10, "Merge Matrices", Opts) 
    if !ret_value then goto badmerge

     Opts = null

     Opts.Input.[Target Currency] = { modesplit_matrix, "Highway OP Time - Prem Drive", "Rows", "Columns"}
     Opts.Input.[Source Currencies] = {{input_matrix, "Actual Drive Time", "Rows", "Columns"}}
     Opts.Global.[Missing Option].[Force Missing] = "Yes"

     ret_value = RunMacro("TCB Run Operation", 11, "Merge Matrices", Opts) 
        if !ret_value then goto badmerge
    end

    if (transit_mode="premium2") then do

// Nullify paths with PNR to Destination distance less then 2.0 miles
     Opts = null

     Opts.Input.[Target Currency] = { updmtx, "In-Veh Time", "Rows", "Columns"}
     Opts.Input.[Source Currencies] = {{modesplit_matrix, "IVTT - Prem2 Drive", "Rows", "Columns"}}
     Opts.Global.[Missing Option].[Force Missing] = "Yes"

     ret_value = RunMacro("TCB Run Operation", 12, "Merge Matrices", Opts) 
    if !ret_value then goto badmerge
     
     Opts=null

     Opts = {{"Input",    {{"Matrix Currency",   {updmtx,
                                                  "In-Veh Time",
                                                  "Rows",
                                                  "Columns"}}}},
             {"Global",   {{"Method",            11},
                           {"Cell Range",        2},
               {"Matrix K",          {1,
                          1}},
                           {"Expression Text",   "if [PNR 2 Dest Length] > 2.0 then [In-Veh Time] else null"},
                           {"Force Missing",     "Yes"}}}}

     ret_value = RunMacro("TCB Run Operation", 13, "Fill Matrices", Opts)
    if !ret_value then goto badfill

     Opts = null

     Opts.Input.[Target Currency] = { modesplit_matrix, "IVTT - Prem2 Drive", "Rows", "Columns"}
     Opts.Input.[Source Currencies] = {{input_matrix, "In-Veh Time", "Rows", "Columns"}}
     Opts.Global.[Missing Option].[Force Missing] = "Yes"

     ret_value = RunMacro("TCB Run Operation", 14, "Merge Matrices", Opts) 
    if !ret_value then goto badmerge
////////
// Subtract PNR cost equivalent minutes from origin to parking time. The parking cost in $ is already added to the cost table.
     Opts = null

     Opts.Input.[Target Currency] = { updmtx, "OP Time", "Rows", "Columns"}
     Opts.Input.[Source Currencies] = {{modesplit_matrix, "Drive Access Time - Prem2 Drive", "Rows", "Columns"}}
     Opts.Global.[Missing Option].[Force Missing] = "Yes"

     ret_value = RunMacro("TCB Run Operation", 15, "Merge Matrices", Opts) 
    if !ret_value then goto badmerge

     Opts=null
     if(period="peak") then exp_txt="[OP Time]-([OP Cost]*0.05)"
     if(period="offpeak") then exp_txt="[OP Time]-([OP Cost]*0.05/2.58)"

     Opts = {{"Input",    {{"Matrix Currency",   {updmtx,
                                                  "OP Time",
                                                  "Rows",
                                                  "Columns"}}}},
             {"Global",   {{"Method",            11},
                           {"Cell Range",        2},
               {"Matrix K",          {1,
                          1}},
                           {"Expression Text",   exp_txt},
                           {"Force Missing",     "Yes"}}}}

     ret_value = RunMacro("TCB Run Operation", 16, "Fill Matrices", Opts)
    if !ret_value then goto badfill
     Opts = null

     Opts.Input.[Target Currency] = { modesplit_matrix, "Drive Access Time - Prem2 Drive", "Rows", "Columns"}
     Opts.Input.[Source Currencies] = {{input_matrix, "OP Time", "Rows", "Columns"}}
     Opts.Global.[Missing Option].[Force Missing] = "Yes"

     ret_value = RunMacro("TCB Run Operation", 17, "Merge Matrices", Opts) 
    if !ret_value then goto badmerge

////////
     
     Opts = null

     Opts.Input.[Target Currency] = { modesplit_matrix, "Cost - Prem2 Drive", "Rows", "Columns"}
     Opts.Input.[Source Currencies] = {{input_matrix, "Cost", "Rows", "Columns"}}
     Opts.Global.[Missing Option].[Force Missing] = "Yes"

     ret_value = RunMacro("TCB Run Operation", 18, "Merge Matrices", Opts) 
    if !ret_value then goto badmerge

     Opts = null

     Opts.Input.[Target Currency] = { modesplit_matrix, "Drive Access Distance - Prem2 Drive", "Rows", "Columns"}
     Opts.Input.[Source Currencies] = {{input_matrix, "Drive Length", "Rows", "Columns"}}
     Opts.Global.[Missing Option].[Force Missing] = "Yes"

     ret_value = RunMacro("TCB Run Operation", 19, "Merge Matrices", Opts) 
    if !ret_value then goto badmerge

     Opts = null

     Opts.Input.[Target Currency] = { modesplit_matrix, "Highway OP Time - Prem2 Drive", "Rows", "Columns"}
     Opts.Input.[Source Currencies] = {{input_matrix, "Actual Drive Time", "Rows", "Columns"}}
     Opts.Global.[Missing Option].[Force Missing] = "Yes"

     ret_value = RunMacro("TCB Run Operation", 20, "Merge Matrices", Opts) 
     if !ret_value then goto badmerge
    end

    if (transit_mode="premium3") then do

// Nullify paths with PNR to Destination distance less then 2.0 miles
     Opts = null

     Opts.Input.[Target Currency] = { updmtx, "In-Veh Time", "Rows", "Columns"}
     Opts.Input.[Source Currencies] = {{modesplit_matrix, "IVTT - Prem2 Drive", "Rows", "Columns"}}
     Opts.Global.[Missing Option].[Force Missing] = "Yes"

     ret_value = RunMacro("TCB Run Operation", 21, "Merge Matrices", Opts) 
    if !ret_value then goto badmerge
     
     Opts=null

     Opts = {{"Input",    {{"Matrix Currency",   {updmtx,
                                                  "In-Veh Time",
                                                  "Rows",
                                                  "Columns"}}}},
             {"Global",   {{"Method",            11},
                           {"Cell Range",        2},
               {"Matrix K",          {1,
                          1}},
                           {"Expression Text",   "if [PNR 2 Dest Length] > 2.0 then [In-Veh Time] else null"},
                           {"Force Missing",     "Yes"}}}}

     ret_value = RunMacro("TCB Run Operation", 22, "Fill Matrices", Opts)
    if !ret_value then goto badfill
     Opts = null

     Opts.Input.[Target Currency] = { modesplit_matrix, "IVTT - Prem2 Drive", "Rows", "Columns"}
     Opts.Input.[Source Currencies] = {{input_matrix, "In-Veh Time", "Rows", "Columns"}}
     Opts.Global.[Missing Option].[Force Missing] = "Yes"

     ret_value = RunMacro("TCB Run Operation", 23, "Merge Matrices", Opts) 
    if !ret_value then goto badmerge
////////
// Subtract PNR cost equivalent minutes from origin to parking time. The parking cost in $ is already added to the cost table.
     Opts = null

     Opts.Input.[Target Currency] = { updmtx, "OP Time", "Rows", "Columns"}
     Opts.Input.[Source Currencies] = {{modesplit_matrix, "Drive Access Time - Prem2 Drive", "Rows", "Columns"}}
     Opts.Global.[Missing Option].[Force Missing] = "Yes"

     ret_value = RunMacro("TCB Run Operation", 24, "Merge Matrices", Opts) 
    if !ret_value then goto badmerge

     Opts=null
     if(period="peak") then exp_txt="[OP Time]-([OP Cost]*0.05)"
     if(period="offpeak") then exp_txt="[OP Time]-([OP Cost]*0.05/2.58)"

     Opts = {{"Input",    {{"Matrix Currency",   {updmtx,
                                                  "OP Time",
                                                  "Rows",
                                                  "Columns"}}}},
             {"Global",   {{"Method",            11},
                           {"Cell Range",        2},
               {"Matrix K",          {1,
                          1}},
                           {"Expression Text",   exp_txt},
                           {"Force Missing",     "Yes"}}}}

     ret_value = RunMacro("TCB Run Operation", 25, "Fill Matrices", Opts)
    if !ret_value then goto badfill
     Opts = null

     Opts.Input.[Target Currency] = { modesplit_matrix, "Drive Access Time - Prem2 Drive", "Rows", "Columns"}
     Opts.Input.[Source Currencies] = {{input_matrix, "OP Time", "Rows", "Columns"}}
     Opts.Global.[Missing Option].[Force Missing] = "Yes"

     ret_value = RunMacro("TCB Run Operation", 26, "Merge Matrices", Opts) 
    if !ret_value then goto badmerge

////////
     
     Opts = null

     Opts.Input.[Target Currency] = { modesplit_matrix, "Cost - Prem2 Drive", "Rows", "Columns"}
     Opts.Input.[Source Currencies] = {{input_matrix, "Cost", "Rows", "Columns"}}
     Opts.Global.[Missing Option].[Force Missing] = "Yes"

     ret_value = RunMacro("TCB Run Operation", 27, "Merge Matrices", Opts) 
    if !ret_value then goto badmerge

     Opts = null

     Opts.Input.[Target Currency] = { modesplit_matrix, "Drive Access Distance - Prem2 Drive", "Rows", "Columns"}
     Opts.Input.[Source Currencies] = {{input_matrix, "Drive Length", "Rows", "Columns"}}
     Opts.Global.[Missing Option].[Force Missing] = "Yes"

     ret_value = RunMacro("TCB Run Operation", 28, "Merge Matrices", Opts) 
    if !ret_value then goto badmerge

     Opts = null

     Opts.Input.[Target Currency] = { modesplit_matrix, "Highway OP Time - Prem2 Drive", "Rows", "Columns"}
     Opts.Input.[Source Currencies] = {{input_matrix, "Actual Drive Time", "Rows", "Columns"}}
     Opts.Global.[Missing Option].[Force Missing] = "Yes"

     ret_value = RunMacro("TCB Run Operation", 29, "Merge Matrices", Opts) 
    if !ret_value then goto badmerge
    end

    if (transit_mode="bus") then do

// Nullify paths with PNR to Destination distance less then 2.0 miles
     Opts = null

     Opts.Input.[Target Currency] = { updmtx, "In-Veh Time", "Rows", "Columns"}
     Opts.Input.[Source Currencies] = {{modesplit_matrix, "IVTT - Bus Drive", "Rows", "Columns"}}
     Opts.Global.[Missing Option].[Force Missing] = "Yes"

     ret_value = RunMacro("TCB Run Operation", 30, "Merge Matrices", Opts) 
    if !ret_value then goto badmerge
     
     Opts=null

     Opts = {{"Input",    {{"Matrix Currency",   {updmtx,
                                                  "In-Veh Time",
                                                  "Rows",
                                                  "Columns"}}}},
             {"Global",   {{"Method",            11},
                           {"Cell Range",        2},
               {"Matrix K",          {1,
                          1}},
                           {"Expression Text",   "if [PNR 2 Dest Length] > 2.0 then [In-Veh Time] else null"},
                           {"Force Missing",     "Yes"}}}}

     ret_value = RunMacro("TCB Run Operation",31, "Fill Matrices", Opts)
    if !ret_value then goto badfill
     Opts = null

     Opts.Input.[Target Currency] = { modesplit_matrix, "IVTT - Bus Drive", "Rows", "Columns"}
     Opts.Input.[Source Currencies] = {{input_matrix, "In-Veh Time", "Rows", "Columns"}}
     Opts.Global.[Missing Option].[Force Missing] = "Yes"

     ret_value = RunMacro("TCB Run Operation", 32, "Merge Matrices", Opts) 
    if !ret_value then goto badmerge
////////
// Subtract PNR cost equivalent minutes from origin to parking time. The parking cost in $ is already added to the cost table.
     Opts = null

     Opts.Input.[Target Currency] = { updmtx, "OP Time", "Rows", "Columns"}
     Opts.Input.[Source Currencies] = {{modesplit_matrix, "Drive Access Time - Bus Drive", "Rows", "Columns"}}
     Opts.Global.[Missing Option].[Force Missing] = "Yes"

     ret_value = RunMacro("TCB Run Operation", 33, "Merge Matrices", Opts) 
    if !ret_value then goto badmerge

     Opts=null
     if(period="peak") then exp_txt="[OP Time]-([OP Cost]*0.05)"
     if(period="offpeak") then exp_txt="[OP Time]-([OP Cost]*0.05/2.58)"

     Opts = {{"Input",    {{"Matrix Currency",   {updmtx,
                                                  "OP Time",
                                                  "Rows",
                                                  "Columns"}}}},
             {"Global",   {{"Method",            11},
                           {"Cell Range",        2},
               {"Matrix K",          {1,
                          1}},
                           {"Expression Text",   exp_txt},
                           {"Force Missing",     "Yes"}}}}

     ret_value = RunMacro("TCB Run Operation", 34, "Fill Matrices", Opts)
    if !ret_value then goto badfill
     Opts = null

     Opts.Input.[Target Currency] = { modesplit_matrix, "Drive Access Time - Bus Drive", "Rows", "Columns"}
     Opts.Input.[Source Currencies] = {{input_matrix, "OP Time", "Rows", "Columns"}}
     Opts.Global.[Missing Option].[Force Missing] = "Yes"

     ret_value = RunMacro("TCB Run Operation", 35, "Merge Matrices", Opts) 
    if !ret_value then goto badmerge

////////
     
     Opts = null

     Opts.Input.[Target Currency] = { modesplit_matrix, "Cost - Bus Drive", "Rows", "Columns"}
     Opts.Input.[Source Currencies] = {{input_matrix, "Cost", "Rows", "Columns"}}
     Opts.Global.[Missing Option].[Force Missing] = "Yes"

     ret_value = RunMacro("TCB Run Operation", 36, "Merge Matrices", Opts) 
    if !ret_value then goto badmerge

     Opts = null

     Opts.Input.[Target Currency] = { modesplit_matrix, "Drive Access Distance - Bus Drive", "Rows", "Columns"}
     Opts.Input.[Source Currencies] = {{input_matrix, "Drive Length", "Rows", "Columns"}}
     Opts.Global.[Missing Option].[Force Missing] = "Yes"

     ret_value = RunMacro("TCB Run Operation", 37, "Merge Matrices", Opts) 
    if !ret_value then goto badmerge

     Opts = null

     Opts.Input.[Target Currency] = { modesplit_matrix, "Highway OP Time - Bus Drive", "Rows", "Columns"}
     Opts.Input.[Source Currencies] = {{input_matrix, "Actual Drive Time", "Rows", "Columns"}}
     Opts.Global.[Missing Option].[Force Missing] = "Yes"

     ret_value = RunMacro("TCB Run Operation", 38, "Merge Matrices", Opts) 
    if !ret_value then goto badmerge
    end

//  
///////////////////////////////////////////
goto quit
done:

    badmerge:
    Throw("Update_Drive_Skim_Mtx - Error merging matrices")
     // Throw("Update_Drive_Skim_Mtx - Error merging matrices")
    // AppendToLogFile(2, "Update_Drive_Skim_Mtx - Error merging matrices")
    // goto badquit

    badfill:
     Throw("Update_Drive_Skim_Mtx - Error filling matrices")
    // Throw("Update_Drive_Skim_Mtx - Error filling matrices")
    // AppendToLogFile(2, "Update_Drive_Skim_Mtx - Error filling matrices")
    // goto badquit

    nofortran:
     Throw("Update_Drive_Skim_Mtx - Program Update_Drive_Skims_Mtx missing")
    // Throw("Update_Drive_Skim_Mtx - Program Update_Drive_Skims_Mtx missing")
    // AppendToLogFile(2, "Update_Drive_Skim_Mtx - Program Update_Drive_Skims_Mtx missing")
    // goto badquit

    badfortran:
     Throw("Update_Drive_Skims_Mtx - error return from \\ModeChoice\\UPD_DA_Dist_Time_Costv2 !")
    // Throw("Update_Drive_Skims_Mtx - error return from \\ModeChoice\\UPD_DA_Dist_Time_Costv2 !")
    // AppendToLogFile(2, "Update_Drive_Skims_Mtx - error return from \\ModeChoice\\UPD_DA_Dist_Time_Costv2 !")
    // goto badquit

    badquit:
    RunMacro("TCB Closing", 0, "TRUE" ) 
    UpdateDriveSkimOK = 0
    goto quit
    
quit:

    datentime = GetDateandTime()
    AppendToLogFile(2, "Exit Update_Drive_Skim_Mtx: " + datentime)
    AppendToLogFile(1, " ")

    return({UpdateDriveSkimOK, msg})

endMacro

macro "RunDADist2" (odmtx, opmtx, pdmtx)
    od = CreateObject("Matrix", odmtx, {MemoryOnly: true})
    op = CreateObject("Matrix", opmtx, {MemoryOnly: true})
    pd = CreateObject("Matrix", pdmtx, {MemoryOnly: true})
    tmp1 = GetTempFileName("*.bin")

    od.ExportToTable({OutputMode: "Tables", FileName: tmp1, Cores: "Park Node"})
    odt = CreateObject("Table", tmp1)
    odtx = odt.GetView()
    export_opts = {{"Additional Fields",                                            // elseif (PrdHr_DEP<{BegPrd_PM_HWY})  RO.TRIP_MD   = 1
            {{"ODP", "string", 16, , "false", },
             {"OPD", "string", 16, , "false", }
            }}}

    odtm = ExportView(odtx+"|", "MEM", "InMem2",,export_opts)
    {o,p,d} = GetDataVectors(odtm+"|", {"Rows", "Park Node", "Columns"},)
    opstr = String(o) + ":" + String(R2I(p))
    pdstr = String(R2I(p)) + ":" + String(d)
    SetDataVector(odtm + "|", "ODP", opstr,)
    SetDataVector(odtm + "|", "OPD", pdstr,)
    tmp2 = GetTempFileName("*.bin")
    op.ExportToTable({OutputMode: "Tables", FileName: tmp2})
    opcores = op.GetCoreNames()
    oplen = opcores[2]
    optime = opcores[3]

    opt = CreateObject("Table", tmp2)
    opt.RenameField({FieldName: oplen, NewName: "OPLength"})
    opt.RenameField({FieldName: optime, NewName: "OPTime"})
    optx = opt.GetView()
    export_opts = {{"Additional Fields",                                            // elseif (PrdHr_DEP<{BegPrd_PM_HWY})  RO.TRIP_MD   = 1
            {{"OP", "string", 16, , "false", }
            }}}

    optm = ExportView(optx+"|", "MEM", "InMem3",,export_opts)
    {o,d} = GetDataVectors(optm+"|", {"Origin", "Destination"},)
    odstr = String(o) + ":" + String(d)
    SetDataVector(optm + "|", "OP", odstr,)
    tmp3 = GetTempFileName("*.bin")
    pd.ExportToTable({OutputMode: "Tables", FileName: tmp3})
    pdt = CreateObject("Table", tmp3)
    pdt.RenameField({FieldName: "Length (Skim)", NewName: "PDLength"})
    pdtx = pdt.GetView()
    export_opts = {{"Additional Fields",                                            // elseif (PrdHr_DEP<{BegPrd_PM_HWY})  RO.TRIP_MD   = 1
            {{"PD", "string", 16, , "false", }
            }}}
    pdtm = ExportView(pdtx+"|", "MEM", "InMem4",,export_opts)
    {o,d} = GetDataVectors(pdtm+"|", {"Origin", "Destination"},)
    odstr = String(o) + ":" + String(d)
    SetDataVector(pdtm + "|", "PD", odstr,)
    jv1 = JoinViews("jv", odtm + ".ODP", optm + ".OP",)
    jv1x = ExportView(jv1+"|", "MEM" , "InMem5",,)
    jv2 = JoinViews("jv2", jv1x + ".OPD", pdtm + ".PD",)
    jvtm = ExportView(jv2+"|", "MEM", "InMem6",,)
    {jvflds,} = GetFields(jvtm, "All")
    od = null
    od = CreateObject("Matrix", odmtx)
    mhandle = od.GetMatrixHandle()

    UpdateCores = {null, "OPLength", null, "OPTime", "PDLength", null, null, "PNR_Cost"}
    UpdateMatrixFromView(mhandle, jvtm + "|", jvflds[1], jvflds[2], , UpdateCores, "Replace",) // fill in class number in matrix
    od.Cost := if od.Cost > 0 and od.[Drive Length] > 0 then 100 * od.Cost + 10 * od.[Drive Length] + 0.5 * od.[OP Cost] else null
    CloseView(jvtm)
    CloseView(jv2)
    CloseView(jv1x)
    CloseView(jv1)
    CloseView(pdtm)
    CloseView(optm)
    CloseView(odtm)

endmacro