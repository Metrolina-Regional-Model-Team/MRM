Macro "MS_HBWPeak" (Args)

// Macro to call HBW_Peak Modechoice ONLY - Not a part of standard conformity run (Conformity run uses MS_RunPeak)

	// LogFile = Args.[Log File].value
	// SetLogFileName(LogFile)
	// ReportFile = Args.[Report File].value
	// SetReportFileName(ReportFile)

	Dir = Args.[Run Directory]
	theyear = Args.[Run Year]
	
	msg = null
	MSPeakOK = 1

	datentime = GetDateandTime()
	AppendToLogFile(1, "Enter MS_HBWPeak, HBW Peak ONLY: " + datentime)

// run batch file

	runprogram(Dir + "\\modesplit\\" + theyear + "_HBW_PEAK.BAT",)

// post process matrices

	M  = OpenMatrix(Dir + "\\modesplit\\HBW_PEAK_MS.mtx", "True")
	RenameMatrix(M,  "HBW_PEAK_MS")
			
	idx  = Getmatrixindex(M)
	idxnew = {"Rows", "Columns"}
			
	for index = 1 to idx.length do
		if idx[index] <> idxnew[index] then do
			SetMatrixIndexName(M, idx[index], idxnew[index])
		end
	end
	
	//check competion
	rtn = RunMacro("GetFieldCore", Dir + "\\ModeSplit\\HBW_PEAK_MS.mtx", "Drive Alone")
	if rtn[1] = 0
		then do 
			AppendToLogFile(2, "ERROR - Drive Alone matrix empty - HBW_PEAK_MS.mtx")
			MSPeakOK = 0
		end

	datentime = GetDateandTime()
	AppendToLogFile(1, "Exit MS_HBWPeak: " + datentime)
	return({MSPeakOK, msg})
	
EndMacro