Macro "XPR_StopFlags"  (Args)
// -- This Macro Flags the express stops in CBD other regions as board/alight only
//	and sets PRM_FLAG stops for premium route stops
//	Updated from AECOM xpr_stopflags for TC ver 7.
// 5/30/19, mk: There are now three distinct networks, use offpeak for Free

	Dir = Args.[Run Directory]
	theyear = Args.[Run Year]
	taz_file = Args.[TAZ File]
	yearnet = right(theyear,2)
	//hwy_file = Args.[Offpeak Hwy Name]
	hwy_file = Args.[Hwy Name]
	{, , netname, } = SplitPath(hwy_file)


	xprflagerr = 1
	msg = null
	
	analysis_year = Substring(theyear, 3, 2)

	RunMacro("G30 File Close All")
	RunMacro("TCB Init")


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

	route_layer = rtelyr[1]
	stop_layer = rtelyr[2]
	//	showmessage("stop_layer: " + stop_layer)

	// TRANSYS route stops layer
	
	SetView(stop_layer)

	// -- check if XPR_FLAG & PRM_FLAG exist on ROUTE STOPS layer, add if necessary
	addxpr = 0
	addprm = 0
	field_array = GetFields (stop_layer, "All")
	fld_names = field_array [1]
	fld_specs = field_array [2]

	for k = 1 to fld_names.length do
		if (fld_names [k] = "XPR_FLAG") then addxpr = 1
		if (fld_names [k] = "PRM_FLAG") then addprm = 1
	end

	// add fields if necessary
	if addxpr = 0  
		then do
			strct = GetTableStructure(stop_layer)
			for i = 1 to strct.length do
				strct[i] = strct[i] + {strct[i][1]}
			end
			new_struct = strct + {{"XPR_FLAG", "Integer", 8, null, "False",,,, null}}
			ModifyTable(stop_layer, new_struct)
		end

	if addprm = 0  
		then do
			strct = GetTableStructure(stop_layer)
			for i = 1 to strct.length do
				strct[i] = strct[i] + {strct[i][1]}
			end
			new_struct = strct + {{"PRM_FLAG", "Integer", 8, null, "False",,,, null}}
		ModifyTable(stop_layer, new_struct)
	end


	// Initialize fields XPR_FLAG & PRM_FLAG to zero
	// on error, notfound goto badinitialize
	SetRecordsValues(stop_layer + "|", {{"XPR_FLAG"}, null}, "Value", {0},)
	SetRecordsValues(stop_layer + "|", {{"PRM_FLAG"}, null}, "Value", {0},)
	on error, notfound default


	//	Route Stops joined to routes.dbf - using RTE_ID (TC internal route_id, filled above)
	//StopsRoutesView = joinviews("StopsRoutesView", stop_layer + ".Route_ID", "ROUTES.RTE_ID",)
	StopsRoutesView = joinviews("StopsRoutesView", stop_layer + ".Route_ID", "[Vehicle Routes].Route_ID",)
	
	//Fill PRM_FLAG - all active Premium service stops
	prm_stop_select = "Select * where Mode < 5 and ALT_FLAG = 1"
	n_prm_stop = SelectByQuery("Premium Stops", "Several", prm_stop_select,)

	// Fill the PRM_FLAG field with ones for all the active Premium transit stops
	if n_prm_stop > 0
		then SetRecordsValues("StopsRoutesView|Premium Stops", {{"PRM_FLAG"}, null}, "Value", {1},)
		else do
			Throw("XPR_StopFlags: WARNING - No Premium stops flagged (PRM_Flag)")
			// xprflagerr = 2
			// Throw("XPR_StopFlags: WARNING - No Premium stops flagged (PRM_Flag)")
		end

	
	// EXPRESS STOPS FLAG - AECOM called this CBD
	//	filled initially from \ms_control_template\taz_atype_transit_flags.dbf 
	//	flags CBD and a few other areas outside - lots of Indep corr, a few other areas .  CODED BY AECOM - FIND DOCUMENTATION

	// Add the TAZ Layer to map 

	tazlayers = GetDBLayers(taz_file)
	taz_lyr = AddLayer(net, tazlayers[1], taz_file, tazlayers[1])

	// Get EXP_FLAG from TAZ file and create TAZ selection set - TAZ XPR Flag
	zone_file = Dir+"\\TAZ_ATYPE.bin"
	zone_vw = OpenTable("TAZ_ATYPE", "FFB", {zone_file, })

	SetView(taz_lyr)
	tazviewAT = joinviews("tazviewAT", taz_lyr + ".TAZ", zone_vw + ".ZONE",)

	SetView(tazviewAT)
	query = "Select * where EXP_FLAG = 1"
	n_taz_xpr = SelectByQuery("TAZ XPR Flag", "Several", query, )
	if n_taz_xpr = 0 
		then do
			Throw("XPR_StopFlags: WARNING - No TAZ flagged with XPR_FLAG")
			// xprflagerr = 2
			// Throw("XPR_StopFlags: WARNING - No TAZ flagged with XPR_FLAG")
		end
		
	// Back to route stops layer, still joined to routes.dbf
	//		Selection sets - 
	//			Express Stops - mode 5 or 6
	//			Inbound	
	//			XPR_Flag Stops - stops within TAZ flagged by XPR_FLAG 	

	SetView(StopsRoutesView)

	query = "Select * where Mode = 5 or Mode = 6"
	n_xpr_stops = SelectByQuery("Express Stops", "Several", query,)

	query = "Select * where IO = \"I\""
	n_inbound = SelectByQuery("Inbound Route Stops", "Several", query,)

	query = "Select * where IO = \"O\""
	n_outbound = SelectByQuery("Outbound Route Stops", "Several", query,)
	
	// may need to setview(stop_layer)
	if n_taz_xpr > 0
		then do
			SetSelectInclusion("Enclosed")
			n_Stop_Xpr_Flag = SelectByVicinity ("XPR_Flag Stops", "Several", taz_lyr+"|TAZ XPR Flag", 0)
		end
		else n_Stop_Xpr_Flag = 0
		
	// Combine sets
	n_ExpIn = SetAnd("Express Inbound" ,{"Express Stops", "Inbound Route Stops", "XPR_Flag Stops"})
	n_ExpOut = SetAnd("Express Outbound" ,{"Express Stops", "Outbound Route Stops", "XPR_Flag Stops"})

	if n_ExpIn > 0
		then SetRecordsValues("StopsRoutesView|Express Inbound", {{"XPR_FLAG"}, null}, "Value", {2},)  //Alight only
		else do 
			Throw("XPR_StopFlags: WARNING - No Express Inbound stops flagged (XPR_FLAG = 2)")
			// xprflagerr = 2
			// Throw("XPR_StopFlags: WARNING - No Express Inbound stops flagged (XPR_FLAG = 2)")
		end

	if n_ExpOut > 0
		then SetRecordsValues("StopsRoutesView|Express Outbound", {{"XPR_FLAG"}, null}, "Value", {1},)  //Board only
		else do 
			Throw("XPR_StopFlags: WARNING - No Express Outbound stops flagged (XPR_FLAG = 1)")
			// xprflagerr = 2
			// Throw("XPR_StopFlags: WARNING - No Express Outbound stops flagged (XPR_FLAG = 1)")
		end

	CloseView(zone_vw)
	CloseView(tazviewAT)
	CloseView(StopsRoutesView)        
	CloseMap()

	goto quit

	badinitialize:
	xprflagerr = 3
	Throw("XPR_StopFlags: ERROR - Could not initialize Route Stops EXP_FLAG and/or PRM_FLAG")
	// Throw("XPR_StopFlags: ERROR - Could not initialize Route Stops EXP_FLAG and/or PRM_FLAG")
	// goto quit

	quit:
		return({xprflagerr, msg})

endMacro