{ == License ==
  - "Summer for Delphi" by Jorge L. Cangas <jorge.cangas@gmail.com> is licensed under CC BY 4.0
  -  Summer for Delphi - http://github.com/jcangas/Summer
  -  Summer - Copyright(c) Jorge L. Cangas, Some rights reserved.
  -  Your reuse is governed by the Creative Commons Attribution 4.0 License http://creativecommons.org/licenses/by/4.0/
}

unit Summer.Encryption;

interface

uses
  System.SysUtils,
  System.Rtti,
  Summer.IEncryption;

type
  /// Una implmentación por defecto de IEncrypter. Podemos crear nuevos servicios de encriptación partiendo
  /// de esta clase sin más que redefinir los métodos:
  /// function Encrypt(const Value: TBytes): TBytes;
  /// function Decrypt(const Value: TBytes): TBytes;
  TCustomEncrypter = class(TinterfacedObject, IEncrypter)
  strict private
    FActiveMode: TValue;
  protected
    /// A very simple symetric encrypter
    function SimpleEncrypt(const Value: TBytes): TBytes;
  public
    function GetActiveMode: TValue; virtual;
    procedure SetActiveMode(Value: TValue); virtual;
    function Encrypt(const Value: TBytes): TBytes; overload; virtual;
    function Encrypt(const Value: string): string; overload;
    function Encrypt(const Value: TBytes; Mode: TValue): TBytes; overload; virtual;
    function Encrypt(const Value: string; Mode: TValue): string; overload;
    function Decrypt(const Value: TBytes): TBytes; overload; virtual;
    function Decrypt(const Value: string): string; overload;
    function Decrypt(const Value: TBytes; Mode: TValue): TBytes; overload; virtual;
    function Decrypt(const Value: string; Mode: TValue): string; overload;
    property ActiveMode: TValue read GetActiveMode write SetActiveMode;
  end;

implementation

{ TCustomEncrypter }

function TCustomEncrypter.SimpleEncrypt(const Value: TBytes): TBytes;
var
  idx: Integer;
begin
  Result := Value;
  for idx := 1 to Length(Value) do
    Result[idx] := not(Value[idx] + idx);
end;

function TCustomEncrypter.GetActiveMode: TValue;
begin
  Result := FActiveMode;
end;

procedure TCustomEncrypter.SetActiveMode(Value: TValue);
begin
  FActiveMode := Value;
end;

function TCustomEncrypter.Encrypt(const Value: TBytes): TBytes;
begin
  Result := SimpleEncrypt(Value);
end;

function TCustomEncrypter.Encrypt(const Value: TBytes; Mode: TValue): TBytes;
var
  SavedMode: TValue;
begin
  SavedMode := ActiveMode;
  try
    ActiveMode := Mode;
    Result := Encrypt(Value);
  finally
    ActiveMode := SavedMode;
  end;
end;

function TCustomEncrypter.Encrypt(const Value: string): string;
begin
  Result := StringOf(Encrypt(BytesOf(Value)))
end;

function TCustomEncrypter.Encrypt(const Value: string; Mode: TValue): string;
begin
  Result := StringOf(Encrypt(BytesOf(Value), Mode));
end;

function TCustomEncrypter.Decrypt(const Value: TBytes): TBytes;
begin
  Result := SimpleEncrypt(Value);
end;

function TCustomEncrypter.Decrypt(const Value: string): string;
begin
  Result := StringOf(Decrypt(BytesOf(Value)))
end;

function TCustomEncrypter.Decrypt(const Value: TBytes; Mode: TValue): TBytes;
var
  SavedMode: TValue;
begin
  SavedMode := ActiveMode;
  try
    ActiveMode := Mode;
    Result := Decrypt(Value);
  finally
    ActiveMode := SavedMode;
  end;
end;

function TCustomEncrypter.Decrypt(const Value: string; Mode: TValue): string;
begin
  Result := StringOf(Decrypt(BytesOf(Value), Mode))
end;

end.
