Macro "Reg_PrmW" (Args)
// Modified for new UI - Nov, 2015 - McLelland
// Commented out pkzip for skim file and delete - (lines 542+)
// 5/30/19, mk: There are now three distinct networks, use offpeak since was used to setup route system - dropped in 2024 to one network
// 7/30/25, ar: Loop through four time periods to build and set transit network and skims for each 

	shared route_file, routename, net_file, link_lyr, node_lyr

	METDir = Args.[MET Directory]
	Dir = Args.[Run Directory]
	taz_file = Args.[TAZ File]
	theyear = Args.[Run Year]
	hwy_file = Args.[Hwy Name]
	{, , netname, } = SplitPath(hwy_file)
		
	curiter = Args.[Current Feedback Iter]
	RegPPrmWOK = 1
	msg = null

	datentime = GetDateandTime()
	AppendToLogFile(1, "Enter Reg_PPrmW: " + datentime)
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

	ID = "Key"

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

        Opts = RunMacro("create_tnet", time_period, "premium", "walk", Dir)
        ret_value = RunMacro("TCB Run Operation", 1, "Build Transit Network", Opts) 
        if !ret_value then goto badbuildtrannet
    
    // ----------------------------------- STEP 2: Transit Network Setting  -----------------------------------

        Opts = RunMacro("set_tnet", time_period, "premium", "walk", Dir)
        ret_value = RunMacro("TCB Run Operation", 2, "Transit Network Setting PF", Opts)
        if !ret_value then Throw("PrmW- Error return from transit network settings")

    // ----------------------------------- STEP 3: Transit Skim Path Finder  -----------------------------------

        Opts = null
        Opts.Input.Database = net_file 
        Opts.Input.[Transit RS] = route_file
      
        Opts.Input.Network = Dir + "\\PrmW_" + time_period + ".tnw"
        Opts.Input.[Origin Set] = {net_file + "|" + node_lyr, node_lyr,"Centroids","Select * where centroid = 1 or [External Station] = 1"}
        Opts.Input.[Destination Set] = {net_file + "|" + node_lyr, node_lyr,"Centroids"}
        if time_period = "AM" or time_period = "PM" then do
            Opts.Output.[Skim Matrix].[File Name] = Dir + "\\skims\\TR_SKIM_PPrmW.mtx" 
            Opts.Global.[Skim Var] = {"Generalized Cost", "Fare", "In-Vehicle Time", "Initial Wait Time", "Transfer Wait Time", "Transfer Penalty Time", "Transfer Walk Time", "Access Walk Time", "Egress Walk Time", "Dwelling Time", "Number of Transfers", "In-Vehicle Distance", "Length", "BRT_Flag", "TTPkLoc*", "TTWalk*"}
        end
        if time_period = "MD" or time_period = "NT" then do
            Opts.Output.[Skim Matrix].[File Name] = Dir + "\\skims\\TR_SKIM_OPPrmW.mtx"
             Opts.Global.[Skim Var] = {"Generalized Cost", "Fare", "In-Vehicle Time", "Initial Wait Time", "Transfer Wait Time", "Transfer Penalty Time", "Transfer Walk Time", "Access Walk Time", "Egress Walk Time", "Dwelling Time", "Number of Transfers", "In-Vehicle Distance", "Length", "BRT_Flag", "TTFrLoc*", "TTWalk*"} 
        end
           
        Opts.Global.[OD Layer Type] = 2
        Opts.Global.[Skim Modes] = {1, 2, 3, 4, 5, 6, 10, 11}
        Opts.Output.[Skim Matrix].Label = "Skim Matrix (Pathfinder)"
      
       
        RunMacro("TCB Run Procedure", 3, "Transit Skim PF", Opts)
        if !ret_value then goto badtranskim

        // Check for local matrix cores (JWM 16.09.16) - add if necessary and initialize to null (clear)
        // 	matrix assignment ":=" please see help documentation for "Matrix Assignment Statement"
        if time_period = "AM" or time_period = "PM" then
                OM = OpenMatrix(Dir + "\\skims\\TR_SKIM_PPrmW.mtx", "True")
            else
                OM = OpenMatrix(Dir + "\\skims\\TR_SKIM_OPPrmW.mtx", "True")
        
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

        OM = null
        c = null

    //--- include the highway skim matrix as a part of Transit Skim Matrices

        hwyskim_matrix = Dir + "\\AutoSkims\\SPMAT_free.mtx"
        
        if time_period = "AM" or time_period = "PM" then
            M1 = OpenMatrix(Dir+"\\skims\\TR_SKIM_PPrmW.mtx", "True")
        else    
            M1 = OpenMatrix(Dir+"\\skims\\TR_SKIM_OPPrmW.mtx", "True")
        

        M2 = OpenMatrix(hwyskim_matrix, "True")

        c1 = CreateMatrixCurrency(M2, "Non HOV Length", "Rows", "Columns",)
        c2 = CreateMatrixCurrency(M1, "Highway Skim", "RCIndex", "RCIndex",)
        MatrixOperations(c2, {c1}, {1},,, {{"Operation", "Add"}, {"Force Missing", "Yes"}})

        c1 = null
        c2 = null
        M1 = null
        M2 = null


    // Compute BRT_Flag
        OM = null
        if time_period = "AM" or time_period = "PM" then
            OM = OpenMatrix(Dir + "\\skims\\TR_SKIM_PPrmW.mtx", "True")
        else
            OM = OpenMatrix(Dir + "\\skims\\TR_SKIM_OPPrmW.mtx", "True")

        on notfound do
            addmatrixcore(OM,"BRT_Flag")
            goto brtflg
        end
        
        SetMatrixCore(OM,"BRT_Flag")
        brtflg:
            if time_period = "AM" or time_period = "PM" then
                M1 = OpenMatrix(Dir + "\\skims\\TR_SKIM_PPrmW.mtx", "True")
            else
                M1 = OpenMatrix(Dir + "\\skims\\TR_SKIM_OPPrmW.mtx", "True")
    
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



    // -- path gets retained in the skims if the premium length exists and off-peak highway skim length is greater than 0.5 miles

        //Method 11 - Formula
        Opts = {{"Input",    {{"Matrix Currency",   {Dir + "\\skims\\TR_SKIM_PPrmW.mtx",
                                                    "InVehGT5",
                                                    "RCIndex",
                                                    "RCIndex"}}}},
                            {"Global",   {{"Method",            11},
                                        {"Cell Range",        2},
                                        {"Matrix K",          {1,1}},
                                        {"Expression Text",   "if (((nz([Length (LRT)]) + nz([Length (STR)]) + nz([Length (CMR)]) + nz([Length (BRT)])) > 0.0) or [BRT_Flag] > 0) and [Highway Skim] > 0.75 then [In-Vehicle Time]"},
                                        {"Force Missing",     "Yes"}}}}

        ret_value = RunMacro("TCB Run Operation", 9, "Fill Matrices", Opts)
        if !ret_value then goto badmatrixop

        if time_period = "AM" or time_period = "PM" then
            M1 = OpenMatrix(Dir + "\\skims\\TR_SKIM_PPrmW.mtx", "True")
        else
            M1 = OpenMatrix(Dir + "\\skims\\TR_SKIM_OPPrmW.mtx", "True")
        
        c2 = CreateMatrixCurrency(M1, "Dwelling Time", "RCIndex", "RCIndex",)
        c3 = CreateMatrixCurrency(M1, "InVehGT5", "RCIndex", "RCIndex",)
        c4 = CreateMatrixCurrency(M1, "IVTT", "RCIndex", "RCIndex",)
            MatrixOperations(c4, {c2, c3}, {1, 1},,, {{"Operation", "Add"}, {"Force Missing", "Yes"}})
        c2 = null
        c3 = null
        c4 = null
        M1 = null

        if time_period = "AM" or time_period = "PM" then
            M1 = OpenMatrix(Dir + "\\skims\\TR_SKIM_PPrmW.mtx", "True")
        else
            M1 = OpenMatrix(Dir + "\\skims\\TR_SKIM_OPPrmW.mtx", "True")

        c1 = CreateMatrixCurrency(M1, "Transfer Wait Time", "RCIndex", "RCIndex",)
        c2 = CreateMatrixCurrency(M1, "Transfer Walk Time", "RCIndex", "RCIndex",)
        c3 = CreateMatrixCurrency(M1, "Access Walk Time", "RCIndex", "RCIndex",)
        c4 = CreateMatrixCurrency(M1, "Egress Walk Time", "RCIndex", "RCIndex",)
        c5 = CreateMatrixCurrency(M1, "Approach", "RCIndex", "RCIndex",)
            MatrixOperations(c5, {c1, c2, c3, c4}, {1, 1, 1, 1},,, {{"Operation", "Add"}, {"Force Missing", "No"}})
        c1 = null
        c2 = null
        c3 = null
        c4 = null
        c5 = null

        M1 = null

        if time_period = "AM" or time_period = "PM" then
            M1 = OpenMatrix(Dir + "\\skims\\TR_SKIM_PPrmW.mtx", "True")
        else
            M1 = OpenMatrix(Dir + "\\skims\\TR_SKIM_OPPrmW.mtx", "True")
        
        c1 = CreateMatrixCurrency(M1, "Fare", "RCIndex", "RCIndex",)
        c2 = CreateMatrixCurrency(M1, "Cost", "RCIndex", "RCIndex",)
            MatrixOperations(c2, {c1}, {100},,, {{"Operation", "Add"}, {"Force Missing", "Yes"}})
        c1 = null
        c2 = null
        M1 = null


    // Compute the mode hierarchy and populate the matrix
        OM=null

        if time_period = "AM" or time_period = "PM" then
            OM = OpenMatrix(Dir + "\\skims\\TR_SKIM_PPrmW.mtx", "True")
        else
            OM = OpenMatrix(Dir + "\\skims\\TR_SKIM_OPPrmW.mtx", "True")
        
        on notfound do
            addmatrixcore(OM,"ModeFlag")
            goto modeflg
        end
    
        SetMatrixCore(OM,"ModeFlag")
        modeflg:
        on notfound default
            //Method 11 - Formula
            Opts = {{"Input",    {{"Matrix Currency",   {Dir + "\\skims\\TR_SKIM_PPrmW.mtx",
                                                        "ModeFlag",
                                                        "RCIndex",
                                                        "RCIndex"}}}},
                            {"Global",   {{"Method",            11},
                                        {"Cell Range",        2},
                                        {"Matrix K",          {1,1}},
                                        {"Expression Text",   "if (nz([Length (CMR)])>0 and IVTT>0) then 1 else if (nz([Length (LRT)])>0  and IVTT>0) then 2 else if (nz([Length (BRT)])>0  and IVTT>0) then 3  else if (nz([BRT_Flag])>0  and IVTT>0) then 3  else if (nz([Length (STR)])>0  and IVTT>0) then 4 else null"},
                                            {"Force Missing",     "Yes"}}}}

            if !RunMacro("TCB Run Operation", 10, "Fill Matrices", Opts) then goto badmatrixop


        // --- Update the ModFlag for StreetCar
        // --- StreetCar Mode Flag reset to null if the length of the trip on Street Car is less than 1.2 miles 
        // --  and one of the trip end is in CBD area

        skim_matrix = Dir + "\\skims\\TR_SKIM_PPrmW.mtx"

    // RunMacro("Update ModeFlag", Dir, skim_matrix)


    /////////////////////////////////////////////////mj


        // -- Populate the Skim Values in the Output Skim Matrix for use as an input to the Mode Split Model

        if time_period = "AM" or time_period = "PM" then
            input_matrix = Dir + "\\skims\\TR_SKIM_PPrmW.mtx"
        else
            input_matrix = Dir + "\\skims\\TR_SKIM_OPPRMW.mtx"
        
        if time_period = "AM" or time_period = "PM" then
            modesplit_matrix = Dir + "\\skims\\PK_WKTRAN_SKIMS.mtx"
        else 
	        modesplit_matrix = Dir + "\\skims\\OFFPK_WKTRAN_SKIMS.mtx"
        
        Opts = null

        Opts.Input.[Target Currency] = { modesplit_matrix, "IVTT - Prem Walk", "Rows", "Columns"}
        Opts.Input.[Source Currencies] = {{input_matrix, "IVTT", "RCIndex", "RCIndex"}}
        Opts.Global.[Missing Option].[Force Missing] = "Yes"

        ret_value = RunMacro("TCB Run Operation", 11, "Merge Matrices", Opts) 
        if !ret_value then goto badmatrixop

    // -- this section commented out as Approach is not being used 
    //RunMacro("TCB Init")
    //Opts = null
    //
    //   Opts.Input.[Target Currency] = { modesplit_matrix, "Approach - Prem Walk", "Rows", "Columns"}
    //     Opts.Input.[Source Currencies] = {{input_matrix, "Approach", "RCIndex", "RCIndex"}}
    //     Opts.Global.[Missing Option].[Force Missing] = "Yes"
    //
    //     ret_value = RunMacro("TCB Run Operation", 1, "Merge Matrices", Opts) 


        Opts = null

        Opts.Input.[Target Currency] = { modesplit_matrix, "Cost - Prem Walk", "Rows", "Columns"}
        Opts.Input.[Source Currencies] = {{input_matrix, "Cost", "RCIndex", "RCIndex"}}
        Opts.Global.[Missing Option].[Force Missing] = "Yes"

        ret_value = RunMacro("TCB Run Operation", 12, "Merge Matrices", Opts) 
        if !ret_value then goto badmatrixop

    //Opts = null
    //
    //   Opts.Input.[Target Currency] = { modesplit_matrix, "Xfers - Prem Walk", "Rows", "Columns"}
    //     Opts.Input.[Source Currencies] = {{input_matrix, "Number of Transfers", "RCIndex", "RCIndex"}}
    //   Opts.Global.[Missing Option].[Force Missing] = "Yes"
    //
    //   ret_value = RunMacro("TCB Run Operation", 1, "Merge Matrices", Opts) 

        Opts = null

        Opts.Input.[Target Currency] = { modesplit_matrix, "Initial Wait - Prem Walk", "Rows", "Columns"}
        Opts.Input.[Source Currencies] = {{input_matrix, "Initial Wait Time", "RCIndex", "RCIndex"}}
        Opts.Global.[Missing Option].[Force Missing] = "Yes"

        ret_value = RunMacro("TCB Run Operation", 13, "Merge Matrices", Opts) 
        if !ret_value then goto badmatrixop

        Opts = null

        Opts.Input.[Target Currency] = { modesplit_matrix, "Transfer Penalty Time - Prem Walk", "Rows", "Columns"}
        Opts.Input.[Source Currencies] = {{input_matrix, "Transfer Penalty Time", "RCIndex", "RCIndex"}}
        Opts.Global.[Missing Option].[Force Missing] = "Yes"

        ret_value = RunMacro("TCB Run Operation", 14, "Merge Matrices", Opts) 
        if !ret_value then goto badmatrixop

        Opts = null

        Opts.Input.[Target Currency] = { modesplit_matrix, "Access Walk Time - Prem Walk", "Rows", "Columns"}
        Opts.Input.[Source Currencies] = {{input_matrix, "Access Walk Time", "RCIndex", "RCIndex"}}
        Opts.Global.[Missing Option].[Force Missing] = "Yes"

        ret_value = RunMacro("TCB Run Operation", 15, "Merge Matrices", Opts) 
        if !ret_value then goto badmatrixop

        Opts = null

        Opts.Input.[Target Currency] = { modesplit_matrix, "Egress Walk Time - Prem Walk", "Rows", "Columns"}
        Opts.Input.[Source Currencies] = {{input_matrix, "Egress Walk Time", "RCIndex", "RCIndex"}}
        Opts.Global.[Missing Option].[Force Missing] = "Yes"

        ret_value = RunMacro("TCB Run Operation", 16, "Merge Matrices", Opts) 
        if !ret_value then goto badmatrixop

        Opts = null

        Opts.Input.[Target Currency] = { modesplit_matrix, "Transfer Walk Time - Prem Walk", "Rows", "Columns"}
        Opts.Input.[Source Currencies] = {{input_matrix, "Transfer Walk Time", "RCIndex", "RCIndex"}}
        Opts.Global.[Missing Option].[Force Missing] = "Yes"

        ret_value = RunMacro("TCB Run Operation", 17, "Merge Matrices", Opts) 
        if !ret_value then goto badmatrixop

        Opts = null

        Opts.Input.[Target Currency] = { modesplit_matrix, "Transfer Wait Time - Prem Walk", "Rows", "Columns"}
        Opts.Input.[Source Currencies] = {{input_matrix, "Transfer Wait Time", "RCIndex", "RCIndex"}}
        Opts.Global.[Missing Option].[Force Missing] = "Yes"

        ret_value = RunMacro("TCB Run Operation", 18, "Merge Matrices", Opts) 
        if !ret_value then goto badmatrixop

        Opts = null

        Opts.Input.[Target Currency] = { modesplit_matrix, "ModeFlag", "Rows", "Columns"}
        Opts.Input.[Source Currencies] = {{input_matrix, "ModeFlag", "RCIndex", "RCIndex"}}
        Opts.Global.[Missing Option].[Force Missing] = "Yes"

        ret_value = RunMacro("TCB Run Operation", 19, "Merge Matrices", Opts) 
        if !ret_value then goto badmatrixop

    // Add un-weighted total walk time, JainM, 09.20.11
        Opts = null

        Opts.Input.[Target Currency] = { modesplit_matrix, "Total Walk UnWtd - Prem", "Rows", "Columns"}
        Opts.Input.[Source Currencies] = {{input_matrix, "TTWalk* (WALK)", "RCIndex", "RCIndex"}}
        Opts.Global.[Missing Option].[Force Missing] = "Yes"

        ret_value = RunMacro("TCB Run Operation", 20, "Merge Matrices", Opts) 
        if !ret_value then goto badmatrixop

        Opts = null

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

        M=null
        M1=null
        OM = null

        Opts = {{"Input",    {{"Matrix Currency",   {modesplit_matrix,
                                                    "PrmOnly Flag",
                                                    "Rows",
                                                    "Columns"}}}},
            {"Global",   {{"Method",            11},
                            {"Cell Range",        2},
                            {"Matrix K",          {1,1}},
                            {"Expression Text",   "if (nz([IVTT - Prem Walk]) > 0) then 1 else 0"},
                            {"Force Missing",     "No"}}}}

        if !RunMacro("TCB Run Operation", 21, "Fill Matrices", Opts) then goto badmatrixop
    

     
end // for time_period

goto quit
//	pkzip_program = METDir + "\\pgm\\pkzip25\\pkzip25.exe"
//	status = RunProgram(pkzip_program + " " + Dir+"\\skims\\TR_SKIM_pprmw.zip " +Dir+"\\skims\\TR_Skim_pprmw.mtx -Add", {{"Minimize", "True"}})

//	if status = 0 then DeleteFile(Dir+"\\skims\\TR_Skim_pprmw.mtx")


	badbuildtrannet:
	Throw("Reg_PrmW- Error return build transit network")

	badtransettings:

	badtranskim:
	Throw("Reg_PrmW - Error return from transit network skims")

	badmatrixop:
	Throw("Reg_PrmW - Error in matrix operations")

	badxpr_stopflags:
	Throw(rtnmsg)


	badquit:
	Throw("badquit: Last error message= " + GetLastError())
	AppendToLogFile(2, "badquit: Last error message= " + GetLastError())
	RunMacro("TCB Closing", 0, "TRUE" ) 
	RegPPrmWOK = 0
	goto quit
 	
quit:

    RunMacro("close everything")
    
	datentime = GetDateandTime()
	AppendToLogFile(1, "Exit Reg_PPrmW: " + datentime)
	AppendToLogFile(1, " ")

	return({RegPPrmWOK, msg})

EndMacro

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

EndMacro