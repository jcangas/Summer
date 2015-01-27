unit SummerFW.DDD.Validator;

interface

uses
  Generics.Collections,
  System.SysUtils,
  System.Rtti;

type
  TValidator = class
  public type
    TRule = class;

    TReport = class
    public type
      TLevel = (vlHint, vlWarn, vlError);
      TList = TObjectList<TReport>;
    private
      FRule: TRule;
      FLevel: TLevel;
      FReportMsg: string;
    public
      constructor Create(const Rule: TRule; const Level: TLevel; const ReportMsg: string); overload;
      property Rule: TRule read FRule;
      property Level: TLevel read FLevel;
      property ReportMsg: string read FReportMsg;
      function FormattedMsg: string;
    end;

    TRule = class
    public type
      TList = TObjectList<TRule>;
      TChecker = reference to function(Rule: TRule; Instance: TObject): Boolean;
    private
      FValidator: TValidator;
      FClassRtti: TRttiInstanceType;
      FPropRtti: TRttiInstanceProperty;
      FChecker: TChecker;
      FKey: string;
    protected
      function Match(const Pattern: string): Boolean; overload;
      function Check(const Instance: TObject): Boolean;
    public
      constructor Create(Validator: TValidator; AClass: TClass; APropName: string; AChecker: TRule.TChecker);
      procedure Report(const ReportMsg: string; const Level: TReport.TLevel = vlError);
      property ClassRtti: TRttiInstanceType read FClassRtti;
      property PropRtti: TRttiInstanceProperty read FPropRtti;
      property Validator: TValidator read FValidator;
      property Key: string read FKey;
    end;

  private
    RContext: TRttiContext;
    FReports: TReport.TList;
    FRules: TRule.TList;
  protected
    function GetInstanceType(AClass: TClass): TRttiInstanceType;
  public
    constructor Create;
    destructor Destroy; override;
    procedure AddRule(AClass: TClass; APropName: string; Validation: TRule.TChecker);
    procedure CheckNotEmpty(const AClass: TClass; const APropName: string; const Level: TReport.TLevel = vlError);
    procedure CheckPositive(const AClass: TClass; const APropName: string; const Level: TReport.TLevel = vlError);

    function Check(const Instance: TObject; const Pattern: string = ''): Boolean; overload;
    function FirstErrorIndex: Integer;
    function FirstError: TReport;
    function HasErrors: Boolean;
    property Rules: TRule.TList read FRules;
    property Reports: TReport.TList read FReports;
  end;

function Validator: TValidator;

implementation

uses
  System.RegularExpressions;

var
  FValidator: TValidator;

function Validator: TValidator;
begin
  Result := FValidator;
end;

{ TValidator.TRule }

function TValidator.TRule.Check(const Instance: TObject): Boolean;
begin
  Result := FChecker(Self, Instance);
end;

constructor TValidator.TRule.Create(Validator: TValidator; AClass: TClass; APropName: string; AChecker: TRule.TChecker);
begin
  inherited Create;
  FValidator := Validator;
  FClassRtti := Validator.GetInstanceType(AClass);
  FPropRtti := FClassRtti.GetProperty(APropName) as TRttiInstanceProperty;
  FChecker := AChecker;
  FKey := AClass.QualifiedClassName;
  if not APropName.IsEmpty then
    FKey := FKey + '/' + APropName
end;

function TValidator.TRule.Match(const Pattern: string): Boolean;
begin
  Result := TRegEx.IsMatch(Key, Pattern, [roIgnoreCase]);
end;

procedure TValidator.TRule.Report(const ReportMsg: string; const Level: TReport.TLevel);
begin
  Validator.Reports.Add(TReport.Create(Self, Level, ReportMsg));
end;

{ TValidator.TReport }

constructor TValidator.TReport.Create(const Rule: TRule; const Level: TLevel; const ReportMsg: string);
begin
  inherited Create;
  FRule := Rule;
  FLevel := Level;
  FReportMsg := ReportMsg;
end;

function TValidator.TReport.FormattedMsg: string;
begin
  Result := Format(ReportMsg, [Rule.PropRtti.Name]);
end;

{ TValidator }

function TValidator.Check(const Instance: TObject; const Pattern: string): Boolean;
var
  Rule: TRule;
  FullPattern: string;
begin
  Reports.Clear;
  Result := True;
  if Instance = nil then
    Exit;
  FullPattern := Instance.QualifiedClassName;
  if not Pattern.IsEmpty then
    FullPattern := FullPattern + '/' + Pattern;
  for Rule in Rules do begin
    if not Rule.Match(FullPattern) then
      Continue;
    if not Rule.Check(Instance) then
      Exit(False);
  end;
end;

constructor TValidator.Create;
begin
  inherited Create;
  FRules := TRule.TList.Create;
  FReports := TReport.TList.Create;
end;

destructor TValidator.Destroy;
begin
  FRules.Free;
  FReports.Free;
  inherited;
end;

function TValidator.FirstError: TReport;
begin
  Result := FReports[FirstErrorIndex];
end;

function TValidator.FirstErrorIndex: Integer;
var
  idx: Integer;
begin
  for idx := 0 to FReports.Count - 1 do
    if FReports[idx].Level = vlError then
      Exit(idx);
  Result := -1;
end;

function TValidator.GetInstanceType(AClass: TClass): TRttiInstanceType;
begin
  Result := RContext.GetType(AClass) as TRttiInstanceType;
end;

function TValidator.HasErrors: Boolean;
begin
  Result := FirstErrorIndex > -1;
end;

procedure TValidator.AddRule(AClass: TClass; APropName: string; Validation: TRule.TChecker);
begin
  FRules.Add(TRule.Create(Self, AClass, APropName, Validation));
end;

procedure TValidator.CheckNotEmpty(const AClass: TClass; const APropName: string;
  const Level: TReport.TLevel = vlError);
begin
  AddRule(AClass, APropName,
    function(Rule: TRule; Instance: TObject): Boolean
    begin
      Result := False;
      if not Rule.PropRtti.GetValue(Instance).AsString.IsEmpty then
        Exit(True);
      Rule.Report('%s debe contener un valor', Level);
    end);
end;

procedure TValidator.CheckPositive(const AClass: TClass; const APropName: string; const Level: TReport.TLevel);
begin
  AddRule(AClass, APropName,
    function(Rule: TRule; Instance: TObject): Boolean
    begin
      Result := False;
      if Rule.PropRtti.GetValue(Instance).IsOrdinal and (Rule.PropRtti.GetValue(Instance).AsOrdinal > 0) then
        Exit(True);
      if (Rule.PropRtti.GetValue(Instance).AsExtended > 0) then
        Exit(True);
      Rule.Report('%s debe ser > 0', Level);
    end);
end;

initialization

FValidator := TValidator.Create;

finalization

FValidator.Free;

end.
