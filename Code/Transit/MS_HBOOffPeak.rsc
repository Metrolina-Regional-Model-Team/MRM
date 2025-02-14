Macro "MS_HBOOffPeak" (Args)

// Macro to call HBO_OffPeak Modechoice ONLY - Not a part of standard conformity run (Conformity run uses MS_OffRunPeak)

	// LogFile = Args.[Log File].value
	// SetLogFileName(LogFile)
	// ReportFile = Args.[Report File].value
	// SetReportFileName(ReportFile)

	Dir = Args.[Run Directory]
	theyear = Args.[Run Year]
	
	msg = null
	MSOffPeakOK = 1

	datentime = GetDateandTime()
	AppendToLogFile(1, "Enter MS_HBOOffPeak, HBO OffPeak ONLY: " + datentime)

// run batch file

	runprogram(Dir + "\\modesplit\\" + theyear + "_HBO_OFFPEAK.BAT",)

// post process matrices

	M  = OpenMatrix(Dir + "\\modesplit\\HBO_OFFPEAK_MS.mtx", "True")
	RenameMatrix(M,  "HBO_OFFPEAK_MS")
			
	idx  = Getmatrixindex(M)
	idxnew = {"Rows", "Columns"}
			
	for index = 1 to idx.length do
		if idx[index] <> idxnew[index] then do
			SetMatrixIndexName(M, idx[index], idxnew[index])
		end
	end

	//check competion
	rtn = RunMacro("GetFieldCore", Dir + "\\ModeSplit\\HBO_OFFPEAK_MS.mtx", "Drive Alone")
	if rtn[1] = 0
		then do 
			AppendToLogFile(2, "ERROR - Drive Alone matrix empty - HBO_OFFPEAK_MS.mtx")
			MSOffPeakOK = 0
		end

	datentime = GetDateandTime()
	AppendToLogFile(1, "Exit MS_HBOOffPeak: " + datentime)
	return({MSOffPeakOK, msg})
	
EndMacro