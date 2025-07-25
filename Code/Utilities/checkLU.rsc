Macro "checkLU" (LUFile, TAZFile)

	// Check TAZ in LU file against TAZID 
	
	msg = null
	checkLUOK = 1
	badLUID = null
	badIDLU = null
	
	tazpath = SplitPath(TAZFile)
	TAZIDFile = tazpath[1] + tazpath[2] + tazpath[3] + "_TAZID.bin"
	
	LU_in = OpenTable("LU_in", "FFB", {LUFile,})
	TAZID = OpenTable("TAZID", "FFB", {TAZIDFile,})

	//TAZ in LU not in TAZID
	JoinLUID = JoinViews("JoinLUID", "LU_in.TAZ", "TAZID.TAZ",)
	selsetLUID = "Select * where TAZID.TAZ = null"
	SetView(JoinLUID)
	LUIDerr = SelectByQuery("luid", "Several", selsetLUID,)
	if LUIDerr = 0 then goto checkIDLU
	
	// List of LUID bad TAZ
	checkLUOK = 0
	badLUID = "TAZ in LU file, NOT in TAZ file = "
	bad_rec = GetFirstRecord ("JoinLUID|luid", {{"LU_in.TAZ", "Ascending"}})
	while bad_rec <> null do
		mval = GetRecordValues("JoinLUID|luid", bad_rec, {"LU_in.TAZ"})
		zone = mval[1][2]
		badLUID = badLUID + zone + ", "
 		bad_rec = GetNextRecord ("JoinLUID|luid", null, {{"LU_in.TAZ", "Ascending"}})
	end   // while bad_rec
	Throw(badLUID)
	
	checkIDLU:
	CloseView(JoinLUID)
	
	//TAZ in TAZID, not in LU
	JoinIDLU = JoinViews("JoinIDLU", "TAZID.TAZ", "LU_in.TAZ",)
	selsetIDLU = "Select * where LU_in.TAZ = null and INT_EXT = 1"
	SetView(JoinIDLU)
	IDLUerr = SelectByQuery("idlu", "Several", selsetIDLU,)
	if IDLUerr = 0 then goto donecheck
	
	// List of LUID bad TAZ
	checkLUOK = 0
	badIDID = "TAZ in TAZ file, NOT in LU file = "
	bad_rec = GetFirstRecord ("JoinIDLU|idlu", {{"TAZID.TAZ", "Ascending"}})
	while bad_rec <> null do
		mval = GetRecordValues("JoinIDLU|idlu", bad_rec, {"TAZID.TAZ"})
		zone = mval[1][2]
		badIDLU = badIDLU + zone + ", "
 		bad_rec = GetNextRecord ("JoinIDLU|idlu", null, {{"TAZID.TAZ", "Ascending"}})
	end   // while bad_rec
	Throw(badIDLU)
	
	donecheck:
	CloseView(JoinIDLU)
	CloseView(LU_in)
	CloseView(TAZID)
	
	return({checkLUOK, msg})
EndMacro
