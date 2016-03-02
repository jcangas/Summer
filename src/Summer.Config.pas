{== License ==
- "Summer for Delphi" by Jorge L. Cangas <jorge.cangas@gmail.com> is licensed under CC BY 4.0
-  Summer for Delphi - http://github.com/jcangas/Summer
-  Summer - Copyright(c) Jorge L. Cangas, Some rights reserved.
-  Your reuse is governed by the Creative Commons Attribution 4.0 License http://creativecommons.org/licenses/by/4.0/
}

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
  TConfiguration = class(TJSONProperties, IJSONProperties, IConfiguration)
  strict private
    FDefaults: IConfiguration;
  private
  protected
    function CreateChild(Values: TJSONObject; const OwnValues: Boolean): TJSONProperties;override;
    function GetChild(const Name: string): IJSONProperties; override;
    function GetValue(const Name: string): TValue; override;
    function GetDefaults: IConfiguration;
    procedure SetDefaults(Value: IConfiguration);
    function IConfiguration.GetChild = GetChildAsIConfiguration;
    function GetChildAsIConfiguration(const Name: string): IConfiguration;
  public
    function Clone : IConfiguration; overload;
    property Defaults: IConfiguration read GetDefaults write SetDefaults;
    property Childs[const Name: string]: IConfiguration read GetChildAsIConfiguration;
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
  Result := inherited Clone as IConfiguration;
end;

function TConfiguration.CreateChild(Values: TJSONObject;
  const OwnValues: Boolean): TJSONProperties;
begin
  Result := TConfiguration.Create(Values, OwnValues);
end;

function TConfiguration.GetChildAsIConfiguration(const Name: string): IConfiguration;
begin
  Result := GetChild(Name) as IConfiguration;
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
