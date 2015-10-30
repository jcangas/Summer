{
  Summer Framework for Delphi http://github.com/jcangas/SummerFW4D
  SummerFW4D by Jorge L. Cangas <jorge.cangas@gmail.com>
  SummerFW4D - Copyright(c) Jorge L. Cangas, Some rights reserved.
  Your reuse is governed by the Creative Commons Attribution 3.0 License
}

unit Summer.Strings;

interface

type
  TStringHelper = record helper for string
  public
    function ReplaceTAG(sTagIni, sTagFin, sNewValue: string): string;
    function GetTAGValue(sTagIni, sTagFin: string): string;
(*
( ) — parentheses, brackets (UK, Canada, New Zealand, and Australia), parens, round brackets, soft brackets, or circle brackets
[ ] — square brackets, closed brackets, hard brackets, crotchets,[2] or brackets (US)
{ } — braces are "two connecting marks used in printing"; and in music "to connect staves to be performed at the same time" [3](UK and US), flower brackets (India), French brackets, curly brackets, definite brackets, swirly brackets, curly braces, birdie brackets, Scottish brackets, squirrelly brackets, gullwings, seagulls, squiggly brackets, twirly brackets, Tuborg brackets (DK), accolades (NL), pointy brackets, or fancy brackets
< > — inequality signs, pointy brackets, or brackets. Sometimes referred to as angle brackets, in such cases as HTML markup. Occasionally known as broken brackets or brokets.[4]
*)
    function WithSqrBrackets: string;
  end;

implementation

uses
  System.StrUtils;

{ TStringHelper }

function TStringHelper.ReplaceTAG(sTagIni, sTagFin, sNewValue: string): string;
var
  tam: Integer;
  sTmp: String;
begin
  Result := '';
  sTmp   := Self;

  while sTmp <> ''  do
  begin
     if ( pos( sTagIni, sTmp ) > 0 ) and ( pos( sTagFin, sTmp ) > 0 ) then
     begin
        tam  := ( Pos( sTagFin, sTmp ) - pos( sTagIni, sTmp) ) - length( sTagIni );
        Self := Copy( sTmp, 1, Pos(sTagFin,sTmp)+ Length(sTagFin)-1 );
        sTmp := Copy( sTmp, Length(Self)+1, Length(sTmp));

        Result  := Result + StuffString( Self, pos(sTagIni, Self) + length( sTagIni ),tam, sNewValue);
     end
     else
     begin
        Result := Result + sTmp;
        sTmp   := '';
     end;
  end;
end;

function TStringHelper.WithSqrBrackets: string;
begin
  Result := '[' + self + ']';
end;

function TStringHelper.GetTAGValue(sTagIni, sTagFin: string): string;
var
  tam: Integer;
begin
  Result := '';
  tam    := ( Pos( sTagFin, Self ) - pos( sTagIni, Self) ) - length( sTagIni );
  Result := Copy(Self, Pos(sTagIni,Self)+length(sTagIni), tam);
end;

end.
