Macro "Reg_BusW" (Args)

// Modified for new UI - Nov, 2015 - McLelland
// Commented out pkzip for skim file and delete - (lines 542+)
// 5/30/19, mk: There are now three distinct networks, use offpeak since was used to setup route system

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
	RegPBusWOK = 1
	msg = null
		
	datentime = GetDateandTime()
	AppendToLogFile(1, "Enter Reg_PBusW: " + datentime)
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
			Throw(rtnmsg)
			// Throw(rtnmsg)
			// AppendToLogFile(2, rtnmsg)
		end


	// --- Setup the network names

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


on notfound default
setview("Vehicle Routes")

// ----------------------------------- Loop by 4 time periods  -----------------------------------

  time_periods = {"AM", "PM", "MD","NT"}
   
    for time_period in time_periods do

// ----------------------------------- STEP 1: Build Transit Network  -----------------------------------

		RunMacro("TCB Init")

		Opts = RunMacro("create_tnet", time_period, "bus", "walk", Dir)
		ret_value = RunMacro("TCB Run Operation", 1, "Build Transit Network", Opts) 

		if !ret_value then goto badbuildtrannet

	// ----------------------------------- STEP 2: Transit Network Setting  -----------------------------------


		Opts = RunMacro("set_tnet", time_period, "bus", "walk", Dir)
			ret_value = RunMacro("TCB Run Operation", 2, "Transit Network Setting PF", Opts)

		if !ret_value then goto badtransettings


	// ----------------------------------- STEP 3: Transit Skim Path Finder  -----------------------------------
		// skip PM and NT as same skimming used

		if time_period = "PM" then goto skiptransskim
		if time_period = "NT" then goto skiptransskim
	
		Opts = null
		Opts.Input.Database = net_file 
		Opts.Input.[Transit RS] = route_file
		Opts.Input.Network = Dir + "\\BusW_" + time_period + ".tnw"
		Opts.Input.[Origin Set] = {net_file + "|" + node_lyr, node_lyr,"Centroids","Select * where centroid = 1 or [External Station] = 1"}
		Opts.Input.[Destination Set] = {net_file + "|" + node_lyr, node_lyr,"Centroids"}
		Opts.Global.[Skim Var] = {"Generalized Cost", "Fare", "In-Vehicle Time", "Initial Wait Time", "Transfer Wait Time", "Transfer Penalty Time", "Transfer Walk Time", "Access Walk Time", "Egress Walk Time", "Dwelling Time", "Number of Transfers", "In-Vehicle Distance", "Length", "TTWalk*"}
		Opts.Global.[OD Layer Type] = 2
		Opts.Global.[Skim Modes] = {5, 6, 7, 8, 9, 10, 11}
		Opts.Output.[Skim Matrix].Label = "Skim Matrix (Pathfinder)"
		Opts.Output.[Skim Matrix].[File Name] = Dir + "\\skims\\TR_SKIM_PBusW.mtx"
	//ShowArray(Opts)
		ret_value = RunMacro("TCB Run Procedure", 3, "Transit Skim PF", Opts)

		if !ret_value then goto badtranskim

		// Check for local matrix cores (JWM 16.09.16) - add if necessary and initialize to null (clear)
		// 	matrix assignment ":=" please see help documentation for "Matrix Assignment Statement"

		OM = OpenMatrix(Dir + "\\skims\\TR_SKIM_PBusW.mtx", "True")

		matcores = GetMatrixCoreNames(OM)

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

		corepos = ArrayPosition(matcores, {"Drop Flag"},)
		if corepos = 0 then addmatrixcore(OM,"Drop Flag")
		c = CreateMatrixCurrency(OM, "Drop Flag",,,)
		c := null

		OM = null
		c = null




		c1 = null
		c2 = null
		M1 = null
		M2 = null


	//--- include the highway skim matrix as a part of Transit Skim Matrices

		hwyskim_matrix = Dir + "\\AutoSkims\\SPMAT_free.mtx"

		M1 = OpenMatrix(Dir+"\\skims\\TR_SKIM_PBusW.mtx", "True")
		M2 = OpenMatrix(hwyskim_matrix, "True")

		c1 = CreateMatrixCurrency(M2, "Non HOV Length", "Rows", "Columns",)
		c2 = CreateMatrixCurrency(M1, "Highway Skim", "RCIndex", "RCIndex",)
		MatrixOperations(c2, {c1}, {1},,, {{"Operation", "Add"}, {"Force Missing", "Yes"}})

		c1 = null
		c2 = null
		M1 = null
		M2 = null

	// -- path gets retained in the skims if the off-peak highway skim length is greater than 0.75 miles

	// -- For calibration year drop paths that use only GOLDRUSH (mode 9). 
	// -- For Application Years retain all paths that meet the minimum length criteria

	check:

	if (theyear = "2009") then do

	// --- Set the Drop Flag to identify the paths that get thrown out 

		//Method 11 - Formula
		Opts = {{"Input",    {{"Matrix Currency",   {Dir + "\\skims\\TR_SKIM_PBusW.mtx",
													"Drop Flag",
													"RCIndex",
													"RCIndex"}}}},
								{"Global",   {{"Method",            11},
											{"Cell Range",        2},
											{"Matrix K",          {1,1}},
											{"Expression Text",   "if (nz([Length (XCM)])+nz([Length (XPR)])+nz([Length (LOC)])+nz([Length (FDR)])+ nz([Length (SKS)])) = 0.0 and [In-Vehicle Time] <> null then 1"},
												{"Force Missing",     "Yes"}}}}

		ret_value = RunMacro("TCB Run Operation", 10, "Fill Matrices", Opts)
		if !ret_value then goto badmatrixop

		//Method 11 - formula
		Opts = {{"Input",    {{"Matrix Currency",   {Dir + "\\skims\\TR_SKIM_PBusW.mtx",
													"InVehGT5",
													"RCIndex",
													"RCIndex"}}}},
									{"Global",   {{"Method",            11},
												{"Cell Range",        2},
												{"Matrix K",          {1,1}},
												{"Expression Text",   "if (nz([Length (XCM)])+ nz([Length (XPR)])+ nz([Length (LOC)])+nz([Length (FDR)])+ nz([Length (SKS)]))>0.0 and [Highway Skim] > 0.75 then [In-Vehicle Time]"},
												{"Force Missing",     "Yes"}}}}

		ret_value = RunMacro("TCB Run Operation", 11, "Fill Matrices", Opts)
		if !ret_value then goto badmatrixop

	end else do	   // -- application years, do not drop the paths that occur only on feeders or goldrush

		//Method 11 - formula
		Opts = {{"Input",    {{"Matrix Currency",   {Dir + "\\skims\\TR_SKIM_PBusW.mtx",
													"InVehGT5",
													"RCIndex",
													"RCIndex"}}}},
									{"Global",  {{"Method",            11},
												{"Cell Range",        2},
												{"Matrix K",          {1,1}},
												{"Expression Text",   "if [Highway Skim] > 0.75 then [In-Vehicle Time]"},
													{"Force Missing",     "Yes"}}}}

		ret_value = RunMacro("TCB Run Operation", 12, "Fill Matrices", Opts)
		if !ret_value then goto badmatrixop
	end


		M1 = OpenMatrix(Dir + "\\skims\\TR_SKIM_PBusW.mtx", "True")
		c2 = CreateMatrixCurrency(M1, "Dwelling Time", "RCIndex", "RCIndex",)
		c3 = CreateMatrixCurrency(M1, "InVehGT5", "RCIndex", "RCIndex",)
		c4 = CreateMatrixCurrency(M1, "IVTT", "RCIndex", "RCIndex",)
			MatrixOperations(c4, {c2, c3}, {1, 1},,, {{"Operation", "Add"}, {"Force Missing", "Yes"}})
		c2 = null
		c3 = null
		c4 = null
		M1 = null


		M1 = OpenMatrix(Dir + "\\skims\\TR_SKIM_PBusW.mtx", "True")
		c1 = CreateMatrixCurrency(M1, "Transfer Wait Time", "RCIndex", "RCIndex",)
		c2 = CreateMatrixCurrency(M1, "Transfer Walk Time", "RCIndex", "RCIndex",)
		c3 = CreateMatrixCurrency(M1, "Access Walk Time", "RCIndex", "RCIndex",)
		c4 = CreateMatrixCurrency(M1, "Egress Walk Time", "RCIndex", "RCIndex",)
		c5 = CreateMatrixCurrency(M1, "Approach", "RCIndex", "RCIndex",)
			MatrixOperations(c5, {c1, c2, c3, c4}, {0.775193, 1, 1, 1},,, {{"Operation", "Add"}, {"Force Missing", "No"}})
		c1 = null
		c2 = null
		c3 = null
		c4 = null
		c5 = null
		c6 = null
		M1 = null


		M1 = OpenMatrix(Dir + "\\skims\\TR_SKIM_PBusW.mtx", "True")
			c1 = CreateMatrixCurrency(M1, "Fare", "RCIndex", "RCIndex",)
		c2 = CreateMatrixCurrency(M1, "Cost", "RCIndex", "RCIndex",)
			MatrixOperations(c2, {c1}, {100},,, {{"Operation", "Add"}, {"Force Missing", "Yes"}})
		c1 = null
		c2 = null
		M1 = null

	continuefromhere:
		// -- Populate the Skim Values in the Output Skim Matrix for use as an input to the Mode Split Model

		input_matrix = Dir + "\\skims\\TR_SKIM_PbusW.mtx"
		modesplit_matrix = Dir + "\\skims\\PK_WKTRAN_SKIMS.mtx"

		
	Opts = null

		Opts.Input.[Target Currency] = { modesplit_matrix, "IVTT - Bus Walk", "Rows", "Columns"}
		Opts.Input.[Source Currencies] = {{input_matrix, "IVTT", "RCIndex", "RCIndex"}}
		Opts.Global.[Missing Option].[Force Missing] = "Yes"

		ret_value = RunMacro("TCB Run Operation", 13, "Merge Matrices", Opts) 
		if !ret_value then goto badmatrixop


	//Opts = null
	//
	//   Opts.Input.[Target Currency] = { modesplit_matrix, "Approach - Bus Walk", "Rows", "Columns"}
	//     Opts.Input.[Source Currencies] = {{input_matrix, "Approach", "RCIndex", "RCIndex"}}
	//     Opts.Global.[Missing Option].[Force Missing] = "Yes"
	//
	//     ret_value = RunMacro("TCB Run Operation", 1, "Merge Matrices", Opts) 


	Opts = null

		Opts.Input.[Target Currency] = { modesplit_matrix, "Cost - Bus Walk", "Rows", "Columns"}
		Opts.Input.[Source Currencies] = {{input_matrix, "Cost", "RCIndex", "RCIndex"}}
		Opts.Global.[Missing Option].[Force Missing] = "Yes"

		ret_value = RunMacro("TCB Run Operation", 14, "Merge Matrices", Opts) 
		if !ret_value then goto badmatrixop

	//Opts = null
	//
	//     Opts.Input.[Target Currency] = { modesplit_matrix, "Xfers - Bus Walk", "Rows", "Columns"}
	//     Opts.Input.[Source Currencies] = {{input_matrix, "Number of Transfers", "RCIndex", "RCIndex"}}
	//     Opts.Global.[Missing Option].[Force Missing] = "Yes"
	//
	//     ret_value = RunMacro("TCB Run Operation", 1, "Merge Matrices", Opts) 

	Opts = null

		Opts.Input.[Target Currency] = { modesplit_matrix, "Initial Wait - Bus Walk", "Rows", "Columns"}
		Opts.Input.[Source Currencies] = {{input_matrix, "Initial Wait Time", "RCIndex", "RCIndex"}}
		Opts.Global.[Missing Option].[Force Missing] = "Yes"

		ret_value = RunMacro("TCB Run Operation", 15, "Merge Matrices", Opts) 
		if !ret_value then goto badmatrixop

	Opts = null

		Opts.Input.[Target Currency] = { modesplit_matrix, "Transfer Penalty Time - Bus Walk", "Rows", "Columns"}
		Opts.Input.[Source Currencies] = {{input_matrix, "Transfer Penalty Time", "RCIndex", "RCIndex"}}
		Opts.Global.[Missing Option].[Force Missing] = "Yes"

		ret_value = RunMacro("TCB Run Operation", 16, "Merge Matrices", Opts) 
		if !ret_value then goto badmatrixop

	Opts = null

		Opts.Input.[Target Currency] = { modesplit_matrix, "Access Walk Time - Bus Walk", "Rows", "Columns"}
		Opts.Input.[Source Currencies] = {{input_matrix, "Access Walk Time", "RCIndex", "RCIndex"}}
		Opts.Global.[Missing Option].[Force Missing] = "Yes"

		ret_value = RunMacro("TCB Run Operation", 17, "Merge Matrices", Opts) 
		if !ret_value then goto badmatrixop

	Opts = null

		Opts.Input.[Target Currency] = { modesplit_matrix, "Egress Walk Time - Bus Walk", "Rows", "Columns"}
		Opts.Input.[Source Currencies] = {{input_matrix, "Egress Walk Time", "RCIndex", "RCIndex"}}
		Opts.Global.[Missing Option].[Force Missing] = "Yes"

		ret_value = RunMacro("TCB Run Operation", 18, "Merge Matrices", Opts) 
		if !ret_value then goto badmatrixop

	Opts = null

		Opts.Input.[Target Currency] = { modesplit_matrix, "Transfer Walk Time - Bus Walk", "Rows", "Columns"}
		Opts.Input.[Source Currencies] = {{input_matrix, "Transfer Walk Time", "RCIndex", "RCIndex"}}
		Opts.Global.[Missing Option].[Force Missing] = "Yes"

		ret_value = RunMacro("TCB Run Operation", 19, "Merge Matrices", Opts) 
		if !ret_value then goto badmatrixop

	Opts = null

		Opts.Input.[Target Currency] = { modesplit_matrix, "Transfer Wait Time - Bus Walk", "Rows", "Columns"}
		Opts.Input.[Source Currencies] = {{input_matrix, "Transfer Wait Time", "RCIndex", "RCIndex"}}
		Opts.Global.[Missing Option].[Force Missing] = "Yes"

		ret_value = RunMacro("TCB Run Operation", 20, "Merge Matrices", Opts) 
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

		ret_value = RunMacro("TCB Run Operation", 21, "Fill Matrices", Opts)
		if !ret_value then goto badmatrixop

	// Add un-weighted total walk time, JainM, 09.20.11
	Opts = null

		Opts.Input.[Target Currency] = { modesplit_matrix, "Total Walk UnWtd - Bus", "Rows", "Columns"}
		Opts.Input.[Source Currencies] = {{input_matrix, "TTWalk* (WALK)", "RCIndex", "RCIndex"}}
		Opts.Global.[Missing Option].[Force Missing] = "Yes"

		ret_value = RunMacro("TCB Run Operation", 22, "Merge Matrices", Opts) 
		if !ret_value then goto badmatrixop


        skiptransskim: 
     

    end //time period loop

// -- archive the transit skim to save space 
goto quit
//	pkzip_program = METDir + "\\pgm\\pkzip25\\pkzip25.exe"
//	status = RunProgram(pkzip_program + " " + Dir+"\\skims\\TR_SKIM_pbusw.zip " +Dir+"\\skims\\TR_Skim_pbusw.mtx -Add",{{"Minimize", "True"}})

//	if status = 0 then DeleteFile(Dir+"\\skims\\TR_Skim_pbusw.mtx")

	badbuildtrannet:
	Throw("Reg_PBusW - Error return build transit network")
	// Throw("Reg_PBusW - Error return build transit network")
	// AppendToLogFile(1, "Reg_PBusW - Error return build transit network") 
	// goto badquit

	badtransettings:
	Throw("Reg_PBusW - Error return from transit network settings")
	// Throw("Reg_PBusW - Error return from transit network settings")
	// AppendToLogFile(1, "Reg_PBusW - Error return from transit network settings") 
	// goto badquit

	badtranskim:
	Throw("Reg_PBusW - Error return from transit network skims")
	// Throw("Reg_PBusW - Error return from transit network skims")
	// AppendToLogFile(1, "Reg_PBusW - Error return from transit network skims")
	// goto badquit

	badmatrixop:
	Throw("Reg_PBusW - Error in matrix operations")
	// Throw("Reg_PBusW - Error in matrix operations")
	// AppendToLogFile(1, "Reg_PBusW - Error in matrix operations")
	// goto badquit

	badxpr_stopflags:
	Throw("Reg_PrmW - Error return from XPR_StopFlags")
	// Throw(rtnmsg)
	// AppendToLogFile(2, rtnmsg)
	// Throw("Reg_PPrmW - Error return from XPR_StopFlags")
	// AppendToLogFile(1, "Reg_PPrmW - Error return from XPR_StopFlags")
	// goto badquit

	badquit:
	Throw("badquit: Last error message= " + GetLastError())
	AppendToLogFile(2, "badquit: Last error message= " + GetLastError())
    RunMacro("TCB Closing", 0, "TRUE" ) 
	RegPBusWOK = 0
	goto quit
 	
quit:

    RunMacro("close everything")
    
	datentime = GetDateandTime()
	AppendToLogFile(1, "Exit Reg_PBusW: " + datentime)
	AppendToLogFile(1, " ")

	return({RegPBusWOK, msg})


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