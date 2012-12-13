{
  Summer Framework for Delphi http://github.com/jcangas/SummerFW4D
  SummerFW4D by Jorge L. Cangas <jorge.cangas@gmail.com>
  SummerFW4D - Copyright(c) Jorge L. Cangas, Some rights reserved.
  Your reuse is governed by the Creative Commons Attribution 3.0 License
}

unit SummerFW.Utils.Rules;

interface

uses Classes, SysUtils, Generics.Defaults, Generics.Collections,
  RegularExpressions, SummerFW.Utils.RTL;

type
  TRuleClass = class of TRule;
  TRuleEngine = class;

  TRuleTrigger = TOpenEnum;
  TRuleTriggers = TRuleTrigger.CodeSet;
  TResultKind = (rsNoTrigger, rsSatisfied, rsIgnored, rsHint, rsWarn, rsFail);
  TRule = class
  type
    TTriggerInfo = record
    private
      FSubjectMask: string;
      FTriggers: TRuleTriggers;
      FOrder: Integer;
      FRuleClass: TRuleClass;
    public
      function Match(Subject: string; Trigger: TRuleTrigger): Boolean;
      property SubjectMask: string read FSubjectMask;
      property Triggers: TRuleTriggers read FTriggers;
      property Order: Integer read FOrder;
      property RuleClass: TRuleClass read FRuleClass;
      constructor Create(RuleClass: TRuleClass; SubjectMask: string; Triggers: TRuleTriggers; Order: Integer);
    end;

    TTriggerInfoComparer = class(TComparer<TRule.TTriggerInfo>)
    public
      function Compare(const Left, Right: TRule.TTriggerInfo): Integer;
        override;
    end;
    TTriggerInfos = class(TList<TRule.TTriggerInfo>);

    TResultInfo = record
    strict private
      FRuleClass: TRuleClass;
      FSubject: string;
      FTrigger: TRuleTrigger;
      FTarget: TObject;
      FKind: TResultKind;
      FMessage: string;
    private
      procedure Prepare(Subject: string; Trigger: TRuleTrigger; Target: TObject);
      procedure Reset;
      procedure SetMessage(const Value: string);
    public
      constructor Create(RuleClass: TRuleClass);
      property RuleClass: TRuleClass read FRuleClass;
      property Subject: string read FSubject;
      property Trigger: TRuleTrigger read FTrigger;
      property Target: TObject read FTarget;
      property Kind: TResultKind read FKind write FKind;
      property Message: string read FMessage;
    end;
    TResultInfos = class(TList<TResultInfo>);

  strict private
    FRuleEngine: TRuleEngine;
    FTriggerInfo: TTriggerInfo;
    FRuleResult: TResultInfo;
    function GetTarget: TObject;
  protected
    class function GetName: string; virtual;
    function GetResultMessage: string; virtual;
    procedure Reset; virtual;
    constructor Create(RuleEngine: TRuleEngine; TriggerInfo: TTriggerInfo);
  public
    function Accept(Target: TObject): Boolean; virtual;
    function Satisfied: Boolean; virtual; abstract;
    procedure Done;
    property RuleEngine: TRuleEngine read FRuleEngine;
    property Name: string read GetName;
    property Target: TObject read GetTarget;
    property TriggerInfo: TTriggerInfo read FTriggerInfo;
    property ResultInfo: TResultInfo read FRuleResult;
  end;

  TRuleEngine = class
  strict private
    FRegistry: TRule.TTriggerInfos;
    FRegistryDirty: Boolean;
  protected
    function CreateRule(Info: TRule.TTriggerInfo): TRule;
    procedure CheckRegistryIsDirty;
    procedure AfterTriggerRule(Rule: TRule);virtual;
    procedure BeforeTriggerRule(Rule: TRule);virtual;
  public
    constructor Create;
    destructor Destroy; override;
    function Register(Info: TRule.TTriggerInfo): TRuleEngine; overload;
    function Register(RuleClass: TRuleClass; SubjectMask: string;
      Triggers: array of TRuleTrigger; Order: Integer): TRuleEngine; overload;
    function Satisfy(Subject: string; ForTrigger: TRuleTrigger;
      ATarget: TObject; var ResultInfos: TRule.TResultInfos): Boolean; overload;
    function Satisfy(SubjectFmt: string; Args: array of const;
      ForTrigger: TRuleTrigger; ATarget: TObject; var ResultInfos: TRule.TResultInfos)
      : Boolean; overload;
  end;

implementation

uses StrUtils, DB;

{ TRule }

function TRule.Accept(Target: TObject): Boolean;
begin
  Result := True;
end;

constructor TRule.Create(RuleEngine: TRuleEngine; TriggerInfo: TTriggerInfo);
begin
  inherited Create;
  FRuleEngine := RuleEngine;
  FTriggerInfo := TriggerInfo;
  FRuleResult.Create(TRuleClass(ClassType));
  Reset;
end;

procedure TRule.Done;
begin
  FRuleResult.Reset;
  Reset;
end;

function TRule.GetResultMessage: string;
begin
  Result := Format('Rule %s failed for target %s', [Name, Self.ResultInfo.Target.ToString])
end;

function TRule.GetTarget: TObject;
begin
  Result := FRuleResult.Target;
end;

class function TRule.GetName: string;
begin
  Result := ClassName;
  if AnsiStartsText('T', Result) then
    System.Delete(Result, 1, 1); // Remove 'T' prefix
  if AnsiEndsText('Rule', Result) then // Remove 'Rule' sufix
    System.Delete(Result, Length(Result) - 3, 4);
end;

procedure TRule.Reset;
begin

end;

{ TRuleEngine }

function TRuleEngine.CreateRule(Info: TRule.TTriggerInfo): TRule;
begin
  Result := Info.RuleClass.Create(Self, Info);
end;

function TRuleEngine.Satisfy(SubjectFmt: string; Args: array of const;
  ForTrigger: TRuleTrigger; ATarget: TObject;
  var ResultInfos: TRule.TResultInfos): Boolean;
begin
  Result := Satisfy(Format(SubjectFmt, Args), ForTrigger, ATarget, ResultInfos);
end;

procedure TRuleEngine.BeforeTriggerRule(Rule: TRule);
begin
end;

procedure TRuleEngine.AfterTriggerRule(Rule: TRule);
begin
end;

function TRuleEngine.Satisfy(Subject: string; ForTrigger: TRuleTrigger;
  ATarget: TObject; var ResultInfos: TRule.TResultInfos): Boolean;
var
  Rule: TRule;
  Info: TRule.TTriggerInfo;
  Rules: TObjectList<TRule>;
begin
  Result := True;
  CheckRegistryIsDirty;
  Rules := TObjectList<TRule>.Create;
  try
    for Info in FRegistry do begin
      if not Info.Match(Subject, ForTrigger) then Continue;
      Rule := CreateRule(Info);
      Rules.Add(Rule);
      if not Rule.Accept(ATarget) then Continue;
      Rule.ResultInfo.Prepare(Subject, ForTrigger, ATarget);
      BeforeTriggerRule(Rule);
      if not Rule.Satisfied then begin
        Rule.ResultInfo.SetMessage(Rule.GetResultMessage);
        ResultInfos.Add(Rule.ResultInfo);
        Result := False;
      end;
      Rule.Done;
      AfterTriggerRule(Rule);
    end;
  finally
    Rules.Free;
  end;
end;

procedure TRuleEngine.CheckRegistryIsDirty;
begin
  if not FRegistryDirty then
    Exit;
  FRegistry.Sort;
  FRegistryDirty := False;
end;

constructor TRuleEngine.Create;
begin
  inherited Create;
  FRegistry := TRule.TTriggerInfos.Create(TRule.TTriggerInfoComparer.Create);
end;

destructor TRuleEngine.Destroy;
begin
  FRegistry.Free;
  inherited;
end;

function TRuleEngine.Register(Info: TRule.TTriggerInfo): TRuleEngine;
begin
  Result := Self;
  FRegistry.Add(Info);
  FRegistryDirty := True;
end;

function TRuleEngine.Register(RuleClass: TRuleClass; SubjectMask: string;
  Triggers: array of TRuleTrigger; Order: Integer): TRuleEngine;
var
  Info: TRule.TTriggerInfo;
begin
  Result := Self;
  Info.Create(RuleClass, SubjectMask, TOpenEnum.&Set(Triggers), Order);
  Register(Info);
end;

{ TRuleEngine.TRegistryComparer }

function TRule.TTriggerInfoComparer.Compare(const Left,
  Right: TRule.TTriggerInfo): Integer;
begin
  Result := Left.Order - Right.Order;
end;

{ TRule.TTriggerInfo }

constructor TRule.TTriggerInfo.Create(RuleClass: TRuleClass; SubjectMask: string; Triggers: TRuleTriggers; Order: Integer);
begin
  FRuleClass := RuleClass;
  FSubjectMask := SubjectMask;
  FTriggers := Triggers;
  FOrder := Order;
end;

function TRule.TTriggerInfo.Match(Subject: string;
  Trigger: TRuleTrigger): Boolean;
begin
  Result := Trigger.MemberOf(Triggers) and TRegEx.IsMatch(Subject, '^' + SubjectMask + '$')
end;

{ TRule.TResultInfo }

constructor TRule.TResultInfo.Create(RuleClass: TRuleClass);
begin
  FRuleClass := RuleClass;
  Reset;
end;

procedure TRule.TResultInfo.Reset;
begin
  FKind := rsNoTrigger;
  FTarget := nil;
  FSubject := '';
  FMessage := '';
end;

procedure TRule.TResultInfo.SetMessage(const Value: string);
begin
  FMessage := Value;
end;

procedure TRule.TResultInfo.Prepare(Subject: string; Trigger: TRuleTrigger;
  Target: TObject);
begin
  FSubject := Subject;
  FTrigger := Trigger;
  FTarget := Target;
  FKind := rsSatisfied;
  FMessage := '';
end;

end.
