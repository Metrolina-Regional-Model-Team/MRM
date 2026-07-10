Macro "Build_Networks" (Args)

	MRMDir = Args.[MRM Directory]
	Dir = Args.[Run Directory]
	RunYear = Args.[Run Year]
	TAZFile = Args.[TAZ File]
	HwyName = Args.[Hwy Name]
	MasterHwyFile = Args.MasterHwyFile
	ProjectFile = Args.ProjectFile
	TollFile = Args.TollFile

	//ShowMessage("Run Directory = " + Dir) //added for testing
	//ShowMessage("MasterHwyFile = " + MasterHwyFile) //added for testing
	MasterInfo = GetFileInfo(MasterHwyFile)
	/*if !MasterInfo then
    Throw("GetFileInfo returned null")*/
	MasterTimeStamp = MasterInfo[7] + " " + MasterInfo[8]
	ProjInfo = GetFileInfo(ProjectFile)
	ProjTimeStamp = ProjInfo[7] + " " + ProjInfo[8]
	TollInfo = GetFileInfo(TollFile)
	TollTimeStamp = TollInfo[7] + " " + TollInfo[8]

	AppendToReportFile(1, "Build Highway Networks")
	AppendToReportFile(2, "Master Highway File:   " + MasterHwyFile + "  TimeStamp: " + MasterTimeStamp)
	AppendToReportFile(2, "Project File:                " + ProjectFile + "  TimeStamp: " + ProjTimeStamp)
	AppendToReportFile(2, "Toll File:                     " + TollFile + "  TimeStamp: " + TollTimeStamp)

	//	Read project file - create prj_year array - used by both highway and transit
	datentime = GetDateandTime()
	AppendtoLogFile(2, " ")
	AppendToLogFile(2, "Enter Fill_prj_year: " + datentime)

	prj_year = RunMacro("Fill_prj_year", ProjectFile)

	if prj_year = null then goto badprjyear
	datentime = GetDateandTime()
	AppendToLogFile(2, "Exit Fill_prj_year: " + datentime)
	NumProj = prj_year.length
	AppendToReportFile(2, "Number of projects for " + RunYear + ":   " + i2s(NumProj))

	datentime = GetDateandTime()
	AppendtoLogFile(2, " ")
	AppendToLogFile(2, "Enter Build_HwyNet: " + datentime)

	HwyName = RunMacro("Build_HwyNet", MRMDir, Dir, RunYear, MasterHwyFile, prj_year, TollFile, HwyName)			
	datentime = GetDateandTime()
	AppendToLogFile(2, "Exit Build_HwyNet: " + datentime)

	//Args.[Hwy Name].value = HwyName

	datentime = GetDateandTime()
	AppendToLogFile(1, "Exit Build_Networks: " + datentime)

	if HwyName = null 
			then do
				msg = msg + {"Error return from Build_HwyNet"}
				AppendToLogFile(1, "Error return from Build_HwyNet")
				HwyOK = 0
				goto didnotwork
			end
			else goto didwork
			
		badprjyear:
		HwyOK = 0
		msg = msg + {"Build_Networks: Error - prj_year array not created"}
		AppendToLogFile(1, "Build_Networks: Error: - prj_year array not created")
		goto didnotwork

	NoRun:
	didnotwork:
	if HwyOK = 0
		then do	
			ShowItem(" Error/Warning messages ")
			ShowItem("netmessageslist")
		end	
	goto quit
	
	didwork:
		datentime = GetDateandTime()
		AppendToLogFile(1, "Exit Build_Networks: " + datentime)

	return({1, msg})
	quit:
EndMacro

