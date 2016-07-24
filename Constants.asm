; ================================================================
; Constants
; ================================================================

if !def(incConsts)
incConsts	set	1

; ================================================================
; Global constants
; ================================================================

sys_DMG		equ	0
sys_GBP		equ	1
sys_SGB		equ	2
sys_SGB2	equ	3
sys_GBC		equ	4
sys_GBA		equ	5

btnA		equ	0
btnB		equ	1
btnSelect	equ	2
btnStart	equ	3
btnRight	equ	4
btnLeft		equ	5
btnUp		equ	6
btnDown		equ	7

; ================================================================
; Carillon Player-specific constants
; ================================================================

InitPlayer	equ	$4000
StartMusic	equ	$4003
StopMusic	equ	$4006
SelectSong	equ	$400c
UpdateMusic	equ	$4100

; ================================================================
; Project-specific constants
; ================================================================

; Game modes

GM_DebugMenu	equ	0
GM_SplashScreen	equ	1
GM_TestScreen	equ	2
GM_SoundTest	equ	3
GM_TitleScreen	equ	4
GM_LevelSelect	equ	5
GM_OptionsMenu	equ	6
GM_Level		equ	7

; Song IDs


mus_Introtune	equ	$00
mus_MenuTheme	equ	$01
mus_Fruitless	equ	$02
mus_Soundcheck	equ	$03
mus_Train		equ	$04
mus_Oldschool	equ	$05
mus_Fruitful	equ	$06
mus_FishFiles	equ	$07
mus_LoOp		equ	$08
mus_20y			equ	$09
mus_Gejmbaj		equ	$0a
mus_Oh			equ	$0b
mus_Pocket		equ	$0c
mus_Demotronic	equ	$0d

endc