Macro "RouteSystemSetUp" (Args)
// 5/30/19, mk: There are now three distinct networks, use offpeak initially for transit set-up

	Dir = Args.[Run Directory]
	METDir = Args.[MET Directory]
	//net_file = Args.[Offpeak Hwy Name]
	net_file = Args.[Hwy Name]
	theyear = Args.[Run Year]

	datentime = GetDateandTime()
	AppendToLogFile(1, "Enter RouteSystemSetUp:  " + datentime)

	routename = "transys"
	route_file = Dir + "\\"+routename+".rts"
	{, , netname, } = SplitPath(net_file)
	ModifyRouteSystem(route_file, {{"Geography", net_file, netname},{"Link ID", "ID"}})
	map = CreateObject("Map", {FileName: route_file})

	// Get the scope of a geographic file

	info = GetDBInfo(net_file)
	scope = info[1]
	
	ReloadRouteSystem(route_file)
	VerifyRouteSystem(route_file, "Connected")
	nottagged = TagRouteStopsWithNode("Vehicle Routes", null, "UserID", 0.02)
	if nottagged > 0 
		then do
			Throw("RouteSystemSetUp ERROR!, " + i2s(nottagged) + " stops not tagged to node!")
		end	
	//map = null

	SetLayer("Vehicle Routes")
	qry = 'Select * where ALT_Flag = 2 ' // If ALT_Flag = 2 route is not built
	num_recs = SelectByQuery("Drop", "Several", qry,)
	if num_recs > 0 then do
		dim delete_array[num_recs]
			rh = GetFirstRecord("Vehicle Routes|Drop",)
			vals = GetRecordsValues("Vehicle Routes|Drop", rh, {"[Route_Name]"},,,,) 
			for n = 1 to num_recs do
				delete_array[n] = vals[1][n] // 1st element is field, 2nd element is value another day!
				//ShowArray(vals)
			end
			//ShowArray(delete_array)
		DeleteRoutes("Vehicle Routes", delete_array)
	end

	datentime = GetDateandTime()
	AppendToLogFile(1, "Build Networks: exit Route System Set Up  " + datentime)
	
endMacro
