unit SummerFW.DDD.IAppFacade;

interface

uses
  System.Classes,
  PureMVC.Interfaces.IFacade;

const
  //RunModes
  rmDevelopment = 'development';
  rmProduction = 'production';
  rmTest = 'test';

type
  TRunMode = record
  public
    Name: string;
    /// Name for this Run mode
    RelativeRootPath: string; // RootPath relative to ExeFileName
  end;

  IApplicationFacade = interface(IFacade)
  ['{A97A1EAA-4D70-491C-AE10-A566463B51FB}']
{$REGION 'Fake Delphi TApplication API'}
    procedure Initialize;
    procedure Run;
    function MainForm: TObject;
    procedure CreateForm(const InstanceClass: TComponentClass; var Reference);
    procedure ProccessMessages;
{$ENDREGION}
    procedure SetRunMode(const Value: TRunMode);
    function GetRunMode: TRunMode;
    property RunMode: TRunMode read GetRunMode write SetRunMode;
  end;

var
  EnvironmentMode: TRunMode = (name: rmProduction; RelativeRootPath: '..');
implementation

end.
