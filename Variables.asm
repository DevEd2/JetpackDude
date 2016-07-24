; ================================================================
; Variables
; ================================================================

if !def(incVars)
incVars	set	1

SECTION	"Variables",BSS

; ================================================================
; Global variables
; ================================================================

GBType				ds	1	; current Game Boy model
GBTestRun			ds	1	; flag set when GB type test is run
sys_btnHold			ds	1	; held buttons
sys_btnPress		ds	1	; pressed buttons
CurrentFrame		ds	1	; current frame
FadeState			ds	1
FadeTimer			ds	1
ScreenTimer			ds	1	; screen timer (up to 255 frames)
PlayMusic			ds	1	; set when a song is playing
MusicBank			ds	1	; current music bank

; ================================================================
; Project-specific variables
; ================================================================

; Insert project-specific variables here.

CurrentMenuItem		ds	1	; currently selected menu item
OldMenuItem			ds	1	; old menu item
GameMode			ds	1	; current game mode
DebugEnabled		ds	1	; debug mode flag

SoundTestMusicID	ds	1	; music ID (on sound test)
SoundTestSFXID		ds	1	; SFX ID (on sound test)

ParTileBuffer		ds	32	; parallax tile source buffer


; ================================================================

SECTION "Temporary register storage space",HRAM

tempAF				ds	2
tempBC				ds	2
tempDE				ds	2
tempHL				ds	2
tempSP				ds	2
tempPC				ds	2
tempIF				ds	1
tempIE				ds	1
OAM_DMA				ds	8

endc