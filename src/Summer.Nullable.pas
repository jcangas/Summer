{ == License ==
  - "Summer for Delphi" by Jorge L. Cangas <jorge.cangas@gmail.com> is licensed under CC BY 4.0
  -  Summer for Delphi - http://github.com/jcangas/Summer
  -  Summer - Copyright(c) Jorge L. Cangas, Some rights reserved.
  -  Your reuse is governed by the Creative Commons Attribution 4.0 License http://creativecommons.org/licenses/by/4.0/
}

unit Summer.Nullable;

interface

uses
  System.Rtti,
  System.TypInfo;

type
  PNullable = ^TNullable;

  TNullable = record
  strict private
    FHasValue: Boolean;
  private
    constructor Create(const HasValue: Boolean);
  public
    class function IsNullableType(ATypeInfo: PTypeInfo): Boolean; static;
    class function BaseTypeInfo(ATypeInfo: PTypeInfo): PTypeInfo; static;
    function IsNull: Boolean;
    property HasValue: Boolean read FHasValue write FHasValue;
    class function Null: TValue; static; inline;
  end;

  TNullable<T> = record
  private
    FNullable: TNullable;
    FValue: T;
    function GetValue: T;
    class var FNull: ^TNullable<T>;
  public
    class function Null: TNullable<T>; static; inline;
    class constructor Create;
    constructor Create(const AValue: T);
    property Value: T read GetValue;
    function IsNull: Boolean; inline;
    class function BaseTypeInfo: PTypeInfo; static;
    class operator NotEqual(ALeft, ARight: TNullable<T>): Boolean;
    class operator Equal(ALeft, ARight: TNullable<T>): Boolean;

    class operator Implicit(const Value: T): TNullable<T>;
    class operator Implicit(const Value: TValue): TNullable<T>;
    class operator Implicit(const Value: TNullable<T>): T;
    class operator Implicit(const Value: TNullable<T>): TValue;
  end;

  PNullableString = ^TNullableString;
  TNullableString = TNullable<string>;

  PNullableInteger = ^TNullableInteger;
  TNullableInteger = TNullable<Integer>;

  PNullableBoolean = ^TNullableBoolean;
  TNullableBoolean = TNullable<Boolean>;

  PNullableDate = ^TNullableDate;
  TNullableDate = TNullable<TDate>;

  PNullableTime = ^TNullableTime;
  TNullableTime = TNullable<TTime>;

  PNullableDateTime = ^TNullableDateTime;
  TNullableDateTime = TNullable<TDateTime>;

  PNullableDouble = ^TNullableDouble;
  TNullableDouble = TNullable<Double>;

  PNullableCurrency = ^TNullableCurrency;
  TNullableCurrency = TNullable<Currency>;

  PNullableExtended = ^TNullableExtended;
  TNullableExtended = TNullable<Extended>;

implementation

uses
  System.Generics.Defaults,
  System.SysUtils,
  Summer.Rtti;

{ TNullable<T> }

constructor TNullable<T>.Create(const AValue: T);
begin
  FNullable.Create(True);
  FValue := AValue;
end;

class constructor TNullable<T>.Create;
begin
  New(FNull);
end;

class operator TNullable<T>.Equal(ALeft, ARight: TNullable<T>): Boolean;
var
  Comparer: IEqualityComparer<T>;
begin
  if not ALeft.IsNull and not ARight.IsNull then begin
    Comparer := TEqualityComparer<T>.Default;
    Result := Comparer.Equals(ALeft.Value, ARight.Value);
  end
  else
    Result := ALeft.IsNull = ARight.IsNull;
end;

class operator TNullable<T>.NotEqual(ALeft, ARight: TNullable<T>): Boolean;
begin
  Result := not(ALeft = ARight);
end;

class function TNullable<T>.Null: TNullable<T>;
begin
  Result := FNull^;
end;

class function TNullable<T>.BaseTypeInfo: PTypeInfo;
begin
  Result := System.TypeInfo(T);
end;

function TNullable<T>.GetValue: T;
begin
  if IsNull then
    raise Exception.CreateFmt('Invalid operation, TNullable<%s> is null', [GetTypeName(TypeInfo(T))]);
  Result := FValue;
end;

class operator TNullable<T>.Implicit(const Value: T): TNullable<T>;
begin
  Result := TNullable<T>.Create(Value);
end;

class operator TNullable<T>.Implicit(const Value: TNullable<T>): T;
begin
  Result := Value.Value;
end;

class operator TNullable<T>.Implicit(const Value: TValue): TNullable<T>;

begin
  if Value.IsEmpty then
    Result := TNullable<T>.Null
  else
    Result := TNullable<T>.Create(Value.GetNullable.AsType<T>);
end;

class operator TNullable<T>.Implicit(const Value: TNullable<T>): TValue;
begin
  if Value.IsNull then
    Result := TValue.Empty
  else
    Result := TValue.From<T>(Value.Value);
end;

function TNullable<T>.IsNull: Boolean;
begin
  Result := FNullable.IsNull;
end;

{ TNullable }

constructor TNullable.Create(const HasValue: Boolean);
begin
  FHasValue := HasValue;
end;

class function TNullable.BaseTypeInfo(ATypeInfo: PTypeInfo): PTypeInfo;
begin
  if (ATypeInfo = TypeInfo(TNullableString)) then
    Result := TNullableString.BaseTypeInfo
  else if (ATypeInfo = TypeInfo(TNullableInteger)) then
    Result := TNullableInteger.BaseTypeInfo
  else if (ATypeInfo = TypeInfo(TNullableBoolean)) then
    Result := TNullableBoolean.BaseTypeInfo
  else if (ATypeInfo = TypeInfo(TNullableDate)) then
    Result := TNullableDate.BaseTypeInfo
  else if (ATypeInfo = TypeInfo(TNullableTime)) then
    Result := TNullableTime.BaseTypeInfo
  else if (ATypeInfo = TypeInfo(TNullableDateTime)) then
    Result := TNullableDateTime.BaseTypeInfo
  else if (ATypeInfo = TypeInfo(TNullableDouble)) then
    Result := TNullableDouble.BaseTypeInfo
  else if (ATypeInfo = TypeInfo(TNullableCurrency)) then
    Result := TNullableCurrency.BaseTypeInfo
  else if (ATypeInfo = TypeInfo(TNullableExtended)) then
    Result := TNullableExtended.BaseTypeInfo
  else
    Result := ATypeInfo;
end;

function TNullable.IsNull: Boolean;
begin
  Result := not FHasValue;
end;

class function TNullable.IsNullableType(ATypeInfo: PTypeInfo): Boolean;
begin
  Result := (ATypeInfo = TypeInfo(TNullableString))
    or (ATypeInfo = TypeInfo(TNullableInteger))
    or (ATypeInfo = TypeInfo(TNullableBoolean))
    or (ATypeInfo = TypeInfo(TNullableDate))
    or (ATypeInfo = TypeInfo(TNullableTime))
    or (ATypeInfo = TypeInfo(TNullableDateTime))
    or (ATypeInfo = TypeInfo(TNullableDouble))
    or (ATypeInfo = TypeInfo(TNullableCurrency))
    or (ATypeInfo = TypeInfo(TNullableExtended));
end;

class function TNullable.Null: TValue;
begin
  Result := TValue.Empty;
end;

end.
