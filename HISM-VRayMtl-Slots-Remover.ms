/*  
[INFO] 

NAME = HISM VRayMtl Slots Remover
VERSION = 1.0.0
AUTHOR = MastaMan
DEV = https://3dground.net
HELP = 
CLIENT = HISM

[1.0.0]
* Initial release =

[ABOUT]

Script for mass deletion of specified slots in VRayMtl.=

[SCRIPT]
*/	


try(closeRolloutFloater fVRayMtlSlotsRemover) catch()
global fVRayMtlSlotsRemover = newRolloutFloater "Advanced Corona2VRay Converter" 300 300
global _rVMSR_Step0
global _rVMSR_About

rollout _rVMSR_Step0  "Remove Slots" (
	
	group "Remove VRayMtl Slots" (
		checkbox cbxDispacement "Displacement" align: #left across: 2 checked: true
		label lblDispacement "-" align: #right
		
		checkbox cbxBump "Bump" align: #left across: 2 checked: true
		label lblBump "-" align: #right
	)
	
	local checkboxes = #(
		#(cbxDispacement, lblDispacement, #texmap_displacement, 0),
		#(cbxBump, lblBump, #texmap_bump, 0)
	)
	
	button btnStart "Start" width: 260 height: 35  offset: [0, 5]
	
	fn resetStatistics = (
		for c in checkboxes do (
			c[2].caption = "-"
			c[4] = 0
		)
	)
	
	fn showStatistics = (
		for c in checkboxes do c[2].caption = c[4] as string
	)
	
	fn removeSelectedSlots = (		
		resetStatistics()
		
		local q = queryBox "The operation to remove slots from VRayMtl cannot be undone and you may lose your data.\nMake sure you back up your scene!\n\nWould you like to continue?" title: "Confirm?"
		if (not q) do return false
		
		for m in getClassInstances VRayMtl do (
			for c in checkboxes do (
				if(c[1].checked) do (
					if (getProperty m c[3] != undefined) do (
						setProperty m c[3] undefined
						c[4] += 1
					)
				)
			)
		)
		
		showStatistics()
	)
	
	on btnStart pressed do removeSelectedSlots()
)


rollout _rVMSR_About "About" (
	label lblDummy1 ""
    
	label lblName "" 
	label lblVer ""
	label lblClient ""
	
	label lblDummy2 ""
	
	label lblAuthor ""
	hyperlink lblCopy ""  align: #center
	
	label lblDummy3 ""
	
	group "Description" (
		dotNetControl edtDescription "System.Windows.Forms.Textbox" align:#center height: 300
	)
	
	
	timer tmrRestart "" active: false interval: 300
	    
	fn downloadFile url dl = (
		deleteFile dl
		w = dotNetObject "System.Net.WebClient"			
		try(
			spm = dotNetClass "System.Net.ServicePointManager"
			spm.SecurityProtocol = spm.SecurityProtocol.TLS12				
			w.DownloadFile (url + "?time=" + timestamp() as string) dl				
		) catch(
			return false
		)
		
		return true
	)
	
	fn bgUpdate = (
		local url = "raw_url"
		
		local files = #(
			"file1.ms",
			"Install.mcr"
		)
		
		this = getThisScriptFileName()
		dl = this + ".tmp"
		p = getFilenamePath this
		r = downloadFile (url + files[1]) dl
		if(not r or not doesFileExist dl) do return print "Can't download updates!"
		vn = getIniSetting dl "INFO" "VERSION"
		vo = getIniSetting this "INFO" "VERSION"
		
		if(vn > vo) do (
			deleteFile this
			renameFile dl this
			
			for f in files do (				
				downloadFile (url + f) (p + f)
			)
			
			tmrRestart.active = true
		)
		
		deleteFile dl
	)
	
	fn updateWorker = (
		m = dotnetobject "CSharpUtilities.SynchronizingBackgroundWorker"
		m.WorkerSupportsCancellation = true 
		m.CancelAsync() 
		dotNet.addEventHandler m "DoWork" bgUpdate
		m.RunWorkerAsync()	
	)
	
    fn getScriptInfo s releaseInfo: "" =  (
        if(releaseInfo != "") do (
            local r = getINISetting s releaseInfo
            return r
        )
		
        local v = getINISetting s "INFO" "VERSION"
        local a = getINISetting s "INFO" "AUTHOR"
        local n = getINISetting s "INFO" "NAME"
        local o = ""
		for i in (getINISetting s "ABOUT") do o += i + "\r\n"
        local d = getINISetting s "INFO" "DEV"
        local h = getINISetting s "INFO" "HELP"
        local c = getINISetting s "INFO" "CLIENT"
        
		struct data (version, author, name, description, developer, client, help, releases)
		
        local r = for i in (getINISetting s) where (i != "INFO" and i != "ABOUT" and i != "SCRIPT" and i != "COPY") collect i
		
		return (data version: v author: a name: n description: o developer: d client: c help: h releases: r)
    )
	
	on tmrRestart tick do (
		this = getThisScriptFileName()
		try(fileIn this) catch()
		vo = getIniSetting this "INFO" "VERSION"
		m = ("Script updated to version " + vo + "!\n\n\n")
		for c in (getIniSetting this vo) do (
			m += c + "\n"
		)
		
		messageBox m title: "Success!" beep: false
		tmrRestart.active = false
	)

    on _rVMSR_About open do (
		edtDescription.MultiLine = true
		edtDescription.WordWrap = true
		edtDescription.ReadOnly = true
		edtDescription.BorderStyle = (dotNetClass "System.Windows.Forms.BorderStyle").FixedSingle
		edtDescription.ScrollBars = (dotNetClass "System.Windows.Forms.ScrollBars").Vertical
		
		local thisScript = getThisScriptFilename()
        local i = getScriptInfo thisScript
		
        lblName.caption = i.name
        lblAuthor.caption = i.author
        lblVer.caption = i.version
        lblCopy.address = lblCopy.caption = i.developer
        lblClient.caption = i.client
		edtDescription.text = i.description
			
			
		local releaseNotes = ""	
		for ii in i.releases.count to 1 by -1 do (
			local v = i.releases[ii]
			local r = getScriptInfo thisScript releaseInfo: v
			
			releaseNotes += "\r\n" + v + "\r\n"
			for j in r do releaseNotes += j + "\r\n"
		)
		
		edtDescription.text += releaseNotes
		
		try (fVRayMtlSlotsRemover.title = i.name + " v" +  i.version) catch()
		
		--updateWorker()
    )		
)


addRollout ::_rVMSR_Step0 ::fVRayMtlSlotsRemover rolledUp:false
addRollout ::_rVMSR_About ::fVRayMtlSlotsRemover rolledUp:true