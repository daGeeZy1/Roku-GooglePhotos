'*************************************************************
'** PhotoView for Google Photos
'** Copyright (c) 2017-2020 Chris Taylor.  All rights reserved.
'** Use of code within this application subject to the MIT License (MIT)
'** https://raw.githubusercontent.com/chtaylo2/Roku-GooglePhotos/master/LICENSE
'*************************************************************

' This is our global function declaration script.
' Since ROKU doesn't support global functions, the following must be added to each XML file where needed
' <script type="text/brightscript" uri="pkg:/components/Utils/Common.brs" />


Function loadCommon()
    ' Common varables for needed for Oauth and GooglePhotos API
    
    m.releaseVersion   = "3.5"
    m.gp_scope         = "https://photoslibrary.googleapis.com"
    m.gp_prefix        = m.gp_scope + "/v1"
    
    'Moving m.register_prefix to HTTP (vs. HTTPS) during the domain name transition. Will be moved back in next release.
    m.register_prefix  = "https://www.photoviewapp.com"
    m.oauth_prefix     = "https://www.googleapis.com/oauth2/v4"
    m.oauth_scope      = ""
    
    'Help manage API calls. YES, Google monitors this. Which ever comes first
    m.maxApiPerPage    = 12
    m.maxImagesPerPage = 1000
    
    'Load device details
    m.device           = createObject("roDeviceInfo")
    
End Function


Function loadPrivlanged()
    m.clientId        = getClientId()
    m.clientSecret    = getClientSecret()
End Function


Function loadItems()
    m.section   = "GooglePhotos-Auth"
    m.items     = CreateObject("roList")
    m.items.push("accessToken")
    m.items.push("refreshToken")
    m.items.push("versionToken")
    m.items.push("userInfoName")
    m.items.push("userInfoEmail")
    m.items.push("userInfoPhoto")
End Function


Function loadDefaults()

    device  = createObject("roDeviceInfo")
    is4k    = (val(device.GetVideoMode()) = 2160)
    is1080p = (val(device.GetVideoMode()) = 1080)

    tmp = RegRead("SSaverUser", "Settings")
    if tmp=invalid RegWrite("SSaverUser", "0", "Settings")
    tmp = RegRead("SSaverDelay", "Settings")
    if tmp=invalid RegWrite("SSaverDelay", itostr(15), "Settings")
    tmp = RegRead("SSaverOrder", "Settings")
    if tmp=invalid RegWrite("SSaverOrder", "Random Order", "Settings")
    tmp = RegRead("SSaverMethod", "Settings")
    if tmp=invalid RegWrite("SSaverMethod", "YesFading_YesBlur", "Settings")
    tmp = RegRead("SSaverCEC", "Settings")
    if tmp=invalid RegWrite("SSaverCEC", "HDMI-CEC Enabled", "Settings")
    tmp = RegRead("SSaverTime", "Settings")
    if tmp=invalid RegWrite("SSaverTime", "Disabled", "Settings")
    
    tmp = RegRead("SlideshowDisplay", "Settings")
    if tmp=invalid RegWrite("SlideshowDisplay", "YesFading_YesBlur", "Settings")
    tmp = RegRead("SlideshowDelay", "Settings")
    if tmp=invalid RegWrite("SlideshowDelay", itostr(8), "Settings")
    
    'v3 - Minimum delay is 5 seconds. Sorry - but Google enforces a downlaod limit.
    tmp = RegRead("SlideshowDelay", "Settings")
    if Strtoi(tmp) < 5 RegWrite("SlideshowDelay", itostr(5), "Settings")
    tmp = RegRead("SSaverDelay", "Settings")
    if Strtoi(tmp) < 5 RegWrite("SSaverDelay", itostr(5), "Settings")
    
    tmp = RegRead("SlideshowOrder", "Settings")
    if tmp=invalid RegWrite("SlideshowOrder", "Album Order", "Settings")
    
    if is4k then
        tmp = RegRead("SSaverRes", "Settings")
        if tmp=invalid RegWrite("SSaverRes", "FHD", "Settings")
        tmp = RegRead("SlideshowRes", "Settings")
        if tmp=invalid RegWrite("SlideshowRes", "FHD", "Settings")
    else if is1080p
        tmp = RegRead("SSaverRes", "Settings")
        if tmp=invalid RegWrite("SSaverRes", "HD", "Settings")
        tmp = RegRead("SlideshowRes", "Settings")
        if tmp=invalid RegWrite("SlideshowRes", "HD", "Settings")
    else
        tmp = RegRead("SSaverRes", "Settings")
        if tmp=invalid RegWrite("SSaverRes", "SD", "Settings")
        tmp = RegRead("SlideshowRes", "Settings")
        if tmp=invalid RegWrite("SlideshowRes", "SD", "Settings")
    end if   
    
End Function


'*********************************************************
'**
'** Registry actions
'**
'*********************************************************
Function RegRead(key, section=invalid)
    if section = invalid then section = "Default"
    sec = CreateObject("roRegistrySection", section)
    if sec.Exists(key) then return sec.Read(key)
    return invalid
End Function


Function RegWrite(key, val, section=invalid)
    if section = invalid then section = "Default"
    sec = CreateObject("roRegistrySection", section)
    sec.Write(key, val)
    sec.Flush() 'commit it
End Function


Function RegDelete(key, section=invalid)
    if section = invalid then section = "Default"
    sec = CreateObject("roRegistrySection", section)
    sec.Delete(key)
    sec.Flush()
End Function


'*********************************************************
'**
'** Load tokens from registry
'**
'*********************************************************
Function loadReg() As Boolean

    loadItems()
    for each item in m.items
        temp = RegRead(item, m.section)
        if temp = invalid then temp = ""
        m[item] = temp.Split(",")
        if m[item][0] = "" then m[item].shift()
      
        print "LOAD REG ["; item; "] = "; temp
    end for

    'Legacy Support
    if m.accessToken[0]<>invalid and m.userInfoName[0]=invalid then
        m.userInfoName.Push("Legacy User")
        m.userInfoEmail.Push("Relink account to pull user details (then remove this link in Settings)")
        m.userInfoPhoto.Push("pkg:/images/userdefault.png")
    end if
End Function


'*********************************************************
'**
'** Save tokens to registry
'**
'*********************************************************
Function saveReg()

    loadItems()
    for each item in m.items
        value=""
        for i = 0 to m[item].Count()-1
            if i = m[item].Count()-1 then
                value = value+m[item][i]
            else
                value = value+m[item][i]+","
            end if
        end for
      
        print "SAVE REG ["; item; "] = "; value
    
        RegWrite(item, value, m.section)
    end for
End Function


'*********************************************************
'**
'** Erase tokens from registry
'**
'*********************************************************
Function eraseReg()

    loadItems()
    for each item in m.items
        RegDelete(item, m.section)
    end for
End Function


Function definedReg() As Boolean

    loadItems()
    
    'Legacy Support
    if m.accessToken[0]<>invalid and m.userInfoName[0]=invalid then
        m.userInfoName.Push("Legacy User")
        m.userInfoEmail.Push("Relink account to pull user details (then remove this link in Settings)")
        m.userInfoPhoto.Push("pkg:/images/userdefault.png")
    end if

    for each item in m.items
        if m[item] = invalid Or m[item].Count()=0 then return false
    end for
    return true
End Function


Function dumpReg() As String

    loadItems()
    result = ""
    for each item in m.items
        value=""
        for i = 0 to m[item].Count()-1
            if i = m[item].Count()-1 then
                value = value+m[item][i]
            else
                value = value+m[item][i]+","
            end if
        end for 
        result = result + " " +item+"="+value
    end for
    return result
End Function


'*********************************************************
'**
'** Count number of user tokens we have
'**
'*********************************************************
Function oauth_count()
    
    loadItems()
    
    print "DEBUG: "; m.versionToken
    'The following to for v2.x to v3 migration. Can be removed in a later version (Sometime after August, 2019)
    if (m.versionToken = invalid and m.accessToken.Count()<>0) or (m.versionToken.Count() = 0 and m.accessToken.Count()<>0) then
        usersLoaded = m.accessToken.Count()
        for i = 0 to usersLoaded-1
            m.versionToken.Push("v2token")
        end for
        saveReg()
    end if
    
    
    for each item in m.items
        if m.accessToken.Count() <> m.[item].Count() then
            print "accessToken / "; item; " counts do not match"
            'This sucks, items don't match. We need to kill all registrations
            eraseReg()
        end if
    end for
        
    return m.accessToken.Count()

End Function


'*********************************************************
'**
'** create a header object with authorization token
'**
'*********************************************************
Function oauth_sign(userIndex As Integer) as Object 

    ' Save our current selection
    m.currentAccessTokenInd = userIndex
    
    signedHeader = {}
    
    if m.accessToken[userIndex] <> ""
        signedHeader["Authorization"] = "Bearer " + m.accessToken[userIndex]
        'print "Creating Signed Headers: "; m.accessToken[userIndex]
    end if
    
    return signedHeader

End Function


Sub makeRequest(headers as Object, url as String, method as String, post_params as String, num as Integer, post_data as Object)
    print "Common.brs [makeRequest]"

    context = createObject("roSGNode", "Node")
    params = {
        headers: headers,
        uri: url,
        method: method,
        params: post_params
    }

    context.addFields({
        parameters: params,
        num: num,
        post_data: post_data,
        response: {}
    })

    m.UriHandler.request = { context: context }    
End Sub


Function getResolution(setting=invalid As String)
    ssres = RegRead("SlideshowRes","Settings")

    resUHD   = "=w3840-h2160"
    resFHD   = "=w1920-h1080"
    resHD720 = "=w1280-h720"
    resSD    = "=w640-h480"

    'Using selected settings
    if setting<>invalid then
        if setting="UHD" then
            resolution = resUHD
        else if (setting="FHD" or setting="HD")
            resolution = resFHD
        else if setting="HD720"
            resolution = resHD720
        else
            resolution = resSD
        end if    
    
    'No res size selected
    else
        device  = createObject("roDeviceInfo")
        is4k    = (val(device.GetVideoMode()) >= 2160)
        is1080p = (val(device.GetVideoMode()) = 1080)
        is720p  = (val(device.GetVideoMode()) = 720)

        if is4k then
            resolution = resUHD
        else if is1080p
            resolution = resFHD
        else if is720p
            resolution = resHD720
        else
            resolution = resSD
        end if
    end if
    
    return resolution
End Function


Function GetRandom(items As Object)
    return Rnd(items.Count())-1
End Function


'******************************************************
'Parse a string into a roXMLElement
'
'return invalid on error, else the xml object
'******************************************************
Function ParseXML(str As String) As dynamic
    if str = invalid return invalid
    xml=CreateObject("roXMLElement")
    if not xml.Parse(str) return invalid
    return xml
End Function


'******************************************************
'Determine if the given object supports the ifXMLElement interface
'******************************************************
Function isxmlelement(obj as dynamic) As Boolean
    if obj = invalid return false
    if GetInterface(obj, "ifXMLElement") = invalid return false
    return true
End Function


'******************************************************
'Return Ceiling of number
'******************************************************
Function ceiling(x):
    i = int(x)
    if i < x then i = i + 1
    return i
End Function


'******************************************************
'Convert int to string. This is necessary because
'the builtin Stri(x) prepends whitespace
'******************************************************
Function itostr(i As Integer) As String
    str = Stri(i)
    return strTrim(str)
End Function


'******************************************************
'Trim a string
'******************************************************
Function strTrim(str As String) As String
    st=CreateObject("roString")
    st.SetString(str)
    return st.Trim()
End Function


'******************************************************
'Pluralize simple strings like "1 minute" or "2 minutes"
'******************************************************
Function Pluralize(val As Integer, str As String) As String
    ret = itostr(val) + " " + str
    if val <> 1 ret = ret + "s"
    return ret
End Function


'******************************************************************************
' Extract a string from an associative array returned by ParseJson
' Return the default value if the field is missing, invalid or the wrong type
'******************************************************************************
Function getString(json As Dynamic,fieldName As String,defaultValue="" As String) As String
    returnValue = defaultValue
    if json <> Invalid
        if type(json) = "roAssociativeArray" or GetInterface(json,"ifAssociativeArray")
            fieldValue = json.LookupCI(fieldName)
            if fieldValue <> Invalid
                if type(fieldValue) = "roString" or type(fieldValue) = "String" or GetInterface(fieldValue,"ifString") <> Invalid
                    returnValue = fieldValue
                end if
            end if
        end if
    end if
    return returnValue
End Function


'******************************************************************************
' Extract an integer from an associative array returned by ParseJson
' Return the default value if the field is missing, invalid or the wrong type
'******************************************************************************
Function getInteger(json As Dynamic,fieldName As String,defaultValue=0 As Integer) As Integer
    returnValue = defaultValue
    if json <> Invalid
        if type(json) = "roAssociativeArray" or GetInterface(json,"ifAssociativeArray")
            fieldValue = json.LookupCI(fieldName)
            if fieldValue <> Invalid
                if type(fieldValue) = "roInteger" or type(fieldValue) = "Integer" or type(fieldValue) = "roInt" or GetInterface(fieldValue,"ifInt") <> Invalid
                    returnValue = fieldValue
                end if
            end if
        end if
    end if
    return returnValue
End Function


'******************************************************
'Get friendly date output given seconds
'******************************************************
Function friendlyDate(dateString As String) As String
    calcDate = CreateObject("roDateTime")
    calcDate.FromISO8601String(dateString)
    showDate = calcDate.AsDateString("long-date")
    return showDate
End Function


'******************************************************
'Get short friendly date output given seconds
'******************************************************
Function friendlyDateShort(dateString As String) As String
    calcDate = CreateObject("roDateTime")
    calcDate.FromISO8601String(dateString)
    showDate = calcDate.AsDateString("no-weekday")
    return showDate
End Function


'******************************************************
'Replace special charactors in string
'******************************************************
Function strReplaceSpecial(basestr As String) As String
    newstr = basestr
    newstr = newstr.Replace("'", "")
    newstr = newstr.Replace(",", "")
    newstr = newstr.Replace("<", "")
    newstr = newstr.Replace(">", "")
    newstr = newstr.Replace("$", "")
    newstr = newstr.Replace("*", "")
    newstr = newstr.Replace("#", "")
    newstr = newstr.Replace("!", "")
    newstr = newstr.Replace("%", "")
    newstr = newstr.Replace("^", "")
    newstr = newstr.Replace("&", "")
    newstr = newstr.Replace("\", "")
    newstr = newstr.Replace("|", "")
    newstr = newstr.Replace("/", "")
    newstr = newstr.Replace("?", "")
    
    return newstr
End Function


'******************************************************
'Replace a leading 0 if only 1 digit is found
'******************************************************
Function zeroCheck(day as string) as string
   if len(day)=1 then day="0"+day
   
   return day   
End Function


'******************************************************
'Get current time.
'******************************************************
Function getLocalTime() as string   
    dt = CreateObject("roDateTime")
    dt.toLocalTime()
    
    chour = dt.GetHours()

    if chour=0 then
      chour = 12
      ampm  = "am"
    else if chour=12 then
      chour = 12
      ampm  = "pm"
    else if chour>12 then 
      chour = chour-12
      ampm  = "pm"
    else if chour<12 then
      chour=chour
      ampm="am"
    endif
    
    dateStr = dt.asDateString("no-weekday") + chr(10) + chour.ToStr() + ":" + zeroCheck(dt.getMinutes().ToStr()) + " " + ampm
    return dateStr
End Function


'******************************************************
'This will monitor events looking for the registery delete sequence
'Sequence Required:  UP, UP, UP, UP, UP, Options, Options, Play, Play, Play
'******************************************************
Function supportResetMonitor(key as string, sequence as string) as string

    strStep = "Normal"
    
    if ( key = "up" and sequence = "Normal" ) then
         strStep = "1"
    else if ( key = "up" and sequence = "1" ) then
         strStep = "2"
    else if ( key = "up" and sequence = "2" ) then
         strStep = "3"
    else if ( key = "up" and sequence = "3" ) then
         strStep = "4"
    else if ( key = "up" and sequence = "4" ) then
         strStep = "5"
    else if ( key = "options" and sequence = "5" ) then
         strStep = "6"
    else if ( key = "options" and sequence = "6" ) then
         strStep= "7"
    else if ( key = "play" and sequence = "7" ) then
         strStep = "8"
    else if ( key = "play" and sequence = "8" ) then
         strStep = "9"
    else if ( key = "play" and sequence = "9" ) then
         'Sequence triggered. Issue registry wipe (This channel only of course!)
         DeleteRegistry()
    end if
         
    return strStep
End Function


'******************************************************
'Delete all registery entries for this channel
'******************************************************
Function DeleteRegistry()
    print "Deleting Registry"
    Registry = CreateObject("roRegistry")
    i = 0
    for each section in Registry.GetSectionList()
        sec = CreateObject("roRegistrySection", section)
        for each key in sec.GetKeyList()
            i = i+1
            print "Deleting: " section + ":" key
            RegDelete(key, section)
        end for
    end for
    print i.toStr() " Registry Keys Deleted"
    m.global.selectedUser = -2
End Function


'******************************************************
'Create random string
'******************************************************
Function getRandomString(length As Integer) As String
    hexChars = "0123456789ABCDEF"
    hexString = ""
    For i = 1 to length
        hexString = hexString + hexChars.Mid(Rnd(16) - 1, 1)
    Next
    Return hexString
End Function
