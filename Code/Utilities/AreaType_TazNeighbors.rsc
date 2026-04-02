DBox "AreaType_TAZNeighbors" Title: "Create TAZ Neighbors file for Area Type" 

	// Used to creat zone_pct file created to build a file with percentage of a TAZ's neighbors within 
	// a 1.5 mile buffer.  A new TAZNeighbors_pct file is necessary only when TAZ file changes.  
	//  McLelland, Aug, 2017

	init do
		progressbar = "false"
		msg = null
	enditem
	
	Text "tazname" 10, 2, 40 Framed Prompt: "TAZ file:" Variable: TAZFile Help:"TAZ file - may include external sta (TAZ > 12000)" 
	Button "gettaz" after, same Icon: "bmp\\buttons|148" Help: "TAZ file - may include external sta (TAZ > 12000)" do
		TAZFile = ChooseFile({{"Standard","*.dbd"}},"Open TAZ File to create TAZ Neighbors pct",)
	enditem
	text " " after, same
		
	text " " same, after
	Button " Run TAZ Neighbors " 10,after do

		//Set input file layernames and dataviews
		mapname = "MRM TAZ Map"  //set mapname
		Throw("AreaType_TAZNeighbors started")
		info = GetDBInfo(TAZFile)
		if info = null 
			then do
				Throw("TAZ File missing!")
				goto killjob
			end
		TAZSplit = SplitPath(TAZFile)
		TAZDir = TAZSplit[1] + TAZSplit[2]
		TAZRoot = TAZSplit[3]
		ZonePctFile = TAZDir + "TAZNeighbors_Pct.bin"

		//TAZs
		zonedb  = TAZFile
		zonelay = GetDBLayers(zonedb)
		zonename= TAZRoot
		zoneinfo= GetDBInfo(zonedb)
		scope   = zoneinfo[1]
		zset    = "Zone set"
		
		//Open map
		map1 = CreateMap(mapname,
			{{"Scope", scope}})
		SetMapUnits("Miles")
		AddLayer(map1,zonename,zonedb,zonelay[1])
		SetLayerVisibility(map1+"|"+zonename,"False")
		redrawmap(map1)

		SetView(zonename)

		// Cannot include external stations 
		on notfound goto nointernals
		selectquery = "select * where TAZ < 12000"
		NumTAZ = SelectByQuery("InternalTAZ", "Several", selectquery,)
		on notfound default
		//ShowMessage("Internal TAZ = " + i2s(NumTAZ))				

		// dropped attempt for taz as id - 
		//taznum = CreateExpression(view, "TAZNum", "TAZ",)
		//	 {"ID Field", zonename + ".TAZNum"}})

	  // temporary centroid database
		centdb = TAZDir + "TAZCentroids_temp.dbd"
		centname= "TAZCentroids"

		//export zone centroids to a new geographic file (centdb)
		ExportGeography(zonename + "|InternalTAZ",centdb,
			{{"Centroid", "Yes"},
			 {"Layer Name", centname},
			 {"Label", centname},
			 {"Fields", {"ID", "TAZ"}},
			 {"Field Spec",{zonename + ".ID", zonename + ".TAZ"}}})


		//Add centroids created in step above to the map - 
		AddLayer(map1,centname,centdb,centname)
		seticon(centname+"|", "Font Character", "Arial|Bold|10", 46)
		SetLayerVisibility(map1+"|"+centname,"False")
		redrawmap(map1)

		//tempoary bands
		banddb  = TAZDir + "temp_band.dbd"
		bandname= "Temporary Bands"
		bandsize= {1.50}

		//temporary area intersections
		IntXDataFile = TAZDir + "temp_xsec.asc"
		xdb    = TAZDir + "tempxsec.dbd"
		xname  = "Intersection Data"

		//Create output table
		outview = CreateTable("zonprcnt",ZonePctFile,"FFA",
			{{"TAZ","I",10,0,"Yes"},
			 {"TAZNeighbor","I",10,0,"Yes"},
			 {"Band_ID","I",3,0,"Yes"},
			 {"PercentIN","R",10,6,"No"}})
  
		CreateProgressBar("AreaType_TAZNeighbors pct (zone_pct)", "True")
		progressbar = "true"
		ticks = 1
		addtick = r2i(NumTAZ / 100) 
		if stat = "True" then goto killjob

		//set view and layer to centroids (i.e. centname)
		setview (centname)
		setlayer(centname)
		view=getview()
		layer=getlayer()

		// extra ID field for centroid file - used in merge later to add TAZ ID to output file
		cent_id = CreateExpression(view, "CENT_ID", "ID",)

		set="working zone"    //name selection set to use in processing

		ptr = GetFirstRecord(view + "|",{{"TAZ","Ascending"}})
		
		// Loop through all TAZ
		i = 0
//		for ii = 1 to 2 do
		while ptr <> null do
			rec = GetRecordValues(view, ptr, {"TAZ", "Longitude","Latitude"})
			curTAZ = rec[1][2]
			scurTAZ = i2s(curTAZ)
			centcoords = Coord(rec[2][2], rec[3][2])

			i = i + 1
			if Mod(i2r(i), i2r(addtick)) = 0
				then ticks = ticks + 1
			stat = UpdateProgressBar("AreaType_TAZNeighbors pct, TAZ " + scurTAZ, ticks)
			if stat = "True" then goto killjob
		
			//Select TAZ
			curTAZquery = "Select * where TAZ = " + scurTAZ
			nsel = SelectByQuery(set, "Several", curTAZquery,)
				
			//Build bands around selected zone
			bandlayer = "TAZband" 
			CreateBuffers(banddb,
				bandlayer,{set},"Value",bandsize,
				{{"Exterior","Merged"},
				 {"Arcs",50},
				 {"Units","Miles"},
				 {"Database Label",bandname}})

			bandlay=GetDBLayers(banddb)

			//Add Bands Layer to map
			bandlayers=GetDBLayers(banddb)
			AddLayer(map1,bandname,banddb,bandlay[1])

			//Select zones in the vicinity of the bands
			setlayer(zonename)
			zoneselect = SelectByQuery(zset, "Several", curTAZquery,)

			// Extended scope around centroid to 20 miles - 
			//	NO WAY the merge w/ 1.5 mile band will leave any TAZ out 
			zsetscope=Scope(centcoords,20.0,20.0,0.0)
			zoneselect=SelectByScope(zset,"More",zsetscope,{{"Source And","InternalTAZ"}})
  
			//Intersect area layers
			area1 = zonename+"|"+zset
			area2 = bandname
			ComputeIntersectionPercentages({area1,area2},IntXDataFile,{{"Database",xdb}})
  
			//Open the intersection data to process output
			xview = "PO"
			xview = Opentable(xview, "FFA", {IntXDataFile,})

			// Join with centroid file to pull TAZ ID 
//			setview(xview)
			TAZxview = JoinViews("TAZxview", xview + ".area_1", centname + ".CENT_ID",)
			setview(TAZxview)
				    	
			query="Select * where AREA_1 > 0 and AREA_2 > 0"

			count=SelectByQuery("output","Several",query,)
			j = 1

			//GET All RECORDs AND OUTPUT TO A NEW TABLE (outview)
			pos=GetFirstRecord(TAZxview + "|output",)
			xdata_fields=GetRecordsValues(TAZxview + "|output",pos,
				{"TAZ","AREA_2","PERCENT_1"},,count,"Row",)
    	             
	    		while j <= count do
				//Output the data fields
				out_rh=AddRecord(outview,
					{{"TAZ", curTAZ},
					 {"TAZNeighbor", xdata_fields[j][1]},
					 {"Band_ID", xdata_fields[j][2]},
					 {"PercentIN",xdata_fields[j][3]}})
    		  		j = j + 1
			end

			//drop bands layer, and close xview
			DropLayer(map1,bandname)
			CloseView(TAZxview)
			CloseView(xview)
    
			//Get next record
			setview(centname)
			view=getview()
			SelectNone(set)                 //Clear centroids selection set
			ptr = GetNextRecord(view+"|", , {{"TAZ","Ascending"}})
		end

		//Close table file
		Closeview(outview)
		CloseMap()
		goto done

		nointernals:
		Throw("No internal TAZ in TAZ file!")
		goto killjob

		
		killjob:
		Throw("AreaType_TAZNeighbors CANCELLED!")
		showarray(msg)
		goto done
		
		done:
		if progressbar = "true" then DestroyProgressBar()
		stopdatentime = GetDateandTime()
	enditem 

	text " " same, after
	Button " Cancel " 10, after Cancel do
		ShowMessage("AreaType_TAZNeighbors CANCELLED!")
		ShowArray(msg)
   		RunMacro("G30 File Close All")
		return()
	enditem 
	Button " Exit " 22, same do
		ShowArray(msg)
   		RunMacro("G30 File Close All")
   		return()
	enditem 


	Close Do
   		RunMacro("G30 File Close All")
   		return()
	EndItem  	
	
endDBox
