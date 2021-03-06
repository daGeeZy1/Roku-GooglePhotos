'*************************************************************
'** PhotoView for Google Photos
'** Copyright (c) 2017-2018 Chris Taylor.  All rights reserved.
'** Use of code within this application subject to the MIT License (MIT)
'** https://raw.githubusercontent.com/chtaylo2/Roku-GooglePhotos/master/LICENSE
'*************************************************************

Sub Main()
    'Start main screen
    showGooglePhotosScreen()
End Sub


Sub showGooglePhotosScreen()
    screen    = CreateObject("roSGScreen")
    port      = CreateObject("roMessagePort")
    cecstatus = CreateObject("roCECStatus")
    
    scene     = screen.CreateScene("GooglePhotosMainScene")
    m.global  = screen.getGlobalNode()
 
    m.global.addFields( {SlideshowRes: "", SlideshowDisplay: "", SlideshowDelay: "", SlideshowOrder: "", VideoContinuePlay: ""} )
    m.global.addFields( {selectedUser: -1, CECStatus: true} )

    cecstatus.SetMessagePort(port)
    screen.setMessagePort(port)    
    screen.show()

    scene.signalBeacon("AppLaunchComplete")

    if CECStatus <> invalid and CECStatus.IsActiveSource() = false then
        'HDMI-CEC status is false
        m.global.CECStatus = false
    else
        'HDMI-CEC status is true
        m.global.CECStatus = true
    end if

    while(true)
        msg     = wait(0, port)
        msgType = type(msg)

        if msgType = "roCECStatusEvent"
            'print "RECEIVED roCECStatusEvent event - CECStatus.IsActiveSource: -> "; CECStatus.IsActiveSource()
            
            if CECStatus <> invalid and CECStatus.IsActiveSource() = false then
                'HDMI-CEC status has changed to false
                m.global.CECStatus = false
            else
                'HDMI-CEC status has changed to true
                m.global.CECStatus = true
            end if
            
        end if
        
        if type(msg) = "roInputEvent"
            if msg.IsInput()
                info = msg.GetInfo()
                if info.DoesExist("mediaType") and info.DoesExist("contentID")
                    print "DEEP LINK TRIGGERED"
                    mediaType = info.mediaType
                    contentId = info.contentID
                end if
            end if
        end if
        
        if msgType = "roSGScreenEvent"
            if msg.isScreenClosed() then return
        end if
    end while
End Sub
