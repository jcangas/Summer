unit EncryptSample.IEncrypter;

interface

uses
  System.SysUtils,
  System.Rtti,
  Summer.Encryption;

type
  TSimpleEncriptMode = record
    Seed: string;
    class operator Implicit(Value: TValue): TSimpleEncriptMode;
    class operator Implicit(Value: TSimpleEncriptMode): TValue;
  end;

  TComplexEncryptMode = record
    Name: string;
    Arg1: Integer;
    Arg2: string;
    class operator Implicit(Value: TValue): TComplexEncryptMode;
    class operator Implicit(Value: TComplexEncryptMode): TValue;
  end;

  EncryptMode = class
  public const
    Default: TSimpleEncriptMode = (Seed: '1a24Qh28');
    Orangesaft: TComplexEncryptMode = (Name: 'Orangesaft'; Arg1: 12; Arg2: 'x4yhP');
    Apfelsaft: TComplexEncryptMode = (Name: 'Apfelsaft'; Arg1: 1017; Arg2: 'AbbqinAQp');
  end;

implementation

{ TSimpleEncriptMode }

class operator TSimpleEncriptMode.Implicit(Value: TValue): TSimpleEncriptMode;
begin
  Result := Value.AsType<TSimpleEncriptMode>;
end;

class operator TSimpleEncriptMode.Implicit(Value: TSimpleEncriptMode): TValue;
begin
  Result := Value;
end;

{ TComplexEncryptMode }

class operator TComplexEncryptMode.Implicit(Value: TValue): TComplexEncryptMode;
begin
  Result := Value.AsType<TComplexEncryptMode>;
end;

class operator TComplexEncryptMode.Implicit(Value: TComplexEncryptMode): TValue;
begin
  Result := Value;
end;

end.

