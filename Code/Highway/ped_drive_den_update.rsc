macro "ped_drive_den_update" (Args, netview)

//	Modified for 2015 User Interface  8/6/15
//  TAZ required
// 6/11/19, mk: This version is set up with three distinct networks: AM peak, PM peak, and offpeak--so loop the three networks


//for tp = 2 to 3 do
	Dir = Args.[Run Directory]
	tazfile = Args.[TAZ File]

	notaz = "Select*where TAZ = null"
	tazlayers = GetDBLayers(tazfile)
	tazlayer = addlayer(netview, tazlayers[1], tazfile, tazlayers[1])
        Setview(netview)
        SelectbyQuery("notaz","Several",notaz,)
	TagLayer("Value", netview+ "|notaz",netview+".TAZ", tazlayer, tazlayer+".TAZ")
	droplayer(netview, tazlayer)
//Opens the TAZ_AREATYPE.asc file and then fills the value of atype (area type) into the regnet's areatp (area type)
	base = Dir + "\\landuse\\TAZ_AREATYPE.bin"
	opentable("TAZ_AREATYPE", "FFB", {base,})
	JoinViews(netview+"+ TAZ_AREATYPE", netview+".TAZ", "TAZ_AREATYPE.TAZ", )
	
	hi = GetFirstRecord(netview+"+ TAZ_AREATYPE|",)
	    while hi <> null do
		mval = GetRecordValues(netview+"+ TAZ_AREATYPE", hi, {"ATYPE"})
	
		tazatype = mval[1][2]
		
		SetRecordValues(netview,null,{{netview+".areatp", tazatype}}) 
		
	 	hi = GetNextRecord(netview+"+ TAZ_AREATYPE|", null, )
	    end

	closeview(netview+"+ TAZ_AREATYPE")
	closeview("TAZ_AREATYPE")

//_______PARKING______________

	setview(netview)

	if s2i(theyear) > 2002 then do
		select1 = "Select*where parking = null and (funcl = 901 | funcl = 902 | funcl = 908 | funcl = 909 | (funcl >= 922 and funcl <= 984) | funcl = 1 | funcl = 2 | funcl = 8 | funcl = 9 | (funcl >= 22 and funcl <= 84))"
		SelectByQuery("One Two Eight and Nine", "subset", select1,)
	
		select2 = "Select*where parking = null and (funcl = 903 or funcl = 3)"
		SelectByQuery("Three", "Several", select2,)
	
		select3 = "Select*where parking = null and (funcl = 904 or funcl = 4)"
		SelectByQuery("Four", "Several", select3,)
	
		select4 = "Select*where parking = null and (funcl = 905 or funcl = 5)"
		SelectByQuery("Five", "Several", select4,)
	
		select5 = "Select*where parking = null and (funcl = 906 or funcl = 907  or funcl = 6 or funcl = 7)"
		SelectByQuery("Six and Seven", "Several", select5,)
	
		select6 = "Select*where parking = null and (funcl = 990 or funcl = 992 or funcl = 90 or funcl = 92)"
		SelectByQuery("Centroids", "Several", select6,)
	
	setview(netview)
		hi = GetFirstRecord(netview+"|One Two Eight and Nine",)
		while hi <> null do
	
		SetRecordValues(netview,null,{{"parking", "N"}})
	
		hi = GetNextRecord(netview+"|One Two Eight and Nine", null,)
		end
	
	
		hi = GetFirstRecord(netview+"|Three",)
		while hi <> null do
	
		SetRecordValues(netview,null,{{"parking", "N"}})
	
		hi = GetNextRecord(netview+"|Three", null,)
		end
	
	
		hi = GetFirstRecord(netview+"|Four",)
		while hi <> null do
	
		SetRecordValues(netview,null,{{"parking", "N"}})
	
		hi = GetNextRecord(netview+"|Four", null,)
		end
	
	
		hi = GetFirstRecord(netview+"|Five",)
		while hi <> null do
	
			mval = GetRecordValues(netview, hi,{"areatp"})
	
			areatp = mval[1][2]
	
			if areatp = 1 then do
				park = "Y"
				end
			if areatp = 2 then do
				park = "Y"
				end
			if areatp = 3 then do
				park = "N"
				end
			if areatp = 4 then do
				park = "N"
				end
			if areatp = 5 then do
				park = "N"
				end
	
		SetRecordValues(netview,null,{{"parking", park}})
	
		hi = GetNextRecord(netview+"|Five", null,)
		end
	
		hi = GetFirstRecord(netview+"|Six and Seven",)
		while hi <> null do
	
			mval = GetRecordValues(netview, hi,{"areatp"})
	
			areatp = mval[1][2]
	
			if areatp = 1 then do
				park = "Y"
				end
			if areatp = 2 then do
				park = "Y"
				end
			if areatp = 3 then do
				park = "Y"
				end
			if areatp = 4 then do
				park = "N"
				end
			if areatp = 5 then do
				park = "N"
				end
	
		SetRecordValues(netview,null,{{"parking", park}})
	
		hi = GetNextRecord(netview+"|Six and Seven", null,)
		end
	
	
		hi = GetFirstRecord(netview+"|Centroids",)
		while hi <> null do
	
			mval = GetRecordValues(netview, hi,{"areatp"})
	
		SetRecordValues(netview,null,{{"parking", "N"}})
	
		hi = GetNextRecord(netview+"|Centroids", null,)
		end
	
	deleteset("One Two Eight and Nine")
	deleteset("Three")
	deleteset("Four")
	deleteset("Five")
	deleteset("Six and Seven")
	deleteset("Centroids")
	
	//_______PARKING______________
	
		setview(netview)
	
	
		select1 = "Select*where Pedactivity = null and (funcl = 901 or funcl = 902 or funcl = 908 or funcl = 909 or funcl = 1 or funcl = 2 or funcl = 8 or funcl = 9)"
		SelectByQuery("One Two Eight and Nine", "subset", select1,)
	
		select2 = "Select*where Pedactivity = null and (funcl = 903 or funcl = 3)"
		SelectByQuery("Three", "Several", select2,)
	
		select3 = "Select*where Pedactivity = null and (funcl = 904 or funcl = 4)"
		SelectByQuery("Four", "Several", select3,)
	
		select4 = "Select*where Pedactivity = null and (funcl = 905 or funcl = 5)"
		SelectByQuery("Five", "Several", select4,)
	
		select5 = "Select*where Pedactivity = null and (funcl = 906 or funcl = 907  or funcl = 6 or funcl = 7)"
		SelectByQuery("Six and Seven", "Several", select5,)
	
		select6 = "Select*where Pedactivity = null and (funcl = 900 or funcl = 90)"
		SelectByQuery("Centroids", "Several", select6,)
	
	
		hi = GetFirstRecord(netview+"|One Two Eight and Nine",)
		while hi <> null do
	
			mval = GetRecordValues(netview, hi,)
	
		SetRecordValues(netview,null,{{"Pedactivity", "X"}})
	
		hi = GetNextRecord(netview+"|One Two Eight and Nine", null,)
		end
	
	
		hi = GetFirstRecord(netview+"|Three",)
		while hi <> null do
	
			mval = GetRecordValues(netview, hi,{"areatp"})
	
		SetRecordValues(netview,null,{{"Pedactivity", "L"}})
	
		hi = GetNextRecord(netview+"|Three", null,)
		end
	
	
		hi = GetFirstRecord(netview+"|Four",)
		while hi <> null do
	
			mval = GetRecordValues(netview, hi,{"areatp"})
	
			areatp = mval[1][2]
	
			if areatp = 1 then do
				ped = "H"
				end
			if areatp = 2 then do
				ped = "M"
				end
			if areatp = 3 then do
				ped = "M"
				end
			if areatp = 4 then do
				ped = "L"
				end
			if areatp = 5 then do
				ped = "L"
				end
	
		SetRecordValues(netview,null,{{"Pedactivity", ped}})
	
		hi = GetNextRecord(netview+"|Four", null,)
		end
	
	
		hi = GetFirstRecord(netview+"|Five",)
		while hi <> null do
	
			mval = GetRecordValues(netview, hi,{"areatp"})
	
			areatp = mval[1][2]
	
			if areatp = 1 then do
				ped = "H"
				end
			if areatp = 2 then do
				ped = "M"
				end
			if areatp = 3 then do
				ped = "M"
				end
			if areatp = 4 then do
				ped = "L"
				end
			if areatp = 5 then do
				ped = "L"
				end
	
		SetRecordValues(netview,null,{{"Pedactivity", ped}})
	
		hi = GetNextRecord(netview+"|Five", null,)
		end
	
	
		hi = GetFirstRecord(netview+"|Six and Seven",)
		while hi <> null do
	
			mval = GetRecordValues(netview, hi,{"areatp"})
	
			areatp = mval[1][2]
	
			if areatp = 1 then do
				ped = "H"
				end
			if areatp = 2 then do
				ped = "M"
				end
			if areatp = 3 then do
				ped = "M"
				end
			if areatp = 4 then do
				ped = "L"
				end
			if areatp = 5 then do
				ped = "L"
				end
	
		SetRecordValues(netview,null,{{"Pedactivity", ped}})
	
		hi = GetNextRecord(netview+"|Six and Seven", null,)
		end
	
	
	
		hi = GetFirstRecord(netview+"|Centroids",)
		while hi <> null do
	
			mval = GetRecordValues(netview, hi,{"areatp"})
	
			areatp = mval[1][2]
	
			if areatp = 1 then do
				ped = "H"
				end
			if areatp = 2 then do
				ped = "M"
				end
			if areatp = 3 then do
				ped = "L"
				end
			if areatp = 4 then do
				ped = "L"
				end
			if areatp = 5 then do
				ped = "M"
				end
	
		SetRecordValues(netview,null,{{"Pedactivity", ped}})
	
		hi = GetNextRecord(netview+"|Centroids", null,)
		end
	
	deleteset("One Two Eight and Nine")
	deleteset("Three")
	deleteset("Four")
	deleteset("Five")
	deleteset("Six and Seven")
	deleteset("Centroids")
	
	//_______DEVELOPMENT_DENSITY______________
	
		setview(netview)
	
	
		select1 = "Select*where Developden = null and (funcl = 901 or funcl = 902 or funcl = 908 or funcl = 909 or funcl = 1 or funcl = 2 or funcl = 8 or funcl = 9)"
		SelectByQuery("One Two Eight and Nine", "subset", select1,)
	
		select2 = "Select*where Developden = null and (funcl = 903 or funcl = 3)"
		SelectByQuery("Three", "Several", select2,)
	
		select3 = "Select*where Developden = null and (funcl = 904 or funcl = 4)"
		SelectByQuery("Four", "Several", select3,)
	
		select4 = "Select*where Developden = null and (funcl = 905 or funcl = 5)"
		SelectByQuery("Five", "Several", select4,)
	
		select5 = "Select*where Developden = null and (funcl = 906 or funcl = 907  or funcl = 6 or funcl = 7)"
		SelectByQuery("Six and Seven", "Several", select5,)
	
		select6 = "Select*where Developden = null and (funcl = 900 or funcl = 90)"
		SelectByQuery("Centroids", "Several", select6,)
	
	
		hi = GetFirstRecord(netview+"|One Two Eight and Nine",)
		while hi <> null do
	
			mval = GetRecordValues(netview, hi,)
	
		SetRecordValues(netview,null,{{"Developden", "X"}})
	
		hi = GetNextRecord(netview+"|One Two Eight and Nine", null,)
		end
	
	
		hi = GetFirstRecord(netview+"|Three",)
		while hi <> null do
	
			mval = GetRecordValues(netview, hi,{"areatp"})
	
			areatp = mval[1][2]
	
			if areatp = 5 then do
				develop = "L"
				end
			else do
				develop = "H"
				end
	
		SetRecordValues(netview,null,{{"Developden", develop}})
	
		hi = GetNextRecord(netview+"|Three", null,)
		end
	
	
		hi = GetFirstRecord(netview+"|Four",)
		while hi <> null do
	
			mval = GetRecordValues(netview, hi,{"areatp"})
	
			areatp = mval[1][2]
	
			if areatp = 1 then do
				develop = "H"
				end
			if areatp = 2 then do
				develop = "H"
				end
			if areatp = 3 then do
				develop = "H"
				end
			if areatp = 4 then do
				develop = "H"
				end
			if areatp = 5 then do
				develop = "L"
				end
	
		SetRecordValues(netview,null,{{"Developden", develop}})
	
		hi = GetNextRecord(netview+"|Four", null,)
		end
	
	
		hi = GetFirstRecord(netview+"|Five",)
		while hi <> null do
	
			mval = GetRecordValues(netview, hi,{"areatp"})
	
			areatp = mval[1][2]
	
			if areatp = 1 then do
				develop = "H"
				end
			if areatp = 2 then do
				develop = "H"
				end
			if areatp = 3 then do
				develop = "M"
				end
			if areatp = 4 then do
				develop = "M"
				end
			if areatp = 5 then do
				develop = "L"
				end
	
		SetRecordValues(netview,null,{{"Developden", develop}})
	
		hi = GetNextRecord(netview+"|Five", null,)
		end
	
	
		hi = GetFirstRecord(netview+"|Six and Seven",)
		while hi <> null do
	
			mval = GetRecordValues(netview, hi,{"areatp"})
	
			areatp = mval[1][2]
	
			if areatp = 1 then do
				develop = "H"
				end
			if areatp = 2 then do
				develop = "M"
				end
			if areatp = 3 then do
				develop = "M"
				end
			if areatp = 4 then do
				develop = "L"
				end
			if areatp = 5 then do
				develop = "L"
				end
	
		SetRecordValues(netview,null,{{"Developden", develop}})
	
		hi = GetNextRecord(netview+"|Six and Seven", null,)
		end
	
	
	
		hi = GetFirstRecord(netview+"|Centroids",)
		while hi <> null do
	
			mval = GetRecordValues(netview, hi,{"areatp"})
	
			areatp = mval[1][2]
	
			if areatp = 1 then do
				develop = "H"
				end
			if areatp = 2 then do
				develop = "M"
				end
			if areatp = 3 then do
				develop = "L"
				end
			if areatp = 4 then do
				develop = "L"
				end
			if areatp = 5 then do
				develop = "M"
				end
		SetRecordValues(netview,null,{{"Developden", develop}})
	
		hi = GetNextRecord(netview+"|Centroids", null,)
		end
	
	deleteset("One Two Eight and Nine")
	deleteset("Three")
	deleteset("Four")
	deleteset("Five")
	deleteset("Six and Seven")
	deleteset("Centroids")
	
	//_______DRIVEWAY_DENSITY______________
	
		setview(netview)
	
	
		select1 = "Select*where Drivewayden = null and (funcl = 901 or funcl = 902 or funcl = 908 or funcl = 909 or funcl = 1 or funcl = 2 or funcl = 8 or funcl = 9)"
		SelectByQuery("One Two Eight and Nine", "subset", select1,)
	
		select2 = "Select*where Drivewayden = null and (funcl = 903 or funcl = 3)"
		SelectByQuery("Three", "Several", select2,)
	
		select3 = "Select*where Drivewayden = null and (funcl = 904 or funcl = 4)"
		SelectByQuery("Four", "Several", select3,)
	
		select4 = "Select*where Drivewayden = null and (funcl = 905 or funcl = 5)"
		SelectByQuery("Five", "Several", select4,)
	
		select5 = "Select*where Drivewayden = null and (funcl = 906 or funcl = 907  or funcl = 6 or funcl = 7)"
		SelectByQuery("Six and Seven", "Several", select5,)
	
		select6 = "Select*where Drivewayden = null and (funcl = 900 or funcl = 90)"
		SelectByQuery("Centroids", "Several", select6,)
	
	
		hi = GetFirstRecord(netview+"|One Two Eight and Nine",)
		while hi <> null do
	
		SetRecordValues(netview,null,{{"Drivewayden", "X"}})
	
		hi = GetNextRecord(netview+"|One Two Eight and Nine", null,)
		end
	
	
		hi = GetFirstRecord(netview+"|Three",)
		while hi <> null do
	
		SetRecordValues(netview,null,{{"Drivewayden", "L"}})
	
		hi = GetNextRecord(netview+"|Three", null,)
		end
	
	
		hi = GetFirstRecord(netview+"|Four",)
		while hi <> null do
	
			mval = GetRecordValues(netview, hi,{"areatp"})
	
			areatp = mval[1][2]
	
			if areatp = 1 then do
				drive = "M"
				end
			if areatp = 2 then do
				drive = "H"
				end
			if areatp = 3 then do
				drive = "H"
				end
			if areatp = 4 then do
				drive = "M"
				end
			if areatp = 5 then do
	
				drive = "L"
				end
		SetRecordValues(netview,null,{{"Drivewayden", drive}})
	
		hi = GetNextRecord(netview+"|Four", null,)
		end
	
	
		hi = GetFirstRecord(netview+"|Five",)
		while hi <> null do
	
			mval = GetRecordValues(netview, hi,{"areatp"})
	
			areatp = mval[1][2]
	
			if areatp = 1 then do
				drive = "M"
				end
			if areatp = 2 then do
				drive = "H"
				end
			if areatp = 3 then do
				drive = "H"
				end
			if areatp = 4 then do
				drive = "M"
				end
			if areatp = 5 then do
				drive = "L"
				end
	
		SetRecordValues(netview,null,{{"Drivewayden", drive}})
	
		hi = GetNextRecord(netview+"|Five", null,)
		end
	
		hi = GetFirstRecord(netview+"|Six and Seven",)
		while hi <> null do
	
			mval = GetRecordValues(netview, hi,{"areatp"})
	
			areatp = mval[1][2]
	
			if areatp = 1 then do
				drive = "M"
				end
			if areatp = 2 then do
				drive = "H"
				end
			if areatp = 3 then do
				drive = "H"
				end
			if areatp = 4 then do
				drive = "M"
				end
			if areatp = 5 then do
				drive = "L"
				end
	
		SetRecordValues(netview,null,{{"Drivewayden", drive}})
	
		hi = GetNextRecord(netview+"|Six and Seven", null,)
		end
	
	
	
		hi = GetFirstRecord(netview+"|Centroids",)
		while hi <> null do
	
			mval = GetRecordValues(netview, hi,{"areatp"})
	
			areatp = mval[1][2]
	
			if areatp = 1 then do
				drive = "M"
				end
			if areatp = 2 then do
				drive = "H"
				end
			if areatp = 3 then do
				drive = "M"
				end
			if areatp = 4 then do
				drive = "L"
				end
			if areatp = 5 then do
				drive = "H"
				end
	
		SetRecordValues(netview,null,{{"Drivewayden", drive}})
	
		hi = GetNextRecord(netview+"|Centroids", null,)
		end
	
		deleteset("One Two Eight and Nine")
		deleteset("Three")
		deleteset("Four")
		deleteset("Five")
		deleteset("Six and Seven")
		deleteset("Centroids")
		mval=null
	end	//if s2i(theyear) > 2002 then do
//	RunMacro("G30 File Close All") 

//	netview=null
//end	//loop of time periods
quit:
//closemap()

endmacro
