Macro "Terminal_Intrazonal_TT" (Args, TermTimeFile, SPMATFile, SPMATCoreName, PeakFree)

	//Highway trip terminal time - and Intrazonal time
	//	Terminal time -  minutes added at BOTH ends of trip based on Area Type of Origin and Destination TAZ.
	//		MinDelay array - minutes by AType
	//	Intrazonal time - average of three shortest IntERzonal times / 2 + 1 terminal time
	// Called by Highway Skim_peak & _free
	// Before 2017, this was calculated in Fortran job Intraterm.
	//12/28/18, mk: edited script to use vector sorting and to get rid of multiple loops

	// Minutes of delay - array 1-5 Index is area type.  MinDelay{Minutes of delay}
	MinDelay = {5.0, 4.0, 3.0, 2.0, 1.0}

	// Args
	// LogFile = Args.[Log File].value
	// SetLogFileName(LogFile)
	Dir = Args.[Run Directory]

	TermIntraOK = 1
	msg = null

	datentime = GetDateandTime()
	AppendToLogFile(1, "Enter Terminal_Intrazonal_TT: " + datentime)

	CreateProgressBar("Terminal Time and Intrazonal Time", "False")
	stat = UpdateProgressBar("Terminal Time and Intrazonal Time",1)

	// Open SPMAT
	// on error, notfound goto badspmat
	SPMATMtx = OpenMatrix(SPMATFile, "True")
	SPMATNdx = GetMatrixIndex(SPMATMtx)
	SPMATCore = CreateMatrixCurrency(SPMATMtx, SPMATCoreName, SPMATNdx[1], SPMATNdx[2],)

	Row_labels = GetMatrixIndexIDs(SPMATMtx, SPMATNdx[1])
	NumTAZ = Row_labels.length

	// Area type file (written by Area_Type macro)
	// on error, notfound goto badatype
	ATFile = Dir + "\\TAZ_ATYPE.bin"
	ATView = OpenTable("ATView", "FFB", {ATFile, })

	// open new matrix - get core labels (xref to ATYPE and SPMAT
	// on error, notfound goto badTTIntraFile
	TermTimeMtx = OpenMatrix(TermTimeFile, "True")
	TermTimeCore = CreateMatrixCurrency(TermTimeMtx, PeakFree, "Rows", "Columns",)
	TermTimeNdx = GetMatrixIndex(TermTimeMtx)
	Row_labels2 = GetMatrixIndexIDs(TermTimeMtx, TermTimeNdx[1])
	
	// on error, notfound default

	// Area type file into vectors
	//	vTAZ = GetDataVector(ATView + "|", "ZONE", {{"Sort Order", {"ZONE", "Ascending"}}, {"Match Matrix Index", {{"Row", "True"}, TermTimeMtx, TermTimeCore}}})  didn't work
	aTAZAT = GetDataVectors(ATView + "|", {"ZONE", "ATYPE"}, {{"Sort Order", {{"ZONE", "Ascending"}}}})
	ATTAZ = aTAZAT[1]
	ATYPE  = aTAZAT[2]

	// Terminal time at origin of trip (this creates a vector)
	OrigMinutes = if (ATYPE = 1) then MinDelay[1] 
		else if (ATYPE = 2) then MinDelay[2] 
		else if (ATYPE = 3) then MinDelay[3] 
		else if (ATYPE = 4) then MinDelay[4] 
		else if (ATYPE = 5) then MinDelay[5]

	//intrazonal (diagonal)
	intraterm_v = Vector(NumTAZ, "float", )

	// check TAZ match, fill TermMinutes vector
	for i = 1 to NumTAZ do

		// check TAZ matching up
		if Row_labels[i] <> Row_labels2[i] then goto badmatchTTIntra
		if Row_labels[i] <> ATTAZ[i] then goto badmatchATYPE
		
		//set destination minutes equal to origin minutes of that same zone; then total is orig + dest (also a vector)
		DestMinutes = OrigMinutes[i]
		TermMinutes = OrigMinutes + DestMinutes
		
		//set intrazonal time : ((average of shortest 3 times) / 2) + OrigMinutes
		ttime_v = GetMatrixVector(SPMATCore, {{"Row", ATTAZ[i]}})		
		sorted_tt = SortVector(ttime_v, {{"Omit Missing", "True"}})		//sort to pull the 3 shortest times			
		intraterm_v[i] = ((sorted_tt[1] + sorted_tt[2] + sorted_tt[3]) / 6) + DestMinutes  //DestMinutes = OrigMinutes[i]
		
		//go ahead and set intra term for all, and will reset diagonals (intrazonal) after loop is complete
		SetMatrixVector(TermTimeCore, TermMinutes, {{"Row", ATTAZ[i]}})
	end
	SetMatrixVector(TermTimeCore, intraterm_v, {{"Diagonal"}})
		
	CloseView(ATView)

	goto done

	badspmat:
	Throw("Terminal_Intrazonal_TT ERROR opening SPMAT")
	AppendToLogFile(1, "Terminal_Intrazonal_TT ERROR opening SPMAT")
	TermIntraOK = 0
	goto done

	badTTIntraFile:
	Throw("Terminal_Intrazonal_TT ERROR opening Terminal Time matrix")
	AppendToLogFile(1, "Terminal_Intrazonal_TT ERROR opening Terminal Time matrix")
	TermIntraOK = 0
	goto done

	badatype:
	Throw("Terminal_Intrazonal_TT ERROR opening TAZ_ATYE.asc")
	AppendToLogFile(1, "Terminal_Intrazonal_TT ERROR opening TAZ_ATYE.asc")
	TermIntraOK = 0
	goto done
	
	badmatchTTIntra:
	Throw("Terminal_Intrazonal_TT ERROR - Terminal time matrix does not match SPMAT!")
	AppendToLogFile(1, "Terminal_Intrazonal_TT ERROR  - Terminal time matrix does not match SPMAT!")
	TermIntraOK = 0
	goto done

	badmatchATYPE:
	Throw("Terminal_Intrazonal_TT ERROR - Area Type file does not match SPMAT!")
	AppendToLogFile(1, "Terminal_Intrazonal_TT ERROR  - Area Type file does not match SPMAT!")
	TermIntraOK = 0
	goto done

	done:
	SPMATFile = null
	SPMATMtx = null
	SPMATNdx = null
	SPMATCore = null
	Row_labels = null
	OutFile = null
	TermTimeMtx = null
	TermTimeCore = null
	Row_labels2 = null
	on error default
	datentime = GetDateandTime()

	DestroyProgressBar()

	AppendToLogFile(1, "Exit Terminal_Intrazonal_TT " + datentime)
	return({TermIntraOK, msg})



endmacro

