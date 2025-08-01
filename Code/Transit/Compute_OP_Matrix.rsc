Macro "Compute_OP_Matrix"(time_period,transit_mode,access_mode, Args)

    shared route_file, routename, net_file, link_lyr, node_lyr


	// LogFile = Args.[Log File].value
	// ReportFile = Args.[Report File].value
	// SetLogFileName(LogFile)
	// SetReportFileName(ReportFile)

	Dir = Args.[Run Directory]
		
	msg = null
	ComputeOPMatrixOK = 1
	datentime = GetDateandTime()
	AppendToLogFile(2, "Enter Compute OP Matrix: " + datentime)


// STEP0:
//-------------------Close joined view Node Layer with Station Database-----------------------------------

on notfound default

if (access_mode="drive") then do

    views = GetViewNames()
    for i=1 to views.length do
       if views[i] = "Nodes+Stations" then CloseView(views[i])
    end

// Populate Shadow price
    SetStatus(2, "Update PNR Shadow Price",)

    NewFlds=null
    // Add new field to node layer
    NewFlds = {{"Shadow_Price", "real"}}
    ret_value = RunMacro("TCB Run Macro", 1, "TCB Add View Fields", {node_lyr, NewFlds}) 
    if !ret_value then goto badaddfield

    setview(node_lyr)
    pnr_file=Dir + "\\STATION_DATABASE.dbf"
    pnr_vw=opentable("STATION_DATABASE", "DBASE", {pnr_file,})

//--------------------------------- Joining Node Layer with Station Database -----------------------------------

    
    Opts = {{"Input",  {{"Dataview Set", {{net_file + "|" + node_lyr, pnr_file, "NODE.ID", "STATION_DATABASE.ID"}, "Nodes+PNR"}}}},
            {"Global", {{"Fields",       {"[Shadow_Price]"}},
                        {"Method",        "Formula"},
                        {"Parameter",     {"if "+pnr_vw+".[PNR_CAT] = 1 and "+pnr_vw+".PNR>0 then 9.0 else if "+pnr_vw+".[PNR_CAT] = 2 and "+pnr_vw+".PNR>0 then 6 else if "+pnr_vw+".[PNR_CAT] = 3 and "+pnr_vw+".PNR>0 then 3 else 0.0 "}}}}} 
    if !RunMacro("TCB Run Operation", 2, "Fill Dataview", Opts) then goto badfill

    //set the default shadow price to 0
    Opts = {{"Input",  {{"Dataview Set", {net_file + "|" + node_lyr}}}},
            {"Global", {{"Fields",       {"Shadow_Price"}},
                        {"Method",        "Formula"},
                        {"Parameter",     {"if [" + node_lyr + "].[Shadow_Price] > 0.0 then [" + node_lyr + "].[Shadow_Price] else 0.0"}}}}} 
    if !RunMacro("TCB Run Operation", 3, "Fill Dataview", Opts) then goto badfill
    closeview(pnr_vw)


    setview(node_lyr)

    opentable("STATION_DATABASE", "DBASE", {Dir + "\\STATION_DATABASE.dbf",})

    nodes_view = joinviews("Nodes+Stations", node_lyr + ".ID", "STATION_DATABASE.ID",)

end

// STEP 1: Build Highway Network
     Opts = null
     Opts.Input.[Link Set] = {net_file + "|" + link_lyr, link_lyr, "hwyskims", "Select * where (funcl > 0 and funcl < 10) or funcl = 82 or funcl = 84 or funcl = 90 or funcl = 92 or funcl = 85"}
     Opts.Global.[Network Options].[Link ID] = link_lyr+".ID"
     Opts.Global.[Network Options].[Node ID] = node_lyr+".ID"
     Opts.Global.[Network Options].[Turn Penalties] = "Yes"
     Opts.Global.[Network Options].[Keep Duplicate Links] = "FALSE"
     Opts.Global.[Network Options].[Ignore Link Direction] = "FALSE"
     Opts.Global.[Link Options] = {{"Length", link_lyr+".Length", link_lyr+".Length"}, {"TTPkAssn*", link_lyr+".TTPkAssnAB", link_lyr+".TTPkAssnBA"}, {"TTfree*", link_lyr+".TTfreeAB", link_lyr+".TTfreeBA"}}
     Opts.Global.[Node Options].ID = "Node.ID"
     Opts.Output.[Network File] = Dir + "\\pnr_net.net"

     ret_value = RunMacro("TCB Run Operation", 4, "Build Highway Network", Opts)

     if !ret_value then goto badhwynet
// STEP 2: Highway Network Setting
     Opts = null
     Opts.Input.Database = net_file
     Opts.Input.Network = Dir + "\\pnr_net.net"
     Opts.Input.[Centroids Set] = {net_file + "|" + node_lyr, node_lyr,"Centroids","Select * where centroid = 1 or [External Station] = 1"}

     ret_value = RunMacro("TCB Run Operation", 5, "Highway Network Setting", Opts)

     if !ret_value then goto badhwysettings

// STEP 3a: TCSPMAT Free SPEED
if (time_period = "MD" or time_period = "NT") then do
     Opts = null
     Opts.Input.Network = Dir + "\\pnr_net.net"
     Opts.Input.[Origin Set] = {net_file + "|" + node_lyr, node_lyr, "centroid", "Select * where Centroid = 1 or [External Station] = 1"}
     if (access_mode="drive") then do
         if(transit_mode="premium") then Opts.Input.[Destination Set] = {net_file + "|" + node_lyr, "Nodes+Stations","Park & Ride", "Select * where PNR = 1 or PNR = 2"}
         if(transit_mode="premium2") then Opts.Input.[Destination Set] = {net_file + "|" + node_lyr, "Nodes+Stations","Park & Ride", "Select * where PNR = 2"}
         if(transit_mode="bus") then Opts.Input.[Destination Set] = {net_file + "|" + node_lyr, "Nodes+Stations","Park & Ride", "Select * where PNR = 1"}
     end
     if (access_mode="dropoff") then Opts.Input.[Destination Set] = {net_file + "|" + node_lyr, "Nodes+Stations","Kiss & Ride", "Select * where KNR = 1 or KNR = 2 or KNR = 3"}
     Opts.Input.[Via Set] = {net_file + "|" + node_lyr, node_lyr}
     Opts.Field.Minimize = "TTFree*"
     Opts.Field.Nodes = "Node.ID"
     Opts.Field.[Skim Fields].Length = "All"
     Opts.Field.[Skim Fields].[TTFree*] = "All"
     Opts.Field.[Skim Fields].[TTPkAssn*] = "All"

     if (access_mode="drive") then do 
         if(transit_mode="premium") then Opts.Output.[Output Matrix].Label = "OP_PrmSkim_OffPeak"
         if(transit_mode="premium") then Opts.Output.[Output Matrix].[File Name] = Dir + "\\skims\\skim_pnr_offpeak_prm.mtx"
         if(transit_mode="premium2") then Opts.Output.[Output Matrix].Label = "OP_Prm2Skim_OffPeak"
         if(transit_mode="premium2") then Opts.Output.[Output Matrix].[File Name] = Dir + "\\skims\\skim_pnr_offpeak_prm2.mtx"
         if(transit_mode="bus") then Opts.Output.[Output Matrix].Label = "OP_BusSkim_OffPeak"
         if(transit_mode="bus") then Opts.Output.[Output Matrix].[File Name] = Dir + "\\skims\\skim_pnr_offpeak_bus.mtx"
     end

     if (access_mode="dropoff") then do 
         Opts.Output.[Output Matrix].Label = "KNR_Skim_OffPeak"
         Opts.Output.[Output Matrix].[File Name] = Dir + "\\skims\\skim_knr_offpeak.mtx"
     end

     ret_value = RunMacro("TCB Run Procedure", 6, "TCSPMAT", Opts)
     if !ret_value then goto badtcspmat
     
     // Juggle matrix names and values so that free flow times are stored in third core as some programs use core numbers.
     
     if (access_mode="drive" and transit_mode="premium") then mat_file=Dir + "\\skims\\skim_pnr_offpeak_prm.mtx"
     if (access_mode="drive" and transit_mode="premium2") then mat_file=Dir + "\\skims\\skim_pnr_offpeak_prm2.mtx"
     if (access_mode="drive" and transit_mode="bus") then mat_file=Dir + "\\skims\\skim_pnr_offpeak_bus.mtx"
     if (access_mode="dropoff") then mat_file=Dir + "\\skims\\skim_knr_offpeak.mtx"
     
     Opts = null
     Opts.Input.[Input Matrix] = mat_file 
     Opts.Input.[Target Core] = "TTPkAssn* (Skim)" 
     Opts.Input.[Core Name] = "TTFree* (Skim) - Copy" 
     RunMacro("TCB Run Operation", "Rename Matrix Core", Opts) 
     
     temp_mtx  = OpenMatrix(mat_file, "FALSE")
     midx      = GetMatrixIndex(temp_mtx)
     temp_mc1=CreateMatrixCurrency(temp_mtx, "TTFree* (Skim)", midx[1], midx[2], )
     temp_mc2=CreateMatrixCurrency(temp_mtx, "TTFree* (Skim) - Copy", midx[1], midx[2], )
        
     temp_mc2 := NullToZero(temp_mc1)
     
     Opts=null
     temp_mtx=null
     temp_mc1=null
     temp_mc2=null
     mat_file=null
     midx=null

/////////////////////////////////////
// Compute PNR Station  to Destination Distance. This is used to nullify paths which park very close to PNR / Drop-Off location
     Opts = null
     Opts.Input.Network = Dir + "\\pnr_net.net"
     if (access_mode="drive") then do
         if(transit_mode="premium") then Opts.Input.[Origin Set] = {net_file + "|" + node_lyr, "Nodes+Stations","Park & Ride", "Select * where PNR = 1 or PNR = 2"}
         if(transit_mode="premium2") then Opts.Input.[Origin Set] = {net_file + "|" + node_lyr, "Nodes+Stations","Park & Ride", "Select * where PNR = 2"}
         if(transit_mode="bus") then Opts.Input.[Origin Set] = {net_file + "|" + node_lyr, "Nodes+Stations","Park & Ride", "Select * where PNR = 1"}
     end
     if (access_mode="dropoff") then Opts.Input.[Origin Set] = {net_file + "|" + node_lyr, "Nodes+Stations","Kiss & Ride", "Select * where KNR = 1 or KNR = 2 or KNR = 3"}
     Opts.Input.[Destination Set] = {net_file + "|" + node_lyr, node_lyr, "centroid", "Select * where Centroid = 1 or [External Station] = 1"}
     Opts.Input.[Via Set] = {net_file + "|" + node_lyr, node_lyr}
     Opts.Field.Minimize = "Length"
     Opts.Field.Nodes = "Node.ID"
     Opts.Field.[Skim Fields].Length = "All"

     if (access_mode="drive") then do 
         if(transit_mode="premium") then Opts.Output.[Output Matrix].Label = "PNR2Dest_PrmSkim_OffPeak"
         if(transit_mode="premium") then Opts.Output.[Output Matrix].[File Name] = Dir + "\\skims\\skim_pnr2dest_offpeak_prm.mtx"
         if(transit_mode="premium2") then Opts.Output.[Output Matrix].Label = "PNR2Dest_Prm2Skim_OffPeak"
         if(transit_mode="premium2") then Opts.Output.[Output Matrix].[File Name] = Dir + "\\skims\\skim_pnr2dest_offpeak_prm2.mtx"
         if(transit_mode="bus") then Opts.Output.[Output Matrix].Label = "PNR2Dest_BusSkim_OffPeak"
         if(transit_mode="bus") then Opts.Output.[Output Matrix].[File Name] = Dir + "\\skims\\skim_pnr2dest_offpeak_bus.mtx"
     end

     if (access_mode="dropoff") then do 
         Opts.Output.[Output Matrix].Label = "KNR2Dest_Skim_OffPeak"
         Opts.Output.[Output Matrix].[File Name] = Dir + "\\skims\\skim_knr2dest_offpeak.mtx"
     end

     ret_value = RunMacro("TCB Run Procedure", 7, "TCSPMAT", Opts)
     if !ret_value then goto badtcspmat
////////////////////////////////////
end
else if (time_period = "AM" or time_period = "PM") then do
// STEP 3b: TCSPMAT PEAK SPEED
     Opts = null
     Opts.Input.Network = Dir + "\\pnr_net.net"
     Opts.Input.[Origin Set] = {net_file + "|" + node_lyr, node_lyr, "centroid", "Select * where Centroid = 1 or [External Station] = 1"}
     if (access_mode="drive") then do
         if(transit_mode="premium") then Opts.Input.[Destination Set] = {net_file + "|" + node_lyr, "Nodes+Stations","Park & Ride", "Select * where PNR = 1 or PNR = 2"}
         if(transit_mode="premium2") then Opts.Input.[Destination Set] = {net_file + "|" + node_lyr, "Nodes+Stations","Park & Ride", "Select * where PNR = 2"}
         if(transit_mode="bus") then Opts.Input.[Destination Set] = {net_file + "|" + node_lyr, "Nodes+Stations","Park & Ride", "Select * where PNR = 1"}
     end
     if (access_mode="dropoff") then Opts.Input.[Destination Set] = {net_file + "|" + node_lyr, "Nodes+Stations","Kiss & Ride", "Select * where KNR = 1 or KNR = 2 or KNR = 3"}
     Opts.Input.[Via Set] = {net_file + "|" + node_lyr, node_lyr}
     Opts.Field.Minimize = "TTPkAssn*"
     Opts.Field.Nodes = "Node.ID"
     Opts.Field.[Skim Fields].Length = "All"
     Opts.Field.[Skim Fields].[TTPkAssn*] = "All"
     Opts.Field.[Skim Fields].[TTFree*] = "All"
     
     if (access_mode="drive") then do 
        if(transit_mode="premium") then Opts.Output.[Output Matrix].Label = "OP_PrmSkim_Peak"
        if(transit_mode="premium") then Opts.Output.[Output Matrix].[File Name] = Dir + "\\skims\\skim_pnr_peak_prm.mtx"
        if(transit_mode="premium2") then Opts.Output.[Output Matrix].Label = "OP_Prm2Skim_Peak"
        if(transit_mode="premium2") then Opts.Output.[Output Matrix].[File Name] = Dir + "\\skims\\skim_pnr_peak_prm2.mtx"
        if(transit_mode="bus") then Opts.Output.[Output Matrix].Label = "OP_BusSkim_Peak"
        if(transit_mode="bus") then Opts.Output.[Output Matrix].[File Name] = Dir + "\\skims\\skim_pnr_peak_bus.mtx"
     end

     if (access_mode="dropoff") then do 
        Opts.Output.[Output Matrix].Label = "KNR_Skim_Peak"
        Opts.Output.[Output Matrix].[File Name] = Dir + "\\skims\\skim_knr_peak.mtx"
     end

     ret_value = RunMacro("TCB Run Procedure", 8, "TCSPMAT", Opts)
     if !ret_value then goto badtcspmat
/////////////////////////////////////////////
// Compute PNR Station  to Destination Distance. This is used to nullify paths which park very close to PNR / Drop-Off location
     Opts = null
     Opts.Input.Network = Dir + "\\pnr_net.net"
     if (access_mode="drive") then do
         if(transit_mode="premium") then Opts.Input.[Origin Set] = {net_file + "|" + node_lyr, "Nodes+Stations","Park & Ride", "Select * where PNR = 1 or PNR = 2"}
         if(transit_mode="premium2") then Opts.Input.[Origin Set] = {net_file + "|" + node_lyr, "Nodes+Stations","Park & Ride", "Select * where PNR = 2"}
         if(transit_mode="bus") then Opts.Input.[Origin Set] = {net_file + "|" + node_lyr, "Nodes+Stations","Park & Ride", "Select * where PNR = 1"}
     end
     if (access_mode="dropoff") then Opts.Input.[Origin Set] = {net_file + "|" + node_lyr, "Nodes+Stations","Kiss & Ride", "Select * where KNR = 1 or KNR = 2 or KNR = 3"}
     Opts.Input.[Destination Set] = {net_file + "|" + node_lyr, node_lyr, "centroid", "Select * where Centroid = 1 or [External Station] = 1"}
     Opts.Input.[Via Set] = {net_file + "|" + node_lyr, node_lyr}
     Opts.Field.Minimize = "Length"
     Opts.Field.Nodes = "Node.ID"
     Opts.Field.[Skim Fields].Length = "All"
     
     if (access_mode="drive") then do 
        if(transit_mode="premium") then Opts.Output.[Output Matrix].Label = "PNR2Dest_PrmSkim_Peak"
        if(transit_mode="premium") then Opts.Output.[Output Matrix].[File Name] = Dir + "\\skims\\skim_pnr2dest_peak_prm.mtx"
        if(transit_mode="premium2") then Opts.Output.[Output Matrix].Label = "PNR2Dest_Prm2Skim_Peak"
        if(transit_mode="premium2") then Opts.Output.[Output Matrix].[File Name] = Dir + "\\skims\\skim_pnr2dest_peak_prm2.mtx"
        if(transit_mode="bus") then Opts.Output.[Output Matrix].Label = "PNR2Dest_BusSkim_Peak"
        if(transit_mode="bus") then Opts.Output.[Output Matrix].[File Name] = Dir + "\\skims\\skim_pnr2dest_peak_bus.mtx"
     end

     if (access_mode="dropoff") then do 
        Opts.Output.[Output Matrix].Label = "KNR2Dest_Skim_Peak"
        Opts.Output.[Output Matrix].[File Name] = Dir + "\\skims\\skim_knr2dest_peak.mtx"
     end

     ret_value = RunMacro("TCB Run Procedure", 9, "TCSPMAT", Opts)
     if !ret_value then goto badtcspmat
////////////////////////////////////////////
end



if (access_mode="drive") then do
/*
 // Use highway skim matrix to find distance from all origins to CBD zone 10011
 // Restrict maximum drive access length to Max(Originto10011,7) miles
    hskm_mtx=OpenMatrix(Dir + "\\AutoSkims\\SPMAT_Free.mtx", "FALSE")
    hmtx_idx=GetMatrixIndex(hskm_mtx)
    hskm_cur=CreateMatrixCurrency(hskm_mtx, "HOV Length", hmtx_idx[1], hmtx_idx[2], )
    hwy_dist2CBD = GetMatrixVector(hskm_cur,  {{"Column", 10011}})
    max_dr_dist  = GetMatrixVector(hskm_cur,  {{"Column", 10011}})
    for i=1 to hwy_dist2CBD.length do
       max_dr_dist[i]=max(NullToZero(hwy_dist2CBD[i]),3.0)
    end
*/    
    if (time_period = "AM" or time_period = "PM") then do 
       if(transit_mode="premium") then dacc_time_mtx  = OpenMatrix(Dir + "\\skims\\skim_pnr_peak_prm.mtx", "FALSE")
       if(transit_mode="premium2") then dacc_time_mtx  = OpenMatrix(Dir + "\\skims\\skim_pnr_peak_prm2.mtx", "FALSE")
       if(transit_mode="bus") then dacc_time_mtx  = OpenMatrix(Dir + "\\skims\\skim_pnr_peak_bus.mtx", "FALSE")
       midx           = GetMatrixIndex(dacc_time_mtx)
       dacc_time_cur  = CreateMatrixCurrency(dacc_time_mtx, "TTPkAssn*", midx[1], midx[2], )
       dacc_dist_cur  = CreateMatrixCurrency(dacc_time_mtx, "Length (Skim)", midx[1], midx[2], )

       dacc_time_cur1 = CreateMatrixCurrency(dacc_time_mtx, "TTFree* (Skim)", midx[1], midx[2], )
       dacc_time_cur1 := NullToZero(dacc_time_cur1)

//       dacc_dist_mtx  = OpenMatrix(Dir + "\\skims\\skim_pnr2dest_peak.mtx", "FALSE")
//       mdidx          = GetMatrixIndex(dacc_dist_mtx)
//       dacc_dist_cur = CreateMatrixCurrency(dacc_dist_mtx, "Length (Skim)", mdidx[1], mdidx[2], )
    end 

    if (time_period = "MD" or time_period = "NT") then do 
        if(transit_mode="premium") then dacc_time_mtx = OpenMatrix(Dir + "\\skims\\skim_pnr_offpeak_prm.mtx", "FALSE")
        if(transit_mode="premium2") then dacc_time_mtx = OpenMatrix(Dir + "\\skims\\skim_pnr_offpeak_prm2.mtx", "FALSE")
        if(transit_mode="bus") then dacc_time_mtx = OpenMatrix(Dir + "\\skims\\skim_pnr_offpeak_bus.mtx", "FALSE")
        midx          = GetMatrixIndex(dacc_time_mtx)
        dacc_time_cur = CreateMatrixCurrency(dacc_time_mtx, "TTFree*", midx[1], midx[2], )
        dacc_dist_cur = CreateMatrixCurrency(dacc_time_mtx, "Length (Skim)", midx[1], midx[2], )
        
//        dacc_dist_mtx = OpenMatrix(Dir + "\\skims\\skim_pnr2dest_offpeak.mtx", "FALSE")
//        mdidx         = GetMatrixIndex(dacc_dist_mtx)
//        dacc_dist_cur = CreateMatrixCurrency(dacc_dist_mtx, "Length (Skim)", mdidx[1], mdidx[2], )
    end
    dacc_time_cur   := NullToZero(dacc_time_cur)
    dacc_dist_cur   := NullToZero(dacc_dist_cur)
    rowID           = GetMatrixRowLabels(dacc_time_cur)
    pnrID           = GetMatrixColumnLabels(dacc_time_cur)

// Add a table for storing PNR Parking Cost (Cents)
    on notfound do
		addmatrixcore(dacc_time_mtx,"PNR_Cost")
		goto pnrcost
    end
    SetMatrixCore(OM,"PNR_Cost")
pnrcost:
    PNR_cost_cur  = CreateMatrixCurrency(dacc_time_mtx, "PNR_Cost", midx[1], midx[2], )


// STEP 4:
    SetStatus(2, "Adding Shadow Price to Drive Access Time",)
       
//    EnableProgressBar("Progress", 2)
    CreateProgressBar("Adding Shadow Price to Drive Access Time...", "True")

    setview(nodes_view)
    park_set = "PNR_Nodes_Set"
    n_selected=SelectByQuery(park_set, "Several", "select * where PNR = 1 or PNR = 2", )
    
    prods_set = "Production_Zones_Set"
    n_selected=SelectByQuery(prods_set, "Several", "Select * where Centroid = 1 or [External Station] = 1", )

    zone_file=Dir+"\\TAZ_ATYPE.bin"
    
    zone_vw = OpenTable("TAZ_ATYPE", "FFB", {zone_file, })
    zone_count = GetRecordCount(zone_vw,)
    
    for i=1 to rowID.length do
       UpdateProgressBar("Adding Shadow Price to Drive Access Time...", RealToInt(i/zone_count * 100))
       drive_time   = GetMatrixVector(dacc_time_cur,  {{"Row", StringToInt(rowID[i])}})
       drive_dist   = GetMatrixVector(dacc_dist_cur,  {{"Row", StringToInt(rowID[i])}})

       if (time_period = "AM" or time_period = "PM") then drive_time1   = GetMatrixVector(dacc_time_cur1,  {{"Row", StringToInt(rowID[i])}})


// identify production area type to apply drive access time weights
       rh2 = LocateRecord(zone_vw+"|", zone_vw + ".ZONE", {rowID[i]}, {{"Exact", "True"}})
       ProdAType=zone_vw.[ATYPE]

///////
       if (i=1) then do

           // Get the projection of current map
           {proj_name, proj_params} = GetMapProjection()
           proj_scp = GetProjectionScope(proj_name, proj_params)


           // Change the map's projection to 1983 State Plane, North Carolina, US Survey Feet
           new_scp = GetProjectionScope("nad83:3200", {"units=us-ft"})
           SetMapScope(null, new_scp)
           SetMapProjection(null, "nad83:3200", {"units=us-ft"})
           RedrawMap()

           // store the xy cooridnates of all productions zones
           dim xcord[rowID.length]
           dim ycord[rowID.length]
           for j=1 to rowID.length do
               rhxy = LocateRecord(nodes_view+"|"+prods_set, node_lyr + ".ID", {rowID[j]}, {{"Exact", "True"}})
               xcord[j] = a2r(MapCoordToXY(, coord(nodes_view.Longitude, nodes_view.Latitude)), 1)
               ycord[j] = a2r(MapCoordToXY(, coord(nodes_view.Longitude, nodes_view.Latitude)), 2)
               
               if (StringToInt(rowID[j]) = 10001) then do
                  xcordcbd=xcord[j]
                  ycordcbd=ycord[j]
               end
           end


           dim shadowprice[drive_time.length]

           dim staxcord[drive_time.length]
           dim staycord[drive_time.length]
           dim sta_cat[drive_time.length]
           dim pnr_dist[drive_time.length]
           dim pnr_type[drive_time.length]
           dim pnr_cost[drive_time.length]
           
           for j=1 to drive_time.length do 
               shadowprice[j]=0.0
               temp=0
               
               rh1 = LocateRecord(nodes_view+"|"+park_set, node_lyr + ".ID", {pnrID[j]}, {{"Exact", "True"}})
               temp=nodes_view.Shadow_Price
               
               if (temp > 0) then shadowprice[j]=temp
               
               staxcord[j] = a2r(MapCoordToXY(, coord(nodes_view.Longitude, nodes_view.Latitude)), 1)
               staycord[j] = a2r(MapCoordToXY(, coord(nodes_view.Longitude, nodes_view.Latitude)), 2)
               
               sta_cat[j] = nz(nodes_view.PNR_CAT)
               pnr_dist[j] = nz(nodes_view.PNR_DIST)
               pnr_type[j] = nz(nodes_view.PNR)
               pnr_cost[j] = nz(nodes_view.PNRCOST)
           end
           
           // reset the projection of map to default projection
           SetMapScope(null, proj_scp)
           SetMapProjection(GetMap(), proj_name, proj_params)
           RedrawMap()

       end
               
       DriveTime    = Vector(drive_time.length, "Float",)
       PNRCost      = Vector(drive_time.length, "Float",)
       if (time_period = "AM" or time_period = "PM") then do       
           for j=1 to drive_time.length do
              fftime=0
              kk=0.65 // changed from 1 to 0.50 JainM 06.17.08; changed from 0.5 to 0.65, JainM, 08.13.08
              ff=1.5 // changed from 2 to 1.35 JainM 06.17.08; changed from 1.35 to 1.5, JainM, 08.13.08
              if (drive_time1[j] > 0.0) then fftime=drive_time1[j]
              if (drive_time[j] > 0.0 ) then do

// Identify productions zones that are south of end-of-line park-ride (i.e. zones oriented towards CBD but farther then park-ride lot).
// For these zones, the drive access time to end-of-line park ride time is treated as same as auto time.
                divpc = 1.25
                if (sta_cat[j] > 3) then divpc = 1.35  // increase to 1.35 from 1.25 (calib5)
                xback = 99
                
                // xback = 99 when the production zone is outside the intended catchment area.
                
                ret_backtr = runmacro("backtr",xcord[i],ycord[i],staxcord[j],staycord[j],xcordcbd,ycordcbd,divpc,pnr_dist[j])
                
                xback=ret_backtr[1]
                prod2cbd=ret_backtr[2]
                prod2pnr=ret_backtr[3]
/*                showmessage("xcord="+string(xcord[i]))
                showmessage("ycord="+string(ycord[i]))
                showmessage("staxcord="+string(staxcord[j]))
                showmessage("staycord="+string(staycord[j]))
                showmessage("xcordcbd="+string(xcordcbd))
                showmessage("ycordcbd="+string(ycordcbd))
                showmessage("divpc="+string(divpc))
                showmessage("pnr_dist="+string(pnr_dist[j]))
                showmessage("xback="+string(xback))*/

                if (xback=100) then do 
                /*
                if (fftime > 0) then do
                    DriveTime[j]=drive_time[j]*(min((((max(drive_time[j]/fftime,1.35)-kk)*ff)+1),3.0)) // Changed Min from 1.0 to 1.39 JainM 06.17.08, set maximum at 3; Changed Min from 1.39 to 1.35 JainM 08.13.08
                end
                
                if (ProdAType=1) then DriveTime[j]=2*DriveTime[j]
                if (ProdAType=2) then DriveTime[j]=1.25*DriveTime[j]

                if (xback = 100 and sta_cat[j]=5) then DriveTime[j]=1.5*drive_time[j]
                
                if (xback = 99) then DriveTime[j]=2*DriveTime[j]  // For production zones with significant backtracking, double the percieved drive access time.
                   

                DriveTime[j]=DriveTime[j]+shadowprice[j]
                */

                
                    if (ProdAType > 3) then DriveTime[j]=1.50*drive_time[j]
                    if (ProdAType = 3) then DriveTime[j]=1.50*drive_time[j]
                    if (ProdAType = 2) then DriveTime[j]=3.00*drive_time[j]
//                    if (ProdAType = 2) then DriveTime[j]=2.50*drive_time[j]
//                    if (ProdAType = 1) then DriveTime[j]=5.00*drive_time[j]
                    if (ProdAType = 1) then DriveTime[j]=3.50*drive_time[j]

                    DriveTime[j]=DriveTime[j]+shadowprice[j]

                end
                
                if (xback=99) then do
//                    DriveTime[j]=5.0*drive_time[j]
                    if (ProdAType > 3) then DriveTime[j]=5.0*drive_time[j]
                    if (ProdAType = 3) then DriveTime[j]=6.0*drive_time[j]
                    if (ProdAType = 2 and sta_cat[j]>3) then DriveTime[j]=7.0*drive_time[j]
                    if (ProdAType = 1 and sta_cat[j]>3) then DriveTime[j]=7.0*drive_time[j]

                    DriveTime[j]=DriveTime[j]+shadowprice[j]
                end

                // Add parking cost to drive access time. Use value of time of $ 12/ Hr to convert parking cost to equivalent minutes.
                pnr_cost_minutes=pnr_cost[j]*0.05
                DriveTime[j]=DriveTime[j]+pnr_cost_minutes
                PNRCost[j]=pnr_cost[j]
                 
                 // Add auto operating cost to drive access time. Auto operating cost is 10c/mile. Use value of time of 12$/hr.
                 // auto_op_cost_min=drive_dist[j]*0.1/0.2
                 // DriveTime[j]=DriveTime[j]+auto_op_cost_min
                 maxdrdist=max(prod2cbd,3.0)
                 if (prod2pnr > maxdrdist) then DriveTime[j]=null
                 if (prod2pnr > maxdrdist) then PNRCost[j]=null

              end
              
           end    
       end       
       if (time_period = "MD" or time_period = "NT") then do       
           for j=1 to drive_time.length do
              
              if (drive_time[j] > 0.0 ) then do
                
// Identify productions zones that are south of end-of-line park-ride (i.e. zones oriented towards CBD but farther then park-ride lot).
// For these zones, the drive access time to end-of-line park ride time is treated as same as auto time.
                divpc = 1.25
                if (sta_cat[j] > 3) then divpc = 1.35  // increase to 1.35 from 1.25 (calib5)
                xback = 99
                
                // xback = 99 when the production zone is outside the intended catchment area.
                
                ret_backtr = runmacro("backtr",xcord[i],ycord[i],staxcord[j],staycord[j],xcordcbd,ycordcbd,divpc,pnr_dist[j])
                xback=ret_backtr[1]
                prod2cbd=ret_backtr[2]
                prod2pnr=ret_backtr[3]

                if (xback=100) then do
                    if (ProdAType > 2) then DriveTime[j]=1.00*drive_time[j]
                    if (ProdAType = 2) then DriveTime[j]=1.75*drive_time[j]
                    if (ProdAType = 1) then DriveTime[j]=2.00*drive_time[j]
                end
                
                if (xback=99) then DriveTime[j]=3.0*drive_time[j]

                DriveTime[j]=DriveTime[j]+shadowprice[j]

                // Add parking cost to drive access time. Use value of time of $ 12/ Hr to convert parking cost to equivalent minutes. The parking cost is in cents. The drive weight is 2.58, so divide by weight.
                pnr_cost_minutes=pnr_cost[j]*0.05/2.58
                DriveTime[j]=DriveTime[j]+pnr_cost_minutes
                PNRCost[j]=pnr_cost[j]

/*
                DriveTime[j]=drive_time[j]
                if (ProdAType=1) then DriveTime[j]=2*drive_time[j]
                if (ProdAType=2) then DriveTime[j]=1.5*drive_time[j]
                
                   
                if (xback = 100 and sta_cat[j]=5) then DriveTime[j]=1.5*drive_time[j]
                
                if (xback = 99) then DriveTime[j]=2*DriveTime[j]  // For production zones with significant backtracking, double the percieved drive access time.

                DriveTime[j]=DriveTime[j]+shadowprice[j]
              
                // Add auto operating cost to drive access time. Auto operating cost is 10c/mile. Use value of time of 12$/hr.
                // auto_op_cost_min=drive_dist[j]*0.1/0.2
                // DriveTime[j]=DriveTime[j]+auto_op_cost_min
*/
                 maxdrdist=max(prod2cbd,3.0)
                 if (prod2pnr > maxdrdist) then DriveTime[j]=null
                 if (prod2pnr > maxdrdist) then PNRCost[j]=null

//              if (drive_dist[j] > max_dr_dist[i]) then DriveTime[j]=null

              end
              

           end    
       end       
       SetMatrixVector(dacc_time_cur, DriveTime, {{"Row", StringToInt(rowID[i])}} )
       SetMatrixVector(PNR_cost_cur, PNRCost, {{"Row", StringToInt(rowID[i])}} )
              
    end       
    closeview(zone_vw)
    DestroyProgressBar()
    
end

//&&&&&&&&&&&&&&&
// For drop-off access mode, create a second set of access time skim which excludes CBD drop-off location
if (access_mode="dropoff") then do

    if (time_period = "AM" or time_period = "PM") then do 
       dacc_time_file       = Dir + "\\skims\\skim_knr_peak.mtx"
       dacc_time_file_noCBD = Dir + "\\skims\\skim_knr_peak_noCBD.mtx"
       dacc_time_mtx        = OpenMatrix(dacc_time_file, "FALSE")

       midx = GetMatrixIndex(dacc_time_mtx)
       core = GetMatrixCoreNames(dacc_time_mtx)
       matrix_info=GetMatrixInfo(dacc_time_mtx)
       label=matrix_info[6][6]

       dacc_time_cur1 = CreateMatrixCurrency(dacc_time_mtx, "TTPkAssn* (Skim)", midx[1], midx[2], )

    end 

    if (time_period = "MD" or time_period = "NT") then do 
       dacc_time_file       = Dir + "\\skims\\skim_knr_offpeak.mtx"
       dacc_time_file_noCBD = Dir + "\\skims\\skim_knr_offpeak_noCBD.mtx"
       dacc_time_mtx        = OpenMatrix(dacc_time_file, "FALSE")

       midx = GetMatrixIndex(dacc_time_mtx)
       core = GetMatrixCoreNames(dacc_time_mtx)
       matrix_info=GetMatrixInfo(dacc_time_mtx)
       label=matrix_info[6][6]

       dacc_time_cur1 = CreateMatrixCurrency(dacc_time_mtx, "TTFree* (Skim)", midx[1], midx[2], )

    end

    SetStatus(2, "Nullify very long drop-off connectors",)
       
//    EnableProgressBar("Progress", 2)
    CreateProgressBar("Nullify very long drop-off connectors...", "True")

    // Determine the nearest drop-off location. Set maxiumum drop-off distance to 5 miles or nearest drop-off location
    dacc_time_cur = CreateMatrixCurrency(dacc_time_mtx, core[1], midx[1], midx[2], )
    dacc_dist_cur = CreateMatrixCurrency(dacc_time_mtx, "Length (Skim)", midx[1], midx[2], )

    dacc_dist_cur   := NullToZero(dacc_dist_cur)
    
    rowID           = GetMatrixRowLabels(dacc_time_cur)
    knrID           = GetMatrixColumnLabels(dacc_time_cur)
    max_drop_dist   = Vector(rowID.length, "Float",)
    
    for i=1 to rowID.length do
       UpdateProgressBar("Nullify very long drop-off connectors...", RealToInt(i/rowID.length * 100))

       dropoff_time   = GetMatrixVector(dacc_time_cur,  {{"Row", StringToInt(rowID[i])}})
       dropoff_dist   = GetMatrixVector(dacc_dist_cur,  {{"Row", StringToInt(rowID[i])}})
       max_drop_dist[i]  = max(ArrayMin(v2a(dropoff_dist)),5.0)
       
       for j=1 to knrID.length do
           if (dropoff_dist[j] > max_drop_dist[i]) then dropoff_time[j]=null
       end
       
       SetMatrixVector(dacc_time_cur, dropoff_time, {{"Row", StringToInt(rowID[i])}} )
    end

    DestroyProgressBar()

    SetStatus(2, "Create drop-off matrix without CBD drop-off location",)
       
//    EnableProgressBar("Progress", 2)
    CreateProgressBar("Create drop-off matrix without CBD drop-off location...", "True")

// Make a copy of drop-off access time skim matrix
    mc1 = CreateMatrixCurrency(dacc_time_mtx, core[1], midx[1], midx[2], )

    new_mat=CopyMatrix(mc1, {{"File Name", dacc_time_file_noCBD},
      {"Label", label[2]},
      {"File Based", "Yes"},
      {"Compression", 0}})
    mc1=null

// Identify CBD Drop-Off locations (KNR=2)
    setview(nodes_view)
    dropoff_set = "CBD_DropOff_Set"
    n_selected=SelectByQuery(dropoff_set, "Several", "select * where KNR = 2", )

    if (n_selected >0) then do
        dim cbd_dropoff_node[n_selected]
        i=0
	nodes_rec = GetFirstRecord (dropoff_set, null)
        
	while nodes_rec <> null do
	    i=i+1
            cbd_dropoff_node[i]=s2i(nodes_rec)
            nodes_rec = GetNextRecord (dropoff_set, null, null)
        end
    
        dacc_time_noCBD  = OpenMatrix(dacc_time_file_noCBD, "FALSE")
        midx_noCBD = GetMatrixIndex(dacc_time_noCBD)
        core_noCBD = GetMatrixCoreNames(dacc_time_noCBD)
        // Nullify CBD drop-off skims
        for i=1 to cbd_dropoff_node.length do
           
           UpdateProgressBar("Create drop-off matrix without CBD drop-off location...", RealToInt(i/cbd_dropoff_node.length * 100))
           
           for j=1 to core_noCBD.length do
               dacc_time_noCBD_cur = CreateMatrixCurrency(dacc_time_noCBD, core_noCBD[j], midx_noCBD[1], midx_noCBD[2], )
               rowID         = GetMatrixRowLabels(dacc_time_noCBD_cur)
               v = Vector(rowID.length, "float", {{"Constant", null},{"Column Based", "True"}})
               SetMatrixVector(dacc_time_noCBD_cur, v, {{"Column", cbd_dropoff_node[i]}} )
           end
// There is no restriction on drive length for CBD drop-off's so re-populate column with original skims
//           dacc_time_cur = CreateMatrixCurrency(dacc_time_mtx, core[1], midx[1], midx[2], )
//           rowID         = GetMatrixRowLabels(dacc_time_cur)
//           v = GetMatrixVector(dacc_time_cur1,  {{"Column", cbd_dropoff_node[i]}})
//           SetMatrixVector(dacc_time_cur, v, {{"Column", cbd_dropoff_node[i]}} )
//
        end
    end

    DestroyProgressBar()
    

end
//&&&&&&&&&&&&&&&

/*
if (access_mode="dropoff") then do

    if (time_period = "peak") then do 
       dacc_time_mtx  = OpenMatrix(Dir + "\\skims\\skim_knr_peak.mtx", "FALSE")
       midx           = GetMatrixIndex(dacc_time_mtx)
       dacc_time_cur  = CreateMatrixCurrency(dacc_time_mtx, "TTPkAssn*", midx[1], midx[2], )

       dacc_dist_mtx  = OpenMatrix(Dir + "\\skims\\skim_knr2dest_peak.mtx", "FALSE")
       mdidx          = GetMatrixIndex(dacc_dist_mtx)
       dacc_dist_cur = CreateMatrixCurrency(dacc_dist_mtx, "Length (Skim)", mdidx[1], mdidx[2], )
    end 

    if (time_period = "offpeak") then do 
        dacc_time_mtx = OpenMatrix(Dir + "\\skims\\skim_knr_offpeak.mtx", "FALSE")
        midx          = GetMatrixIndex(dacc_time_mtx)
        dacc_time_cur = CreateMatrixCurrency(dacc_time_mtx, "TTFree*", midx[1], midx[2], )

        dacc_dist_mtx = OpenMatrix(Dir + "\\skims\\skim_knr2dest_offpeak.mtx", "FALSE")
        mdidx         = GetMatrixIndex(dacc_dist_mtx)
        dacc_dist_cur = CreateMatrixCurrency(dacc_dist_mtx, "Length (Skim)", mdidx[1], mdidx[2], )
    end
    
    dacc_time_cur   := NullToZero(dacc_time_cur)
    dacc_dist_cur   := NullToZero(dacc_dist_cur)
    rowID           = GetMatrixRowLabels(dacc_time_cur)
    pnrID           = GetMatrixColumnLabels(dacc_time_cur)

// STEP 4:
    SetStatus(2, "Nullify drop-off times if very close to destination",)
       
    EnableProgressBar("Progress", 2)
    CreateProgressBar("Nullify drop-off times if very close to destination...", "True")

    for i=1 to rowID.length do
       UpdateProgressBar("Nullify drop-off times if very close to destination...", RealToInt(i/rowID.length * 100))
       drive_time   = GetMatrixVector(dacc_time_cur,  {{"Row", StringToInt(rowID[i])}})
       drive_dist   = GetMatrixVector(dacc_dist_cur,  {{"Column", StringToInt(rowID[i])}})
///////

       DriveTime    = Vector(drive_time.length, "Float",)
              
       for j=1 to drive_time.length do
              
              if (drive_dist[j] <= 3.0 ) then do
                DriveTime[j]=null
              end

              if (drive_dist[j] > 3.0 ) then do
                DriveTime[j]=drive_time[j]
              end
       end    
              
       SetMatrixVector(dacc_time_cur, DriveTime, {{"Row", StringToInt(rowID[i])}} )
              
    end       
    DestroyProgressBar()
    
end

*/
goto quit

badaddfield:
    Throw("Compute_OP_Matrix - Error adding field to node layer")
	// Throw("Compute_OP_Matrix - Error adding field to node layer")
	// AppendToLogFile(2, "Compute_OP_Matrix - Error adding field to node layer")
	// goto badquit

badfill:
    Throw("Compute_OP_Matrix - Error filling matrix")
	// Throw("Compute_OP_Matrix - Error filling matrix")
	// AppendToLogFile(2, "Compute_OP_Matrix - Error filling matrix")
	// goto badquit

badhwynet:
    Throw("Compute_OP_Matrix - Error building highway network")
	// Throw("Compute_OP_Matrix - Error building highway network")
	// AppendToLogFile(2, "Compute_OP_Matrix - Error building highway network")
	// goto badquit

badhwysettings:
    Throw("Compute_OP_Matrix - Error in highway network settings")
	// Throw("Compute_OP_Matrix - Error in highway network settings")
	// AppendToLogFile(2, "Compute_OP_Matrix - Error in highway network settings")
	// goto badquit

badtcspmat:
    Throw("Compute_OP_Matrix - Error creating highway skim (TCSPMAT)")
	// Throw("Compute_OP_Matrix - Error creating highway skim (TCSPMAT)")
	// AppendToLogFile(2, "Compute_OP_Matrix - Error creating highway skim (TCSPMAT)")
	// goto badquit

badquit:
	ComputeOPMatrixOK = 0
	goto quit

quit:
//	DestroyProgressBar()

	datentime = GetDateandTime()
	AppendToLogFile(2, "Exit Compute OP Matrix: " + datentime)


	return({ComputeOPMatrixOK, msg})
endMacro


Macro "backtr" (ii,jj,stai,staj,cbdi,cbdj,divpc,pnrdist)

      xback=100
      bx=1
      by=1
      xb=0.0
      yb=0.0

      dim ret_backtr[3] // ret_backtr[1]=xback, ret_backtr[2]=xcbd, ret_backtr[3]=xacc     
      
      if(stai > ii and stai <= cbdi) then bx=0
      if(stai > cbdi and stai <= ii) then bx=0
      if(staj > jj and staj <= cbdj) then by=0
      if(staj > cbdj and staj <= jj) then by=0
      
      xi=abs(ii-cbdi)
      xj=abs(jj-cbdj)
      dcbd=sqrt(xi*xi+xj*xj)+0.5
      xcbd=dcbd/5280
      
      if(bx = 1) then do
        if(cbdi >= ii and cbdi <= stai) then bx=2
        if(ii >= stai and ii <= cbdi)   then bx=3
        if(cbdi >= stai and cbdi <= ii) then bx=2
        if(ii >= cbdi and ii <= stai)   then bx=3
      end
      
      if(bx = 2) then xb = abs(cbdi-stai)/5280
      
      if(bx = 3) then xb = abs(ii-stai)/5280
      
      if(by = 1) then do
        if(cbdj >= jj and cbdj <= staj) then by=2
        if(jj >= staj and jj <= cbdj)   then by=3
        if(cbdj >= staj and cbdj <= jj) then by=2
        if(jj >= cbdj and jj <= staj)   then by=3
      end
      
      if(by = 2) then yb=abs(cbdj-staj)/5280
      
      if(by = 3) then yb=abs(jj-staj)/5280
      
      xt=xb+yb
      xpc=0.0
      
      if(xcbd > 0.0) then xpc=xt/xcbd
      
      xi=stai-cbdi
      xj=staj-cbdj
      xsta=sqrt(xi*xi+xj*xj)/5280
      xi=ii-stai
      xj=jj-staj
      xacc=sqrt(xi*xi+xj*xj)/5280
      xdiv=0.0
      
      if(xcbd > 0.0) then xdiv=(xacc+xsta)/xcbd
      
      if(xdiv > divpc) then xback=99
      
      if(xacc > pnrdist) then xback=99
      
      ret_backtr[1]=xback
      ret_backtr[2]=xcbd
      ret_backtr[3]=xacc
      
      
/*      
showmessage("xdiv="+string(xdiv))
showmessage("xacc="+string(xacc))
showmessage("pnrdist="+string(pnrdist))
showmessage("xback="+string(xback))*/
      return(ret_backtr)
      
EndMacro
