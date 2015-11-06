{
  Summer Framework for Delphi http://github.com/jcangas/SummerFW4D
  SummerFW4D by Jorge L. Cangas <jorge.cangas@gmail.com>
  SummerFW4D - Copyright(c) Jorge L. Cangas, Some rights reserved.
  Your reuse is governed by the Creative Commons Attribution 3.0 License
}

unit Summer.JSON;

interface

uses
  System.Rtti,
  System.JSON,
  System.SysUtils,
  System.Character,
  Data.DB;

{$SCOPEDENUMS ON}

type
  JSONAttribute = class(TCustomAttribute)
  private
    FNames: TArray<string>;
    FSelect: Boolean;
    FEmbed: Boolean;
    FFormatName: string;
  public
    constructor Create(const Select: Boolean; const Names: string = ''); overload;
    constructor Create(const Names: string = ''); overload;
    constructor Create(const Names: string; Embed: Boolean; FormatName: string = '%s'); overload;
    constructor Create(const Select: Boolean; const Names: string; Embed: Boolean; FormatName: string = '%s'); overload;
    function Accept(const Name: string): Boolean;
    function HasNames: Boolean;
    property Names: TArray<string> read FNames;
    property Select: Boolean read FSelect;
    property Embed: Boolean read FEmbed;
    property FormatName: string read FFormatName;
  end;

  TJSON = class
  public type
    SupportedTypes = (TNone, // 00
      TString, // 01
      TInteger, // 02
      TFloat, // 03
      TBoolean, // 04
      TDateTime, // 05
      TDate, // 06
      TTime // 07
      );

    // Ej para el dia y hora: "22/04/2015 - 09:53:59.784"
    DateTimeFormat = (Simple, // 2015-04-22T09:53:59.784
      UTC, // 2015-04-22T07:53:59.784Z
      ISO8601 // 2015-04-22T09:53:59.784+02:00
      );

    JSONError = class(Exception);
  protected
    class function StrJSONToFloat(Value: string): Double;
    class function Error(Msg: string; Args: array of const): JSONError;
  public
    class function UnSuportedType(TypeName: string): JSONError;

    class function ToJSON(const Value: TValue): TJSONValue; overload;
    class function ToJSON(const AObject: TObject; Select: JSONAttribute = nil): TJSONValue; overload;
    class function ToJSONObject(const AObject: TObject; Select: JSONAttribute = nil): TJSONObject;
    class function ToJSONArray(const ObjectList; Select: JSONAttribute = nil): TJSONArray;

    class function TryJSONAttr(AClass: TClass; out Found: JSONAttribute): Boolean; overload;
    class function TryJSONAttr(Prop: TRttiObject; out Found: JSONAttribute): Boolean; overload;

    { DateTime to String }
    class function DateTimeToJSON(const Value: TDateTime; TipoFormat: DateTimeFormat = DateTimeFormat.Simple): string; overload;
    class function DateToJSON(const Value: TDate): string; overload;
    class function TimeToJSON(const Value: TTime; TipoFormat: DateTimeFormat = DateTimeFormat.Simple): string; overload;

    { String to DateTime }
    class function DateTimeFromJSON(const Value: string; UseLocalTime: Boolean = True): TDateTime; overload;
    class function DateFromJSON(const Value: string): TDate; overload;
    class function TimeFromJSON(const Value: string; UseLocalTime: Boolean = True): TTime; overload;

    { StringJSON to TValue }
    class function StrJSONToTValue(ValueType: SupportedTypes; Value: string): TValue;

    { DataSet to JSON }
    class function DataSetToJSON(DataSet: TDataSet): TJSONObject;

    { JSON Pretty Print }
    class function PrettyPrint(const value : TJSONValue; const IdentString : string = '  ') : string;

  end;

implementation

uses
  System.Generics.Collections,
  System.DateUtils,
  Summer.Nullable,
  Summer.Rtti,
  Summer.JSONProperties,
  Summer.DateTime,
  Summer.Enum,
  Summer.Utils,
  System.StrUtils;

resourcestring
  StrUnSuportedType = 'Tipo no soportado: %s';

type
  { ---------------------------------------------------------
    Basado en:
    https://github.com/ahausladen/JsonDataObjects
    http://www.w3.org/TR/NOTE-datetime
    http://www.horamundial.com/
    --------------------------------------------------------- }
  TDateTimeJSON = class
  private
    class function ParseDateTimePart(P: PChar; var Value: Integer; MaxLen: Integer): PChar;
  protected
    class function FixDateIFEmpty(Value: TDateTime): TDateTime;

    class function UTCDateTime_To_LocalDateTime(UTCDateTime: TDateTime): TDateTime;
    class function LocalDateTime_To_UTCDateTime(LocalDateTime: TDateTime): TDateTime;

    class function DateToISO8601(Value: TDate): string;
    class function TimeToISO8601(Value: TDateTime): string;
    class function TimeToSimple(Value: TTime): string;

    class function InternalTimeToJSON(const Value: TDateTime; TipoFormat: TJSON.DateTimeFormat = TJSON.DateTimeFormat.Simple): string;
    // La diferencia del no internal, es que aqui revibimos tambien la fecha.
    class function InternalTimeFromJSON(const Value: string; const dFecha: TDate; UseLocalTime: Boolean = True): TTime; overload;
  public
    { DateTime to String }
    class function DateTimeToJSON(const Value: TDateTime; TipoFormat: TJSON.DateTimeFormat = TJSON.DateTimeFormat.Simple): string; overload;
    class function DateToJSON(const Value: TDate): string; overload;
    class function TimeToJSON(const Value: TTime; TipoFormat: TJSON.DateTimeFormat = TJSON.DateTimeFormat.Simple): string; overload;

    { String to DateTime }
    class function DateTimeFromJSON(const Value: string; UseLocalTime: Boolean = True): TDateTime; overload;
    class function DateFromJSON(const Value: string): TDate; overload;
    class function TimeFromJSON(const Value: string; UseLocalTime: Boolean = True): TTime; overload;
  end;

  TDataSetJSON = class
  private
    class function FieldTypeToDTOColumnType(FieldType: TFieldType): TJSON.SupportedTypes;
  protected
    class function ToJSONFieldsDef(DataSet: TDataSet): TJSONObject;
    class function ToJSONValues(DataSet: TDataSet): TJSONArray; // All Lines
    class function ToJSONValue(DataSet: TDataSet): TJSONObject; // Current Line
  public
    class function ToJSON(DataSet: TDataSet): TJSONObject;
  end;

const
  // Ej: UTC = True:  "2015-04-09T16:05:15.371Z"
  // Ej: UTC = False: "2015-04-09T18:05:15.371+02:00"

  _AnoNeg = '-';
  _SepMes = '-';
  _SepDia = '-';
  _SepTimpo = 'T';
  _SepMin = ':';
  _SepSeg = ':';
  _SepMSeg = '.';
  _DefineUTC = 'Z';

  _ZonaPostiva = '+';
  _ZonaNegativa = '-';
  _SepOffsetMin = ':';

  _FormatFecha = '%.4d-%.2d-%.2d';
  _FormatHora = '%.2d:%.2d:%.2d.%d';
  _FormatHoraUTC = _FormatHora + _DefineUTC;

  _FormatZonaPostiva = '%s' + _ZonaPostiva + '%.2d:%.2d';
  _FormatZonaNegativa = '%s' + _ZonaNegativa + '%.2d:%.2d';

  { JSONAttribute }

constructor JSONAttribute.Create(const Names: string);
begin
  Create(True, Names, False);
end;

constructor JSONAttribute.Create(const Select: Boolean; const Names: string = '');
begin
  Create(Select, Names, False);
end;

constructor JSONAttribute.Create(const Names: string; Embed: Boolean; FormatName: string);
begin
  Create(True, Names, Embed, FormatName);
end;

constructor JSONAttribute.Create(const Select: Boolean; const Names: string; Embed: Boolean; FormatName: string);
begin
  inherited Create;
  FSelect := Select;
  FNames := Names.Split([';']);
  FEmbed := Embed;
  FFormatName := FormatName;
end;

function JSONAttribute.HasNames: Boolean;
begin
  Result := Length(FNames) > 0;
end;

function JSONAttribute.Accept(const Name: string): Boolean;
var
  Item: string;
begin
  Result := not HasNames;
  for Item in Names do
    if SameText(Item, name) then begin
      Result := True;
      Break;
    end;

  if not Select then
    Result := not Result;
end;

{ TDateTimeJSON }

class function TDateTimeJSON.DateTimeToJSON(const Value: TDateTime; TipoFormat: TJSON.DateTimeFormat = TJSON.DateTimeFormat.Simple): string;
begin
  Result := Self.DateToJSON(Value) + _SepTimpo + Self.InternalTimeToJSON(Value, TipoFormat); // Importante aqui llamar el internalTime, porque pasa tb la fecha.
end;

class function TDateTimeJSON.DateToJSON(const Value: TDate): string;
var
  Year, Month, Day: Word;
begin
  DecodeDate(Value, Year, Month, Day);
  Result := Format(_FormatFecha, [Year, Month, Day]);
end;

class function TDateTimeJSON.TimeToJSON(const Value: TTime; TipoFormat: TJSON.DateTimeFormat = TJSON.DateTimeFormat.Simple): string;
begin
  Result := Self.InternalTimeToJSON(Value, TipoFormat);
end;

class function TDateTimeJSON.InternalTimeToJSON(const Value: TDateTime; TipoFormat: TJSON.DateTimeFormat = TJSON.DateTimeFormat.Simple): string;
var
  UtcTime: TDateTime;
  Hour, Minute, Second, Milliseconds: Word;
begin
  if (TipoFormat = TJSON.DateTimeFormat.UTC) then begin
    UtcTime := LocalDateTime_To_UTCDateTime(Value);
    DecodeTime(UtcTime, Hour, Minute, Second, Milliseconds);
    Result := Format(_FormatHoraUTC, [Hour, Minute, Second, Milliseconds]);
  end
  else if (TipoFormat = TJSON.DateTimeFormat.ISO8601) then begin
    Result := TimeToISO8601(Value);
  end
  else // if (TipoFormat = DateTimeFormat.Simple) then
  begin
    Result := TimeToSimple(Value);
  end;
end;

class function TDateTimeJSON.DateTimeFromJSON(const Value: string; UseLocalTime: Boolean = True): TDateTime;
var
  sTime: string;
  iPos: Integer;
begin
  Result := 0;
  if Value.IsEmpty then
    Exit;

  // Fecha
  Result := Self.DateFromJSON(Value);

  // Time
  iPos := System.Pos(_SepTimpo, Value);
  if iPos > 0 then begin
    sTime := Copy(Value, iPos + 1, Length(Value));
    Result := Trunc(Result) + Frac(Self.InternalTimeFromJSON(sTime, Result, UseLocalTime)); // Unimos Fecha+Hora
  end;
end;

class function TDateTimeJSON.DateFromJSON(const Value: string): TDate;
var
  P: PChar;
  Year, Month, Day: Integer;
begin
  Result := 0;
  if Value.IsEmpty then
    Exit;

  P := PChar(Value);

  Year := 0;
  Month := 0;
  Day := 0;

  if P^ = _AnoNeg then // negative year
    Inc(P);
  P := ParseDateTimePart(P, Year, 4);

  if P^ <> _SepMes then
    Exit; // invalid format
  P := ParseDateTimePart(P + 1, Month, 2);

  if P^ <> _SepDia then
    Exit; // invalid format
  ParseDateTimePart(P + 1, Day, 2);

  Result := EncodeDate(Year, Month, Day);
end;

class function TDateTimeJSON.TimeFromJSON(const Value: string; UseLocalTime: Boolean): TTime;
begin
  Result := Self.InternalTimeFromJSON(Value, 0, UseLocalTime);
end;

class function TDateTimeJSON.InternalTimeFromJSON(const Value: string; const dFecha: TDate; UseLocalTime: Boolean): TTime;
var
  P: PChar;
  Hour, Min, Sec, MSec: Integer;
  OffsetHour, OffsetMin: Integer;
  Sign: Double;
  TipoFormat: TJSON.DateTimeFormat;
  dFullFecha: TDateTime;
begin
  Result := 0;
  if Value.IsEmpty then
    Exit;

  P := PChar(Value);

  Hour := 0;
  Min := 0;
  Sec := 0;
  MSec := 0;

  P := ParseDateTimePart(P, Hour, 2);

  if P^ <> _SepMin then
    Exit; // invalid format
  P := ParseDateTimePart(P + 1, Min, 2);

  if P^ = _SepSeg then begin
    P := ParseDateTimePart(P + 1, Sec, 2);

    if P^ = _SepMSeg then
      P := ParseDateTimePart(P + 1, MSec, 3);
  end;

  Result := EncodeTime(Hour, Min, Sec, MSec);

  // Recuperamos el tipo.
  if (P^ = _DefineUTC) then
    TipoFormat := TJSON.DateTimeFormat.UTC
  else if ((P^ <> _DefineUTC) and ((P^ = _ZonaPostiva) or (P^ = _ZonaNegativa))) then
    TipoFormat := TJSON.DateTimeFormat.ISO8601
  else
    TipoFormat := TJSON.DateTimeFormat.Simple;

  // Si esta en ISO lo convertimos a UTC.
  if (TipoFormat = TJSON.DateTimeFormat.ISO8601) then begin
    if P^ = _ZonaPostiva then
      Sign := -1 // +0100 means that the time is 1 hour later than UTC
    else
      Sign := 1;

    P := ParseDateTimePart(P + 1, OffsetHour, 2);
    if P^ = _SepOffsetMin then
      Inc(P);
    ParseDateTimePart(P, OffsetMin, 2);

    Result := Result + (EncodeTime(OffsetHour, OffsetMin, 0, 0) * Sign);
  end;

  // UseLocalTime solo se aplica si la string esta en formato: UTC o ISO, si esta en SIMPLE no hace falta hacer nada.
  if (TipoFormat <> TJSON.DateTimeFormat.Simple) and (UseLocalTime) then begin
    if (dFecha > 0) then
      dFullFecha := Trunc(dFecha) + Frac(Result)
    else
      dFullFecha := Result;

    Result := UTCDateTime_To_LocalDateTime(dFullFecha);
  end;
end;

class function TDateTimeJSON.UTCDateTime_To_LocalDateTime(UTCDateTime: TDateTime): TDateTime;
begin
  UTCDateTime := Self.FixDateIFEmpty(UTCDateTime);
  Result := TTimeZone.Local.ToLocalTime(UTCDateTime);
end;

class function TDateTimeJSON.LocalDateTime_To_UTCDateTime(LocalDateTime: TDateTime): TDateTime;
begin
  LocalDateTime := Self.FixDateIFEmpty(LocalDateTime);
  Result := TTimeZone.Local.ToUniversalTime(LocalDateTime);
end;

class function TDateTimeJSON.DateToISO8601(Value: TDate): string;
var
  Year, Month, Day: Word;
begin
  DecodeDate(Value, Year, Month, Day);
  Result := Format(_FormatFecha, [Year, Month, Day]);
end;

class function TDateTimeJSON.TimeToISO8601(Value: TDateTime): string;
var
  Offset: TDateTime;
  Hour, Minute, Second, Milliseconds: Word;
begin
  Value := Self.FixDateIFEmpty(Value);

  DecodeTime(Value, Hour, Minute, Second, Milliseconds);
  Result := Format(_FormatHora, [Hour, Minute, Second, Milliseconds]);

  Offset := Value - LocalDateTime_To_UTCDateTime(Value);
  DecodeTime(Offset, Hour, Minute, Second, Milliseconds);

  if Offset < 0 then
    Result := Format(_FormatZonaNegativa, [Result, Hour, Minute]) // (-)
  else if Offset > 0 then
    Result := Format(_FormatZonaPostiva, [Result, Hour, Minute]) // (+)
  else
    Result := Result + _DefineUTC;
end;

class function TDateTimeJSON.TimeToSimple(Value: TTime): string;
var
  Hour, Minute, Second, Milliseconds: Word;
begin
  DecodeTime(Value, Hour, Minute, Second, Milliseconds);
  Result := Format(_FormatHora, [Hour, Minute, Second, Milliseconds]);
end;

class function TDateTimeJSON.FixDateIFEmpty(Value: TDateTime): TDateTime;
var
  dFecha: TDate;
  dTime: TTime;
begin
  dFecha := Trunc(Value);
  dTime := Frac(Value);

  if dFecha <= 0 then // Si no tenemos la fecha, ponemos la fecha actual.
    dFecha := Now;

  Result := Trunc(dFecha) + Frac(dTime);
end;

class function TDateTimeJSON.ParseDateTimePart(P: PChar; var Value: Integer; MaxLen: Integer): PChar;
var
  V: Integer;
begin
  Result := P;
  V := 0;

  while Result^.IsDigit and (MaxLen > 0) do
  begin
    V := V * 10 + (Ord(Result^) - Ord('0'));
    Inc(Result);
    Dec(MaxLen);
  end;

  Value := V;
end;

{ TDataSetJSON }

class function TDataSetJSON.FieldTypeToDTOColumnType(FieldType: TFieldType): TJSON.SupportedTypes;
begin
  { resumimos en unos cuantos }
  if FieldType in [TFieldType.ftString, TFieldType.ftFixedChar, TFieldType.ftWideString, TFieldType.ftGuid, TFieldType.ftFixedWideChar] then begin
    Result := TJSON.SupportedTypes.TString;
  end
  else if FieldType in [TFieldType.ftSmallint, TFieldType.ftInteger, TFieldType.ftAutoInc, TFieldType.ftLargeint, TFieldType.ftShortint, TFieldType.ftSingle]
  then begin
    Result := TJSON.SupportedTypes.TInteger;
  end
  else if FieldType in [TFieldType.ftFloat, TFieldType.ftCurrency, TFieldType.ftBCD, TFieldType.ftFMTBcd, TFieldType.ftWord, TFieldType.ftLongWord,
    TFieldType.ftExtended] then begin
    Result := TJSON.SupportedTypes.TFloat;
  end
  else if FieldType in [TFieldType.ftBoolean] then begin
    Result := TJSON.SupportedTypes.TBoolean;
  end
  else if FieldType in [TFieldType.fTDateTime, TFieldType.ftTimeStamp, TFieldType.ftTimeStampOffset] then begin
    Result := TJSON.SupportedTypes.TDateTime;
  end
  else if FieldType in [TFieldType.ftDate] then begin
    Result := TJSON.SupportedTypes.TDate;
  end
  else if FieldType in [TFieldType.ftTime] then begin
    Result := TJSON.SupportedTypes.TTime;
  end
  else begin
    raise TJSON.UnSuportedType(TEnumHelper<TFieldType>.ToString(FieldType));
  end;
end;

class function TDataSetJSON.ToJSON(DataSet: TDataSet): TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('Fields', Self.ToJSONFieldsDef(DataSet));
  Result.AddPair('Values', Self.ToJSONValues(DataSet));
end;

class function TDataSetJSON.ToJSONFieldsDef(DataSet: TDataSet): TJSONObject;
var
  Field: TField;
  ColJSONType: TJSON.SupportedTypes;
begin
  Result := TJSONObject.Create;

  for Field in DataSet.Fields do begin
    ColJSONType := Self.FieldTypeToDTOColumnType(Field.DataType);
    Result.AddPair(Field.FieldName, TEnumHelper<TJSON.SupportedTypes>.ToString(ColJSONType));
  end;
end;

class function TDataSetJSON.ToJSONValues(DataSet: TDataSet): TJSONArray;
var
  LBookmark: TBookmark;
begin
  Result := TJSONArray.Create;

  if not DataSet.IsEmpty then begin
    DataSet.DisableControls;
    try
      LBookmark := DataSet.Bookmark;
      try
        DataSet.First;
        while not DataSet.Eof do begin
          Result.AddElement(Self.ToJSONValue(DataSet));
          DataSet.Next;
        end;
      finally
        if DataSet.BookmarkValid(LBookmark) then
          DataSet.GotoBookmark(LBookmark);

        DataSet.FreeBookmark(LBookmark);
      end;
    finally
      DataSet.EnableControls;
    end;
  end;
end;

class function TDataSetJSON.ToJSONValue(DataSet: TDataSet): TJSONObject;
var
  Field: TField;
  SuportedType: TJSON.SupportedTypes;
begin
  Result := TJSONObject.Create;

  for Field in DataSet.Fields do begin
    if Field.IsNull then begin
      Result.AddPair(Field.FieldName, TJSONNull.Create);
    end
    else begin
      SuportedType := Self.FieldTypeToDTOColumnType(Field.DataType);

      if (SuportedType = TJSON.SupportedTypes.TString) then begin
        Result.AddPair(Field.FieldName, Field.AsWideString);
      end
      else if (SuportedType = TJSON.SupportedTypes.TInteger) then begin
        Result.AddPair(Field.FieldName, TJSONNumber.Create(Field.AsLargeInt));
      end
      else if (SuportedType = TJSON.SupportedTypes.TFloat) then begin
        Result.AddPair(Field.FieldName, TJSONNumber.Create(Field.AsFloat));
      end
      else if (SuportedType = TJSON.SupportedTypes.TBoolean) then begin
        if Field.AsBoolean then
          Result.AddPair(Field.FieldName, TJSONTrue.Create)
        else
          Result.AddPair(Field.FieldName, TJSONFalse.Create);
      end
      else if (SuportedType = TJSON.SupportedTypes.TDateTime) then begin
        Result.AddPair(Field.FieldName, Field.AsDateTime.ToJSON);
      end
      else if (SuportedType = TJSON.SupportedTypes.TDate) then begin
        Result.AddPair(Field.FieldName, Field.AsDateTime.Date.ToJSON);
      end
      else if (SuportedType = TJSON.SupportedTypes.TTime) then begin
        Result.AddPair(Field.FieldName, Field.AsDateTime.Time.ToJSON);
      end
      else begin
        raise TJSON.UnSuportedType(TEnumHelper<TJSON.SupportedTypes>.ToString(SuportedType));
      end;
    end;
  end;
end;

{ TJSON }

class function TJSON.ToJSON(const AObject: TObject; Select: JSONAttribute = nil): TJSONValue;
begin
  if AObject = nil then
    Result := TJSONNull.Create
  else if AObject.InheritsFrom(TJSONValue) then
    Result := AObject as TJSONValue
  else if AObject.IsObjList then
    Result := ToJSONArray(AObject, Select)
  else
    Result := ToJSONObject(AObject, Select);
end;

class function TJSON.ToJSON(const Value: TValue): TJSONValue;
var
  Aux: TValue;
begin
  with Value do begin
    if IsEmpty then
      Result := TJSONNull.Create
    else if TryGetNullable(Aux) then
      Result := ToJSON(Aux)
    else if IsString then begin
      Result := TJSONString.Create(AsString)
    end
    else if IsBoolean then begin
      if AsBoolean then
        Result := TJSONTrue.Create
      else
        Result := TJSONFalse.Create;
    end
    else if IsTime then
      Result := TJSONString.Create(Value.AsTime.ToJSON)
    else if IsDate then
      Result := TJSONString.Create(Value.AsDate.ToJSON)
    else if IsDateTime then
      Result := TJSONString.Create(Value.AsDateTime.ToJSON)
    else if IsInteger then
      Result := TJSONNumber.Create(AsInt64)
    else if IsFloat then
      Result := TJSONNumber.Create(AsExtended)
    else if IsObject then
      Result := TJSON.ToJSON(AsObject)
    else if IsArray then
      Result := ArrayToJSON
    else
      Result := TJSONString.Create(ToString)
  end;
end;

class function TJSON.ToJSONArray(const ObjectList; Select: JSONAttribute = nil): TJSONArray;
var
  List: TObjectList<TObject>;
  Elem: TObject;
begin
  List := TObjectList<TObject>(ObjectList);
  Result := TJSONArray.Create;
  if List = nil then
  Exit;
  for Elem in List do
    Result.AddElement(TJSON.ToJSONObject(Elem, Select));
end;

class function TJSON.ToJSONObject(const AObject: TObject; Select: JSONAttribute = nil): TJSONObject;

  procedure AddProps(const FromObj: TObject; var ToJsonObj: TJSONObject; Select: JSONAttribute);
  var
    RContext: TRTTIContext;
    V: TValue;
    RTSource: TRttiInstanceType;
    PropSource: TRttiProperty;
    ClassAttr: JSONAttribute;
    PropAttr: JSONAttribute;
    RefObj: TObject;
    FmtPropName: string;
  begin
    TryJSONAttr(FromObj.ClassType, ClassAttr);
    RTSource := RContext.GetType(FromObj.ClassType) as TRttiInstanceType;

    if ToJsonObj = nil then
      ToJsonObj := TJSONObject.Create;

    ToJsonObj.AddPair(TJSONPair.Create('$type', FromObj.ClassType.QualifiedClassName));
    for PropSource in RTSource.GetProperties do begin
      if Assigned(Select) and not Select.Accept(PropSource.Name) then
        Continue;

      TryJSONAttr(PropSource, PropAttr);

      if Assigned(PropAttr) then begin
        if PropSource.PropertyType.IsPlainType then begin
          if not PropAttr.Select then
            Continue;
        end
        else if not PropAttr.HasNames then begin
          if not PropAttr.Select then
            Continue;
        end;
      end
      else if Assigned(ClassAttr) and not ClassAttr.Accept(PropSource.Name) then
        Continue;

      V := PropSource.GetValue(FromObj);

      if Assigned(Select) then
        FmtPropName := Select.FormatName
      else
        FmtPropName := '%s';
      FmtPropName := Format(FmtPropName, [PropSource.Name]);

      if not V.IsObject or V.IsEmpty or V.AsObject.InheritsFrom(TJSONValue) then
        ToJsonObj.AddPair(TJSONPair.Create(FmtPropName, ToJSON(V)))
      else begin
        RefObj := V.AsObject;
        if not RefObj.IsObjList and Assigned(PropAttr) and PropAttr.Embed then
          AddProps(RefObj, ToJsonObj, PropAttr)
        else
          ToJsonObj.AddPair(TJSONPair.Create(FmtPropName, ToJSON(RefObj, PropAttr)))
      end;
    end;
  end;

begin
  Result := nil;

  if AObject = nil then
    Exit;

  if AObject is TJSONObject then
    Exit(AObject as TJSONObject);

  if AObject is TJSONProperties then
    Exit((AObject as TJSONProperties).AsObject.Clone as TJSONObject);

  AddProps(AObject, Result, Select);
end;

class function TJSON.TryJSONAttr(AClass: TClass; out Found: JSONAttribute): Boolean;
var
  RContext: TRTTIContext;
begin
  Result := TryJSONAttr(RContext.GetType(AClass), Found)
end;

class function TJSON.TryJSONAttr(Prop: TRttiObject; out Found: JSONAttribute): Boolean;
var
  Attr: TCustomAttribute;
begin
  Result := False;
  Found := nil;
  for Attr in Prop.GetAttributes do begin
    if Attr.InheritsFrom(JSONAttribute) then begin
      Found := JSONAttribute(Attr);
      Exit(True);
    end;
  end;
end;

class function TJSON.DateTimeToJSON(const Value: TDateTime; TipoFormat: DateTimeFormat): string;
begin
  Result := TDateTimeJSON.DateTimeToJSON(Value, TipoFormat);
end;

class function TJSON.DateToJSON(const Value: TDate): string;
begin
  Result := TDateTimeJSON.DateToJSON(Value);
end;

class function TJSON.TimeToJSON(const Value: TTime; TipoFormat: DateTimeFormat): string;
begin
  Result := TDateTimeJSON.TimeToJSON(Value, TipoFormat);
end;

class function TJSON.DateTimeFromJSON(const Value: string; UseLocalTime: Boolean): TDateTime;
begin
  Result := TDateTimeJSON.DateTimeFromJSON(Value, UseLocalTime);
end;

class function TJSON.DateFromJSON(const Value: string): TDate;
begin
  Result := TDateTimeJSON.DateFromJSON(Value);
end;

class function TJSON.TimeFromJSON(const Value: string; UseLocalTime: Boolean): TTime;
begin
  Result := TDateTimeJSON.TimeFromJSON(Value, UseLocalTime);
end;

class function TJSON.StrJSONToFloat(Value: string): Double;
var
  JSONNumber: TJSONNumber;
begin
  JSONNumber := TJSONNumber.Create(Value);
  try
    Result := JSONNumber.AsDouble;
  finally
    FreeAndNil(JSONNumber);
  end;
end;

class function TJSON.Error(Msg: string; Args: array of const): JSONError;
begin
  Result := JSONError.CreateFmt(Msg, Args);
end;

class function TJSON.UnSuportedType(TypeName: string): JSONError;
begin
  Result := Self.Error(StrUnSuportedType, [TypeName]);
end;

class function TJSON.StrJSONToTValue(ValueType: SupportedTypes; Value: string): TValue;
var
  DateTime: TDateTime;
  Date: TDate;
  Time: TTime;
begin
  // Vacio
  if Value.IsEmpty then begin
    Result := TValue.Empty;
    Exit;
  end;

  // Otros tipos
  if (ValueType = SupportedTypes.TString) then begin
    Result := TValue.From<string>(Value);
  end
  else if (ValueType = SupportedTypes.TInteger) then begin
    Result := TValue.From<Integer>(StrToInt(Value));
  end
  else if (ValueType = SupportedTypes.TFloat) then begin
    Result := TValue.From<Double>(Self.StrJSONToFloat(Value));
  end
  else if (ValueType = SupportedTypes.TBoolean) then begin
    Result := TValue.From<Boolean>(StrToBool(Value));
  end
  else if (ValueType = SupportedTypes.TDateTime) then begin
    Result := TValue.From<TDateTime>(DateTime.FromJSON(Value));
  end
  else if (ValueType = SupportedTypes.TDate) then begin
    Result := TValue.From<TDate>(Date.FromJSON(Value));
  end
  else if (ValueType = SupportedTypes.TTime) then begin
    Result := TValue.From<TTime>(Time.FromJSON(Value));
  end
  else begin
    raise UnSuportedType(TEnumHelper<SupportedTypes>.ToString(ValueType));
  end;
end;

class function TJSON.DataSetToJSON(DataSet: TDataSet): TJSONObject;
begin
  Result := TDataSetJSON.ToJSON(DataSet);
end;

class function TJSON.PrettyPrint(const value : TJSONValue; const IdentString : string = '  ') : string;

  procedure PrettyPrintValue(const aValue : TJSONValue; const level : Integer;
    const sbResult : TStringBuilder; const identation : String);
  var
    pair : TJSONPair;
    item : TJSONValue;
    isFirst : Boolean;
  begin
    if aValue is TJSONObject then begin
      sbResult.Append('{').AppendLine;
      isFirst := true;
      if TJSONObject(aValue).Count = 0 then
        sbResult.Append('}')
      else begin
        for pair in TJSONObject(aValue) do begin
          if isFirst then isFirst := False
          else sbResult.Append(',').AppendLine;
          sbResult.Append(DupeString(identation, level+1))
            .Append(pair.JsonString)
            .Append(': ');
          PrettyPrintValue(pair.JsonValue, level + 1, sbResult, identation);
        end;
        sbResult.AppendLine.Append(DupeString(identation, level))
          .Append('}');
      end;
    end
    else if aValue is TJSONArray then begin
      sbResult.Append('[').AppendLine;
      isFirst := true;
      if TJSONArray(aValue).Count = 0 then
        sbResult.Append(']')
      else begin
        for item in TJSONArray(aValue) do begin
          if isFirst then isFirst := False
          else sbResult.Append(',').AppendLine;

          sbResult.Append(DupeString(identation, level+1));
          PrettyPrintValue(item, level + 1, sbResult, identation);
        end;
        sbResult.AppendLine.Append(DupeString(identation, level))
          .Append(']');
      end;
    end
    else if (aValue is TJSONString) or (aValue is TJSONTrue) or (aValue is TJSONFalse)
    or (aValue is TJSONNull) or (aValue is TJSONNumber) then
      sbResult.Append(aValue.ToString);
  end;
var
  sb : TStringBuilder;
begin
  sb := TStringBuilder.Create;
  PrettyPrintValue(value, 0, sb, IdentString);
  result := sb.ToString;
  sb.Free;
end;


end.
