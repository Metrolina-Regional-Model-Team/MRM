Macro "PBusD_Assign" (Args)

	//Macro to assign Peak Premium walk approach trips
	//Modified for new UI, McLelland, Jan 2016
	// 5/30/19, mk: There are now three distinct networks: AM peak, PM peak, and offpeak; use AM for peak
	
	// LogFile = Args.[Log File].value
	// ReportFile = Args.[Report File].value
	// SetLogFileName(LogFile)
	// SetReportFileName(ReportFile)

	Dir = Args.[Run Directory]
	taz_file = Args.[TAZ File]
	theyear = Args.[Run Year]
	//hwy_file = Args.[AM Peak Hwy Name]
	hwy_file = Args.[Hwy Name]
	{, , netname, } = SplitPath(hwy_file)
		
	msg = null
	PBusDAssnOK = 1
	datentime = GetDateandTime()
	AppendToLogFile(1, "Enter PBusD_Assign: " + datentime)

	shared route_file, routename, net_file, link_lyr, node_lyr

	yearnet = Substring(theyear, 3, 2)
	analysis_year = yearnet

//	if taz_file = null then taz_file = ChooseFile({{"Standard", "*.dbd"}},"Specify the input TAZ layer (e.g. metrolina_taz2999.dbd", )

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

	Opts = RunMacro("create_tnet", "peak", "bus", "drive", Dir)
	ret_value = RunMacro("TCB Run Operation", 1, "Build Transit Network", Opts) 

	if !ret_value then goto badbuildtrannet

// ----------------------------------- STEP 2: Transit Network Setting  -----------------------------------

	Opts = RunMacro("set_tnet", "peak", "bus" , "drive", Dir)
	ret_value = RunMacro("TCB Run Operation", 2, "Transit Network Setting PF", Opts)

	if !ret_value then goto badtransettings

// ----------------------------------- STEP 3: Transit Assignment Setting  -----------------------------------

     Opts = null
     Opts.Input.[Transit RS] = route_file
     Opts.Input.Network = Dir + "\\PbusD.tnw"
     Opts.Input.[OD Matrix Currency] = {Dir + "\\tranassn\\Transit Assign Drive.mtx", "PbusD", "Rows", "Columns"}
     Opts.Output.[Flow Table] = Dir + "\\tranassn\\PbusD\\TASN_FLW.bin"
     Opts.Output.[Walk Flow Table] = Dir + "\\tranassn\\PbusD\\TASN_WFL.bin"
     Opts.Output.[OnOff Table] = Dir + "\\tranassn\\PbusD\\TASN_ONO.bin"

     ret_value = RunMacro("TCB Run Procedure", 3, "Transit Assignment PF", Opts)

// -- Running SP Assignment for Test Purposes
//     Opts.Global.[Load Method] = 1
//   ret_value = RunMacro("TCB Run Procedure", 1, "Transit Assignment SP", Opts)


	if !ret_value then goto badtranassn

	closemap()

	goto quit
			
	badbuildtrannet:
	Throw("PBusD_Assign - Error return build transit network")
	AppendToLogFile(1, "PBusD_Assign - Error return build transit network") 
	goto badquit

	badtransettings:
	Throw("PBusD_Assign - Error return from transit network settings")
	AppendToLogFile(1, "PBusD_Assign - Error return from transit network settings") 
	goto badquit

	badtranassn:
	Throw("PBusD_Assign - Error return from transit network skims")
	AppendToLogFile(1, "PBusD_Assign - Error return from transit network skims")
	goto badquit

	badxpr_stopflags:
	Throw(rtnmsg)
	AppendToLogFile(2, rtnmsg)
	Throw("PBusD_Assign - Error return from XPR_StopFlags")
	AppendToLogFile(1, "PBusD_Assign - Error return from XPR_StopFlags")
	goto badquit

	badquit:
	Throw("badquit: Last error message= " + GetLastError())
	AppendToLogFile(2, "badquit: Last error message= " + GetLastError())
	RunMacro("TCB Closing", 0, "TRUE" ) 
	PBusDAssnOK = 0
	goto quit
 	
	quit:
	
	datentime = GetDateandTime()
	AppendToLogFile(1, "Exit PBusD_Assign: " + datentime)
	AppendToLogFile(1, " ")

	return({PBusDAssnOK, msg})

endMacro	
