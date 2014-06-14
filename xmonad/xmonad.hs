--
-- File     : ~/.xmonad/xmonad.hs (for Xmonad >= 0.9)
-- Author   : Leaeasy
-- Desc     : A simple, mouse-friendly xmonad config geared towards
--            netbooks and other low-resolution devices.
--
--            dzen is used for statusbar rendering, with optional mouse
--            integration provided by xdotool:
--
--             * left-click workspace num to go to that ws
--             * left-click layout to cycle next layout
--             * left-click window title to cycle next window
--             * middle-click window title to kill focused window
--

import XMonad
import XMonad.Actions.CycleWindows -- classic alt-tab
import XMonad.Actions.CycleWS      -- cycle thru WS', toggle last WS
import XMonad.Actions.DwmPromote   -- swap master like dwm
import XMonad.Hooks.DynamicLog     -- statusbar 
import XMonad.Hooks.EwmhDesktops   -- fullscreenEventHook fixes chrome fullscreen
import XMonad.Hooks.ManageDocks    -- dock/tray mgmt
import XMonad.Hooks.UrgencyHook    -- window alert bells 
import XMonad.Layout.Named         -- custom layout names
import XMonad.Layout.NoBorders     -- smart borders on solo clients
import XMonad.Util.EZConfig        -- append key/mouse bindings
import XMonad.Util.Run(spawnPipe)  -- spawnPipe and hPutStrLn
import System.IO                   -- hPutStrLn scope

import qualified XMonad.StackSet as W   -- manageHook rules

main = do
        status <- spawnPipe myDzenStatus    -- xmonad status on the left
        gumon  <- spawnPipe myDzenGumon     -- conky stats on the right
        xmonad $ withUrgencyHook NoUrgencyHook $ defaultConfig 
            { modMask            = mod4Mask
            , terminal           = "urxvtc"
            , borderWidth        = 1
            , normalBorderColor  = "#dddddd"
            , focusedBorderColor = "#0000ff"
            , focusFollowsMouse  = myFocusFollowsMouse
            , handleEventHook    = fullscreenEventHook
            , workspaces = myWorkspaces
            , layoutHook = myLayoutHook
            , startupHook = myStartup
            , manageHook = manageDocks <+> myManageHook
                            <+> manageHook defaultConfig
            , logHook    = myLogHook status
            } 
            `additionalKeysP` myKeys

-- Tags/Workspaces
-- clickable workspaces via dzen/xdotool
myWorkspaces            :: [String]
myWorkspaces            = clickable . (map dzenEscape) $ ["1.Web","2.Doc","3.Emacs","4.Remote","5.Others"]
 
  where clickable l     = [ "^ca(1,xdotool key super+" ++ show (n) ++ ")" ++ ws ++ "^ca()" |
                            (i,ws) <- zip [1..] l,
                            let n = i ]

-- 不跟随鼠标聚集
myFocusFollowsMouse :: Bool
myFocusFollowsMouse = False 

-- Layouts
-- the default layout is fullscreen with smartborders applied to all
myLayoutHook = avoidStruts $ smartBorders ( tiled ||| mtiled ||| full )
  where
    tiled   = named "T" $ Tall 1 (5/100) (2/(1+(toRational(sqrt(5)::Double))))
    full    = named "X" $ Full
    mtiled  = named "M" $ Mirror tiled
    -- sets default tile as: Tall nmaster (delta) (golden ratio)

-- startup programs
myStartup :: X ()
myStartup = do
    spawn "unclutter"
    spawn "fcitx"
    spawn "start-pulseaudio-x11"
    spawn "urxvtd"
    spawn "xcompmgr"


-- Window management
--
myManageHook = composeAll
    [ className =? "MPlayer"        --> doFloat
    , className =? "Vlc"            --> doFloat
    , className =? "mpv"            --> doFloat
    , className =? "Gimp"           --> doFloat
    , className =? "XCalc"          --> doFloat
    , className =? "Chromium"       --> doF (W.shift (myWorkspaces !! 1)) -- send to ws 2
    , className =? "firefox"        --> doF (W.shift (myWorkspaces !! 1)) -- send to ws 2
    , className =? "Nautilus"       --> doF (W.shift (myWorkspaces !! 2)) -- send to ws 3
    , className =? "Gimp"           --> doF (W.shift (myWorkspaces !! 3)) -- send to ws 4
    , className =? "stalonetray"    --> doIgnore
    ]

-- Statusbar 
myLogHook h = dynamicLogWithPP $ myDzenPP { ppOutput = hPutStrLn h }

-- myDzenStatus = "dzen2 -w '320' -ta 'l'" ++ myDzenStyle
myDzenStatus = "dzen2 -w '920' -ta 'l'" ++ myDzenStyle
myDzenGumon  = "gumon | dzen2 -x '920' -w '1000' -ta 'r'" ++ myDzenStyle
-- myDzenStyle  = " -h '21' -fg '#777778' -bg '#222222' -fn 'XHei Ubuntu:bold:size=11'"
myDzenStyle  = " -h '19' -fg '#777778' -bg '#222222' -fn 'bold:size=11'"

myDzenPP  = dzenPP
    { ppCurrent = dzenColor "#3399ff" "" . wrap " " " "
    , ppHidden  = dzenColor "#dddddd" "" . wrap " " " "
    , ppHiddenNoWindows = dzenColor "#777777" "" . wrap " " " "
    , ppUrgent  = dzenColor "#ff0000" "" . wrap " " " "
    , ppSep     = "     "
    , ppLayout  = dzenColor "#aaaaaa" "" . wrap "^ca(1,xdotool key super+space)· " " ·^ca()"
    , ppTitle   = dzenColor "#ffffff" "" 
                    . wrap "^ca(1,xdotool key super+k)^ca(2,xdotool key super+shift+c)"
                           "                          ^ca()^ca()" . shorten 20 . dzenEscape
    }

-- Key bindings
--
myKeys = [ ("M-b"        , sendMessage ToggleStruts              ) -- toggle the status bar gap
         , ("M1-<Tab>"   , cycleRecentWindows [xK_Alt_L] xK_Tab xK_Tab ) -- classic alt-tab behaviour
         , ("M-<Return>" , dwmpromote                            ) -- swap the focused window and the master window
         , ("M-<Tab>"    , toggleWS                              ) -- toggle last workspace (super-tab)
         , ("M-<Right>"  , nextWS                                ) -- go to next workspace
         , ("M-<Left>"   , prevWS                                ) -- go to prev workspace
         , ("M-S-<Right>", shiftToNext                           ) -- move client to next workspace
         , ("M-S-<Left>" , shiftToPrev                           ) -- move client to prev workspace
         , ("M-r"        , spawn "dmenu_run -fn 'Sans-11'"       ) -- app launcher
         , ("M-n"        , spawn "wicd-client -n"                ) -- network manager
         , ("C-M-r"        , spawn "killall dzen2 && killall gumon && xmonad --restart"              ) -- restart xmonad w/o recompiling
         , ("C-q t"        , spawn "urxvtc"                       ) -- launch terminal
         , ("M-w"        , spawn "firefox"                       ) -- launch browser
         , ("M-e"        , spawn "nautilus"                      ) -- launch file manager
         , ("C-M1-l"     , spawn "slimlock"                      ) -- lock screen
         , ("C-q k"      , kill                                  ) -- kill buffer
         , ("<XF86AudioLowerVolume>", spawn "amixer -q set Master 1%-") --XF86AudioLowerVolume
         , ("<XF86AudioRaiseVolume>", spawn "amixer -q set Master 1%+") --XF86AudioRaiseVolume
         , ("<XF86AudioMute>", spawn "amixer -q set Master playback toggle") --XF86AudioMute
         , ("C-M1-<Delete>" , spawn "shutdown now"       ) -- poweroff
         , ("C-M1-<Insert>" , spawn "reboot"       ) -- reboot
         ]

-- vim:sw=4 sts=4 ts=4 tw=0 et ai 
