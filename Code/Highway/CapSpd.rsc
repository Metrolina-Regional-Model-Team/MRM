Macro "CapSpd" (Args)

	// GISDK CapSpd - replaces Fortran CapSpd
	// February 2, 2019 McLelland
	// GOT RID OF INTERSECTION_FACTYPE factor (turn lanes should handle)
	//	Signalized intersections - all cycle len are SAME by area type - lookup is by approach
	//		link, so it may differ by intersection.
	//	Capacity factor for signalized intersections = green percentage
	//	2/2/19	Added Funcl 85 for walk times OK to transit stations 
	// 			ATYPEFACTOR - Changed from reciprocal to straight factor (older versions based on speed, not TT)
	// 
	//	TuDu
	//		Reports - Guideway links 
	//		Guideway - get rid of HOV links transit time
	//		READ ME in guideway worksheet
	//	add these checks	
	//		State = hwyrec[15][2]
	//		County = hwyrec[16][2]
	//	Calculate all of the air quality ids	

	//	Input files
	//		dir/HwyName
	//		dir/landuse/taz_areatype.asc
	//		METDir/CapSpdFactors/Capspd_lookup.csv
	//		METDir/CapSpdFactors/Capspd_guideway.asc
		
	//	Macro has 5 major parts
	
	//	11111111111111111111111111111111111111111111111111111111111111111111111111111111111111
	//	    1.  Read lookup and guideway tables from Excel worksheets
	//	11111111111111111111111111111111111111111111111111111111111111111111111111111111111111

	//   22222222222222222222222222222222222222222222222222222222222222222222222222222222222222
	//		2.	Merge with Area Type by TAZ
	//   22222222222222222222222222222222222222222222222222222222222222222222222222222222222222
	
	//   33333333333333333333333333333333333333333333333333333333333333333333333333333333333333
	//		3.  First pass through network - error checks on entry - set defaults
	//   33333333333333333333333333333333333333333333333333333333333333333333333333333333333333

	//   44444444444444444444444444444444444444444444444444444444444444444444444444444444444444
	//		4.	Node arrays - error checks - fillg node (endpoint arrays) for cap / spd calc
	//   44444444444444444444444444444444444444444444444444444444444444444444444444444444444444

	//	 55555555555555555555555555555555555555555555555555555555555555555555555555555555555555
	//		5.	CapSpd - calculate speed and capacity based on link characteristics
	//	 55555555555555555555555555555555555555555555555555555555555555555555555555555555555555

	//****************************************************************************************
	//	Speed Limits
	//  	Includes resetting speed limits for future years based on area type!!!!
	//		Base Year = 2022   Adjusts speed limit after base year (UPDATED from 2005 to 2022 - TO DO: make a variable instead )
	//****************************************************************************************
	//	Got rid of PedActivity, Driveway Density. Development Density - Area Type covers it

	//	ORIGINAL CAPSPD MODULE WRITTEN BY RICHARD L. MERRICK              


//	Old program order
//		AreaType		look at taz at table - may want to add state and county to it
//		Guideway
//		NetPass1		done
//		checkN
//		zbr
//		capspd
	
	shared 	nwarns, LaneCap1hr, ATypeFac, TTPkEstFac, HwyDelay1ln, HwyDelay3ln, 
			TimeOfDayCapacityHours, Cap_FacType, Cap_Control, IntX_Control, 
			IntX_Prohibit, IntX_TurnLanes, IntX_CycleLength, IntX_GreenPct, ParkingFac,
			LocTranFreeSpeed, XprTranFreeSpeed, LocTranPeakSpeed, XprTranPeakSpeed

	nwarns = null
	dim LaneCap1hr[21,7]
	dim ATypeFac[21,8]
	dim TTPkEstFac[21,6]

	dim HwyDelay1ln[21,11]
	dim HwyDelay3ln[21,11]
	dim TimeOfDayCapacityHours[4,2]
	dim Cap_FacType[9,4]
	dim Cap_Control[7,2]
	dim IntX_Control[7,2]
	dim IntX_Prohibit[6,2]
	dim IntX_TurnLanes[3,3]
	dim IntX_CycleLength[21,6]
	dim IntX_GreenPct[21,22]
	dim ParkingFac[5,3]
	dim LocTranFreeSpeed[21,6]
	dim XprTranFreeSpeed[21,6]
	dim LocTranPeakSpeed[21,6]
	dim XprTranPeakSpeed[21,6]


	//	USES MRMFunctions - Highway file and matrix checks version 2 - 
	//		Each function returns an integer code - messages below respond to code 

	//	Returns Code
	//		 0 - no issue with field check
	//		 1 - file not found
	//		 2 - not a TC database
	//		 3 - layer not found
	//		 4 - field name not found
	//		 5 - field name added
	//		 6 - add field name error
	//		 7 - file not a TC matrix
	//	 	 8 - matrix missing core
	//		 9 - empty selection set
	//		10 - hwy file matrix mismatch 

		mrmfunctionmessages = 
			{" file not found",		
			 " not a TC database",
			 " layer not found",
			 " field name name found",
			 " field name added",
			 " add field name error",
			 " file is not a TC matrix",
			 " matrix core missing",
			 " selection set empty",
			 " hwy - matrix mismatch"
			} 

	
	Dir = Args.[Run Directory]
	METDir = Args.[MET Directory]
	//hwyname_ar = {Args.[AM Peak Hwy Name], Args.[PM Peak Hwy Name], Args.[Offpeak Hwy Name]}
	//hwyname_ar = {"RegNet_AMpeak", "RegNet_PMpeak", "RegNet_Offpeak"}
	//timeperiod_ar = {"AM Peak", "PM Peak", "Offpeak"}

	RunYear = Args.[Run Year]
	Hwy = SplitPath(Args.[Hwy Name])
	HwyName = Hwy[3]

	CapSpdLookUpFile = METDir + "\\Pgm\\Capspdfactors\\CapSpd_lookup.csv"
	GuidewayFile = METDir + "\\Pgm\\Capspdfactors\\capspd_guideway.asc"

	timeweight = Args.TimeWeight
	distweight = Args.DistWeight

	LogFile = Args.[Log File]
	ReportFile = Args.[Report File]
	SetLogFileName(LogFile)
	SetReportFileName(ReportFile)
	datentime = GetDateandTime()
	AppendToLogFile(1, "Enter CapSpd: " + datentime)

	msg = null
	lookupmsg = null
  	RunMacro("TCB Init")
	
//	CreateProgressBar("Capacity and Speed Calculations", "False")
//	stat = UpdateProgressBar("Capacity and Speed Calculations",1)

	msg = null
	CapSpdOK = 1

	legaldir = {-1, 0, 1}
	legalfun   = { 1, 2, 3, 4, 5, 6, 7, 8, 9,22,23,24,25,30,40,82,83,84,85,90,92}
	funclorder = { 1,22,23, 2, 3, 4,24,25, 5,82,83,30,40, 6, 9, 7, 8,84,85,90,92}
//  arraypos       1, 2, 3, 4, 5, 6, 7, 8, 9,10,11,12,13,14,15,16,17,18,19,20,21 

	legalat = {1,2,3,4,5}
	legalffn = {'IU','IR','FU','PU','PR','MU','MR','CU','CM','CR','LU','LR','TR','HO'}
	legalfac = {'F','E','R','D','M','B','T','C','U'}
	legalcntl = {'T','L','S','F','Y','R','X'}
	legalprk = {'Y','N','A','P','B'}
	legalprhb = {'N','L','R','T','C','X'}

	maxfuncl = 92

	// Error Table
	ErrFileRec = null

	CapSpdErrFile = Dir + "\\Report\\CapSpdErr.asc"
	exist = GetFileInfo(CapSpdErrFile)
	if exist then DeleteFile(CapSpdErrFile)
	CapSpdErr = CreateTable("CapSpdErr", CapSpdErrFile, "FFA",
			{{"ID", "Integer", 10, null, "Yes"},
			 {"ErrLayer", "String", 7, null, "No"},
			 {"ErrLevel", "String", 7, null, "No"},
			 {"ErrField", "String", 12, null, "No"},
			 {"ErrVal", "String", 12, null, "No"},
			 {"ErrMsg", "String", 120, null, "No"}}) 

	cnterrlvl1 = 0
	cnterrlvl2 = 0
	cnterrlvl3 = 0

//Loop through three networks
	// Check files
	// Highway network
	/*for tp = 1 to 3 do
		CreateProgressBar("Capacity and Speed Calculations "+timeperiod_ar[tp], "False")
		stat = UpdateProgressBar("Capacity and Speed Calculations "+timeperiod_ar[tp],1)
	*/
		//HwyName = hwyname_ar[tp]
	netview = HwyName
	altname = netview
	HwyFile = Dir + "\\" + HwyName + ".dbd"
	
	HwyFileChk = RunMacro("DBFieldCheck", HwyFile, HwyName, "OppFunclA", 0)

	if HwyFileChk > 0 then do
		cnterrlvl3 = cnterrlvl3 + 1
		// ErrFileRec: ID, layer, level field, val, message
		ErrFileRec = ErrFileRec + {{, "No File", "FATAL", "HwyFile", ,"Highway file " + mrmfunctionmessages[HwyFileChk]}}
	end
		
	// Area type by TAZ - to be joined to HwyView by TAZ no.  
	AreaTypeFile = Dir + "\\LandUse\\TAZ_AreaType.asc"
	exist = GetFileInfo(AreaTypeFile)
	if exist = null
		then do
			cnterrlvl3 = cnterrlvl3 + 1
			ErrFileRec = ErrFileRec + {{, "No File", "FATAL", "ATFile", ,AreaTypeFile + " NOT FOUND"}}
		end
	
	// CapSpd Factors file - lookup tables for capspd - See READ ME tab in spreadsheet
	exist = GetFileInfo(CapSpdLookUpFile)
	if exist = null
		then do
			cnterrlvl3 = cnterrlvl3 + 1
			ErrFileRec = ErrFileRec + {{, "No File", "FATAL", "Lookup", ,CapSpdLookUpFile + " NOT FOUND"}}
		end

	// CapSpd Guideway file - guideway travel time over-rides - See READ ME tab in spreadsheet
	exist = GetFileInfo(GuidewayFile)
	if exist = null
		then do
			cnterrlvl2 = cnterrlvl2 + 1
			GuidewayOverride = "False"
			ErrFileRec = ErrFileRec + {{, "No File", "Severe", "Guideway", ,HwyFile + " NOT FOUND, No Guideway overrides"}}
		end
		else GuidewayOverride = "True"
	
	// Write error/warning messages
	if ErrFileRec <> null 
		then do
			SetView(CapSpdErr)
			for i = 1 to ErrFileRec.length do
				errvals = 	{{"ID", ErrFileRec[i][1]}, {"ErrLayer", ErrFileRec[i][2]},
								{"ErrLevel", ErrFileRec[i][3]}, {"ErrField", ErrFileRec[i][4]}, 
								{"ErrVal", ErrFileRec[i][5]}, {"ErrMsg", ErrFileRec[i][6] }}
				AddRecord (CapSpdErr, errvals)
				//AppendToLogFile
			end // for i	
		end
	ErrFileRec = null

	if cnterrlvl3 > 0 then goto badquit	
	
		//	11111111111111111111111111111111111111111111111111111111111111111111111111111111111111
		//	    1.  Read lookup and guideway tables from Excel worksheets
		//	11111111111111111111111111111111111111111111111111111111111111111111111111111111111111
	
		stat = UpdateProgressBar("Read CapSpd lookup tables",5)
	
		// Read lookup table
		
		{LookupChk, lookupmsg} = RunMacro("CapSpd_ReadLookup", CapSpdLookUpFile)
		if LookupChk > 0 then do
			cnterrlvl3 = cnterrlvl3 + 1
			ErrFileRec = ErrFileRec + {{, "Bad Lookup", "FATAL", "LookupFile", ,CapSpdLookUpFile + " has issues"}}
			goto badquit		
		end
	
		//   22222222222222222222222222222222222222222222222222222222222222222222222222222222222222
		// 	2.	Merge with Area Type - from macro AreaType, linked using TAZ identified on link
		//   22222222222222222222222222222222222222222222222222222222222222222222222222222222222222
	
		// Open highway file
		layers = RunMacro("TCB Add DB Layers", HwyFile)
		NodeLayer = layers[1]
		HwyLayer = layers[2]
		SetLayer(NodeLayer)
		NodeView = GetView()
		SetLayer(HwyLayer)
		
		HwyView =GetView()
		SetView(HwyView)
		
		stat = UpdateProgressBar("Add area type - based on link TAZ",10)
	
		AT_TAZ = OpenTable("AT_TAZ",	"FFA", {AreaTypeFile},)
		Join_AT = JoinViews("Join_AT", HwyView+".TAZ", "AT_TAZ.TAZ",)
	
		SetView(Join_AT)
		vATypeIn = GetDataVector("Join_AT|", "AT_TAZ.ATYPE",)
		SetDataVector("Join_AT|", "areatp", vATypeIn, )
	
		// areatp : Check if any taz are illegal - SETS DEFAULT AREA TYPE TO 3
		TAZErrSelect = "Select * where AT_TAZ.TAZ = null"
		nsel = SelectByQuery("BadTAZ", "Several", TAZErrSelect)
		ptr = GetFirstRecord("Join_AT|BadTAZ",)
		while ptr <> null do
			hwyrec = GetRecordValues(Join_AT, ptr, {"ID", HwyView +".TAZ"})
			ID = hwyrec[1][2]
			BadTAZ = hwyrec[2][2]
			cnterrlvl3 = cnterrlvl3 + 1
			ErrFileRec = ErrFileRec + {{ID, "Link", "FATAL", "TAZ", i2s(BadTAZ), "Illegal TAZ, Default Area Type = 3"}}
			AT = 3
			SetRecordValues(Join_AT, ptr,{{HwyView + ".areatp", AT}})
			ptr = GetNextRecord("Join_AT|", null,)
		end //while ptr <> null
	
		// Area type
		//	legalat = {1,2,3,4,5}
		ATErrSelect = "Select * where areatp = null or areatp < 1 or areatp > 6"
		nsel = SelectByQuery("BadAT", "Several", ATErrSelect)
		ptr = GetFirstRecord("Join_AT|BadAT",)
		while ptr <> null do
			hwyrec = GetRecordValues(Join_AT, ptr, {"ID", "areatp"})
			ID = hwyrec[1][2]
			BadAT = hwyrec[2][2]
			cnterrlvl3 = cnterrlvl3 + 1
			ErrFileRec = ErrFileRec + {{ID, "Link", "FATAL", "areatp", i2s(BadAT), "Illegal Area Type, Default Area Type = 3"}}
			AT = 3
			SetRecordValues(Join_AT, ptr,{{HwyView + ".areatp", AT}})
			ptr = GetNextRecord("Join_AT|", null,)
		end //while ptr <> null
	
		CloseView(Join_AT)
		CloseView(AT_TAZ)
		vATypeIn = null
	
		//   33333333333333333333333333333333333333333333333333333333333333333333333333333333333333
		//		3.  First pass through network - error checks on entry - set defaults
		//   33333333333333333333333333333333333333333333333333333333333333333333333333333333333333
	
					
		// get maximum node number from HwyView.Nodes to set max node ID as index to node arrays
		SetView(NodeView)
		n = GetDataVector(NodeView + "|", "ID", {{"Sort Order", {{"ID", "Descending"}}}})
		maxnode = n[1]
		n = null
	
		dim	nlid[maxnode],			// array of link IDs of approach nodes 
			nlab[maxnode],			// array:  "A" or "B" node of link
			nfuncl[maxnode],  		// array of functional class of approach links 
			ncntl[maxnode], 		// array of control of approach links (by dir)
			noppfuncl[maxnode],		// array of opposing functional class for signalized intersections
			zbrin[maxnode], 		// number of approaches to node (non-centroid)
			zbrout[maxnode]			// number of exits from node (non-centroid)
	
		// initialize zbrin and zbrout to zero
		for i = 1 to maxnode do
			zbrin[i] = 0
			zbrout[i] = 0
		end
	
		// first pass through HwyView - check legal values for capacity / speed input.  
		// Warning or Error messages - use defaults if possible
		stat = UpdateProgressBar("First pass through network looking for illegal codes",15)
					
		SetView(HwyView)
		ptr = GetFirstRecord(HwyView+"|",)
		while ptr <> null do
			cntrec = cntrec + 1
			
			hwyrec = GetRecordValues(HwyView,ptr, {"ID", "Length", "DIR", "funcl", "fedfuncl", 
				"lanesAB", "lanesBA", "factype", "parking", "areatp",
				"A_Control", "A_Prohibit", "A_LeftLns", "A_ThruLns", "A_RightLns",
				"B_Control", "B_Prohibit", "B_LeftLns", "B_ThruLns", "B_RightLns",
				"State", "County", "TAZ", "SpdLimit"})
			ID = hwyrec[1][2]
			LinkLen = hwyrec[2][2]
			TrafficDir = hwyrec[3][2]
			funcl = hwyrec[4][2]
			fedfuncl = hwyrec[5][2]
			lanesAB = hwyrec[6][2]
			lanesBA = hwyrec[7][2]
			factype = hwyrec[8][2]
			parking = hwyrec[9][2]
			areatype = hwyrec[10][2]
			A_Control = hwyrec[11][2]
			A_Prohibit = hwyrec[12][2]
			A_LeftLns = hwyrec[13][2]
			A_ThruLns = hwyrec[14][2]
			A_RightLns = hwyrec[15][2]
			B_Control = hwyrec[16][2]
			B_Prohibit = hwyrec[17][2]
			B_LeftLns = hwyrec[18][2]
			B_ThruLns = hwyrec[19][2]
			B_RightLns = hwyrec[20][2]
			State = hwyrec[21][2]
			County = hwyrec[22][2]
			TAZ = hwyrec[23][2]
			SpdLimit = hwyrec[24][2]
			
	
			// Anode , Bnode : Endpoints
			node_ids = GetEndPoints(ID)
			A_node = node_ids[1]
			B_node = node_ids[2]
			SetRecordValues(HwyView, ptr,{{"Anode", A_node}})
			SetRecordValues(HwyView, ptr,{{"Bnode", B_node}})
	
			//Check single record values and ranges, 
			//  Errors are 1-Warning, 2-Severe, 3-Fatal
	
			// Zero length link
			chklinklen:
			if LinkLen > 0.001 then goto chktrafficdir
			cnterrlvl3 = cnterrlvl3 + 1
			ErrFileRec = ErrFileRec + {{ID, "Link", "FATAL", "Length", r2s(LinkLen), "Zero length link"}}
	
			// Link direction code,  legaldir = {-1, 0, 1}
			chktrafficdir:
			pos = ArrayPosition(legaldir, {TrafficDir},)	
			if pos = 0 then do
				cnterrlvl3 = cnterrlvl3 + 1
				ErrFileRec = ErrFileRec + {{ID, "Link", "FATAL", "Dir", i2s(TrafficDir), "Illegal direction code"}}
			end
	
			// funcl : Functional class  DEFAULT = 6
			//	legalfun = {1,2,3,4,5,6,7,8,9,22,23,24,25,30,40,82,83,84,85,90,92}
			chkfuncl:
			pos = ArrayPosition(legalfun, {funcl},)	
			if pos = 0 then do
				cnterrlvl2 = cnterrlvl2 + 1
				ErrFileRec = ErrFileRec + {{ID, "Link", "Severe", "funcl", i2s(funcl), "Illegal funcl, default=6"}}
				funcl = 6
				SetRecordValues(HwyView, ptr,{{"funcl", funcl}})
			end
	
			// fedfuncl : Federal functional class, DEFAULT = LU
			//	legalffn = {'IU','IR','FU','PU','PR','MU','MR','CU','CM','CR','LU','LR','TR','HO'}
			chkfedfuncl:
			pos = ArrayPosition(legalffn, {fedfuncl},)	
			if pos = 0 then do
				cnterrlvl2 = cnterrlvl2 + 1
				ErrFileRec = ErrFileRec + {{ID, "Link", "Severe", "fedfuncl", fedfuncl, "Illegal federal funcl, default=LU"}}
				fedfuncl = "LU"
				SetRecordValues(HwyView, ptr,{{"fedfuncl", fedfuncl}})
			end
	
			// factype : facility type,  DEFAULT = U
			//	legalfac = {'F','E','R','D','M','B','T','C','U'}
			chkfactype:
			pos = ArrayPosition(legalfac, {factype},)	
			if pos = 0 then do
				cnterrlvl1 = cnterrlvl1 + 1
				ErrFileRec = ErrFileRec + {{ID, "Link", "Warning", "factype", factype, "Illegal facility type, default=U"}}
				factype = "U"
				SetRecordValues(HwyView, ptr,{{"factype", factype}})
			end
	
			// lanesAB , lanesBA :  Lanes A to B and B to A
			// Severe - dir indicates lanes, none there.  Warning - dir indicates no lanes, have lanes
			chkABlanes:
			if ((TrafficDir = 1 or TrafficDir = 0) and lanesAB = 0) then do
				cnterrlvl3 = cnterrlvl3 + 1
				ErrFileRec = ErrFileRec + {{ID, "Link", "FATAL", "lanesAB", i2s(lanesAB), "Dir = " + i2s(TrafficDir) + " and lanesAB = " + i2s(lanesAB)}}
			end
			if ((TrafficDir = -1 or TrafficDir = 0) and lanesBA = 0) then do
				cnterrlvl3 = cnterrlvl3 + 1
				ErrFileRec = ErrFileRec + {{ID, "Link", "FATAL", "lanesBA", i2s(lanesBA), "Dir = " + i2s(TrafficDir) + " and lanesBA = " + i2s(lanesBA)}}
			end
			if (TrafficDir = -1 and lanesAB > 0) then do
				cnterrlvl1 = cnterrlvl1 + 1
				ErrFileRec = ErrFileRec + {{ID, "Link", "Warning", "lanesAB", i2s(lanesAB), "Dir = -1 and lanesAB = " + i2s(lanesAB) + ", set to 0"}}
				lanesAB = 0
				SetRecordValues(HwyView, ptr,{{"lanesAB", lanesAB}})
			end
			if (TrafficDir = 1 and lanesBA > 0) then do
				cnterrlvl1 = cnterrlvl1 + 1
				ErrFileRec = ErrFileRec + {{ID, "Link", "Warning", "lanesBA", i2s(lanesBA), "Dir = 1 and lanesBA = " + i2s(lanesBA) + ", set to 0"}}
				lanesBA = 0
				SetRecordValues(HwyView, ptr,{{"lanesBA", lanesBA}})
			end
			
			//Not quite sure where to put this but need to make sure we fill Lane field -AR
 			SetRecordValues(HwyView, ptr,{{"Lanes", nz(lanesAB)+nz(lanesBA)}})

			// parking : parking on link, DEFAULT = N
			//	legalprk = {'Y','N','A','P','B'}
			chkparking:
			pos = ArrayPosition(legalprk, {parking},)	
			if pos = 0 then do
				cnterrlvl1 = cnterrlvl1 + 1
				ErrFileRec = ErrFileRec + {{ID, "Link", "Warning", "parking", parking, "Illegal parking code, default=N"}}
				parking = "N"
				SetRecordValues(HwyView, ptr,{{"parking", parking}})
			end
	
			// B_Control : B node control, Doesn't matter if dir = -1 (B to A), DEFAULT = S
			//	legalcntl = ('T','L','S','F','Y','R','X'}
			chkbcontrol:
			pos = ArrayPosition(legalcntl, {B_Control},)	
			if TrafficDir = -1 
				then do
					if B_Control <> "X" 
						then do 
							cnterrlvl1 = cnterrlvl1 + 1
							ErrFileRec = ErrFileRec + {{ID, "Link", "Warning", "B_Control", B_Control, 
								"B_Control on B->A coded.  Changed to \"X\" (no movement)"}}
							B_Control = "X"
							SetRecordValues(HwyView, ptr,{{"B_Control", B_Control}})
						end // if bcontrol <> x
					goto chkacontrol
				end // if TrafficDir = -1
				
			//  illegal or x bcontrol
			if (pos = 0 or pos = 7) 
				then do
					cnterrlvl2 = cnterrlvl2 + 1
					ErrFileRec = ErrFileRec + {{ID, "Link", "Severe", "B_Control", B_Control, "Illegal B_Control code, default=S (stop)"}}
					B_Control = "S"
					SetRecordValues(HwyView, ptr,{{"B_Control", B_Control}})
				end
	
			//Freeway - Anything except T (thru) - Severe warning
			if funcl = 1 and (TrafficDir = 1 or TrafficDir = 0) and pos <> 1
				then do
					cnterrlvl2 = cnterrlvl2 + 1
					ErrFileRec = ErrFileRec + {{ID, "Link", "Severe", "B_Control", B_Control, "Illegal B_Control on Freeway"}}
				end
				
			// A_Control : A node control, don't bother if dir = 1 (A to B), DEFAULT = S
			//	legalcntl = ('T','L','S','F','Y','R','X'}
			chkacontrol:
			pos = ArrayPosition(legalcntl, {A_Control},)	
			if TrafficDir = 1 
				then do
					if A_Control <> "X" 
						then do 
							cnterrlvl1 = cnterrlvl1 + 1
							ErrFileRec = ErrFileRec + {{ID, "Link", "Warning", "A_Control", A_Control, 
								"A_Control on A->B coded.  Changed to \"X\" (no movement)"}}
							A_Control = "X"
							SetRecordValues(HwyView, ptr,{{"A_Control", A_Control}})
						end // if acontrol <> x
					goto chkbprohibit
				end // if TrafficDir = 1
	
			//  illegal or x acontrol
			if (pos = 0 or pos = 7) 
				then do
					cnterrlvl2 = cnterrlvl2 + 1
					ErrFileRec = ErrFileRec + {{ID, "Link", "Severe", "A_Control", A_Control, "Illegal A_Control code, default=S (stop)"}}
					A_Control = "S"
					SetRecordValues(HwyView, ptr,{{"A_Control", A_Control}})
				end
			
			//Freeway - Anything except T (thru) - Severe warning
			if funcl = 1 and (TrafficDir = -1 or TrafficDir = 0) and pos <> 1
				then do
					cnterrlvl2 = cnterrlvl2 + 1
					ErrFileRec = ErrFileRec + {{ID, "Link", "Severe", "A_Control", A_Control, "Illegal A_Control on Freeway"}}
				end
				
			// B_Prohibit : B node prohibitions, ,  DEFAULT = N
			//	legalprhb = {'N','L','R','T','C','X'}
			chkbprohibit:
			if TrafficDir = -1 then goto chkaprohibit
			pos = ArrayPosition(legalprhb, {B_Prohibit},)	
			if pos = 0 then do
				cnterrlvl1 = cnterrlvl1 + 1
				ErrFileRec = ErrFileRec + {{ID, "Link", "Warning", "B_Prohibit", B_Prohibit, "Illegal B_Prohibit code, default=N (none)"}}
				B_Prohibit = "N"
				SetRecordValues(HwyView, ptr,{{"B_Prohibit", B_Prohibit}})
			end
			
			// A_Prohibit :  A node prohibitions,  DEFAULT = N
			//	legalprhb = {'N','L','R','T','C','X'}
			chkaprohibit:
			pos = ArrayPosition(legalprhb, {A_Prohibit},)	
			if pos = 0 then do
				cnterrlvl1 = cnterrlvl1 + 1
				ErrFileRec = ErrFileRec + {{ID, "Link", "Warning", "A_Prohibit", A_Prohibit, "Illegal A_Prohibit code, default=N (none)"}}
				A_Prohibit = "N"
				SetRecordValues(HwyView, ptr,{{"A_Prohibit", A_Prohibit}})
			end
	
			// B node number of lanes at intersection, (A to B direction only) 
			//   lanes at intersection - fewer than incoming or > 4 more than incoming warning  
			chkbintlanes:
			if TrafficDir = -1 then goto chkaintlanes
			BIntlns = B_LeftLns + B_ThruLns + B_RightLns
			if BIntlns - lanesAB < 0 then do
				cnterrlvl1 = cnterrlvl1 + 1
				ErrFileRec = ErrFileRec + {{ID, "Link", "Warning", "B_Int Lns", i2s(lanesAB), 
						"Too few B intersection lns: lanesAB="+i2s(lanesAB)+ " Int L/T/R="+i2s(B_LeftLns)+","+i2s(B_ThruLns)+","+i2s(B_RightLns)}}
			end
			else if BIntlns - lanesAB > 4 then do
				cnterrlvl1 = cnterrlvl1 + 1
				ErrFileRec = ErrFileRec + {{ID, "Link", "Warning", "B_Int Lns", i2s(lanesAB), 
						"Too many B intersection lns: lanesAB="+i2s(lanesAB)+ " Int L/T/R="+i2s(B_LeftLns)+","+i2s(B_ThruLns)+","+i2s(B_RightLns)}}
			end
	
			// A node number of lanes at intersection, (B to A direction only) 
			//   lanes at intersection - fewer than incoming or > 4 more than incoming warning  
			chkaintlanes:
			if TrafficDir = 1 then goto chkspdlimit
			AIntlns = A_LeftLns + A_ThruLns + A_RightLns
			if AIntlns - lanesBA < 0 then do
				cnterrlvl1 = cnterrlvl1 + 1
				ErrFileRec = ErrFileRec + {{ID, "Link", "Warning", "A_Int Lns", i2s(lanesBA), 
						"Too few A intersection lns: lanesBA="+i2s(lanesBA)+ " Int L/T/R="+i2s(A_LeftLns)+","+i2s(A_ThruLns)+","+i2s(A_RightLns)}}
			end
			else if BIntlns - lanesBA > 4 then do
				cnterrlvl1 = cnterrlvl1 + 1
				ErrFileRec = ErrFileRec + {{ID, "Link", "Warning", "A_Int Lns", i2s(lanesBA), 
						"Too many A intersection lns: lanesBA="+i2s(lanesBA)+ " Int L/T/R="+i2s(A_LeftLns)+","+i2s(A_ThruLns)+","+i2s(A_RightLns)}}
			end
	
			//  speed limit, default, freeway, expressway = 55, surface streets = 35, transit walk = 10, cenconn = 25
			//****************************************************************************************
			//  Includes resetting speed limits for future years based on area type!!!!
			//****************************************************************************************
			chkspdlimit:
	
			// SpdLmtRun : default speed - issue warning, DEFAULT: FREEWAY=55, OTH=35
			changespeed = "false"
			changespdmsg = null
			if SpdLimit = null or SpdLimit < 10 or SpdLimit > 80 then do
				// freeways, expressways, frwy ramps, hov, hot lanes and access, default=55
				if funcl = 1 or funcl = 2 or funcl = 9 or funcl = 22 or funcl = 23 or funcl = 24 or funcl = 25 or 
							funcl = 82 or funcl = 83
					then do
						NewSpdLimit = "55"
						changespeed = "true"
						changespdmsg = "High speed facility, Speed limit changed to default = "+ NewSpdLimit
					end
					// everything else 
					else do
						NewSpdLimit = "35"
						changespeed = "true"
						changespdmsg = "Surface street, Speed limit changed to default = "+ NewSpdLimit
					end
				end // if SpdLimit = null..
	
			//  v 2.4 - Adjust base year speed limit for rural 55 MPH roads that are now suburban
			//          only for funcl 4,5,6,7
			LastCapYear = 2100 
			BaseYear = 2022			// Speeds will NOT be adjusted for year <= base year
	
			if s2i(RunYear) > BaseYear and (funcl = 4 or funcl = 5 or funcl = 6 or funcl = 7) and areatype < 5 and SpdLimit > 49
	     	   	then do
					NewSpdLimit = "45"
					changespeed = "true"
					changespdmsg = "No longer rural surface street, Speed limit reduced to "+ NewSpdLimit
				end
	  
			// Message
			if changespeed = "false"
				then SpdLimRun = SpdLimit
				else do
					cnterrlvl1 = cnterrlvl1 + 1
					ErrFileRec = ErrFileRec + {{ID, "Link", "Warning", "SpdLimit", i2s(SpdLimit), changespdmsg}}
					SpdLimRun = NewSpdLimit
				end
			SetRecordValues(HwyView, ptr,{{"SpdLimRun", SpdLimRun}})
	
			skipspdlimit:
	
	
			chknext:
			donerecchecks:
	
			//*************************************************************************************
			// Fill the node arrays - CENTROID CONNECTORS AND WALK APPROACH DO NOT COUNT
			//*************************************************************************************
			// nlid[maxnode],			// array of link IDs of approach nodes 
			// nlab[maxnode],			// array:  "A" or "B" node of link
			// nfuncl[maxnode],  		// array of functional class of approach links 
			// ncntl[maxnode], 			// array of control of approach links (by dir)
			// zbrin[maxnode], 			// number of approaches to node (non-centroid)
			// zbrout[maxnode]			// number of exits from node (non-centroid)
	
			// control array and zero balance test array
			//	 noppfuncl filled with zeros 
			// do not fill for centroid connecgtors (funcl = 90, 92)
	
			if funcl = 90 or funcl = 92 then goto skipnode1
	
			if TrafficDir = 0 or TrafficDir = 1 
				then do
					nlid[B_node]	= nlid[B_node] + {ID}
					nlab[B_node]	= nlab[B_node] + {"B"} 
					nfuncl[B_node]	= nfuncl[B_node] + {funcl}
					ncntl[B_node]	= ncntl[B_node] + {B_Control}
					noppfuncl[B_node] = noppfuncl[B_node] + {0}
					// zbr (zero balance error) approach at B, exit at A
					zbrin[B_node] = zbrin[B_node] + 1
					zbrout[A_node] = zbrout[A_node] + 1
				end
				
			// B->A direction - same thing for A node
			if TrafficDir = 0 or TrafficDir = -1
				then do
					nlid[A_node]	= nlid[A_node] + {ID}
					nlab[A_node]	= nlab[A_node] + {"A"} 
					nfuncl[A_node]	= nfuncl[A_node] + {funcl}
					ncntl[A_node]	= ncntl[A_node] + {A_Control}
					noppfuncl[A_node] = noppfuncl[A_node] + {0}
	
					zbrin[A_node] = zbrin[A_node] + 1
					zbrout[B_node] = zbrout[B_node] + 1
				end
			skipnode1:
	
			// all done - 
			ptr = GetNextRecord(HwyView + "|", null,)
		end //while ptr <> null
	
		// Write Error / warning messages
		if ErrFileRec <> null 
			then do
				SetView(CapSpdErr)
				for i = 1 to ErrFileRec.length do
					errvals = 	{{"ID", ErrFileRec[i][1]}, {"ErrLayer", ErrFileRec[i][2]},
								 {"ErrLevel", ErrFileRec[i][3]}, {"ErrField", ErrFileRec[i][4]}, 
								 {"ErrVal", ErrFileRec[i][5]}, {"ErrMsg", ErrFileRec[i][6] }}
					AddRecord (CapSpdErr, errvals)
		 		end // for i	
			end
		ErrFileRec = null
		if cnterrlvl3 > 0 then goto badquit	
	
		// End of first read 
		
		//	44444444444444444444444444444444444444444444444444444444444444444444444444444444444444
		//		4.	Node arrays - error checks - fill node (endpoint arrays) for cap / spd calc
		//			ZBR - zero balance errors - checks if nodes have ways in but not out or other way around
		//					zbrin (link traffic INTO node) and zbrout (link traffic OUT of node)
		//			Pairs of functional classes that should not be at same node (Warning only)
		//			Controls - Signal, 4-way stop, Roundabout - DOMINANT (in that order) - ALL APPROACHS SAME
		//			Opposing functional class - maximum opposing funcl used in signalized intersections
		//				rank based on array funclorder
		//	44444444444444444444444444444444444444444444444444444444444444444444444444444444444444
	
		stat = UpdateProgressBar("Checking nodes",25)
	
		for nodenum = 1 to zbrin.length do
		
			//Ins, no outs
			if zbrin[nodenum] > 0 and zbrout[nodenum] = 0
				then do
					cnterrlvl3 = cnterrlvl3 + 1
					ErrFileRec = ErrFileRec + {{nodenum, "Node", "FATAL", "Zero Balance", , "Traffic can flow INTO node, but not OUT!"}}
				end		 
	
			//Outs, no ins
			if zbrin[nodenum] = 0 and zbrout[nodenum] > 0
				then do
					cnterrlvl3 = cnterrlvl3 + 1
					ErrFileRec = ErrFileRec + {{nodenum, "Node", "FATAL", "Zero Balance", , "Traffic can flow OUT of node, but not IN!"}}
				end		 
		end // for zbrin.length
	
		//Go thru nfuncl (funcl by node) - see if pairs of funcls are there
		//	check against nwarn (created in section 1 of program)
		if nwarns.length = 0 then do
			cnterrlvl1 = cnterrlvl1 + 1
			ErrFileRec = ErrFileRec + {{0, "Node", "Warning", , , "No node funcl in control file"}}
			goto skipnodewarns
		end // num_nwarns = 0 
		for nodenum = 1 to nfuncl.length do
		
			//no check if only one funcl (not counting centroid connectors, walk links)
			if nfuncl[nodenum] = null then goto skipnode2
		
			for j = 1 to nwarns.length do
				bad1 = nwarns[j][1]
				bad2 = nwarns[j][2]
				baddesc = nwarns[j][3]
				hit1 = 0
				hit2 = 0
				for k = 1 to nfuncl[nodenum].length do
					if nfuncl[nodenum][k] = bad1 then hit1 = 1
					if nfuncl[nodenum][k] = bad2 then hit2 = 1
				end 		
				if hit1 = 1 and hit2 = 1 
					then do
						cnterrlvl1 = cnterrlvl1 + 1
						ErrFileRec = ErrFileRec + {{nodenum, "Node", "Warning", "Funcl Pair", ,
							"Node funcl warning: " + i2s(bad1) + ", " + i2s(bad2) + ": " + baddesc}}
					end // hit1 & hit2
			end // for j
				
			skipnode2:
		end // for i
		skipnodewarns:
		// check ncntl file for bad combinations of controls
		// Controls checked in this order
		//		L	Signal		All approaches are set to signal
		//		F	4-way		All approaches are set to 4-way
		//		R	Roundabout	All approaches are set to roundabout
		//		S	Stop	
		//		Y	Yield
		//		T	Through	
		//
	
		for nodenum = 1 to ncntl.length do
		
			//no check if < 1 controls
			if ncntl[nodenum] = null then goto skipnode3
	
			gotthru = 0
			gotsignal = 0
			gotstop = 0
			got4way = 0
			gotyield = 0
			gotroundabout = 0	
	
			for k = 1 to ncntl[nodenum].length do
				cntl = ncntl[nodenum][k]
				if cntl = "T" then gotthru = 1
				if cntl = "L" then gotsignal = 1
				if cntl = "S" then gotstop = 1
				if cntl = "F" then got4way = 1
				if cntl = "Y" then gotyield = 1
				if cntl = "R" then gotroundabout = 1
			end // for k
			
			// Signal - all should be signals, repair input link
			if gotsignal = 1 
				then do
					for k = 1 to ncntl[nodenum].length do
						if ncntl[nodenum][k] <> "L" then do
							badcontrol = ncntl[nodenum][k]
							badlinkid = nlid[nodenum][k]
							if nlab[nodenum][k] = "A" 
								then badapproach = "A_Control"
								else badapproach = "B_Control"
									 
							cnterrlvl1 = cnterrlvl1 + 1
							ErrFileRec = ErrFileRec + {{badlinkid, "Link", "Warning", badapproach, badcontrol ,
								"Signalized intersection at node "+ i2s(nodenum) + ", control changed to L"}}
							//Repair
							SetView(HwyView)
							linkptr = LocateRecord(HwyView + "|", "ID", {badlinkid},)						
							SetRecordValues(HwyView, linkptr, {{badapproach, "L"}})
						end  //if cntl <> "L"
					end // for k =
					goto skipnode3
				end //gotsignal = 1
								  
			// 4 way stop - all should be 4 way stops
			if got4way = 1 
				then do
					for k = 1 to ncntl[nodenum].length do
						if ncntl[nodenum][k] <> "F" then do
							badcontrol = ncntl[nodenum][k]
							badlinkid = nlid[nodenum][k]
							if nlab[nodenum][k] = "A" 
								then badapproach = "A_Control"
								else badapproach = "B_Control"
									 
							cnterrlvl1 = cnterrlvl1 + 1
							ErrFileRec = ErrFileRec + {{badlinkid, "Link", "Warning", badapproach, badcontrol ,
								"Four way stop at node "+ i2s(nodenum) + ", control changed to F"}}
							//Repair
							SetView(HwyView)
							linkptr = LocateRecord(HwyView + "|", "ID", {badlinkid},)						
							SetRecordValues(HwyView, linkptr, {{badapproach, "F"}})
						end  //if cntl <> "F"
					end // for k =
					goto skipnode3
				end //got4way = 1
	
			// RoundAbout - all should be roundabouts
			if gotroundabout = 1 
				then do
					for k = 1 to ncntl[nodenum].length do
						if ncntl[nodenum][k] <> "R" then do
							badcontrol = ncntl[nodenum][k]
							badlinkid = nlid[nodenum][k]
							if nlab[nodenum][k] = "A" 
								then badapproach = "A_Control"
								else badapproach = "B_Control"
									 
							cnterrlvl1 = cnterrlvl1 + 1
							ErrFileRec = ErrFileRec + {{badlinkid, "Link", "Warning", badapproach, badcontrol ,
								"Roundabout at node "+ i2s(nodenum) + ", control changed to R"}}
	
							//Repair
							SetView(HwyView)
							linkptr = LocateRecord(HwyView + "|", "ID", {badlinkid},)						
							SetRecordValues(HwyView, linkptr, {{badapproach, "R"}})
						end  //if cntl <> "L"
					end // for k =
					goto skipnode3
				end //gotroundabout = 1
	
			// Stop sign - should have a thru - warning only
			if gotstop = 1 
				then do
					if gotthru = 0 
						then do
							idstring = null
							for k = 1 to nlid[nodenum].length do
								idstring = idstring + i2s(nlid[nodenum][k]) + ", "
							end
							cnterrlvl1 = cnterrlvl1 + 1
							ErrFileRec = ErrFileRec + {{nodenum, "Node", "Warning", "Controls", ,
								"Node has stop sign but no thru, IDs: " + idstring}}
							goto skipnode3
						end
				end
	
			// Yield - should have a thru - warning only
			if gotyield = 1 
				then do
					if gotthru = 0 
						then do
							idstring = null
							for k = 1 to nlid[nodenum].length do
								idstring = idstring + i2s(nlid[nodenum][k]) + ", "
							end
							cnterrlvl1 = cnterrlvl1 + 1
							ErrFileRec = ErrFileRec + {{nodenum, "Node", "Warning", "Controls", ,
								"Node has yield, but no thru, IDs: " + idstring}}
	
							goto skipnode3
						end
				end
			skipnode3:
		end // for i
	
		// Write Error / warning messages
		if ErrFileRec <> null 
			then do
				SetView(CapSpdErr)
				for i = 1 to ErrFileRec.length do
					errvals = 	{{"ID", ErrFileRec[i][1]}, {"ErrLayer", ErrFileRec[i][2]},
								 {"ErrLevel", ErrFileRec[i][3]}, {"ErrField", ErrFileRec[i][4]}, 
								 {"ErrVal", ErrFileRec[i][5]}, {"ErrMsg", ErrFileRec[i][6] }}
					AddRecord (CapSpdErr, errvals)
		 		end // for i	
			end
		ErrFileRec = null
		if cnterrlvl3 > 0 then goto badquit	
	
		// Opposing functional class - choose maximum of opposing facilities (other than funcl of same)
		//		if > 2 approaches have maximum - that is max2 as well as max1	
		// legalfun   = { 1, 2, 3, 4, 5, 6, 7, 8, 9,22,23,24,25,30,40,82,83,84,85,90,92}
		// funclorder = { 1,22,23, 2, 3, 4,24,25, 5,82,83,30,40, 6, 9, 7, 8,84,85,90,92}
		//  arraypos      1, 2, 3, 4, 5, 6, 7, 8, 9,10,11,12,13,14,15,16,17,18,19,20,21 
		// e.g. funcl 2,2,3,3   rank 4,4,5,5,   oppfuncl = 3,3,2,2
	
		stat = UpdateProgressBar("Opposing functional class", 30)
	
		for nodenum = 1 to nfuncl.length do
	
			//skip if no funcls
			if nfuncl[nodenum] = null then goto skipnode4
	
			max1 = 22
			max2 = 22
	
			// get max1
			for k = 1 to nfuncl[nodenum].length do
				rank = ArrayPosition(funclorder, {nfuncl[nodenum][k]},)
				if rank < max1 then max1 = rank 
			end
			countmax = 0
			// get max2
			for k = 1 to nfuncl[nodenum].length do
				rank = ArrayPosition(funclorder, {nfuncl[nodenum][k]},)
				if rank < max2 and rank > max1 then max2 = rank 
				if rank = max1 then countmax = countmax + 1
			end
			if max2 = 22 or countmax > 2 then max2 = max1
	
			// assign opposing funcls
			for k = 1 to nfuncl[nodenum].length do
				rank = ArrayPosition(funclorder, {nfuncl[nodenum][k]},)
				max1funcl = funclorder[max1]
				max2funcl = funclorder[max2]
				if rank = max1 
					then noppfuncl[nodenum][k] = max2funcl
					else noppfuncl[nodenum][k] = max1funcl
			end
	
			skipnode4:
		end  // for nfuncl
		
		// Put opposing funcl on links for intersection links (no centroid connectors or walk links, direction matters
		//	 found if id is in nlid array 
		SetView(HwyView)
		ptr = GetFirstRecord(HwyView + "|",)	
		while ptr <> null do
			rec = GetRecordValues(HwyView, ptr, {"ID", "Anode", "Bnode"})
			ID = rec[1][2]
			Anode = rec[2][2]
			Bnode = rec[3][2]
			posA = ArrayPosition(nlid[Anode], {ID},)
			if posA > 0 
				then oppfunclA = noppfuncl[Anode][posA]
				else oppfunclA = 0
			posB = ArrayPosition(nlid[Bnode], {ID},)
			if posB > 0 
				then oppfunclB = noppfuncl[Bnode][posB]
				else oppfunclB = 0
			SetRecordValues(HwyView, ptr, {{"OppFunclA", oppfunclA}, {"OppFunclB", oppfunclB}})
			ptr = GetNextRecord(HwyView + "|", null,)
		end  // while ptr
	
	
		//*********************************************************************************************
		//  Temporary node array files for trace
		//************************************************************************************************
	
		SaveArray(nfuncl, Dir + "\\Report\\nfunclarray.temp")
		SaveArray(ncntl, Dir + "\\Report\\ncntlarray.temp")
		SaveArray(nlid, Dir + "\\Report\\nlinkidarray.temp")
		SaveArray(nlab, Dir + "\\Report\\nlinkendarray.temp")
		SaveArray(noppfuncl, Dir + "\\Report\\noppfunclarray.temp")
		SaveArray(zbrin, Dir + "\\Report\\zbrinarray.temp")
		SaveArray(zbrout, Dir + "\\Report\\zbroutarray.temp")
		
		// skip first pass - load arrays from earlier run
		skip_pass1_nodes:
	
		//	5555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
		//	**********************************************************************************************
		//		5.	CapSpd - calculate speed and capacity based on link characteristics
		//	**********************************************************************************************
		//	5555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
	
		ErrFileRec = null
	
	
		// CapSpd - Lookup and Factor Table for each record - stored in report
		FactorFileRec = null
		
		CapSpdFactorFile = Dir + "\\Report\\CapSpd_Factors_" + HwyView + ".asc"
		exist = GetFileInfo(CapSpdFactorFile)
		if exist then DeleteFile(CapSpdFactorFile)
		CapSpdFactor = CreateTable("CapSpdFactor", CapSpdFactorFile, "FFA",
				{{"ID", "Integer", 10, null, "Yes"},
				 {"Cap1hrBase", "Real", 10, 2, "No"},
				 {"Cap1hrMax", "Real", 10, 2, "No"},
				 {"FactypeFac_CapAB", "Real", 10, 4, "No"},
				 {"FactypeFac_CapBA", "Real", 10, 4, "No"},
				 {"Control_CapAB", "Real", 10, 4, "No"},
				 {"Control_CapBA", "Real", 10, 4, "No"},
				 {"Peak_Hours", "Real", 10, 2, "No"},
				 {"Midday_Hours", "Real", 10, 2, "No"},
				 {"Night_Hours", "Real", 10, 2, "No"},
				 {"ParkFac_TTFree", "Real", 10, 4, "No"},
				 {"ParkFac_TTPeak", "Real", 10, 4, "No"},
				 {"ATypeFac_TT", "Real", 10, 4, "No"},
				 {"TTPkEstFac", "Real", 10, 4, "No"},
				 {"LocTranFr_MPH", "Real", 10, 4, "No"},
				 {"XprTranFr_MPH", "Real", 10, 4, "No"},
				 {"LocTranPk_MPH", "Real", 10, 4, "No"},
				 {"XprTranPk_MPH", "Real", 10, 4, "No"},
				 {"MinSpeed", "Real", 10, 4, "No"},
				 {"CycleLen_A", "Real", 10, 4, "No"},
				 {"GreenPct_A", "Real", 10, 4, "No"},
				 {"DelayBase_A", "Real", 10, 4, "No"},
				 {"ProhibitFac_A", "Real", 10, 4, "No"},
				 {"LeftLnsFac_A", "Real", 10, 4, "No"},
				 {"RightLnsFac_A", "Real", 10, 4, "No"},
				 {"CycleLen_B", "Real", 10, 4, "No"},
				 {"GreenPct_B", "Real", 10, 4, "No"},
				 {"DelayBase_B", "Real", 10, 4, "No"},
				 {"ProhibitFac_B", "Real", 10, 4, "No"},
				 {"LeftLnsFac_B", "Real", 10, 4, "No"},
				 {"RightLnsFac_B", "Real", 10, 4, "No"},
				 {"TTLinkFrAB", "Real", 10, 2, "No"},
				 {"TTLinkFrBA", "Real", 10, 2, "No"},
				 {"TTLinkPkAB", "Real", 10, 2, "No"},
				 {"TTLinkPkBA", "Real", 10, 2, "No"},
				 {"IntDelFr_A", "Real", 10, 2, "No"},
				 {"IntDelFr_B", "Real", 10, 2, "No"}
				}) 
	
		// Time of Day periods (AM Peak, Midday, PM Peak, Night) - number of hours in each period
		Peak_Hours = 0
		Midday_Hours = 0
		Night_Hours = 0
		for i = 1 to 4 do
			if TimeOfDayCapacityHours[i][1] = "AMPeak"
				then Peak_Hours = TimeOfDayCapacityHours[i][2]
			else if TimeOfDayCapacityHours[i][1] = "Midday"
				then Midday_Hours = TimeOfDayCapacityHours[i][2]
			else if TimeOfDayCapacityHours[i][1] = "Night"
				then Night_Hours = TimeOfDayCapacityHours[i][2]
		end
		
		SetView(HwyView)
		ptr = GetFirstRecord(HwyView + "|",)
		while ptr <> null do 
			rec = GetRecordValues(HwyView, ptr, {"ID", "length", "dir", "Anode", "Bnode", "funcl", "lanesAB",
						"lanesBA", "factype", "SpdLimRun", "parking", 
						"areatp", "A_LeftLns", "A_RightLns", "A_Control", "A_Prohibit", "B_LeftLns", 
						"B_RightLns", "B_Control", "B_Prohibit", "OppFunclA", "OppFunclB"})
			ID = rec[1][2]
			Length = rec[2][2]
			TrafficDir = rec[3][2]
			Anode = rec[4][2]
			Bnode = rec[5][2]
			Funcl = rec[6][2]
			LanesAB = rec[7][2]
			LanesBA = rec[8][2]
			FacType = rec[9][2]
			SpdLimRun = rec[10][2]
			Parking = rec[11][2]
			AreaType = rec[12][2]
			A_LeftLns = rec[13][2]
			A_RightLns = rec[14][2]
			A_Control = rec[15][2]
			A_Prohibit = rec[16][2]
			B_LeftLns = rec[17][2]
			B_RightLns = rec[18][2]
			B_Control = rec[19][2]
			B_Prohibit = rec[20][2]
			OppFunclA = rec[21][2]
			OppFunclB = rec[22][2]
	
			// Initialize capspd fields
			Alpha = 0.
			Beta = 0.
			SPFreeAB = 0.
			SPFreeBA = 0.
			SPPeakAB = 0.
			SPPeakBA = 0.
			TTFreeAB = 0.
			TTFreeBA = 0.
			TTPeakAB = 0.
			TTPeakBA = 0.
			CapPk3hrAB = 0.
			CapPk3hrBA = 0.
			CapMidAB = 0.
			CapMidBA = 0.
			CapNightAB = 0.
			CapNightBA = 0.
			Cap1hrAB = 0.
			Cap1hrBA = 0. 
			TTPkLocAB = 0.
			TTPkLocBA = 0.
			TTPkXprAB = 0.
			TTPkXprBA = 0. 
			TTFrLocAB = 0.
			TTFrLocBA = 0.
			TTFrXprAB = 0.
			TTFrXprBA = 0.
			PkLocLUAB = 0.
			PkLocLUBA = 0.
			PkXprLUAB = 0.
			PkXprLUBA = 0.
			TTPkNStAB = 0.
			TTPkNStBA = 0.
			TTFrNStAB = 0.
			TTFrNStBA = 0.
			TTPkSkSAB = 0.
			TTPkSkSBA = 0.
			TTFrSkSAB = 0.
			TTFrSkSBA = 0.
			TTWalkAB = 0.
			TTWalkBA = 0.
			TTBikeAB = 0.
			TTBikeBA = 0.
			ImpPkAB = 0.
			ImpPkBA = 0.
			ImpFreeAB = 0.
			ImpFreeBA = 0.
			BRT_Flag = 0.
			Mode = 0.
	
			// Zero out intermediate variables
			LaneCap1hr_Base = 0.
			LaneCap1hr_Max = 0.
			Cap_FacType_CapFacAB = 0.
			Cap_FacType_CapFacBA = 0.
			ParkingFac_TTFree = 0.
			ParkingFac_TTPeak = 0.
			ATypeFac_rec = 0.
			TTPkEstFac_rec = 0.
			LocTranFreeSpeed_rec = 0.
			XprTranFreeSpeed_rec = 0.
			LocTranPeakSpeed_rec = 0.
			XprTranPeakSpeed_rec = 0.
			MinSpeed = 0.
			CycleLen_A = 0.
			GreenPct_A = 0.
			ProhibitFac_A = 0.
			GreenPct_A = 0.
			LeftLnsFac_A = 0.
			RightLnsFac_A = 0.
			DelayBase_A = 0.
			CycleLen_B = 0.
			GreenPct_B = 0.
			DelayBase_B = 0.
			ProhibitFac_B = 0.
			LeftLnsFac_B = 0.
			RightLnsFac_B = 0.
	 		TTLinkFrAB = 0.
	 		TTLinkFrBA = 0.
	 		TTLinkpKAB = 0.
	 		TTLinkpKBA = 0.
	 		IntDelFr_A = 0.
	 		IntDelFr_B = 0.
	 		TTPkEstAB = 0.
	 		TTPkEstBA  = 0.
	
	
			//**********************************************************************************************
			// Walk and Bike Travel Time, Mode (Walk mode)
			//**********************************************************************************************
			// Surface streets, connectors 
			if (Funcl > 1 and Funcl < 9) or Funcl = 84 or Funcl = 85 or Funcl = 90 or Funcl = 92
				then do
					// Walk 3 MPH - either direction regardless of traffic flow, 
					TTWalkAB = Length * 20. 		// Travel time @ 3 MPH (60 / 3 = 20) 
					TTWalkBA = Length * 20. 	
					// Bikes must obey traffic flow			
					if TrafficDir > -1 
						then TTBikeAB = Length * 8.57	// Travel time @ 7 MPH (60 / 7 = 8.57)
						else TTBikeAB = 999.
					if TrafficDir < 1
						then TTBikeBA = Length * 8.57	
						else TTBikeBA = 999.
					// Mode - WalkMode in transit skims : 10 - walk ok, 0 - walk prohibited
					Mode = 10
				end //surface streets
			
				// Freeways, Freeway ramps, HOV, Transit guideways - walk / bike prohibited
				else do
					TTWalkAB = 999.
					TTWalkBA = 999.	
					TTBikeAB = 999.
					TTBikeBA = 999.	
					Mode = 0
				end
	
			//**********************************************************************************************
			// Highway Assignment Delay Coefficients - Alpha and Beta
			//**********************************************************************************************
			//	HwyDelay1ln[21][11]   :  Alpha / Beta for each area type, single ln facilities]  
			//  	HwyDelay3ln[21][11]      Alpha / Beta for each area type multi ln facilities 
			if 	(TrafficDir = 0 and LanesAB + LanesBA > 2) or
					(TrafficDir = 1 and LanesAB > 1) or
					(TrafficDir = -1 and LanesBA > 1) then do
				rownum = RunMacro("FindRow",HwyDelay3ln, Funcl)			
				Alpha = HwyDelay3ln[rownum][AreaType*2]
				Beta  = HwyDelay3ln[rownum][AreaType*2 + 1]
			end
			else do
				rownum = RunMacro("FindRow",HwyDelay1ln, Funcl)			
				Alpha = HwyDelay1ln[rownum][AreaType*2]
				Beta  = HwyDelay1ln[rownum][AreaType*2 + 1]
			end 	
	
			//**********************************************************************************************
			// Centroid connectors and centroid to transit connectors (funcl 90 and 92)
			//**********************************************************************************************
			if Funcl = 90 or Funcl = 92
				then do
					TT = (Length / SpdLimRun) * 60.
					if TrafficDir > -1 
						then do
							TTFreeAB = TT
							TTPeakAB = TT
							TTPkEstAB = TT
							SPFreeAB = SpdLimRun
							SPPeakAB = SpdLimRun
							Cap1hrAB = 1000.
							CapPk3hrAB = Cap1hrAB * Peak_Hours
							CapMidAB = Cap1hrAB * Midday_Hours
							CapNightAB = Cap1hrAB * Night_Hours
						end  // trafficdir > -1
					if TrafficDir < 1 
						then do
							TTFreeBA = TT
							TTPeakBA = TT
							TTPkEstBA = TT
							SPFreeBA = SpdLimRun
							SPPeakBA = SpdLimRun
							Cap1hrBA = 1000.
							CapPk3hrBA = Cap1hrBA * Peak_Hours
							CapMidBA = Cap1hrBA * Midday_Hours
							CapNightBA = Cap1hrBA * Night_Hours
						end  // trafficdir < 1
					goto donewithrecord
				end // funcl = 90 or 92			
	
			//**********************************************************************************************
			// Walk to transit link - funcl = 85 - travel time = 1 minute, mode = 10 (ok to walk)
			//**********************************************************************************************
			if Funcl = 85
				then do
					SPFreeAB = 3.
					SPFreeBA = 3.
					SPPeakAB = 3.
					SPPeakBA = 3.
					TTFreeAB = 1.
					TTFreeBA = 1.
					TTPeakAB = 1.
					TTPeakBA = 1.
					TTPkEstAB = 1.
					TTPkEstBA = 1.
					TTPkLocAB = 1.
					TTPkLocBA = 1.
					TTPkXprAB = 1.
					TTPkXprBA = 1.
					TTFrLocAB = 1.
					TTFrLocBA = 1.
					TTFrXprAB = 1.
					TTFrXprBA = 1.
					TTPkNStAB = 1.
					TTPkNStBA = 1.
					TTFrNStAB = 1.
					TTFrNStBA = 1.
					TTPkSkSAB = 1.
					TTPkSkSBA = 1.
					TTFrSkSAB = 1.
					TTFrSkSBA = 1.
					TTwalkAB = 1.
					TTwalkBA = 1.
					TTbikeAB = 1.
					TTbikeBA = 1.
					ImpPkAB = 1.
					ImpPkBA = 1.
					ImpFreeAB = 1.
					ImpFreeBA = 1.
					Mode = 10
					goto donewithrecord
				end // funcl = 85	
							
			//************************************************************************************************
			// Look up Travel Time and Capacity Factors - not dependent on traffic direction
			//************************************************************************************************
	
			// Base Lane Capacity - varies funcl x area type
			//	max 2000 / lane for surface and 2200 / lane for freeway
			rownum = RunMacro("FindRow",LaneCap1hr, Funcl)			
			LaneCap1hr_Base = LaneCap1hr[rownum][AreaType + 1]
			LaneCap1hr_Max =  LaneCap1hr[rownum][7]
				
			//	Parking, PedActivity, DevelopDen, DrivewayDen 
			//	each has travel time (free speed) and capacity factor
	
			rownum = RunMacro("FindRow",ParkingFac, Parking)			
			ParkingFac_TTFree = ParkingFac[rownum][2]
			ParkingFac_TTPeak = ParkingFac[rownum][3]
		
			// AREA TYPE PACTOR - NOT Speed - old versions had reciprocal for this factor  (2/2/19)
			//	Minimum and maximum speed in MPH 
			rownum = RunMacro("FindRow",ATypeFac, Funcl)			
			ATypeFac_rec = ATypeFac[rownum][AreaType + 1]
			MinSpeed = ATypeFac[rownum][7]
		
			// Peak Estimated Travel time factor (funcl x area type) - calc free speed first, then factor for peak 
			rownum = RunMacro("FindRow",TTPkEstFac, Funcl)			
			TTPkEstFac_rec = TTPkEstFac[rownum][AreaType + 1]
	
			// Transit speeds - MPH - Free speed and peak - Local and Express  (MAX of 90% general traffic MPH) 
			rownum = RunMacro("FindRow",LocTranFreeSpeed, Funcl)			
			LocTranFreeSpeed_rec = LocTranFreeSpeed[rownum][AreaType + 1]
	
			rownum = RunMacro("FindRow",XprTranFreeSpeed, Funcl)			
			XprTranFreeSpeed_rec = XprTranFreeSpeed[rownum][AreaType + 1]
	
			rownum = RunMacro("FindRow",LocTranPeakSpeed, Funcl)			
			LocTranPeakSpeed_rec = LocTranPeakSpeed[rownum][AreaType + 1]
	
			rownum = RunMacro("FindRow",XprTranPeakSpeed, Funcl)			
			XprTranPeakSpeed_rec = XprTranPeakSpeed[rownum][AreaType + 1]
	
	
			//************************************************************************************************
			// A -> B direction
			//************************************************************************************************
			
			if TrafficDir > -1
				then do
	
					//************************************************************************************************
					// B Node Intersection delay, zero delay for thru (funcl = T)  
					//************************************************************************************************
					// factors that do not differ by signalized / non signalized
	
					// Turn prohibitions factor
					rownum = RunMacro("FindRow",IntX_Prohibit, B_Prohibit)			
					ProhibitFac_B = IntX_Prohibit[rownum][2]
	
					// Non signalized B intersection
					if B_Control = "S" or B_Control = "F" or B_Control = "Y" or B_Control = "R"
						then do
							// Base no. seconds
							rownum = RunMacro("FindRow",IntX_Control, B_Control)
							DelayBase_B = IntX_Control[rownum][2]
		
							// Turn lanes factors
							if B_LeftLns = 1 
								then LeftLnsFac_B = IntX_TurnLanes[1][3]
								else if B_LeftLns > 1 then LeftLnsFac_B = IntX_TurnLanes[2][3]
								else LeftLnsFac_B = 1.0
							if B_RightLns > 0
								then RightLnsFac_B = IntX_TurnLanes[3][3]
								else RightLnsFac_B = 1.0										
							IntDelFr_B	= DelayBase_B * ProhibitFac_B * LeftLnsFac_B * RightLnsFac_B 
	
						end // B node - non signalized
	
					// signalized intersection
					else if B_Control = "L"
						then do
							// Cycle Length - funcl x area type
							rownum = RunMacro("FindRow",IntX_CycleLength, Funcl)			
							CycleLen_B = IntX_CycleLength[rownum][AreaType + 1]
	
							// IntX_GreenPct - based on opposing funcl
							rownum = RunMacro("FindRow",IntX_GreenPct, Funcl)			
	
							// find column for opposing funcl in IntX_GreenPct - same array - but first col is link funcl 
							colnum = RunMacro("FindRow",IntX_GreenPct, OppFunclB) + 1
							GreenPct_B = IntX_GreenPct[rownum][colnum] 
	
							// Turn lanes factors
							if B_LeftLns = 1 
								then LeftLnsFac_B = IntX_TurnLanes[1][2]
								else if B_LeftLns > 1 then LeftLnsFac_B = IntX_TurnLanes[2][2]
								else LeftLnsFac_B = 1.0
							if B_RightLns > 0
								then RightLnsFac_B = IntX_TurnLanes[3][2]
								else RightLnsFac_B = 1.0
											
							// IntDelFr_B : B node signalized intersection delay (free speed) 
							GreenTime_B = CycleLen_B * GreenPct_B
							RedTime_B = CycleLen_B - GreenTime_B
							DelayBase_B = (RedTime_B / CycleLen_B) * (RedTime_B / 2.0)
					
							IntDelFr_B = DelayBase_B * ProhibitFac_B * LeftLnsFac_B * RightLnsFac_B 
						end // B_Control = L
	
	
					//************************************************************************************************
					// Capacity (AB), base lane cap - factored with max 2000 / lane for surface and 2200 / lane for freeway
					//************************************************************************************************
					CapBase = LanesAB * LaneCap1hr_Base
					CapMax = LanesAB * LaneCap1hr_Max
				
					// Facility Type Capacity factor (differs by 1, 2, or 3+ lanes
					rownum = RunMacro("FindRow",Cap_FacType, FacType)
					if LanesAB > 2 then colnum = 4
					else if LanesAB = 2 then colnum = 3
					else colnum = 2
				
					Cap_FacType_CapFacAB = Cap_FacType[rownum][colnum]			
				
					// Intersection Control Capacity Factor 
					// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
					// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
					//  Signalized - cut capacity to green percemtage - otherwise use lookup
					// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
					// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
					rownum = RunMacro("FindRow",Cap_Control, B_Control)
					if B_Control = "L" 
						then IntX_Control_CapFacAB = GreenPct_B 
						else IntX_Control_CapFacAB = Cap_Control[rownum][2]
				
					Cap1hrAB = 
						MIN(CapBase * Cap_FacType_CapFacAB * IntX_Control_CapFacAB, CapMax) 
					CapPk3hrAB = Cap1hrAB * Peak_Hours
					CapMidAB = Cap1hrAB * Midday_Hours
					CapNightAB = Cap1hrAB * Night_Hours
	
					//************************************************************************************************
					// Travel time - Free Speed.  Estimated Peak travel time is a factor of free speed
					//	starts with SpdLimRun (SpdLimit - adjusted for future year area type)
					//************************************************************************************************
	
					// TTLinkFrAB:  Link travel time (minutes) A->B  (free speed) (NOT INCLUDING INTERSECTION DELAY)
					// TTFreeAB , SPFreeAB :  minimum speed (MPH) - MinSpeed on SpdLimitFactor table
					TTLinkFrAB	=  ((Length / SpdLimRun) * 60.0) * ParkingFac_TTFree * ATypeFac_rec	 
					TTFreeAB = TTLinkFrAB + (IntDelFr_B / 60.)
					SPFreeAB = Length / (TTFreeAB / 60.)
					if SPFreeAB < MinSpeed
						then do
							cnterrlvl1 = cnterrlvl1 + 1
							ErrFileRec = ErrFileRec + {{ID, "Link", "Warning", "SPFreeAB", SPFreeAB, 
								"Speed < minimum " + r2s(MinSpeed) + " MPH, SPFreeAB and TTFreeAB set to minimum"}}
							SPFreeAB = MinSpeed
							TTFreeAB = Length / (SPFreeAB / 60.)
						end
						
					// TTPeakAB , SPPeakAB :  minimum speed (MPH) - MinSpeed on SpdLimitFactor table
					// Includes peak perking prohibitions and TTPkEst
					TTLinkPkAB	=  ((Length / SpdLimRun) * 60.0) * ParkingFac_TTPeak * ATypeFac_rec	 
					TTPeakAB = TTLinkPkAB	+ (IntDelFr_B / 60.) * TTPkEstFac_rec
					SPPeakAB = Length / (TTPeakAB / 60.)
					if SPPeakAB < MinSpeed
						then do
							cnterrlvl1 = cnterrlvl1 + 1
							ErrFileRec = ErrFileRec + {{ID, "Link", "Warning", "SPPeakAB", SPPeakAB, 
								"Speed < minimum " + r2s(MinSpeed) + " MPH, SPPeakAB and TTPeakAB set to minimum"}}
							SPPeakAB = MinSpeed
							TTPeakAB = Length / (SPPeakAB / 60.)
						end
					TTPkEstAB = TTPeakAB
						
					// Impedance  
					ImpFreeAB	= (TTFreeAB * timeweight) + (Length * distweight)
					ImpPkAB 	= (TTPeakAB * timeweight) + (Length * distweight)
	
					// TTFrLocAB , TTFrxprAB , TTPkLocAB, TTPkxprAB : Transit default speeds (MPH) - not to exceed 90% of vehicle speed 
					TTFrLocAB = max(TTFreeAB / 0.90, Length / (LocTranFreeSpeed_rec / 60.))
					TTFrXprAB = max(TTFreeAB / 0.90, Length / (XprTranFreeSpeed_rec / 60.))
					TTPkLocAB = max(TTPeakAB / 0.90, Length / (LocTranPeakSpeed_rec / 60.))
					TTPkXprAB = max(TTPeakAB / 0.90, Length / (XprTranPeakSpeed_rec / 60.))
	
					// PkLocLUAB , PkXprLUAB : retain look-up transit speed for revision to speeds in feedbck loop (McLelland, Aug 15)
					PkLocLUAB = LocTranPeakSpeed_rec
					PkXprLUAB = XprTranPeakSpeed_rec			
	
					// TTFrNStAB , TTPkNStAB :  Non-stop transit speed - same as background traffic
					TTFrNStAB = TTFreeAB
					TTPkNStAB = TTPeakAB
		
					// TTFrSkSAB , TTPkSkSAB : Skip stop transit speeds set to average of local and express speeds , McLelland - Dec. 29, 2005
					TTFrSkSAB = (TTFrLocAB + TTFrXprAB) / 2.0
					TTPkSkSAB = (TTPkLocAB + TTPkXprAB) / 2.0
	
	
				end // A -> B direction
	
		//************************************************************************************************
		// B -> A direction
		//************************************************************************************************
	
			if TrafficDir < 1
				then do
	
					//************************************************************************************************
					// A Node Intersection delay, zero delay for thru (funcl = T)  
					//************************************************************************************************
					// factors that do not differ by signalized / non signalized
	
					// Turn prohibitions factor
					rownum = RunMacro("FindRow",IntX_Prohibit, A_Prohibit)			
					ProhibitFac_A = IntX_Prohibit[rownum][2]
	
					// Non signalized A intersection
					if A_Control = "S" or A_Control = "F" or A_Control = "Y" or A_Control = "R"
						then do
							// Base no. seconds
							rownum = RunMacro("FindRow",IntX_Control, A_Control)
							DelayBase_A = IntX_Control[rownum][2]
		
							// Turn lanes factors
							if A_LeftLns = 1 
								then LeftLnsFac_A = IntX_TurnLanes[1][3]
								else if A_LeftLns > 1 then LeftLnsFac_A = IntX_TurnLanes[2][3]
								else LeftLnsFac_A = 1.0
							if A_RightLns > 0
								then RightLnsFac_A = IntX_TurnLanes[3][3]
								else RightLnsFac_A = 1.0
											
							IntDelFr_A = DelayBase_A * ProhibitFac_A * LeftLnsFac_A * RightLnsFac_A 
						end // A node - non signalized
	
					// signalized intersection
					else if A_Control = "L"
						then do
							// Cycle Length - funcl x area type
							rownum = RunMacro("FindRow",IntX_CycleLength, Funcl)			
							CycleLen_A = IntX_CycleLength[rownum][AreaType + 1]
	
							// IntX_GreenPct - based on opposing funcl
							rownum = RunMacro("FindRow",IntX_GreenPct, Funcl)			
	
							// find column for opposing funcl in IntX_GreenPct - same array - but first col is link funcl 
							colnum = RunMacro("FindRow",IntX_GreenPct, OppFunclA) + 1
							GreenPct_A = IntX_GreenPct[rownum][colnum] 
	
							// Turn lanes factors
							if A_LeftLns = 1 
								then LeftLnsFac_A = IntX_TurnLanes[1][2]
								else if A_LeftLns > 1 then LeftLnsFac_A = IntX_TurnLanes[2][2]
								else LeftLnsFac_A = 1.0
							if A_RightLns > 0
								then RightLnsFac_A = IntX_TurnLanes[3][2]
								else RightLnsFac_A = 1.0
											
							// IntDelFr_A : A node signalized intersection delay (free speed) 
							GreenTime_A = CycleLen_A * GreenPct_A
							RedTime_A = CycleLen_A - GreenTime_A
							DelayBase_A = (RedTime_A / CycleLen_A) * (RedTime_A / 2.0)
					
							IntDelFr_A = DelayBase_A * ProhibitFac_A * LeftLnsFac_A * RightLnsFac_A 
						end // A_Control = L
	
	
					//************************************************************************************************
					// Capacity (BA), base lane cap - factored with max 2000 / lane for surface and 2200 / lane for freeway
					//************************************************************************************************
					CapBase = LanesBA * LaneCap1hr_Base
					CapMax = LanesBA * LaneCap1hr_Max
				
					// Facility Type Capacity factor (differs by 1, 2, or 3+ lanes
					rownum = RunMacro("FindRow",Cap_FacType, FacType)
					if LanesBA > 2 then colnum = 4
					else if LanesBA = 2 then colnum = 3
					else colnum = 2
				
					Cap_FacType_CapFacBA = Cap_FacType[rownum][colnum]			
				
					// Intersection Control Capacity Factor 
					// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
					// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
					//  Signalized - cut capacity to green percentage - otherwise use lookup
					// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
					// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
					rownum = RunMacro("FindRow",Cap_Control, A_Control)
					if A_Control = "L" 
						then IntX_Control_CapFacBA = GreenPct_A 
						else IntX_Control_CapFacBA = Cap_Control[rownum][2]
				
					Cap1hrBA = 
						MIN(CapBase * Cap_FacType_CapFacBA * IntX_Control_CapFacBA, CapMax) 
					CapPk3hrBA = Cap1hrBA * Peak_Hours
					CapMidBA = Cap1hrBA * Midday_Hours
					CapNightBA = Cap1hrBA * Night_Hours
	
	
					//************************************************************************************************
					// Travel time - Free Speed.  Estimated Peak travel time is a factor of free speed
					//	starts with SpdLimRun (SpdLimit - adjusted for future year area type)
					//************************************************************************************************
	
					// TTLinkFrBA:  Link travel time (minutes) B->A  (free speed) (NOT INCLUDING INTERSECTION DELAY)
					// TTFreeBA , SPFreeBA :  minimum speed (MPH) - MinSpeed on SpdLimitFactor table
					TTLinkFrBA	=  ((Length / SpdLimRun) * 60.0) * ParkingFac_TTFree * ATypeFac_rec	 
					TTFreeBA = TTLinkFrBA + (IntDelFr_A / 60.)
					SPFreeBA = Length / (TTFreeBA / 60.)
	
					if SPFreeBA < MinSpeed
						then do
							cnterrlvl1 = cnterrlvl1 + 1
							ErrFileRec = ErrFileRec + {{ID, "Link", "Warning", "SPFreeBA", SPFreeBA, 
								"Speed < minimum " + r2s(MinSpeed) + " MPH, SPFreeBA and TTFreeBA set to minimum"}}
							SPFreeBA = MinSpeed
							TTFreeBA = Length / (SPFreeBA / 60.)
						end
						
	
					// TTPeakBA , SPPeakBA :  minimum speed (MPH) - MinSpeed on SpdLimitFactor table
					// Includes peak perking prohibitions and TTPkEst
					TTLinkPkBA	=  ((Length / SpdLimRun) * 60.0) * ParkingFac_TTPeak * ATypeFac_rec	 
					TTPeakBA = TTLinkPkBA	+ (IntDelFr_A / 60.) * TTPkEstFac_rec
					SPPeakBA = Length / (TTPeakBA / 60.)
	
					if SPPeakBA < MinSpeed
						then do
							cnterrlvl1 = cnterrlvl1 + 1
							ErrFileRec = ErrFileRec + {{ID, "Link", "Warning", "SPPeakBA", SPPeakBA, 
								"Speed < minimum " + r2s(MinSpeed) + " MPH, SPPeakBA and TTPeakBA set to minimum"}}
							SPPeakBA = MinSpeed
							TTPeakBA = Length / (SPPeakBA / 60.)
						end
					TTPkEstBA = TTPeakBA
						
					// Impedance  
					ImpFreeBA	= (TTFreeBA * timeweight) + (Length * distweight)
					ImpPkBA 	= (TTPeakBA * timeweight) + (Length * distweight)
	
					// TTFrLocBA , TTFrxprBA , TTPkLocBA, TTPkxprBA : Transit default speeds (MPH) - not to exceed 90% of vehicle speed 
					TTFrLocBA = max(TTFreeBA / 0.90, Length / (LocTranFreeSpeed_rec / 60.))
					TTFrXprBA = max(TTFreeBA / 0.90, Length / (XprTranFreeSpeed_rec / 60.))
					TTPkLocBA = max(TTPeakBA / 0.90, Length / (LocTranPeakSpeed_rec / 60.))
					TTPkXprBA = max(TTPeakBA / 0.90, Length / (XprTranPeakSpeed_rec / 60.))
	
					// PkLocLUBA , PkXprLUBA : retain look-up transit speed for revision to speeds in feedbck loop (McLelland, Aug 15)
					PkLocLUBA = LocTranPeakSpeed_rec
					PkXprLUBA = XprTranPeakSpeed_rec			
	
					// TTFrNStBA , TTPkNStBA :  Non-stop transit speed - same as background traffic
					TTFrNStBA = TTFreeBA
					TTPkNStBA = TTPeakBA
		
					// TTFrSkSBA , TTPkSkSBA : Skip stop transit speeds set to average of local and express speeds , McLelland - Dec. 29, 2005
					TTFrSkSBA = (TTFrLocBA + TTFrXprBA) / 2.0
					TTPkSkSBA = (TTPkLocBA + TTPkXprBA) / 2.0
	
				end // B -> A direction
	
		//((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((
			// Fill capspd variables in HwyView and get next record
	
			donewithrecord:
	
			SetRecordValues(HwyView, ptr, 
				{
				 {"Alpha", Alpha},			{"Beta", Beta}, 
				 {"SPFreeAB", SPFreeAB},		{"SPFreeBA", SPFreeBA}, 
				 {"SPPeakAB", SPPeakAB},		{"SPPeakBA", SPPeakBA}, 
				 {"TTFreeAB", TTFreeAB},		{"TTFreeBA", TTFreeBA}, 
				 {"TTPeakAB", TTPeakAB},		{"TTPeakBA", TTPeakBA}, 
				 {"TTPkEstAB", TTPeakAB},	{"TTPkEstBA", TTPeakBA}, 
				 {"TTPkPrevAB", TTPeakAB},	{"TTPkPrevBA", TTPeakBA}, 
				 {"TTPkAssnAB", TTPeakAB},	{"TTPkAssnBA", TTPeakBA}, 
				 {"CapPk3hrAB", CapPk3hrAB},	{"CapPk3hrBA", CapPk3hrBA}, 
				 {"CapMidAB", CapMidAB},		{"CapMidBA", CapMidBA}, 
				 {"CapNightAB", CapNightAB},	{"CapNightBA", CapNightBA}, 
				 {"Cap1hrAB", Cap1hrAB},		{"Cap1hrBA", Cap1hrBA}, 
				 {"TTFrLocAB", TTFrLocAB},	{"TTFrLocBA", TTFrLocBA}, 
				 {"TTFrXprAB", TTFrXprAB},	{"TTFrXprBA", TTFrXprBA}, 
				 {"TTPkLocAB", TTPkLocAB},	{"TTPkLocBA", TTPkLocBA}, 
				 {"TTPkXprAB", TTPkXprAB},	{"TTPkXprBA", TTPkXprBA}, 
				 {"TTPkNStAB", TTPkNStAB},	{"TTPkNStBA", TTPkNStBA}, 
				 {"TTFrNStAB", TTFrNStAB},	{"TTFrNStBA", TTFrNStBA}, 
				 {"TTPkSkSAB", TTPkSkSAB},	{"TTPkSkSBA", TTPkSkSBA}, 
				 {"TTFrSkSAB", TTFrSkSAB},	{"TTFrSkSBA", TTFrSkSBA}, 
				 {"PkLocLUAB", TTPkLocAB},	{"PkLocLUBA", TTPkLocBA}, 
				 {"PkXprLUAB", TTPkXprAB},	{"PkXprLUBA", TTPkXprBA}, 
				 {"TTWalkAB", TTWalkAB},		{"TTWalkBA", TTWalkBA}, 
				 {"TTBikeAB", TTBikeAB},		{"TTBikeBA", TTBikeBA}, 
				 {"ImpPkAB", ImpPkAB},		{"ImpPkBA", ImpPkBA}, 
				 {"ImpFreeAB", ImpFreeAB},	{"ImpFreeBA", ImpFreeBA}, 
				 {"Mode", Mode}
				})
	
			// Write capspdfactor table in report subdirectory
				SetView(CapSpdFactor)
	
				factorvals = 	
					{
					 {"ID", ID},			 
					 {"Cap1hrBase", LaneCap1hr_Base},				{"Cap1hrMax", LaneCap1hr_Max},
					 {"FactypeFac_CapAB", Cap_FacType_CapFacAB},		{"FactypeFac_CapBA", Cap_FacType_CapFacBA},
					 {"Control_CapAB", IntX_Control_CapFacAB},		{"Control_CapBA", IntX_Control_CapFacBA},
					 {"Peak_Hours", Peak_Hours},					{"Midday_Hours", Midday_Hours},
					 {"Night_Hours", Night_Hours},
					 {"ParkFac_TTFree", ParkingFac_TTFree},			{"ParkFac_TTPeak", ParkingFac_TTPeak},
					 {"ATypeFac_TT", ATypeFac_rec},
					 {"TTPkEstFac", TTPkEstFac_rec},
					 {"LocTranFr_MPH", LocTranFreeSpeed_rec},		{"XprTranFr_MPH", XprTranFreeSpeed_rec},
					 {"LocTranPk_MPH", LocTranPeakSpeed_rec},		{"XprTranPk_MPH", XprTranPeakSpeed_rec},
					 {"MinSpeed", MinSpeed},						
					 {"CycleLen_A",  CycleLen_A},					{"GreenPct_A", GreenPct_A},
					 {"ProhibitFac_A", ProhibitFac_A},				{"DelayBase_A", DelayBase_A},
					 {"LeftLnsFac_A", LeftLnsFac_A},				{"RightLnsFac_A", RightLnsFac_A},
					 {"CycleLen_B", CycleLen_B},					{"GreenPct_B", GreenPct_B},
					 {"ProhibitFac_B", ProhibitFac_B},				{"DelayBase_B", DelayBase_B},
					 {"LeftLnsFac_B", LeftLnsFac_B},				{"RightLnsFac_B", RightLnsFac_B},
	 				 {"TTLinkFrAB", TTLinkFrAB},					{"TTLinkFrBA", TTLinkFrBA}, 
					 {"TTLinkPkAB", TTLinkPkAB},					{"TTLinkPkBA", TTLinkPkBA}, 
					 {"IntDelFr_A", IntDelFr_A},					{"IntDelFr_B", IntDelFr_B} 
				}
	
			AddRecord (CapSpdFactor, factorvals)
			setview(HwyView)
			ptr = GetNextRecord(HwyView + "|", null,)
			rec = null
		end  // while ptr
		//((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((
	
	
		skip_to_guideway:
	
		if GuidewayOverride = "False"
			then goto noguideway
			
		stat = UpdateProgressBar("Guideway travel time overrides", 90)
		// Transit guideways - travel time override based on CATS schedules / plans & speed estimates from other cities
		//  legal guideway (funcl=22  HOV 2+ - transit speeds only,
		//                          funcl=23  HOV 3+ - transit speeds only,
		//                          funcl=24  HOV 3+ - transit speeds only,
		//                          funcl=25  HOV 3+ - transit speeds only,
		//                          funcl=30  Rail, - all speeds 
		//                          funcl=40  BRT - all speeds
	
		// Transit guideways - travel time override based on CATS schedules / plans & speed estimates from other cities
	
		GuidewayTT	= OpenTable("GuidewayTT", "FFA", {GuidewayFile},)
	
		guidewayview = 	JoinViews("guidewayview", HwyView + ".ID", "GuidewayTT.ID",)
		SetView(guidewayview)
		selguideway = "select * where GuidewayTT.ID <> null"
		nguideway = SelectByQuery("GuidewayLinks", "Several", selguideway, )
		if nguideway = 0 then goto noguideway
	
		selalltraveltime = "select * where funcl = 22 or funcl = 23 or funcl = 24 or funcl = 25 or funcl = 30 or funcl = 40"
		selexclusiveguideway = "select * where funcl = 30 or funcl = 40"
	
		// Transit speeds for all guideways 
		nalltraveltime = SelectByQuery("AllTravelTime", "Several", selalltraveltime, {{"Source And", "GuidewayLinks"}} )	
		if nalltraveltime > 0
			then do
				vAB_TT 		= GetDataVector("guidewayview|AllTravelTime", "AB_TT",)
				vAB_NonStop = GetDataVector("guidewayview|AllTravelTime", "AB_NonStop",)
				vAB_SkipStop = (vAB_TT + vAB_NonStop) / 2.0
				
				SetDataVector("guidewayview|AllTravelTime", "TTFrLocAB", vAB_TT, )
				SetDataVector("guidewayview|AllTravelTime", "TTFrXprAB", vAB_TT, )
				SetDataVector("guidewayview|AllTravelTime", "TTPkLocAB", vAB_TT, )
				SetDataVector("guidewayview|AllTravelTime", "TTPkXprAB", vAB_TT, )
				SetDataVector("guidewayview|AllTravelTime", "PkLocLUAB", vAB_TT, )
				SetDataVector("guidewayview|AllTravelTime", "PkXprLUAB", vAB_TT, )
				SetDataVector("guidewayview|AllTravelTime", "TTFrNStAB", vAB_NonStop, )
				SetDataVector("guidewayview|AllTravelTime", "TTPkNStAB", vAB_NonStop, )
				SetDataVector("guidewayview|AllTravelTime", "TTFrSksAB", vAB_SkipStop, )
				SetDataVector("guidewayview|AllTravelTime", "TTPkSksAB", vAB_SkipStop, )
	
				vBA_TT 		= GetDataVector("guidewayview|AllTravelTime", "BA_TT",)
				vBA_NonStop = GetDataVector("guidewayview|AllTravelTime", "BA_NonStop",)
				vBA_SkipStop = (vBA_TT + vBA_NonStop) / 2.0
				
				SetDataVector("guidewayview|AllTravelTime", "TTFrLocBA", vBA_TT, )
				SetDataVector("guidewayview|AllTravelTime", "TTFrXprBA", vBA_TT, )
				SetDataVector("guidewayview|AllTravelTime", "TTPkLocBA", vBA_TT, )
				SetDataVector("guidewayview|AllTravelTime", "TTPkXprBA", vBA_TT, )
				SetDataVector("guidewayview|AllTravelTime", "PkLocLUBA", vBA_TT, )
				SetDataVector("guidewayview|AllTravelTime", "PkXprLUBA", vBA_TT, )
				SetDataVector("guidewayview|AllTravelTime", "TTFrNStBA", vBA_NonStop, )
				SetDataVector("guidewayview|AllTravelTime", "TTPkNStBA", vBA_NonStop, )
				SetDataVector("guidewayview|AllTravelTime", "TTFrSksBA", vBA_SkipStop, )
				SetDataVector("guidewayview|AllTravelTime", "TTPkSksBA", vBA_SkipStop, )
			end // if nalltraveltime
	
		// Exclusive transit guideway - all speed / travel time fields
		nexclusive = SelectByQuery("ExclusiveGuideway", "Several", selexclusiveguideway, {{"Source And", "GuidewayLinks"}}  )	
		if nexclusive > 0
			then do
				vlength		= GetDataVector("guidewayview|ExclusiveGuideway", "length",)
				vAB_TT 		= GetDataVector("guidewayview|ExclusiveGuideway", "AB_TT",)
				vAB_NonStop = GetDataVector("guidewayview|ExclusiveGuideway", "AB_NonStop",)
				vAB_SkipStop = (vAB_TT + vAB_NonStop) / 2.0
				vAB_speed 	= vlength / (vAB_TT / 60.)			
	
				SetDataVector("guidewayview|ExclusiveGuideway", "TTfreeAB", vAB_TT, )
				SetDataVector("guidewayview|ExclusiveGuideway", "TTpeakAB", vAB_TT, )
				SetDataVector("guidewayview|ExclusiveGuideway", "TTPkEstAB", vAB_TT, )
				SetDataVector("guidewayview|ExclusiveGuideway", "TTPkPrevAB", vAB_TT, )
				SetDataVector("guidewayview|ExclusiveGuideway", "TTPkAssnAB", vAB_TT, )
				SetDataVector("guidewayview|ExclusiveGuideway", "SPfreeAB", vAB_speed, )
				SetDataVector("guidewayview|ExclusiveGuideway", "SPpeakAB", vAB_speed, )
	
				vBA_TT 		= GetDataVector("guidewayview|ExclusiveGuideway", "BA_TT",)
				vBA_NonStop = GetDataVector("guidewayview|ExclusiveGuideway", "BA_NonStop",)
				vBA_SkipStop = (vBA_TT + vBA_NonStop) / 2.0
				vBA_speed 	= vlength / (vBA_TT / 60.)			
				
				SetDataVector("guidewayview|ExclusiveGuideway", "TTfreeBA", vBA_TT, )
				SetDataVector("guidewayview|ExclusiveGuideway", "TTpeakBA", vBA_TT, )
				SetDataVector("guidewayview|ExclusiveGuideway", "TTPkEstBA", vBA_TT, )
				SetDataVector("guidewayview|ExclusiveGuideway", "TTPkPrevBA", vBA_TT, )
				SetDataVector("guidewayview|ExclusiveGuideway", "TTPkAssnBA", vBA_TT, )
				SetDataVector("guidewayview|ExclusiveGuideway", "SPfreeBA", vBA_speed, )
				SetDataVector("guidewayview|ExclusiveGuideway", "SPpeakBA", vBA_speed, )
			end // if nexclusive
		CloseView(GuidewayTT)
		CloseView(guidewayview)
		noguideway:
		// Write Error / warning messages
		if ErrFileRec <> null 
			then do
				SetView(CapSpdErr)
				for i = 1 to ErrFileRec.length do
					errvals = 	{{"ID", ErrFileRec[i][1]}, {"ErrLayer", ErrFileRec[i][2]},
								 {"ErrLevel", ErrFileRec[i][3]}, {"ErrField", ErrFileRec[i][4]}, 
								 {"ErrVal", ErrFileRec[i][5]}, {"ErrMsg", ErrFileRec[i][6] }}
					AddRecord (CapSpdErr, errvals)
		 		end // for i	
			end
		ErrFileRec = null
		if cnterrlvl3 > 0 then goto badquit	
	
		goto quit	
		
		badquit:
		msg = msg + {"CapSpd: bad quit: Last error message= " + GetLastError()}
	
		AppendToLogFile(2, "CapSpd: badquit: Last error message= " + GetLastError())
	
		RunMacro("TCB Closing", 0, "TRUE" ) 
		CapSpdOK = 0
		goto quit
	
	
	//	Badload:
	//	msg = GetLastError()
	//	showmessage("badload: + " + msg)
	
	
		userquit:
		CapSpdOK = 0
		msg = msg + {"CapSpd - User quit"}
		goto quit
		
		quit:
	
		// Write report to Log file
		datentime = GetDateandTime()
		AppendToLogFile(1, "Exit CapSpd: " + datentime)
		AppendToLogFile(2, "     FATAL errors   = " + i2s(cnterrlvl3))
		AppendToLogFile(2, "     Severe errors 	= " + i2s(cnterrlvl2))
		AppendToLogFile(2, "     Warnings       = " + i2s(cnterrlvl1))
	
		on error default
		if GetMap() <> null then CloseMap()
	
		CloseView(CapSpdFactor)
		CloseView(HwyView)
		CloseView(NodeView)
		vws = GetViewNames()
/*		if vws <> null then do
			for i = 1 to vws.length do
				CloseView(vws[i])
			end	
		end
*/
	DestroyProgressBar()
	//end // timeperiod loop (tp)
	
	CloseView(CapSpdErr)
	return({CapSpdOK, msg})


EndMacro


Macro "FindRow" (arrayin, rowid)

	// macro returns row number of lookup array 
	for i = 1 to arrayin.length do
		if arrayin[i][1] = rowid 
			then return(i)
	end
	return(0)

endmacro


Macro "CapSpd_ReadLookup" (CapSpdLookUpFile)

	shared 	nwarns, LaneCap1hr, ATypeFac, TTPkEstFac, HwyDelay1ln, HwyDelay3ln, 
			TimeOfDayCapacityHours, Cap_FacType, Cap_Control, IntX_Control, 
			IntX_Prohibit, IntX_TurnLanes, IntX_CycleLength, IntX_GreenPct, ParkingFac,
			LocTranFreeSpeed, XprTranFreeSpeed, LocTranPeakSpeed, XprTranPeakSpeed

	
	//	CapSpd Factors lookup sections.  
	//	 1	NodeFileWarnings 
	//	 2 	LaneCap1Hr 
	//	 3	ATypeFactor 
	//	 4	TTPkEstFactor
	//	 5	HwyDelay1ln
	//	 6	HwyDelay3ln
	//	 7	TimeOfDay
	//	 8	Cap_FacType
	//	 9	Cap_Control
	//	10	IntX_Control
	//	11	IntX_Prohibit
	//	12	IntX_TurnLanes
	//	13	IntX_CycleLength
	//	14	IntX_GreenPct
	//	15	IntX_Progression (NOT USED)
	//	16	ParkingFac
	//	17	LocTranFreeSpeed
	//	18	XprTranFreeSpeed
	//	19	LocTranPeakSpeed
	//	20	XprTranPeakSpeed

	// returns code and messages 
	rtncode = 0
	msg = null
	
	// Variables for status of lookup tables
	NodeFileWarningsTab = 0
	LaneCap1HrTab = 0
	ATypeFactorTab = 0
	TTPkEstFactorTab = 0
	HwyDelay1lnTab = 0
	HwyDelay3lnTab = 0
	TimeOfDayTab = 0
	Cap_FacTypeTab = 0
	Cap_ControlTab = 0
	IntX_ControlTab = 0
	IntX_ProhibitTab = 0
	IntX_TurnLanesTab = 0
	IntX_CycleLengthTab = 0
	IntX_GreenPctTab = 0
	ParkingFacTab = 0
	LocTranFreeSpeedTab = 0
	XprTranFreeSpeedTab = 0
	LocTranPeakSpeedTab = 0
	XprTranPeakSpeedTab = 0
	
		
	LookupView = OpenTable("LookupView", "CSV", {CapSpdLookUpFile,})
	
	ptr = GetFirstRecord(LookupView + "|",)
	while ptr <> null do
		tabletype = LookupView.FIELD_1
		if upper(tabletype) = "NODEFUNCLWARNINGS" then goto ProcessNodeFunclWarnings
		else if  upper(tabletype) = "LANECAP1HR" then goto ProcessLaneCap1Hr
		else if  upper(tabletype) = "ATYPEFACTOR" then goto ProcessATypeFactor
		else if  upper(tabletype) = "TTPKESTFACTOR" then goto ProcessTTPKEstFactor
		else if  upper(tabletype) = "HWYDELAY1LN" then goto ProcessHwyDelay1ln
		else if  upper(tabletype) = "HWYDELAY3LN" then goto ProcessHwyDelay3ln
		else if  upper(tabletype) = "TIMEOFDAY" then goto ProcessTimeOfDay
		else if  upper(tabletype) = "CAP_FACTYPE" then goto ProcessCap_FacType
		else if  upper(tabletype) = "CAP_CONTROL" then goto ProcessCap_Control
		else if  upper(tabletype) = "INTX_CONTROL" then goto ProcessIntX_Control
		else if  upper(tabletype) = "INTX_PROHIBIT" then goto ProcessIntX_Prohibit
		else if  upper(tabletype) = "INTX_TURNLANES" then goto ProcessIntX_TurnLanes
		else if  upper(tabletype) = "INTX_CYCLELENGTH" then goto ProcessIntX_CycleLength
		else if  upper(tabletype) = "INTX_GREENPCT" then goto ProcessIntX_GreenPct
		else if  upper(tabletype) = "INTX_PROGRESSION" then goto ProcessIntX_Progression
		else if  upper(tabletype) = "PARKINGFAC" then goto ProcessParkingFac
		else if  upper(tabletype) = "LOCTRANFREESPEED" then goto ProcessLocTranFreeSpeed
		else if  upper(tabletype) = "XPRTRANFREESPEED" then goto ProcessXprTranFreeSpeed
		else if  upper(tabletype) = "LOCTRANPEAKSPEED" then goto ProcessLocTranPeakSpeed
		else if  upper(tabletype) = "XPRTRANPEAKSPEED" then goto ProcessXprTranPeakSpeed
		else do
			msg = msg + {"bad tabletype: " + tabletype}
			rtncode = 1
			goto donelookup
		end

		ProcessNodeFunclWarnings:
		// Warnings for potentially wrong combo of functional classes at same node
		// header record
		if LookupView.FIELD_2 = "funcl1" then do
			NodeFileWarningsTab = 1
			nfw = 0
		end
		else do
			NodeFileWarningsTab = 2
			nfw = nfw + 1
			nwarns = nwarns + {{s2i(LookupView.FIELD_2), s2i(LookupView.FIELD_3), LookupView.FIELD_4}}		
		end
		goto getnextrec

		ProcessLaneCap1Hr:
		// Lane Capacity by area type
		// MAX LCap set by funcl (2200 for freeways, 2000 for surface streets)
		// header record
		if LookupView.FIELD_2 = "LCAP_Funcl" then do
			LaneCap1HrTab = 1
			f = 0
		end
		else do
			LaneCap1HrTab = 2
			f = f + 1
			LaneCap1hr[f][1] = s2i(LookupView.FIELD_2)
			LaneCap1hr[f][2] = s2i(LookupView.FIELD_4)  // skip fname (field_3)
			LaneCap1hr[f][3] = s2i(LookupView.FIELD_5)
			LaneCap1hr[f][4] = s2i(LookupView.FIELD_6)
			LaneCap1hr[f][5] = s2i(LookupView.FIELD_7)
			LaneCap1hr[f][6] = s2i(LookupView.FIELD_8)
			LaneCap1hr[f][7] = s2i(LookupView.FIELD_9)
		end
		goto getnextrec

		ProcessATypeFactor:
		// Speed limit factor - factor speed limit either up or down by funcl x areatype (formerly Speederfac)
		// MinSpeed - mph minimum
		// header record
		if LookupView.FIELD_2 = "AType_Funcl" then do
			ATypeFactorTab = 1
			f = 0
		end
		else do
			ATypeFactorTab = 2
			f = f + 1
			ATypeFac[f][1] = s2i(LookupView.FIELD_2)
			ATypeFac[f][7] = s2r(LookupView.FIELD_4)  // MinSpeed - (last field in second dimension of array)
			ATypeFac[f][2] = s2r(LookupView.FIELD_5)  // skip fname (field_3)
			ATypeFac[f][3] = s2r(LookupView.FIELD_6)
			ATypeFac[f][4] = s2r(LookupView.FIELD_7)
			ATypeFac[f][5] = s2r(LookupView.FIELD_8)
			ATypeFac[f][6] = s2r(LookupView.FIELD_9)
		end
		goto getnextrec

		ProcessTTPKEstFactor:
		// Estimated peak travel time factor - based on prev runs - used for first round of peak hwy skims
		// header record
		if LookupView.FIELD_2 = "TTEst_Funcl" then do
			TTPkEstFactorTab = 1
			f = 0
		end
		else do
			TTPkEstFactorTab = 2
			f = f + 1
			TTPkEstFac[f][1] = s2i(LookupView.FIELD_2)
			TTPkEstFac[f][2] = s2r(LookupView.FIELD_4)  // skip fname (field_3)
			TTPkEstFac[f][3] = s2r(LookupView.FIELD_5)
			TTPkEstFac[f][4] = s2r(LookupView.FIELD_6)
			TTPkEstFac[f][5] = s2r(LookupView.FIELD_7)
			TTPkEstFac[f][6] = s2r(LookupView.FIELD_8)
		end
		goto getnextrec

		ProcessHwyDelay1ln:
		// Hwy Delay Coefficients, Alpha & Beta : funcl x area type x 1 ln [1] or multi ln(2],
		if LookupView.FIELD_2 = "Del1_Funcl" then do
			HwyDelay1lnTab = 1
			f = 0
		end
		else do
			HwyDelay1lnTab = 2
			f = f + 1
			HwyDelay1ln[f][1] = s2i(LookupView.FIELD_2)
			HwyDelay1ln[f][2] = s2r(LookupView.FIELD_4)  // skip fname (field_3)
			HwyDelay1ln[f][3] = s2r(LookupView.FIELD_5)
			HwyDelay1ln[f][4] = s2r(LookupView.FIELD_6)
			HwyDelay1ln[f][5] = s2r(LookupView.FIELD_7)
			HwyDelay1ln[f][6] = s2r(LookupView.FIELD_8)
			HwyDelay1ln[f][7] = s2r(LookupView.FIELD_9)  
			HwyDelay1ln[f][8] = s2r(LookupView.FIELD_10)
			HwyDelay1ln[f][9] = s2r(LookupView.FIELD_11)
			HwyDelay1ln[f][10] = s2r(LookupView.FIELD_12)
			HwyDelay1ln[f][11] = s2r(LookupView.FIELD_13)
		end
		goto getnextrec

		ProcessHwyDelay3ln:
		// Hwy Delay Coefficients, Alpha & Beta : funcl x area type x 1 ln [1] or multi ln(2],
		if LookupView.FIELD_2 = "Del3_Funcl" then do
			HwyDelay3lnTab = 1
			f = 0
		end
		else do
			HwyDelay33lnTab = 2
			f = f + 1
			HwyDelay3ln[f][1] = s2i(LookupView.FIELD_2)
			HwyDelay3ln[f][2] = s2r(LookupView.FIELD_4)  // skip fname (field_3)
			HwyDelay3ln[f][3] = s2r(LookupView.FIELD_5)
			HwyDelay3ln[f][4] = s2r(LookupView.FIELD_6)
			HwyDelay3ln[f][5] = s2r(LookupView.FIELD_7)
			HwyDelay3ln[f][6] = s2r(LookupView.FIELD_8)
			HwyDelay3ln[f][7] = s2r(LookupView.FIELD_9)  
			HwyDelay3ln[f][8] = s2r(LookupView.FIELD_10)
			HwyDelay3ln[f][9] = s2r(LookupView.FIELD_11)
			HwyDelay3ln[f][10] = s2r(LookupView.FIELD_12)
			HwyDelay3ln[f][11] = s2r(LookupView.FIELD_13)
		end
		goto getnextrec

		ProcessTimeOfDay:
		// Time of day factors - factor 1 hour capacity for TOD periods - set as variables
		// header record
		if LookupView.FIELD_2 = "TOD_var" then do
			TimeOfDayTab = 1
			f = 0
		end
		else do
			TimeOfDayTab = 2
			f = f + 1
			TimeOfDayCapacityHours[f][1] = LookupView.FIELD_2
			TimeOfDayCapacityHours[f][2] = s2r(LookupView.FIELD_3) 
		end
		goto getnextrec

		ProcessCap_FacType:
		//  Facility type factor - col 1 = factype, 2-4 = lanes 1,2 or 3+	
		// header record
		if LookupView.FIELD_2 = "Cap_FT_Val" then do
			Cap_FacTypeTab = 1
			f = 0
		end
		else do
			Cap_FacTypeTab = 2
			f = f + 1
			Cap_FacType[f][1] = LookupView.FIELD_2
			Cap_FacType[f][2] = s2r(LookupView.FIELD_3) 
			Cap_FacType[f][3] = s2r(LookupView.FIELD_4) 
			Cap_FacType[f][4] = s2r(LookupView.FIELD_5) 
		end
		goto getnextrec

		ProcessCap_Control:
		// Intersection control CAPACITY factor 
		if LookupView.FIELD_2 = "Cap_Ctl_Val" then do
			Cap_ControlTab = 1
			f = 0
		end
		else do
			Cap_ControlTab = 2
			f = f + 1
			Cap_Control[f][1] = LookupView.FIELD_2
			Cap_Control[f][2] = s2r(LookupView.FIELD_3) 
		end
		goto getnextrec

		ProcessIntX_Control:
		// Intersection delay in seconds (non-signalized intersections)
		if LookupView.FIELD_2 = "IntX_Ctl_Val" then do
			IntX_ControlTab = 1
			f = 0
		end
		else do
			IntX_ControlTab = 2
			f = f + 1
			IntX_Control[f][1] = LookupView.FIELD_2
			IntX_Control[f][2] = s2i(LookupView.FIELD_3) 
		end
		goto getnextrec

		ProcessIntX_Prohibit:
		// Intersection prohibitions factor - applied to intersection delay
		if LookupView.FIELD_2 = "IntX_Proh_Val" then do
			IntX_ProhibitTab = 1
			f = 0
		end
		else do
			IntX_ProhibitTab = 2
			f = f + 1
			IntX_Prohibit[f][1] = LookupView.FIELD_2
			IntX_Prohibit[f][2] = s2r(LookupView.FIELD_3) 
		end
		goto getnextrec

		ProcessIntX_TurnLanes:
		// Intersection turn lanes - set delay factors as variables for if then else statements
		if LookupView.FIELD_2 = "IntX_NoTLanes" then do
			IntX_TurnLanesTab = 1
			f = 0
		end
		else do
			IntX_TurnLanesTab = 2
			f = f + 1
			IntX_TurnLanes[f][1] = LookupView.FIELD_2
			IntX_TurnLanes[f][2] = s2r(LookupView.FIELD_3) 
			IntX_TurnLanes[f][3] = s2r(LookupView.FIELD_4) 
		end
		goto getnextrec

		ProcessIntX_CycleLength:
		// Signalized intersections - estimated cycle length and green percentage - green pct based on opposing funcl
		if LookupView.FIELD_2 = "CycLen_Funcl" then do
			IntX_CycleLengthTab = 1
			f = 0
		end
		else do
			IntX_CycleLengthTab = 2
			f = f + 1
			IntX_CycleLength[f][1] = s2i(LookupView.FIELD_2)
			IntX_CycleLength[f][2] = s2i(LookupView.FIELD_4)  // skip fname (field_3)
			IntX_CycleLength[f][3] = s2i(LookupView.FIELD_5)
			IntX_CycleLength[f][4] = s2i(LookupView.FIELD_6)
			IntX_CycleLength[f][5] = s2i(LookupView.FIELD_7)
			IntX_CycleLength[f][6] = s2i(LookupView.FIELD_8)
		end
		goto getnextrec

		ProcessIntX_GreenPct:
		// Signalized intersections - estimated cycle length and green percentage - green pct based on opposing funcl
		if LookupView.FIELD_2 = "GP_Funcl" then do
			IntX_GreenPctTab = 1
			f = 0
		end
		else do
			IntX_GreenPctTab = 2
			f = f + 1
			IntX_GreenPct[f][1] = s2i(LookupView.FIELD_2)
			IntX_GreenPct[f][2] = s2r(LookupView.FIELD_4)  // skip fname (field_3)
			IntX_GreenPct[f][3] = s2r(LookupView.FIELD_5)
			IntX_GreenPct[f][4] = s2r(LookupView.FIELD_6)
			IntX_GreenPct[f][5] = s2r(LookupView.FIELD_7)
			IntX_GreenPct[f][6] = s2r(LookupView.FIELD_8)
			IntX_GreenPct[f][7] = s2r(LookupView.FIELD_9)
			IntX_GreenPct[f][8] = s2r(LookupView.FIELD_10)
			IntX_GreenPct[f][9] = s2r(LookupView.FIELD_11)
			IntX_GreenPct[f][10] = s2r(LookupView.FIELD_12)
			IntX_GreenPct[f][11] = s2r(LookupView.FIELD_13)
			IntX_GreenPct[f][12] = s2r(LookupView.FIELD_14)
			IntX_GreenPct[f][13] = s2r(LookupView.FIELD_15)
			IntX_GreenPct[f][14] = s2r(LookupView.FIELD_16)
			IntX_GreenPct[f][15] = s2r(LookupView.FIELD_17)
			IntX_GreenPct[f][16] = s2r(LookupView.FIELD_18)
			IntX_GreenPct[f][17] = s2r(LookupView.FIELD_19)
			IntX_GreenPct[f][18] = s2r(LookupView.FIELD_20)
			IntX_GreenPct[f][19] = s2r(LookupView.FIELD_21)
			IntX_GreenPct[f][20] = s2r(LookupView.FIELD_22)
			IntX_GreenPct[f][21] = s2r(LookupView.FIELD_23)
			IntX_GreenPct[f][22] = s2r(LookupView.FIELD_24)
		end
		goto getnextrec

		ProcessIntX_Progression:
		goto getnextrec

		ProcessParkingFac:
		//  Parking	- [1] parking code, [2] TT factor [3] Cap Factor]
		// header record
		if LookupView.FIELD_2 = "Park_Val" then do
			ParkingFacTab = 1
			f = 0
		end
		else do
			ParkingFacTab = 2
			f = f + 1
			ParkingFac[f][1] = LookupView.FIELD_2
			ParkingFac[f][2] = s2r(LookupView.FIELD_3) 
			ParkingFac[f][3] = s2r(LookupView.FIELD_4) 
		end
		goto getnextrec


		ProcessLocTranFreeSpeed:
		// Transit default speeds (MPH) - not to exceed 90% of vehicle speed 
		// Local bus - free speed
		if LookupView.FIELD_2 = "LocFr_Funcl" then do
			LocTranFreeSpeedTab = 1
			f = 0
		end
		else do
			LocTranFreeSpeedTab = 2
			f = f + 1
			LocTranFreeSpeed[f][1] = s2i(LookupView.FIELD_2)
			LocTranFreeSpeed[f][2] = s2r(LookupView.FIELD_4)  // skip fname (field_3)
			LocTranFreeSpeed[f][3] = s2r(LookupView.FIELD_5)
			LocTranFreeSpeed[f][4] = s2r(LookupView.FIELD_6)
			LocTranFreeSpeed[f][5] = s2r(LookupView.FIELD_7)
			LocTranFreeSpeed[f][6] = s2r(LookupView.FIELD_8)
		end
		goto getnextrec

		ProcessXprTranFreeSpeed:
		// Transit default speeds (MPH) - not to exceed 90% of vehicle speed 
		// Express bus - free speed
		if LookupView.FIELD_2 = "XprFr_Funcl" then do
			XprTranFreeSpeedTab = 1
			f = 0
		end
		else do
			XprTranFreeSpeedTab = 2
			f = f + 1
			XprTranFreeSpeed[f][1] = s2i(LookupView.FIELD_2)
			XprTranFreeSpeed[f][2] = s2r(LookupView.FIELD_4)  // skip fname (field_3)
			XprTranFreeSpeed[f][3] = s2r(LookupView.FIELD_5)
			XprTranFreeSpeed[f][4] = s2r(LookupView.FIELD_6)
			XprTranFreeSpeed[f][5] = s2r(LookupView.FIELD_7)
			XprTranFreeSpeed[f][6] = s2r(LookupView.FIELD_8)
		end
		goto getnextrec

		ProcessLocTranPeakSpeed:
		// Transit default speeds (MPH) - not to exceed 90% of vehicle speed 
		// Local bus - peak speed
		if LookupView.FIELD_2 = "LocPk_Funcl" then do
			LocTranPeakSpeedTab = 1
			f = 0
		end
		else do
			LocTranPeakSpeedTab = 2
			f = f + 1
			LocTranPeakSpeed[f][1] = s2i(LookupView.FIELD_2)
			LocTranPeakSpeed[f][2] = s2r(LookupView.FIELD_4)  // skip fname (field_3)
			LocTranPeakSpeed[f][3] = s2r(LookupView.FIELD_5)
			LocTranPeakSpeed[f][4] = s2r(LookupView.FIELD_6)
			LocTranPeakSpeed[f][5] = s2r(LookupView.FIELD_7)
			LocTranPeakSpeed[f][6] = s2r(LookupView.FIELD_8)
		end
		goto getnextrec

		ProcessXprTranPeakSpeed:
		// Transit default speeds (MPH) - not to exceed 90% of vehicle speed 
		// Express bus - peak speed
		if LookupView.FIELD_2 = "XprPk_Funcl" then do
			XprTranPeakSpeedTab = 1
			f = 0
		end
		else do
			XprTranPeakSpeedTab = 2
			f = f + 1
			XprTranPeakSpeed[f][1] = s2i(LookupView.FIELD_2)
			XprTranPeakSpeed[f][2] = s2r(LookupView.FIELD_4)  // skip fname (field_3)
			XprTranPeakSpeed[f][3] = s2r(LookupView.FIELD_5)
			XprTranPeakSpeed[f][4] = s2r(LookupView.FIELD_6)
			XprTranPeakSpeed[f][5] = s2r(LookupView.FIELD_7)
			XprTranPeakSpeed[f][6] = s2r(LookupView.FIELD_8)
		end
		goto getnextrec


		getnextrec:
		ptr = GetNextRecord(LookupView + "|",,)
	end
	
	donelookup:
	CloseView(LookupView)
	return({0, msg})

endmacro
