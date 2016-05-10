program EncryptSample;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  EncryptSample.Encrypter in '..\Encrypt\EncryptSample.Encrypter.pas',
  EncryptSample.IEncrypter in '..\Encrypt\EncryptSample.IEncrypter.pas';

begin
  try
    { TODO -oUser -cConsole Main : Insert code here }
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
