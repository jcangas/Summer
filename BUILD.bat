@echo off
setlocal
set BDSPROJECTGROUPDIR=%~dp0

call rsvars
msbuild SummerFW4D.groupproj
