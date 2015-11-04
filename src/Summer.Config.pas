unit Summer.Config;

interface

uses
  System.JSON,
  System.SysUtils,
  System.IOUtils,
  System.Rtti,
  Summer.IConfig,
  Summer.IJSONProperties,
  Summer.JSONProperties;

type
  TConfiguration = class(TJSONProperties, IConfiguration)
  strict private
    FDefaults: IConfiguration;
  private
  protected
    function GetChild(const Name: string): IJSONProperties; override;
    function GetValue(const Name: string): TValue; override;
    function GetDefaults: IConfiguration;
    procedure SetDefaults(Value: IConfiguration);

  public
    function Clone : IConfiguration; overload;
    property Defaults: IConfiguration read GetDefaults write SetDefaults;
  end;

implementation

uses
  Summer.RTTI;

procedure TConfiguration.SetDefaults(Value: IConfiguration);
begin
  FDefaults := Value.Clone;
end;

function TConfiguration.Clone: IConfiguration;
begin
  Result := TConfiguration.Create(AsObject.Clone as TJSONObject, True);
end;

function TConfiguration.GetChild(const Name: string): IJSONProperties;
begin
  Result := inherited;
  if (Result = nil) then begin
    if (FDefaults <> nil) then
      Result := FDefaults.Childs[Name]
    else
      Result := nil;
  end;
end;

function TConfiguration.GetDefaults: IConfiguration;
begin
  if FDefaults = nil then
    FDefaults := TConfiguration.Create;
  Result := FDefaults;
end;

function TConfiguration.GetValue(const Name: string): TValue;
begin
  Result := inherited GetValue(Name);
  if Result.IsEmpty then begin
    if (FDefaults <> nil) then
      Result := FDefaults.GetValue(name)
    else
      Result := nil;
  end;
end;

end.
