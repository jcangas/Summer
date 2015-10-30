{
  Summer Framework for Delphi http://github.com/jcangas/SummerFW4D
  SummerFW4D by Jorge L. Cangas <jorge.cangas@gmail.com>
  SummerFW4D - Copyright(c) Jorge L. Cangas, Some rights reserved.
  Your reuse is governed by the Creative Commons Attribution 3.0 License
  --------
  Unit BASE: http://www.thedelphigeek.com/2013/03/using-generics-to-manipulate-enumerable.html
}

unit Summer.Enum;

interface

uses Classes;

type
  TEnumRange<T: record> = record
  private
    FCurrentInt: Integer;
    FMaxInt: Integer;
    function GetCurrent: T;
  public
    class function Create: TEnumRange<T>; static;
    function GetEnumerator: TEnumRange<T>;
    function MoveNext: Boolean;
    property Current: T read GetCurrent;
  end;

  TEnumHelper<T: record> = record
  private
    class function InternalToType(const value: Integer): T; overload; static; inline;
  public
    class function MaxInt: Integer; static; inline;
    class function MinInt: Integer; static; inline;

    class function Max: T; static; inline;
    class function Min: T; static; inline;

    class function Clip(const value: Integer): T; overload; static; inline;
    class function Clip(const value: T): T; overload; static; inline;

    class function Ensure(const value: Integer; const min, max: T): T; overload; static; inline;
    class function Ensure(const value, min, max: T): T; overload; static; inline;
    class function Ensure(const value, min, max: Integer): T; overload; static; inline;

    class function Enum: TEnumRange<T>; static; inline;

    class function IsValid(const value: Integer): Boolean; overload; static; inline;
    class function IsValid(const value: T): Boolean; overload; static; inline;

    { Conversor }
    class function ToInt(const value: T): Integer; static; inline;
    class function ToString(const value: T): string; static; inline;

    class function ToType(const value: Integer): T; overload; static; inline;
    class function ToType(const value: string): T; overload; static; inline;
  end;

implementation

uses
  TypInfo,
  Rtti;

{ Range<T> }

class function TEnumHelper<T>.Clip(const value: Integer): T;
begin
  Result := Ensure(value, MinInt, MaxInt);
end;

class function TEnumHelper<T>.Clip(const value: T): T;
begin
  Result := Ensure(value, Min, Max);
end;

class function TEnumHelper<T>.Ensure(const value, min, max: Integer): T;
var
  valInt: Integer;
begin
  valInt := value;
  Assert(min <= max);
  if valInt < min then
    valInt := min;
  if valInt > max then
    valInt := max;
  Result := InternalToType(valInt);
end;

class function TEnumHelper<T>.Ensure(const value: Integer; const min, max: T): T;
begin
  Result := Ensure(value, ToInt(min), ToInt(max));
end;

class function TEnumHelper<T>.Ensure(const value, min, max: T): T;
begin
  Result := Ensure(ToInt(value), ToInt(min), ToInt(max));
end;

class function TEnumHelper<T>.Enum: TEnumRange<T>;
begin
  Result := TEnumRange<T>.Create();
end;

class function TEnumHelper<T>.InternalToType(const value: Integer): T;
begin
  Move(value, Result, SizeOf(Result));
end;

class function TEnumHelper<T>.ToType(const value: string): T;
var
  ItemInt: Integer;
begin
  ItemInt := GetEnumValue(TypeInfo(T), Value);
  Result  := InternalToType(ItemInt);
end;

class function TEnumHelper<T>.ToType(const value: Integer): T;
begin
  if IsValid(value) then
    Result := InternalToType(value)
  else
    Result := Default(T);
end;

class function TEnumHelper<T>.IsValid(const value: Integer): Boolean;
begin
  Result := (value >= MinInt) and (value <= MaxInt);
end;

class function TEnumHelper<T>.IsValid(const value: T): Boolean;
begin
  Result := IsValid(ToInt(value));
end;

class function TEnumHelper<T>.Max: T;
begin
  Result := InternalToType(MaxInt);
end;

class function TEnumHelper<T>.MaxInt: Integer;
begin
  Result := GetTypeData(TypeInfo(T)).MaxValue;
end;

class function TEnumHelper<T>.Min: T;
begin
  Result := InternalToType(MinInt);
end;

class function TEnumHelper<T>.MinInt: Integer;
begin
  Result := GetTypeData(TypeInfo(T)).MinValue;
end;

class function TEnumHelper<T>.ToInt(const value: T): Integer;
begin
  Result := 0;
  Move(value, Result, SizeOf(value));
end;

class function TEnumHelper<T>.ToString(const value: T): string;
var
  rttiVal: TValue;
begin
  rttiVal := TValue.From<T>(value);
  Result := rttiVal.ToString;
end;

{ RangeEnum<T> }

class function TEnumRange<T>.Create: TEnumRange<T>;
begin
  Result.FCurrentInt := TEnumHelper<T>.MinInt - 1;
  Result.FMaxInt := TEnumHelper<T>.MaxInt;
end;

function TEnumRange<T>.GetCurrent: T;
begin
  Result := TEnumHelper<T>.InternalToType(FCurrentInt);
end;

function TEnumRange<T>.GetEnumerator: TEnumRange<T>;
begin
  Result := Self;
end;

function TEnumRange<T>.MoveNext: Boolean;
begin
  Result := FCurrentInt < FMaxInt;
  if Result then
    Inc(FCurrentInt);
end;

end.