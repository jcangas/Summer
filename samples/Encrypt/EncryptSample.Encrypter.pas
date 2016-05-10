unit EncryptSample.Encrypter;

interface

uses
  System.SysUtils,
  System.Rtti,
  Summer.Encryption;

type
  TSampleEncrypter = class(TCustomEncrypter)
  public
    constructor Create;
    procedure SetActiveMode(Value: TValue); override;

    function Encrypt(const Value: TBytes): TBytes; override;
    function Decrypt(const Value: TBytes): TBytes; override;
  end;

implementation

uses
  EncryptSample.IEncrypter;

{ TSampleEncrypter }

constructor TSampleEncrypter.Create;
begin
  inherited;
  SetActiveMode(EncryptMode.Default);
end;

procedure TSampleEncrypter.SetActiveMode(Value: TValue);
begin
  if Value.IsType<TSimpleEncriptMode> then begin
    // Setup this encrypter using Value.AsType<TSimpleEncriptMode>
  end
  else if Value.IsType<TComplexEncryptMode> then begin
    // Setup this encrypter using Value.AsType<TComplexEncryptMode>
  end;
  inherited;
end;

function TSampleEncrypter.Decrypt(const Value: TBytes): TBytes;
begin
  Result := inherited;
end;

function TSampleEncrypter.Encrypt(const Value: TBytes): TBytes;
begin
  Result := inherited;
end;

end.
