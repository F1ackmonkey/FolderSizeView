### This provides a visual representation of the filesystem where the largest folders show up with the largest font size.
### the purpose is to quickly identify where on the filesystem the storage is being used.
 

#Browse folder button on_click action
function Btn_OpenFolder {
    $OpenFolderDialog = New-Object system.windows.forms.folderbrowserdialog
    $OpenFolderDialog.showDialog() | Out-Null
    return $($OpenFolderDialog.SelectedPath)
}

Function Update_Ctr_ContainerControl1 {
    $VerbosePrefrence = "Continue"
    $Bar_Progress1.Visible = $true
    if ($this.text -and ($this.GetType()).fullname -eq "System.Windows.Forms.Label"){
        $FolderPath = $this.Text
    } else {
        $FolderPath = $Lbl_FolderPath1.text
    }
    if (Test-Path $FolderPath){
        $Lbl_FolderPath1.text = $FolderPath
        $Ctr_ContainerControl1.Controls.Clear()
        $Folders = Get-ChildItem -Path $FolderPath -Directory -Attributes !ReparsePoint
        $LocationY = 0
        $labelSpacing = 0
        $FolderCollection = @()
        $Error.Clear()
        $Bar_Progress1.Value = 0
        $Bar_Progress1.maximum = $folders.count
        $folders | ForEach-Object {
            try {
                $FolderSize = (Get-ChildItem $_.FullName -Recurse -ErrorAction SilentlyContinue |Measure-Object -Property length -Sum -ErrorAction SilentlyContinue).Sum
            } catch [System.UnauthorizedAccessException] {
                Write-Warning "$_ Try Running as an administrator"
                $FolderSize = (Get-ChildItem $_.FullName -Recurse -ErrorAction SilentlyContinue |Measure-Object -Property length -Sum -ErrorAction SilentlyContinue).Sum
            } catch {
                $FolderSize = 0
            }
           
            $TempObj = New-Object -TypeName psobject
            $TempObj | Add-Member -MemberType NoteProperty -Name FolderName -Value $_.FullName
            $TempObj | Add-Member -MemberType NoteProperty -Name Size -Value $FolderSize
            $folderCollection += $TempObj
            $Bar_Progress1.Value += 1
        }
       
        #Also Add Hidden folder
        $Bar_Progress1.Value = 0
        $Folders = Get-ChildItem -Path $FolderPath -Directory -Hidden -Attributes !ReparsePoint #this will exclude symlinks
        $folders | ForEach-Object {
            try {
                $FolderSize = (Get-ChildItem $_.FullName -Recurse -ErrorAction Stop |Measure-Object -Property length -Sum -ErrorAction Stop).Sum
            } catch [System.UnauthorizedAccessException] {
                Write-Warning "$_ Try Running as an administrator"
                $FolderSize = (Get-ChildItem $_.FullName -Recurse -ErrorAction SilentlyContinue |Measure-Object -Property length -Sum -ErrorAction SilentlyContinue).Sum
            } catch {
                $FolderSize = 0
            }
           
            $TempObj = New-Object -TypeName psobject
            $TempObj | Add-Member -MemberType NoteProperty -Name FolderName -Value $_.FullName
            $TempObj | Add-Member -MemberType NoteProperty -Name Size -Value $FolderSize
            $folderCollection += $TempObj
            $Bar_Progress1.Value += 1
        }
 
        #Also add the files in the current directory as an entry in the collection
        $TempObj = New-Object -TypeName psobject
        $TempObj | Add-Member -MemberType NoteProperty -Name FolderName -Value "$((Get-ChildItem -File $FolderPath).count)Files in Current Directory"
        $error.Clear()
        try {
            $TempObj | Add-Member -MemberType NoteProperty -Name Size -Value $((Get-ChildItem -File $FolderPath -ErrorAction Stop |Measure-Object -Property length -Sum -ErrorAction Stop).Sum)
        } catch [System.UnauthorizedAccessException] {
            Write-Warning "$_ Try Running as an administrator"
            $FolderSize = (Get-ChildItem $_.FullName -Recurse -ErrorAction SilentlyContinue |Measure-Object -Property length -Sum -ErrorAction SilentlyContinue).Sum
        } catch {
            $TempObj | Add-Member -MemberType NoteProperty -Name Size -Value 0
        }
        $FolderCollection += $TempObj
 
        #Also add hidden files in the current directory as an entry in the collection
        $TempObj = New-Object -TypeName psobject
        $TempObj | Add-Member -MemberType NoteProperty -Name FolderName -Value "$((Get-ChildItem -File -Hidden $FolderPath).count) Hidden Files in Current Directory"
        try {
            $TempObj | Add-Member -MemberType NoteProperty -Name Size -Value $((Get-ChildItem -File -Hidden $FolderPath -ErrorAction Stop |Measure-Object -Property length -Sum -ErrorAction Stop).Sum)
        } catch [System.UnauthorizedAccessException] {
            Write-Warning "$_ Try Running as an administrator"
            $FolderSize = (Get-ChildItem $_.FullName -Recurse -ErrorAction SilentlyContinue |Measure-Object -Property length -Sum -ErrorAction SilentlyContinue).Sum
        } catch {
            $TempObj | Add-Member -MemberType NoteProperty -Name Size -Value 0
        }
        $FolderCollection += $TempObj
 
        #Also add system files in the current directory as an entry in the collection
        $TempObj = New-Object -TypeName psobject
        $TempObj | Add-Member -MemberType NoteProperty -Name FolderName -Value "$((Get-ChildItem -File -System $FolderPath).count) System Files in Current Directory"
        try {
            $TempObj | Add-Member -MemberType NoteProperty -Name Size -Value $((Get-ChildItem -System -System $FolderPath -ErrorAction Stop |Measure-Object -Property length -Sum -ErrorAction Stop).Sum)
        } catch [System.UnauthorizedAccessException] {
            Write-Warning "$_ Try Running as an administrator"
            $FolderSize = (Get-ChildItem $_.FullName -Recurse -ErrorAction SilentlyContinue |Measure-Object -Property length -Sum -ErrorAction SilentlyContinue).Sum
        } catch {
            $TempObj | Add-Member -MemberType NoteProperty -Name Size -Value 0
        }
        $FolderCollection += $TempObj
 
        $Bar_Progress1.value = 0
        $Bar_Progress1.maximum = $FolderCollection.count
        #sort by size
        $FolderCollection = $FolderCollection | Sort-Object -Property Size -Descending
 
        $TotalSize = ($FolderCollection | Measure-Object -Property Size -Sum).Sum
        $Lbl_CurrentDirSize.text = [string] ([math]::Round($TotalSize /1mb,2)) + " MB"
        $FontMax = 100
 
        $FontMin = 5
        $LocationY =0
        $FolderCollection | ForEach-Object{
            $Lbl_Temp = New-Object System.Windows.Forms.Label
            $Lbl_Temp.Text = $_.FolderName
            $Lbl_Temp.AutoSize = $true
            $ToolTip = New-Object System.Windows.Forms.ToolTip
            $FolderPercentage = [math]::Round(($_.size/$TotalSize *100),2)
            if ([double]::IsNaN($FolderPercentage)){
                $FolderPercentage = 1
            }
            $ToolTipText = [string] $($Lbl_Temp.Text) + " " + [string] "{0:N2} MB" -f ($_.size /1mb) + " " + [String] $FolderPercentage + "%"
            $ToolTip.SetToolTip($Lbl_Temp,$ToolTipText)
 
            if ($FolderPercentage -lt $FontMin) {
                $NewFont = New-Object System.Drawing.Font($Lbl_Temp.Font.FontFamily,$FontMin)
            } else {
                Write-Verbose $FolderPercentage
                $NewFont = New-Object System.Drawing.Font($Lbl_Temp.Font.FontFamily,$FolderPercentage)
            }
            $Lbl_Temp.Font = $NewFont
            $Lbl_Temp.Size.Height = $Lbl_Temp.Font.Size #New-Object System.Drawing.Size (700,$Lbl_Temp.font.size)
 
 
            Write-Verbose "$LocationY, $($Lbl_Temp.PreferredHeight)"
 
            $Lbl_Temp.Location = New-Object System.Drawing.Size(0,$LocationY) #system.Drawing.Size(width,Height)
            $LocationY = $LocationY + $Lbl_Temp.PreferredHeight #increment the Y location to push the next control down
 
            $Lbl_Temp.add_click(${function:Update_Ctr_ContainerControl1})
 
            $Ctr_ContainerControl1.Controls.Add($Lbl_Temp)
            $Bar_Progress1.Value += 1
        }
        $Bar_Progress1.Visible = $false
        $Ctr_ContainerControl1.PerformAutoScale()
        Write-Verbose "Ctr_ContainerControl1 size: $($Ctr_ContainerControl1.Size)"
 
        #update volume percentage
        $DriveLetter = ([System.IO.Path]::GetPathRoot($FolderPath)).replace('\','')
        $VolumeSize = (Get-CimInstance -Class win32_volume -Filter "driveletter='$DriveLetter'").capacity
        $Lbl_PercentOfVolume.text = [string]([math]::Round(($TotalSize/$VolumeSize*100),2)) + "%"
        $Lbl_PercentOfVolumeText.Text = "Percent of $DriveLetter Volume"
    } else {
        Write-Verbose "Path $FolderPath does not exist"
    }
    $Bar_Progress1.Visible = $false
}
 
$Global:GlobalFolderPath = "C:\Program Files"
Add-Type -AssemblyName system.windows.forms
 
#Create Form
$Frm_Form1 = New-Object System.Windows.Forms.Form
$Frm_Form1.Size = New-Object System.Drawing.Size(825,730)
$Frm_Form1.Text = "Folder Size View"
 
#Folder Path Label
$Lbl_FolderPath1 = New-Object System.Windows.Forms.TextBox
$Lbl_FolderPath1.Size = New-Object System.Drawing.Size(720,23)
$Lbl_FolderPath1.Text = "Test"
$Lbl_FolderPath1.ReadOnly =$true
 
#Current Dir Size Label text
$Lbl_CurrentDirSizeText = New-Object System.Windows.Forms.Label
$Lbl_CurrentDirSizeText.Size = New-Object System.Drawing.Size(425,30)
$Lbl_CurrentDirSizeText.Location = New-Object System.Drawing.Size(0,53)
$NewFont = New-Object System.Drawing.Font($Lbl_CurrentDirSizeText.Font.FontFamily,20)
$Lbl_CurrentDirSizeText.Text = "Current Folder and Subfolder Size"
$Lbl_CurrentDirSizeText.Font = $NewFont
 
#Current Dir Size Label
$Lbl_CurrentDirSize = New-Object System.Windows.Forms.Label
$Lbl_CurrentDirSize.Size = New-Object System.Drawing.Size(150,30)
$Lbl_CurrentDirSize.Location = New-Object System.Drawing.Size(425,53)
$NewFont = New-Object System.Drawing.Font($Lbl_CurrentDirSize.Font.FontFamily,20)
$Lbl_CurrentDirSize.Font = $NewFont
 
#Current percent of volume text
$Lbl_PercentOfVolumeText = New-Object System.Windows.Forms.Label
$Lbl_PercentOfVolumeText.Size = New-Object System.Drawing.Size(425,30)
$Lbl_PercentOfVolumeText.Location = New-Object System.Drawing.Size(0,83)
$NewFont = New-Object System.Drawing.Font($Lbl_CurrentDirSize.Font.FontFamily,20)
$Lbl_PercentOfVolumeText.Text = "Percent Of Volume"
$Lbl_PercentOfVolumeText.Font = $NewFont
 
#Current percent of volume label
$Lbl_PercentOfVolume = New-Object System.Windows.Forms.Label
$Lbl_PercentOfVolume.Size = New-Object System.Drawing.Size(150,30)
$Lbl_PercentOfVolume.Location = New-Object System.Drawing.Size(425,83)
$NewFont = New-Object System.Drawing.Font($Lbl_CurrentDirSize.Font.FontFamily,20)
$Lbl_PercentOfVolume.Font = $NewFont
 
#folder Browse Button
$Btn_OpenFolder = New-Object System.Windows.Forms.Button
$Btn_OpenFolder.Text = "Open Folder"
$Btn_OpenFolder.Location = New-Object System.Drawing.Size(120,23)
$Btn_OpenFolder.size = New-Object System.Drawing.Size(120,23)
$Btn_OpenFolder.add_click({$Lbl_FolderPath1.Text = Btn_OpenFolder;Update_Ctr_ContainerControl1($Lbl_FolderPath1.Text)})
 
#Back Button
$Btn_Back = New-Object System.Windows.Forms.Button
$Btn_Back.Text = "Back"
$Btn_Back.Location = New-Object System.Drawing.Size(25,23)
$Btn_Back.size = New-Object System.Drawing.Size(75,23)
$Btn_Back.add_click({if(($Lbl_FolderPath1.Text.SubString($Lbl_FolderPath1.Text.Length-2)) -ne ":\"){$Lbl_FolderPath1.Text = Split-Path $Lbl_FolderPath1.Text;Update_Ctr_ContainerControl1($Lbl_FolderPath1.Text)}})
 
#container Control
$Ctr_ContainerControl1 = New-Object System.Windows.Forms.ContainerControl
$Ctr_ContainerControl1.size = New-Object System.Drawing.Size(700,700)
$Ctr_ContainerControl1.Location = New-Object System.Drawing.Size(0,123)
$Ctr_ContainerControl1.AutoScroll = $true
$Ctr_ContainerControl1.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::Dpi
$Ctr_ContainerControl1.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
 
#status strip
$Sts_Strip1 = New-Object System.Windows.Forms.StatusStrip
$Bar_Progress1 = New-Object System.Windows.Forms.ToolStripProgressBar
$Sts_Strip1.Dock = [System.Windows.Forms.DockStyle]::Bottom
#$toolstripitem = New-Object System.Windows.Forms.ToolStripItem
$Sts_Strip1.Items.AddRange([System.Windows.Forms.ToolStripItem[]] @($Bar_Progress1))
$Sts_Strip1.Visible = $true
$Sts_Strip1.Enabled = $true
$Sts_Strip1.ShowItemToolTips = $true
$Sts_Strip1.AutoSize = $true
#Progress Bar
 
#$bar_progress1.visible = $false
$Bar_Progress1.Minimum = 0
$Bar_Progress1.Step = 1
$Bar_Progress1.Width = 50
$Bar_Progress1.Text = "Refreshing"
 
#$Sts_Strip1.Controls.Add($Bar_Progress1)

#TODO: Make Hidden button do something
#Show Hidden
$Chk_Hidden = New-Object System.Windows.Forms.CheckBox
$Chk_Hidden.Size = New-Object System.Drawing.Size(30,30)
$Chk_Hidden.Location = New-Object System.Drawing.Size(425,25)
$Chk_Hidden.Checked = $true
 
#Show Hidden Text
$Lbl_HiddenText = New-Object System.Windows.Forms.Label
$Lbl_HiddenText.Size = New-Object System.Drawing.Size(80,30)
$Lbl_HiddenText.Location = New-Object System.Drawing.Size(350,33)
$Lbl_HiddenText.Text = "Show Hidden"
 
#TODO: Make System button do something
#Show System
$Chk_System = New-Object System.Windows.Forms.CheckBox
$Chk_System.Size = New-Object System.Drawing.Size(30,30)
$Chk_System.Location = New-Object System.Drawing.Size(535,25)
$Chk_System.Checked = $true
 
#Show System Text
$Lbl_SystemText = New-Object System.Windows.Forms.Label
$Lbl_SystemText.Size = New-Object System.Drawing.Size(80,30)
$Lbl_SystemText.Location = New-Object System.Drawing.Size(460,33)
$Lbl_SystemText.Text = "Show Hidden"
 
#add controls to form
$Frm_Form1.Controls.add($Lbl_FolderPath1)
$Frm_Form1.Controls.add($Btn_OpenFolder)
$Frm_Form1.Controls.add($Ctr_ContainerControl1)
$Frm_Form1.Controls.add($Lbl_CurrentDirSizeText)
$Frm_Form1.Controls.add($Lbl_CurrentDirSize)
$Frm_Form1.Controls.add($Sts_Strip1)
$Frm_Form1.Controls.add($Btn_Back)
$Frm_Form1.Controls.add($Lbl_PercentOfVolume)
$Frm_Form1.Controls.add($Lbl_PercentOfVolumeText)
$Frm_Form1.Controls.add($Chk_Hidden)
$Frm_Form1.Controls.add($Chk_System)
$Frm_Form1.Controls.add($Lbl_HiddenText)
$Frm_Form1.Controls.add($Lbl_SystemText)
$Sts_Strip1.BringToFront()
 
#set starting path and refresh
$Lbl_FolderPath1.Text = "C:\Program Files"
Update_Ctr_ContainerControl1($Global:GlobalFolderPath)
 
$Frm_Form1.ShowDialog()