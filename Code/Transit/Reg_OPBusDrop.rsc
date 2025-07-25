Macro "Reg_OPBusDrop" (Args)

// Modified for new UI - Nov, 2015 - McLelland
// Commented out pkzip for skim file and delete - (lines 542+)
// 5/30/19, mk: There are now three distinct networks, use offpeak since was used to setup route system

    // LogFile = Args.[Log File].value
    // ReportFile = Args.[Report File].value
    // SetLogFileName(LogFile)
    // SetReportFileName(ReportFile)

    METDir = Args.[MET Directory]
    Dir = Args.[Run Directory]
    taz_file = Args.[TAZ File]
    theyear = Args.[Run Year]
    //hwy_file = Args.[Offpeak Hwy Name]
    hwy_file = Args.[Hwy Name]
    {, , netname, } = SplitPath(hwy_file)
        
    msg = null
    RegOPBusDropOK = 1
    datentime = GetDateandTime()
    AppendToLogFile(1, "Enter Reg_OPBusDrop: " + datentime)

    shared route_file, routename, net_file, link_lyr, node_lyr, nodes_view

    yearnet = Substring(theyear, 3, 2)
    analysis_year = yearnet

    //  Invoke "XPR_StopFlags" macro to flag express stops as board/alight only and premium stops
    //  Enable stop access coding for modes 5 and 6 for use with TransCAD5, JainM, 07.20.08
    //  Updated for TransCad7, McLelland 09.12.16
    //  Returns 1 for clean run, 2 for warning about flags (run continues), 3 for fatal error 

    stopflagrtn = RunMacro("XPR_StopFlags", Args)
    rtnerr = stopflagrtn[1]
    rtnmsg = stopflagrtn[2]
    
    if runerr = 3 
        then goto badxpr_stopflags

    if runerr = 2
        then do
            Throw(rtnmsg)
            // Throw(rtnmsg)
            // AppendToLogFile(2, rtnmsg)
        end


    //-- Set up the network names

    routename = "TranSys"

    route_file = Dir + "\\"+routename+".rts"
    net_file = Dir + "\\"+netname+".dbd"

    ModifyRouteSystem(route_file, {{"Geography", net_file, netname},{"Link ID", "ID"}})


    // Get the scope of a geographic file

    info = GetDBInfo(net_file)
    scope = info[1]

    // Create a map using this scope
    CreateMap(net, {{"Scope", scope},{"Auto Project", "True"}})
    layers = GetDBLayers(net_file)
    node_lyr = addlayer(net, layers[1], net_file, layers[1])
    link_lyr = addlayer(net, layers[2], net_file, layers[2])
    rtelyr = AddRouteSystemLayer(net, "Vehicle Routes", route_file, )
    RunMacro("Set Default RS Style", rtelyr, "TRUE", "TRUE")
    SetLayerVisibility(node_lyr, "False")
    SetIcon(node_lyr + "|", "Font Character", "Caliper Cartographic|4", 36)
    SetIcon("Route Stops|", "Font Character", "Caliper Cartographic|4", 36)
    SetLayerVisibility(link_lyr, "True")
    solid = LineStyle({{{1, -1, 0}}})
    SetLineStyle(link_lyr+"|", solid)
    SetLineColor(link_lyr+"|", ColorRGB(0, 0, 32000))
    SetLineWidth(link_lyr+"|", 0)
    SetLayerVisibility("Route Stops", "False")

//--------------------------------- Joining Node Layer with Station Database-----------------------------------

on notfound default
setview(node_lyr)

opentable("STATION_DATABASE", "DBASE", {Dir + "\\STATION_DATABASE.dbf",})

nodes_view = joinviews("Nodes+Stations", node_lyr + ".ID", "STATION_DATABASE.ID",)


on notfound default
setview("Vehicle Routes")


// ----------------------------------- STEP 1: Build Transit Network  -----------------------------------

    RunMacro("TCB Init")

    Opts = RunMacro("create_tnet", "offpeak", "bus", "dropoff", Dir)
    ret_value = RunMacro("TCB Run Operation", 1, "Build Transit Network", Opts) 

    if !ret_value then goto badbuildtrannet

// Call macro Compute_OP_Matrix to create Origin-to-DropOff Node Time matrix
// added by JainM March 07

    rtn_OP = RunMacro("Compute_OP_Matrix", "offpeak", "bus", "dropoff", Args)
    if rtn_OP[1] = 0
        then do
            Throw(rtn_OP[2])
            // msg = msg + rtn_OP[2]
            // goto badcomputeopmatrix
        end

//////
// ----------------------------------- STEP 2: Transit Network Setting  -----------------------------------


    Opts = RunMacro("set_tnet", "offpeak", "bus", "dropoff", Dir)
    tnwOpts=Opts

        ret_value = RunMacro("TCB Run Operation", 2, "Transit Network Setting PF", Opts)

    if !ret_value then goto badtransettings

// ----------------------------------- STEP 3a: Transit Skim Path Finder  -----------------------------------

  
     Opts = null
     Opts.Input.Database = net_file 
     Opts.Input.[Transit RS] = route_file
     Opts.Input.Network = Dir + "\\OPBusDrop.tnw"
     Opts.Input.[Origin Set] = {net_file + "|" + node_lyr, node_lyr,"Centroids","Select * where centroid = 1 or [External Station] = 1"}
     Opts.Input.[Destination Set] = {net_file + "|" + node_lyr, node_lyr,"Centroids"}
     Opts.Global.[Skim Var] = {"Generalized Cost", "Fare", "In-Vehicle Time", "Initial Wait Time", "Transfer Wait Time", "Transfer Penalty Time", "Transfer Walk Time", "Access Walk Time", "Egress Walk Time", "Access Drive Time", "Dwelling Time", "Number of Transfers", "In-Vehicle Distance", "Access Drive Distance", "Length", "TTWalk*"}
     Opts.Global.[OD Layer Type] = 2
     Opts.Global.[Skim Modes] = { 5, 6, 7, 8, 9, 10, 11}
     Opts.Output.[Skim Matrix].Label = "Skim Matrix (Pathfinder)"
     Opts.Output.[Skim Matrix].[File Name] = Dir + "\\skims\\TR_SKIM_OPBusDrop.mtx"
     Opts.Output.[Parking Matrix].Label = "TR_PARK_OPBusDrop"
     Opts.Output.[Parking Matrix].[File Name] = Dir + "\\skims\\TR_PARK_OPBusDrop.mtx"
// -------- Output Origin-to-Drop-Off Time Matrix ---------------
//     Opts.Output.[OP Matrix].Label = "OP Time Matrix (Drop-Off Off-Peak)"
//     Opts.Output.[OP Matrix].[File Name] = Dir + "\\skims\\TR_OP_SKIM_opbusdrop.mtx"

     ret_value = RunMacro("TCB Run Procedure", 3, "Transit Skim PF", Opts)

     if !ret_value then goto badtranskim

// ----------------------------------- STEP 3b: Transit Skim Path Finder (No CBD Drop-Off) ------------------

     tnwOpts.Input.[OP Time Currency] = {Dir + "\\skims\\skim_knr_offpeak_noCBD.mtx", "TTfree*", "Origin", "Destination"}

     ret_value = RunMacro("TCB Run Operation", 4, "Transit Network Setting PF", tnwOpts)
    if !ret_value then goto badtransettings

 
     Opts = null
     Opts.Input.Database = net_file 
     Opts.Input.[Transit RS] = route_file
     Opts.Input.Network = Dir + "\\OPBusDrop.tnw"
     Opts.Input.[Origin Set] = {net_file + "|" + node_lyr, node_lyr,"Centroids","Select * where centroid = 1 or [External Station] = 1"}
     Opts.Input.[Destination Set] = {net_file + "|" + node_lyr, node_lyr,"Centroids"}
     Opts.Global.[Skim Var] = {"Generalized Cost", "Fare", "In-Vehicle Time", "Initial Wait Time", "Transfer Wait Time", "Transfer Penalty Time", "Transfer Walk Time", "Access Walk Time", "Egress Walk Time", "Access Drive Time", "Dwelling Time", "Number of Transfers", "In-Vehicle Distance", "Access Drive Distance", "Length", "TTWalk*"}
     Opts.Global.[OD Layer Type] = 2
     Opts.Global.[Skim Modes] = { 5, 6, 7, 8, 9, 10, 11}
     Opts.Output.[Skim Matrix].Label = "Skim Matrix (Pathfinder)"
     Opts.Output.[Skim Matrix].[File Name] = Dir + "\\skims\\TR_SKIM_OPBusDrop_NoCBD.mtx"
     Opts.Output.[Parking Matrix].Label = "TR_PARK_OPBusDrop"
     Opts.Output.[Parking Matrix].[File Name] = Dir + "\\skims\\TR_PARK_OPBusDrop_NoCBD.mtx"

     ret_value = RunMacro("TCB Run Procedure", 5, "Transit Skim PF", Opts)
    if !ret_value then goto badtranskim

     zone_file=Dir+"\\TAZ_ATYPE.bin"
    
     zone_vw = OpenTable("TAZ_ATYPE", "FFB", {zone_file, })
     setview(zone_vw)
//     CBD_set = "CBD_Set"
//     n_selected=SelectByQuery(CBD_set, "Several", "select * where CBD_FLAG = 2", )

//     if (n_selected >0) then do
//        dim cbd_zone[n_selected]
//        i=0
//  zone_rec = GetFirstRecord (CBD_set, null)
        
//  while zone_rec <> null do
//      i=i+1
//            cbd_zone[i]=s2i(zone_rec)
//            zone_rec = GetNextRecord (CBD_set, null, null)
//      end
    
     matx1 = OpenMatrix(Dir + "\\skims\\TR_SKIM_OPBusDrop.mtx", "FALSE")
     midx1 = GetMatrixIndex(matx1)
     core1 = GetMatrixCoreNames(matx1)

     matx2 = OpenMatrix(Dir + "\\skims\\TR_SKIM_OPBusDrop_NoCBD.mtx", "FALSE")
     midx2 = GetMatrixIndex(matx2)
     core2 = GetMatrixCoreNames(matx2)

     matx3 = OpenMatrix(Dir + "\\skims\\TR_PARK_OPBusDrop.mtx", "FALSE")
     midx3 = GetMatrixIndex(matx3)
     core3 = GetMatrixCoreNames(matx3)

     matx4 = OpenMatrix(Dir + "\\skims\\TR_PARK_OPBusDrop_NoCBD.mtx", "FALSE")
     midx4 = GetMatrixIndex(matx4)
     core4 = GetMatrixCoreNames(matx4)

     cur1 = CreateMatrixCurrency(matx1, core1[1], midx1[1], midx1[2], )
     // Replace CBD Attaction drop-off skims from set without drop-off at CBD option
     rowID           = GetMatrixRowLabels(cur1)
     colID           = GetMatrixColumnLabels(cur1)
     for i=1 to colID.length do
     // identify CBD Attraction zone
        CBDFLG=0
        rh2 = LocateRecord(zone_vw+"|", zone_vw + ".ZONE", {colID[i]}, {{"Exact", "True"}})
        CBDFLG=zone_vw.[CBD_FLAG]
        if (CBDFLG = 2) then do  
            for j1=1 to core1.length do
                cur1 = CreateMatrixCurrency(matx1, core1[j1], midx1[1], midx1[2], )
                cur2 = CreateMatrixCurrency(matx2, core1[j1], midx2[1], midx2[2], )
                v2   = GetMatrixVector(cur2,  {{"Column", StringToInt(colID[i])}})
                SetMatrixVector(cur1, v2, {{"Column", StringToInt(colID[i])}} )
            end
 
            for j2=1 to core3.length do
                cur3 = CreateMatrixCurrency(matx3, core3[j2], midx3[1], midx3[2], )
                cur4 = CreateMatrixCurrency(matx4, core3[j2], midx4[1], midx4[2], )
                v4   = GetMatrixVector(cur4,  {{"Column", StringToInt(colID[i])}})
                SetMatrixVector(cur3, v4, {{"Column", StringToInt(colID[i])}} )
            end
        end
     end
 
//      end
     closeview(zone_vw)
// ----------------------------------- End STEP 3b ----------------------------------------------------------

    // -- Post Process the Drop-Off Skims to split the drive leg and the transit legs.

// --- Fill the Null Values in PARK matrix with Zeroes


    park_matrix = Dir + "\\skims\\TR_PARK_OPBusDrop.mtx"

    OM = OpenMatrix(park_matrix, "True")
    matcores = GetMatrixCoreNames(OM)
    corepos = ArrayPosition(matcores, {"Parking"},)
    if corepos = 0 then addmatrixcore(OM,"Parking")
    c = CreateMatrixCurrency(OM, "Parking",,,)
    c := 0
    c = null

     Opts = null
     Opts.Input.[Target Currency] = {park_matrix, "Parking", "RCIndex", "RCIndex"}
     Opts.Input.[Source Currencies] = {{park_matrix, "Parking Nodes", "RCIndex", "RCIndex"}}
     Opts.Global.[Missing Option].[Force Missing] = "No"

     ret_value = RunMacro("TCB Run Operation", 7, "Merge Matrices", Opts)
     if !ret_value then goto badmatrixop

//  om = OpenMatrix(Dir + "\\skims\\TR_PARK_opbusdrop.mtx", "True")
//  CreateTableFromMatrix(om, Dir + "\\tranassn\\opbusdrop\\pnrnode_opbusdrop.asc", "FFA", {{"Complete", "Yes"}})

    // -- Flag the dropoff stations as

    //   1. DropOffs at Park&Ride Nodes
    //   2. Dropoffs inside the CBD
    //   3. Pseudo DropOffs outside CBD

    rtn_Pflags = RunMacro("Create OPbusDrop Parking Flags", Args)
    if rtn_Pflags[1] = 0 then goto badparkflags


    // Check for local matrix cores (JWM 16.09.16) - add if necessary and initialize to null (clear)
    //  matrix assignment ":=" please see help documentation for "Matrix Assignment Statement"

    OM = OpenMatrix(Dir + "\\skims\\TR_SKIM_OPBusDrop.mtx", "True")

    matcores = GetMatrixCoreNames(OM)
    corepos = ArrayPosition(matcores, {"Total Distance"},)
    if corepos = 0 then addmatrixcore(OM,"Total Distance")
    c = CreateMatrixCurrency(OM, "Total Distance",,,)
    c := null

    corepos = ArrayPosition(matcores, {"IVTT"},)
    if corepos = 0 then addmatrixcore(OM,"IVTT")
    c = CreateMatrixCurrency(OM, "IVTT",,,)
    c := null

    corepos = ArrayPosition(matcores, {"InVehGT5"},)
    if corepos = 0 then addmatrixcore(OM,"InVehGT5")
    c = CreateMatrixCurrency(OM, "InVehGT5",,,)
    c := null

    corepos = ArrayPosition(matcores, {"Approach"},)
    if corepos = 0 then addmatrixcore(OM,"Approach")
    c = CreateMatrixCurrency(OM, "Approach",,,)
    c := null

    corepos = ArrayPosition(matcores, {"Cost"},)
    if corepos = 0 then addmatrixcore(OM,"Cost")
    c = CreateMatrixCurrency(OM, "Cost",,,)
    c := null


    corepos = ArrayPosition(matcores, {"Highway Skim"},)
    if corepos = 0 then addmatrixcore(OM,"Highway Skim")
    c = CreateMatrixCurrency(OM, "Highway Skim",,,)
    c := null

    corepos = ArrayPosition(matcores, {"Park_Flag"},)
    if corepos = 0 then addmatrixcore(OM,"Park_Flag")
    c = CreateMatrixCurrency(OM, "Park_Flag",,,)
    c := null

    corepos = ArrayPosition(matcores, {"Walk Drop Flag"},)
    if corepos = 0 then addmatrixcore(OM,"Walk Drop Flag")
    c = CreateMatrixCurrency(OM, "Walk Drop Flag",,,)
    c := null

    OM = null
    c = null

 //--- include the highway skim matrix as a part of Transit Skim Matrices 

    hwyskim_matrix = Dir + "\\AutoSkims\\SPMAT_free.mtx"

    M1 = OpenMatrix(Dir+"\\skims\\TR_SKIM_OPBusDrop.mtx", "True")
    M2 = OpenMatrix(hwyskim_matrix, "True")

    c1 = CreateMatrixCurrency(M2, "Non HOV Length", "Rows", "Columns",)
    c2 = CreateMatrixCurrency(M1, "Highway Skim", "RCIndex", "RCIndex",)
    MatrixOperations(c2, {c1}, {1},,, {{"Operation", "Add"}, {"Force Missing", "Yes"}})

      c1 = null
      c2 = null
      M1 = null
      M2 = null


// --- Update the Skim Matrix With the Park Flag

    park_matrix = Dir + "\\Skims\\ParkFlag_OPbusDrop.mtx"

    M1 = OpenMatrix(park_matrix, "True")
    M2 = OpenMatrix(Dir+"\\skims\\TR_SKIM_OPBusDrop.mtx", "True")

    c1 = CreateMatrixCurrency(M1, "Parking_Flag", "Rows", "Columns",)
    c2 = CreateMatrixCurrency(M2, "Park_Flag", "RCIndex", "RCIndex",)
    MatrixOperations(c2, {c1}, {1},,, {{"Operation", "Add"}, {"Force Missing", "Yes"}})

    c1 = null
        c2 = null
        M1 = null
        M2 = null

    M1 = OpenMatrix(Dir + "\\skims\\TR_SKIM_OPBusDrop.mtx", "True")
        c1 = CreateMatrixCurrency(M1, "Length (XCM)", "RCIndex", "RCIndex",)
        c2 = CreateMatrixCurrency(M1, "Length (XPR)", "RCIndex", "RCIndex",)
        c3 = CreateMatrixCurrency(M1, "Length (FDR)", "RCIndex", "RCIndex",)
        c4 = CreateMatrixCurrency(M1, "Length (LOC)", "RCIndex", "RCIndex",)
        c5 = CreateMatrixCurrency(M1, "Length (GLD)", "RCIndex", "RCIndex",)
        c11 = CreateMatrixCurrency(M1, "Length (SKS)", "RCIndex", "RCIndex",)
        c6 = CreateMatrixCurrency(M1, "Total Distance", "RCIndex", "RCIndex",)
        MatrixOperations(c6, {c1, c2, c3, c4, c5, c11 }, {1, 1, 1, 1, 1, 1 },,, {{"Operation", "Add"}, {"Force Missing", "No"}})
    c1 = null
    c2 = null
    c3 = null
    c4 = null
    c5 = null
    c6 = null

    M1 = null


if (theyear = "2009") then do

     Opts = {{"Input",    {{"Matrix Currency",   {Dir + "\\skims\\TR_SKIM_OPBusDrop.mtx",
                                                  "InVehGT5",
                                                  "RCIndex",
                                                  "RCIndex"}}}},
             {"Global",   {{"Method",            11},
                           {"Cell Range",        2},
               {"Matrix K",          {1,
                          1}},
             {"Expression Text", "if ((nz([Length (XCM)])+nz([Length (XPR)])+ nz([Length (LOC)])+nz([Length (FDR)])+ nz([Length (SKS)]))> 0.0 and [Highway Skim] > 0.75) then [In-Vehicle Time]"},                     
                {"Force Missing",     "Yes"}}}}

     if !RunMacro("TCB Run Operation", 15, "Fill Matrices", Opts) then goto badmatrixop


//--- include the DropFlag from OPbusW as a part of Transit Skim Matrices 

    opbusw_matrix = Dir + "\\skims\\TR_SKIM_opbusw.mtx"

    M1 = OpenMatrix(opbusw_matrix, "True")
    M2 = OpenMatrix(Dir+"\\skims\\TR_SKIM_OPBusDrop.mtx", "True")

    c1 = CreateMatrixCurrency(M1, "Drop Flag", "RCIndex", "RCIndex",)
    c2 = CreateMatrixCurrency(M2, "Walk Drop Flag", "RCIndex", "RCIndex",)
    MatrixOperations(c2, {c1}, {1},,, {{"Operation", "Add"}, {"Force Missing", "Yes"}})

      c1 = null
      c2 = null
      M1 = null
      M2 = null

// -- If a Walk Access Path was droppped since the path used only the Gold Rush
// -- then delete the drive access path for these interchanges as well

   Opts = {{"Input",    {{"Matrix Currency",   {Dir + "\\skims\\TR_SKIM_OPBusDrop.mtx",
                                                  "IVTT",
                                                  "RCIndex",
                                                  "RCIndex"}}}},
             {"Global",   {{"Method",            11},
                           {"Cell Range",        2},
               {"Matrix K",          {1,
                          1}},
             {"Expression Text", "if ([Walk Drop Flag] = null) then [InVehGT5]"},                     
                {"Force Missing",     "Yes"}}}}

     if !RunMacro("TCB Run Operation", 16, "Fill Matrices", Opts) then goto badmatrixop



end else do

     Opts = {{"Input",    {{"Matrix Currency",   {Dir + "\\skims\\TR_SKIM_OPBusDrop.mtx",
                                                  "InVehGT5",
                                                  "RCIndex",
                                                  "RCIndex"}}}},
             {"Global",   {{"Method",            11},
                           {"Cell Range",        2},
               {"Matrix K",          {1,
                          1}},
             {"Expression Text", "if [Total Distance] > 0.0 and [Highway Skim] > 0.75 then [In-Vehicle Time]"},                     
                {"Force Missing",     "Yes"}}}}

     if !RunMacro("TCB Run Operation", 17, "Fill Matrices", Opts) then goto badmatrixop

end

    M1 = OpenMatrix(Dir + "\\skims\\TR_SKIM_OPBusDrop.mtx", "True")
    c1 = CreateMatrixCurrency(M1, "InVehGT5", "RCIndex", "RCIndex",)
    c2 = CreateMatrixCurrency(M1, "IVTT", "RCIndex", "RCIndex",)
        MatrixOperations(c2, {c1}, {1},,, {{"Operation", "Add"}, {"Force Missing", "Yes"}})
    c2 = null
    c3 = null
    c4 = null
    M1 = null


    M1 = OpenMatrix(Dir + "\\skims\\TR_SKIM_OPBusDrop.mtx", "True")
//  c1 = CreateMatrixCurrency(M1, "Transfer Wait Time", "RCIndex", "RCIndex",)
    c2 = CreateMatrixCurrency(M1, "Transfer Walk Time", "RCIndex", "RCIndex",)
    c3 = CreateMatrixCurrency(M1, "Access Walk Time", "RCIndex", "RCIndex",)
    c4 = CreateMatrixCurrency(M1, "Egress Walk Time", "RCIndex", "RCIndex",)
    c5 = CreateMatrixCurrency(M1, "Approach", "RCIndex", "RCIndex",)
        MatrixOperations(c5, {c2, c3, c4}, {1, 1, 1},,, {{"Operation", "Add"}, {"Force Missing", "No"}})
    c1 = null
    c2 = null
    c3 = null
    c4 = null
    c5 = null
    c6 = null
    M1 = null


    M1 = OpenMatrix(Dir + "\\skims\\TR_SKIM_OPBusDrop.mtx", "True")
        c1 = CreateMatrixCurrency(M1, "Fare", "RCIndex", "RCIndex",)
      c2 = CreateMatrixCurrency(M1, "Cost", "RCIndex", "RCIndex",)
        MatrixOperations(c2, {c1}, {100},,, {{"Operation", "Add"}, {"Force Missing", "Yes"}})
    c1 = null
    c2 = null
    c3 = null
    M1 = null
//continuefromhere:

    // -- Populate the Skim Values in the Output Skim Matrix for use as an input to the Mode Split Model

    input_matrix = Dir + "\\skims\\TR_SKIM_OPBusDrop.mtx"
    modesplit_matrix = Dir + "\\skims\\OFFPK_DROPTRAN_SKIMS.mtx"

    

Opts = null

     Opts.Input.[Target Currency] = { modesplit_matrix, "IVTT - Bus DropOff", "Rows", "Columns"}
     Opts.Input.[Source Currencies] = {{input_matrix, "IVTT", "RCIndex", "RCIndex"}}
     Opts.Global.[Missing Option].[Force Missing] = "Yes"

     ret_value = RunMacro("TCB Run Operation", 18, "Merge Matrices", Opts) 
    if !ret_value then goto badmatrixop

Opts = null

     Opts.Input.[Target Currency] = { modesplit_matrix, "Approach - Bus DropOff", "Rows", "Columns"}
     Opts.Input.[Source Currencies] = {{input_matrix, "Approach", "RCIndex", "RCIndex"}}
     Opts.Global.[Missing Option].[Force Missing] = "Yes"

     ret_value = RunMacro("TCB Run Operation", 19, "Merge Matrices", Opts) 
    if !ret_value then goto badmatrixop


Opts = null

     Opts.Input.[Target Currency] = { modesplit_matrix, "Cost - Bus DropOff", "Rows", "Columns"}
     Opts.Input.[Source Currencies] = {{input_matrix, "Cost", "RCIndex", "RCIndex"}}
     Opts.Global.[Missing Option].[Force Missing] = "Yes"

     ret_value = RunMacro("TCB Run Operation", 20, "Merge Matrices", Opts) 
    if !ret_value then goto badmatrixop

//Opts = null
//
//   Opts.Input.[Target Currency] = { modesplit_matrix, "Xfers - Bus DropOff", "Rows", "Columns"}
//     Opts.Input.[Source Currencies] = {{input_matrix, "Number of Transfers", "RCIndex", "RCIndex"}}
//     Opts.Global.[Missing Option].[Force Missing] = "Yes"
//
//     ret_value = RunMacro("TCB Run Operation", 1, "Merge Matrices", Opts) 

Opts = null

     Opts.Input.[Target Currency] = { modesplit_matrix, "Initial Wait - Bus DropOff", "Rows", "Columns"}
     Opts.Input.[Source Currencies] = {{input_matrix, "Initial Wait Time", "RCIndex", "RCIndex"}}
     Opts.Global.[Missing Option].[Force Missing] = "Yes"

     ret_value = RunMacro("TCB Run Operation", 21, "Merge Matrices", Opts) 
    if !ret_value then goto badmatrixop


Opts = null

     Opts.Input.[Target Currency] = { modesplit_matrix, "ParkFlag - Bus DropOff", "Rows", "Columns"}
     Opts.Input.[Source Currencies] = {{input_matrix, "Park_Flag", "RCIndex", "RCIndex"}}
     Opts.Global.[Missing Option].[Force Missing] = "Yes"

     ret_value = RunMacro("TCB Run Operation", 22, "Merge Matrices", Opts) 
    if !ret_value then goto badmatrixop

Opts = null

     Opts.Input.[Target Currency] = { modesplit_matrix, "Transfer Penalty Time - Bus DropOff", "Rows", "Columns"}
     Opts.Input.[Source Currencies] = {{input_matrix, "Transfer Penalty Time", "RCIndex", "RCIndex"}}
     Opts.Global.[Missing Option].[Force Missing] = "Yes"

     ret_value = RunMacro("TCB Run Operation", 23, "Merge Matrices", Opts) 
    if !ret_value then goto badmatrixop

Opts = null

     Opts.Input.[Target Currency] = { modesplit_matrix, "Drive Access Time - Bus DropOff", "Rows", "Columns"}
     Opts.Input.[Source Currencies] = {{input_matrix, "Access Drive Time", "RCIndex", "RCIndex"}}
     Opts.Global.[Missing Option].[Force Missing] = "Yes"

     ret_value = RunMacro("TCB Run Operation", 24, "Merge Matrices", Opts) 
    if !ret_value then goto badmatrixop

/*
Opts = null

     Opts.Input.[Target Currency] = { modesplit_matrix, "Drive Access Distance - Bus DropOff", "Rows", "Columns"}
     Opts.Input.[Source Currencies] = {{input_matrix, "Drive Distance", "RCIndex", "RCIndex"}}
     Opts.Global.[Missing Option].[Force Missing] = "Yes"

     ret_value = RunMacro("TCB Run Operation", 1, "Merge Matrices", Opts) 
*/
Opts = null

     Opts.Input.[Target Currency] = { modesplit_matrix, "Transfer Wait Time - Bus DropOff", "Rows", "Columns"}
     Opts.Input.[Source Currencies] = {{input_matrix, "Transfer Wait Time", "RCIndex", "RCIndex"}}
     Opts.Global.[Missing Option].[Force Missing] = "Yes"

     ret_value = RunMacro("TCB Run Operation", 25, "Merge Matrices", Opts) 
    if !ret_value then goto badmatrixop

Opts = null

     Opts.Input.[Target Currency] = { modesplit_matrix, "Highway SkimLength - Bus DropOff", "Rows", "Columns"}
     Opts.Input.[Source Currencies] = {{input_matrix, "Highway Skim", "RCIndex", "RCIndex"}}
     Opts.Global.[Missing Option].[Force Missing] = "Yes"

     ret_value = RunMacro("TCB Run Operation", 26, "Merge Matrices", Opts) 
    if !ret_value then goto badmatrixop

// Add skip-stop use flag, JainM, 01.08.09
Opts = null

     Opts.Input.[Matrix Currency] = {modesplit_matrix, "SkS Flag", "Rows", "Columns"}
     Opts.Input.[Formula Currencies] = {{input_matrix, "Generalized Cost", "RCIndex", "RCIndex"}}
     Opts.Global.Method = 11
     Opts.Global.[Cell Range] = 2
     Opts.Global.[Expression Text] = "if([Skim Matrix (Pathfinder)].[Length (SKS)] > 0) then 1 else 0"
     Opts.Global.[Formula Labels] = {"Skim Matrix (Pathfinder)"}
     Opts.Global.[Force Missing] = "No"

     ret_value = RunMacro("TCB Run Operation", 27, "Fill Matrices", Opts)
    if !ret_value then goto badmatrixop
    
// Add un-weighted total walk time, JainM, 09.20.11
Opts = null

     Opts.Input.[Target Currency] = { modesplit_matrix, "Total Walk UnWtd - Bus", "Rows", "Columns"}
     Opts.Input.[Source Currencies] = {{input_matrix, "TTWalk* (WALK)", "RCIndex", "RCIndex"}}
     Opts.Global.[Missing Option].[Force Missing] = "Yes"

     ret_value = RunMacro("TCB Run Operation", 28, "Merge Matrices", Opts) 
    if !ret_value then goto badmatrixop

///////////////////////////////
// Call macro Update_DropOff_Skims to update table Drive Access distance in the final skims
// added by JainM March 07

       rtn_upskim = RunMacro("Update_DropOff_Skims_Mtx", "offpeak", "bus", "dropoff", Args)
        if rtn_upskim[1] = 0 then goto badupskim

CloseMap()

// -- archive the transit skim to save space 
goto quit
//  pkzip_program = METDir + "\\pgm\\pkzip25\\pkzip25.exe"
//  status = RunProgram(pkzip_program + " " + Dir+"\\skims\\TR_SKIM_opbusdrop.zip " +Dir+"\\skims\\TR_Skim_opbusdrop.mtx -Add",{{"Minimize", "True"}})

//  if status = 0 then DeleteFile(Dir+"\\skims\\TR_Skim_opbusdrop.mtx")

    badcomputeopmatrix:
    Throw("Reg_OPBusDrop - Error return from Compute_OP_Matrix")
    // Throw("Reg_OPBusDrop - Error return from Compute_OP_Matrix")
    // AppendToLogFile(1, "Reg_OPBusDrop - Error return from Compute_OP_Matrix") 
    // goto badquit

    badupskim:
    Throw("Reg_OPBusDrop - Error return from Update_Dropoff_Skim_Mtx")
    // msg = rtn_upskim[2] + {"Reg_OPBusDrop - Error return from Update_Dropoff_Skim_Mtx"}
    // AppendToLogFile(1, "Reg_OPBusDrop - Error return from Update_Dropoff_Skim_Mtx") 
    // goto badquit
        
    badparkflags:
    Throw("Reg_OPBusDrop - Error return from Create OPBusDrop Parking Flags")
    // msg = rtn_Pflags[2] + {"Reg_OPBusDrop - Error return from Create OPBusDrop Parking Flags"}
    // AppendToLogFile(1, "Reg_OPBusDrop - Error return from Create OPBusDrop Parking Flags") 
    // goto badquit
        
    badbuildtrannet:
    Throw("Reg_OPBusDrop - Error return build transit network")
    // Throw("Reg_OPBusDrop - Error return build transit network")
    // AppendToLogFile(1, "Reg_OPBusDrop - Error return build transit network") 
    // goto badquit

    badtransettings:
    Throw("Reg_OPBusDrop - Error return from transit network settings")
    // Throw("Reg_OPBusDrop - Error return from transit network settings")
    // AppendToLogFile(1, "Reg_OPBusDrop - Error return from transit network settings") 
    // goto badquit

    badtranskim:
    Throw("Reg_OPBusDrop - Error return from transit network skims")
    // Throw("Reg_OPBusDrop - Error return from transit network skims")
    // AppendToLogFile(1, "Reg_OPBusDrop - Error return from transit network skims")
    // goto badquit

    badmatrixop:
    Throw("Reg_OPBusDrop - Error in matrix operations")
    // Throw("Reg_OPBusDrop - Error in matrix operations")
    // AppendToLogFile(1, "Reg_OPBusDrop - Error matrix operations")
    // goto badquit

    badxpr_stopflags:
    Throw("Reg_PPrmW - Error return from XPR_StopFlags")
    // Throw(rtnmsg)
    // AppendToLogFile(2, rtnmsg)
    // Throw("Reg_PPrmW - Error return from XPR_StopFlags")
    // AppendToLogFile(1, "Reg_PPrmW - Error return from XPR_StopFlags")
    // goto badquit

    badquit:
    Throw("badquit: Last error message= " + GetLastError())
    AppendToLogFile(2, "badquit: Last error message= " + GetLastError())
    RunMacro("TCB Closing", 0, "TRUE" ) 
    RegOPBusDropOK = 0
    goto quit
    
quit:

    RunMacro("close everything")
    datentime = GetDateandTime()
    AppendToLogFile(1, "Exit Reg_OPBusDrop: " + datentime)
    AppendToLogFile(1, " ")

    return({RegOPBusDropOK, msg})


endMacro

Macro "close everything"
    maps = GetMaps()
    if maps <> null then do
        for i = 1 to maps[1].length do
            SetMapSaveFlag(maps[1][i],"False")
        end
    end
    RunMacro("G30 File Close All")
    mtxs = GetMatrices()
    if mtxs <> null then do
        handles = mtxs[1]
        for i = 1 to handles.length do
            handles[i] = null
        end
    end
endMacro


// -----------------------------------------
//   Macro "Create OPbusDrop Parking Flags"
// -----------------------------------------

Macro "Create OPbusDrop Parking Flags" (Args)

shared route_file, routename, net_file, link_lyr, node_lyr, parking_view, nodes_view


    // LogFile = Args.[Log File].value
    // SetLogFileName(LogFile)

    METDir = Args.[MET Directory]
    Dir = Args.[Run Directory]
        
    msg = null
    ParkFlagsOK = 1
    datentime = GetDateandTime()
    AppendToLogFile(2, "Enter Create OPBusDrop Parking Flags: " + datentime)


m = OpenMatrix(Dir + "\\skims\\TR_PARK_OPBusDrop.mtx", )
mc1 = CreateMatrixCurrency(m, "Parking Nodes", "RCIndex", "RCIndex", )
mc2 = CreateMatrixCurrency(m, "Parking Nodes", "RCIndex", "RCIndex", )
CopyMatrixStructure({mc1,mc2}, {{"File Name", Dir + "\\skims\\ParkFlag_OPbusDrop.mtx"},
    {"Label", "New Matrix"},
    {"File Based", "Yes"},
    {"Tables", {"Parking_Flag"}},
    {"Operation", "Union"},
    {"Compression",0}})


//---- close open view ----
    SetView(nodes_view)
    query = "Select * where KNR > 0 and KNR <4"
    n1=selectbyquery("knrcat","Several",query,)
    
    
ExportView(nodes_view+"|knrcat", "FFA", Dir+ "//skims//KNR_CAT.asc",
    {"Node.ID", "KNR"},)

/////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////
// Write the control file and batch file

    exist = GetFileInfo(METDir + "\\pgm\\ModeChoice\\KNR_Loc_CAT.exe")
    if (exist = null) then goto nofortran
    
    ctlname = Dir + "\\skims\\KNR_Loc_CAT.ctl"
    exist = GetFileInfo(ctlname)
    if (exist <> null) then DeleteFile(ctlname)

// replace backslash "\" in ctl file filenames with forward slash "/" - Manish had a 
//  different method - but it won't work with longer file names , not sure why it needs it either, but it seems to. JWM - 11/2015

    // dirparse = parsestring(Dir, "\\")
    // DirSlash = dirparse[1]
    // for i = 2 to dirparse.length do
    //     DirSlash = DirSlash + "//" + dirparse[i]
    // end
    DirSlash = Dir
 /*
    ctl = OpenFile(ctlname, "w")

    WriteLine(ctl, DirSlash + "//Skims//TR_PARK_OPBusDrop.mtx")
    WriteLine(ctl, DirSlash + "//skims//KNR_CAT.asc")
    WriteLine(ctl, DirSlash + "//Skims//ParkFlag_OPbusDrop.mtx")
    CloseFile(ctl)

    batchname=Dir + "\\skims\\knrflag.bat"
    exist = GetFileInfo(batchname)
    if (exist <> null) then DeleteFile(batchname)
    bat = OpenFile(batchname, "w")

    WriteLine(bat, METDir + "\\pgm\\ModeChoice\\KNR_Loc_CAT.exe " + ctlname)
    CloseFile(bat)

    FortInfo = GetFileInfo(METDir + "\\Pgm\\ModeChoice\\KNR_Loc_CAT.exe")
    TimeStamp = FortInfo[7] + " " + FortInfo[8]
    AppendToLogFile(2, "Create OPBusDrop Parking Flags call to fortran: pgm=\\ModeChoice\\KNR_Loc_CAT.exe, timestamp: " + TimeStamp)

     status = RunProgram(batchname,{{"Maximize", "True"}})
    if (status <> 0) then goto badfortran
*/
    ascfile = DirSlash + "//skims//KNR_CAT.asc"
    inmtx = DirSlash + "//Skims//TR_PARK_OPBusDrop.mtx"
    outmtx = DirSlash + "//Skims//ParkFlag_OPbusDrop.mtx"
    RunMacro("Run KCAT", ascfile, inmtx, outmtx)

    modesplit_matrix = Dir + "\\skims\\OFFPK_DROPTRAN_SKIMS.MTX"
    input_matrix= Dir + "\\skims\\ParkFlag_OPbusDrop.mtx"
     Opts = null

     Opts.Input.[Target Currency] = { modesplit_matrix, "ParkFlag - Bus DropOff", "Rows", "Columns"}
     Opts.Input.[Source Currencies] = {{input_matrix, "Parking_Flag", "Rows", "Columns"}}
     Opts.Global.[Missing Option].[Force Missing] = "Yes"

    ret_value = RunMacro("TCB Run Operation", 1, "Merge Matrices", Opts) 
    if !ret_value then goto badmatrixop
    goto quit
    
    nofortran:
    Throw("Fortran program to compute parking flag is missing")
    AppendToLogFile(2, "Fortran program to compute parking flag is missing")
    goto badquit

    badfortran:
    Throw("Error return from fortran program KNR_LOC_Cat")
    AppendToLogFile(2, "Error return from fortran program KNR_LOC_Cat")
    goto badquit

    badmatrixop:
    Throw("Create OPBusDrop Parking Flags - Error merging matrices")
    AppendToLogFile(1, "Create OPBusDrop Parking Flags - Error merging matrices")
    goto badquit

    badquit:
    RunMacro("TCB Closing", 0, "TRUE" ) 
    ParkFlagsOK = 0
    goto quit
    
quit:
    datentime = GetDateandTime()
    AppendToLogFile(2, "Exit Create OPBusDrop Parking Flags: " + datentime)
    AppendToLogFile(1, " ")

    return({ParkFlagsOK, msg})

endMacro


macro "Run KCAT" (ascfile, inmtx, outmtx)

    inm = CreateObject("Matrix", inmtx, {MemoryOnly: true})
    outm = CreateObject("Matrix", outmtx, {MemoryOnly: true})
    asc = OpenTable("asc", "FFA", {ascfile})
    tmp = GetTempFileName("*.bin")

    inm.ExportToTable({OutputMode: "Tables", FileName: tmp})
    intab = CreateObject("Table", tmp)
    intabm = intab.Export()
    invw = intabm.GetView()
    jv = JoinViews("jv", GetFieldFullSpec(invw, "Parking"), GetFieldFullSpec(asc, "ID"),)
    {flds,} = GetFields(jv, "All")
    jvv = ExportView(jv+"|", "MEM", "InMem2",,)

    od = null
    od = CreateObject("Matrix", outmtx)
    mhandle = od.GetMatrixHandle()

    UpdateMatrixFromView(mhandle, jvv + "|", flds[1], flds[2], , {"KNR"}, "Replace",) // fill in class number in matrix
    mhandle = null
    outm = null
    outm = CreateObject("Matrix", outmtx)
    outm.Parking_Flag := if outm.Parking_Flag = 2 then outm.Parking_Flag else null
    CloseView(jvv)
    CloseView(jv)
    CloseView(asc)

endmacro
