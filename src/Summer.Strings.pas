{ Summer for Delphi http://github.com/jcangas/Summer
  Summer by Jorge L. Cangas <jorge.cangas@gmail.com>
  Summer - Copyright(c) Jorge L. Cangas, Some rights reserved.
  Your reuse is governed by the Creative Commons Attribution 3.0 License
}

unit Summer.Strings;

interface

type
  TStringHelper = record helper for string
  public
    /// <summary>
    ///  TAG manipulation. A TAG use two string marks for delimite it
    /// </summary>
    function ReplaceTAG(TagBegin, TagEnd, ReplaceBy: string): string;
    function GetTAGValue(TagBegin, TagEnd: string): string;

    /// <summary>
    ///  several methods to self wrap
    /// </summary>
    function WrapParentheses: string;
    function WrapSqrBrackets: string;
    function WrapAngleBrackets: string;
    function WrapBraces: string;
  end;

implementation

uses
  System.StrUtils;

{ TStringHelper }

function TStringHelper.ReplaceTAG(TagBegin, TagEnd, ReplaceBy: string): string;
var
  TagSize: Integer;
  AuxStr: String;
begin
  Result := '';
  AuxStr := Self;

  while AuxStr <> '' do
  begin
    if (Pos(TagBegin, AuxStr) > 0) and (Pos(TagEnd, AuxStr) > 0) then
    begin
      TagSize := (Pos(TagEnd, AuxStr) - Pos(TagBegin, AuxStr)) - Length(TagBegin);
      Self := Copy(AuxStr, 1, Pos(TagEnd, AuxStr) + Length(TagEnd) - 1);
      AuxStr := Copy(AuxStr, Length(Self) + 1, Length(AuxStr));

      Result := Result + StuffString(Self, Pos(TagBegin, Self) +
        Length(TagBegin), TagSize, ReplaceBy);
    end
    else
    begin
      Result := Result + AuxStr;
      AuxStr := '';
    end;
  end;
end;

function TStringHelper.GetTAGValue(TagBegin, TagEnd: string): string;
var
  TagSIze: Integer;
begin
  Result := '';
  TagSIze := (Pos(TagEnd, Self) - Pos(TagBegin, Self)) - Length(TagBegin);
  Result := Copy(Self, Pos(TagBegin, Self) + Length(TagBegin), TagSIze);
end;

function TStringHelper.WrapAngleBrackets: string;
begin
  Result := '<' + Self + '>';
end;

function TStringHelper.WrapBraces: string;
begin
  Result := '{' + Self + '}';
end;

function TStringHelper.WrapParentheses: string;
begin
  Result := '(' + Self + ')';
end;

function TStringHelper.WrapSqrBrackets: string;
begin
  Result := '[' + Self + ']';
end;

end.
