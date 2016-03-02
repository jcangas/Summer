{== License ==
- "Summer for Delphi" by Jorge L. Cangas <jorge.cangas@gmail.com> is licensed under CC BY 4.0
-  Summer for Delphi - http://github.com/jcangas/Summer
-  Summer - Copyright(c) Jorge L. Cangas, Some rights reserved.
-  Your reuse is governed by the Creative Commons Attribution 4.0 License http://creativecommons.org/licenses/by/4.0/
}

unit Summer.Variants;

interface

type
  /// <summary>
  /// Helper for varianr to DateTime conversion.
  ///  Return argument Def when the variant value is null
  /// </summary>
  VariantHelper = record helper for Variant
  public
    function ToDate(Def: TDate = 0): TDate;
    function ToTime(Def: TTime = 0): TTime;
    function ToDateTime(Def: TDateTime = 0): TDateTime;
  end;

implementation

uses
  System.Variants,
  Summer.DateTime;

{ VariantHelper }

function VariantHelper.ToDate(Def: TDate): TDate;
begin
  Result := Self.ToDateTime(Def).Date;
end;

function VariantHelper.ToTime(Def: TTime): TTime;
begin
  Result := Self.ToDateTime(Def).Time;
end;

function VariantHelper.ToDateTime(Def: TDateTime): TDateTime;
begin
  if VarIsNull(Self) then
  begin
     Result := Def
  end
  else
  begin
     try
        Result := VarToDateTime(Self);
     except
        Result := Def;
     end;
  end;
end;

end.
