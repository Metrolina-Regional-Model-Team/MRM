Macro "Reg_PrmD" (Args) 

// Modified for new UI - Nov, 2015 - McLelland
// Commented out pkzip for skim file and delete - (lines 542+)
// 5/30/19, mk: There are now three distinct networks, use offpeak since was used to setup route system - dropped in 2024 to one network
// 7/30/25, ar: Loop through four time periods to build and set transit network and skims for each 
	shared route_file, routename, net_file, link_lyr, node_lyr

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
		
	curiter = Args.[Current Feedback Iter]
	RegPPrmDOK = 1
	msg = null

	datentime = GetDateandTime()
	AppendToLogFile(1, "Enter Reg_PPrmD: " + datentime)
	AppendToLogFile(2, "AM Peak feedback iteration: " + i2s(curiter))

	yearnet = Substring(theyear, 3, 2)
	analysis_year = yearnet

	//	Invoke "XPR_StopFlags" macro to flag express stops as board/alight only and premium stops
	//	Enable stop access coding for modes 5 and 6 for use with TransCAD5, JainM, 07.20.08
	//	Updated for TransCad7, McLelland 09.12.16
	//	Returns 1 for clean run, 2 for warning about flags (run continues), 3 for fatal error 

    stopflagrtn = RunMacro("XPR_StopFlags", Args)
	rtnerr = stopflagrtn[1]
	rtnmsg = stopflagrtn[2]
	
	if runerr = 3 
		then goto badxpr_stopflags

	if runerr = 2
		then do
			AppendToLogFile(2, rtnmsg)
               Throw(rtnmsg)
			// Throw(rtnmsg)
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
//	CreateMap(net, {{"Scope", scope},{"Auto Project", "True"}})
	CreateMap(net, {{"Scope", scope},{"Auto Project", "False"}})
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

// ----------------------------------- Loop by 4 time periods  -----------------------------------

  time_periods = {"AM", "PM", "MD","NT"}
   
    for time_period in time_periods do

// ----------------------------------- STEP 1: Build Transit Network  -----------------------------------

          RunMacro("TCB Init")

     // Call macro Compute_Shadow_Price to create Origin-to-parking Node Time matrix and add shadow price
     // added by JainM Dec 05

     //       return_value = RunMacro("Compute_Shadow_Price", "peak")
     //       if return_value <> 0 then showmessage("Return status is: " + return_value)

     //////
          Opts = RunMacro("create_tnet", time_period, "premium", "drive", Dir)
          ret_value = RunMacro("TCB Run Operation", 1, "Build Transit Network", Opts) 

          if !ret_value then goto badbuildtrannet

     // Call macro Add_Shadow_Price to create Origin-to-parking Node Time matrix and add shadow price
     // added by JainM Dec 05
     // JainM March 07, replace Add_Shadow_Price with "Compute_OP_Matrix"
     // This new macro penalizes drive access time if driving to a PNR lot farther then closes formal PNR lot. It also adds the shadow price.

          rtn_OP = RunMacro("Compute_OP_Matrix", time_period, "premium", "drive", Args)
          if rtn_OP[1] = 0
               then do
                    Throw(rtn_OP[2])
                    // msg = msg + rtn_OP[2]
                    // goto badcomputeopmatrix
               end

     //////

     // ----------------------------------- STEP 2: Transit Network Setting  -----------------------------------


          Opts = RunMacro("set_tnet", time_period, "premium", "drive", Dir)
          ret_value = RunMacro("TCB Run Operation", 2, "Transit Network Setting PF", Opts)

          if !ret_value then goto badtransettings

     // ----------------------------------- STEP 3: Transit Skim Path Finder  -----------------------------------

          // skip PM and NT as same skimming used

          if time_period = "PM" then goto skiptransskim
          if time_period = "NT" then goto skiptransskim

          Opts = null
          Opts.Input.Database = net_file 
          Opts.Input.[Transit RS] = route_file
          Opts.Input.Network = Dir + "\\PrmD_" + time_period + ".tnw"
          Opts.Input.[Origin Set] = {net_file + "|" + node_lyr, node_lyr,"Centroids","Select * where centroid = 1 or [External Station] = 1"}
          Opts.Input.[Destination Set] = {net_file + "|" + node_lyr, node_lyr,"Centroids"}
          Opts.Global.[OD Layer Type] = 2
          Opts.Output.[Skim Matrix].Label = "Skim Matrix (Pathfinder)"
          if time_period = "AM" or time_period = "PM" then do
               Opts.Global.[Skim Modes] = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11}
               Opts.Global.[Skim Var] = {"Generalized Cost", "Fare", "In-Vehicle Time", "Initial Wait Time", "Transfer Wait Time", "Transfer Penalty Time", "Transfer Walk Time", "Access Walk Time", "Egress Walk Time", "Access Drive Time", "Dwelling Time", "Number of Transfers", "In-Vehicle Distance", "Access Drive Distance", "Length", "BRT_Flag", "TTPkLoc*", "TTWalk*"}
               Opts.Output.[Skim Matrix].[File Name] = Dir + "\\skims\\TR_SKIM_PPrmD.mtx"
               Opts.Output.[Parking Matrix].Label = "TR_PARK_PPrmD"
               Opts.Output.[Parking Matrix].[File Name] = Dir + "\\skims\\TR_PARK_PPrmD.mtx"
          end
          if time_period = "MD" or time_period = "NT" then do
               Opts.Global.[Skim Modes] = { 5, 6, 7, 8, 9, 10, 11}
               Opts.Global.[Skim Var] = {"Generalized Cost", "Fare", "In-Vehicle Time", "Initial Wait Time", "Transfer Wait Time", "Transfer Penalty Time", "Transfer Walk Time", "Access Walk Time", "Egress Walk Time", "Access Drive Time", "Dwelling Time", "Number of Transfers", "In-Vehicle Distance", "Access Drive Distance", "Length", "BRT_Flag", "TTFrLoc*", "TTWalk*"}
               Opts.Output.[Skim Matrix].[File Name] = Dir + "\\skims\\TR_SKIM_OPPrmD.mtx"
               Opts.Output.[Parking Matrix].Label = "TR_PARK_OPPrmD"
               Opts.Output.[Parking Matrix].[File Name] = Dir + "\\skims\\TR_PARK_OPPrmD.mtx"
          end
     // -------- Output Origin-to-Parking Time Matrix ---------------
     //     Opts.Output.[OP Matrix].Label = "Prm OP Time Matrix (Peak)"
     //     Opts.Output.[OP Matrix].[File Name] = Dir + "\\skims\\TR_OP_SKIM_pprmd.mtx"

          ret_value = RunMacro("TCB Run Procedure", 3, "Transit Skim PF", Opts)

          if !ret_value then goto badtranskim


          // --- Fill the Null Values in PARK matrix with Zeroes

          if time_period = "AM" or time_period = "PM" then
               park_matrix = Dir + "\\skims\\TR_PARK_PPrmD.mtx"
          else 
               park_matrix = Dir + "\\skims\\TR_PARK_OPPrmD.mtx"

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

          ret_value = RunMacro("TCB Run Operation", 5, "Merge Matrices", Opts)
          if !ret_value then goto badmatrixop

          //	om = OpenMatrix(Dir + "\\skims\\TR_PARK_PPRMD.mtx", "True")
          //	CreateTableFromMatrix(om, Dir + "\\tranassn\\PprmD\\pnrnode_pprmd.asc", "FFA", {{"Complete", "Yes"}})

          // Check for local matrix cores (JWM 16.09.16) - add if necessary and initialize to null (clear)
          // 	matrix assignment ":=" please see help documentation for "Matrix Assignment Statement"

          if time_period = "AM" or time_period = "PM" then
               skim_matrix = Dir + "\\skims\\TR_SKIM_PPrmD.mtx"
          else 
               skim_matrix = Dir + "\\skims\\TR_SKIM_OPPrmD.mtx"

          OM = OpenMatrix(skim_matrix, "True")

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

          corepos = ArrayPosition(matcores, {"ParkTime"},)
          if corepos = 0 then addmatrixcore(OM,"ParkTime")
          c = CreateMatrixCurrency(OM, "ParkTime",,,)
          c := null

          corepos = ArrayPosition(matcores, {"Highway Skim"},)
          if corepos = 0 then addmatrixcore(OM,"Highway Skim")
          c = CreateMatrixCurrency(OM, "Highway Skim",,,)
          c := null

          OM = null
          c = null

          //--- include the highway skim matrix as a part of Transit Skim Matrices . Added By Balaji

          if time_period = "AM" or time_period = "PM" then
               hwyskim_matrix = Dir + "\\AutoSkims\\SPMAT_free.mtx"
          else
               hwyskim_matrix = Dir + "\\AutoSkims\\SPMAT_free.mtx"

          M1 = OpenMatrix(skim_matrix, "True")
          M2 = OpenMatrix(hwyskim_matrix, "True")

          c1 = CreateMatrixCurrency(M2, "Non HOV Length", "Rows", "Columns",)
          c2 = CreateMatrixCurrency(M1, "Highway Skim", "RCIndex", "RCIndex",)
          MatrixOperations(c2, {c1}, {1},,, {{"Operation", "Add"}, {"Force Missing", "Yes"}})

          c1 = null
          c2 = null
          M1 = null
          M2 = null
     // Compute BRT_Flag

          OM=null

          OM = OpenMatrix(skim_matrix, "True")
          matcores = GetMatrixCoreNames(OM)
          corepos = ArrayPosition(matcores, {"BRT_Flag"},)
          if corepos = 0 then addmatrixcore(OM,"BRT_Flag")
          SetMatrixCore(OM,"BRT_Flag")

          M1 = OpenMatrix(skim_matrix, "True")
          c1 = CreateMatrixCurrency(M1, "BRT_Flag (BRT)", "RCIndex", "RCIndex",)
          c2 = CreateMatrixCurrency(M1, "BRT_Flag (XPR)", "RCIndex", "RCIndex",)
          c3 = CreateMatrixCurrency(M1, "BRT_Flag (XCM)", "RCIndex", "RCIndex",)
          c4 = CreateMatrixCurrency(M1, "BRT_Flag (SKS)", "RCIndex", "RCIndex",)
          c5 = CreateMatrixCurrency(M1, "BRT_Flag", "RCIndex", "RCIndex",)
          MatrixOperations(c5, {c1, c2, c3, c4}, {1, 1, 1, 1},,, {{"Operation", "Add"}, {"Force Missing", "No"}})
     c1 = null
     c2 = null
     c3 = null
     c4 = null
     c5 = null

     M1 = null

     ///////////////////////////////////

          M1 = OpenMatrix(skim_matrix, "True")
          c1 = CreateMatrixCurrency(M1, "Length (LRT)", "RCIndex", "RCIndex",)
          c2 = CreateMatrixCurrency(M1, "Length (STR)", "RCIndex", "RCIndex",)
          c3 = CreateMatrixCurrency(M1, "Length (CMR)", "RCIndex", "RCIndex",)
          c4 = CreateMatrixCurrency(M1, "Length (BRT)", "RCIndex", "RCIndex",)
          c5 = CreateMatrixCurrency(M1, "Length (XCM)", "RCIndex", "RCIndex",)
          c6 = CreateMatrixCurrency(M1, "Length (XPR)", "RCIndex", "RCIndex",)
          c7 = CreateMatrixCurrency(M1, "Length (FDR)", "RCIndex", "RCIndex",)
          c8 = CreateMatrixCurrency(M1, "Length (LOC)", "RCIndex", "RCIndex",)
          c9 = CreateMatrixCurrency(M1, "Length (GLD)", "RCIndex", "RCIndex",)
          c11 = CreateMatrixCurrency(M1, "Length (SKS)", "RCIndex", "RCIndex",)
          c10 = CreateMatrixCurrency(M1, "Total Distance", "RCIndex", "RCIndex",)
          MatrixOperations(c10, {c1, c2, c3, c4, c5, c6, c7, c8, c9, c11}, {1, 1, 1, 1, 1, 1, 1, 1, 1, 1},,, {{"Operation", "Add"}, {"Force Missing", "No"}})
     c1 = null
     c2 = null
     c3 = null
     c4 = null
     c5 = null
     c6 = null
     c7 = null
     c8 = null
     c9 = null
     c10 = null
     c11 = null
     M1 = null


          Opts = {{"Input",    {{"Matrix Currency",   {skim_matrix,
                                                       "InVehGT5",
                                                       "RCIndex",
                                                       "RCIndex"}}}},
               {"Global",   {{"Method",            11},
                              {"Cell Range",        2},
                    {"Matrix K",          {1,
                                   1}},
     {"Expression Text", "if ((nz([Length (LRT)]) + nz([Length (STR)]) + nz([Length (CMR)]) + nz([Length (BRT)]))> 0.0 or [BRT_Flag] > 0) and [Highway Skim] > 0.75 then [In-Vehicle Time]"},                     
               {"Force Missing",     "Yes"}}}}

          if !RunMacro("TCB Run Operation", 13, "Fill Matrices", Opts) then goto badmatrixop

     Opts = {{"Input",    {{"Matrix Currency",   {skim_matrix,
                                                       "ParkTime",
                                                       "RCIndex",
                                                       "RCIndex"}}}},
               {"Global",   {{"Method",            11},
                              {"Cell Range",        2},
                    {"Matrix K",          {1,
                                   1}},
                              {"Expression Text",   "if [InVehGT5] <> null then 1.0 else 0"},
                              {"Force Missing",     "Yes"}}}}

          if !RunMacro("TCB Run Operation", 14, "Fill Matrices", Opts) then goto badmatrixop


          M1 = OpenMatrix(skim_matrix, "True")
          c2 = CreateMatrixCurrency(M1, "Dwelling Time", "RCIndex", "RCIndex",)
          c3 = CreateMatrixCurrency(M1, "InVehGT5", "RCIndex", "RCIndex",)
          c4 = CreateMatrixCurrency(M1, "IVTT", "RCIndex", "RCIndex",)
          MatrixOperations(c4, {c2, c3}, {1, 1},,, {{"Operation", "Add"}, {"Force Missing", "Yes"}})
     c2 = null
     c3 = null
     c4 = null
     M1 = null

     // The premium stations are micro coded and the transit skims include the Park Time. Don't add ParkTime here. JainM, 08.15.08

          M1 = OpenMatrix(skim_matrix, "True")
     //	c1 = CreateMatrixCurrency(M1, "Transfer Wait Time", "RCIndex", "RCIndex",)
          c2 = CreateMatrixCurrency(M1, "Transfer Walk Time", "RCIndex", "RCIndex",)
          c3 = CreateMatrixCurrency(M1, "Access Walk Time", "RCIndex", "RCIndex",)
          c4 = CreateMatrixCurrency(M1, "Egress Walk Time", "RCIndex", "RCIndex",)
          c5 = CreateMatrixCurrency(M1, "ParkTime", "RCIndex", "RCIndex",)
          c6 = CreateMatrixCurrency(M1, "Approach", "RCIndex", "RCIndex",)
          MatrixOperations(c6, {c2, c3, c4, c5}, {1, 1, 1, 0},,, {{"Operation", "Add"}, {"Force Missing", "No"}})
     c1 = null
     c2 = null
     c3 = null
     c4 = null
     c5 = null
     c6 = null
     M1 = null


          M1 = OpenMatrix(skim_matrix, "True")
          c1 = CreateMatrixCurrency(M1, "Fare", "RCIndex", "RCIndex",)
          c2 = CreateMatrixCurrency(M1, "Access Drive Distance", "RCIndex", "RCIndex",)
          c3 = CreateMatrixCurrency(M1, "Cost", "RCIndex", "RCIndex",)
          MatrixOperations(c3, {c1, c2}, {100, 10},,, {{"Operation", "Add"}, {"Force Missing", "No"}})
     c1 = null
     c2 = null
     c3 = null
     M1 = null

     // Compute the mode hierarchy and populate the matrix
          OM=null
          OM = OpenMatrix(skim_matrix, "True")

          matcores = GetMatrixCoreNames(OM)
          corepos = ArrayPosition(matcores, {"ModeFlag"},)
          if corepos = 0 then addmatrixcore(OM,"ModeFlag")
          SetMatrixCore(OM,"ModeFlag")

          Opts = {{"Input",    {{"Matrix Currency",   {skim_matrix,
                                                       "ModeFlag",
                                                       "RCIndex",
                                                       "RCIndex"}}}},
               {"Global",   {{"Method",            11},
                              {"Cell Range",        2},
                         {"Matrix K",          {1,1}},
                              {"Expression Text",   "if (nz([Length (CMR)])>0 and IVTT>0) then 1 else if (nz([Length (LRT)])>0  and IVTT>0) then 2 else if (nz([Length (BRT)])>0  and IVTT>0) then 3  else if (nz([BRT_Flag])>0  and IVTT>0) then 3  else if (nz([Length (STR)])>0  and IVTT>0) then 4 else null"},
                              {"Force Missing",     "Yes"}}}}

          if !RunMacro("TCB Run Operation", 15, "Fill Matrices", Opts) then goto badmatrixop


     // --- Update the ModFlag for StreetCar
     // --- StreetCar Mode Flag reset to null if the length of the trip on Street Car is less than 1.2 miles 
     // --  and one of the trip end is in CBD area

     //skim_matrix = Dir + "\\skims\\TR_SKIM_PPrmD.mtx"

     // RunMacro("Update ModeFlag", Dir, skim_matrix)


     /////////////////////////////////////////////////mj


          // -- Populate the Skim Values in the Output Skim Matrix for use as an input to the Mode Split Model

          input_matrix = skim_matrix

          if time_period = "AM" or time_period = "PM" then
               modesplit_matrix = Dir + "\\skims\\PK_DRVTRAN_SKIMS.mtx"
          else 
               modesplit_matrix = Dir + "\\skims\\OFFPK_DRVTRAN_SKIMS.mtx"

          

     Opts = null

          Opts.Input.[Target Currency] = { modesplit_matrix, "IVTT - Prem Drive", "Rows", "Columns"}
          Opts.Input.[Source Currencies] = {{input_matrix, "IVTT", "RCIndex", "RCIndex"}}
          Opts.Global.[Missing Option].[Force Missing] = "Yes"

          ret_value = RunMacro("TCB Run Operation", 16, "Merge Matrices", Opts) 
          if !ret_value then goto badmatrixop


     Opts = null

          Opts.Input.[Target Currency] = { modesplit_matrix, "Approach - Prem Drive", "Rows", "Columns"}
          Opts.Input.[Source Currencies] = {{input_matrix, "Approach", "RCIndex", "RCIndex"}}
          Opts.Global.[Missing Option].[Force Missing] = "Yes"

          ret_value = RunMacro("TCB Run Operation", 17, "Merge Matrices", Opts) 
          if !ret_value then goto badmatrixop


     Opts = null

          Opts.Input.[Target Currency] = { modesplit_matrix, "Cost - Prem Drive", "Rows", "Columns"}
          Opts.Input.[Source Currencies] = {{input_matrix, "Cost", "RCIndex", "RCIndex"}}
          Opts.Global.[Missing Option].[Force Missing] = "Yes"

          ret_value = RunMacro("TCB Run Operation", 18, "Merge Matrices", Opts) 
          if !ret_value then goto badmatrixop

     //Opts = null
     //
     //   Opts.Input.[Target Currency] = { modesplit_matrix, "Xfers - Prem Drive", "Rows", "Columns"}
     //     Opts.Input.[Source Currencies] = {{input_matrix, "Number of Transfers", "RCIndex", "RCIndex"}}
     //     Opts.Global.[Missing Option].[Force Missing] = "Yes"
     //
     //     ret_value = RunMacro("TCB Run Operation", 1, "Merge Matrices", Opts) 

     Opts = null

          Opts.Input.[Target Currency] = { modesplit_matrix, "Initial Wait - Prem Drive", "Rows", "Columns"}
          Opts.Input.[Source Currencies] = {{input_matrix, "Initial Wait Time", "RCIndex", "RCIndex"}}
          Opts.Global.[Missing Option].[Force Missing] = "Yes"

          ret_value = RunMacro("TCB Run Operation", 19, "Merge Matrices", Opts) 
          if !ret_value then goto badmatrixop

     Opts = null

          Opts.Input.[Target Currency] = { modesplit_matrix, "Transfer Penalty Time - Prem Drive", "Rows", "Columns"}
          Opts.Input.[Source Currencies] = {{input_matrix, "Transfer Penalty Time", "RCIndex", "RCIndex"}}
          Opts.Global.[Missing Option].[Force Missing] = "Yes"

          ret_value = RunMacro("TCB Run Operation", 20, "Merge Matrices", Opts) 
          if !ret_value then goto badmatrixop

     Opts = null

          Opts.Input.[Target Currency] = { modesplit_matrix, "Drive Access Time - Prem Drive", "Rows", "Columns"}
          Opts.Input.[Source Currencies] = {{input_matrix, "Access Drive Time", "RCIndex", "RCIndex"}}
          Opts.Global.[Missing Option].[Force Missing] = "Yes"

          ret_value = RunMacro("TCB Run Operation", 21, "Merge Matrices", Opts) 
          if !ret_value then goto badmatrixop

     Opts = null

          Opts.Input.[Target Currency] = { modesplit_matrix, "Drive Access Distance - Prem Drive", "Rows", "Columns"}
          Opts.Input.[Source Currencies] = {{input_matrix, "Access Drive Distance", "RCIndex", "RCIndex"}}
          Opts.Global.[Missing Option].[Force Missing] = "Yes"

          ret_value = RunMacro("TCB Run Operation", 22, "Merge Matrices", Opts) 
          if !ret_value then goto badmatrixop

     Opts = null

          Opts.Input.[Target Currency] = { modesplit_matrix, "Transfer Wait Time - Prem Drive", "Rows", "Columns"}
          Opts.Input.[Source Currencies] = {{input_matrix, "Transfer Wait Time", "RCIndex", "RCIndex"}}
          Opts.Global.[Missing Option].[Force Missing] = "Yes"

          ret_value = RunMacro("TCB Run Operation", 23, "Merge Matrices", Opts) 
          if !ret_value then goto badmatrixop

     //Opts = null
     //
     //     Opts.Input.[Target Currency] = { modesplit_matrix, "Highway SkimLength - Prem Drive", "Rows", "Columns"}
     //     Opts.Input.[Source Currencies] = {{input_matrix, "Highway Skim", "RCIndex", "RCIndex"}}
     //     Opts.Global.[Missing Option].[Force Missing] = "Yes"
     //
     //     ret_value = RunMacro("TCB Run Operation", 1, "Merge Matrices", Opts) 
     //
     Opts = null

          Opts.Input.[Target Currency] = { modesplit_matrix, "ModeFlag", "Rows", "Columns"}
          Opts.Input.[Source Currencies] = {{input_matrix, "ModeFlag", "RCIndex", "RCIndex"}}
          Opts.Global.[Missing Option].[Force Missing] = "Yes"

          ret_value = RunMacro("TCB Run Operation", 24, "Merge Matrices", Opts) 
          if !ret_value then goto badmatrixop

     // Add un-weighted total walk time, JainM, 09.20.11
     Opts = null

          Opts.Input.[Target Currency] = { modesplit_matrix, "Total Walk UnWtd - Prem", "Rows", "Columns"}
          Opts.Input.[Source Currencies] = {{input_matrix, "TTWalk* (WALK)", "RCIndex", "RCIndex"}}
          Opts.Global.[Missing Option].[Force Missing] = "Yes"

          ret_value = RunMacro("TCB Run Operation", 25, "Merge Matrices", Opts) 
          if !ret_value then goto badmatrixop

     // Add Premium in-vehicle time
     c1 = null
     c2 = null
     c3 = null
     c4 = null
     c5 = null

     M  = OpenMatrix(modesplit_matrix, "True")
     M1 = OpenMatrix(input_matrix, "True")

     if time_period = "AM" or time_period = "PM" then do
          c1 = CreateMatrixCurrency(M1, "TTPkLoc* (LRT)", "RCIndex", "RCIndex",)
          c2 = CreateMatrixCurrency(M1, "TTPkLoc* (STR)", "RCIndex", "RCIndex",)
          c3 = CreateMatrixCurrency(M1, "TTPkLoc* (CMR)", "RCIndex", "RCIndex",)
          c4 = CreateMatrixCurrency(M1, "TTPkLoc* (BRT)", "RCIndex", "RCIndex",)
     end

     if time_period = "MD" or time_period = "NT" then do
          c1 = CreateMatrixCurrency(M1, "TTFrLoc* (LRT)", "RCIndex", "RCIndex",)
          c2 = CreateMatrixCurrency(M1, "TTFrLoc* (STR)", "RCIndex", "RCIndex",)
          c3 = CreateMatrixCurrency(M1, "TTFrLoc* (CMR)", "RCIndex", "RCIndex",)
          c4 = CreateMatrixCurrency(M1, "TTFrLoc* (BRT)", "RCIndex", "RCIndex",)
     end

     c5 = CreateMatrixCurrency(M , "Prem IVTT", "Rows", "Columns",)

     MatrixOperations(c5, {c1, c2, c3, c4}, {1, 1, 1, 0},,, {{"Operation", "Add"}, {"Force Missing", "No"}})

     c1 = null
     c2 = null
     c3 = null
     c4 = null
     c5 = null
     

     Opts = {{"Input",    {{"Matrix Currency",   {modesplit_matrix,
                                                  "PrmOnly Flag",
                                                  "Rows",
                                                  "Columns"}}}},
               {"Global",   {{"Method",            11},
                              {"Cell Range",        2},
                              {"Matrix K",          {1,1}},
                              {"Expression Text",   "if (nz([IVTT - Prem Drive]) > 0) then 1 else 0"},
                              {"Force Missing",     "No"}}}}

     if !RunMacro("TCB Run Operation", 26, "Fill Matrices", Opts) then goto quit
          if !ret_value then goto badmatrixop
     /*
     Opts = null
     Opts.Input.[Matrix Currency] = {modesplit_matrix, "PrmOnly Flag", "Rows", "Columns"}
     Opts.Input.[Formula Currencies] = {{input_matrix, "Generalized Cost", "RCIndex", "RCIndex"}}
     Opts.Global.Method = 11
     Opts.Global.[Cell Range] = 2
     Opts.Global.[Expression Text] = "if((nz([SkmMat].[In-Vehicle Distance])-nz([SkmMat].[Length (LRT)])-nz([SkmMat].[Length (CMR)]))=0 and (nz([SkmMat].[Length (LRT)]+[SkmMat].[Length (CMR)]) > 0) then 1 else 0"
     Opts.Global.[Formula Labels] = {"SkmMat"}
     Opts.Global.[Force Missing] = "No"

     ret_value = RunMacro("TCB Run Operation", 1, "Fill Matrices", Opts)
     */

     // Export the skims to ASCII file
     //
     //
     //	M1 = OpenMatrix(Dir + "\\skims\\TR_PARK_pprmd.mtx", "True")
     //        CreateTableFromMatrix(M1, Dir + "\\skims\\TR_PARK_pprmd.asc", "FFA", {{"Complete", "Yes"}})
     //    	M1 = null
     ///////////////////////////////
     // Call macro Update_Drive_Skims to update tables Cost and Drive Access distance tables in the final skims
     // added by JainM Dec 05

          rtn_upskim = RunMacro("Update_Drive_Skims_Mtx", time_period, "premium", "drive", Args)
               if rtn_upskim[1] = 0 then goto badupskim

          //CloseMap()
     skiptransskim:

     M=null
     M1=null
     M2= null
     OM = null
     
     end //time period loop

// -- archive the transit skim to save space 
goto quit
//	pkzip_program = METDir + "\\pgm\\pkzip25\\pkzip25.exe"
//	status = RunProgram(pkzip_program + " " + Dir+"\\skims\\TR_SKIM_pprmd.zip " +Dir+"\\skims\\TR_Skim_pprmd.mtx -Add",{{"Minimize", "True"}})

//	if status = 0 then DeleteFile(Dir+"\\skims\\TR_Skim_pprmd.mtx")

	badcomputeopmatrix:
     Throw("Reg_PPrmD - Error return from Compute_OP_Matrix")
	// Throw("Reg_PPrmD - Error return from Compute_OP_Matrix")
	// AppendToLogFile(1, "Reg_PPrmD - Error return from Compute_OP_Matrix") 
	// goto badquit
		
	badupskim:
     Throw("Reg_PPrmD - Error return from Update_Drive_Skim_Mtx")
	// msg = rtn_upskim[2] + {"Reg_PPrmD - Error return from Update_Drive_Skim_Mtx"}
	// AppendToLogFile(1, "Reg_PPrmD - Error return from Update_Drive_Skim_Mtx") 
	// goto badquit

	badbuildtrannet:
     Throw("Reg_PPrmD - Error return build transit network")
	// Throw("Reg_PPrmD - Error return build transit network")
	// AppendToLogFile(1, "Reg_PPrmD - Error return build transit network") 
	// goto badquit

	badtransettings:
     Throw("Reg_PPrmD - Error return from transit network settings")
	// Throw("Reg_PPrmD - Error return from transit network settings")
	// AppendToLogFile(1, "Reg_PPrmD - Error return from transit network settings") 
	// goto badquit

	badtranskim:
     Throw("Reg_PPrmD - Error return from transit network skims")
	// Throw("Reg_PPrmD - Error return from transit network skims")
	// AppendToLogFile(1, "Reg_PPrmD - Error return from transit network skims")
	// goto badquit

	badmatrixop:
     Throw("Reg_PPrmD - Error in matrix operations")
	// Throw("Reg_PPrmD - Error in matrix operations")
	// AppendToLogFile(1, "Reg_PPrmD - Error in matrix operations")
	// goto badquit

	badxpr_stopflags:
     Throw(rtnmsg)
	// Throw(rtnmsg)
	// AppendToLogFile(2, rtnmsg)
	// Throw("Reg_PPrmW - Error return from XPR_StopFlags")
	// AppendToLogFile(1, "Reg_PPrmW - Error return from XPR_StopFlags")
	// goto badquit

	badquit:
	Throw("badquit: Last error message= " + GetLastError())
	AppendToLogFile(2, "badquit: Last error message= " + GetLastError())
    RunMacro("TCB Closing", 0, "TRUE" ) 
	RegPPrmDOK = 0
	goto quit
 	
quit:

    RunMacro("close everything")
    
	datentime = GetDateandTime()
	AppendToLogFile(1, "Exit Reg_PPrmD: " + datentime)
	AppendToLogFile(1, " ")

	return({RegPPrmDOK, msg})


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