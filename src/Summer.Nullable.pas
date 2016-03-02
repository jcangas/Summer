{== License ==
- "Summer for Delphi" by Jorge L. Cangas <jorge.cangas@gmail.com> is licensed under CC BY 4.0
-  Summer for Delphi - http://github.com/jcangas/Summer
-  Summer - Copyright(c) Jorge L. Cangas, Some rights reserved.
-  Your reuse is governed by the Creative Commons Attribution 4.0 License http://creativecommons.org/licenses/by/4.0/
}

unit Summer.Nullable;

interface
uses
 System.TypInfo;

type
  PNullable = ^TNullable;
  TNullable = record
  private
    FHasValue: Boolean;
  public
    constructor Create(const HasValue: Boolean);
    function IsNull: Boolean;
    property HasValue: Boolean read FHasValue write FHasValue;
  end;

  TNullable<T> = record
  private
    FNullable: TNullable;
    FValue: T;
    function GetValue: T;
  public
    constructor Create(const AValue: T);
    property Value: T read GetValue;
    function IsNull: Boolean;

    class operator NotEqual(ALeft, ARight: TNullable<T>): Boolean;
    class operator Equal(ALeft, ARight: TNullable<T>): Boolean;

    class operator Implicit(const Value: T): TNullable<T>;
    class operator Implicit(const Value: TNullable<T>): T;
  end;

  TNullableString = TNullable<string>;
  TNullableInteger = TNullable<Integer>;
  TNullableBoolean = TNullable<Boolean>;
  TNullableDate = TNullable<TDate>;
  TNullableTime = TNullable<TTime>;
  TNullableDateTime = TNullable<TDateTime>;
  TNullableDouble = TNullable<Double>;
  TNullableCurrency = TNullable<Currency>;
  TNullableExtended = TNullable<Extended>;



implementation
uses
  System.Generics.Defaults,
  System.SysUtils,
  System.Rtti;


{ TNullable<T> }

constructor TNullable<T>.Create(const AValue: T);
begin
  FNullable.Create(True);
  FValue := AValue;
end;

class operator TNullable<T>.Equal(ALeft, ARight: TNullable<T>): Boolean;
var
  Comparer: IEqualityComparer<T>;
begin
  if not ALeft.IsNull and not ARight.IsNull then
  begin
    Comparer := TEqualityComparer<T>.Default;
    Result := Comparer.Equals(ALeft.Value, ARight.Value);
  end
  else
    Result := ALeft.IsNull = ARight.IsNull;
end;

class operator TNullable<T>.NotEqual(ALeft, ARight: TNullable<T>): Boolean;
var
  Comparer: IEqualityComparer<T>;
begin
  if not ALeft.IsNull and not ARight.IsNull then
  begin
    Comparer := TEqualityComparer<T>.Default;
    Result := not Comparer.Equals(ALeft.Value, ARight.Value);
  end
  else
    Result := ALeft.IsNull <> ARight.IsNull;
end;

function TNullable<T>.GetValue: T;
begin
  if IsNull then
    raise Exception.CreateFmt('Invalid operation, TNullable<> is null', [GetTypeName(TypeInfo(T))]);
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

function TNullable<T>.IsNull: Boolean;
begin
  Result := FNullable.IsNull;
end;

{ TNullable }

constructor TNullable.Create(const HasValue: Boolean);
begin
  FHasValue := HasValue;
end;

function TNullable.IsNull: Boolean;
begin
  Result := not FHasValue;
end;

end.

