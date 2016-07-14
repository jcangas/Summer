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
{$M+}
  PNullable = ^TNullable;

  /// <summary> Tipo para manipular un Nullable asbtracto, simulando
  ///  herencia con records. Los nullables concretos "extienden" este tipo
  /// Ver TNullable<T>
  ///  </summary>
  TNullable = record
  strict private
    FHasValue: Boolean;
    class var FNullableTypes: array of PTypeInfo;
    class var FNullableBaseTypes: array of PTypeInfo;
  private
    constructor Create(const HasValue: Boolean);
    class procedure RegisterNullableType(ATypeInfo: PTypeInfo; ABaseTypeInfo: PTypeInfo); static;
    class function IndexOfNullableType(ATypeInfo: PTypeInfo): Integer; static;
  public
    class constructor Create;
    class function IsNullableType(ATypeInfo: PTypeInfo): Boolean; static;
    class function BaseTypeInfo(ATypeInfo: PTypeInfo): PTypeInfo; static;
    function IsNull: Boolean;
    property HasValue: Boolean read FHasValue write FHasValue;
    class function Null: TValue; static; inline;
  end;

  /// <summary> Tipo genérico para crear Nullables concretos. Para simular
  ///  herencia, notar que el **primer** campo es TNullable
  /// </summary>
  TNullable<T> = record
  private
    FNullable: TNullable;
    FValue: T;
    function GetValue: T;
    class var FNull: ^TNullable<T>;
  public
  /// <summary> Devuelve el valor Null para este TNullable<T>
  /// </summary>
    class function Null: TNullable<T>; static; inline;
  /// <summary> Inicializa el valor Null de este TNullable<T>
  /// </summary>
    class constructor Create;

    constructor Create(const AValue: T);
  /// <summary> Devuelve el valor T contenido en el nullable.
  ///  Levanta exception si es null
  /// </summary>
    property Value: T read GetValue;
    function IsNull: Boolean; inline;

  /// <summary> Retorna TypeInfo(T)
  /// </summary>
    class function BaseTypeInfo: PTypeInfo; static;

    class operator NotEqual(ALeft, ARight: TNullable<T>): Boolean;
    class operator Equal(ALeft, ARight: TNullable<T>): Boolean;
    class operator Implicit(const Value: T): TNullable<T>;
    class operator Implicit(const Value: TValue): TNullable<T>;
    class operator Implicit(const Value: TNullable<T>): T;
    class operator Implicit(const Value: TNullable<T>): TValue;
  end;

{$REGION 'Tipos nullables predefinidos'}
  PNullableString = ^TNullableString;
  TNullableString = TNullable<string>;

  PNullableByte = ^TNullableByte;
  TNullableByte = TNullable<Byte>;

  PNullableWord = ^TNullableWord;
  TNullableWord = TNullable<Word>;

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
{$ENDREGION}

{$M-}

resourcestring
  CannotConvertNull = 'TNullable: cannot convert null to %s';

implementation

uses
  System.Generics.Defaults,
  System.SysUtils,
  Summer.Rtti;

{ TNullable }

class constructor TNullable.Create;
begin
  SetLength(FNullableTypes, 0);
  SetLength(FNullableBaseTypes, 0);
end;

class procedure TNullable.RegisterNullableType(ATypeInfo: PTypeInfo; ABaseTypeInfo: PTypeInfo);
begin
  FNullableTypes := FNullableTypes + [ATypeInfo];
  FNullableBaseTypes := FNullableBaseTypes + [ABaseTypeInfo];
end;

class function TNullable.IndexOfNullableType(ATypeInfo: PTypeInfo): Integer;
var
  idx: Integer;
begin
  for idx := 0 to High(FNullableTypes) do
    if FNullableTypes[idx] = ATypeInfo then
      Exit(idx);
  Result := -1;
end;

class function TNullable.IsNullableType(ATypeInfo: PTypeInfo): Boolean;
begin
  Result := IndexOfNullableType(ATypeInfo) > -1;
end;

class function TNullable.Null: TValue;
begin
  Result := TValue.Empty;
end;

class function TNullable.BaseTypeInfo(ATypeInfo: PTypeInfo): PTypeInfo;
var
  idx: Integer;
begin
  idx := IndexOfNullableType(ATypeInfo);
  if idx = -1 then Exit(ATypeInfo);
  Result := FNullableBaseTypes[idx];
end;

constructor TNullable.Create(const HasValue: Boolean);
begin
  FHasValue := HasValue;
end;

function TNullable.IsNull: Boolean;
begin
  Result := not FHasValue;
end;

{ TNullable<T> }

constructor TNullable<T>.Create(const AValue: T);
begin
  FNullable.Create(True);
  FValue := AValue;
end;

class constructor TNullable<T>.Create;
begin
  TNullable.RegisterNullableType(System.TypeInfo(TNullable<T>), System.TypeInfo(T));
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
    raise Exception.CreateFmt(CannotConvertNull, [GetTypeName(TypeInfo(T))]);
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

end.





