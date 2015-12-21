unit Summer.Variants;

interface

type
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
