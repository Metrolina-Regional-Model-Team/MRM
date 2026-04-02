Macro "Market_Segment" (Args) 

	//Altered for new UI - McLelland, Jan 2016


	// LogFile = Args.[Log File].value
	// SetLogFileName(LogFile)

	Dir = Args.[Run Directory]
		
	msg = null
	mktsegOK = 1
	datentime = GetDateandTime()
	AppendToLogFile(2, "Enter Market_Segment: " + datentime)

	
//$$$$$$$$$$$$$$$$$$$
     SetStatus(2, "Market Segments Initialization",)

     OM = OpenMatrix(Dir + "\\tranassn\\Transit Assign DropOff.mtx",)
     core_list = GetMatrixCoreNames(OM)
     midx  = GetMatrixIndex(OM)

// Look for a core named "CBD Attractions"

     pos = ArrayPosition(core_list, {"CBD Attractions Flag"}, )

// If there isn�t one, add it
     if pos = 0 then AddMatrixCore(OM, "CBD Attractions Flag")

// Copy TAZ_AtYPE to new file so columns can be added without screwing up mode split .def file call to TAZ_ATYPE

	// on error goto notaz_atype
		CopyFile(Dir+"\\TAZ_ATYPE.bin", Dir + "\\TranAssn\\TAZ_ATYPE_TranAssn_Market_Segment.ASC")
		CopyFile(Dir+"\\TAZ_ATYPE.bin", Dir + "\\TranAssn\\TAZ_ATYPE_TranAssn_Market_Segment.DCT")
	on error default

	zone_file = Dir + "\\TranAssn\\TAZ_ATYPE_TranAssn_Market_Segment.ASC"
    
     zone_view = OpenTable("TAZ_ATYPE", "FFB", {zone_file, })
     setview(zone_view)

    MS_CBD_Currency    = CreateMatrixCurrency(OM, "CBD Attractions Flag",midx[1], midx[2],)
    MS_CBD_Currency    := 1

    RowthenColumn={"Yes","No"}
    ProdthenAtt={zone_view + ".District_P", zone_view + ".District_A"}

    // Added new fields to zone table
    NewFlds = {{"District_P", "integer"},
               {"District_A", "integer"}
              }
    if !RunMacro("TCB Run Macro", 1, "TCB Add View Fields", {zone_view, NewFlds}) then goto badaddfields

// Step 1: SET CBD Market Conditions
    // all CBD attractions
    SetStatus(2, "Set CBD Market Conditions",)
    SetView(zone_view)
    
    order1 =             {{"ZONE","Ascending"}}
    rec_id = GetFirstRecord(zone_view+"|",order1)
    i=0
    while rec_id <> null
    do
       i=i+1
       if zone_view.[CBD_FLAG]=2   then zone_view.District_A=1 else zone_view.District_A=0
       zone_view.District_P=1
       rec_id = GetNextRecord(zone_view+"|",rec_id,order1)
    end
    
    for i=1 to 2 do
        Opts = null
        Opts.Input.[Matrix Currency]         = {Dir + "\\tranassn\\Transit Assign DropOff.mtx", "CBD Attractions Flag", midx[1], midx[2]}
        Opts.Input.[Source Matrix Currency]  = {Dir + "\\tranassn\\Transit Assign DropOff.mtx", "CBD Attractions Flag", midx[1], midx[2]}
        Opts.Input.[Data Set]                = {zone_file, zone_view}
        Opts.Global.Method                   = 12
        Opts.Global.[Fill Option].[ID Field] = zone_view + ".[ZONE]"
        Opts.Global.[Fill Option].[Value Field] = ProdthenAtt[i]
        Opts.Global.[Fill Option].[Apply by Rows] = RowthenColumn[i]
        Opts.Global.[Fill Option].[Missing is Zero] = "Yes"
        if !RunMacro("TCB Run Operation", 2, "Fill Matrices", Opts)  then goto badfill
   end

	CloseView(zone_view)
	goto quit

	notaz_atype:
	Throw("Market_Segment - bad copy of TAZ_ATYPE.asc")
	AppendToLogFile(1, "Market_Segment - bad copy of TAZ_ATYPE.asc")
	goto badquit

	badaddfields:
	Throw("Market_Segment - cannot add field to \\TranAssn\\TAZ_ATYPE_Market_Segment.asc")
	AppendToLogFile(1, "Market_Segment - cannot add field to \\TranAssn\\TAZ_ATYPE_Market_Segment.asc")
	goto badquit

	badfill:
	Throw("Market_Segment - cannot fill matricies \\TranAssn\\Transit Assign DropOff.mtx")
	AppendToLogFile(1, "Market_Segment - cannot fill matricies \\TranAssn\\Transit Assign DropOff.mtx")
	goto badquit

	badquit:
	Throw("badquit: Last error message= " + GetLastError())
	AppendToLogFile(2, "badquit: Last error message= " + GetLastError())

	tmp = GetViews()
	vws = tmp[1]
	for i = 1 to vws.length do
	     CloseView(vws[i])
     end
	mktsegOK = 0
 	
	quit:
	
	datentime = GetDateandTime()
	AppendToLogFile(2, "Exit Market_Segment: " + datentime)

	return({mktsegOK, msg})

endMacro

